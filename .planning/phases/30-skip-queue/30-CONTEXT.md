# Phase 30: Skip Queue - Context

**Gathered:** 2026-03-26
**Status:** Ready for planning

<domain>
## Phase Boundary

Pre-built local track buffer so skipping a song during a run feels instant (~100ms, no spinner). Buffer serves both manual skips and natural song-end transitions. No queue UI — buffer is internal to RunEngineService.

</domain>

<decisions>
## Implementation Decisions

### Buffer Size & Refill
- **D-01:** 3-track pre-computed buffer — enough runway for rapid skipping
- **D-02:** Refill immediately after each skip/pop — async refill to maintain 3 tracks at all times
- **D-03:** Buffer serves ALL transitions — both manual skip and natural song-end use the buffer (replaces current on-demand computation in `queueNextMatch()`)

### Skip Rate Limiting
- **D-04:** 1-second cooldown between skips — prevents accidental double-taps while allowing fast skipping
- **D-05:** Current 5-second rate limit in `queueNextMatch()` is removed/replaced by the new 1-second cooldown
- **D-06:** When buffer is empty (all 3 skipped, refill in progress), skip button blocks until refill completes — no fallback to on-demand computation

### Cadence Drift Handling
- **D-07:** When sustained cadence change commits (after 17s debounce), invalidate buffer and rebuild with 3 new tracks at new cadence
- **D-08:** When user toggles tempo mode (1:1 <-> 1:2) mid-run, invalidate buffer and rebuild — tempo mode changes effective BPM range

### Claude's Discretion
- Internal buffer data structure (array, queue, etc.)
- Whether `selectNextMatch(forSPM:)` is called 3x upfront or refactored for batch selection
- How buffer interacts with the existing `playedTrackIDs` no-repeat pool
- Refill timing details (sync vs async, which thread)

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

No external specs — requirements fully captured in decisions above.

### Core Files
- `BeatStep/Services/RunEngineService.swift` — Contains `skipToNextMatch()`, `queueNextMatch()`, `selectNextMatch(forSPM:)`, song-end monitor, cadence monitor, and rate limiting logic. This is the primary file being modified.
- `BeatStep/Services/SpotifyPlayerService.swift` — Contains `play(uri:)` which the buffer will call. Note the 500ms sleep after play for state fetch.
- `BeatStep/Views/Run/ActiveRunView.swift` — Skip button calls `runEngine.skipToNextMatch()` via Task (line 83). May need update if skip becomes synchronous pop.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `selectNextMatch(forSPM:)` — Already handles BPM matching with danceability ranking, no-repeat pool, zero-BPM fallback, and discovery trigger. Can be called multiple times to fill buffer.
- `playedTrackIDs` — Existing no-repeat tracking. Buffer tracks should be registered here when selected (not when played) to avoid duplicates in buffer.
- `BSHaptics` — Design system haptic tokens available for skip feedback.

### Established Patterns
- `@ObservationIgnored` on private engine state — buffer array should follow this pattern
- `Task { @MainActor }` for async operations that touch observable state
- `isQueueingNext` guard flag pattern for preventing concurrent operations

### Integration Points
- `skipToNextMatch()` — Current public API, called by ActiveRunView. Will change from compute+play to pop-from-buffer+play.
- `queueNextMatch()` — Called by song-end monitor. Will change to pop-from-buffer+play.
- `onCadenceChanged()` — Where sustained change commits. Needs to trigger buffer invalidation.
- `tempoMode` setter — Needs to trigger buffer invalidation when changed mid-run.

</code_context>

<specifics>
## Specific Ideas

No specific requirements — open to standard approaches.

</specifics>

<deferred>
## Deferred Ideas

- **Queue visibility on active run screen** (RUN-05) — Future requirement. Buffer is internal-only for now, but can be made observable later.

None otherwise — discussion stayed within phase scope.

</deferred>

---

*Phase: 30-skip-queue*
*Context gathered: 2026-03-26*
