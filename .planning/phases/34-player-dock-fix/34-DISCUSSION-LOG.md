# Phase 34: Player Dock Fix - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md -- this log preserves the alternatives considered.

**Date:** 2026-03-26
**Phase:** 34-player-dock-fix
**Areas discussed:** Player-tab bar spacing, Scroll content inset

---

## Player-tab bar spacing

| Option | Description | Selected |
|--------|-------------|----------|
| Flush -- zero gap | Player bottom edge touches tab bar top edge. Apple Music style. | ✓ |
| Floating with gap | Small gap, rounded corners, more modern/distinctive. | |
| Blended material | One continuous blur from player through tab bar, subtle divider. | |

**User's choice:** Flush -- zero gap (Recommended)
**Notes:** Both player and tab bar already use ultraThinMaterial, so they'll look cohesive.

### Shadow follow-up

| Option | Description | Selected |
|--------|-------------|----------|
| Keep top shadow | Subtle upward shadow separates player from content above. | ✓ |
| Remove shadow | Clean flat edge, material blur transition only. | |
| You decide | Claude picks based on flush layout. | |

**User's choice:** Keep top shadow (Recommended)

---

## Scroll content inset

| Option | Description | Selected |
|--------|-------------|----------|
| Fix safeAreaInset | Keep .safeAreaInset(edge: .bottom), debug root cause. | ✓ |
| Manual padding | Remove safeAreaInset, add manual .padding(.bottom) per tab. | |
| You decide | Claude investigates and picks cleanest fix. | |

**User's choice:** Fix safeAreaInset (Recommended)

### Hidden state follow-up

| Option | Description | Selected |
|--------|-------------|----------|
| Reclaim space | Content fills to tab bar when player hidden. Animated. | ✓ |
| Always reserve | Fixed bottom inset even with no player. Prevents content jump. | |

**User's choice:** Reclaim space (Recommended)

---

## Claude's Discretion

- safeAreaInset placement restructuring
- ignoresSafeArea modifiers on MiniPlayerView
- NavigationStack contribution to inset issues
- Tab bar tappability approach

## Deferred Ideas

None
