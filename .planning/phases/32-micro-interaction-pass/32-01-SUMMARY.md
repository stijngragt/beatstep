---
phase: 32-micro-interaction-pass
plan: 01
subsystem: ui
tags: [swiftui, animation, haptics, design-tokens, micro-interactions]

requires:
  - phase: 31-skeleton-loading
    provides: BSAnimation and BSHaptics design system tokens
provides:
  - "All run screen animations scoped to specific values (numbers snap, chrome animates)"
  - "Zero raw UIFeedbackGenerator calls in Views/ (all use BSHaptics tokens)"
  - "Zero raw animation values in target files (all use BSAnimation tokens)"
affects: [32-02, 32-03]

tech-stack:
  added: []
  patterns:
    - "BSAnimation.gentle for background/badge color transitions"
    - "BSAnimation.smooth for position/progress animations"
    - "BSAnimation.quick for micro-feedback (tap flash, cancel press)"
    - "BSAnimation.snappy for tap/selection interactions"
    - "BSAnimation.page for page-level transitions"
    - "BSHaptics tokens for all user-action haptic feedback"

key-files:
  created: []
  modified:
    - BeatStep/Views/Run/SyncBackgroundModifier.swift
    - BeatStep/Views/Run/RunStatusBar.swift
    - BeatStep/Views/Run/ZoneBandView.swift
    - BeatStep/Views/Run/RampPhaseIndicator.swift
    - BeatStep/Views/Run/CadenceDisplayView.swift
    - BeatStep/Views/Run/ActiveRunView.swift
    - BeatStep/Views/Run/LongPressStopButton.swift
    - BeatStep/Views/Settings/ZoneSettingsRow.swift
    - BeatStep/Views/Onboarding/OnboardingFlow.swift
    - BeatStep/Views/Library/TapBPMView.swift

key-decisions:
  - "Trend arrow gets BSAnimation.quick; number text has zero animation modifiers"
  - "Haptics only on user-action buttons during run (tempo toggle, cool down), not on data updates"

patterns-established:
  - "Run screen scoping: .animation(token, value:) on chrome, no animation on numeric displays"
  - "User-action haptics: BSHaptics.light() before toggle/button actions"
  - "Stepper haptics: onChange handler with BSHaptics.selection()"

requirements-completed: [POL-02]

duration: 2min
completed: 2026-03-26
---

# Phase 32 Plan 01: Run Screen Animation Scoping & Token Migration Summary

**BSAnimation/BSHaptics token migration across 10 view files with run screen animation scoping -- numbers snap instantly, chrome animates smoothly, zero raw values remaining**

## Performance

- **Duration:** 2 min
- **Started:** 2026-03-26T12:50:43Z
- **Completed:** 2026-03-26T12:53:05Z
- **Tasks:** 1
- **Files modified:** 10

## Accomplishments
- Run screen animations scoped: chrome (sync badge, zone band, ramp progress, background) uses BSAnimation tokens; number displays (SPM, delta) have zero animation modifiers and snap instantly
- All 3 raw UIFeedbackGenerator calls in TapBPMView migrated to BSHaptics.light(), .error(), .success()
- All raw animation values (.easeInOut, .easeOut, .spring) in target files replaced with BSAnimation tokens
- Haptics added to ActiveRunView user-action buttons (tempo toggle, cool down) and LongPressStopButton (success on stop)
- ZoneSettingsRow expand/collapse and stepper both have BSHaptics.selection() feedback

## Task Commits

Each task was committed atomically:

1. **Task 1: Run screen animation scoping and token migration** - `f8235d0` (feat)

## Files Created/Modified
- `BeatStep/Views/Run/SyncBackgroundModifier.swift` - BSAnimation.gentle for sync quality color shift
- `BeatStep/Views/Run/RunStatusBar.swift` - BSAnimation.gentle for sync badge transitions
- `BeatStep/Views/Run/ZoneBandView.swift` - BSAnimation.smooth for cadence position indicator
- `BeatStep/Views/Run/RampPhaseIndicator.swift` - BSAnimation.smooth for ramp progress bar
- `BeatStep/Views/Run/CadenceDisplayView.swift` - BSAnimation.quick on trend arrow only, numbers untouched
- `BeatStep/Views/Run/ActiveRunView.swift` - BSHaptics.light() on tempo toggle and cool down buttons
- `BeatStep/Views/Run/LongPressStopButton.swift` - BSAnimation.quick for cancel press, BSHaptics.success() on stop
- `BeatStep/Views/Settings/ZoneSettingsRow.swift` - BSAnimation.snappy + BSHaptics.selection() for expand and stepper
- `BeatStep/Views/Onboarding/OnboardingFlow.swift` - BSAnimation.page for page transitions
- `BeatStep/Views/Library/TapBPMView.swift` - BSHaptics.light/error/success replacing raw generators, BSAnimation.quick/smooth

## Decisions Made
- Trend arrow in CadenceDisplayView gets BSAnimation.quick animation on trend value change; all number text (SPM, delta) has zero animation modifiers per D-08
- Haptics on ActiveRunView limited to user-initiated actions (tempo toggle, cool down) per D-05 -- no haptics on observed property changes
- TapBPMView tap flash recovery animation also migrated to BSAnimation.quick (was .easeIn(duration: 0.1))

## Deviations from Plan
None - plan executed exactly as written.

## Known Stubs
None.

## Issues Encountered
None.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- All run screen views and key non-run views now use BSAnimation/BSHaptics tokens exclusively
- Ready for Plan 32-02 (remaining view haptics/transitions) and Plan 32-03 (conditional view transitions)
- Zero raw UIFeedbackGenerator or inline animation values remain in any Views/ file

## Self-Check: PASSED

All 10 modified files verified present. Task commit f8235d0 verified in git log. SUMMARY.md created.

---
*Phase: 32-micro-interaction-pass*
*Completed: 2026-03-26*
