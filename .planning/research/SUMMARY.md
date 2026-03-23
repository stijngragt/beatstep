# Project Research Summary

**Project:** BeatStep v1.1 — Dark by Design
**Domain:** Native iOS SwiftUI — design system, dark-mode commitment, tab navigation, brand assets
**Researched:** 2026-03-23
**Confidence:** HIGH

## Executive Summary

BeatStep v1.1 is a focused visual and navigation milestone for a working iOS running app. The core product (cadence-to-BPM matching, Spotify playback, guided/free run modes) shipped in v1.0 and is unchanged. This milestone has one goal: make the app feel like a finished, opinionated product rather than a prototype. Research across all four areas confirms that every v1.1 objective is achievable using exclusively first-party Apple APIs — no new external dependencies are required.

The recommended approach is strictly sequential in its early steps, then parallelizable. Design tokens must be defined before any view work begins; they are the foundation everything else references. Dark-mode commitment at the window level (not just the SwiftUI layer) must happen in the same commit as token definition to avoid a class of bugs where system UI (alerts, sheets, Spotify OAuth) flickers light-mode. Tab navigation is the structural container — build it third so subsequent view updates only touch files once. Token adoption across existing views and the new RunHomeView component come after the shell is stable. App icon and wordmark are design artifacts that can proceed in parallel with the track count bug fix.

The primary risk is partial execution. Every pitfall identified in this milestone is a variant of "looks correct but isn't" — hardcoded colors that survive the migration grep, system alerts that flash white on a light-mode device, MiniPlayer that disappears behind the tab bar. The prevention strategy is completeness over speed: define all tokens before migrating, set window-level dark override at the same time as the SwiftUI modifier, and verify navigation state preservation by testing deep-navigate-then-switch-tab-then-switch-back on a physical device. These are not edge cases; they are the exact scenarios real users hit.

---

## Key Findings

### Recommended Stack

The v1.1 stack adds zero new dependencies. All required functionality is available through SwiftUI static extensions, `ViewModifier`, the asset catalog, and `UITabBarAppearance`. The design token layer — the most important new architectural element — is implemented as a `DesignSystem/` file group containing `Color+Theme.swift`, `Font+Theme.swift`, and `Spacing.swift`. Named color assets go in the asset catalog (`AccentGreen.colorset`, `AccentGreenDim.colorset`) so the electric green value is available to both SwiftUI and the app icon toolchain. Named asset catalog colors are the correct primitive for brand values; they work in Xcode Canvas, SwiftUI previews, and allow future Dynamic Color support without code changes.

Tab navigation uses native SwiftUI `TabView`. The `Tab(_:systemImage:)` initializer is iOS 18 only; use the `.tabItem { Label(...) }` form for iOS 17 compatibility (BeatStep targets iOS 17+). Tab bar styling requires `UITabBarAppearance` in the app initializer — `configureWithOpaqueBackground()` plus custom backgroundColor and tintColor. The SwiftUI `.tint()` modifier alone is insufficient for background color control.

**Core technologies:**
- `UIUserInterfaceStyle = Dark` in Info.plist — enforces dark globally before SwiftUI renders; prevents launch flash on light-mode devices
- `UIWindow.overrideUserInterfaceStyle = .dark` at window level — covers system alerts, sheets, and Spotify OAuth WebView that ignore SwiftUI's `preferredColorScheme`
- `Color`/`Font` static extensions + `ViewModifier` — design token layer; zero runtime overhead, no environment propagation needed for a static theme
- Asset catalog named colors (`AccentGreen.colorset`) — brand color primitives shared across SwiftUI and icon assets
- Native SwiftUI `TabView` with `UITabBarAppearance` — bottom nav; `.tabItem { Label }` form for iOS 17 compat
- `safeAreaInset(edge: .bottom)` on `TabView` — correct single-instance MiniPlayer placement across all tabs; replaces ZStack overlay pattern

### Expected Features

All five v1.1 features are P1. No deferral. Research confirms each is independently deliverable in this milestone.

**Must have (table stakes):**
- Consistent dark-mode UI — fitness app category standard (Strava, Nike Run, Apple Fitness are all dark-first); light-mode flash signals unfinished product
- Semantic color tokens — gates all other visual work; without tokens, hardcoded hex values diverge across views within a single sprint
- Bottom tab navigation (Library / Run / Settings) — iOS navigation convention since iOS 2; Settings currently buried in toolbar gear icon, Run tab not independently accessible
- Working track count display — "0 tracks" on playlist rows for Discover Weekly and Daily Mixes destroys data integrity trust; isolated fix in model + view layer

