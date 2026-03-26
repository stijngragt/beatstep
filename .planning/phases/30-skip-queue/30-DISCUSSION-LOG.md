# Phase 30: Skip Queue - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-03-26
**Phase:** 30-skip-queue
**Areas discussed:** Buffer size & refill, Skip rate limiting, Cadence drift handling

---

## Buffer Size & Refill

### Buffer size

| Option | Description | Selected |
|--------|-------------|----------|
| 2 tracks (Recommended) | Enough for instant skip + one more while refilling. Minimal memory, fast refill. | |
| 3 tracks | More runway for rapid skipping. Slightly more computation upfront but still lightweight. | ✓ |
| 1 track | Minimal — just the next song. Simpler but no buffer depth if user skips twice quickly. | |

**User's choice:** 3 tracks
**Notes:** None

### Refill timing

| Option | Description | Selected |
|--------|-------------|----------|
| Immediately after skip (Recommended) | Each skip pops one track and triggers async refill to maintain 3. | ✓ |
| Background timer | Refill on a periodic check (e.g., every 5s). Simpler but buffer could be empty if user skips rapidly. | |
| You decide | Claude picks the approach that works best with the existing RunEngineService architecture. | |

**User's choice:** Immediately after skip
**Notes:** None

### Song-end transitions

| Option | Description | Selected |
|--------|-------------|----------|
| Yes — use buffer for all transitions (Recommended) | Song ends naturally → pop from buffer. Consistent fast transitions everywhere. | ✓ |
| No — buffer for manual skip only | Song-end monitor keeps current behavior (compute on demand). Buffer exclusively serves skip button. | |

**User's choice:** Yes — use buffer for all transitions
**Notes:** None

---

## Skip Rate Limiting

### Rapid-fire skip handling

| Option | Description | Selected |
|--------|-------------|----------|
| 1-second cooldown (Recommended) | Allow fast skipping but prevent accidental double-taps. | ✓ |
| No cooldown | Every tap skips immediately. Buffer depth is the only limit. | |
| Haptic-only feedback | No rate limit, but warning haptic if buffer empty. | |

**User's choice:** 1-second cooldown
**Notes:** None

### Empty buffer behavior

| Option | Description | Selected |
|--------|-------------|----------|
| Block skip until refill (Recommended) | Skip button becomes non-interactive briefly. Refill is fast (local computation). | ✓ |
| Fall back to on-demand | If buffer empty, compute + play synchronously like current behavior. | |
| You decide | Claude picks the best UX for empty buffer edge case. | |

**User's choice:** Block skip until refill
**Notes:** None

---

## Cadence Drift Handling

### Sustained cadence change

| Option | Description | Selected |
|--------|-------------|----------|
| Invalidate & rebuild (Recommended) | Clear buffer and re-select 3 tracks at new cadence. 17s debounce already filters noise. | ✓ |
| Play through, then rebuild | Let current buffer drain naturally. Next refill uses new cadence. | |
| You decide | Claude picks based on how the debounce and song-end monitor interact. | |

**User's choice:** Invalidate & rebuild
**Notes:** None

### Tempo mode toggle

| Option | Description | Selected |
|--------|-------------|----------|
| Yes — invalidate on toggle (Recommended) | Tempo mode changes effective BPM range. Same invalidate-and-rebuild logic. | ✓ |
| No — let buffer drain | Tempo toggle is rare. Current buffer plays out, next refill uses new mode. | |

**User's choice:** Yes — invalidate on toggle
**Notes:** None

---

## Claude's Discretion

- Internal buffer data structure
- Whether `selectNextMatch(forSPM:)` is called 3x or refactored for batch
- How buffer interacts with `playedTrackIDs`
- Refill timing details (sync vs async, thread)

## Deferred Ideas

- Queue visibility on active run screen (RUN-05) — future requirement
