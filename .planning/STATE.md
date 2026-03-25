---
gsd_state_version: 1.0
milestone: v1.4
milestone_name: Under The Hood
status: in-progress
stopped_at: Completed 21-01-PLAN.md
last_updated: "2026-03-25T12:20:21.000Z"
last_activity: 2026-03-25 -- Plan 21-01 complete (ZeroBPMFallback enum + Settings picker)
progress:
  total_phases: 5
  completed_phases: 3
  total_plans: 8
  completed_plans: 8
  percent: 100
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-03-25)

**Core value:** When you run, your music should move with you -- every footstrike landing on the beat.
**Current focus:** Phase 21 - Zero-BPM Fallback

## Current Position

Phase: 21 of 22 (Zero-BPM Fallback) -- fourth of 5 v1.4 phases
Plan: 2 of 2 complete
Status: Complete
Last activity: 2026-03-25 -- Plan 21-02 complete (ZeroBPMFallback wired into RunEngineService)

Progress: [██████████] 100%

## Performance Metrics

**Velocity:**
- Total plans completed: 38 (11 v1.0, 7 v1.1, 6 v1.2, 8 v1.3, 6 v1.4)
- v1.0: 5 days, 11 plans
- v1.1: 2 days, 7 plans
- v1.2: 1 day, 6 plans
- v1.3: 2 days, 8 plans
- v1.4: in progress, 6 plans

| Phase | Plan | Duration | Tasks | Files |
|-------|------|----------|-------|-------|
| 19-01 | confidence-badge-data | 6min | 2 | 6 |
| 19-02 | confidence-badges-view | 7min | 2 | 1 |
| 20-01 | tap-bpm-engine | 7min | 2 | 3 |
| 20-02 | tap-bpm-view | 28min | 2 | 3 |
| 21-01 | zero-bpm-fallback-model | 9min | 2 | 4 |
| 21-02 | zero-bpm-fallback-engine | 6min | 1 | 2 |

## Accumulated Context

### Decisions

Full decision log in PROJECT.md Key Decisions table.

- [18-01] Lazy backfill pattern: nil raw + non-nil bpm returns .verified/.api without migration
- [18-01] Write paths use confidenceRaw (String?) directly, never computed property
- [18-01] Updated existing test files in 18-01 (originally 18-02 scope) since removing cache() broke compilation
- [18-02] Task 1 no-op: rename already done in 18-01 as Rule 3 deviation
- [19-01] BPMInfo uses let properties for immutability -- view layer receives read-only snapshots
- [19-01] stateApproximate blue (0.35, 0.55, 0.95) distinct from existing state colors
- [19-02] No-BPM tracks use muted gray capsule with -- BPM text for consistent row alignment
- [20-01] 40% median-deviation threshold for outlier rejection (tunable constant)
- [20-01] Boundary rejection at <0.2s and >2.0s before median check
- [20-01] tapCount tracks tap events (1-indexed), not intervals
- [20-02] Button wrapping on badge for gesture separation -- badge tap opens sheet, row tap plays track
- [20-02] ShakeModifier with offset-based animation for outlier rejection visual feedback
- [21-01] Default fallback is .skip preserving current behavior for existing users
- [21-02] Separate playedNilBPMIDs set for independent nil-BPM pool cycling
- [21-02] Prompt fallback shares playRegardless code path (plays track) -- future phase adds UI overlay

### Pending Todos

None.

### Blockers/Concerns

- Spotify Premium detection timing during onboarding is an unresolved product decision (carried from v1.2)
- SwiftData migration must use optional String? fields to trigger lightweight migration (from research)
- Prompt fallback UX during active run may need deferral if skip + playRegardless cover the need (from research)
- Pre-existing test failure: SpotifyAPIServiceTests.testPlaylistTrackDecoding (XCTUnwrap on SpotifyTrack)

## Session Continuity

Last session: 2026-03-25T12:29:30Z
Stopped at: Completed 21-02-PLAN.md (Phase 21 complete)
Resume file: Next milestone phase
