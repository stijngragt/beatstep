import Foundation

@Observable
final class RunEngineService {
    static let shared = RunEngineService()

    // MARK: - Observable State

    var isRunActive = false
    var tolerance: BPMTolerance = .saved
    var currentMatchedTrack: SpotifyTrack?
    var runMode: RunMode = .free
    var rampPhase: RampPhase? = nil
    var tempoMode: TempoMode = .saved {
        didSet {
            if isRunActive && oldValue != tempoMode {
                invalidateBuffer()  // Per D-08
            }
        }
    }
    var latestCadence: Int = 0

    // MARK: - Private

    @ObservationIgnored
    private var playlistTracks: [SpotifyTrack] = []
    @ObservationIgnored
    private var bpmMap: [String: Int] = [:]
    @ObservationIgnored
    private var playedTrackIDs: Set<String> = []
    @ObservationIgnored
    private var sustainedSPM: Int = 0
    @ObservationIgnored
    private var sustainedChangeTask: Task<Void, Never>?
    @ObservationIgnored
    private var songEndMonitorTask: Task<Void, Never>?
    @ObservationIgnored
    private var cadenceMonitorTask: Task<Void, Never>?
    @ObservationIgnored
    private var isQueueingNext = false
    @ObservationIgnored
    private var lastPlayTime: Date?
    @ObservationIgnored
    private var targetBPM: Int = 160
    @ObservationIgnored
    private var rampSongsPlayed: Int = 0
    @ObservationIgnored
    private var danceabilityMap: [String: Int] = [:]
    @ObservationIgnored
    private var zeroBPMFallback: ZeroBPMFallback = .skip
    @ObservationIgnored
    private var playedNilBPMIDs: Set<String> = []
    @ObservationIgnored
    private var isDiscovering: Bool = false
    @ObservationIgnored
    private(set) var needsDiscovery: Bool = false
    @ObservationIgnored
    private var trackBuffer: [SpotifyTrack] = []
    @ObservationIgnored
    private var bufferRefillTask: Task<Void, Never>?
    @ObservationIgnored
    private var isRefillingBuffer = false
    @ObservationIgnored
    private var lastSkipTime: Date?

    private init() {}

    // MARK: - Effective BPM

    /// Effective BPM for song selection. Free mode uses cadence, guided uses ramp target.
    var effectiveBPM: Int {
        switch runMode {
        case .free:
            return sustainedSPM
        case .guided:
            guard let phase = rampPhase else { return targetBPM }
            let warmUpStart = 140
            switch phase {
            case .warmUp:
                return min(warmUpStart + rampSongsPlayed * 8, targetBPM)
            case .atPace:
                return targetBPM
            case .coolDown:
                return max(targetBPM - rampSongsPlayed * 8, warmUpStart)
            }
        }
    }

    // MARK: - Tempo-Aware Computed Properties

    /// Cadence adjusted for tempo mode (cadence/2 in half mode)
    var adjustedCadence: Int {
        switch tempoMode {
        case .oneToOne: return latestCadence
        case .half: return latestCadence / 2
        }
    }

    /// Current matched track's BPM from the bpmMap
    var currentTrackBPM: Int? {
        guard let track = currentMatchedTrack else { return nil }
        return bpmMap[track.id]
    }

    /// Signed delta between adjusted cadence and current song BPM. 0 when no track matched.
    var cadenceDelta: Int {
        guard let trackBPM = currentTrackBPM else { return 0 }
        return adjustedCadence - trackBPM
    }

    /// Sync quality derived from adjusted cadence and current track BPM with tempo normalization
    var syncQuality: SyncQuality {
        guard let trackBPM = currentTrackBPM else { return .mismatched }
        return SyncQuality.from(spm: adjustedCadence, trackBPM: trackBPM, tolerance: tolerance)
    }

    // MARK: - Run Lifecycle

