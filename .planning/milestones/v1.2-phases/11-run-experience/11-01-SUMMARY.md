---
phase: 11-run-experience
plan: 01
subsystem: ui
tags: [swiftui, userdefaults, zone-picker, run-tab]

# Dependency graph
requires:
  - phase: 10-models-settings-library-ux
    provides: RunZone model with defaults and BPM persistence
provides:
  - ZonePickerView component with Z1-Z5 + Free capsule selection
  - RunZone.selectedZoneId persistence property
  - Restructured RunTabView with zone picker, conditional tolerance, pinned CTA
affects: [11-02, run-experience, onboarding]

# Tech tracking
tech-stack:
  added: []
  patterns: [unified zone picker replacing ModePicker + PacePresetPicker, full-width pinned CTA pattern]

key-files:
  created:
    - BeatStep/Views/Run/ZonePickerView.swift
    - BeatStepTests/ZoneSelectionTests.swift
  modified:
    - BeatStep/Models/RunZone.swift
    - BeatStep/Views/Run/RunTabView.swift
    - BeatStep.xcodeproj/project.pbxproj

key-decisions:
  - "Zone capsule Free uses minHeight frame to match two-line zone capsule height"
  - "noRunContent simplified to text-only -- no CTA button when no playlist exists"

patterns-established:
  - "Zone selection persistence via selectedZoneId with nil=Free mapping"
  - "Full-width accent-red CTA pinned at bottom of VStack with Spacer"

requirements-completed: [RUN-01, RUN-02]

# Metrics
duration: 8min
completed: 2026-03-24
---

# Phase 11 Plan 01: Zone Picker & RunTabView Summary

**Unified zone picker (Z1-Z5 + Free) replacing ModePicker/PacePresetPicker, with conditional tolerance and pinned full-width accent-red CTA on RunTabView**

## Performance

- **Duration:** 8 min
- **Started:** 2026-03-24T12:24:01Z
- **Completed:** 2026-03-24T12:31:32Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments
- ZonePickerView renders Z1-Z5 + Free as horizontal capsule scroll matching PacePresetPicker styling
- RunTabView restructured with zone picker, conditional TolerancePicker, and full-width pinned CTA
- Zone selection persists via RunZone.selectedZoneId and syncs RunMode + targetBPM
- All 13 tests pass (8 RunZoneTests + 5 ZoneSelectionTests)

## Task Commits

Each task was committed atomically:

1. **Task 1: Add selectedZoneId persistence and build ZonePickerView** - `7f6ceb7` (feat)
2. **Task 2: Restructure RunTabView with zone picker, conditional tolerance, and pinned CTA** - `9162490` (feat)

## Files Created/Modified
- `BeatStep/Views/Run/ZonePickerView.swift` - Horizontal capsule scroll for Z1-Z5 + Free zone selection
- `BeatStepTests/ZoneSelectionTests.swift` - 5 tests for selectedZoneId persistence and zone mapping
- `BeatStep/Models/RunZone.swift` - Added selectedZoneId static property with UserDefaults persistence
- `BeatStep/Views/Run/RunTabView.swift` - Integrated zone picker, conditional tolerance, full-width CTA
- `BeatStep.xcodeproj/project.pbxproj` - Added missing file references (RunZone, ZoneSettingsRow, test files)

## Decisions Made
- Zone capsule Free uses minHeight frame to vertically align with two-line zone capsules (research pitfall 3)
- noRunContent simplified to text-only prompt -- no CTA button when no playlist exists (per user decision)

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Added missing file references to Xcode project**
- **Found during:** Task 1 (build verification)
- **Issue:** RunZone.swift, ZoneSettingsRow.swift, RunZoneTests.swift, TrackCountTests.swift were on disk but not referenced in project.pbxproj -- build failed with "Cannot find type 'RunZone' in scope"
- **Fix:** Added PBXFileReference, PBXBuildFile, PBXGroup children, and PBXSourcesBuildPhase entries for all 6 missing files (4 pre-existing + 2 new)
- **Files modified:** BeatStep.xcodeproj/project.pbxproj
- **Verification:** Build succeeds, all tests pass
- **Committed in:** 7f6ceb7 (Task 1 commit)

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** Pre-existing pbxproj gap from Phase 10 -- required fix to unblock compilation. No scope creep.

## Issues Encountered
- iPhone 16 simulator not available (OS 26.2 only has iPhone 17) -- switched destination to iPhone 17
- xcode-select pointed to CommandLineTools -- used DEVELOPER_DIR env var to target Xcode.app

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- Zone picker and RunTabView ready for Plan 02 (run flow integration)
- PacePresetPicker and ModePicker still exist but are no longer used on RunTabView -- candidates for cleanup

## Self-Check: PASSED

All created files verified on disk. All commit hashes verified in git log.

---
*Phase: 11-run-experience*
*Completed: 2026-03-24*
