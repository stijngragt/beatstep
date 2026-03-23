---
phase: 05-guided-run-polish
plan: 01
subsystem: engine
tags: [swift, swiftui, runengine, ramp, danceability, discovery, tdd]

# Dependency graph
requires:
  - phase: 04-core-loop-free-run
    provides: RunEngineService with free run cadence matching, BPM cache, discovery service
provides:
  - RunMode enum with UserDefaults persistence
  - RampPhase enum with display labels
  - PacePreset enum with BPM values
  - effectiveBPM computed property (free=cadence, guided=ramp)
  - Warm-up/cool-down ramp state machine
  - Danceability-ranked smart selection
  - On-demand discovery integration
  - startCoolDown() method
affects: [05-02-PLAN, ui-wiring, guided-run-view]

# Tech tracking
tech-stack:
  added: []
  patterns: [ramp-state-machine, danceability-ranking, effectiveBPM-dispatch]

key-files:
  created:
    - BeatStep/Models/RunMode.swift
    - BeatStep/Models/RampPhase.swift
    - BeatStep/Models/PacePreset.swift
    - BeatStepTests/PacePresetTests.swift
  modified:
    - BeatStep/Services/RunEngineService.swift
    - BeatStep/Services/BPMCacheService.swift
    - BeatStep/Services/GetSongBPMService.swift
    - BeatStep/Models/GetSongBPMResponse.swift
    - BeatStep/Models/CachedBPM.swift
    - BeatStepTests/RunEngineServiceTests.swift

key-decisions:
  - "Smart selection picks best-ranked track deterministically with 1-3 matches, random from top 3 with 4+ matches"
  - "8 BPM step size per song for warm-up/cool-down ramp progression"
  - "Warm-up starts at 140 BPM, clamps at target; cool-down clamps at 140"
  - "needsDiscovery flag exposed for testability; discovery fires non-blocking background Task"

patterns-established:
  - "effectiveBPM dispatch: free mode returns sustainedSPM, guided returns ramp-calculated BPM"
  - "Ramp state machine: warmUp -> atPace (on clamp hit), coolDown -> stopRun (on 140 clamp)"
  - "Smart selection: danceability-ranked sorting with preferHighEnergy flag based on mode/phase"

requirements-completed: [RUN-02, RUN-03, BPM-06]

# Metrics
duration: 11min
completed: 2026-03-23
---

# Phase 5 Plan 1: Guided Run Engine Summary

**Guided run engine with warm-up/cool-down ramp state machine, danceability-ranked smart selection, and on-demand catalog discovery**

## Performance

- **Duration:** 11 min
- **Started:** 2026-03-23T08:19:03Z
- **Completed:** 2026-03-23T08:30:38Z
- **Tasks:** 3
- **Files modified:** 10

## Accomplishments
- Built RunMode, RampPhase, PacePreset model enums with UserDefaults persistence following BPMTolerance pattern
- Implemented effectiveBPM computed property dispatching free mode (cadence) vs guided mode (ramp target with 8 BPM steps and clamping)
- Replaced randomElement() song selection with danceability-ranked smart selection in both free and guided modes
- Integrated on-demand BPMDiscoveryService when match pool drops below 3 tracks
- Added danceability field to GetSongBPMSong and CachedBPM with lightweight SwiftData migration
- All 44 in-scope tests pass (20 RunEngineServiceTests including 9 new, 8 PacePresetTests, 16 others)

## Task Commits

Each task was committed atomically:

1. **Task 1: RED - Models + failing tests** - `070deda` (test)
2. **Task 2: GREEN - Implement guided mode, ramp, smart selection, discovery** - `cab6ca4` (feat)
3. **Task 3: REFACTOR - Full test suite verification** - No changes needed (verify-only)

## Files Created/Modified
- `BeatStep/Models/RunMode.swift` - RunMode enum (free/guided) with UserDefaults persistence + savedTargetBPM
- `BeatStep/Models/RampPhase.swift` - RampPhase enum (warmUp/atPace/coolDown) with display labels
- `BeatStep/Models/PacePreset.swift` - Named pace presets (easyJog=150, steady=160, tempo=170, fast=180, sprint=190, custom=nil)
- `BeatStep/Models/GetSongBPMResponse.swift` - Added danceability: Int? to GetSongBPMSong
- `BeatStep/Models/CachedBPM.swift` - Added danceability: Int? with nil default for lightweight migration
- `BeatStep/Services/RunEngineService.swift` - effectiveBPM, ramp state machine, smart selection, discovery integration, startCoolDown()
- `BeatStep/Services/BPMCacheService.swift` - getDanceability/cacheDanceability methods
- `BeatStep/Services/GetSongBPMService.swift` - fetchBPMAndDanceability method
- `BeatStepTests/RunEngineServiceTests.swift` - 9 new tests for guided mode, ramp, smart selection, discovery
- `BeatStepTests/PacePresetTests.swift` - 8 tests for preset BPM values and display names

## Decisions Made
- Smart selection picks best-ranked track deterministically with 1-3 matches (avoids 50/50 randomness), random from top 3 with 4+ matches for variety
- 8 BPM step size per song for ramp progression (fits 3-5 songs for typical targets)
- Warm-up starts at 140 BPM, clamped to never overshoot target
- Cool-down auto-stops run when reaching 140 BPM
- needsDiscovery exposed as internal(set) for testability

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed smart selection randomness with small match pools**
- **Found during:** Task 2 (GREEN - implementing smart selection)
- **Issue:** With 2 matching tracks, top 3 randomization still gave 50/50 odds, defeating danceability ranking
- **Fix:** Changed to deterministic pick (first/best) when 3 or fewer matches, random from top 3 only with 4+ matches
- **Files modified:** BeatStep/Services/RunEngineService.swift
- **Verification:** testSmartSelectionRanksByDanceability passes consistently
- **Committed in:** cab6ca4 (Task 2 commit)

---

**Total deviations:** 1 auto-fixed (1 bug)
**Impact on plan:** Minor logic adjustment for correctness with small match pools. No scope creep.

## Issues Encountered
- Pre-existing test failures in SpotifyAuthServiceTests.testTrackParsing and SpotifyAPIServiceTests.testPlaylistTrackDecoding (mock data uses "track" key, model uses "item" key from Feb 2026 API change). Logged to deferred-items.md. Not caused by Phase 5 changes.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- All guided run engine logic is testable and tested
- Plan 02 (UI wiring) can wire RunView to RunMode segmented control, PacePreset picker, ramp phase labels, and Cool Down button
- effectiveBPM, runMode, rampPhase are all observable for SwiftUI binding

---
*Phase: 05-guided-run-polish*
*Completed: 2026-03-23*
