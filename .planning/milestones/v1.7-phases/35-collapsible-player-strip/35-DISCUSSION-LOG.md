# Phase 35: Collapsible Player Strip - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-03-26
**Phase:** 35-collapsible-player-strip
**Areas discussed:** Collapse/expand gesture, Collapsed handle design, Content transition, State persistence

---

## Collapse/Expand Gesture

### How should the user collapse the expanded player?

| Option | Description | Selected |
|--------|-------------|----------|
| Swipe down only | Drag gesture on the player strip — swipe down to collapse. Natural, matches iOS sheet patterns. | |
| Swipe down + tap toggle | Swipe to collapse, but also tap the handle to expand and tap a collapse affordance to minimize. More discoverable. | ✓ |
| Tap only (no swipe) | Simple tap toggle between states. No drag gesture complexity. | |

**User's choice:** Swipe down + tap toggle
**Notes:** Both interaction modes for maximum discoverability.

### Should the swipe follow your finger or just detect direction?

| Option | Description | Selected |
|--------|-------------|----------|
| Interactive drag | Player moves with finger during swipe, snaps at threshold. Like iOS sheets and Apple Music. | ✓ |
| Direction detect + animate | Detect swipe direction, then animate. Simpler, no partial states. | |

**User's choice:** Interactive drag
**Notes:** Tactile, physical feel preferred.

### Should swiping up on the collapsed handle also be interactive?

| Option | Description | Selected |
|--------|-------------|----------|
| Swipe up + tap | Both gestures work symmetrically. Consistent with collapse behavior. | ✓ |
| Tap only to expand | Collapse is swipe-driven, expand is tap-only. Handle is small target. | |

**User's choice:** Swipe up + tap
**Notes:** Symmetric gestures in both directions.

### Should collapsing include a haptic?

| Option | Description | Selected |
|--------|-------------|----------|
| Light haptic on snap | BSHaptics.light() when drag crosses threshold. Consistent with play/pause/skip. | ✓ |
| No haptic | Silent transition — animation is enough feedback. | |
| You decide | Claude picks the right haptic intensity. | |

**User's choice:** Light haptic on snap
**Notes:** Consistent with existing haptic patterns.

---

## Collapsed Handle Design

### What should the collapsed handle look like?

| Option | Description | Selected |
|--------|-------------|----------|
| Pill bar only | Minimal centered pill/capsule shape. Clean, recognizable. | ✓ |
| Pill + track name | Pill handle with single-line truncated track name. Compact but informative. | |
| Pill + play indicator | Pill handle with animated bouncing bars to show music playing. | |

**User's choice:** Pill bar only
**Notes:** Maximum minimalism — ~36pt wide, 4pt tall, textTertiary color.

### Should the collapsed handle keep the ultraThinMaterial background bar?

| Option | Description | Selected |
|--------|-------------|----------|
| Full-width material bar | Same ultraThinMaterial, just thinner (~20pt). Consistent visual stacking. | ✓ |
| Floating pill only | No background bar — pill floats between content and tab bar. | |

**User's choice:** Full-width material bar
**Notes:** Consistent with tab bar material below.

### Should the collapsed handle keep the top shadow?

| Option | Description | Selected |
|--------|-------------|----------|
| Keep shadow | Same shadow as expanded state. Visual continuity. | ✓ |
| No shadow when collapsed | Drop shadow for thin state — may look heavy. | |
| You decide | Claude picks based on material bar thickness. | |

**User's choice:** Keep shadow
**Notes:** Visual continuity between both states.

---

## Content Transition

### How should the content disappear when collapsing?

| Option | Description | Selected |
|--------|-------------|----------|
| Fade + shrink | Content fades out and bar height shrinks simultaneously during drag. Opacity tied to progress. | ✓ |
| Clip + shrink | Content clips from bottom as bar shrinks — like a closing drawer. | |
| You decide | Claude picks transition approach for interactive drag + BSAnimation.smooth. | |

**User's choice:** Fade + shrink
**Notes:** Unified motion — opacity and height interpolate together.

### When should the pill handle appear during collapse?

| Option | Description | Selected |
|--------|-------------|----------|
| Cross-fade during drag | Pill fades in as content fades out — smooth handoff during drag. | ✓ |
| Pill appears after snap | Content fades during drag, pill pops in after snap completes. Two-beat rhythm. | |

**User's choice:** Cross-fade during drag
**Notes:** No moment where nothing is visible. Continuous transition.

---

## State Persistence

### What should the default state be on fresh install?

| Option | Description | Selected |
|--------|-------------|----------|
| Expanded | New users see full player with all info. Discover collapse naturally. | ✓ |
| Collapsed | Minimal by default — user expands when they want more info. | |
| You decide | Claude picks based on success criteria. | |

**User's choice:** Expanded
**Notes:** Matches success criteria — users see title, BPM, and controls by default.

### Should collapse state reset when playback stops?

| Option | Description | Selected |
|--------|-------------|----------|
| Always remember | Stays collapsed across sessions and track changes. Respect user choice. | ✓ |
| Reset on new session | Collapse state resets to expanded when app restarts. | |
| You decide | Claude picks persistence behavior. | |

**User's choice:** Always remember
**Notes:** Matches existing @AppStorage patterns. User explicitly chose to minimize.

---

## Claude's Discretion

- Drag threshold distance
- Spring animation parameters for snap-to-state
- Exact collapsed bar height and pill dimensions
- Hit target area for collapsed handle
- DragGesture approach for interactive drag
- safeAreaInset height changes between states

## Deferred Ideas

None — discussion stayed within phase scope.
