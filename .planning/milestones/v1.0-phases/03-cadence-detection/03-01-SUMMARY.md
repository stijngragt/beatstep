---
phase: 03-cadence-detection
plan: 01
subsystem: services
tags: [coremotion, cmpedometer, cadence, smoothing, swift, observable]

# Dependency graph
requires:
  - phase: 01-spotify-integration
    provides: "@Observable singleton service pattern (SpotifyPlayerService)"
provides:
  - "CadenceService singleton with real-time cadence detection"
  - "CadenceState and CadenceTrend enums for run session state"
  - "Rolling-average smoothing and trend detection logic"
  - "CoreMotion framework integration"
affects: [03-cadence-detection, 04-song-matching]

# Tech tracking
tech-stack:
  added: [CoreMotion.framework, CMPedometer]
  patterns: [rolling-window-smoothing, state-machine, lazy-pedometer-init]

key-files:
  created:
    - BeatStep/Services/CadenceService.swift
    - BeatStep/Models/RunSession.swift
    - BeatStepTests/CadenceServiceTests.swift
    - BeatStepTests/Mocks/MockPedometerData.swift
  modified:
    - project.yml

key-decisions:
  - "CMPedometer created lazily (optional) to avoid privacy crash when @Observable singleton is instantiated during tests"
  - "@ObservationIgnored on all private stored properties to avoid @Observable macro conflicts with tuples and let constants"
  - "processCadenceSample has internal access for direct unit testing without needing CMPedometer mocks"
  - "Secrets.example.swift excluded from build sources to fix pre-existing duplicate symbol error"

patterns-established:
  - "Lazy CMPedometer: created on startDetecting(), not init, to avoid privacy prompts at app launch"
  - "Internal test hook: expose processing methods as internal for testability without protocol overhead"

requirements-completed: [CAD-01, CAD-02]

# Metrics
duration: 8min
completed: 2026-03-20
---

# Phase 3 Plan 1: Cadence Detection Service Summary

**CadenceService with CMPedometer integration, 5-second rolling average smoothing, trend detection, and idle/detecting/active/paused state machine**

## Performance

- **Duration:** 8 min
- **Started:** 2026-03-20T14:53:06Z
- **Completed:** 2026-03-20T15:01:22Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments
- CadenceService singleton detects running cadence via CMPedometer with rolling 5-second smoothing window
- Trend detection with sustained-change logic (>5 SPM delta over history window)
- State machine handles idle/detecting/active/paused transitions with inactivity monitor
- 9 unit tests covering SPM computation, rolling average, pruning, state transitions, trend detection, and reset
- CoreMotion framework dependency and NSMotionUsageDescription configured in project.yml

## Task Commits

Each task was committed atomically:

1. **Task 1: Create RunSession model and CadenceService with tests** - `a9de91e` (test: RED) + `cbbbf3f` (feat: GREEN)
2. **Task 2: Add CoreMotion dependency to project.yml** - `b158ee7` (chore)

_Note: Task 1 followed TDD with RED (failing tests) and GREEN (implementation) commits._

## Files Created/Modified
- `BeatStep/Services/CadenceService.swift` - @Observable singleton wrapping CMPedometer with smoothing, trend, state machine
- `BeatStep/Models/RunSession.swift` - CadenceState and CadenceTrend enums
- `BeatStepTests/CadenceServiceTests.swift` - 9 unit tests for smoothing, trend, state transitions
- `BeatStepTests/Mocks/MockPedometerData.swift` - Helper for generating test cadence sample data
- `project.yml` - Added CoreMotion.framework dependency, NSMotionUsageDescription, excluded Secrets.example.swift

## Decisions Made
- CMPedometer stored as optional and created lazily on `startDetecting()` to avoid iOS privacy crash during test host app launch
- All private stored properties marked `@ObservationIgnored` to prevent @Observable macro conflicts with tuple arrays and let constants
- `processCadenceSample(_:at:)` exposed with internal access for direct unit testing without needing CMPedometer mocks or protocol abstractions
- Fallback cadence calculation from step count delta when CMPedometerData.currentCadence is nil

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Fixed Secrets.example.swift duplicate symbol build error**
- **Found during:** Task 1 (build for tests)
- **Issue:** Both Secrets.swift and Secrets.example.swift compile, causing "Invalid redeclaration of 'Secrets'" error
- **Fix:** Excluded Secrets.example.swift from sources in project.yml
- **Files modified:** project.yml
- **Verification:** Build succeeds
- **Committed in:** cbbbf3f (part of Task 1 GREEN commit)

**2. [Rule 3 - Blocking] Added NSMotionUsageDescription early for test execution**
- **Found during:** Task 1 (test execution)
- **Issue:** Test host app crashed with "attempted to access privacy-sensitive data without a usage description" when CadenceService was instantiated
- **Fix:** Added NSMotionUsageDescription to project.yml Info.plist properties (was planned for Task 2 but needed for Task 1 tests)
- **Files modified:** project.yml
- **Verification:** Tests run without privacy crash
- **Committed in:** cbbbf3f (part of Task 1 GREEN commit)

**3. [Rule 3 - Blocking] Lazy CMPedometer initialization for @Observable compatibility**
- **Found during:** Task 1 (GREEN implementation)
- **Issue:** `lazy var` is not compatible with @Observable macro; `let` with immediate CMPedometer init triggers privacy prompt at singleton creation
- **Fix:** Made pedometer an optional property created on-demand in startDetecting(); marked all private properties @ObservationIgnored
- **Files modified:** BeatStep/Services/CadenceService.swift
- **Verification:** Build and all 9 tests pass
- **Committed in:** cbbbf3f (part of Task 1 GREEN commit)

---

**Total deviations:** 3 auto-fixed (3 blocking)
**Impact on plan:** All auto-fixes necessary for correct compilation and test execution. No scope creep.

## Issues Encountered
- Xcode command line tools pointed to CommandLineTools instead of Xcode.app -- worked around by using DEVELOPER_DIR environment variable
- iPhone 16 simulator not available (iOS 26.2 SDK ships with iPhone 17) -- used iPhone 17 simulator instead

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- CadenceService ready for Plan 02 (Run UI) to consume state via CadenceService.shared
- Run screen can observe currentSPM, trend, and state for display
- requestPermissionAndStart() ready for "Start Run" button integration

## Self-Check: PASSED

- All 4 created files exist on disk
- All 3 commits (a9de91e, cbbbf3f, b158ee7) verified in git history
- CadenceService.swift: 179 lines (min 80 required)
- CadenceServiceTests.swift: 131 lines (min 50 required)
- 9/9 tests pass

---
*Phase: 03-cadence-detection*
*Completed: 2026-03-20*
