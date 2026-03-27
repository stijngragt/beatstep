# Phase 37: Beat Sync Badge - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-03-27
**Phase:** 37-beat-sync-badge
**Areas discussed:** Badge design, Tempo matching logic, Badge placement

---

## Badge Design

### Badge appearance

| Option | Description | Selected |
|--------|-------------|----------|
| Evolve SyncBadge | Add SF Symbol icon to existing capsule, consistent with Phase 19 badges | ✓ |
| Visual indicator only | Pulsing dot/ring instead of text — more ambient | |
| Icon + percentage | Numeric match percentage (e.g., "92% sync") | |
| You decide | Claude picks based on existing patterns | |

**User's choice:** Evolve SyncBadge
**Notes:** Keeps consistency with Phase 19 confidence badge pattern (icon + text in capsule)

### Label text

| Option | Description | Selected |
|--------|-------------|----------|
| Keep text labels | "In Sync", "Drifting", "Mismatched" — unambiguous at a glance | ✓ |
| Icon + color only | Compact but runner needs to learn visual language | |
| Adaptive | Text initially, fade to icon-only after stable sync | |

**User's choice:** Keep text labels

### SF Symbol icons

| Option | Description | Selected |
|--------|-------------|----------|
| Waveform set | waveform.path.ecg / waveform.badge.minus / waveform.slash — rhythm metaphor | ✓ |
| Circle set | checkmark.circle.fill / exclamationmark.circle / xmark.circle — universal status | |
| Beat/metronome set | metronome.fill / metronome / pause.circle — music-specific | |
| You decide | Claude picks icons for labelText size | |

**User's choice:** Waveform set

---

## Tempo Matching Logic

### Half/double handling

| Option | Description | Selected |
|--------|-------------|----------|
| Normalize before comparing | Check 2x/0.5x multiples, compare normalized value — badge shows "In Sync" for valid tempo multiples | ✓ |
| Show as special state | Distinct badge state like "Half Sync" or "2x Sync" with unique color | |
| You decide | Claude picks cleanest approach | |

**User's choice:** Normalize before comparing

### Tempo multiples

| Option | Description | Selected |
|--------|-------------|----------|
| Half and double only | 0.5x and 2x — covers 95% of scenarios | ✓ |
| Include triple | 0.5x, 2x, and 3x — edge case for waltz-tempo | |
| You decide | Claude picks based on running cadence range | |

**User's choice:** Half and double only

---

## Badge Placement

### Location

| Option | Description | Selected |
|--------|-------------|----------|
| Keep in status bar | Top-right in RunStatusBar — established position, minimal change | ✓ |
| Move to hero area | Near cadence display — more prominent | |
| Both locations | Status bar AND cadence area — maximum visibility but redundant | |

**User's choice:** Keep in status bar

### CadenceDisplayView redundancy

| Option | Description | Selected |
|--------|-------------|----------|
| Remove from CadenceDisplay | Badge is single source of sync info — cadence shows just number + trend | ✓ |
| Keep both | Redundant but visible wherever runner looks | |
| You decide | Claude picks for visual hierarchy | |

**User's choice:** Remove from CadenceDisplay

---

## Claude's Discretion

- Exact normalization algorithm
- Icon sizing
- Normalization code location
- Animation behavior
- No-track-playing edge case

## Deferred Ideas

None — discussion stayed within phase scope
