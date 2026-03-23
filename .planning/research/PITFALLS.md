# Pitfalls Research

**Domain:** Dark-mode design system, tab navigation, and brand assets — adding to existing SwiftUI iOS app
**Researched:** 2026-03-23
**Confidence:** HIGH

---

## Critical Pitfalls

### Pitfall 1: preferredColorScheme Does Not Control System-Presented UI

**What goes wrong:**
Setting `.preferredColorScheme(.dark)` on your root view forces dark appearance on SwiftUI views, but system-vended presentations ignore it. `confirmationDialog`, `DatePicker` (sheet presentation style), and UIKit-backed alerts (UIAlertController) continue rendering in whatever the device system setting dictates. On a user's phone set to light mode, these components flash white while the rest of the app is dark.

**Why it happens:**
`preferredColorScheme` operates at the SwiftUI rendering layer. When UIKit presents a new window (alerts, action sheets) or SwiftUI passes control to a system sheet host, the override does not propagate. Apple never documented this scope boundary clearly, so developers assume the modifier is global.

**How to avoid:**
Use `UIWindow.overrideUserInterfaceStyle = .dark` at the window level in addition to the SwiftUI modifier. Set this in `BeatStepApp.init()` or in the `WindowGroup` `onAppear` by reaching into `UIApplication.shared.connectedScenes`. The window-level override propagates through UIKit's view controller hierarchy including system alerts.

```swift
// In BeatStepApp body, after WindowGroup
.onAppear {
    UIApplication.shared
        .connectedScenes
        .compactMap { $0 as? UIWindowScene }
        .flatMap { $0.windows }
        .forEach { $0.overrideUserInterfaceStyle = .dark }
}
```

This must be combined with `UIUserInterfaceStyle = Dark` in Info.plist to prevent any flash of light mode at launch before SwiftUI renders.

**Warning signs:**
- Light-colored alert dialogs appearing in the app during testing on a light-mode device
- Safari web view (Spotify OAuth login) appearing in light mode

**Phase to address:**
Design System Foundation phase — set both the Info.plist key and window override before any other visual work begins. Treating this as a "cleanup later" item means every screenshot and review video will show broken system UI.

---

### Pitfall 2: MiniPlayer Overlay Breaks When TabView Introduces Its Own Tab Bar

**What goes wrong:**
The existing app uses `ZStack` + `safeAreaInset` to float `MiniPlayerView` above a `NavigationStack`. When `TabView` is introduced, the tab bar occupies the bottom safe area. The MiniPlayer's `safeAreaInset` reservation now stacks on top of the tab bar safe area, creating a double-height gap below the last list item. Alternatively, if the MiniPlayer is placed incorrectly in the hierarchy, it renders behind the tab bar and becomes invisible.

**Why it happens:**
`TabView` inserts its own safe area inset for the tab bar. A custom bottom overlay that was already accounting for the bottom safe area ends up doubled. The exact behavior depends on whether the MiniPlayer is inside or outside the `TabView`, and whether `.ignoresSafeArea` is applied.

**How to avoid:**
Restructure so `TabView` is the outermost navigation container. The MiniPlayer should live in a `ZStack` that wraps the `TabView`, not inside any individual tab. Use `.toolbar(.hidden, for: .tabBar)` on the inner `NavigationStack` if needed to gain manual control, then render both the custom tab bar and MiniPlayer from the outer `ZStack`. On iOS 18+, evaluate `.tabViewBottomAccessory()` which is designed exactly for a "Now Playing" mini-player row above the tab bar.

The content scroll inset reservation (`safeAreaInset`) must account for both the tab bar height and the MiniPlayer height combined, not each individually.

**Warning signs:**
- Empty white space at the bottom of list content after adding TabView
- MiniPlayer invisible or clipped on devices with home indicator

**Phase to address:**
Tab Navigation phase — the MiniPlayer integration must be designed as part of the TabView structure, not retrofitted afterward.

---

### Pitfall 3: NavigationStack Inside TabView — State Lost on Tab Switch

**What goes wrong:**
Each tab needs its own `NavigationStack`. When the user navigates from Library into a PlaylistDetailView, then switches to Run, then switches back to Library — the navigation stack resets to the root (PlaylistListView). The user loses their place.

**Why it happens:**
SwiftUI's `TabView` recreates tab content when switching tabs unless the state is preserved explicitly. View structs are value types that get discarded on tab switch. This is a known SwiftUI limitation.

