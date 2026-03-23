# Feature Research

**Domain:** iOS fitness app dark-mode UI, design system, tab navigation, brand identity (v1.1 "Dark by Design")
**Researched:** 2026-03-23
**Confidence:** HIGH

## Scope Note

This file covers NEW features for v1.1 only. Core running features (cadence detection, BPM matching, Spotify playback, free/guided run, smart selection) are shipped in v1.0. Research below addresses: dark-mode commitment, design system tokens, tab navigation, track count bug, and app icon/wordmark.

---

## Feature Landscape

### Table Stakes (Users Expect These)

Features users assume exist in a polished iOS fitness app. Missing = product feels unfinished.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Consistent dark-mode UI | Fitness apps (Strava, Nike Run, Apple Fitness) are all dark-native. Dark UI is category standard for anything used outdoors or at night. Light-mode flash or inconsistent rendering signals unfinished product. | LOW | `.preferredColorScheme(.dark)` on root `WindowGroup` in `BeatStepApp.swift`. Also set `UIUserInterfaceStyle = Dark` in Info.plist. Enforces dark throughout including sheets, alerts, system pickers. |
| Semantic color tokens | Apple HIG requires consistent color usage. Without tokens, hex values diverge across views in a single sprint. Fitness apps with a strong color identity (orange Strava, Activity rings) make it work through discipline, not luck. | MEDIUM | `DesignSystem.swift` with nested `Colors`, `Typography`, `Spacing` enums. Static vars on `Color` extension: `.accent`, `.backgroundBase`, `.backgroundElevated`, `.backgroundCard`, `.textPrimary`, `.textSecondary`. Assets.xcassets for any adaptive colors. |
| Bottom tab navigation | iOS navigation convention since iOS 2. TabView with Library/Run/Settings mirrors how every major fitness app structures top-level content. Gearshape in toolbar is not discoverable. | MEDIUM | Replaces current `NavigationStack` + toolbar gearshape in `ContentView.swift`. `TabView` wraps three top-level views. MiniPlayer overlay must persist across all tabs — wrap `TabView` in `ZStack(alignment: .bottom)` with `MiniPlayerView()` floating above. |
| App icon with brand identity | Required for App Store, Home Screen, and user recall. A dark icon with an electric accent reads immediately as high-energy, distinct from generic blue-and-white fitness icons. | MEDIUM | Design artifact + asset catalog entry. Must cover all required iOS sizes. Icon Composer (Xcode 16+) supports layered icons for iOS 26 liquid-glass format, but a strong single-layer icon ships now without it. |
| Working track count display | "0 tracks" on a playlist row destroys trust in data integrity. Users see this and wonder if the app is broken or unconnected. | LOW | Bug: Spotify's paginated playlist endpoint returns `tracks` as `null` (or `total: 0`) for algorithmic playlists (Discover Weekly, Radio, Mixes). `SpotifyPlaylist.trackCount` returns `tracks?.total ?? 0` — correct fallback, but the UI should handle zero gracefully. Fix: show "—" instead of "0 tracks", or fetch track count on playlist detail load for zero-count playlists. |

### Differentiators (Competitive Advantage)

