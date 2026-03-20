# Phase 4: Core Loop (Free Run) - Context

**Gathered:** 2026-03-20
**Status:** Ready for planning

<domain>
## Phase Boundary

Wire cadence detection to BPM-matched song queuing — the core value proposition. When the runner starts a run, the app auto-plays a song from their selected playlist that matches their cadence. As cadence changes, the next song is matched accordingly. This phase delivers the complete free run experience. Guided run mode (target pace) comes in Phase 5.

</domain>

<decisions>
## Implementation Decisions

### Song matching logic
- Match cadence to song BPM within tolerance, always including half (÷2) and double (×2) BPM variants (e.g., 170 SPM matches 170, 85, and 340 BPM songs)
- Song pool is the selected playlist only — not all scanned playlists
- When no songs match within tolerance: play the closest available BPM match from the playlist (never silence)
- Auto-play on run start: when user taps "Start Run", immediately queue and play a matching song from the playlist

### Song transition timing
- Only switch songs after sustained cadence change (~15-20 seconds at a new level) — brief pace changes don't trigger switches
- Queue the matched song for next, don't interrupt the current song — current song plays to completion
- At natural song end (no cadence change): re-evaluate current cadence and pick the best BPM match for the next song
- No "up next" queue display — keep the run UI clean and focused on cadence

### BPM tolerance control
- 3 named presets: Tight (±3 BPM), Normal (±7 BPM), Loose (±12 BPM)
- Control lives on RunView as a pre-run setting — visible before tapping "Start Run"
- Default for first-time users: Normal (±7 BPM)
- Persist last-used tolerance setting between runs (UserDefaults or similar)

### Queue & playback behavior
- Random selection from all matching songs in the playlist — avoid playing the same song twice until pool is exhausted
- Skip button (existing MiniPlayerView) queues the next BPM-matched song, not the next playlist track
- During "Paused" cadence state (stopped at a light): keep playing current song, don't pause music
- When pool of unplayed matching songs is exhausted: reset played tracker and re-shuffle from all matches

### Claude's Discretion
- BPM matching service architecture and internal data structures
- Exact sustained-change detection threshold tuning
- How to intercept/override the existing skip behavior during a run
- Pre-run tolerance UI widget design (segmented control, picker, etc.)
- Error handling for Spotify API failures during song queuing

</decisions>

<specifics>
## Specific Ideas

- This is the moment BeatStep becomes BeatStep — the core loop is the product
- "Turn it on and go" fully realized: pick playlist → set tolerance → Start Run → pocket phone → run with music matching your stride
- The matching should feel magical but not frenetic — songs change with your sustained pace, not every stride variation
- Skip = "I don't like this song, give me another match" — respects the runner's taste within the BPM constraint

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- `CadenceService.shared`: Live `currentSPM` (Int) and `trend` (CadenceTrend) observables, `state` (CadenceState) for idle/detecting/active/paused
- `BPMCacheService.shared`: `getBPM(forTrackID:)` returns cached BPM for any track
- `BPMDiscoveryService.shared`: `discoverTracks(atBPM:)` for catalog search (deferred to Phase 5 for guided mode)
- `SpotifyPlayerService.shared`: `currentTrack`, `isPaused`, `togglePlayPause()`, `skipNext()` — playback control
- `SpotifyAPIService.shared`: Authenticated Spotify API requests
- `RunView`: Dark run screen with hero cadence display, start/stop controls, MiniPlayerView at bottom
- `MiniPlayerView`: Track info + BPM display + play/pause + skip controls

### Established Patterns
- Singleton services with `.shared` pattern
- `@Observable` for reactive SwiftUI state
- Async/await for all service operations
- SwiftData for persistent caching (BPM data via CachedBPM model)

### Integration Points
- `RunView` — add tolerance selector to pre-run state, wire Start Run to auto-play matched song
- `CadenceService.currentSPM` — observe for sustained changes to trigger song matching
- `SpotifyPlayerService` — override skip behavior during run to queue BPM-matched song instead
- `BPMCacheService` — query playlist tracks by BPM range for matching
- New `RunEngineService` or similar — orchestrates cadence observation → BPM matching → Spotify queuing

</code_context>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 04-core-loop-free-run*
*Context gathered: 2026-03-20*
