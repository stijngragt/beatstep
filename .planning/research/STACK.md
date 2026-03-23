# Stack Research

**Domain:** Native iOS running music-sync app (accelerometer cadence to Spotify BPM matching)
**Researched:** 2026-03-23
**Confidence:** HIGH (all v1.1 additions use first-party Apple APIs; no third-party libraries required)

---

## v1.0 Foundation (Validated — Do Not Re-Research)

All of the following are working in production. No changes needed:

| Technology | Status |
|------------|--------|
| Swift 6 / SwiftUI + @Observable | Working |
| CoreMotion (CMPedometer) | Working |
| Spotify Web API (PKCE) | Working |
| GetSongBPM API via Cloudflare Worker | Working |
| SwiftData (BPM cache) | Working |
| SpotifyiOS SDK v5 | Working |

---

## v1.1 Stack Additions: Dark by Design

All v1.1 capabilities use **zero new external dependencies**. Every item below is a first-party Apple pattern or asset convention.

### Core Technologies (v1.1)

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| SwiftUI `Color` extension (static tokens) | iOS 17+ | Semantic color tokens | Extend `Color` with `static var` properties to create a single source of truth for palette. Callers use `Color.accent` not hardcoded hex. Survives refactor, easy to audit. |
| SwiftUI `Font` extension (static tokens) | iOS 17+ | Typography scale tokens | Mirror pattern: `Font.beatstepTitle`, `Font.beatstepLabel`. Centralizes typeface + weight + size decisions. |
| SwiftUI `ViewModifier` (component tokens) | iOS 17+ | Reusable styling contracts | Encapsulate multi-property styles (font + color + spacing) into named modifiers: `.beatstepCardStyle()`, `.beatstepHeadlineStyle()`. Prevents style drift across 5,000+ LOC. |
| `UIUserInterfaceStyle = Dark` in Info.plist | iOS 13+ | Force dark-only appearance | Single key in Info.plist strips the system-level light/dark toggle for this app. No runtime logic needed. The entire UIKit + SwiftUI render pipeline honors it. |
| SwiftUI `TabView` | iOS 17+ | Bottom tab navigation | Native Apple component. Handles safe area, tab badges, accessibility labels. Use `.tabViewStyle(.automatic)` (default) for standard iOS bottom bar. No custom tab bar needed. |
| Asset Catalog (AppIcon.appiconset) | Xcode 14+ | App icon | Since Xcode 14, a single 1024×1024 PNG in the asset catalog is sufficient. System auto-scales to all required sizes. No icon generator tools needed. |

### Supporting Libraries (v1.1)

None. All v1.1 work is first-party SwiftUI patterns.

If the electric green exact hex color needs to be available across multiple contexts (SwiftUI + UIKit), define it in the asset catalog as a named color resource instead of only in a `Color` extension. Xcode 15+ auto-generates `Color(.beatstepAccent)` access from asset catalog entries.

### Development Tools (v1.1)

| Tool | Purpose | Notes |
|------|---------|-------|
| SF Symbols 6 | Icon system for tab bar glyphs | Use `Image(systemName:)`. Provides "music.library", "figure.run", "gearshape" or equivalents. No icon font licensing needed. |
| Figma / Sketch (optional) | Wordmark + app icon design | Design the wordmark externally, export as SVG or 1024×1024 PNG, import to asset catalog. Xcode is not a design tool. |

---

## Design System Architecture (Recommended Pattern)

### Token Hierarchy

```
DesignTokens (namespace enum — not instantiable)
├── Color tokens     → extension Color { static var ... }
├── Font tokens      → extension Font { static var ... }
├── Spacing tokens   → enum Spacing { static let xs: CGFloat = 4; ... }
└── Radius tokens    → enum Radius { static let card: CGFloat = 12; ... }
```

Use an `enum` (not `struct` or `class`) for namespace groups because an enum with no cases cannot be accidentally instantiated.

### Color Token Pattern

Define tokens in two layers: **primitive** (raw hex) and **semantic** (named by role):

```swift
// Layer 1: Primitives (private) — never use directly in views
private extension Color {
    static let _electricGreen = Color(hex: "#39FF14")
    static let _nearBlack     = Color(hex: "#0A0A0A")
    static let _surfaceGray   = Color(hex: "#1A1A1A")
    static let _textPrimary   = Color.white
    static let _textSecondary = Color.white.opacity(0.55)
}

// Layer 2: Semantic tokens (public) — use these in views
extension Color {
    static let accent          = _electricGreen     // Primary brand accent
    static let background      = _nearBlack          // App background
    static let surface         = _surfaceGray        // Card / elevated surfaces
    static let textPrimary     = _textPrimary        // Primary readable text
    static let textSecondary   = _textSecondary      // Labels, captions
    static let textOnAccent    = Color.black         // Text on green accent buttons
}
```

This pattern means every call in 5,000+ LOC that says `.foregroundStyle(.white.opacity(0.5))` becomes `.foregroundStyle(.textSecondary)` — and changing the opacity project-wide is a one-line edit.

### Font Token Pattern