Features that distinguish BeatStep's aesthetic and identity within the category.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Electric green accent (#39FF14 range) | Most fitness apps use blue, orange, or white. Electric/neon green reads as high-energy, tech-forward, and distinct at a glance. No major competitor owns it. | LOW | Single accent color. Reserve for: active/selected states, progress indicators, primary CTAs, cadence pulse animations, tab bar selected state. Avoid overuse — foreground on dark backgrounds only, never as text on accent background (contrast risk). |
| Opinionated near-black base (not system gray) | System dark `#1C1C1E` looks generic iOS. Custom near-black (`#0D0D0D` or `#111111`) with two elevated surface levels creates depth and a premium feel that separates the app from stock SwiftUI. | LOW | Three background levels: `backgroundBase` (darkest, main bg), `backgroundElevated` (cards, list rows), `backgroundCard` (modals, overlays). Avoid flat single-surface treatment. |
| SF Pro Rounded for numeric displays | Standard SF Pro reads cleanly, but SF Pro Rounded for BPM, cadence, and SPM numbers communicates energy and rhythm. Rounder numerals feel alive vs angular in a fitness context. Nike and Strava both use custom typefaces for this reason. | LOW | Not a custom font — SF Pro Rounded is a built-in variant. Use `.fontDesign(.rounded)` modifier on numeric displays. Define as a token: `DesignSystem.Typography.numericDisplay`. |
| Wordmark as identity anchor | A simple wordmark (BEATSTEP or B/ mark) in the nav bar or as a tab bar header communicates product identity on every screen without adding visual noise. | LOW | Design decision + asset. Keep it minimal — weight and letter-spacing do the work. Avoid decorative glyphs that don't scale to small sizes. Same mark used in icon and wordmark for coherence. |

### Anti-Features (Commonly Requested, Often Problematic)

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| Light mode support | "Some users prefer light mode" | v1.1 goal is intentional dark identity. Splitting design decisions doubles QA surface and dilutes the aesthetic commitment. Fitness app users skew toward dark mode anyway (AMOLED battery, outdoor visibility). Revisit in v2 only if feedback is loud. | Lock to dark via `.preferredColorScheme(.dark)` on `WindowGroup`. Set `UIUserInterfaceStyle: Dark` in Info.plist as belt-and-suspenders. |
| Custom tab bar component from scratch | "Native TabView looks generic" | Custom tab bar requires handling: safe area insets, accessibility labels, keyboard avoidance, state restoration, and gesture conflicts manually. High effort, fragile on new iOS versions. iOS 26 also introduced native liquid-glass tab bar — fighting it adds maintenance debt. | Use native `TabView`. Style via `.tint(DesignSystem.Colors.accent)`. Customize via SF Symbols (fill vs outline for selected state). Achieve distinctive look within the native container. |
| Gradient accent colors | "More dynamic energy feel" | Gradients on interactive elements cause contrast ratio failures (WCAG), are hard to maintain consistently, and date faster than solid colors. | Solid electric green for interactive states. Subtle radial gradient acceptable on background layers or cards only — not on text, icons, or buttons. |
| Multiple accent colors (one per tab) | "Each section has its own identity" | Color-coded tabs fragment the visual system. Every new dev touchpoint requires a color decision. Reduces brand coherence. | Single accent throughout. Tab identity comes from icon shape + label, not color. |
| Alternate icon variants (light/tinted/dark) at launch | "iOS 18 supports adaptive icons" | Three mediocre icons ship worse than one excellent icon. Alternate variants are a polish-pass feature. | Design one icon excellently. iOS 18/26 Icon Composer handles adaptive tinting automatically for apps that opt in. Ship the base icon first. |

---

## Feature Dependencies

```
Dark-mode enforcement (.preferredColorScheme)
    └── requires: Nothing (applies at BeatStepApp root)
    └── enables: Consistent rendering for all subsequent visual work

Design system tokens (DesignSystem.swift)
    └── requires: Dark-mode decision locked (so tokens are dark-only)
    └── enables: All view files using consistent colors
    └── enables: Tab bar tint color via .tint()
    └── enables: Typography tokens for view updates

Tab navigation (TabView replacing ContentView)
    └── requires: Design system tokens (accent for .tint)
    └── requires: MiniPlayer overlay refactor
            MiniPlayer currently lives inside NavigationStack ZStack
            After: ZStack wraps TabView, MiniPlayer floats above
    └── enables: Settings as first-class tab (no more gearshape)
    └── enables: Run tab accessible without entering a playlist first

Track count bug fix
    └── requires: Nothing
    └── independent of: All other v1.1 features
    └── note: Isolated to SpotifyPlaylist model + PlaylistListView/PlaylistDetailView display

App icon
    └── requires: Design system accent color hex (must be finalized before icon design)
    └── independent of: All code changes (asset catalog only)

Wordmark
    └── requires: Design system typeface decision
    └── enhances: App icon (same mark used in both)
    └── optional dependency: Tab navigation (wordmark placement in nav bar determined by tab structure)
```

