---
phase: 25-consolidate-run-entry
plan: 01
subsystem: ui
tags: [swiftui, navigation, tab-switching, environment-key]

# Dependency graph
requires:
  - phase: 24-fix-run-tab-start
    provides: RunTabView with selectedTab binding and LastRunPlaylist-based playlist loading
provides:
  - CTA button in PlaylistDetailView for Library-to-Run-tab navigation
  - SelectedTabKey environment key for programmatic tab switching
  - RunView.swift deleted, single run entry point via Run tab
affects: []

# Tech tracking
tech-stack:
  added: []
  patterns: [EnvironmentKey for cross-tab navigation binding]

key-files:
  created: []
  modified:
    - BeatStep/App/ContentView.swift
    - BeatStep/Views/Library/PlaylistDetailView.swift
    - BeatStep.xcodeproj/project.pbxproj

key-decisions:
  - "SelectedTabKey EnvironmentKey over deep binding chains for tab switching"

patterns-established:
  - "EnvironmentKey pattern: inject selectedTab binding on NavigationStack, read via @Environment in child views"

requirements-completed: [FLOW-01, FLOW-03, FLOW-04]

# Metrics
duration: 18min
completed: 2026-03-25
---

# Phase 25 Plan 01: Consolidate Run Entry Summary

**"Run with this playlist" CTA button in PlaylistDetailView with SelectedTabKey environment, RunView.swift deleted**

## Performance

- **Duration:** 18 min
- **Started:** 2026-03-25T19:42:17Z
- **Completed:** 2026-03-25T20:00:08Z
- **Tasks:** 3
- **Files modified:** 3

## Accomplishments
- Added "Run with this playlist" CTA button to PlaylistDetailView header that writes LastRunPlaylist and switches to Run tab
- Created SelectedTabKey EnvironmentKey for programmatic tab switching without deep binding chains
- Deleted RunView.swift and removed all Xcode project references (PBXBuildFile, PBXFileReference, PBXGroup, PBXSourcesBuildPhase)
- Removed RunView NavigationLink from PlaylistDetailView toolbar

## Task Commits

Each task was committed atomically:

1. **Task 1: Add CTA button and wire Library-to-Run-tab navigation** - `f9da72b` (feat)
2. **Task 2: Delete RunView.swift and remove all references** - `0fd5fba` (feat)
3. **Task 3: Verify consolidated run entry flow** - human-verify checkpoint (approved)

## Files Created/Modified
- `BeatStep/App/ContentView.swift` - Added SelectedTabKey EnvironmentKey, injected on Library NavigationStack
- `BeatStep/Views/Library/PlaylistDetailView.swift` - Added CTA button, removed RunView NavigationLink from toolbar
- `BeatStep.xcodeproj/project.pbxproj` - Removed all RunView.swift references
- `BeatStep/Views/Run/RunView.swift` - Deleted

## Decisions Made
- Used EnvironmentKey (`SelectedTabKey`) over deep binding chains -- cleaner than threading a `@Binding var selectedTab: Tab` through PlaylistListView's NavigationLink

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Run entry is fully consolidated to the Run tab
- Ready for phase 26 (or milestone completion)

## Self-Check: PASSED

All files verified present (or deleted as expected). All commit hashes found in git log.

---
*Phase: 25-consolidate-run-entry*
*Completed: 2026-03-25*