**How to avoid:**
Bind each tab's `NavigationStack` to a `@State` (or `@SceneStorage` for persistence across launches) path variable. The path binding keeps SwiftUI from discarding the navigation state:

```swift
@State private var libraryPath = NavigationPath()

TabView {
    NavigationStack(path: $libraryPath) {
        PlaylistListView()
    }
    .tabItem { Label("Library", systemImage: "music.note.list") }
}
```

Keep the `NavigationStack` inside `TabView` (not outside). Placing `TabView` inside a parent `NavigationStack` causes the entire TabView — all tabs — to share one navigation hierarchy, which is wrong.

**Warning signs:**
- Navigating into a playlist, switching tabs, switching back: playlist detail is gone
- Back button disappears after tab switching

**Phase to address:**
Tab Navigation phase — navigation path state must be established when building the tab structure. This is not fixable without restructuring.

---

### Pitfall 4: Hardcoded Colors Missed in Migration — Incomplete Token Adoption

**What goes wrong:**
The codebase currently has hardcoded color references scattered across views: `.green` (BPM match indicator, start button), `.orange` (BPM display, guided mode warning), `.white.opacity(0.5)` (secondary text in RunView), `Color.gray.opacity(0.3)` (placeholder backgrounds), `Color.red.opacity(0.08)` (error state background), and the local `spotifyGreen` constant in LoginView. When a design token layer is added, developers migrate the visible screens and miss edge cases — especially states only visible during a run (low cadence, BPM mismatch indicator, end-of-ramp state).

**Why it happens:**
Color migration is tedious and grep-based searches miss colors defined as computed properties, colors inside closures, or colors constructed with opacity modifiers rather than named colors. RunView has the highest density of hardcoded colors (11 white-based references) because it was built dark-first, so it "works" without migration and gets deprioritized.

**How to avoid:**
1. Define all tokens in a single `AppColors` enum before touching any views.
2. Use a SwiftLint custom rule to flag `Color.white`, `Color.black`, `Color.green`, `Color.orange`, `Color.red`, `Color.gray` usages outside `AppColors.swift` after migration.
3. Migrate one file at a time. For BeatStep: LoginView (has `spotifyGreen` local var), MiniPlayerView, PlaylistDetailView, PlaylistListView, RunView (largest surface), CadenceDisplayView, SettingsView.
4. After each migration, build and run — do not batch migrations.

The `spotifyGreen` local variable in LoginView is a specific debt item: the Spotify brand green (`#1DB954`) must remain distinct from BeatStep's electric green accent. Define both in `AppColors` with explicit names (`AppColors.spotifyBrand` vs `AppColors.accent`).

**Warning signs:**
- A color looks right in normal use but the wrong shade in high-contrast mode
- `spotifyGreen` still defined as a local constant after design system work
- A color that doesn't update when you change the token value

**Phase to address:**
Design System Foundation phase — establish all tokens before migrating. Do not migrate in the same commit as token definition; define first, then migrate file-by-file.

---

### Pitfall 5: Electric Green Fails Accessibility Contrast in Some States

**What goes wrong:**
WCAG AA requires 4.5:1 contrast ratio for normal text, 3:1 for large text and UI components. Electric green (e.g., `#39FF14` neon green) against a near-black background (`#0A0A0A`) looks high-contrast visually but can fail when the green is used at reduced opacity — such as `.green.opacity(0.5)` for "dim" states, placeholder text, or secondary indicators. The current codebase already uses `.foregroundStyle(.green)` for BPM match indicators and a green Capsule for the Start Run button — if these get swapped to a bright electric green without checking text-on-green contrast, the black text on the green button may fail.

**Why it happens:**
Designers pick a color that looks vivid and on-brand. The contrast failure isn't in the primary use case (bright accent text on dark background) — it's in secondary uses: muted versions for inactive states, black text on a green button fill, green against the `ultraThinMaterial` background which is not pure black.

**How to avoid:**
Before finalizing the electric green token value, verify three scenarios:
1. Electric green text on `#000000` (pure black) — this almost always passes
2. Black text on the electric green fill (the Start Run button) — electric greens that are too saturated or too light fail here
3. Electric green text on `ultraThinMaterial` dark background — material is not pure black; the effective background is approximately `#1C1C1E` in dark mode

Use the WebAIM contrast checker at exact hex values. Target a green around `#4ADE80` (Tailwind green-400) or `#39FF14` (neon) rather than Apple's system green `#30D158` which is designed for light mode contexts. Also define a `dimAccent` token (e.g., 40% opacity) and verify that passes 3:1 for non-text UI components.

