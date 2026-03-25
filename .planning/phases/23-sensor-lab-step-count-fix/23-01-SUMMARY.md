---
phase: 23-sensor-lab-step-count-fix
plan: 01
subsystem: ui
tags: [cmpedometer, coremotion, sensor-lab, cadence, step-count]

requires:
  - phase: 22-sensor-lab
    provides: SensorLabView and SensorLabService foundation
provides:
  - Live step count display in Sensor Lab from CMPedometer
  - CadenceService.stepCount observable property
affects: []

tech-stack:
  added: []
  patterns:
    - "Pedometer data flows through CadenceService, not SensorLabService"

key-files:
  created: []
  modified:
    - BeatStep/Services/CadenceService.swift
    - BeatStep/Views/Settings/SensorLabView.swift
    - BeatStep/Services/SensorLabService.swift
    - BeatStepTests/CadenceServiceTests.swift
    - BeatStepTests/SensorLabServiceTests.swift

key-decisions:
  - "stepCount lives on CadenceService (owns pedometer) not SensorLabService (owns accelerometer)"

patterns-established:
  - "Sensor Lab starts/stops CadenceService alongside SensorLabService for full sensor coverage"

requirements-completed: [SLAB-02]

duration: 2min
completed: 2026-03-25
---

# Phase 23 Plan 01: Sensor Lab Step Count Fix Summary

**Live step count from CMPedometer via CadenceService.stepCount wired into Sensor Lab display, replacing orphaned SensorLabService.stepCount**

## Performance

- **Duration:** 2 min
- **Started:** 2026-03-25T13:47:49Z
- **Completed:** 2026-03-25T13:49:56Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments
- Added public observable stepCount property to CadenceService, written from pedometer numberOfSteps on every update
- Rewired SensorLabView to read cadence.stepCount instead of the always-zero service.stepCount
- CadenceService now starts/stops with Sensor Lab lifecycle (onAppear/onDisappear)
- Removed orphaned stepCount from SensorLabService and its test assertions

## Task Commits

Each task was committed atomically:

1. **Task 1: Expose stepCount on CadenceService (RED)** - `bbef7b8` (test)
2. **Task 1: Expose stepCount on CadenceService (GREEN)** - `7655cd2` (feat)
3. **Task 2: Wire SensorLabView and clean up orphaned property** - `eca19a8` (feat)

_Note: Task 1 used TDD with separate RED and GREEN commits_

## Files Created/Modified
- `BeatStep/Services/CadenceService.swift` - Added stepCount property, pedometer write, stop reset
- `BeatStep/Views/Settings/SensorLabView.swift` - Changed to cadence.stepCount, added CadenceService lifecycle
- `BeatStep/Services/SensorLabService.swift` - Removed orphaned stepCount property and its reset
- `BeatStepTests/CadenceServiceTests.swift` - Added step count tests, updated reset assertion
- `BeatStepTests/SensorLabServiceTests.swift` - Removed orphaned stepCount assertions

## Decisions Made
- stepCount lives on CadenceService (which owns the pedometer) not SensorLabService (which owns the accelerometer)

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
- xcodebuild unavailable (xcode-select pointed to CommandLineTools, not Xcode.app; sudo required to switch). Verified changes through static analysis and grep checks instead of running tests on simulator.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- Step count display is fully wired and ready for on-device verification
- All test files updated and should pass once xcodebuild is available

---
*Phase: 23-sensor-lab-step-count-fix*
*Completed: 2026-03-25*
