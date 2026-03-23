# Phase 4: Core Loop (Free Run) - Research

**Researched:** 2026-03-20
**Domain:** BPM-matched song queuing, cadence-reactive playback orchestration, Spotify Web API player control
**Confidence:** HIGH

## Summary

This phase wires the existing CadenceService (live SPM + trend) and BPMCacheService (cached BPM per track) together through a new orchestration service that matches the runner's cadence to songs in their selected playlist. The core loop is: observe cadence -> detect sustained change -> query playlist for BPM-matched songs -> queue next song via Spotify Web API. All building blocks exist; the work is orchestration logic, sustained-change detection, tolerance UI, and skip-override behavior.

The Spotify Web API provides two viable approaches for playing matched songs: (1) `PUT /me/player/play` with a `uris` array to start a specific track immediately, and (2) `POST /me/player/queue` to add a track to the user's queue. The existing `SpotifyPlayerService.play(uri:contextURI:)` already uses approach (1). For this phase, approach (1) is preferred for the initial auto-play on run start, while approach (2) or a combination can handle "queue next song" behavior. However, Spotify's queue endpoint only adds to queue -- it cannot clear or reorder the queue -- so the cleanest approach is to use `PUT /me/player/play` with `uris` containing just the next matched track when the current song ends.

**Primary recommendation:** Create a `RunEngineService` that observes `CadenceService.currentSPM`, implements sustained-change detection with a configurable debounce window (~15-20s), queries `BPMCacheService` for BPM-matched tracks in the selected playlist, and controls playback via `SpotifyPlayerService`. Use `PUT /me/player/play` (not queue endpoint) for predictable single-track playback control.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- Match cadence to song BPM within tolerance, always including half (divide by 2) and double (multiply by 2) BPM variants (e.g., 170 SPM matches 170, 85, and 340 BPM songs)
- Song pool is the selected playlist only -- not all scanned playlists
- When no songs match within tolerance: play the closest available BPM match from the playlist (never silence)
- Auto-play on run start: when user taps "Start Run", immediately queue and play a matching song from the playlist
- Only switch songs after sustained cadence change (~15-20 seconds at a new level) -- brief pace changes don't trigger switches
- Queue the matched song for next, don't interrupt the current song -- current song plays to completion
- At natural song end (no cadence change): re-evaluate current cadence and pick the best BPM match for the next song
- No "up next" queue display -- keep the run UI clean and focused on cadence
- 3 named presets: Tight (+/-3 BPM), Normal (+/-7 BPM), Loose (+/-12 BPM)
- Control lives on RunView as a pre-run setting -- visible before tapping "Start Run"
- Default for first-time users: Normal (+/-7 BPM)
- Persist last-used tolerance setting between runs (UserDefaults or similar)
- Random selection from all matching songs in the playlist -- avoid playing the same song twice until pool is exhausted
- Skip button (existing MiniPlayerView) queues the next BPM-matched song, not the next playlist track
- During "Paused" cadence state (stopped at a light): keep playing current song, don't pause music
- When pool of unplayed matching songs is exhausted: reset played tracker and re-shuffle from all matches

### Claude's Discretion
- BPM matching service architecture and internal data structures
- Exact sustained-change detection threshold tuning
- How to intercept/override the existing skip behavior during a run
- Pre-run tolerance UI widget design (segmented control, picker, etc.)
- Error handling for Spotify API failures during song queuing