### Dependency Notes

- **Tab navigation requires MiniPlayer refactor.** Current `ContentView.swift` uses `ZStack(alignment: .bottom)` with `MiniPlayerView()` as a child of the NavigationStack zone. When TabView replaces NavigationStack as root, the MiniPlayer must float above all three tabs. Solution: `ZStack(alignment: .bottom)` where `TabView` is background layer and `MiniPlayerView()` sits on top. `.safeAreaInset(edge: .bottom)` on TabView reserves height so tab content scrolls above mini-player.

- **Design tokens must be defined before any view edits.** Without `DesignSystem.Colors.accent` defined, views get hardcoded hex values that need a second cleanup pass. Token definition is a 30-minute task that gates everything else.

- **Track count bug is isolated.** `SpotifyPlaylist.trackCount` computes `tracks?.total ?? 0`. The Spotify API returns `tracks: null` for algorithmic playlists (Discover Weekly, Daily Mixes, Radio). The view shows "0 tracks" which is confusing. Fix options: (a) show "—" when count is 0, (b) display nothing, (c) fetch actual count from playlist detail endpoint for zero-count playlists. Option (a) is lowest risk and requires only a view change. No dependency on any other v1.1 feature.

- **Run tab design decision needed.** Currently `RunView` is only reachable via `NavigationLink` from `PlaylistDetailView`. A Run tab can either: (a) show "select a playlist first" when no playlist is active, or (b) show last-used playlist context. This decision must be made before implementing tab navigation.

---

## MVP Definition

### This Milestone (v1.1) — All Five Features

No deferral. All items are tightly scoped and independent enough to build in parallel after design tokens are defined.

- [ ] Dark-mode enforcement — single modifier at root, zero regression risk
- [ ] Design system tokens (DesignSystem.swift) — additive file, no existing code breaks
- [ ] Tab navigation (Library / Run / Settings) — replaces NavigationStack + toolbar gearshape; requires MiniPlayer refactor
- [ ] Track count bug fix — isolated model/view change
- [ ] App icon + wordmark — design artifact + asset catalog

### Add After Validation (v1.x)

- [ ] Dynamic Type support — accessibility; add after token system is stable so size tokens can scale
- [ ] Light mode — only if users explicitly request it in meaningful volume
- [ ] Alternate icon variants (light/tinted) — iOS 18 adaptive icon polish pass

### Future Consideration (v2+)

- [ ] Haptic design system — tactile feedback synchronized with accent color interactions
- [ ] Animated SF Symbols tab icons — SF Symbols 7 draw animations; high delight, low priority
- [ ] Onboarding redesign — LoginView needs brand polish once identity is validated

---

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| Design system tokens | HIGH — gates all visual work | LOW — additive, no breakage | P1 |
| Dark-mode enforcement | HIGH — removes inconsistent rendering | LOW — one modifier | P1 |
| Tab navigation | HIGH — discoverability of Settings/Run is currently poor | MEDIUM — MiniPlayer refactor is the complexity | P1 |
| Track count bug fix | MEDIUM — data integrity perception | LOW — isolated change | P1 |
| App icon + wordmark | MEDIUM — brand recall; no impact on functionality | MEDIUM — design time, not engineering time | P1 |

**Priority key:**
- P1: Must have for this milestone (all five are P1 for v1.1)
- P2: Should have, add when possible
- P3: Nice to have, future consideration

---

## Existing Code Integration Points

These are not pitfalls — see PITFALLS.md — but sequencing constraints the roadmap must respect.

### BeatStepApp.swift

