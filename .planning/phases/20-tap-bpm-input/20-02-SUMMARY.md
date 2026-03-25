---
phase: 20-tap-bpm-input
plan: 02
subsystem: ui
tags: [tap-bpm, swiftui, half-sheet, haptics, gesture-separation]

requires:
  - phase: 20-tap-bpm-input
    provides: TapBPMEngine with tap(), reset(), currentBPM, tapCount, isStable, lastTapWasOutlier, canSave
  - phase: 19-confidence-badges
    provides: BPMInfo struct, confidence badge capsule pattern
  - phase: 18-bpm-confidence-model
    provides: BPMCacheService.cacheManual(), BPMConfidence enum
provides:
  - TapBPMView half-sheet UI with tap zone, progress dots, and save flow
  - Badge tap gesture on TrackRow opening tap BPM sheet
  - End-to-end tap BPM feature from badge tap through save with badge refresh
affects: []

tech-stack:
  added: []
  patterns: [Button wrapping for gesture separation on list rows, ShakeModifier for error feedback, flash animation for valid tap feedback]

key-files:
  created:
    - BeatStep/Views/Library/TapBPMView.swift
  modified:
    - BeatStep/Views/Library/PlaylistDetailView.swift
    - BeatStep.xcodeproj/project.pbxproj

key-decisions:
  - "Button wrapping on badge for gesture separation -- badge tap opens sheet, row tap plays track"
  - "ShakeModifier with offset-based animation for outlier rejection visual feedback"
  - "Flash animation via opacity pulse on valid tap for immediate tactile + visual response"

patterns-established:
  - "Button wrapping for gesture separation: wrap sub-elements in Button with .buttonStyle(.plain) to capture taps before parent .onTapGesture"
  - "ShakeModifier: reusable ViewModifier for shake animation via x-offset with repeatCount and autoreverses"

requirements-completed: [TAP-01, TAP-02, TAP-03]

duration: 28min
completed: 2026-03-25
---

# Phase 20 Plan 02: TapBPMView Summary

**TapBPMView half-sheet with tap zone, 8-dot progress, outlier shake feedback, and badge-triggered presentation via Button gesture separation**

## Performance

- **Duration:** 28 min
- **Started:** 2026-03-25T11:14:08Z
- **Completed:** 2026-03-25T11:42:28Z
- **Tasks:** 2 (1 auto + 1 human-verify)
- **Files modified:** 3

## Accomplishments
- TapBPMView half-sheet with header (track name, artist, live BPM, tap count), 8-dot progress indicator, tap zone with haptic feedback, and save/reset bottom bar
- Badge tap gesture separation using Button wrapping -- badge opens sheet, row tap still plays track
- Outlier rejection visual feedback via ShakeModifier with error haptic
- Valid tap feedback via opacity flash with light impact haptic
- Save flow persists BPM via cacheManual, fires success haptic, dismisses sheet, refreshes badge
- Track auto-plays via SpotifyPlayerService when sheet opens

## Task Commits

Each task was committed atomically:

1. **Task 1: Create TapBPMView and wire PlaylistDetailView** - `16345c9` (feat)
2. **Task 2: Human verification** - approved (no commit)

## Files Created/Modified
- `BeatStep/Views/Library/TapBPMView.swift` - Half-sheet tap BPM UI with engine integration, haptics, and save flow
- `BeatStep/Views/Library/PlaylistDetailView.swift` - Added tapBPMTrack state, sheet presentation, badge Button wrapping with onBadgeTap callback
- `BeatStep.xcodeproj/project.pbxproj` - Added TapBPMView.swift to project

## Decisions Made
- Button wrapping on BPM badge for gesture separation -- Button captures tap before the row's onTapGesture, preventing gesture conflict
- ShakeModifier uses x-offset animation with repeatCount(3, autoreverses: true).speed(6) for quick, subtle error shake
- Opacity flash (0.15s ease-out then 0.1s ease-in) for valid tap visual feedback
- completedIntervals = min(max(0, tapCount - 1), 8) -- matches engine's 1-indexed tapCount to 0-indexed dot progress

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
- iPhone 16 simulator not available (Xcode 26.2 uses iPhone 17 series) -- used iPhone 17 Pro (same as plan 01)
- TapBPMView.swift needed manual addition to project.pbxproj (file references, group, and build sources)

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- Tap BPM feature complete end-to-end (Phase 20 done)
- Ready for Phase 21 (next v1.4 phase)

## Self-Check: PASSED

All files exist. All commits verified.

---
*Phase: 20-tap-bpm-input*
*Completed: 2026-03-25*