    @MainActor
    func startRun(playlist: SpotifyPlaylist, tracks: [SpotifyTrack]) async {
        // Load BPMs and danceability into memory
        var map: [String: Int] = [:]
        var danceMap: [String: Int] = [:]
        for track in tracks {
            if let bpm = BPMCacheService.shared.getBPM(forTrackID: track.id) {
                map[track.id] = bpm
            }
            if let dance = BPMCacheService.shared.getDanceability(forTrackID: track.id) {
                danceMap[track.id] = dance
            }
        }

        playlistTracks = tracks
        bpmMap = map
        danceabilityMap = danceMap
        playedTrackIDs = []
        isRunActive = true
        zeroBPMFallback = ZeroBPMFallback.saved
        needsDiscovery = false
        isDiscovering = false

        // Set up guided mode if active
        if runMode == .guided {
            targetBPM = RunMode.savedTargetBPM
            rampPhase = .warmUp
            rampSongsPlayed = 0
        } else {
            rampPhase = nil
            rampSongsPlayed = 0
        }

        // Read current cadence as starting point
        sustainedSPM = CadenceService.shared.currentSPM

        // Play first matched song immediately
        let firstBPM = effectiveBPM
        if let first = selectNextMatch(forSPM: firstBPM) {
            await playTrack(first)
        }

        // Fill buffer with 3 pre-computed tracks (per D-01)
        fillBuffer()

        // Start monitoring
        startCadenceMonitor()
        startSongEndMonitor()
    }

    func stopRun() {
        isRunActive = false
        currentMatchedTrack = nil
        playlistTracks = []
        bpmMap = [:]
        danceabilityMap = [:]
        playedTrackIDs = []
        playedNilBPMIDs = []
        sustainedSPM = 0
        latestCadence = 0
        isQueueingNext = false
        lastPlayTime = nil
        rampPhase = nil
        rampSongsPlayed = 0
        needsDiscovery = false
        isDiscovering = false
        trackBuffer.removeAll()
        bufferRefillTask?.cancel()
        bufferRefillTask = nil
        isRefillingBuffer = false
        lastSkipTime = nil

        sustainedChangeTask?.cancel()
        sustainedChangeTask = nil
        songEndMonitorTask?.cancel()
        songEndMonitorTask = nil
        cadenceMonitorTask?.cancel()
        cadenceMonitorTask = nil
    }

    func skipToNextMatch() async {
        guard isRunActive else { return }

        // Per D-04: 1-second cooldown between skips (replaces old 5s rate limit per D-05)
        if let lastSkip = lastSkipTime,
           Date().timeIntervalSince(lastSkip) < 1.0 {
            return
        }

        // Per D-06: if buffer empty, await refill (no fallback to on-demand)
        if trackBuffer.isEmpty {
            // Wait for in-flight refill to complete
            await bufferRefillTask?.value
            guard !trackBuffer.isEmpty else { return }
        }

        lastSkipTime = Date()
        await popAndPlay()
    }

    /// Manually start cool-down phase (guided mode only)
    func startCoolDown() {
        guard runMode == .guided else { return }
        rampPhase = .coolDown
        rampSongsPlayed = 0
    }

    // MARK: - BPM Matching (internal for testing)

    func findMatchingTracks(forSPM spm: Int) -> [SpotifyTrack] {
        let targets = [spm, spm / 2, spm * 2]
        let range = tolerance.range

        var matches = playlistTracks.filter { track in
            guard let bpm = bpmMap[track.id] else { return false }
            return targets.contains { target in abs(bpm - target) <= range }
        }

        // Half-tempo ranking: prefer tracks near spm/2
        if tempoMode == .half {
            let preferredTarget = spm / 2
            matches.sort { trackA, trackB in
                let bpmA = bpmMap[trackA.id] ?? 0
                let bpmB = bpmMap[trackB.id] ?? 0
                return abs(bpmA - preferredTarget) < abs(bpmB - preferredTarget)
            }
        }

        return matches
    }

