---
phase: 36-responsive-cadence
plan: 01
subsystem: cadence
tags: [coremotion, signal-processing, dead-zone, debounce, rolling-window]

# Dependency graph
requires:
  - phase: 18-bpm-confidence-model
    provides: CadenceService rolling window and trend detection
provides:
  - 2.5s rolling window for sub-2s cadence display updates
  - Dead zone filter (3 SPM threshold) for jitter suppression
  - 8s debounce for faster song selection on pace change
affects: [beat-sync, active-run-view]

# Tech tracking
tech-stack:
  added: []
  patterns: [dead-zone-filter, hysteresis-gating]

key-files:
  created: []
  modified:
    - BeatStep/Services/CadenceService.swift
    - BeatStep/Services/RunEngineService.swift
    - BeatStepTests/CadenceServiceTests.swift
    - BeatStepTests/RunEngineServiceTests.swift
    - BeatStepTests/ActiveRunViewTests.swift

key-decisions:
  - "2.5s window duration (middle of 2-3s range) balances responsiveness with sample count"
  - "Dead zone of 3 SPM gates display updates; trend detection bypasses filter using raw avgSPM"
  - "8s debounce + 2s poll = ~10s total, well within 12s CAD-02 target"

patterns-established:
  - "Dead zone filter: gate @Observable property updates with threshold check + initial bypass"
  - "Trend detection receives raw signal, display receives filtered signal"

requirements-completed: [CAD-01, CAD-02, CAD-03]

# Metrics
duration: 5min
completed: 2026-03-27
---

# Phase 36 Plan 01: Responsive Cadence Summary

**2.5s rolling window + 3 SPM dead zone filter on cadence display, 8s debounce for song selection**

## Performance

- **Duration:** 5 min
- **Started:** 2026-03-27T17:02:32Z
- **Completed:** 2026-03-27T17:07:50Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments
- CadenceService rolling window shrunk from 5s to 2.5s for sub-2s display response (CAD-01)
- Dead zone filter gates currentSPM updates to changes >= 3 SPM, eliminating jitter (CAD-03)
- RunEngineService debounce reduced from 17s to 8s, total pace-to-song time ~10s (CAD-02)
- 5 new CadenceServiceTests covering dead zone behavior, window pruning, and trend bypass
- Full test suite green: 311 tests, 0 failures

## Task Commits

Each task was committed atomically:

1. **Task 1 RED: Add dead zone + window tests** - `8f3d867` (test)
2. **Task 1 GREEN: Implement dead zone filter + 2.5s window** - `0436a14` (feat)
3. **Task 2: Reduce debounce from 17s to 8s** - `6474b93` (feat)

_Note: Task 1 followed TDD (RED -> GREEN). No refactor needed._

## Files Created/Modified
- `BeatStep/Services/CadenceService.swift` - 2.5s window duration + dead zone filter in processCadenceSample
- `BeatStep/Services/RunEngineService.swift` - 8s debounce in onCadenceChanged (was 17s)
- `BeatStepTests/CadenceServiceTests.swift` - 5 new dead zone/window tests (16 total)
- `BeatStepTests/RunEngineServiceTests.swift` - Fixed pre-existing .wide -> .loose compilation error
- `BeatStepTests/ActiveRunViewTests.swift` - Fixed pre-existing selectedZoneId -> selectedZoneIds API

## Decisions Made
- Used 2.5s window (middle of 2-3s range) -- captures 2-3 CMPedometer samples for meaningful averaging while staying responsive
- Dead zone threshold of 3 SPM -- matches natural CMPedometer fluctuation range during steady-state running
- Trend detection continues to receive raw avgSPM (not dead-zone-filtered value) to maintain sensitivity
- Poll interval kept at 2s -- 2s poll + 8s debounce = 10s total, within 12s target with margin

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Fixed BPMTolerance.wide -> .loose in RunEngineServiceTests**
- **Found during:** Task 1 RED (test compilation)
- **Issue:** RunEngineServiceTests referenced non-existent BPMTolerance.wide case (6 occurrences), preventing test target compilation
- **Fix:** Replaced all .wide references with .loose (the correct case name)
- **Files modified:** BeatStepTests/RunEngineServiceTests.swift
- **Verification:** Test target compiles, all 48 RunEngineServiceTests pass
- **Committed in:** 8f3d867 (Task 1 RED commit)

**2. [Rule 3 - Blocking] Fixed ActiveRunViewTests selectedZoneId -> selectedZoneIds API**
- **Found during:** Task 1 RED (test compilation)
- **Issue:** ActiveRunViewTests used old selectedZoneId: Int? parameter (now selectedZoneIds: Set<Int>), preventing test target compilation
- **Fix:** Updated both test methods to use new Set<Int> API
- **Files modified:** BeatStepTests/ActiveRunViewTests.swift
- **Verification:** Test target compiles, all 3 ActiveRunViewTests pass
- **Committed in:** 8f3d867 (Task 1 RED commit)

---

**Total deviations:** 2 auto-fixed (2 blocking -- pre-existing compilation errors in unrelated test files)
**Impact on plan:** Both fixes were necessary to compile the test target. No scope creep -- purely restoring tests to compilable state.

## Issues Encountered
- xcode-select pointed to CommandLineTools instead of Xcode.app -- worked around with DEVELOPER_DIR env var
- iPhone 16 simulator not available -- used iPhone 17 Pro (iOS 26.2)

## User Setup Required
None - no external service configuration required.

## Known Stubs
None - all changes are to existing production code with real data flow.

## Next Phase Readiness
- Cadence display is now responsive (sub-2s) and stable (no jitter)
- Song selection responds within ~10s of sustained pace change
- Ready for beat sync validation or collapsible player phases

## Self-Check: PASSED

All files exist. All 3 commits verified (8f3d867, 0436a14, 6474b93). 311/311 tests pass.

---
*Phase: 36-responsive-cadence*
*Completed: 2026-03-27*