**Should have (competitive differentiators):**
- Electric green accent (#39FF14 range) — no major fitness app competitor owns neon green; high-energy, tech-forward visual identity
- Opinionated near-black base (not system gray #1C1C1E) — two elevated surface levels create depth that separates from stock SwiftUI
- SF Pro Rounded for numeric displays — `.fontDesign(.rounded)` on BPM/cadence/SPM numbers; built-in Apple variant, zero font licensing
- App icon + wordmark — dark background with electric green mark; required for App Store submission and home screen brand recall

**Defer (v2+):**
- Dynamic Type support — add after token system is stable so size tokens can scale
- Light mode — only if users explicitly request it at meaningful volume
- Alternate icon variants (light/tinted) — one excellent icon ships better than three mediocre ones; iOS 18 adaptive tinting can be added post-launch
- Haptic design system, animated SF Symbols tab icons, onboarding redesign

### Architecture Approach

The target architecture introduces two new components (`MainTabView`, `RunHomeView`) and one new file group (`DesignSystem/`). All six existing services (`RunEngineService`, `SpotifyPlayerService`, `BPMCacheService`, `SpotifyAuthService`, `LibraryScanService`, `AudioSessionService`) are unchanged. The structural change is that `ContentView` routes to `MainTabView` instead of an inline authenticated view, and `MainTabView` owns both the tab container and the single `MiniPlayerView` instance via `safeAreaInset`. The v1.0 pattern of `MiniPlayerView` embedded inside `RunView` is eliminated — single source, single instance.

**Major components:**
1. `DesignSystem/` group (`Color+Theme.swift`, `Font+Theme.swift`, `Spacing.swift`) — static token source of truth; all views reference tokens, never hardcoded values
2. `MainTabView` — TabView shell with three tabs, `MiniPlayerView` at `safeAreaInset(edge: .bottom)`, library scan task; replaces `authenticatedView` in `ContentView`
3. `RunHomeView` — Run tab landing; reads `RunEngineService.shared.isRunActive` to show idle CTA or active run state; new file, does not replace existing `RunView`
4. Modified existing views — `PlaylistListView`, `RunView`, `MiniPlayerView`, `SettingsView`, `LoginView`, `CadenceDisplayView` — all receive token adoption plus structural cleanup (remove gear toolbar, remove per-view MiniPlayer instances, remove per-view `preferredColorScheme`)
5. Asset catalog additions — `AppIcon.appiconset` (1024×1024 PNG), `AccentGreen.colorset`, `AccentGreenDim.colorset`, `Wordmark.imageset`

### Critical Pitfalls

1. **`preferredColorScheme` does not cover system-presented UI** — `confirmationDialog`, `DatePicker` sheets, and Spotify OAuth WebView render in the device system setting, not the SwiftUI modifier. Prevention: set `UIWindow.overrideUserInterfaceStyle = .dark` at the window level AND add `UIUserInterfaceStyle = Dark` to Info.plist. Both required; neither alone is sufficient.

2. **MiniPlayer placement breaks when TabView introduces its own tab bar insets** — placing MiniPlayer inside a single tab or leaving it in the old `ContentView` ZStack without restructuring creates double-height gap or invisible MiniPlayer. Prevention: single `MiniPlayerView` instance as `safeAreaInset(edge: .bottom)` on the `TabView` itself, not inside any individual tab.

3. **NavigationStack state lost on tab switch** — without explicit `NavigationPath` bindings, SwiftUI discards navigation state on tab switch. A user who navigates into a playlist, switches to Run, and switches back finds themselves at the Library root. Prevention: `@State private var libraryPath = NavigationPath()` bound to each navigable tab's `NavigationStack`.

4. **Incomplete color token migration** — RunView has 11+ hardcoded color references and gets deprioritized because it "looks correct" already in dark mode. Prevention: define all tokens first, then migrate all view files in a single atomic pass; verify with grep that `Color.green`, `Color.orange`, `Color.white`, `Color.gray` return zero hits outside the token file.

5. **Electric green accessibility contrast failures** — neon green against near-black passes for text, but black text on a green button fill and green text on `ultraThinMaterial` backgrounds can fail WCAG 4.5:1. Prevention: verify all three contrast scenarios (green text on black, black text on green fill, green text on material) with a contrast checker before locking the token value.

---

## Implications for Roadmap

Based on the feature dependency graph and architecture build order from ARCHITECTURE.md, four phases are recommended. Phases 1 and 2 are strictly sequential. Phases 3 and 4 can overlap or run in parallel.

### Phase 1: Design System Foundation
**Rationale:** Tokens gate everything. Every subsequent view edit references `Color.accent`, `Font.beatstepDisplay`, `Spacing.md` — if those don't exist first, hardcoded values go in and need a second removal pass. Dark-mode commitment at both layers (Info.plist + window override) must be established before any screenshots are taken or review videos recorded. This phase also resolves the entire cluster of "looks dark but system UI flickers light" and "contrast not measured" pitfalls.
**Delivers:** `DesignSystem/` file group with color, font, and spacing tokens; named color assets in asset catalog; Info.plist `UIUserInterfaceStyle = Dark`; window-level `overrideUserInterfaceStyle`; contrast ratios documented for all three electric green scenarios
**Addresses:** Consistent dark-mode UI (table stakes), semantic color tokens (table stakes), electric green differentiator (value locked before views use it)
**Avoids:** Pitfalls 1, 4, 5, 7, 8 — the entire "looks correct but isn't dark" and "missed migration" cluster

### Phase 2: Tab Navigation Shell
**Rationale:** Tab structure is the container; views go inside it. Building the shell before touching individual views ensures no file is modified twice. MiniPlayer placement must be solved as part of this phase — retrofitting it after tab structure is built is significantly harder.
**Delivers:** `MainTabView.swift`; restructured `ContentView` routing to `MainTabView`; MiniPlayer at `TabView.safeAreaInset(edge: .bottom)`; Settings as first-class tab; gear toolbar removed from `PlaylistListView`; library scan task migrated to `MainTabView`; `NavigationPath` state bindings for Library and Settings tabs
**Addresses:** Bottom tab navigation (table stakes)
**Avoids:** Pitfalls 2, 3 — MiniPlayer displacement and NavigationStack state loss

### Phase 3: Token Adoption + RunHomeView
**Rationale:** Token adoption across existing views is mechanical once tokens exist and the shell is stable. `RunHomeView` is a new component that requires both the shell (Phase 2) and tokens (Phase 1). These are logically grouped because both complete the "inside the shell" work.
**Delivers:** All existing views updated to design tokens (zero hardcoded color references outside token files); `RunHomeView.swift` with idle CTA and active run state reading `RunEngineService.shared.isRunActive`; `spotifyGreen` local variable in `LoginView` replaced with `AppColors.spotifyBrand` token
**Addresses:** Token adoption completeness (required for any future theme change), Run tab usability (Run is now independently accessible with clear idle state)
**Avoids:** Pitfall 4 (incomplete migration); completion verified by grep

### Phase 4: Track Count Fix + Brand Assets
**Rationale:** Both items are independent of all structural work. Track count fix is isolated to `SpotifyPlaylist.swift` model plus list view display. App icon and wordmark are design artifacts plus asset catalog entries — no code changes. Running these in parallel or after Phase 3 keeps milestone scope clean.
**Delivers:** "—" shown instead of "0 tracks" for algorithmic playlists (Discover Weekly, Daily Mixes, Radio); `AppIcon.appiconset` with 1024×1024 PNG; `Wordmark.imageset` in asset catalog
**Addresses:** Track count bug (table stakes), app icon + wordmark (differentiator and App Store requirement)
**Avoids:** Pitfall 6 — design dark and tinted icon variants before App Store submission (TestFlight can proceed with standard variant)

### Phase Ordering Rationale

- Design tokens before navigation structure: prevents double-touching view files (tokens defined once, views adopt them once in Phase 3)
- Navigation structure before view updates: prevents triple-touching files (shell built once, token adoption applied once)
- Track count fix isolated: no dependency on design work; batched with brand assets to minimize phase count
- App icon last: design artifact with zero code dependencies; naturally the final milestone polish item

### Research Flags

No phases require a `/gsd:research-phase` step. All required patterns are documented with sufficient implementation detail:

**Phases with standard patterns (research complete):**
- **Phase 1:** SwiftUI Color/Font extensions are well-documented Apple patterns; primitive/semantic token hierarchy is established community practice; window-level dark override is documented with code samples
- **Phase 2:** TabView + per-tab NavigationStack + safeAreaInset are first-party APIs with known pitfall mitigations already documented in PITFALLS.md
- **Phase 3:** Mechanical token migration; RunHomeView observes existing @Observable service with no new patterns
- **Phase 4:** Track count is a model/view bug with a clear isolated fix; app icon is a design + asset catalog task with documented requirements

---

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | All v1.1 additions are first-party Apple APIs verified against official documentation. Zero new dependencies. v1.0 foundation already validated in production. |
| Features | HIGH | Five features tightly scoped; dependency graph verified against actual codebase file analysis. Anti-features well-justified with competitor benchmarks. |
| Architecture | HIGH | Based on direct codebase reading of current implementation plus SwiftUI documented patterns. Build order derived from actual file dependencies, not theory. |
| Pitfalls | HIGH | Each pitfall sourced from Apple Developer Forums, official documentation, or community-verified edge cases. Recovery strategies included. |

**Overall confidence:** HIGH

### Gaps to Address

- **RunHomeView idle state visual design:** Research recommends "pick a playlist from Library to start a run" with optional last-used playlist shortcut. Exact layout is an implementation decision. Low risk — the interaction model is clear and the component is new with no migration concerns.

- **Electric green final hex value:** Research recommends `#39FF14` range but verification against three contrast scenarios (text on black, black text on green fill, green text on material) must happen during Phase 1 before any view references the token. This is a 10-minute measurement task, not a knowledge gap.

- **`spotifyGreen` local variable in LoginView:** Currently a local constant set to Spotify's brand green (`#1DB954`). Must become `AppColors.spotifyBrand` — a distinct named token separate from BeatStep's electric green accent — during the Phase 3 migration pass.

- **Dark and tinted app icon variants:** PITFALLS.md identifies that iOS 18 dark home screen auto-converts single-variant icons poorly. For v1.1, a single excellent standard icon is acceptable for TestFlight. Dark and tinted variants should be added before App Store submission to avoid the auto-converted grey result on dark home screens.

---

## Sources

### Primary (HIGH confidence)
- Apple Documentation: Choosing a specific interface style — `UIUserInterfaceStyle` Info.plist key
- Apple Documentation: Configuring your app icon — asset catalog single-size requirements
- Apple Documentation: Enhancing your app's content with tab navigation — `Tab(_:systemImage:)` API
- Apple Documentation: preferredColorScheme(_:) — SwiftUI modifier scope limitations
- Apple WWDC 2022 "The SwiftUI cookbook for navigation" — TabView + per-tab NavigationStack pattern
- Apple Documentation: safeAreaInset — persistent overlays, iOS 15+
- Direct codebase reading: `ContentView.swift`, `BeatStepApp.swift`, `RunView.swift`, `MiniPlayerView.swift`, `PlaylistListView.swift`, `SettingsView.swift` — verified 2026-03-23

### Secondary (MEDIUM confidence)
- magnuskahr.dk: SwiftUI Design System Considerations: Semantic Colors (2025) — primitive/semantic token layer pattern
- Design Systems Collective: Building a SwiftUI Design System Parts 1 & 2 — color and typography token patterns
- Donny Wals: Using iOS 18's new TabView with a sidebar — TabView iOS 18 API changes
- SwiftLee: App Icon Generator no longer needed with Xcode 14 — single-size icon confirmed
- nilcoalescing.com: Reading and Setting Color Scheme in SwiftUI — window-level override pattern
- Use Your Loaf: Overriding Dark Mode — `UIWindow.overrideUserInterfaceStyle` usage
- fatbobman.com: Mastering Safe Area in SwiftUI — `safeAreaInset` behavior with TabView
- Apple Developer Forums: preferredColorScheme not affecting system dialogs — scope boundary confirmed

### Tertiary (MEDIUM-LOW confidence)
- Koombea: Preparing App Icons for iOS 18 Dark and Tinted Modes — dark/tinted icon variant requirements
- WebAIM Contrast Checker — WCAG 4.5:1 contrast requirements for electric green verification approach

---
*Research completed: 2026-03-23*
*Ready for roadmap: yes*