**Warning signs:**
- Electric green chosen by looking at it on a monitor rather than measuring contrast ratio
- Same green token used for both interactive and decorative elements at different opacities

**Phase to address:**
Design System Foundation phase — measure contrast before committing token values. Changing the green later requires updating the asset catalog and all references.

---

### Pitfall 6: App Icon Requires Separate Dark and Tinted Variants for iOS 18+

**What goes wrong:**
On iOS 18+, users can set their device to use dark app icons. If BeatStep only provides the standard light icon, iOS applies an automatic dark conversion that looks desaturated and wrong — especially bad for an app whose brand is electric green on black (the auto-dark version may invert to a light background).

**Why it happens:**
Most icon design guides focus on the single 1024x1024 PNG. The dark and tinted variants are new (iOS 18) and require explicit design work: a true dark variant needs the icon to be designed for dark context, not just darkened automatically.

**How to avoid:**
Design three icon variants from the start:
- **Standard (light):** What most users see
- **Dark:** Designed explicitly for dark icon mode (typically dark background, lighter/glowing elements)
- **Tinted:** Grayscale source image that iOS tints to the user's chosen wallpaper color

In Xcode 16+, configure the AppIcon asset with `Appearances: Any, Dark, Tinted` in the asset catalog. For BeatStep's electric green / dark aesthetic, the dark variant may actually be the preferred design — consider making it the primary icon and ensuring the light variant still reads well.

Do not use Icon Composer's layered `.icon` format unless confirmed supported by the target iOS version. For iOS 17 and below support, provide flat PNGs in the asset catalog.

**Warning signs:**
- Only one entry in the AppIcon asset catalog
- Dark mode device shows an auto-converted icon that looks wrong
- Icon review screenshots not taken on a dark-mode device

**Phase to address:**
Brand Assets phase — design all three variants before submitting. App Store Connect requires the 1024x1024 be the standard variant.

---

### Pitfall 7: ultraThinMaterial in MiniPlayer Looks Wrong Without Dark Commitment

**What goes wrong:**
The existing MiniPlayer uses `.ultraThinMaterial` for its background, which creates a frosted glass effect. In dark mode this looks intentional and elegant — the blur over dark content is dark. But if the window-level dark mode override is not set correctly (Pitfall 1), the material will use light-mode blur when presented over the Spotify OAuth web view or any UIKit-backed content. The result is a white/grey glass pill floating above dark content — completely broken visually.

**Why it happens:**
Material appearance is determined by the environment's color scheme, not the view's modifier. If a parent UIKit window or view controller has a different interface style, the material resolves to the wrong variant.

**How to avoid:**
This is resolved by the same fix as Pitfall 1 (window-level `overrideUserInterfaceStyle`). Verify explicitly by testing the MiniPlayer overlay while the Spotify login web view is active — this is the most likely context where the material environment is wrong.

**Warning signs:**
- MiniPlayer background appears light/grey during Spotify auth flow
- Material looks correct in the app but wrong on certain screens

**Phase to address:**
Design System Foundation phase — dark mode commitment at the window level must precede any material/overlay styling.

---

### Pitfall 8: Custom Font Registration Silently Falls Back to System Font

**What goes wrong:**
If the design system specifies a custom typeface (e.g., a geometric sans-serif for the BeatStep wordmark or UI numerics), and the font file is added to the project but not listed in `Info.plist` under `UIAppFonts`, SwiftUI silently falls back to the system font with no runtime error. The app builds and runs; the font just looks like SF Pro everywhere. This is especially insidious for monospaced numeric fonts used in the cadence/BPM display — the fallback SF Pro Mono looks similar enough that the issue is not caught until a side-by-side comparison.

**Why it happens:**
Xcode does not validate that font filenames in `UIAppFonts` match the actual PostScript font name required in `.font(.custom("PostScriptName", size:))`. Developers add the file to the bundle but use the filename instead of the PostScript name, or forget the Info.plist entry entirely.

**How to avoid:**
Use a font verification helper in debug builds that logs all registered fonts at launch:
```swift
#if DEBUG
UIFont.familyNames.sorted().forEach { family in
    UIFont.fontNames(forFamilyName: family).forEach { print("FONT:", $0) }
}
#endif
```
This confirms the PostScript names available. If a custom font is not listed, it is not registered.

For the design system, define font constants using the verified PostScript name once, and reference the constant everywhere rather than string literals.

**Warning signs:**
- UI looks "almost right" but numerics feel wrong weight
- Font renders differently on device vs. simulator
- No font verification step in the design system setup