### Deferred Ideas (OUT OF SCOPE)
None -- discussion stayed within phase scope
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| BPM-02 | App queues songs whose BPM matches the runner's current cadence | RunEngineService orchestration: observe cadence -> query BPMCacheService for matching tracks -> play via SpotifyPlayerService |
| BPM-03 | Half/double BPM matching expands the matchable song pool | BPM matching function must check target SPM, SPM/2, and SPM*2 against each song's cached BPM within tolerance |
| BPM-04 | User can configure BPM tolerance (how tight the match needs to be) | Three presets (Tight/Normal/Loose) stored in UserDefaults, exposed as segmented control on RunView pre-run state |
| RUN-01 | Free run mode -- music adapts to the runner's natural pace | Full pipeline: CadenceService -> sustained change detection -> BPM matching -> Spotify playback, with song-end re-evaluation |
</phase_requirements>

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| SwiftUI | iOS 17+ | UI (RunView tolerance selector) | Already used throughout app |
| Observation (@Observable) | iOS 17+ | Reactive state for RunEngineService | Established project pattern |
| SwiftData | iOS 17+ | Query CachedBPM for BPM matching | Already used for BPM cache |
| Spotify Web API | Feb 2026 | Playback control (play, queue) | Already integrated via SpotifyPlayerService |
| UserDefaults | Foundation | Persist tolerance preference | Simplest persistence for single setting |
| Combine/AsyncSequence | Foundation | Cadence observation debouncing | Built-in, no external dependency needed |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| XCTest | Xcode 16+ | Unit tests for matching logic | Test BPM matching, sustained change detection, pool management |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| UserDefaults for tolerance | SwiftData model | Overkill for a single enum value; UserDefaults is simpler |
| PUT /me/player/play | POST /me/player/queue | Queue endpoint only appends, cannot clear/reorder; play endpoint gives full control |
| Timer-based song-end detection | Polling SpotifyPlayerService.currentTrack changes | Polling is already in place (3s interval); detecting track change is more reliable than computing duration remaining |

## Architecture Patterns

### Recommended Project Structure
```
BeatStep/
  Services/
    RunEngineService.swift      # NEW: orchestrates cadence -> matching -> playback
  Models/
    BPMTolerance.swift          # NEW: enum with Tight/Normal/Loose presets
  Views/
    Run/
      RunView.swift             # MODIFY: add tolerance selector, wire Start Run to engine
      TolerancePicker.swift     # NEW: segmented control for tolerance presets
    Player/
      MiniPlayerView.swift      # MODIFY: skip override during active run
```

### Pattern 1: RunEngineService as Orchestrator
**What:** A singleton `@Observable` service that owns the run lifecycle. It observes CadenceService, manages the song matching pipeline, tracks played songs, and controls Spotify playback. It is the single source of truth for "is a run active" and "what should play next".
**When to use:** Always -- this is the central coordination point.
**Example:**
```swift
@Observable
final class RunEngineService {
    static let shared = RunEngineService()

    // Observable state
    var isRunActive = false
    var tolerance: BPMTolerance = .normal
    var currentMatchedTrack: SpotifyTrack?

    // Private
    @ObservationIgnored private var playlistTracks: [SpotifyTrack] = []
    @ObservationIgnored private var playedTrackIDs: Set<String> = []
    @ObservationIgnored private var sustainedSPM: Int = 0
    @ObservationIgnored private var sustainedChangeTimer: Task<Void, Never>?
    @ObservationIgnored private var songEndMonitorTask: Task<Void, Never>?

    func startRun(playlist: SpotifyPlaylist, tracks: [SpotifyTrack]) async { ... }
    func stopRun() { ... }
    func skipToNextMatch() async { ... }

    // Internal for testing
    func findMatchingTracks(forSPM spm: Int) -> [SpotifyTrack] { ... }
}
```

### Pattern 2: Sustained Change Detection
**What:** Debounce cadence changes to prevent frenetic song switching. Only trigger a "new cadence level" event when SPM stays at a significantly different level for ~15-20 seconds.
**When to use:** Every cadence observation cycle.
**Example:**
```swift
// Observe CadenceService.currentSPM changes
// When SPM changes significantly (outside current tolerance range):
//   1. Start a 15-second timer
//   2. If SPM stays in the new range for the full duration -> commit as new sustained SPM
//   3. If SPM returns to old range before timer fires -> cancel timer
//   4. On sustained change: mark next song for BPM re-match (don't interrupt current)

private func onCadenceChanged(_ newSPM: Int) {
    let significantChange = abs(newSPM - sustainedSPM) > tolerance.range
    guard significantChange else { return }

    sustainedChangeTimer?.cancel()
    sustainedChangeTimer = Task {
        try? await Task.sleep(for: .seconds(17)) // ~15-20s midpoint
        guard !Task.isCancelled else { return }
        await commitSustainedChange(newSPM)
    }
}
```