```swift
extension Font {
    // Headline — large BPM readout, run mode display
    static let beatstepDisplay = Font.system(size: 48, weight: .bold, design: .monospaced)
    // Title — section headers
    static let beatstepTitle   = Font.system(size: 22, weight: .semibold)
    // Body — general readable text
    static let beatstepBody    = Font.system(.body)
    // Label — captions, metadata, secondary info
    static let beatstepLabel   = Font.system(.subheadline)
    // Caption — smallest; timestamps, tolerances
    static let beatstepCaption = Font.system(.caption)
}
```

Note: If a custom typeface (not SF Pro) is chosen, replace `Font.system(...)` with `Font.custom("TypefaceName", size: ..., relativeTo: .body)`. The `relativeTo:` parameter enables Dynamic Type scaling on custom fonts — do not omit it.

### ViewModifier Token Pattern

```swift
struct BeatstepCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color.surface)
            .cornerRadius(Radius.card)
            .padding(Spacing.md)
    }
}

extension View {
    func beatstepCard() -> some View { modifier(BeatstepCard()) }
}
```

### Spacing Tokens

```swift
enum Spacing {
    static let xs: CGFloat  = 4
    static let sm: CGFloat  = 8
    static let md: CGFloat  = 16
    static let lg: CGFloat  = 24
    static let xl: CGFloat  = 32
    static let xxl: CGFloat = 48
}
```

---

## Dark-Mode-Only Configuration

### Info.plist Key

Add to `/BeatStep/Resources/Info.plist`:

```xml
<key>UIUserInterfaceStyle</key>
<string>Dark</string>
```

This forces dark appearance app-wide regardless of system setting. No SwiftUI modifier needed. No runtime logic needed.

### What This Replaces

All existing code in the codebase currently uses `Color.black` backgrounds and `.white` foreground styles — this is already written for dark mode. Once `UIUserInterfaceStyle = Dark` is set, the `.colorScheme(.dark)` modifier on individual views (if any exist) can be removed as redundant.

Do NOT add `.preferredColorScheme(.dark)` on the root `WindowGroup` — the Info.plist key is the correct approach. The SwiftUI modifier only works below the view hierarchy and can be accidentally overridden; the Info.plist key applies to the entire process.

---

## TabView Integration

### Current Navigation (v1.0)

`ContentView` uses a single `NavigationStack` with `PlaylistListView` as root, settings in a toolbar nav link, and `MiniPlayerView` as a ZStack overlay. The mini-player is manually positioned with `.safeAreaInset`.

### Target Navigation (v1.1)

Replace with a `TabView` containing three tabs: Library, Run, Settings.

```swift
TabView {
    Tab("Library", systemImage: "music.note.list") {
        NavigationStack { PlaylistListView() }
    }
    Tab("Run", systemImage: "figure.run") {
        NavigationStack { RunView() }
    }
    Tab("Settings", systemImage: "gearshape") {
        NavigationStack { SettingsView() }
    }
}
```

The `Tab(_:systemImage:)` initializer is the iOS 18 API. For iOS 17 compatibility, use the `.tabItem { Label(...) }` modifier form instead.

### Mini-Player with TabView

The existing `MiniPlayerView` ZStack overlay pattern must survive the TabView refactor. Two options:

1. **Wrap TabView in a ZStack** — place MiniPlayerView above TabView. Use `.safeAreaInset(edge: .bottom)` on the TabView to push tab content above the mini-player height.
2. **TabView accessory** — iOS 26+ adds `tabViewBottomAccessory()` which places content directly above the tab bar. This is the cleanest approach but targets iOS 26 only. Since BeatStep targets iOS 17+, use option 1.

Option 1 is the right choice for v1.1. The existing ZStack pattern in `ContentView` already does this — it just needs the inner `NavigationStack` replaced with a `TabView`.

### Tab Bar Appearance

To style the tab bar (dark background, green selection tint), use `UITabBar.appearance()` in the app initializer:

```swift
init() {
    // ... existing SwiftData setup ...
    let tabBarAppearance = UITabBarAppearance()
    tabBarAppearance.configureWithOpaqueBackground()
    tabBarAppearance.backgroundColor = UIColor(Color.background)
    UITabBar.appearance().standardAppearance = tabBarAppearance
    UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
    UITabBar.appearance().tintColor = UIColor(Color.accent)
}
```

This is the correct way to customize tab bar background and selection color in SwiftUI. SwiftUI's `.tint()` modifier on `TabView` only controls the selected icon color (acceptable alternative), but for background color the UIAppearance API is required.

---

## App Icon Requirements

### Asset Catalog Setup

Xcode 14+ supports single-size app icons. Workflow:

1. Design a 1024×1024 PNG (no transparency, no rounded corners — system applies squircle mask)
2. Open `Assets.xcassets` → `AppIcon` → Attributes Inspector → Device: "Single Size"
3. Drag the PNG into the single 1024×1024 slot
4. Xcode auto-generates all required sizes at build time

### File Requirements

| Requirement | Spec |
|-------------|------|
| Format | PNG (not JPG, not SVG) |
| Size | 1024 × 1024 px |
| Color space | sRGB |
| Transparency | None (fully opaque) |
| Rounded corners | Do not add — system applies squircle mask |
| Dark mode variant | Optional (iOS 18+ allows dark/tinted variants via asset catalog) |

