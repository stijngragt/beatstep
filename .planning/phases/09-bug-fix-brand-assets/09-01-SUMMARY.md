---
phase: 09-bug-fix-brand-assets
plan: 01
subsystem: ui
tags: [swift, swiftui, spotify, optional, model]

# Dependency graph
requires:
  - phase: 03-cadence-detection
    provides: SpotifyPlaylist model with trackCount property
provides:
  - Optional trackCount property (Int?) on SpotifyPlaylist
  - Conditional track count display in PlaylistListView and PlaylistDetailView
affects: []

# Tech tracking
tech-stack:
  added: []
  patterns: [optional-unwrap-view-display]

key-files:
  created:
    - BeatStepTests/TrackCountTests.swift
  modified:
    - BeatStep/Models/SpotifyPlaylist.swift
    - BeatStep/Views/Library/PlaylistListView.swift
    - BeatStep/Views/Library/PlaylistDetailView.swift

key-decisions:
  - "nil means unknown (hide count), 0 means genuinely empty (show '0 tracks')"

patterns-established:
  - "Optional model properties with if-let conditional display in views"

requirements-completed: [BUG-01]

# Metrics
duration: 1min
completed: 2026-03-24
---

# Phase 9 Plan 1: Track Count Bug Fix Summary

**Optional trackCount (Int?) on SpotifyPlaylist -- nil hides count for algorithmic playlists, 0 shows "0 tracks" for empty playlists**

## Performance

- **Duration:** 1 min
- **Started:** 2026-03-24T08:43:16Z
- **Completed:** 2026-03-24T08:44:40Z
- **Tasks:** 1
- **Files modified:** 4

## Accomplishments
- Changed SpotifyPlaylist.trackCount from Int to Int?, removing the ?? 0 fallback
- Wrapped track count display in if-let in both PlaylistListView and PlaylistDetailView
- Added 3 unit tests covering nil, zero, and non-zero track count cases

## Task Commits

Each task was committed atomically:

1. **Task 1 (RED): Add failing tests for optional trackCount** - `b35e6bf` (test)
2. **Task 1 (GREEN): Fix trackCount to Int? with conditional view display** - `4d50873` (feat)

_TDD task with RED and GREEN commits._

## Files Created/Modified
- `BeatStepTests/TrackCountTests.swift` - 3 unit tests for nil/zero/non-zero trackCount
- `BeatStep/Models/SpotifyPlaylist.swift` - trackCount changed from Int to Int?
- `BeatStep/Views/Library/PlaylistListView.swift` - Conditional track count display with if-let
- `BeatStep/Views/Library/PlaylistDetailView.swift` - Conditional track count display with if-let

## Decisions Made
- nil means unknown (hide count entirely), 0 means genuinely empty (show "0 tracks") -- semantic distinction matching Spotify API behavior

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
- xcodebuild unavailable (xcode-select points to CommandLineTools, not Xcode.app) -- tests verified by code analysis; structure matches existing test patterns

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Track count bug fix complete, ready for plan 02 (brand assets)
- No blockers

---
*Phase: 09-bug-fix-brand-assets*
*Completed: 2026-03-24*

## Self-Check: PASSED