### Pattern 3: BPM Matching with Half/Double
**What:** For a given SPM, find songs whose BPM is within tolerance of SPM, SPM/2, or SPM*2.
**When to use:** Every time a new song needs to be selected.
**Example:**
```swift
func findMatchingTracks(forSPM spm: Int) -> [SpotifyTrack] {
    let targets = [spm, spm / 2, spm * 2]
    let range = tolerance.range

    return playlistTracks.filter { track in
        guard let bpm = BPMCacheService.shared.getBPM(forTrackID: track.id) else { return false }
        return targets.contains { target in abs(bpm - target) <= range }
    }
}

// Fallback: if no matches, find closest BPM in playlist
func findClosestTrack(forSPM spm: Int) -> SpotifyTrack? {
    let targets = [spm, spm / 2, spm * 2]
    return playlistTracks
        .compactMap { track -> (SpotifyTrack, Int)? in
            guard let bpm = BPMCacheService.shared.getBPM(forTrackID: track.id) else { return nil }
            let minDist = targets.map { abs(bpm - $0) }.min() ?? Int.max
            return (track, minDist)
        }
        .min(by: { $0.1 < $1.1 })?
        .0
}
```

### Pattern 4: Song-End Detection via Polling
**What:** Detect when the current song ends by observing `SpotifyPlayerService.currentTrack` changes during polling. When the track ID changes (and we didn't initiate the change), re-evaluate cadence and queue the next match.
**When to use:** Continuously during an active run.
**Example:**
```swift
private func startSongEndMonitor() {
    songEndMonitorTask = Task { @MainActor [weak self] in
        var lastTrackID: String?
        while !Task.isCancelled {
            let currentID = SpotifyPlayerService.shared.currentTrack?.id
            if let currentID, currentID != lastTrackID, lastTrackID != nil {
                // Song changed naturally -- queue next match
                await self?.queueNextMatch()
            }
            lastTrackID = currentID
            try? await Task.sleep(for: .seconds(2))
        }
    }
}
```

### Pattern 5: Skip Override During Run
**What:** During an active run, the MiniPlayerView skip button should call `RunEngineService.skipToNextMatch()` instead of `SpotifyPlayerService.skipNext()`.
**When to use:** Only when `RunEngineService.isRunActive == true`.
**Example:**
```swift
// In MiniPlayerView:
Button {
    if RunEngineService.shared.isRunActive {
        Task { await RunEngineService.shared.skipToNextMatch() }
    } else {
        SpotifyPlayerService.shared.skipNext()
    }
} label: {
    Image(systemName: "forward.fill")
}
```

### Anti-Patterns to Avoid
- **Interrupting current song on cadence change:** Never stop the current song mid-play. Always queue the next match and let the current song finish.
- **Using Spotify queue endpoint for primary playback control:** The queue endpoint only appends; you cannot clear it. Use `PUT /me/player/play` with specific URIs for deterministic control.
- **Observing cadence with no debounce:** Raw SPM fluctuates constantly. Without sustained-change detection, you'll trigger re-matching every second.
- **Storing played-track history in persistent storage:** The played-tracks set is session-scoped. Reset it when the run ends or when the pool exhausts. UserDefaults or SwiftData is unnecessary.
- **Building a complex queue system:** The user said no "up next" display. Keep it simple: one "next track" decision at a time.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Sustained change detection | Custom NSTimer/RunLoop debouncing | Task.sleep with cancellation | Structured concurrency handles cancellation cleanly; no retain cycle risk |
| BPM data lookup | Re-fetching BPM from GetSongBPM at runtime | BPMCacheService.shared.getBPM() | BPM data is already cached from Phase 2 scanning |
| Playback state monitoring | Custom WebSocket/event system | SpotifyPlayerService polling (already 3s) | Polling is already implemented and sufficient |
| Tolerance persistence | SwiftData model or Keychain | UserDefaults with RawRepresentable enum | Single enum value; UserDefaults is the standard iOS pattern |
| Random selection without repeats | Custom shuffle algorithm | Fisher-Yates on filtered array + Set<String> tracker | Standard approach; Set tracks played IDs, filter before random pick |

**Key insight:** Every infrastructure piece exists. This phase is pure orchestration -- connecting CadenceService, BPMCacheService, and SpotifyPlayerService through a new RunEngineService. No new external dependencies, no new API integrations, no new data models beyond a simple enum.

## Common Pitfalls

### Pitfall 1: Race Condition Between Skip and Song-End Detection
**What goes wrong:** User taps skip while the song-end monitor also detects a track change, causing two songs to be queued in rapid succession.
**Why it happens:** Both the skip action and the polling-based song-end monitor trigger `queueNextMatch()`.
**How to avoid:** Use a serial gate (e.g., an actor or a simple Bool flag `isQueueingNext`) that prevents concurrent song selections. The skip action sets the flag, queues a song, then clears it. The song-end monitor checks the flag before acting.
**Warning signs:** Songs skipping twice rapidly, or a matched song playing for 1-2 seconds then switching.

### Pitfall 2: Empty Match Pool on Small Playlists
**What goes wrong:** A playlist with 15 songs might have only 2-3 in the BPM range. The "no repeat" tracker exhausts the pool after 2 songs, then resets, creating obvious repetition.
**Why it happens:** Small playlists combined with narrow tolerance.
**How to avoid:** When the pool has fewer than 3 unplayed matches, automatically widen to include the closest matches or silently reset the played tracker. Document this as expected behavior.
**Warning signs:** Same 2-3 songs playing on loop during testing.

### Pitfall 3: Spotify API Rate Limiting During Rapid Cadence Changes
**What goes wrong:** If sustained-change detection is too aggressive (short timer), rapid `PUT /me/player/play` calls hit Spotify's rate limit (429).
**Why it happens:** Spotify rate limits are undocumented but typically ~30 requests/minute for player endpoints.
**How to avoid:** The 15-20 second sustained-change window inherently rate-limits. Additionally, never call the play endpoint more than once per 5 seconds as a safety floor.
**Warning signs:** 429 responses in debug logs, songs failing to start.

### Pitfall 4: BPMCacheService @MainActor Constraint
**What goes wrong:** `BPMCacheService.shared` is `@MainActor`. Calling `getBPM()` from a background Task without `await MainActor.run {}` causes a compile error or runtime crash.
**Why it happens:** SwiftData's ModelContext is not sendable; the service is correctly constrained to MainActor.
**How to avoid:** Either (a) load all playlist BPMs into an in-memory dictionary at run start (recommended -- avoids repeated SwiftData queries), or (b) always call from MainActor context.
**Warning signs:** Purple runtime warnings about main actor isolation, or compilation errors about Sendable.

### Pitfall 5: Song-End Detection Misses Due to Polling Gap
**What goes wrong:** SpotifyPlayerService polls every 3 seconds. If a song ends and Spotify auto-plays the next playlist track before the next poll, the user hears a non-matched song for up to 3 seconds.
**Why it happens:** Polling is inherently laggy. Spotify has its own queue behavior.
**How to avoid:** When starting a run, play tracks using `PUT /me/player/play` with only a single URI (not a context_uri). This way, when the song ends, Spotify has nothing queued and either pauses or repeats. The poll detects this and the RunEngine queues the next match. Alternatively, pre-queue the next match ~10 seconds before the current song ends by estimating remaining time from `durationMs` and playback start time.
**Warning signs:** Brief moments of unexpected songs between matched tracks.

### Pitfall 6: CadenceService Singleton Shared State Between Runs
**What goes wrong:** `CadenceService.shared` retains state from a previous run. If the user stops and restarts quickly, stale cadence data influences the first song match.
**Why it happens:** Singleton pattern means state persists across the app lifecycle.
**How to avoid:** `RunEngineService.startRun()` should read `CadenceService.currentSPM` fresh but not rely on `trend` history from before the run started. The sustained-change detection should start fresh each run.
**Warning signs:** First song of a new run matching the cadence from the end of the previous run.

## Code Examples

### BPMTolerance Enum
```swift
// Source: Project pattern (UserDefaults + RawRepresentable)
enum BPMTolerance: String, CaseIterable {
    case tight = "tight"
    case normal = "normal"
    case loose = "loose"

    var range: Int {
        switch self {
        case .tight: return 3
        case .normal: return 7
        case .loose: return 12
        }
    }

    var displayName: String {
        switch self {
        case .tight: return "Tight"
        case .normal: return "Normal"
        case .loose: return "Loose"
        }
    }

    var description: String {
        "±\(range) BPM"
    }

    static var defaultTolerance: BPMTolerance { .normal }

    // UserDefaults persistence
    private static let key = "selectedBPMTolerance"

    static var saved: BPMTolerance {
        guard let raw = UserDefaults.standard.string(forKey: key),
              let value = BPMTolerance(rawValue: raw) else {
            return .defaultTolerance
        }
        return value
    }

    func save() {
        UserDefaults.standard.set(rawValue, forKey: BPMTolerance.key)
    }
}
```

### Spotify Play Specific Track (existing pattern)
```swift
// Source: SpotifyPlayerService.play(uri:contextURI:) -- already in codebase
// PUT /me/player/play with uris array plays a specific track
// Body: {"uris": ["spotify:track:xyz"]}
// No context_uri means Spotify won't auto-advance to next playlist track
func playTrack(_ track: SpotifyTrack) {
    SpotifyPlayerService.shared.play(uri: track.uri)
    // NOTE: Do NOT pass contextURI -- we control what plays next
}
```

### Loading Playlist BPMs Into Memory
```swift
// Source: BPMCacheService pattern + MainActor constraint
// Load at run start to avoid repeated SwiftData queries
@MainActor
func loadPlaylistBPMs(tracks: [SpotifyTrack]) -> [String: Int] {
    var bpmMap: [String: Int] = [:]
    for track in tracks {
        if let bpm = BPMCacheService.shared.getBPM(forTrackID: track.id) {
            bpmMap[track.id] = bpm
        }
    }
    return bpmMap
}
```

### Tolerance Picker UI
```swift
// Source: SwiftUI Picker with segmented style (standard iOS pattern)
Picker("BPM Match", selection: $tolerance) {
    ForEach(BPMTolerance.allCases, id: \.self) { level in
        Text("\(level.displayName) (\(level.description))")
            .tag(level)
    }
}
.pickerStyle(.segmented)
.onChange(of: tolerance) { _, newValue in
    newValue.save()
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| SPTAppRemote for playback | Web API player (PUT /me/player/play) | Phase 02-02 | All playback goes through REST API, no SDK dependency |
| Spotify Audio Features for BPM | GetSongBPM via Cloudflare Worker proxy | Phase 02-03 | BPM cached in SwiftData, lookup is local |
| tracks field in playlist API | items field | Feb 2026 | Already handled in existing code (PlaylistTrackItem) |

**Deprecated/outdated:**
- SPTAppRemote: Replaced with Web API in Phase 02-02
- Spotify Audio Features endpoint: Restricted for new apps since Nov 2024; using GetSongBPM instead

## Open Questions

1. **Song-end detection strategy: polling vs. duration estimation**
   - What we know: SpotifyPlayerService polls every 3 seconds; SpotifyTrack has `durationMs`
   - What's unclear: Whether polling gap (up to 3s) will cause noticeable non-matched songs between tracks
   - Recommendation: Start with polling-based detection (simplest). If testing reveals gaps, add duration-based pre-queuing as an enhancement. The user decided "current song plays to completion" which gives us natural buffer time.

2. **Spotify queue behavior when playing single URIs**
   - What we know: `PUT /me/player/play` with `uris: ["spotify:track:xyz"]` plays that track. What happens after it ends is unclear -- Spotify may pause, or may resume user's previous context.
   - What's unclear: Whether Spotify auto-plays from the user's queue or stops
   - Recommendation: Test on device. If Spotify auto-plays unwanted tracks, use the `POST /me/player/queue` endpoint to pre-queue the next match before current song ends, giving RunEngine control.

3. **Cadence detection during phone-in-pocket scenarios**
   - What we know: CMPedometer works in background and pocket
   - What's unclear: Whether `currentSPM` accuracy degrades significantly when phone is in an armband vs. shorts pocket
   - Recommendation: This is a Phase 3 concern (already resolved). Trust the 5-second rolling average. The 15-20s sustained-change window adds further smoothing.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | XCTest (Xcode 16+) |
| Config file | BeatStepTests target in project.yml |
| Quick run command | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BeatStepTests` |
| Full suite command | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16'` |

### Phase Requirements to Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| BPM-02 | findMatchingTracks returns tracks within tolerance of current SPM | unit | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BeatStepTests/RunEngineServiceTests/testMatchingTracksReturnsCorrectBPMRange` | No - Wave 0 |
| BPM-03 | Half/double matching: 170 SPM matches 85 and 340 BPM songs | unit | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BeatStepTests/RunEngineServiceTests/testHalfDoubleMatching` | No - Wave 0 |
| BPM-04 | Tolerance presets return correct range values, persist to UserDefaults | unit | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BeatStepTests/BPMToleranceTests` | No - Wave 0 |
| RUN-01 | Sustained change detection triggers re-match only after debounce window | unit | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BeatStepTests/RunEngineServiceTests/testSustainedChangeDetection` | No - Wave 0 |
| BPM-02 | Fallback to closest BPM when no exact match | unit | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BeatStepTests/RunEngineServiceTests/testFallbackToClosestBPM` | No - Wave 0 |
| BPM-02 | No-repeat selection exhausts pool before reshuffling | unit | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BeatStepTests/RunEngineServiceTests/testNoRepeatPoolExhaustion` | No - Wave 0 |

### Sampling Rate
- **Per task commit:** `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BeatStepTests`
- **Per wave merge:** Full suite
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] `BeatStepTests/RunEngineServiceTests.swift` -- covers BPM-02, BPM-03, RUN-01 (matching logic, sustained change, pool management)
- [ ] `BeatStepTests/BPMToleranceTests.swift` -- covers BPM-04 (enum values, persistence)
- [ ] No new framework installs needed -- XCTest already configured

## Sources

### Primary (HIGH confidence)
- Spotify Web API: [Add to Queue](https://developer.spotify.com/documentation/web-api/reference/add-to-queue) - POST /me/player/queue endpoint details
- Spotify Web API: [Start Playback](https://developer.spotify.com/documentation/web-api/reference/start-a-users-playback) - PUT /me/player/play with uris/offset
- Spotify Web API: [Get Queue](https://developer.spotify.com/documentation/web-api/reference/get-queue) - GET /me/player/queue
- Spotify Web API: [Feb 2026 Changelog](https://developer.spotify.com/documentation/web-api/references/changes/february-2026) - tracks->items rename, search limit changes
- Project codebase: CadenceService.swift, BPMCacheService.swift, SpotifyPlayerService.swift, RunView.swift (direct code review)

### Secondary (MEDIUM confidence)
- Spotify rate limiting behavior (~30 req/min for player endpoints) - community reports, not officially documented

### Tertiary (LOW confidence)
- Spotify behavior when single-URI playback ends (pause vs. auto-play) - needs device testing

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - no new dependencies, all existing project patterns
- Architecture: HIGH - clear orchestration pattern, all integration points documented in code
- Pitfalls: HIGH - based on direct code review of existing services and known Spotify API constraints
- Spotify API behavior: MEDIUM - queue endpoint documented, but edge cases around playback end need device testing

**Research date:** 2026-03-20
**Valid until:** 2026-04-20 (stable domain, no fast-moving dependencies)
