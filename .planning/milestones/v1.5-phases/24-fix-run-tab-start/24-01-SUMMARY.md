---
phase: 24-fix-run-tab-start
plan: 01
subsystem: ui
tags: [swiftui, spotify-api, run-engine, cadence, fullScreenCover, tab-navigation]

# Dependency graph
requires:
  - phase: 15-active-run-screen
    provides: ActiveRunView with fullScreenCover presentation pattern
  - phase: 11-run-experience
    provides: ZonePickerView, TolerancePicker, RunZone persistence
provides:
  - Functional Run tab Start Run button that launches ActiveRunView
  - Single-playlist fetch (fetchPlaylist(id:)) in SpotifyAPIService
  - Programmatic tab selection via Tab enum and ContentView binding
  - Eager playlist data loading on Run tab appear
affects: [25-remove-runview-library, 26-library-to-run-routing]

# Tech tracking
tech-stack:
  added: []
  patterns: [eager-fetch-on-appear, programmatic-tab-selection, immediate-fullScreenCover-on-action]

key-files:
  created: []
  modified:
    - BeatStep/Views/Run/RunTabView.swift
    - BeatStep/Services/SpotifyAPIService.swift
    - BeatStep/App/ContentView.swift

key-decisions:
  - "Present ActiveRunView immediately on Start Run tap instead of waiting for cadence state change"
  - "Eager playlist fetch on .onAppear with lastFetchedPlaylistId tracking to avoid redundant requests"

patterns-established:
  - "Tab enum with selection binding: Tab enum in ContentView.swift for programmatic tab switching"
  - "Immediate fullScreenCover: present run screen on tap, not on cadence state change (Spotify bounce causes missed .onChange)"

requirements-completed: [FLOW-02, FLOW-05]

# Metrics
duration: 24min
completed: 2026-03-25
---

# Phase 24 Plan 01: Fix Run Tab Start Summary

**Run tab Start Run wiring with eager playlist fetch, engine config, and immediate ActiveRunView presentation via fullScreenCover**

## Performance

- **Duration:** 24 min
- **Started:** 2026-03-25T18:24:16Z
- **Completed:** 2026-03-25T18:48:50Z
- **Tasks:** 3
- **Files modified:** 3

## Accomplishments
- Run tab is now the functional pre-run config screen: fetches playlist data on appear, configures engine, launches ActiveRunView
- Added fetchPlaylist(id:) to SpotifyAPIService for single-playlist fetch by ID
- Added Tab enum and programmatic tab selection to ContentView, enabling "Go to Library" from Run tab
- Three-state UI: no-playlist (with tab-switch prompt), loading, and loaded (with zone/tolerance pickers)
- Start Run button disabled during loading or when no playlist is available

## Task Commits

Each task was committed atomically:

1. **Task 1: Add single-playlist fetch and tab selection infrastructure** - `e797d4f` (feat)
2. **Task 2: Rewrite RunTabView with full start-run wiring** - `df9fd81` (feat)
3. **Task 2 fix: Present ActiveRunView immediately on Start Run tap** - `ceaea28` (fix)
4. **Task 3: Verify Run tab start-run flow** - human-verified, no commit

## Files Created/Modified
- `BeatStep/Services/SpotifyAPIService.swift` - Added fetchPlaylist(id:) for single playlist fetch
- `BeatStep/App/ContentView.swift` - Added Tab enum, selection binding, passed to RunTabView
- `BeatStep/Views/Run/RunTabView.swift` - Full rewrite: eager fetch, start-run wiring, three-state UI, fullScreenCover

## Decisions Made
- Present ActiveRunView immediately on Start Run tap rather than waiting for cadence state `.active` -- the Spotify app bounce during playback handoff caused the `.onChange(of: cadenceService.state)` to miss the transition
- Eager fetch with `lastFetchedPlaylistId` tracking: only re-fetches when the saved playlist ID changes, avoiding redundant API calls on tab switches

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] ActiveRunView not appearing after Start Run tap**
- **Found during:** Task 3 (human verification)
- **Issue:** The `.onChange(of: cadenceService.state)` handler that presented ActiveRunView via fullScreenCover never fired because the cadence state transition happened while the user was bounced to the Spotify app
- **Fix:** Present ActiveRunView immediately on Start Run tap instead of waiting for cadence state change
- **Files modified:** BeatStep/Views/Run/RunTabView.swift
- **Verification:** User confirmed Start Run now presents ActiveRunView correctly
- **Committed in:** ceaea28

---

**Total deviations:** 1 auto-fixed (1 bug fix)
**Impact on plan:** Essential fix for core functionality. The cadence-state-driven presentation pattern from RunView does not work when Spotify app bounce is involved. No scope creep.

## Issues Encountered
- xcodebuild required `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer` prefix since xcode-select pointed to CommandLineTools
- iPhone 16 Pro simulator not available; used iPhone 17 Pro instead

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- Run tab Start Run flow complete and verified
- Phase 25 (remove RunView from Library) can proceed: RunTabView now handles all pre-run config
- Phase 26 (Library-to-Run routing) can proceed: Tab enum and selectedTab binding are in place for programmatic tab switching

---
*Phase: 24-fix-run-tab-start*
*Completed: 2026-03-25*