    func findClosestTrack(forSPM spm: Int) -> SpotifyTrack? {
        let targets = [spm, spm / 2, spm * 2]

        return playlistTracks
            .compactMap { track -> (SpotifyTrack, Int)? in
                guard let bpm = bpmMap[track.id] else { return nil }
                let minDist = targets.map { abs(bpm - $0) }.min() ?? Int.max
                return (track, minDist)
            }
            .min(by: { $0.1 < $1.1 })?
            .0
    }

    // MARK: - Smart Selection

    /// Determines whether to prefer high-energy (high danceability) tracks
    private var preferHighEnergy: Bool {
        switch runMode {
        case .free:
            return true
        case .guided:
            guard let phase = rampPhase else { return true }
            switch phase {
            case .warmUp, .coolDown:
                return false
            case .atPace:
                return true
            }
        }
    }

    // MARK: - No-Repeat Pool Selection with Smart Ranking

    func selectNextMatch(forSPM spm: Int) -> SpotifyTrack? {
        var matches = findMatchingTracks(forSPM: spm)
            .filter { !playedTrackIDs.contains($0.id) }

        // If pool exhausted, reset and try again
        if matches.isEmpty {
            playedTrackIDs.removeAll()
            matches = findMatchingTracks(forSPM: spm)
        }

        // If still no matches after reset, fall back to closest
        if matches.isEmpty {
            if let closest = findClosestTrack(forSPM: spm) {
                playedTrackIDs.insert(closest.id)
                checkDiscoveryNeeded(matchCount: 0, forBPM: spm)
                return closest
            }
            // Zero-BPM fallback: include nil-BPM tracks if user configured playRegardless or prompt
            if zeroBPMFallback == .playRegardless || zeroBPMFallback == .prompt {
                let nilBPMTracks = playlistTracks.filter { bpmMap[$0.id] == nil && !playedNilBPMIDs.contains($0.id) }
                if let track = nilBPMTracks.first {
                    playedNilBPMIDs.insert(track.id)
                    playedTrackIDs.insert(track.id)
                    return track
                }
                // If nil-BPM pool exhausted, reset and retry
                let allNilBPM = playlistTracks.filter { bpmMap[$0.id] == nil }
                if !allNilBPM.isEmpty {
                    playedNilBPMIDs.removeAll()
                    if let track = allNilBPM.first {
                        playedNilBPMIDs.insert(track.id)
                        playedTrackIDs.insert(track.id)
                        return track
                    }
                }
            }
            checkDiscoveryNeeded(matchCount: 0, forBPM: spm)
            return nil
        }

        // Check if discovery needed before selection
        checkDiscoveryNeeded(matchCount: matches.count, forBPM: spm)

        // Smart selection: rank by danceability
        let sorted = matches.sorted { trackA, trackB in
            let danceA = danceabilityMap[trackA.id] ?? 50
            let danceB = danceabilityMap[trackB.id] ?? 50

            if preferHighEnergy {
                return danceA > danceB
            } else {
                return danceA < danceB
            }
        }

        // Pick from top candidates with weighted bias toward best match
        // With 4+ matches: random from top 3 for variety
        // With 1-3 matches: pick first (best ranked) to maintain danceability preference
        let selected: SpotifyTrack
        if sorted.count > 3 {
            let topSlice = Array(sorted.prefix(3))
            selected = topSlice.randomElement()!
        } else {
            selected = sorted[0]
        }

        playedTrackIDs.insert(selected.id)
        return selected
    }

    // MARK: - Discovery Integration

    private func checkDiscoveryNeeded(matchCount: Int, forBPM bpm: Int) {
        if matchCount < 3 && !isDiscovering {
            needsDiscovery = true
            fireBackgroundDiscovery(atBPM: bpm)
        }
    }

