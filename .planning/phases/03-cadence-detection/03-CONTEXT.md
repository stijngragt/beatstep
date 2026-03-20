# Phase 3: Cadence Detection - Context

**Gathered:** 2026-03-20
**Status:** Ready for planning

<domain>
## Phase Boundary

Detect running cadence in real-time via CMPedometer and display it on a dedicated run screen with smoothing and trend indication. This phase introduces the run session concept (start/stop) and the run UI. Song matching based on cadence comes in Phase 4 -- this phase only detects and displays.

</domain>

<decisions>
## Implementation Decisions

### Run session lifecycle
- Explicit "Start Run" button to begin cadence detection -- no auto-detect from motion
- Dedicated run screen accessible from a new tab or prominent entry point on the main screen
- Pre-run flow: user selects playlist from library first, then navigates to run screen showing selected playlist context, then taps "Start Run"
- Explicit "Stop Run" button to end session -- clean return to normal app, no summary screen
- Run session is a simple start/stop concept -- no pause/resume, no stats persistence

### Cadence display & run UI
- Cadence (SPM) number is the hero element -- large, front and center on the run screen
- Trend indicator uses arrow icons: up arrow (speeding up), horizontal (steady), down arrow (slowing down)
- Dark background with bright text for outdoor visibility and glanceability while running
- Mini-player remains visible at bottom of run screen for track info and playback controls
- Screen stays awake (prevent auto-lock) during an active run via `UIApplication.shared.isIdleTimerDisabled`

### Smoothing behavior
- Rolling average over ~5 seconds for balanced responsiveness -- reflects real pace changes within a few seconds without jittering on single awkward steps
- Brief "Detecting..." settling period (~5 seconds) at run start before showing cadence numbers
- Trend indicator also uses sustained-change smoothing -- only shows "speeding up" / "slowing down" after cadence shifts consistently for ~5+ seconds, prevents arrow flickering
- When runner stops (no steps for ~5 seconds), show "Paused" state instead of cadence dropping to 0; cadence resumes when movement resumes

### Background & permissions
- Motion/pedometer permission requested on first "Start Run" tap -- user understands why in that moment
- If permission denied: block run start, show clear explanation ("BeatStep needs motion access to detect your cadence"), offer button to open iOS Settings
- Cadence detection continues in background via CMPedometer -- essential for Phase 4 song matching
- Motion permission only -- no location permission needed (privacy-first, aligns with "no workout tracking")

### Claude's Discretion
- Exact run screen layout and typography sizing
- Tab bar design or navigation pattern for accessing the run screen
- "Detecting..." animation or indicator design
- "Paused" state visual design
- Error handling for CMPedometer failures
- Run screen color palette beyond "dark background, bright text"

</decisions>

<specifics>
## Specific Ideas

- Run screen should feel like a running companion you can glance at, not an app you interact with mid-run
- The "turn it on and go" philosophy extends here: pick playlist, start run, pocket the phone, glance occasionally
- Dark high-contrast design inspired by running apps (Nike Run Club, Strava) for sunlight readability
- Cadence is the hero metric -- it's what makes BeatStep different from a regular music player

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- `MiniPlayerView` (Views/Player/MiniPlayerView.swift): Already shows track + BPM, will be embedded in run screen
- `SpotifyPlayerService.shared`: Playback control singleton, run screen uses for play/pause/skip
- `BPMCacheService.shared`: Provides current track BPM for potential cadence-vs-BPM display in Phase 4
- `AudioSessionService.shared`: Audio session already configured for background playback
- `ContentView.swift`: Main app structure with NavigationStack + MiniPlayerView overlay -- run screen integrates here

### Established Patterns
- Singleton services with `.shared` pattern (SpotifyPlayerService, BPMCacheService, LibraryScanService)
- `@Observable` / `@Environment` for SwiftUI state
- Async/await for all service operations
- `safeAreaInset` for mini-player space reservation

### Integration Points
- `ContentView` -- add run screen tab/navigation entry point
- `PlaylistDetailView` or `PlaylistListView` -- add "Run with this playlist" flow to connect playlist selection to run screen
- New `CadenceService` singleton following established service patterns
- New `RunView` / `RunScreen` as primary run UI

</code_context>

<deferred>
## Deferred Ideas

None -- discussion stayed within phase scope

</deferred>

---

*Phase: 03-cadence-detection*
*Context gathered: 2026-03-20*
