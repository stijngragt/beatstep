---
phase: 04-core-loop-free-run
plan: 02
subsystem: ui
tags: [swiftui, run-view, tolerance-picker, mini-player, skip-override, spotify-playback]

# Dependency graph
requires:
  - phase: 04-core-loop-free-run
    provides: RunEngineService orchestrator and BPMTolerance model (Plan 01)
  - phase: 03-cadence-detection
    provides: RunView dark UI and CadenceDisplayView
  - phase: 01-spotify-integration
    provides: MiniPlayerView with skip button and SpotifyPlayerService
provides:
  - TolerancePicker segmented control for BPM tolerance presets
  - RunView wired to RunEngineService with Start/Stop run controls
  - MiniPlayerView skip override routing through RunEngineService during active run
  - PlaylistDetailView passing loaded tracks to RunView for BPM matching
affects: [05-01 (guided run mode will extend RunView with target BPM controls)]

# Tech tracking
tech-stack:
  added: []
  patterns: [conditional-skip-routing, pre-run-settings-ui, engine-ui-binding]

key-files:
  created:
    - BeatStep/Views/Run/TolerancePicker.swift
  modified:
    - BeatStep/Views/Run/RunView.swift
    - BeatStep/Views/Player/MiniPlayerView.swift
    - BeatStep/Views/Library/PlaylistDetailView.swift

key-decisions:
  - "Tolerance picker shown only in idle state (pre-run setting, not adjustable mid-run)"
  - "Skip button conditionally routes to RunEngineService.skipToNextMatch() during active run"
  - "RunView onDisappear calls stopRun() to clean up if user navigates away mid-run"

patterns-established:
  - "Conditional service routing: UI action delegates to different service based on run state"
  - "Pre-run settings pattern: configuration UI visible only before run starts"

requirements-completed: [BPM-02, BPM-04, RUN-01]

# Metrics
duration: multi-session
completed: 2026-03-20
---

# Phase 4 Plan 2: UI Wiring Summary

**RunView wired to RunEngineService with tolerance picker, conditional skip routing in MiniPlayerView, and end-to-end device-verified free run loop**

## Performance

- **Duration:** Multi-session (code tasks + device verification)
- **Started:** 2026-03-20
- **Completed:** 2026-03-20
- **Tasks:** 3 (2 auto + 1 human-verify)
- **Files modified:** 5

## Accomplishments
- TolerancePicker component with segmented Tight/Normal/Loose control and UserDefaults persistence
- RunView integrated with RunEngineService: Start Run triggers both cadence detection and BPM-matched playback, Stop Run cleans up both
- MiniPlayerView skip button conditionally routes through RunEngineService during active run for BPM-matched next song
- PlaylistDetailView passes loaded tracks to RunView enabling BPM matching from playlist content
- End-to-end free run core loop verified on physical device

## Task Commits

Each task was committed atomically:

1. **Task 1: Wire RunView with tolerance picker and engine controls** - `9270bc1` (feat)
2. **Task 2: Override MiniPlayerView skip during active run** - `83dcaae` (feat)
3. **Task 3: Verify complete free run core loop on device** - Human-verify checkpoint (approved)

**Plan metadata:** (pending)

## Files Created/Modified
- `BeatStep/Views/Run/TolerancePicker.swift` - Segmented control for BPM tolerance presets (Tight/Normal/Loose)
- `BeatStep/Views/Run/RunView.swift` - Added tracks parameter, tolerance picker in idle state, Start/Stop wired to RunEngineService
- `BeatStep/Views/Player/MiniPlayerView.swift` - Skip button routes through RunEngineService.skipToNextMatch() during active run
- `BeatStep/Views/Library/PlaylistDetailView.swift` - Passes loaded tracks to RunView via navigation
- `BeatStep.xcodeproj/project.pbxproj` - Updated with new TolerancePicker file

## Decisions Made
- Tolerance picker shown only in idle state (pre-run setting, hidden during active run)
- Skip button conditionally routes to RunEngineService.skipToNextMatch() during active run, falls back to SpotifyPlayerService.skipNext() otherwise
- RunView onDisappear calls stopRun() as cleanup safety net for mid-run navigation

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- Phase 4 complete: core free run loop fully functional and device-verified
- Ready for Phase 5: Guided Run + Polish (target pace mode, warm-up/cool-down ramps, smart song selection)
- RunEngineService provides extensible foundation for guided run mode

## Self-Check: PASSED

All 4 key files verified on disk. Both task commits (9270bc1, 83dcaae) verified in git log.

---
*Phase: 04-core-loop-free-run*
*Completed: 2026-03-20*
