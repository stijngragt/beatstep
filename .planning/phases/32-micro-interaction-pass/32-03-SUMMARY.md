---
phase: 32-micro-interaction-pass
plan: 03
subsystem: ui
tags: [swiftui, animations, transitions, opacity, BSAnimation]

# Dependency graph
requires:
  - phase: 32-micro-interaction-pass (plans 01, 02)
    provides: BSAnimation tokens, BSHaptics tokens, withAnimation migration
provides:
  - .transition(.opacity) on all conditional view appearances across 11 view files
  - POL-02 requirement definition and traceability
affects: [future UI views, new conditional appearances]

# Tech tracking
tech-stack:
  added: []
  patterns: [".transition(.opacity) on each branch + .animation(BSAnimation.*, value:) on parent"]

key-files:
  created: []
  modified:
    - BeatStep/Views/Run/ActiveRunView.swift
    - BeatStep/Views/Run/RunTabView.swift
    - BeatStep/Views/Run/RunStatusBar.swift
    - BeatStep/Views/Run/CadenceDisplayView.swift
    - BeatStep/Views/Player/RunPlayerView.swift
    - BeatStep/Views/Player/MiniPlayerView.swift
    - BeatStep/Views/Settings/SettingsView.swift
    - BeatStep/Views/Settings/ZoneSettingsRow.swift
    - BeatStep/Views/Onboarding/OnboardingSpotifyView.swift
    - BeatStep/Views/Onboarding/OnboardingHealthView.swift
    - BeatStep/Views/Onboarding/OnboardingPlaylistView.swift
    - .planning/REQUIREMENTS.md

key-decisions:
  - "Scoped animation drivers on ActiveRunView to avoid number jank (D-08 compliance)"
  - "Used Group wrapper for if/else transitions in CadenceDisplayView and OnboardingHealthView"

patterns-established:
  - "Transition pattern: .transition(.opacity) on each if/else branch + .animation(BSAnimation.smooth, value:) on parent container"
  - "Scoped animations: each .animation() keyed to specific state value, never blanket"

requirements-completed: [POL-02]

# Metrics
duration: 4min
completed: 2026-03-26
---

# Phase 32 Plan 03: Crossfade Transitions Summary

**Added .transition(.opacity) to all conditional view appearances across 11 view files with scoped BSAnimation drivers and defined POL-02 requirement**

## Performance

- **Duration:** 4 min
- **Started:** 2026-03-26T12:57:21Z
- **Completed:** 2026-03-26T13:01:33Z
- **Tasks:** 2
- **Files modified:** 12

## Accomplishments
- All conditional view appearances now crossfade with .transition(.opacity) instead of instant show/hide
- Run screen animations scoped to specific state values (runMode, rampPhase, currentMatchedTrack) to avoid number display jank
- POL-02 requirement formally defined in REQUIREMENTS.md with Phase 32 traceability

## Task Commits

Each task was committed atomically:

1. **Task 1: Add transitions to Run screen and Player conditional views** - `1333dd9` (feat)
2. **Task 2: Add transitions to Settings, Onboarding views and define POL-02** - `6d82a7f` (feat)

## Files Created/Modified
- `BeatStep/Views/Run/ActiveRunView.swift` - 4 transitions (RampPhaseIndicator, ZoneBandView, RunPlayerView, Cool Down) with scoped drivers
- `BeatStep/Views/Run/RunTabView.swift` - 6 transitions on state branches + BPM range
- `BeatStep/Views/Run/RunStatusBar.swift` - 1 transition on zone name
- `BeatStep/Views/Run/CadenceDisplayView.swift` - 2 transitions on guided/free mode branches
- `BeatStep/Views/Player/RunPlayerView.swift` - 1 transition on BPM display
- `BeatStep/Views/Player/MiniPlayerView.swift` - 3 transitions on track presence and BPM
- `BeatStep/Views/Settings/SettingsView.swift` - 2 transitions on Account and Debug sections
- `BeatStep/Views/Settings/ZoneSettingsRow.swift` - 1 transition on expanded stepper
- `BeatStep/Views/Onboarding/OnboardingSpotifyView.swift` - 3 transitions on loading/error/button
- `BeatStep/Views/Onboarding/OnboardingHealthView.swift` - 2 transitions on permission/continue
- `BeatStep/Views/Onboarding/OnboardingPlaylistView.swift` - 9 transitions on all state branches
- `.planning/REQUIREMENTS.md` - POL-02 definition and traceability

## Decisions Made
- Scoped animation drivers on ActiveRunView per D-08 (no blanket .animation() that could cause number jank)
- Used Group wrapper for if/else transitions where individual branches need distinct transitions
- ZoneSettingsRow relies on existing withAnimation(BSAnimation.snappy) from Plan 01 as animation driver

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Phase 32 micro-interaction pass complete across all 3 plans
- All views now use BSAnimation tokens, BSHaptics tokens, and .transition(.opacity) consistently
- Pattern established for future conditional views

---
*Phase: 32-micro-interaction-pass*
*Completed: 2026-03-26*
