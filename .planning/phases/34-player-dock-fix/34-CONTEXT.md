# Phase 34: Player Dock Fix - Context

**Gathered:** 2026-03-26
**Status:** Ready for planning

<domain>
## Phase Boundary

Fix mini player vertical positioning so it sits flush above the tab bar with no overlap, no gap, and no double-padding. No new UI, no new features -- fix the existing layout pipeline.

</domain>

<decisions>
## Implementation Decisions

### Player-tab bar spacing
- **D-01:** Flush layout -- zero gap between mini player bottom edge and tab bar top edge. Apple Music style. Both already use `.ultraThinMaterial` blur backgrounds.
- **D-02:** Keep the existing top shadow (`shadow(color: .black.opacity(0.1), radius: 4, y: -2)`) on MiniPlayerView -- it separates player from scrollable content above.

### Scroll content inset
- **D-03:** Fix `.safeAreaInset(edge: .bottom)` on TabView -- this is the correct SwiftUI pattern. Debug why it's not working (likely a stacking/nesting issue) and fix the root cause. Do not switch to manual padding.
- **D-04:** When no track is playing (player hidden), content reclaims the space and extends to the tab bar. SwiftUI animates the transition. No reserved space when player is absent.

### Claude's Discretion
- Whether the fix requires restructuring the `.safeAreaInset` placement (e.g., moving it inside vs outside TabView)
- Whether additional `.ignoresSafeArea()` modifiers are needed on MiniPlayerView itself
- Whether the NavigationStack wrapping each tab contributes to the inset issue
- Exact approach to ensure tab bar items remain tappable (z-ordering, hit testing)

</decisions>

<canonical_refs>
## Canonical References

No external specs -- requirements fully captured in decisions above.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `MiniPlayerView` (Views/Player/MiniPlayerView.swift): Self-contained player bar with BPM, track info, controls -- no layout changes needed inside it
- `DesignTokens` (DesignSystem/DesignTokens.swift): Spacing, Radius constants used consistently

### Established Patterns
- `.safeAreaInset(edge: .bottom)` on TabView for bottom-docked overlays (ContentView.swift:90-94)
- `.ultraThinMaterial` for blur backgrounds on both player and tab bar
- `BSAnimation.smooth` for player show/hide transitions

### Integration Points
- `ContentView.swift:62-98` -- `authenticatedView` is where TabView + `.safeAreaInset` + MiniPlayerView are composed. This is the primary fix location.
- `ContentView.swift:90-94` -- Current `.safeAreaInset(edge: .bottom)` block that conditionally shows MiniPlayerView
- `MiniPlayerView.swift:78-82` -- Background + shadow styling that affects visual spacing

</code_context>

<specifics>
## Specific Ideas

No specific requirements -- the fix is well-scoped by the success criteria.

</specifics>

<deferred>
## Deferred Ideas

None -- discussion stayed within phase scope.

</deferred>

---

*Phase: 34-player-dock-fix*
*Context gathered: 2026-03-26*