**Phase to address:**
Design System Foundation phase — validate font registration in the first design system commit before building any screen that uses the new typeface.

---

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Add `.preferredColorScheme(.dark)` without window override | Looks correct in most views | System alerts, sheets, Spotify OAuth flicker light | Never — fix window level at the same time |
| Migrate colors file-by-file over multiple milestones | Less risky per commit | Mixed token/hardcoded state makes theme changes inconsistent | Never — do all files in one milestone |
| Use `.green` as the electric green placeholder during design | Fast prototyping | System green is not BeatStep's brand green; builds muscle memory for wrong value | OK in design spike, must be replaced before any review |
| Skip dark icon variant for v1.1 | Saves design time | Auto-converted dark icon looks wrong on iOS 18 dark home screen | Acceptable for TestFlight; must be done before App Store submission |
| Define `spotifyGreen` locally in each view | Easy to read in context | Drift — values diverge across files | Never — one `AppColors.spotifyBrand` constant |

---

## Integration Gotchas

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| TabView + MiniPlayer | Place MiniPlayer inside a single tab | MiniPlayer must wrap TabView in outer ZStack, visible across all tabs |
| TabView + NavigationStack | Wrap TabView in a single NavigationStack | Each tab gets its own NavigationStack; TabView is the outer container |
| preferredColorScheme | Apply only to SwiftUI root view | Also set UIWindow.overrideUserInterfaceStyle for system UI coverage |
| Spotify OAuth WebView | Assume it inherits app dark mode | WKWebView and ASWebAuthenticationSession use system appearance; window override needed |
| accentColor / tintColor | Set in asset catalog only | TabView tab bar tint must also be set via UITabBar.appearance() init-time on iOS 15; iOS 16+ use toolbarBackground |

---

## Performance Traps

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| NavigationPath for all tabs stored as @State in root view | Tab switch causes root view re-render, all tabs rebuild | Keep each tab's path state scoped to the tab's view, not the root | Immediately on complex navigation hierarchies |
| Heavy view construction in TabView tab label closures | Tab bar renders slowly, stutter on tab switch | Tab label closures must be lightweight (Image + Text only) | Any non-trivial view in the label |
| Re-running full library scan on every ContentView appear | Extra API calls when returning to Library tab | Guard scan with a "last scanned" timestamp; scan once per session | Any tab-switching interaction |

---

## UX Pitfalls

| Pitfall | User Impact | Better Approach |
|---------|-------------|-----------------|
| Active run tab showing same content as Library tab | Confusing — is the run on the Library screen? | Run tab should show the run screen only when a run is active; a "Start Run" CTA when idle |
| Tab switching during an active run resets BPM display | Runner glances at phone, sees wrong cadence number | Tab switch should not interrupt RunEngineService; state lives in the service, not the view |
| Settings accessible from a gear icon AND a Settings tab | Duplicate navigation paths confuse mental model | Pick one: Settings tab in TabView OR gear icon in nav bar. Not both |
| Brand mark too small in icon at 60px (iPhone notification) | Icon unreadable at small sizes | Test wordmark/icon at 29x29, 40x40, 60x60 — wordmarks rarely survive below 60px |
| Electric green badge/indicator on dark background looks neon | Feels like a toy, not a premium running app | Use a slightly desaturated electric green for small indicators; reserve full saturation for primary CTAs |

---

## "Looks Done But Isn't" Checklist

- [ ] **Dark mode commitment:** Verify on a physical device set to light mode — no white flashes, no light-mode alerts, Spotify OAuth web view looks dark
- [ ] **Tab navigation:** Test navigate-deep → switch tabs → switch back — navigation state preserved on every tab
- [ ] **Design tokens:** grep for `Color.green`, `Color.orange`, `Color.white`, `Color.gray`, `Color.red`, `Color.black` across all Swift files — zero hits outside AppColors.swift
- [ ] **MiniPlayer visibility:** Confirm MiniPlayer is visible and properly inset on all three tabs, not just the tab it was originally on
- [ ] **Electric green contrast:** Run all three contrast checks (text on black, black on green, text on material) through a contrast checker with actual hex values
- [ ] **App icon dark variant:** Switch device to dark home screen icons (iOS 18+ Settings > Wallpaper > Customise > Dark) — icon looks intentional, not auto-converted grey
- [ ] **Custom fonts:** Run the font registration debug log on device — confirm PostScript names appear as expected
- [ ] **Active run across tabs:** Start a run, switch to Library tab, switch to Settings tab, switch back to Run tab — run is still active, BPM display correct

---

