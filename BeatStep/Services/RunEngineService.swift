import Foundation

@Observable
final class RunEngineService {
    static let shared = RunEngineService()

    // MARK: - Observable State

    var isRunActive = false
    var tolerance: BPMTolerance = .saved
    var currentMatchedTrack: SpotifyTrack?

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
    private var pendingRematch = false
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

    private init() {}

    // MARK: - Run Lifecycle

    @MainActor
    func startRun(playlist: SpotifyPlaylist, tracks: [SpotifyTrack]) async {
        // Load BPMs into memory (avoids repeated @MainActor BPMCacheService queries)
        var map: [String: Int] = [:]
        for track in tracks {
            if let bpm = BPMCacheService.shared.getBPM(forTrackID: track.id) {
                map[track.id] = bpm
            }
        }

        playlistTracks = tracks
        bpmMap = map
        playedTrackIDs = []
        pendingRematch = false
        isRunActive = true

        // Read current cadence as starting point
        sustainedSPM = CadenceService.shared.currentSPM

        // Play first matched song immediately
        if let first = selectNextMatch(forSPM: sustainedSPM) {
            await playTrack(first)
        }

        // Start monitoring
        startCadenceMonitor()
        startSongEndMonitor()
    }

    func stopRun() {
        isRunActive = false
        currentMatchedTrack = nil
        playlistTracks = []
        bpmMap = [:]
        playedTrackIDs = []
        sustainedSPM = 0
        pendingRematch = false
        isQueueingNext = false
        lastPlayTime = nil

        sustainedChangeTask?.cancel()
        sustainedChangeTask = nil
        songEndMonitorTask?.cancel()
        songEndMonitorTask = nil
        cadenceMonitorTask?.cancel()
        cadenceMonitorTask = nil
    }

    func skipToNextMatch() async {
        guard isRunActive, !isQueueingNext else { return }
        await queueNextMatch()
    }

    // MARK: - BPM Matching (internal for testing)

    func findMatchingTracks(forSPM spm: Int) -> [SpotifyTrack] {
        let targets = [spm, spm / 2, spm * 2]
        let range = tolerance.range

        return playlistTracks.filter { track in
            guard let bpm = bpmMap[track.id] else { return false }
            return targets.contains { target in abs(bpm - target) <= range }
        }
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

    // MARK: - No-Repeat Pool Selection

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
                return closest
            }
            return nil
        }

        // Random selection
        let selected = matches.randomElement()!
        playedTrackIDs.insert(selected.id)
        return selected
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
            try? await Task.sleep(for: .seconds(17))
            guard !Task.isCancelled else { return }
            // Commit sustained change
            self?.sustainedSPM = newSPM
            self?.pendingRematch = true
            // Re-match happens at next song end, not immediately
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

    private func queueNextMatch() async {
        guard !isQueueingNext else { return }
        isQueueingNext = true
        defer { isQueueingNext = false }

        // Rate limit: never play more than once per 5 seconds
        if let lastPlay = lastPlayTime,
           Date().timeIntervalSince(lastPlay) < 5.0 {
            return
        }

        // If pending rematch from sustained change, use new SPM
        let spm: Int
        if pendingRematch {
            spm = sustainedSPM
            pendingRematch = false
        } else {
            spm = sustainedSPM
        }

        if let next = selectNextMatch(forSPM: spm) {
            await playTrack(next)
        }
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
    }

    func setSustainedSPMForTesting(_ spm: Int) {
        sustainedSPM = spm
    }
}
