---
phase: 19-confidence-badges
plan: 01
subsystem: ui
tags: [swiftui, design-tokens, bpm-confidence, value-types]

# Dependency graph
requires:
  - phase: 18-bpm-confidence-model
    provides: BPMConfidence enum and CachedBPM model with confidence/source fields
provides:
  - BPMInfo value struct for view-layer data plumbing
  - BPMConfidence display properties (iconName, color)
  - stateApproximate color token
  - getBPMInfo(forTrackID:) service method
affects: [19-02-confidence-badges]

# Tech tracking
tech-stack:
  added: []
  patterns: [value-struct for view data, computed display properties on enums]

key-files:
  created:
    - BeatStep/Models/BPMInfo.swift
    - BeatStepTests/BPMConfidenceBadgeTests.swift
  modified:
    - BeatStep/Models/BPMConfidence.swift
    - BeatStep/DesignSystem/DesignTokens.swift
    - BeatStep/Services/BPMCacheService.swift
    - BeatStep.xcodeproj/project.pbxproj

key-decisions:
  - "BPMInfo uses let properties for immutability -- view layer receives read-only snapshots"
  - "stateApproximate blue (0.35, 0.55, 0.95) distinct from existing state colors"

patterns-established:
  - "Value struct pattern: lightweight Equatable struct decouples SwiftData model from views"
  - "Display properties on enum: iconName/color computed per case for badge rendering"

requirements-completed: [CONF-03]

# Metrics
duration: 6min
completed: 2026-03-25
---

# Phase 19 Plan 01: Confidence Badge Data Contracts Summary

**BPMInfo value struct, BPMConfidence icon/color display properties, stateApproximate token, and getBPMInfo service method with 10 unit tests**

## Performance

- **Duration:** 6 min
- **Started:** 2026-03-25T10:14:03Z
- **Completed:** 2026-03-25T10:20:05Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments
- BPMInfo struct with .empty static provides lightweight view data plumbing decoupled from SwiftData
- BPMConfidence now has iconName and color computed properties for all three confidence levels
- stateApproximate blue color token added to DesignTokens for approximate confidence badges
- getBPMInfo(forTrackID:) returns BPMInfo with bpm and confidence from cache
- All 10 new unit tests pass (8 model + 2 service integration)

## Task Commits

Each task was committed atomically:

1. **Task 1: Create BPMInfo struct and extend BPMConfidence with display properties** - `a1080fb` (feat)
2. **Task 2: Add getBPMInfo service method and test it** - `0c9f852` (feat)

## Files Created/Modified
- `BeatStep/Models/BPMInfo.swift` - Equatable value struct with bpm, confidence, and .empty static
- `BeatStep/Models/BPMConfidence.swift` - Added iconName and color computed properties
- `BeatStep/DesignSystem/DesignTokens.swift` - Added stateApproximate blue color token
- `BeatStep/Services/BPMCacheService.swift` - Added getBPMInfo(forTrackID:) method
- `BeatStepTests/BPMConfidenceBadgeTests.swift` - 10 tests for icon/color mapping, BPMInfo, and service method
- `BeatStep.xcodeproj/project.pbxproj` - Added new files to targets

## Decisions Made
- BPMInfo uses let properties for immutability -- view layer receives read-only snapshots
- stateApproximate color (0.35, 0.55, 0.95) is a subtle blue, distinct from success/warning/error

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
- Pre-existing test failure in SpotifyAPIServiceTests.testPlaylistTrackDecoding (XCTUnwrap on SpotifyTrack) -- not related to this plan's changes, out of scope

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- All data contracts ready for Plan 02 (view integration)
- BPMInfo, BPMConfidence.iconName/color, and getBPMInfo are the exact interfaces Plan 02 consumes

---
*Phase: 19-confidence-badges*
*Completed: 2026-03-25*
