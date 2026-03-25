---
phase: 21-zero-bpm-fallback
plan: 02
subsystem: engine
tags: [swift, run-engine, bpm-matching, fallback]

# Dependency graph
requires:
  - phase: 21-01
    provides: ZeroBPMFallback enum with skip/playRegardless/prompt cases and UserDefaults persistence
provides:
  - Fallback-aware track selection in RunEngineService respecting ZeroBPMFallback setting
  - Separate nil-BPM pool cycling via playedNilBPMIDs set
affects: [future prompt UI overlay for .prompt case]

# Tech tracking
tech-stack:
  added: []
  patterns: [Separate played-ID set for nil-BPM pool cycling independent of BPM pool reset]

key-files:
  created: []
  modified:
    - BeatStep/Services/RunEngineService.swift
    - BeatStepTests/RunEngineServiceTests.swift

key-decisions:
  - "Separate playedNilBPMIDs set to prevent BPM pool reset from clearing nil-BPM play history"
  - "Prompt fallback uses same code path as playRegardless (plays track) -- future phase adds UI overlay"

patterns-established:
  - "Nil-BPM fallback check happens after all BPM matching exhausted, preserving BPM priority"

requirements-completed: [FALL-02]

# Metrics
duration: 6min
completed: 2026-03-25
---

# Phase 21 Plan 02: Zero-BPM Fallback Summary

**ZeroBPMFallback wired into RunEngineService: skip excludes nil-BPM tracks, playRegardless includes them as last-resort fallback with independent pool cycling**

## Performance

- **Duration:** 6 min
- **Started:** 2026-03-25T12:23:23Z
- **Completed:** 2026-03-25T12:29:30Z
- **Tasks:** 1
- **Files modified:** 2

## Accomplishments
- RunEngineService loads ZeroBPMFallback.saved at run start
- selectNextMatch returns nil-BPM tracks as fallback when no BPM match exists and fallback != skip
- Separate playedNilBPMIDs set prevents BPM pool reset from breaking nil-BPM no-repeat tracking
- BPM-matched tracks always take priority over nil-BPM fallback tracks
- 5 new tests covering skip, playRegardless, BPM priority, played tracking, and pool reset

## Task Commits

Each task was committed atomically:

1. **Task 1: Wire ZeroBPMFallback into RunEngineService with tests** - `c10a2ad` (test: RED), `cc2659d` (feat: GREEN)

_TDD task has two commits (RED test + GREEN implementation)_

## Files Created/Modified
- `BeatStep/Services/RunEngineService.swift` - Added zeroBPMFallback property, playedNilBPMIDs set, fallback logic in selectNextMatch, load in startRun, reset in stopRun/loadForTesting, testing helper
- `BeatStepTests/RunEngineServiceTests.swift` - 5 new tests for fallback behavior (skip nil, playRegardless returns, BPM preferred, played tracking, pool reset)

## Decisions Made
- Used separate `playedNilBPMIDs` set instead of relying on `playedTrackIDs` for nil-BPM tracking, because the BPM pool exhaustion reset (`playedTrackIDs.removeAll()`) would clear nil-BPM play history and cause immediate repeats
- Prompt case shares playRegardless code path for now -- plays the track without prompting. Future phase can add the prompt UI overlay

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Separate nil-BPM played tracking set**
- **Found during:** Task 1 (GREEN phase)
- **Issue:** Plan's code used `playedTrackIDs` for nil-BPM tracking, but `playedTrackIDs.removeAll()` in the BPM pool reset path clears nil-BPM history, causing immediate repeats
- **Fix:** Added `playedNilBPMIDs` set for independent nil-BPM pool cycling
- **Files modified:** BeatStep/Services/RunEngineService.swift
- **Verification:** testPlayRegardlessFallbackTracksPlayedIDs passes
- **Committed in:** cc2659d (GREEN commit)

---

**Total deviations:** 1 auto-fixed (1 bug)
**Impact on plan:** Essential for correctness -- without separate tracking, nil-BPM no-repeat guarantee was broken by BPM pool reset. No scope creep.

## Issues Encountered
- Xcode developer directory pointed to CommandLineTools instead of Xcode.app; resolved with DEVELOPER_DIR environment variable
- iPhone 16 simulator not available (iOS 26.2); used iPhone 17 Pro instead (same as plan 21-01)

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- ZeroBPMFallback fully integrated: model (21-01) + engine (21-02) complete
- Phase 21 (zero-bpm-fallback) is now fully implemented
- Prompt fallback UI deferred to future phase if needed

---
*Phase: 21-zero-bpm-fallback*
*Completed: 2026-03-25*
