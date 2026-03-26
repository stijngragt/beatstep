---
phase: 34-player-dock-fix
plan: 01
status: complete
started: 2026-03-26
completed: 2026-03-26
---

## One-Liner
Fixed mini player positioning by moving safeAreaInset from TabView to per-tab NavigationStacks, docking it flush above the tab bar on all screens.

## What Was Built
- Moved `.safeAreaInset(edge: .bottom)` from the `TabView` to each `NavigationStack`, so the mini player renders within each tab's content area — naturally above the tab bar
- Extracted `miniPlayerInset` as a shared `@ViewBuilder` property to avoid code duplication across tabs
- Removed redundant `Group` wrapper from MiniPlayerView body
- Added smooth transition animation for player show/hide

## Key Decisions
- `.safeAreaInset` on `TabView` places the view in the tab bar zone (overlapping it) — this is a SwiftUI limitation, not a bug in our code. The fix is to apply it per-tab instead.
- Applied `.safeAreaInset` on the `NavigationStack` (not inside it) so it persists across pushed views (e.g., playlist detail)

## Deviations
- Plan assumed removing the `Group` wrapper in MiniPlayerView would fix the issue. The actual root cause was `.safeAreaInset` placement level — on `TabView` vs on each `NavigationStack`.
- Human verification caught that the initial fix didn't work, leading to the correct approach.

## Key Files

### Modified
- `BeatStep/App/ContentView.swift` — safeAreaInset moved per-tab, miniPlayerInset extracted
- `BeatStep/Views/Player/MiniPlayerView.swift` — removed redundant Group wrapper

## Self-Check
- [x] Mini player docks above tab bar (verified by user)
- [x] Player visible on pushed views (playlist detail)
- [x] Tab bar items tappable
- [ ] Build verification skipped (CommandLineTools active, not Xcode.app)
