# Phase 6: Design System Foundation - Research

**Researched:** 2026-03-23
**Domain:** SwiftUI design tokens, dark mode enforcement, iOS color/typography/spacing systems
**Confidence:** HIGH

## Summary

Phase 6 establishes BeatStep's visual identity infrastructure: force dark mode globally, define all color/typography/spacing tokens in Swift, and get user approval before any view migration. This is a foundational phase -- no existing views are migrated to tokens here (that is Phase 8). The scope is creating the token file, enforcing dark mode at the system level, and removing the single existing `preferredColorScheme(.dark)` call from RunView.

The user has locked the accent color as #FF4545 (vibrant warm red, heartbeat association), overriding the earlier "electric green" placeholder in REQUIREMENTS.md. All three background levels, text opacities, spacing scale, and state colors are at Claude's discretion within the near-black range. Tokens go in a single `DesignTokens.swift` file as Color/Font extensions with static properties -- no Asset Catalog color sets, no @Environment indirection.

Dark mode enforcement requires a three-layer approach: `UIUserInterfaceStyle = Dark` in Info.plist (prevents launch flash), `UIWindow.overrideUserInterfaceStyle = .dark` at window level (covers system alerts, sheets, Spotify OAuth), and removal of RunView's per-view `.preferredColorScheme(.dark)`. The Info.plist key does NOT currently exist -- it must be added.

**Primary recommendation:** Build the token file first (zero dependencies on anything else), enforce dark mode second (Info.plist + window override), then present tokens for user approval. Keep Phase 8 view migration completely out of scope.

<user_constraints>

## User Constraints (from CONTEXT.md)

