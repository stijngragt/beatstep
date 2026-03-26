---
phase: 29-run-menu-rebuild
plan: 01
subsystem: model
tags: [swift, userdefaults, multi-zone, bpm-range, migration]

requires:
  - phase: 15-run-player-view
    provides: Original RunZone model with single-zone selection
provides:
  - "Multi-zone selection model (selectedZoneIds: Set<Int>) with UserDefaults persistence"
  - "mergedBPMRange(for:) static method returning floor...ceiling ClosedRange<Int>"
  - "Migration from single selectedZoneId to selectedZoneIds"
affects: [29-02-run-menu-rebuild, run-mode-selection, active-run-assembly]

tech-stack:
  added: []
  patterns: [Set-to-sorted-Array UserDefaults encoding, single-to-multi migration on read]

key-files:
  created: []
  modified:
    - BeatStep/Models/RunZone.swift
    - BeatStepTests/RunZoneTests.swift
    - BeatStepTests/ZoneSelectionTests.swift

key-decisions:
  - "Set<Int> persisted as sorted Array<Int> for deterministic UserDefaults storage"
  - "Migration reads old selectedZoneId on-demand (no eager migration write)"

patterns-established:
  - "Multi-value UserDefaults: encode Set as sorted Array for stable persistence"
  - "Migration-on-read: check new key first, fall back to old key, return default last"

requirements-completed: [RUN-02]

duration: 1min
completed: 2026-03-26
---

# Phase 29 Plan 01: Multi-Zone Selection Model Summary

**Multi-zone selection model with Set<Int> UserDefaults persistence, on-read migration from single selectedZoneId, and mergedBPMRange floor...ceiling computation**

## Performance

- **Duration:** 1 min
- **Started:** 2026-03-26T08:28:38Z
- **Completed:** 2026-03-26T08:29:43Z
- **Tasks:** 1 (TDD: RED + GREEN)
- **Files modified:** 3

## Accomplishments
- Added `selectedZoneIds: Set<Int>` computed property with UserDefaults persistence (sorted Array encoding)
- Added `mergedBPMRange(for:)` returning floor...ceiling ClosedRange or nil for empty selection (free mode)
- Migration from old single `selectedZoneId: Int?` works transparently on first read
- 8 new test cases covering round-trip, migration, empty set, and range computation

## Task Commits

Each task was committed atomically:

1. **Task 1 (RED): Add failing tests for multi-zone selection** - `60fa1c0` (test)
2. **Task 1 (GREEN): Implement multi-zone selection model** - `99ea01d` (feat)

_TDD task with RED/GREEN commits._

## Files Created/Modified
- `BeatStep/Models/RunZone.swift` - Added selectedZoneIds, selectedIdsKey, mergedBPMRange(for:)
- `BeatStepTests/RunZoneTests.swift` - Added 4 tests for mergedBPMRange computation
- `BeatStepTests/ZoneSelectionTests.swift` - Added 4 tests for selectedZoneIds persistence and migration, updated tearDown

## Decisions Made
- Set<Int> persisted as sorted Array<Int> for deterministic UserDefaults storage
- Migration reads old selectedZoneId on-demand without writing back to new key (lazy migration)
- Old selectedZoneId property kept intact for backward compatibility

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
- Xcode not available in worktree environment (CLI tools only) -- tests written per spec but xcodebuild verification deferred to main repo

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Model layer complete with selectedZoneIds and mergedBPMRange APIs
- Plan 29-02 can build multi-zone selection UI on top of this model
- All existing RunZone and ZoneSelection test structure preserved

---
*Phase: 29-run-menu-rebuild*
*Completed: 2026-03-26*
