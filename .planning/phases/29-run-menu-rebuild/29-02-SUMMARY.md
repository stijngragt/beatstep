---
phase: 29-run-menu-rebuild
plan: 02
subsystem: ui
tags: [swift, swiftui, haptics, multi-zone, capsule-buttons, run-menu]

requires:
  - phase: 29-run-menu-rebuild
    provides: Multi-zone selection model (selectedZoneIds, mergedBPMRange)
provides:
  - "Multi-select zone toggle grid with BSHaptics.selection() on every tap"
  - "Custom capsule tolerance picker replacing stock SwiftUI Picker"
  - "Merged BPM range display in RunTabView when multiple zones selected"
  - "ActiveRunView updated to accept Set<Int> selectedZoneIds"
affects: [active-run-assembly, run-engine-integration]

tech-stack:
  added: []
  patterns: [capsule-toggle-grid, haptic-on-every-selection, midpoint-bpm-from-zone-set]

key-files:
  created: []
  modified:
    - BeatStep/Views/Run/ZonePickerView.swift
    - BeatStep/Views/Run/TolerancePicker.swift
    - BeatStep/Views/Run/RunTabView.swift
    - BeatStep/Views/Run/ActiveRunView.swift

key-decisions:
  - "buttonStyle(.plain) on all capsule buttons to prevent default highlight doubling"
  - "Midpoint BPM computed as (floor + ceiling) / 2 from selected zone set"

patterns-established:
  - "Capsule toggle grid: Button with BSHaptics.selection() + withAnimation(BSAnimation.snappy) for toggle state"
  - "Multi-zone onChange: persist Set, compute midpoint, set RunMode in single handler"

requirements-completed: [RUN-01, RUN-02]

duration: 2min
completed: 2026-03-26
---

# Phase 29 Plan 02: Run Menu UI Rebuild Summary

**Multi-select zone toggle grid and custom capsule tolerance picker with haptics, merged BPM range display, and full Set<Int> wiring through RunTabView to ActiveRunView**

## Performance

- **Duration:** 2 min
- **Started:** 2026-03-26T08:32:34Z
- **Completed:** 2026-03-26T08:34:18Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments
- ZonePickerView rebuilt as multi-select toggle grid with BSHaptics.selection() on every tap
- TolerancePicker rebuilt with custom capsule buttons replacing stock SwiftUI Picker
- RunTabView wired to Set<Int> selectedZoneIds with merged BPM range label and midpoint engine integration
- ActiveRunView updated to accept selectedZoneIds with multi-zone zoneName display

## Task Commits

Each task was committed atomically:

1. **Task 1: Rebuild ZonePickerView and TolerancePicker with haptics** - `a35f1c3` (feat)
2. **Task 2: Wire RunTabView and ActiveRunView to multi-zone model** - `f51bcb7` (feat)

## Files Created/Modified
- `BeatStep/Views/Run/ZonePickerView.swift` - Multi-select zone toggle grid with Binding<Set<Int>>
- `BeatStep/Views/Run/TolerancePicker.swift` - Custom capsule tolerance buttons with haptics
- `BeatStep/Views/Run/RunTabView.swift` - Set<Int> state, merged BPM range, midpoint engine config
- `BeatStep/Views/Run/ActiveRunView.swift` - Accepts selectedZoneIds: Set<Int>, multi-zone zoneName

## Decisions Made
- Used buttonStyle(.plain) on all capsule buttons to prevent SwiftUI default highlight effects
- Midpoint BPM for guided mode computed as integer average of floor and ceiling zone BPMs

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- All four Run tab view files updated with multi-zone selection
- Zone toggle, tolerance picker, and merged BPM range display are visually cohesive
- Engine integration computes midpoint BPM from selected zones for guided mode

## Self-Check: PASSED

All 4 modified files exist. Both commit hashes verified (a35f1c3, f51bcb7). BSHaptics.selection() present in ZonePickerView (2x) and TolerancePicker (1x). No stock Picker remains. selectedZoneIds wired through RunTabView and ActiveRunView. mergedBPMRange used in RunTabView.

---
*Phase: 29-run-menu-rebuild*
*Completed: 2026-03-26*
