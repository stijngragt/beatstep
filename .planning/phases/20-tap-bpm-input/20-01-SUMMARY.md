---
phase: 20-tap-bpm-input
plan: 01
subsystem: services
tags: [tap-tempo, bpm, rolling-average, outlier-rejection, tdd]

requires:
  - phase: 18-bpm-confidence-model
    provides: BPMConfidence enum, BPMCacheService.cacheManual()
provides:
  - TapBPMEngine class with tap-tempo BPM calculation
  - Rolling 8-interval window with median-deviation outlier rejection
  - Deterministic tap(at:) API for testing
affects: [20-02-tap-bpm-view]

tech-stack:
  added: []
  patterns: [@Observable engine with tap(at:) for deterministic testing]

key-files:
  created:
    - BeatStep/Services/TapBPMEngine.swift
    - BeatStepTests/TapBPMEngineTests.swift
  modified:
    - BeatStep.xcodeproj/project.pbxproj

key-decisions:
  - "40% median-deviation threshold for outlier rejection (tunable constant)"
  - "Boundary rejection at <0.2s and >2.0s before median check"
  - "tapCount tracks tap events (1-indexed), not intervals"

patterns-established:
  - "tap(at: Date) overload pattern for deterministic unit testing of time-dependent engines"

requirements-completed: [TAP-01, TAP-02, TAP-03]

duration: 7min
completed: 2026-03-25
---

# Phase 20 Plan 01: TapBPMEngine Summary

**Pure-logic tap tempo engine with rolling 8-interval average, 40% median-deviation outlier rejection, and 3-second inactivity reset**

## Performance

- **Duration:** 7 min
- **Started:** 2026-03-25T11:04:44Z
- **Completed:** 2026-03-25T11:11:16Z
- **Tasks:** 2 (TDD RED + GREEN)
- **Files modified:** 3

## Accomplishments
- TapBPMEngine with rolling 8-interval window BPM calculation
- Outlier rejection via median deviation (40% threshold) plus boundary guards (0.2s-2.0s)
- 14 unit tests covering all 10 specified behaviors plus edge cases
- Deterministic tap(at:) overload enabling time-controlled testing

## Task Commits

Each task was committed atomically:

1. **RED: Failing tests for TapBPMEngine** - `df633a3` (test)
2. **GREEN: Implement TapBPMEngine** - `bfbe571` (feat)

_TDD plan: RED wrote 14 failing tests, GREEN implemented engine to pass all 14._

## Files Created/Modified
- `BeatStep/Services/TapBPMEngine.swift` - Pure-logic tap tempo engine with @Observable
- `BeatStepTests/TapBPMEngineTests.swift` - 14 unit tests covering all behaviors
- `BeatStep.xcodeproj/project.pbxproj` - Added both files to Xcode project

## Decisions Made
- 40% median-deviation threshold for outlier rejection -- follows research recommendation, easily tunable via private constant
- Boundary rejection (<0.2s, >2.0s) applied before median check -- prevents divide-by-zero and catches extreme inputs even with empty interval buffer
- tapCount tracks tap events (first tap = 1), not intervals -- matches user-facing "N/8 taps" display semantics

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed rolling window test calculation**
- **Found during:** GREEN phase (test verification)
- **Issue:** Test expected BPM=100 after 12 taps but transition interval between tempo groups meant rolling window still contained mixed intervals
- **Fix:** Adjusted test to use 13 taps (3 at 120 BPM + 10 at 100 BPM) ensuring last 8 intervals are all 0.6s
- **Files modified:** BeatStepTests/TapBPMEngineTests.swift
- **Verification:** All 14 tests pass
- **Committed in:** bfbe571 (GREEN phase commit)

---

**Total deviations:** 1 auto-fixed (1 bug in test data)
**Impact on plan:** Test logic correction only. No scope creep.

## Issues Encountered
- iPhone 16 simulator not available (Xcode 26.2 has iPhone 17 series) -- used iPhone 17 Pro instead
- xcode-select pointed to CommandLineTools instead of Xcode.app -- used direct path to xcodebuild

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- TapBPMEngine ready for consumption by TapBPMView (plan 20-02)
- All public APIs match plan specification: tap(), tap(at:), reset(), currentBPM, tapCount, isStable, lastTapWasOutlier, canSave

---
*Phase: 20-tap-bpm-input*
*Completed: 2026-03-25*
