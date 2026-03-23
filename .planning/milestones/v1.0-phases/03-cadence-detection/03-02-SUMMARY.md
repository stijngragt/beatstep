---
phase: 03-cadence-detection
plan: 02
subsystem: ui
tags: [swiftui, run-screen, cadence-display, dark-ui, navigation, cmpedometer]

# Dependency graph
requires:
  - phase: 03-01
    provides: CadenceService with CMPedometer, smoothed SPM, trend detection, state machine
  - phase: 01-02
    provides: MiniPlayerView for embedded playback controls
provides:
  - RunView with dark glanceable UI, hero SPM display, trend arrows, start/stop controls
  - CadenceDisplayView reusable component for hero cadence number and trend indicator
  - Navigation chain from PlaylistDetailView to RunView via "Run with this Playlist"
  - Idle timer management during active run sessions
affects: [04-beat-matching, 05-polish]

# Tech tracking
tech-stack:
  added: []
  patterns: [state-driven-ui, dark-theme-run-screen, hero-metric-display]

key-files:
  created:
    - BeatStep/Views/Run/RunView.swift
    - BeatStep/Views/Run/CadenceDisplayView.swift
  modified:
    - BeatStep/Views/Library/PlaylistDetailView.swift
    - project.yml
    - BeatStep/Resources/Info.plist
    - BeatStep.xcodeproj/project.pbxproj

key-decisions:
  - "UILaunchScreen must be in project.yml info properties to prevent compatibility screen size after xcodegen regen"

patterns-established:
  - "Dark theme run screen: Color.black background with .preferredColorScheme(.dark) for outdoor glanceability"
  - "State-driven UI: switch on CadenceService.state for idle/detecting/active/paused display"
  - "Hero metric pattern: large monospaced font (~72-80pt) for primary numeric display"

requirements-completed: [CAD-03]

# Metrics
duration: multi-session
completed: 2026-03-20
---

# Phase 03 Plan 02: Run UI Summary

**Dark glanceable RunView with hero SPM display, trend arrows, state-driven UI, and playlist-to-run navigation chain**

## Performance

- **Duration:** Multi-session (includes physical device verification)
- **Started:** 2026-03-20
- **Completed:** 2026-03-20
- **Tasks:** 3 (2 auto + 1 human-verify checkpoint)
- **Files modified:** 6

## Accomplishments
- Built RunView with dark high-contrast design showing hero cadence number, trend arrows, and state-driven displays (idle/detecting/active/paused)
- Created reusable CadenceDisplayView with large monospaced SPM and trend indicator arrows
- Wired navigation from PlaylistDetailView to RunView via "Run with this Playlist" toolbar button
- Embedded MiniPlayerView for continuous playback controls during runs
- Implemented idle timer management (screen stays awake during runs)
- Verified all 12 verification steps on physical iPhone hardware

## Task Commits

Each task was committed atomically:

1. **Task 1: Create RunView and CadenceDisplayView** - `0d7b3b0` (feat)
2. **Task 2: Wire RunView into navigation from PlaylistDetailView** - `673e62d` (feat)
3. **Task 3: Verify cadence detection and run UI on physical device** - checkpoint approved, no code commit
4. **UILaunchScreen fix** - `e35053d` (fix, deviation)

## Files Created/Modified
- `BeatStep/Views/Run/RunView.swift` - Main run screen with dark UI, state-driven display, start/stop controls, idle timer management
- `BeatStep/Views/Run/CadenceDisplayView.swift` - Hero SPM number and trend arrow indicator component
- `BeatStep/Views/Library/PlaylistDetailView.swift` - Added "Run with this Playlist" toolbar button with NavigationLink
- `project.yml` - Added UILaunchScreen to info properties
- `BeatStep/Resources/Info.plist` - UILaunchScreen entry restored
- `BeatStep.xcodeproj/project.pbxproj` - Updated with new files and regenerated config

## Decisions Made
- UILaunchScreen must be explicitly set in project.yml info properties; xcodegen regeneration strips it if not present, causing the app to render at a smaller compatibility screen size

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Restored UILaunchScreen in Info.plist after xcodegen regeneration**
- **Found during:** Task 3 (human verification on physical device)
- **Issue:** xcodegen regeneration in Task 2 stripped UILaunchScreen from Info.plist, causing the app to render at a smaller compatibility screen size on physical iPhone
- **Fix:** Added `UILaunchScreen: {}` to project.yml info properties and regenerated with xcodegen
- **Files modified:** project.yml, BeatStep/Resources/Info.plist, BeatStep.xcodeproj/project.pbxproj
- **Verification:** App renders at full screen size on physical iPhone
- **Committed in:** e35053d

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** Essential fix for correct screen rendering. No scope creep.

## Issues Encountered
- CMPedometer requires physical device for testing (simulator cannot detect cadence) -- handled by checkpoint:human-verify task on real hardware
- xcodegen regeneration stripped UILaunchScreen -- resolved by adding to project.yml (see deviation above)

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- Cadence detection system complete: CadenceService (plan 01) + RunView UI (plan 02)
- Runner can navigate from playlist to run screen, start cadence detection, see live SPM with trend
- Ready for Phase 4: Beat Matching (tempo adjustment based on cadence vs track BPM)
- All Phase 3 requirements (CAD-03) fulfilled

---
*Phase: 03-cadence-detection*
*Completed: 2026-03-20*
