---
phase: 04-core-loop-free-run
plan: 01
subsystem: services
tags: [bpm-matching, cadence, spotify-playback, orchestration, swift, tdd]

# Dependency graph
requires:
  - phase: 01-spotify-integration
    provides: SpotifyPlayerService with play(uri:) playback control
  - phase: 02-bpm-data-pipeline
    provides: BPMCacheService with getBPM(forTrackID:) cached BPM lookup
  - phase: 03-cadence-detection
    provides: CadenceService with live currentSPM and state observables
provides:
  - RunEngineService orchestrator wiring cadence to BPM-matched Spotify playback
  - BPMTolerance enum with Tight/Normal/Loose presets and UserDefaults persistence
  - Half/double BPM matching (170 SPM matches 85 and 340 BPM songs)
  - No-repeat pool management with auto-reset on exhaustion
  - Sustained cadence change detection with 17s debounce
  - Song-end detection via polling with race condition guard
affects: [04-02 (RunView UI wiring, tolerance picker, skip override)]

# Tech tracking
tech-stack:
  added: []
  patterns: [orchestrator-service, in-memory-bpm-map, sustained-change-debounce, no-repeat-pool]

key-files:
  created:
    - BeatStep/Models/BPMTolerance.swift
    - BeatStep/Services/RunEngineService.swift
    - BeatStepTests/BPMToleranceTests.swift
    - BeatStepTests/RunEngineServiceTests.swift
  modified: []

key-decisions:
  - "In-memory bpmMap loaded at run start to avoid repeated @MainActor BPMCacheService queries"
  - "evaluateCadenceChange is synchronous for testability; async debounce timer lives in cadence monitor"
  - "loadForTesting/setSustainedSPMForTesting helpers expose internal state for unit tests"
  - "play(uri:) without contextURI prevents Spotify auto-advance to next playlist track"

patterns-established:
  - "Orchestrator singleton: @Observable with @ObservationIgnored on all private stored properties"
  - "Testing helpers: loadForTesting method to inject state without mocking singletons"
  - "Rate limit safety floor: max one Spotify play call per 5 seconds"

requirements-completed: [BPM-02, BPM-03, BPM-04, RUN-01]

# Metrics
duration: 7min
completed: 2026-03-20
---

# Phase 4 Plan 1: RunEngineService + BPMTolerance Summary

**Core orchestration engine matching runner cadence to BPM-matched Spotify songs with half/double matching, sustained change detection, and no-repeat pool management**

## Performance

- **Duration:** 7 min
- **Started:** 2026-03-20T18:12:02Z
- **Completed:** 2026-03-20T18:19:12Z
- **Tasks:** 3 (TDD: RED, GREEN, REFACTOR)
- **Files created:** 4

## Accomplishments
- BPMTolerance enum with Tight (+/-3), Normal (+/-7), Loose (+/-12) presets and UserDefaults persistence
- RunEngineService orchestrates full cadence-to-playback pipeline: observe SPM, match BPM (direct + half + double), select from no-repeat pool, play via Spotify
- Sustained change detection prevents frenetic song switching (17s debounce timer with cancellation on revert)
- Fallback to closest BPM ensures silence never occurs
- 18 tests passing (7 BPMTolerance + 11 RunEngineService)

## Task Commits

Each task was committed atomically:

1. **Task 1: RED - Failing tests** - `3d85a62` (test)
2. **Task 2: GREEN - Implementation** - `31ff0c2` (feat)
3. **Task 3: REFACTOR - Verification** - No changes needed, code clean

**Plan metadata:** (pending)

_TDD flow: RED (failing tests) -> GREEN (implementation) -> REFACTOR (verification only)_

## Files Created/Modified
- `BeatStep/Models/BPMTolerance.swift` - Tolerance enum with range values and UserDefaults persistence
- `BeatStep/Services/RunEngineService.swift` - Core orchestration: cadence observation, BPM matching, playback control, sustained change detection, song-end monitoring
- `BeatStepTests/BPMToleranceTests.swift` - Unit tests for tolerance range values, default, persistence, CaseIterable
- `BeatStepTests/RunEngineServiceTests.swift` - Unit tests for matching, half/double, fallback, no-repeat pool, sustained change, lifecycle

## Decisions Made
- Loaded playlist BPMs into in-memory dictionary at run start to avoid repeated @MainActor BPMCacheService SwiftData queries
- Made evaluateCadenceChange synchronous (returns Bool) for direct unit testing; async debounce timer lives in the private cadence monitor
- Added loadForTesting/setSustainedSPMForTesting helpers to expose internal state for unit tests without mocking singletons
- Used play(uri:) without contextURI to prevent Spotify from auto-advancing to next playlist track after song ends

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
- Pre-existing crash in SpotifyAuthServiceTests.testTrackParsing (force unwrap on mock data using old `track` field vs new `item` field). Not caused by Phase 4 changes. Logged to deferred-items.md.
- Xcode CLI tools pointed to CommandLineTools instead of Xcode.app; used DEVELOPER_DIR override.
- iPhone 16 simulator not available; used iPhone 17 Pro (iOS 26.2).

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- RunEngineService ready for UI wiring in Plan 04-02
- Plan 04-02 will add tolerance picker to RunView, wire Start Run to engine, and override skip behavior during active run
- All matching logic tested and verified

## Self-Check: PASSED

All 4 files verified on disk. Both task commits (3d85a62, 31ff0c2) verified in git log.

---
*Phase: 04-core-loop-free-run*
*Completed: 2026-03-20*