### Locked Decisions
- Primary accent is #FF4545 (vibrant warm red / peach-red) -- heartbeat association, distances from Spotify's green
- Single accent color with opacity variants (no separate lighter/darker shades)
- Opacity levels used for subtle backgrounds (~15%), secondary emphasis (~60%), and full accent (100%)
- Spotify login button keeps Spotify brand green (#1DB954) as a named SpotifyBrand token -- do not use app accent for third-party auth
- Near-black base (not true #000000) -- softer, allows subtle surface differentiation
- 3 levels with subtle steps between them (small jumps, not dramatic contrast)
- Surfaces (cards, sheets) differentiated by background shade only -- no borders
- System elements (alerts, sheets, OAuth webview) use iOS system dark appearance, not custom overrides
- SF Pro for all text; SF Pro Rounded for numeric displays (BPM, cadence numbers)
- Body text at 16pt (slightly larger than iOS default for running-context readability)
- BPM display at hero size (48-56pt) in SF Pro Rounded -- dominant focal point on run screen
- Headings in Bold weight
- Captions smaller (13pt) AND lighter color -- hierarchy through both size and color
- Tokens defined as Swift Color and Font extensions with static properties (e.g., Color.accent, Font.heading)
- Semantic/role-based naming: Color.textPrimary, Color.surfaceBase, etc. -- describes purpose, not visual
- All tokens in a single DesignTokens.swift file
- Swift code only -- no Asset Catalog color sets
- Spacing tokens also in the same file (padding scale, corner radii, component sizing)
- Global dark mode via Info.plist + window-level override (DARK-01)
- Remove all conditional light/dark styling code (DARK-02) -- grep for preferredColorScheme should return zero hits outside AppEntry

### Claude's Discretion
- Exact hex values for the 3 background levels (within near-black range, subtle steps)
- Exact text color opacity levels for primary/secondary/tertiary
- Specific padding scale values and corner radii
- State colors (success/warning/error) -- derive from accent or choose complementary
- How to structure the DS-05 approval gate (how to present tokens for user review)

### Deferred Ideas (OUT OF SCOPE)
None -- discussion stayed within phase scope

</user_constraints>

<phase_requirements>

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| DARK-01 | App enforces dark mode globally (Info.plist + window-level override) | Three-layer dark enforcement pattern: Info.plist `UIUserInterfaceStyle = Dark` + `UIWindow.overrideUserInterfaceStyle = .dark` in BeatStepApp.init() + remove RunView's `.preferredColorScheme(.dark)`. Verified via pitfalls research that Info.plist alone is insufficient for system-presented UI. |
| DARK-02 | All light-mode-specific code paths and conditional styling are removed | Only one `preferredColorScheme` call exists (RunView line 37). Also remove `.toolbarColorScheme(.dark, for: .navigationBar)` from RunView line 39 (redundant once dark is enforced globally). No other light/dark conditional code found in codebase. |
| DS-01 | Color tokens defined: accent, 3 background levels, primary/secondary/tertiary text, state colors | DesignTokens.swift with Color extensions. Accent #FF4545 with opacity variants. Background levels in near-black range. SpotifyBrand #1DB954 as separate token. State colors complementary to accent. |
| DS-02 | Typography tokens defined: heading, body, caption, numeric display scales | Font extensions using SF Pro (.default design) for text, SF Pro Rounded (.rounded design) for numeric displays. Body 16pt, BPM hero 48-56pt, captions 13pt, headings Bold weight. |
| DS-03 | Spacing and component tokens defined: padding scale, corner radii, component sizing | Spacing enum with standard scale (4/8/12/16/24/32/48). Corner radii for cards/buttons. Component sizing constants for common elements. |
| DS-05 | Design system approved by user before view migration begins | Present token definitions (palette swatches, type scale, spacing values) for user review. Gate Phase 8 on approval. |

</phase_requirements>

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| SwiftUI `Color` extension (static vars) | iOS 17+ | Semantic color tokens | Zero-overhead, no environment propagation, no view rebuilds. Static extensions on Color are the standard pattern for fixed single-theme apps. |
| SwiftUI `Font` extension (static vars) | iOS 17+ | Typography scale tokens | Same pattern as color. `Font.system(size:weight:design:)` for SF Pro; `.rounded` design parameter for SF Pro Rounded. |
| `UIUserInterfaceStyle` Info.plist key | iOS 13+ | Global dark mode enforcement | Process-level override. Covers all UIKit and SwiftUI rendering including launch screen. |
| `UIWindow.overrideUserInterfaceStyle` | iOS 13+ | Window-level dark override | Covers system-presented UI (alerts, sheets, OAuth webview) that Info.plist alone does not propagate to reliably. |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| None | -- | -- | All v1.1 work is first-party SwiftUI/UIKit patterns |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Color extensions (static) | Asset Catalog named colors | Asset Catalog is better when sharing colors across SwiftUI + UIKit extensively. User decided Swift-only, no Asset Catalog color sets. |
| Color extensions (static) | @Environment custom theme | Adds boilerplate and re-render surface for zero benefit on a single fixed dark theme. Reserve for future multi-theme support. |
| Single DesignTokens.swift | Separate files per domain | User decided single file. Simpler for a small token set (~30-40 tokens total). |

## Architecture Patterns

### Recommended Project Structure
```
BeatStep/
├── DesignSystem/
│   └── DesignTokens.swift     # All color, font, spacing tokens in one file
├── App/
│   ├── BeatStepApp.swift      # Modified: add window-level dark override
│   └── ContentView.swift      # No changes in this phase
├── Resources/
│   └── Info.plist             # Modified: add UIUserInterfaceStyle = Dark
└── Views/
    └── Run/
        └── RunView.swift      # Modified: remove preferredColorScheme + toolbarColorScheme
```

### Pattern 1: Static Color Token Extensions
**What:** Color tokens as `static let` properties on `Color` extension
**When to use:** Always -- this is the only color access pattern for the app
**Example:**
```swift
// DesignTokens.swift

// MARK: - Color Tokens

extension Color {
    // Accent
    static let accent = Color(red: 1.0, green: 0.271, blue: 0.271)  // #FF4545
    static let accentSubtle = accent.opacity(0.15)    // Subtle backgrounds
    static let accentMedium = accent.opacity(0.60)    // Secondary emphasis

    // Brand (third-party)
    static let spotifyBrand = Color(red: 0.114, green: 0.725, blue: 0.329)  // #1DB954

    // Backgrounds (near-black, subtle steps)
    static let surfaceBase = Color(white: 0.067)       // ~#111111
    static let surfaceElevated = Color(white: 0.098)   // ~#191919
    static let surfaceOverlay = Color(white: 0.133)    // ~#222222

    // Text
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.55)
    static let textTertiary = Color.white.opacity(0.35)

    // State
    static let stateSuccess = Color(red: 0.298, green: 0.851, blue: 0.392)  // Green
    static let stateWarning = Color(red: 1.0, green: 0.757, blue: 0.027)    // Amber
    static let stateError = Color(red: 1.0, green: 0.376, blue: 0.376)      // Light red
}
```

### Pattern 2: Static Font Token Extensions
**What:** Font tokens as `static let` properties on `Font` extension
**When to use:** Always -- this is the only font access pattern
**Example:**
```swift
// MARK: - Font Tokens

extension Font {
    // Display — hero BPM/cadence numbers
    static let displayHero = Font.system(size: 52, weight: .bold, design: .rounded)
    // Display — secondary numeric (mini-player BPM, etc.)
    static let displaySecondary = Font.system(size: 18, weight: .bold, design: .rounded)

    // Headings
    static let heading = Font.system(size: 22, weight: .bold)
    static let subheading = Font.system(size: 18, weight: .semibold)

    // Body
    static let bodyText = Font.system(size: 16, weight: .regular)
    static let bodyBold = Font.system(size: 16, weight: .semibold)

    // Captions
    static let caption = Font.system(size: 13, weight: .regular)
    static let captionBold = Font.system(size: 13, weight: .medium)

    // Labels (smallest)
    static let label = Font.system(size: 11, weight: .medium)
}
```

### Pattern 3: Spacing/Radius Tokens as Enums
**What:** Non-instantiable enums for spacing and radius constants
**When to use:** All padding, margin, and corner radius values
**Example:**
```swift
// MARK: - Spacing Tokens

enum Spacing {
    static let xxs: CGFloat = 2
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
}

// MARK: - Radius Tokens

enum Radius {
    static let sm: CGFloat = 6
    static let md: CGFloat = 12
    static let lg: CGFloat = 20
    static let pill: CGFloat = 28  // Capsule buttons
}

// MARK: - Sizing Tokens

enum ComponentSize {
    static let miniPlayerHeight: CGFloat = 64
    static let buttonHeight: CGFloat = 52
    static let iconSmall: CGFloat = 24
    static let iconMedium: CGFloat = 44
    static let iconLarge: CGFloat = 60
}
```

### Pattern 4: Dark Mode Enforcement (Three-Layer)
**What:** Info.plist key + window-level override + removal of per-view overrides
**When to use:** Once, during this phase
**Example:**
```swift
// BeatStepApp.swift — add to init()
init() {
    // ... existing SwiftData setup ...

    // Force dark mode at window level (covers system alerts, sheets, OAuth)
    UIApplication.shared.connectedScenes
        .compactMap { $0 as? UIWindowScene }
        .flatMap { $0.windows }
        .forEach { $0.overrideUserInterfaceStyle = .dark }
}
```

Note: The window override in `init()` may execute before windows exist. An alternative is to apply it in a `.onAppear` or `SceneDelegate` callback. However, the Info.plist key `UIUserInterfaceStyle = Dark` covers the launch window, so any brief gap before the runtime override applies is invisible. The research recommends using both for defense in depth, with the Info.plist key as the primary mechanism.

A more robust approach for the window override:
```swift
// In BeatStepApp body, on the WindowGroup
WindowGroup {
    ContentView()
        .environment(authService)
        .onAppear {
            // Belt-and-suspenders: force dark on all windows
            for scene in UIApplication.shared.connectedScenes {
                guard let windowScene = scene as? UIWindowScene else { continue }
                for window in windowScene.windows {
                    window.overrideUserInterfaceStyle = .dark
                }
            }
        }
}
```

### Anti-Patterns to Avoid
- **Per-view preferredColorScheme:** Never add `.preferredColorScheme(.dark)` to individual views. One global enforcement point only.
- **Hardcoded hex strings in views:** After tokens exist, never use `Color(red:green:blue:)` or `.white.opacity(0.5)` directly in views. Always use token names. (Enforcement happens in Phase 8, but tokens must be designed to cover all existing usages.)
- **@Environment for static tokens:** No `@Environment(\.theme)` pattern. Static extensions are correct for a single fixed theme.
- **Asset Catalog color sets:** User decided against these. All colors defined in Swift code.
- **Naming by visual property:** Use `Color.textSecondary` not `Color.whiteHalf`. Semantic names describe purpose, not appearance.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Dark mode enforcement | Custom color scheme switching logic | Info.plist `UIUserInterfaceStyle` + window override | OS-level enforcement covers all system UI; custom logic always has gaps |
| SF Pro Rounded access | Custom font loading / bundle fonts | `Font.system(size:weight:design: .rounded)` | SF Pro Rounded is a system font, accessed via the `.rounded` design parameter. No font files needed. |
| Color from hex string | Custom `Color(hex:)` initializer | `Color(red:green:blue:)` with pre-computed values | Hex parsing adds unnecessary complexity for a small fixed palette. Pre-compute RGB values once. |
| Spacing scale | Ad-hoc padding values per view | `Spacing` enum with named constants | Consistent spacing across all views; change once, applies everywhere |

**Key insight:** Every token in this phase is a static constant. There is no dynamic theming, no user-selectable colors, no runtime switching. Static properties on extensions are the simplest correct solution.

## Common Pitfalls

### Pitfall 1: preferredColorScheme Does Not Cover System-Presented UI
**What goes wrong:** Setting `.preferredColorScheme(.dark)` on the root view forces dark on SwiftUI views, but system alerts, confirmation dialogs, date pickers, and the Spotify OAuth Safari web view render in the device's system setting (light mode). White UI flashes appear.
**Why it happens:** `preferredColorScheme` operates at the SwiftUI rendering layer. UIKit-presented windows (alerts, action sheets) and Safari web views do not inherit it.
**How to avoid:** Use `UIUserInterfaceStyle = Dark` in Info.plist AND `UIWindow.overrideUserInterfaceStyle = .dark` at window level. Both are required.
**Warning signs:** Light-colored alert dialogs or Spotify login screen appearing white on a test device set to light mode.

### Pitfall 2: Info.plist Key Not Applied at Build Time
**What goes wrong:** Adding `UIUserInterfaceStyle` to Info.plist but the app still shows light UI elements.
**Why it happens:** Xcode caches build artifacts. The Info.plist change may not propagate until a clean build.
**How to avoid:** After adding the key, do a clean build (Cmd+Shift+K, then Cmd+B). Test on a physical device set to light mode system-wide.
**Warning signs:** Simulator shows dark but device shows light for system elements.

### Pitfall 3: Color.accent Conflicts with SwiftUI's Built-in AccentColor
**What goes wrong:** SwiftUI has a built-in concept of `AccentColor` (set in asset catalog) and the `.tint()` modifier. Naming a static property `Color.accent` might shadow or conflict with system behavior.
**Why it happens:** SwiftUI resolves `Color.accentColor` from the asset catalog's `AccentColor` set. A custom `Color.accent` static property on Color extension is a different thing, but the name similarity can confuse.
**How to avoid:** Use `Color.accent` as the custom token name (it does not conflict -- `Color.accentColor` is the system one). But also set the asset catalog's AccentColor to #FF4545 so system tint (buttons, links, toggle) automatically uses the app accent without explicit `.tint()` everywhere.
**Warning signs:** System buttons (e.g., navigation back button, toggle tint) appearing in default blue instead of accent red.

### Pitfall 4: Font.caption Conflicts with SwiftUI's Built-in
**What goes wrong:** Defining `Font.caption` shadows SwiftUI's built-in `Font.caption` (which is a Dynamic Type text style).
**Why it happens:** Swift extension methods/properties can shadow existing ones. `Font.caption` already exists as a built-in.
**How to avoid:** Use a namespaced name like `Font.dsCaption` or `Font.captionText`, or use a different naming convention that avoids shadowing built-in Font properties. Same applies to `Font.body` -- use `Font.bodyText` or `Font.dsBody`.
**Warning signs:** Autocomplete showing two `caption` options; unexpected font sizes if the wrong one is resolved.

### Pitfall 5: Window Override Timing
**What goes wrong:** Applying `UIWindow.overrideUserInterfaceStyle` in `BeatStepApp.init()` executes before any windows exist, so the override has no effect.
**Why it happens:** At `init()` time, `UIApplication.shared.connectedScenes` is empty.
**How to avoid:** Apply the override in `.onAppear` on the root view, or use a `SceneDelegate`-based approach. The Info.plist key covers the launch gap.
**Warning signs:** First alert after launch appears in light mode, subsequent ones appear dark (because by then the view has appeared and the override was applied).

## Code Examples

### Complete DesignTokens.swift Structure
```swift
// BeatStep/DesignSystem/DesignTokens.swift

import SwiftUI

// MARK: - Color Tokens

extension Color {
    // Accent — #FF4545 (heartbeat red)
    static let accent = Color(red: 1.0, green: 0.271, blue: 0.271)
    static let accentSubtle = accent.opacity(0.15)
    static let accentMedium = accent.opacity(0.60)

    // Third-party brand
    static let spotifyBrand = Color(red: 0.114, green: 0.725, blue: 0.329)  // #1DB954

    // Backgrounds (near-black, subtle steps)
    static let surfaceBase = Color(white: 0.067)       // #111111
    static let surfaceElevated = Color(white: 0.098)   // #191919
    static let surfaceOverlay = Color(white: 0.133)    // #222222

    // Text
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.55)
    static let textTertiary = Color.white.opacity(0.35)

    // State
    static let stateSuccess = Color(red: 0.298, green: 0.851, blue: 0.392)
    static let stateWarning = Color(red: 1.0, green: 0.757, blue: 0.027)
    static let stateError = Color(red: 1.0, green: 0.376, blue: 0.376)

    // Text on colored backgrounds
    static let textOnAccent = Color.white
}

// MARK: - Font Tokens

extension Font {
    // Display — hero BPM/cadence numbers (SF Pro Rounded)
    static let displayHero = Font.system(size: 52, weight: .bold, design: .rounded)
    static let displaySecondary = Font.system(size: 18, weight: .bold, design: .rounded)

    // Headings (SF Pro Bold)
    static let heading = Font.system(size: 22, weight: .bold)
    static let subheading = Font.system(size: 18, weight: .semibold)

    // Body (SF Pro, 16pt base)
    static let bodyText = Font.system(size: 16, weight: .regular)
    static let bodyBold = Font.system(size: 16, weight: .semibold)

    // Captions (SF Pro, 13pt)
    static let captionText = Font.system(size: 13, weight: .regular)
    static let captionBold = Font.system(size: 13, weight: .medium)

    // Labels (smallest)
    static let labelText = Font.system(size: 11, weight: .medium)
}

// MARK: - Spacing Tokens

enum Spacing {
    static let xxs: CGFloat = 2
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
}

// MARK: - Radius Tokens

enum Radius {
    static let sm: CGFloat = 6
    static let md: CGFloat = 12
    static let lg: CGFloat = 20
    static let pill: CGFloat = 28
}

// MARK: - Component Sizing Tokens

enum ComponentSize {
    static let miniPlayerHeight: CGFloat = 64
    static let buttonHeight: CGFloat = 52
    static let coverArtSmall: CGFloat = 44
    static let coverArtLarge: CGFloat = 200
    static let iconSmall: CGFloat = 24
    static let iconMedium: CGFloat = 44
    static let iconLarge: CGFloat = 60
}
```

### Info.plist Dark Mode Key
```xml
<!-- Add inside the top-level <dict> in Info.plist -->
<key>UIUserInterfaceStyle</key>
<string>Dark</string>
```

### Window-Level Dark Override
```swift
// In BeatStepApp.swift, add .onAppear to WindowGroup content
WindowGroup {
    ContentView()
        .environment(authService)
        .onAppear {
            for scene in UIApplication.shared.connectedScenes {
                guard let windowScene = scene as? UIWindowScene else { continue }
                for window in windowScene.windows {
                    window.overrideUserInterfaceStyle = .dark
                }
            }
        }
}
```

### RunView Cleanup (DARK-02)
```swift
// RunView.swift — REMOVE these two lines:
// .preferredColorScheme(.dark)         // line 37
// .toolbarColorScheme(.dark, for: .navigationBar)  // line 39
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `.preferredColorScheme(.dark)` per view | Info.plist `UIUserInterfaceStyle` + window override | iOS 13+ (always available) | Single source of truth for dark enforcement; no view-level maintenance |
| Asset Catalog color sets for dark/light variants | Static Color extensions (dark-only app) | N/A -- design choice for single-theme apps | Simpler; no asset catalog management for colors |
| `Font.custom("SFProRounded", ...)` | `Font.system(size:weight:design: .rounded)` | iOS 16+ formalized `.rounded` design | No custom font files needed; system provides SF Pro Rounded |

## Open Questions

1. **AccentColor Asset Catalog Entry**
   - What we know: SwiftUI uses the asset catalog's `AccentColor` set for default button tint, toggle tint, and navigation link color
   - What's unclear: Whether we should set AccentColor in the asset catalog to #FF4545 alongside the Swift token, or rely on `.tint()` modifiers
   - Recommendation: Set AccentColor in asset catalog to #FF4545. This ensures system UI elements (back buttons, toggles) automatically use the app accent. This is NOT a "color set" for the design system -- it's a system configuration. The user's "no Asset Catalog color sets" decision refers to defining the design system palette in asset catalog, not this system configuration entry.

2. **Text on Accent Color**
   - What we know: Accent is #FF4545 (warm red). Text on accent buttons needs to be legible.
   - What's unclear: White text on #FF4545 has a contrast ratio of approximately 3.8:1 (below WCAG AA 4.5:1 for normal text, but above 3:1 for large text/UI components)
   - Recommendation: Use white text on accent for buttons (large text, meets 3:1). Note this for future accessibility review.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | XCTest (built-in, existing in project) |
| Config file | BeatStepTests target in Xcode project |
| Quick run command | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BeatStepTests 2>&1 \| tail -20` |
| Full suite command | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 \| tail -40` |

### Phase Requirements to Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| DARK-01 | Info.plist contains UIUserInterfaceStyle = Dark | unit | Verify plist content via build / grep | N/A (plist, not code test) |
| DARK-01 | Window override applied | manual-only | Test on light-mode device: alerts, sheets appear dark | N/A |
| DARK-02 | No preferredColorScheme outside AppEntry | unit | `grep -r "preferredColorScheme" BeatStep/ \| grep -v "AppEntry"` returns empty | N/A (grep check) |
| DS-01 | Color tokens compile and are accessible | unit | `xcodebuild build -scheme BeatStep` succeeds | Wave 0 |
| DS-02 | Font tokens compile and are accessible | unit | `xcodebuild build -scheme BeatStep` succeeds | Wave 0 |
| DS-03 | Spacing/radius tokens compile | unit | `xcodebuild build -scheme BeatStep` succeeds | Wave 0 |
| DS-05 | User approves token definitions | manual-only | Present token summary for user review | N/A |

### Sampling Rate
- **Per task commit:** `xcodebuild build -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | tail -5` (compile check)
- **Per wave merge:** Full test suite
- **Phase gate:** Build succeeds + grep for preferredColorScheme returns zero hits in BeatStep/ (excluding planning docs) + user approval of tokens

### Wave 0 Gaps
- [ ] `BeatStepTests/DesignTokenTests.swift` -- verify token values compile and are non-nil; verify accent matches expected hex; verify all three background levels are distinct and ordered dark-to-light
- [ ] Verification script: grep for `preferredColorScheme` in source files returns zero hits outside acceptable locations

## Sources

### Primary (HIGH confidence)
- Direct codebase reading: BeatStepApp.swift, ContentView.swift, RunView.swift, LoginView.swift, MiniPlayerView.swift, CadenceDisplayView.swift, PlaylistListView.swift, Info.plist -- all verified 2026-03-23
- .planning/research/STACK.md -- v1.1 stack research (color extensions, font extensions, Info.plist dark mode)
- .planning/research/ARCHITECTURE.md -- v1.1 architecture research (token hierarchy, component responsibilities)
- .planning/research/PITFALLS.md -- preferredColorScheme limitation, window override requirement

### Secondary (MEDIUM confidence)
- Apple Documentation: Choosing a specific interface style -- UIUserInterfaceStyle Info.plist key
- Apple Documentation: Font.system(size:weight:design:) -- .rounded design parameter for SF Pro Rounded
- SwiftUI community patterns for static Color/Font extensions in single-theme apps

### Tertiary (LOW confidence)
- Contrast ratio estimate for white text on #FF4545 -- needs validation with actual contrast checker tool

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- all first-party Apple APIs, verified in existing research
- Architecture: HIGH -- static extension pattern is well-established, codebase already uses similar patterns
- Pitfalls: HIGH -- preferredColorScheme limitation documented in multiple sources and Apple developer forums
- Token values: MEDIUM -- exact hex values for backgrounds/text opacities are at Claude's discretion, will be validated during DS-05 approval

**Research date:** 2026-03-23
**Valid until:** 2026-04-23 (stable -- all patterns are iOS 17+ established APIs)