    private func fireBackgroundDiscovery(atBPM bpm: Int) {
        guard !isDiscovering else { return }
        isDiscovering = true

        Task { @MainActor [weak self] in
            defer { self?.isDiscovering = false }
            do {
                let discovered = try await BPMDiscoveryService.shared.discoverTracks(atBPM: bpm)
                guard let self, !discovered.isEmpty else { return }

                // Add discovered tracks to pool
                for track in discovered {
                    if !self.playlistTracks.contains(where: { $0.id == track.id }) {
                        self.playlistTracks.append(track)
                    }
                }

                // Look up BPMs for discovered tracks
                for track in discovered {
                    if let cachedBPM = BPMCacheService.shared.getBPM(forTrackID: track.id) {
                        self.bpmMap[track.id] = cachedBPM
                    }
                    if let cachedDance = BPMCacheService.shared.getDanceability(forTrackID: track.id) {
                        self.danceabilityMap[track.id] = cachedDance
                    }
                }

                // Save to discovery playlist
                try? await BPMDiscoveryService.shared.saveToDiscoveryPlaylist(tracks: discovered)
            } catch {
                // Discovery is best-effort, don't fail the run
            }
        }
    }

    // MARK: - Track Buffer

    /// Pop first track from buffer. Returns nil if buffer empty.
    private func popNextFromBuffer() -> SpotifyTrack? {
        guard !trackBuffer.isEmpty else { return nil }
        return trackBuffer.removeFirst()
    }

    /// Fill buffer up to 3 tracks using selectNextMatch at current effectiveBPM.
    /// Per D-01: 3-track buffer. Per D-02: refill immediately after each pop.
    private func fillBuffer() {
        let spm = effectiveBPM
        while trackBuffer.count < 3 {
            guard let track = selectNextMatch(forSPM: spm) else { break }
            trackBuffer.append(track)
        }
    }

    /// Async refill -- guarded by isRefillingBuffer flag (matches isQueueingNext pattern).
    /// Per D-02: maintain 3 tracks at all times.
    private func triggerBufferRefill() {
        guard !isRefillingBuffer else { return }
        bufferRefillTask?.cancel()
        bufferRefillTask = Task { @MainActor [weak self] in
            guard let self else { return }
            self.isRefillingBuffer = true
            defer { self.isRefillingBuffer = false }
            guard !Task.isCancelled else { return }
            self.fillBuffer()
        }
    }

    /// Invalidate buffer and rebuild. Per D-07/D-08: cadence commit and tempo toggle.
    /// Cancels in-flight refill first to prevent stale tracks (Pitfall 3 from RESEARCH.md).
    func invalidateBuffer() {
        bufferRefillTask?.cancel()
        bufferRefillTask = nil
        trackBuffer.removeAll()
        triggerBufferRefill()
    }

    // MARK: - Ramp Transitions

    private func handleRampTransition() {
        guard runMode == .guided, let phase = rampPhase else { return }

        rampSongsPlayed += 1

        switch phase {
        case .warmUp:
            if effectiveBPM >= targetBPM {
                rampPhase = .atPace
                rampSongsPlayed = 0
            }
        case .atPace:
            break
        case .coolDown:
            if effectiveBPM <= 140 {
                stopRun()
            }
        }
    }

    // MARK: - Sustained Change Detection

    /// Returns true if the change is outside tolerance (would start debounce).
    /// Does NOT actually start the async debounce timer (that happens in the cadence monitor).
    func evaluateCadenceChange(newSPM: Int) -> Bool {
        return abs(newSPM - sustainedSPM) > tolerance.range
    }

    // MARK: - Cadence Monitor

    private func startCadenceMonitor() {
        cadenceMonitorTask = Task { [weak self] in
            var lastObservedSPM: Int = 0
            while !Task.isCancelled {
                guard let self else { return }
                let currentSPM = await MainActor.run { CadenceService.shared.currentSPM }

                self.latestCadence = currentSPM

                if currentSPM != lastObservedSPM && currentSPM > 0 {
                    lastObservedSPM = currentSPM
                    self.onCadenceChanged(currentSPM)
                }

                try? await Task.sleep(for: .seconds(2))
            }
        }
    }