## Recovery Strategies

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| System alerts appear in light mode after ship | LOW | Add window overrideUserInterfaceStyle + Info.plist key; no view changes needed |
| MiniPlayer invisible behind tab bar | MEDIUM | Restructure ZStack hierarchy; MiniPlayer must be outside TabView; requires layout rethink |
| NavigationStack state lost on tab switch | MEDIUM | Add NavigationPath bindings to each tab's NavigationStack; state preservation falls into place |
| Incomplete color token migration | LOW-MEDIUM | grep + fix file-by-file; non-breaking changes |
| Electric green fails contrast | LOW | Change token value in AppColors.swift; update asset catalog; all references update automatically |
| Missing dark app icon variant | LOW | Design dark variant, add to asset catalog, submit update |
| Font not registering | LOW | Add PostScript name to UIAppFonts in Info.plist; rebuild |

---

## Pitfall-to-Phase Mapping

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| System UI ignores preferredColorScheme | Design System Foundation | Test alerts, confirmationDialog on light-mode device — must appear dark |
| MiniPlayer breaks with TabView | Tab Navigation | MiniPlayer visible and correctly inset on all three tabs |
| NavigationStack state lost on tab switch | Tab Navigation | Deep navigation preserved after round-trip tab switching |
| Incomplete color token migration | Design System Foundation | grep for raw Color references returns zero outside AppColors.swift |
| Electric green contrast failures | Design System Foundation | Contrast ratios documented for all three background scenarios before tokens locked |
| Missing dark/tinted icon variants | Brand Assets | Dark icon mode on iOS 18 device shows intentional design |
| ultraThinMaterial wrong mode | Design System Foundation | MiniPlayer tested during Spotify auth flow — material appears dark |
| Custom font silent fallback | Design System Foundation | Font debug log confirms PostScript name registration on device |

---

## Sources

- [Apple Developer Forums: preferredColorScheme not affecting DatePicker and confirmationDialog](https://www.hackingwithswift.com/forums/swiftui/preferredcolorscheme-not-affecting-datepicker-and-confirmationdialog/11796)
- [Apple Developer Forums: Sheet dark theme issues](https://developer.apple.com/forums/thread/740489)
- [Apple Documentation: Choosing a specific interface style](https://developer.apple.com/documentation/uikit/choosing-a-specific-interface-style-for-your-ios-app)
- [SwiftUI TabView state — Apple Developer Forums](https://developer.apple.com/forums/thread/124749)
- [NavigationStack in iOS 18 TabView double-push bug — Apple Developer Forums](https://developer.apple.com/forums/thread/759542)
- [The Ideal TabView Behaviour With SwiftUI NavigationStack](https://betterprogramming.pub/swiftui-navigation-stack-and-ideal-tab-view-behaviour-e514cc41a029)
- [Reading and Setting Color Scheme in SwiftUI — nilcoalescing.com](https://nilcoalescing.com/blog/ReadingAndSettingColorSchemeInSwiftUI/)
- [Overriding Dark Mode — Use Your Loaf](https://useyourloaf.com/blog/overriding-dark-mode/)
- [Preparing App Icons for iOS 18 Dark and Tinted Modes — Koombea](https://www.koombea.com/blog/preparing-your-app-icon-for-ios-18-dark-and-tinted-modes/)
- [Apple Developer Documentation: Configuring your app icon using an asset catalog](https://developer.apple.com/documentation/xcode/configuring-your-app-icon/)
- [tabViewBottomAccessory — Apple Developer Documentation](https://developer.apple.com/documentation/SwiftUI/TabViewBottomAccessoryPlacement)
- [Mastering Safe Area in SwiftUI — fatbobman.com](https://fatbobman.com/en/posts/safearea/)
- [What can go wrong when using custom fonts in SwiftUI](https://blog.eidinger.info/what-can-go-wrong-when-using-custom-fonts-in-swiftui)
- [WCAG Contrast Requirements — WebAIM](https://webaim.org/articles/contrast/)
- [SwiftUI Design System: Semantic Colors — magnuskahr.dk](https://www.magnuskahr.dk/posts/2025/06/swiftui-design-system-considerations-semantic-colors/)
- [Master SwiftUI Design Systems: From Scattered Colors to Unified UI Components — DEV Community](https://dev.to/swift_pal/master-swiftui-design-systems-from-scattered-colors-to-unified-ui-components-4i9c)

---
*Pitfalls research for: Dark-mode design system, tab navigation, and brand assets (BeatStep v1.1)*
*Researched: 2026-03-23*
