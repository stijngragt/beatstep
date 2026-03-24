---
phase: 11-run-experience
plan: 02
subsystem: ui
tags: [swiftui, zone-selection, run-view, dead-code-cleanup]

# Dependency graph
requires:
  - phase: 11-run-experience
    plan: 01
    provides: ZonePickerView, RunZone.selectedZoneId persistence, restructured RunTabView
provides:
  - RunView idle state driven by zone selection instead of ModePicker/PacePresetPicker
  - Zone-based runMode and targetBPM derivation on run start
  - Complete removal of PacePreset, PacePresetPicker, ModePicker dead code
affects: [12-onboarding, run-experience]

# Tech tracking
tech-stack:
  added: []
  patterns: [zone-driven run configuration replacing preset-based approach]

key-files:
  created: []
  modified:
    - BeatStep/Views/Run/RunView.swift
    - BeatStep.xcodeproj/project.pbxproj

key-decisions:
  - "TolerancePicker only shown when selectedZoneId != nil (guided mode via zone)"
  - "targetBPM computed property falls back to RunMode.savedTargetBPM when no zone selected"

patterns-established:
  - "Zone selection as single source of truth for run configuration (free vs guided + BPM)"

requirements-completed: [RUN-01]

# Metrics
duration: 4min
completed: 2026-03-24
---

# Phase 11 Plan 02: RunView Zone Migration & Dead Code Cleanup Summary

**RunView migrated from PacePreset/ModePicker to zone-based run config, with full deletion of replaced components**

## Performance

- **Duration:** 4 min
- **Started:** 2026-03-24T12:34:10Z
- **Completed:** 2026-03-24T12:38:45Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments
- RunView idle state shows selected zone label (read-only) or "Free Run" instead of ModePicker + PacePresetPicker
- Start button derives runMode (.guided/.free) and targetBPM from zone selection
- TolerancePicker conditionally shown only when a zone is selected (guided mode)
- PacePreset.swift, PacePresetPicker.swift, ModePicker.swift, PacePresetTests.swift fully deleted
- All pbxproj references cleaned up -- zero dangling references to deleted types

## Task Commits

Each task was committed atomically:

1. **Task 1: Update RunView to use zone selection and remove old pickers** - `8c7d87a` (feat)
2. **Task 2: Delete dead code and clean up tests** - `d8094d8` (chore)

## Files Created/Modified
- `BeatStep/Views/Run/RunView.swift` - Replaced state properties with selectedZoneId, zone-driven idle view and start logic
- `BeatStep/Models/PacePreset.swift` - Deleted
- `BeatStep/Views/Run/PacePresetPicker.swift` - Deleted
- `BeatStep/Views/Run/ModePicker.swift` - Deleted
- `BeatStepTests/PacePresetTests.swift` - Deleted
- `BeatStep.xcodeproj/project.pbxproj` - Removed all references to deleted files

## Decisions Made
- TolerancePicker only shown when selectedZoneId != nil -- free runs don't need tolerance since there's no target BPM
- targetBPM computed property falls back to RunMode.savedTargetBPM when no zone selected, maintaining backward compatibility

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
- xcodebuild `TEST FAILED` exit code due to simctl diagnostic collection error (xcrun path issue), but all 8 tests actually passed with 0 failures -- same tooling artifact as Plan 01

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- Run experience phase complete -- RunView fully migrated to zone-based configuration
- All old preset/mode picker code removed, clean codebase for Phase 12 (onboarding)

## Self-Check: PASSED

All deleted files verified removed from disk. All commit hashes verified in git log. Zero grep matches for PacePreset/ModePicker in .swift files.

---
*Phase: 11-run-experience*
*Completed: 2026-03-24*