Add `.preferredColorScheme(.dark)` to `WindowGroup` body. This is the only change needed for dark-mode enforcement. Also add `UIUserInterfaceStyle = Dark` to Info.plist as belt-and-suspenders (prevents system override on older iOS).

### ContentView.swift

Currently: `ZStack(alignment: .bottom) { NavigationStack { PlaylistListView } / MiniPlayerView }`. After tab navigation: `ZStack(alignment: .bottom) { TabView { LibraryTab / RunTab / SettingsTab } / MiniPlayerView }`. The ZStack pattern is reusable — only the inner structure changes.

### PlaylistListView.swift and PlaylistDetailView.swift

Both show `"\(playlist.trackCount) tracks"`. Track count fix is localized here and in `SpotifyPlaylist.swift`. No structural changes needed for tab navigation — PlaylistListView becomes the Library tab content unchanged.

### RunView.swift

Currently only reachable from PlaylistDetailView via NavigationLink. Becomes a Run tab. Needs a "no playlist context" state design. The view itself does not change — only the navigation path to reach it.

### SettingsView.swift

Currently pushed via toolbar NavigationLink. Becomes a first-class tab. No content changes required for v1.1.

---

## Competitor Feature Analysis

| Feature | Strava | Nike Run Club | Apple Fitness+ | BeatStep v1.1 Approach |
|---------|--------|---------------|----------------|------------------------|
| Dark mode | Dark-optional | Dark-first | System-adaptive | Dark-only (intentional commitment) |
| Accent color | Orange | Yellow-green | Activity rings (R/G/B) | Electric green (single accent) |
| Tab structure | Feed / Map / You | Activity / Run / Me | Activity / Watch / Share | Library / Run / Settings |
| Typeface | Custom (Roobert) | Custom (Nike TG) | SF Pro | SF Pro + SF Pro Rounded for numerics |
| App icon | Orange S on white | Nike swoosh white on black | Colored rings | Dark bg + electric green mark |
| Track count | N/A | N/A | N/A | Fix: show — for zero instead of "0 tracks" |

---

## Sources

- [Apple Developer: Enhancing your app's content with tab navigation](https://developer.apple.com/documentation/SwiftUI/Enhancing-your-app-content-with-tab-navigation)
- [Apple Developer: preferredColorScheme(_:)](https://developer.apple.com/documentation/swiftui/view/preferredcolorscheme(_:))
- [SwiftUI Design System Considerations: Semantic Colors (2025)](https://www.magnuskahr.dk/posts/2025/06/swiftui-design-system-considerations-semantic-colors/)
- [Best Practices for Organizing Colors in iOS Projects (2026)](https://medium.com/@garejakirit/best-practices-for-organizing-colors-in-ios-projects-swiftui-uikit-guide-for-scalable-design-ea747d62c8b6)
- [Apple Design Resources](https://developer.apple.com/design/resources/)
- [App Icon Design Best Practices 2025](https://www.appiconly.com/blogs/ios-app-icon-design-best-practices)
- [App Icon Design Trends 2025](https://iconmaker.studio/blog/app-icon-design-trends-2025)
- [Modern SwiftUI Navigation Best Practices 2025](https://medium.com/@dinaga119/mastering-navigation-in-swiftui-the-2025-guide-to-clean-scalable-routing-bbcb6dbce929)
- [Dark Mode Best Practices — CreateWithPlay](https://createwithplay.com/blog/dark-mode)
- [Tab Bar iOS 26 SwiftUI — SwiftUISnippets](https://swiftuisnippets.wordpress.com/2025/07/15/tab-bar-bottom-accessory-placement-swiftui-for-ios-26/)
- Codebase analysis: `ContentView.swift`, `BeatStepApp.swift`, `SpotifyPlaylist.swift`, `PlaylistListView.swift`, `PlaylistDetailView.swift`

---
*Feature research for: BeatStep v1.1 Dark by Design — dark-mode UI, design system, tab navigation, branding*
*Researched: 2026-03-23*
