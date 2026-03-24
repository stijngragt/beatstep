---
phase: 12-onboarding
plan: 02
subsystem: ui
tags: [swiftui, settings, permissions, healthkit, coremotion]

requires:
  - phase: 12-onboarding-01
    provides: "OnboardingFlow with AppStorage permission flags (hasRequestedHealth, hasRequestedMotion)"
provides:
  - "Permissions section in SettingsView with Motion/Health status and Open Settings link"
  - "Permission recovery path for users who denied during onboarding"
affects: []

tech-stack:
  added: []
  patterns:
    - "CMPedometer.authorizationStatus() for runtime motion permission checks"
    - "HKHealthStore.isHealthDataAvailable() conditional UI rendering"
    - "UIApplication.openSettingsURLString for deep-linking to app settings"

key-files:
  created: []
  modified:
    - BeatStep/Views/Settings/SettingsView.swift
    - BeatStepTests/OnboardingTests.swift

key-decisions:
  - "Health row shows Requested/Not Yet instead of Granted/Denied because HKAuthorizationStatus always returns .notDetermined for read types"
  - "Open Settings uses UIApplication.openSettingsURLString to deep-link directly to BeatStep settings page"

patterns-established:
  - "AppStorage flags from onboarding reused in Settings for permission state display"

requirements-completed: [ONBD-04]

duration: 8min
completed: 2026-03-24
---

# Phase 12 Plan 02: Settings Permission Recovery Summary

**Permissions section in SettingsView showing Motion/Health status with Open Settings deep-link for users who denied permissions during onboarding**

## Performance

- **Duration:** 8 min (across two sessions with checkpoint)
- **Started:** 2026-03-24T13:12:00Z
- **Completed:** 2026-03-24T13:20:25Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments
- Added Permissions section to SettingsView between Running Zones and Disconnect sections
- Motion Access row shows real-time status via CMPedometer.authorizationStatus() (Granted/Check Settings)
- Apple Health row conditionally shown on supported devices with Requested/Not Yet status
- Open Settings button deep-links to BeatStep's iOS Settings page
- Tests verify AppStorage flag defaults and openSettingsURLString availability

## Task Commits

Each task was committed atomically:

1. **Task 1: Add Permissions section to SettingsView** - `1868c36` (feat)
2. **Task 2: Verify complete onboarding flow end-to-end** - checkpoint approved by user

## Files Created/Modified
- `BeatStep/Views/Settings/SettingsView.swift` - Added Permissions section with Motion/Health status rows and Open Settings button
- `BeatStepTests/OnboardingTests.swift` - Added tests for AppStorage defaults and openSettingsURLString

## Decisions Made
- Health row shows "Requested" or "Not Yet" rather than attempting to read authorization status, because HealthKit always returns `.notDetermined` for read-type permissions even when denied
- Open Settings uses `UIApplication.openSettingsURLString` for direct deep-link to BeatStep settings

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- v1.2 milestone complete: all 3 phases (10-models-settings-library-ux, 11-run-experience, 12-onboarding) delivered
- Full onboarding flow verified end-to-end by user on device/simulator
- Permission recovery path available in Settings for users who denied during onboarding

## Self-Check: PASSED

All files exist. All commits verified.

---
*Phase: 12-onboarding*
*Completed: 2026-03-24*
