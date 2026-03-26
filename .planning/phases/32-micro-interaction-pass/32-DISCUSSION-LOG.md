# Phase 32: Micro-Interaction Pass - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-03-26
**Phase:** 32-micro-interaction-pass
**Areas discussed:** Haptic mapping, Animation token selection

---

## Haptic Mapping

### Q1: What haptic style for standard button taps?

| Option | Description | Selected |
|--------|-------------|----------|
| Light impact | Subtle tap confirmation. Differentiates buttons from selection changes. Apple HIG recommended. | ✓ |
| Medium impact | More noticeable thud. Same weight as swipe actions. | |
| Selection feedback | Softest click. Would blur line between buttons and pickers. | |

**User's choice:** Light impact
**Notes:** None

### Q2: Should destructive actions have a distinct haptic?

| Option | Description | Selected |
|--------|-------------|----------|
| Warning haptic | Distinct double-tap feel. Already used for failed scan. | ✓ |
| Same as normal buttons | Red color and confirmation dialog already signal destructive. | |
| Heavy impact | Strong single thud. Less semantically meaningful. | |

**User's choice:** Warning haptic
**Notes:** None

### Q3: Haptics during active run?

| Option | Description | Selected |
|--------|-------------|----------|
| Only user actions | Skip, play/pause, tempo toggle, stop only. Prevents haptic fatigue. | ✓ |
| Sync state transitions too | Physical awareness of pace drift. | |
| No run haptics at all | Phone in pocket may not feel them. | |

**User's choice:** Only user actions
**Notes:** None

---

## Animation Token Selection

### Q1: Animation token mapping for interactive elements?

| Option | Description | Selected |
|--------|-------------|----------|
| Layered mapping | .snappy for taps, .smooth for content, .gentle for background, .quick for micro-feedback, .page for navigation | ✓ |
| Two-tier simple | .snappy for user actions, .smooth for system transitions | |
| Context-specific | Different per view area | |

**User's choice:** Layered mapping
**Notes:** None

### Q2: Conditional view transitions?

| Option | Description | Selected |
|--------|-------------|----------|
| .opacity everywhere | Consistent crossfade for all conditional views. Extends Phase 31 pattern. | ✓ |
| Vary by context | .opacity for swaps, .slide for reveals, .scale for modals | |
| Only where noticeable | Skip small elements that don't feel jarring | |

**User's choice:** .opacity everywhere
**Notes:** None

### Q3: Run screen animation scoping?

| Option | Description | Selected |
|--------|-------------|----------|
| Animate only UI chrome | Sync badge, zone band, ramp phase. NOT cadence/BPM numbers. | ✓ |
| Animate everything with .quick | 0.15s easeOut for all including numbers | |
| No animations on run screen | All data-driven, keep static | |

**User's choice:** Animate only UI chrome
**Notes:** None

---

## Claude's Discretion

- File-by-file inventory of which views need additions
- Implementation order and batching strategy
- Onboarding transition details

## Deferred Ideas

None