### Dark/Tinted Variants (Optional for v1.1)

iOS 18 added support for alternative app icon appearances (dark, tinted) in the asset catalog. Users can choose via Settings > Home Screen. Not required for v1.1 but worth noting the asset catalog slot is available if desired.

---

## Alternatives Considered

| Recommended | Alternative | When to Use Alternative |
|-------------|-------------|-------------------------|
| `UIUserInterfaceStyle = Dark` in Info.plist | `.preferredColorScheme(.dark)` on root view | Never — Info.plist is global and cannot be overridden by subsystems |
| `Color` extension static tokens | Asset catalog named colors | If colors need to be shared across SwiftUI + UIKit extensively. For a pure SwiftUI app, extension is simpler. |
| Native `TabView` | Custom tab bar view | If Apple's tab bar visual cannot be themed to match the design (unlikely — `UITabBarAppearance` is highly configurable) |
| Single 1024px icon in asset catalog | Multi-size icon set | Only use multi-size if you need different artwork at different sizes (very unusual) |
| SF Symbols for tab icons | Custom SVG tab icons | Custom icons only if SF Symbols cannot represent the concept. The three tabs (Library, Run, Settings) all have strong SF Symbol equivalents. |

## What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| Third-party design system libraries (DesignKit, etc.) | No library integrates with BeatStep's specific token needs. Adds dependency overhead with zero benefit. | SwiftUI native `Color`/`Font` extensions + `ViewModifier` |
| Hardcoded hex strings in view files | Already present in v1.0 (e.g. `.foregroundStyle(.white.opacity(0.5))`). Not wrong to ship, but creates drift. | Semantic `Color` token extensions |
| `UITabBarController` directly | Unnecessary UIKit reach-in. SwiftUI's `TabView` wraps it cleanly. | SwiftUI `TabView` |
| `tabViewStyle(.page)` | This creates a horizontally-pageable tab view (like onboarding flows), not a bottom nav bar. | Default `TabView` without style modifier |
| Icon generator tools (MakeAppIcon, etc.) | Xcode 14+ does this natively via single-size asset catalog. | Asset catalog single-size slot |
| `.colorScheme(.dark)` on individual views | Creates per-view overrides. Light-mode devices still show light chrome in unstyled areas. | Info.plist `UIUserInterfaceStyle = Dark` |

---

## Version Compatibility

| Feature | Min iOS | Notes |
|---------|---------|-------|
| `UIUserInterfaceStyle` in Info.plist | iOS 13 | Works on all supported devices |
| `TabView` with `Tab(_:systemImage:)` initializer | iOS 18 | Use `.tabItem { Label(...) }` form for iOS 17 |
| Asset catalog single-size icon | Xcode 14 | Project-level, not runtime |
| `UITabBarAppearance` | iOS 15 | Required for opaque background + custom color |
| Dark/tinted app icon variants | iOS 18 | Optional; ship without for v1.1 |
| `Color` extension static tokens | iOS 15+ | No iOS version dependency for the pattern itself |

---

## Sources

- [Apple Documentation: Choosing a specific interface style](https://developer.apple.com/documentation/uikit/choosing-a-specific-interface-style-for-your-ios-app) — `UIUserInterfaceStyle` Info.plist key (HIGH confidence)
- [Apple Documentation: Configuring your app icon](https://developer.apple.com/documentation/xcode/configuring-your-app-icon/) — asset catalog single-size requirements (HIGH confidence)
- [Apple Documentation: Enhancing your app's content with tab navigation](https://developer.apple.com/documentation/SwiftUI/Enhancing-your-app-content-with-tab-navigation) — `Tab(_:systemImage:)` API (HIGH confidence)
- [SwiftLee: App Icon Generator no longer needed with Xcode 14](https://www.avanderlee.com/xcode/replacing-app-icon-generators/) — single-size icon confirmed (MEDIUM confidence)
- [magnuskahr: SwiftUI Design System Considerations: Semantic Colors](https://www.magnuskahr.dk/posts/2025/06/swiftui-design-system-considerations-semantic-colors/) — semantic token patterns (MEDIUM confidence)
- [Design Systems Collective: Building a SwiftUI Design System Part 1: Color](https://www.designsystemscollective.com/building-a-swiftui-design-system-part-1-color-2ea75035e691) — primitive/semantic layer pattern (MEDIUM confidence)
- [Design Systems Collective: Building a SwiftUI Design System Part 2: Typography](https://www.designsystemscollective.com/building-a-swiftui-design-system-part-2-typography-4dd6b819b711) — font token patterns (MEDIUM confidence)
- [Donny Wals: Using iOS 18's new TabView with a sidebar](https://www.donnywals.com/using-ios-18s-new-tabview-with-a-sidebar/) — TabView iOS 18 API changes (MEDIUM confidence)

---
*Stack research for: BeatStep v1.1 Dark by Design — design system, dark mode, tab navigation, app icon*
*Researched: 2026-03-23*