    private func onCadenceChanged(_ newSPM: Int) {
        let significantChange = abs(newSPM - sustainedSPM) > tolerance.range
        guard significantChange else {
            // Within tolerance -- cancel any pending debounce (cadence reverted)
            sustainedChangeTask?.cancel()
            sustainedChangeTask = nil
            return
        }

        // Outside tolerance -- start debounce
        sustainedChangeTask?.cancel()
        sustainedChangeTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(8))
            guard !Task.isCancelled else { return }
            // Commit sustained change
            self?.sustainedSPM = newSPM
            // Per D-07: invalidate buffer and rebuild with new cadence
            self?.invalidateBuffer()
        }
    }

    // MARK: - Song-End Monitor

    private func startSongEndMonitor() {
        songEndMonitorTask = Task { @MainActor [weak self] in
            var lastTrackID: String?
            while !Task.isCancelled {
                let currentID = SpotifyPlayerService.shared.currentTrack?.id
                if let currentID, currentID != lastTrackID, lastTrackID != nil {
                    // Song changed -- queue next match
                    await self?.queueNextMatch()
                }
                lastTrackID = currentID
                try? await Task.sleep(for: .seconds(2))
            }
        }
    }

    // MARK: - Playback

    /// Pop next track from buffer, play it, handle ramp, trigger refill.
    /// Per D-03: serves ALL transitions (manual skip and song-end).
    private func popAndPlay() async {
        guard let next = popNextFromBuffer() else { return }

        handleRampTransition()
        await playTrack(next)
        triggerBufferRefill()
    }

    private func queueNextMatch() async {
        guard !isQueueingNext else { return }
        isQueueingNext = true
        defer { isQueueingNext = false }

        // Per D-03: song-end transitions pop from buffer (same as skip)
        if trackBuffer.isEmpty {
            await bufferRefillTask?.value
            guard !trackBuffer.isEmpty else { return }
        }

        await popAndPlay()
    }

    private func playTrack(_ track: SpotifyTrack) async {
        currentMatchedTrack = track
        lastPlayTime = Date()
        // Use play(uri:) WITHOUT contextURI so Spotify does not auto-advance
        SpotifyPlayerService.shared.play(uri: track.uri)
    }

    // MARK: - Testing Helpers

    func loadForTesting(tracks: [SpotifyTrack], bpmMap: [String: Int]) {
        playlistTracks = tracks
        self.bpmMap = bpmMap
        playedTrackIDs = []
        playedNilBPMIDs = []
    }

    func setSustainedSPMForTesting(_ spm: Int) {
        sustainedSPM = spm
    }

    func setDanceabilityMapForTesting(_ map: [String: Int]) {
        danceabilityMap = map
    }

    func setRunModeForTesting(_ mode: RunMode, targetBPM: Int) {
        runMode = mode
        self.targetBPM = targetBPM
    }

    func setRampPhaseForTesting(_ phase: RampPhase, songsPlayed: Int) {
        rampPhase = phase
        rampSongsPlayed = songsPlayed
    }

    func setTempoModeForTesting(_ mode: TempoMode) {
        tempoMode = mode
    }

    func setLatestCadenceForTesting(_ spm: Int) {
        latestCadence = spm
    }

    func setZeroBPMFallbackForTesting(_ fallback: ZeroBPMFallback) {
        zeroBPMFallback = fallback
    }

    func fillBufferForTesting(spm: Int) {
        while trackBuffer.count < 3 {
            guard let track = selectNextMatch(forSPM: spm) else { break }
            trackBuffer.append(track)
        }
    }

    func getBufferForTesting() -> [SpotifyTrack] {
        return trackBuffer
    }

    func setLastSkipTimeForTesting(_ date: Date?) {
        lastSkipTime = date
    }

    func popNextFromBufferForTesting() -> SpotifyTrack? {
        return popNextFromBuffer()
    }

    func invalidateBufferForTesting() {
        invalidateBuffer()
    }
}
