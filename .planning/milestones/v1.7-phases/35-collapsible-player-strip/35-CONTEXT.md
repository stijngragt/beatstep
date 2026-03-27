# Phase 35: Collapsible Player Strip - Context

**Gathered:** 2026-03-26
**Status:** Ready for planning

<domain>
## Phase Boundary

Two-state mini player: full strip (title, BPM badge, artist, play/pause, skip) that collapses to a thin drag handle via swipe or tap, and expands back. Collapse/expand state persists across app restarts.

</domain>

<decisions>
## Implementation Decisions

### Collapse/expand gesture
- **D-01:** Swipe down on expanded player to collapse + tap toggle as alternative. Both interaction modes supported.
- **D-02:** Swipe up on collapsed handle to expand + tap handle as alternative. Symmetric with collapse.
- **D-03:** Interactive drag — player follows finger during swipe, snaps to collapsed/expanded at threshold. Not direction-detect-then-animate.
- **D-04:** BSHaptics.light() fires when drag crosses threshold and snaps to new state. Consistent with existing play/pause/skip haptics.

### Collapsed handle design
- **D-05:** Pill bar only — centered capsule shape (~36pt wide, 4pt tall), no track name or play indicator. Minimal.
- **D-06:** Full-width ultraThinMaterial background bar (same as expanded state), just thinner (~20pt total height). Consistent visual stacking with tab bar.
- **D-07:** Keep existing top shadow (shadow(color: .black.opacity(0.1), radius: 4, y: -2)) on collapsed state. Visual continuity with expanded state.

### Content transition
- **D-08:** Fade + shrink — content fades out and bar height shrinks simultaneously during interactive drag. Opacity tied to drag progress.
- **D-09:** Cross-fade between content and pill handle during drag — pill fades in as content fades out. No moment where nothing is visible.

### State persistence
- **D-10:** Default state on fresh install: expanded. New users see full player, discover collapse organically.
- **D-11:** Always remember last user choice via @AppStorage. Once collapsed, stays collapsed across sessions, track changes, and app restarts. Matches existing @AppStorage patterns (RunZone, TempoMode, BPMTolerance).

### Claude's Discretion
- Drag threshold distance (e.g., 40pt vs percentage-based)
- Spring animation parameters for snap-to-state
- Exact collapsed bar height and pill dimensions
- Hit target area for the collapsed handle (likely larger than visual pill)
- Whether DragGesture or custom gesture approach is best for the interactive drag
- How the safeAreaInset height changes between states

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

No external specs — requirements fully captured in decisions above.

### Prior phase context
- `.planning/phases/34-player-dock-fix/34-CONTEXT.md` — Phase 34 dock fix decisions (safeAreaInset per tab, flush layout, material backgrounds)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `MiniPlayerView` (Views/Player/MiniPlayerView.swift): 90-line self-contained HStack with BPM badge, track info, controls — this is the content that gets collapsed
- `BSHaptics` (DesignSystem/BSHaptics.swift): Haptic tokens — `.light()` for snap feedback
- `BSAnimation` (DesignSystem/BSAnimation.swift): Spring animation tokens — `.smooth` for transitions
- `DesignTokens` (DesignSystem/DesignTokens.swift): Spacing, Radius constants

### Established Patterns
- Per-tab `.safeAreaInset(edge: .bottom, spacing: 0)` with `miniPlayerInset` ViewBuilder (ContentView.swift:67-72, 79, 89, 98)
- `@AppStorage` for persisting simple state — used in RunZone, TempoMode, BPMTolerance, ZeroBPMFallback, RunMode, LastRunPlaylist
- Timer-based gesture patterns over GestureState (LongPressStopButton.swift — DragGesture.onEnded is reliable, GestureState resets eagerly)
- `.transition(.opacity)` on conditional views throughout codebase (41 instances)
- `miniPlayerVisible` computed property gates player display (ContentView.swift:62-64)

### Integration Points
- `ContentView.swift:67-72` — `miniPlayerInset` ViewBuilder is where collapse/expand state would be introduced
- `ContentView.swift:74-109` — `authenticatedView` composes TabView with per-tab safeAreaInset
- `MiniPlayerView.swift` — May need to accept collapsed state or be wrapped in a parent that manages the two-state layout

</code_context>

<specifics>
## Specific Ideas

No specific requirements — open to standard approaches.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 35-collapsible-player-strip*
*Context gathered: 2026-03-26*
