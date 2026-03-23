# Architecture Research

**Domain:** iOS SwiftUI — Dark-mode design system, tab navigation, brand assets (v1.1 addendum)
**Researched:** 2026-03-23
**Confidence:** HIGH (based on direct codebase reading + SwiftUI documented patterns)

---

## v1.1 Scope

This document covers only the v1.1 "Dark by Design" milestone additions. The original v1.0 architecture (cadence pipeline, BPM cache, Spotify adapters) is unchanged and documented in the v1.0 retrospective. The questions answered here are:

1. Where do design tokens live?
2. How does TabView replace the current navigation structure?
3. Where does MiniPlayerView live in the new structure?
4. What is the suggested build order given dependencies?

---

## Current Architecture Snapshot (v1.0)

```
BeatStepApp (@main)
  ModelContainer (SwiftData)
  SpotifyAuthService injected via .environment()

ContentView
  Auth gate: isAuthenticated? → authenticatedView : LoginView()

authenticatedView (ZStack)
  NavigationStack
    PlaylistListView
      PlaylistDetailView → RunView
    ToolbarItem: gear → SettingsView (NavigationLink)
  safeAreaInset(.bottom): Color.clear spacer hack
  MiniPlayerView overlay (ZStack .bottom)
```

Key observation: `MiniPlayerView` is also embedded directly inside `RunView` (separate instance). There are two instances in v1.0.

---

## Target Architecture (v1.1)

```
BeatStepApp (@main)
  ModelContainer (SwiftData)
  SpotifyAuthService injected via .environment()

ContentView
  .preferredColorScheme(.dark)        ← moved here from RunView
  Auth gate: isAuthenticated? → MainTabView : LoginView()

MainTabView (TabView)
  .tint(.accent)                      ← electric green tab selected state
  .safeAreaInset(edge: .bottom)
    MiniPlayerView()                  ← single instance, persists across tabs

  Tab 1: Library
    NavigationStack
      PlaylistListView
        PlaylistDetailView → RunView

  Tab 2: Run
    RunHomeView                       ← new landing screen for Run tab

  Tab 3: Settings
    NavigationStack
      SettingsView
```

---

## Design Token Architecture

### Decision: Color extensions + Font extensions (not Environment values)

**Recommendation:** Static `Color` and `Font` extensions in a `DesignSystem/` group. No `@Environment` for tokens.

**Rationale:**
- Static extensions are zero-overhead — no environment propagation, no view rebuilds on token reads
- `.preferredColorScheme(.dark)` applied once at `ContentView` makes all light/dark branching inside tokens unnecessary
- `@Environment` adds boilerplate and re-render surface area for a single, static theme
- ViewModifiers are appropriate for *composite component styles* (button, card) but not for primitive color/type tokens

**Token layers:**

```
Primitive tokens  →  Color("AccentGreen") in Asset Catalog
Semantic tokens   →  Color.accent, Color.textPrimary (Color+Theme.swift)
Component styles  →  PrimaryButtonStyle, CardStyle (ViewModifiers/)
```

**Pattern — Color+Theme.swift:**

```swift
extension Color {
    // Accent
    static let accent    = Color("AccentGreen")
    static let accentDim = Color("AccentGreenDim")

    // Surfaces
    static let surface         = Color(white: 0.08)
    static let surfaceElevated = Color(white: 0.12)

    // Text
    static let textPrimary   = Color.white
    static let textSecondary = Color(white: 1.0, opacity: 0.5)
    static let textTertiary  = Color(white: 1.0, opacity: 0.3)
}
```

**Why Asset Catalog for accent colors (not hardcoded hex):**
The electric green accent must appear in the app icon. Asset Catalog entries work in SwiftUI previews, Xcode canvas, and allow future Dynamic Color support without code changes. Named colors are the correct primitive for brand values.

**Why NOT @Environment for tokens:**
Every view declaring `@Environment(\.appTheme)` re-renders on any token change. Since BeatStep has a single, static dark theme, this is pure overhead. Reserve `@Environment` for genuinely dynamic values (`SpotifyAuthService`, `RunEngineService` state).

**Why NOT ViewModifier for primitive tokens:**
ViewModifiers are for *component styling* (button, card). Conflating modifier layers makes token extraction harder. Keep the two layers distinct: tokens are static values; modifiers apply composed styles that reference those tokens.

---

## TabView Integration

### New component: MainTabView

`BeatStep/App/MainTabView.swift` replaces `authenticatedView` inside `ContentView`.

`ContentView` becomes:

```swift
struct ContentView: View {
    @Environment(SpotifyAuthService.self) private var authService

    var body: some View {
        Group {
            if authService.isAuthenticated {
                MainTabView()
            } else {
                LoginView()
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            AudioSessionService.shared.setupAudioSession()
            SpotifyAuthService.shared.checkExistingAuth()
        }
    }
}
```

**Tab structure in MainTabView:**

```swift
TabView {
    NavigationStack {
        PlaylistListView()
    }
    .tabItem { Label("Library", systemImage: "music.note.list") }
    .tag(Tab.library)

    RunHomeView()
    .tabItem { Label("Run", systemImage: "figure.run") }
    .tag(Tab.run)

    NavigationStack {
        SettingsView()
    }
    .tabItem { Label("Settings", systemImage: "gearshape") }
    .tag(Tab.settings)
}
.tint(.accent)
.safeAreaInset(edge: .bottom) {
    MiniPlayerView()
}
.task {
    await LibraryScanService.shared.scanEnabledPlaylists()
}
```

Note: the `.task` for background library scan moves from `ContentView.authenticatedView` to `MainTabView` since that is the new authenticated root.

### MiniPlayerView placement

`safeAreaInset(edge: .bottom)` on the `TabView` itself. This renders MiniPlayer above the tab bar across all three tabs with a single instance, no per-tab duplication.

This replaces both the v1.0 `ZStack` overlay approach in `ContentView` and the embedded `MiniPlayerView()` instance inside `RunView`. Both are removed.

**How safeAreaInset works here:** `safeAreaInset` on a `TabView` inserts content into the safe area that all child views (including their scroll views and list views) automatically respect. The tab bar sits below. MiniPlayer floats above the tab bar. Scroll content stops above MiniPlayer without any manual `Color.clear.frame(height: 64)` spacer hack.

### NavigationStack per navigable tab

Each tab with navigation (Library, Settings) gets its own `NavigationStack`. A single shared `NavigationStack` wrapping the `TabView` causes navigation state to bleed across tabs — this is a documented SwiftUI pitfall. The Run tab (RunHomeView) does not need a NavigationStack unless RunView is pushed from within it.

### SettingsView toolbar removal

In v1.0, `SettingsView` is reached via a `ToolbarItem` gear icon in `PlaylistListView`. In v1.1:

- `PlaylistListView` toolbar loses the gear `ToolbarItem`
- `SettingsView` becomes the root of the Settings `NavigationStack` tab
- `SettingsView` gains `.navigationTitle("Settings")` (already present) as the visible tab title

---

## RunHomeView (new component)

In v1.0, `RunView` requires `playlist: SpotifyPlaylist` and `tracks: [SpotifyTrack]` injected at construction (navigated from `PlaylistDetailView`). The Run tab needs a landing state when no run is active.

**Recommended approach:** `RunHomeView` as the tab root.

```
RunHomeView
  If run is active (RunEngineService.shared.isRunActive):
    Show run state inline (cadence display, stop/cool-down controls)
  Else:
    Show "Pick a playlist from Library to start a run" prompt
    Optional: shortcut to last-used playlist
```

`RunHomeView` reads `RunEngineService.shared` observation state. When a run is active, it surfaces the active run UI without requiring the playlist parameter (the engine already holds that state). When idle, it provides a clear call-to-action pointing users to Library.

This is a new file: `BeatStep/Views/Run/RunHomeView.swift`. It does not replace `RunView` — `RunView` remains as the navigated destination from `PlaylistDetailView`.

---

## Asset Catalog Structure

```
BeatStep/Resources/Assets.xcassets/
├── AppIcon.appiconset/
│     Single 1024x1024 PNG, "All" platform selected
│     Xcode auto-generates all required sizes
├── AccentGreen.colorset/
│     Single swatch (Appearances: None)
│     Dark-only app means one value is correct
├── AccentGreenDim.colorset/
│     Dimmed variant for disabled / secondary accent usage
└── Wordmark.imageset/
      SVG or @3x PNG for splash / about screen
```

**Color asset configuration — single swatch (not dark/light pair):**
Set "Appearances" to "None" (no appearance variants). Because `.preferredColorScheme(.dark)` is enforced at `ContentView`, the OS always resolves colors in dark context. A single swatch is the correct, unambiguous representation of a dark-only color.

**App icon:** Xcode 15+ accepts a single 1024x1024 PNG in the `AppIcon` appiconset. Icon should use the electric green mark on black background to match app aesthetic.

---

## Component Responsibilities

| Component | New / Modified | Responsibility in v1.1 |
|-----------|---------------|------------------------|
| `BeatStepApp` | Modified | No code change needed — `.preferredColorScheme` moves to `ContentView` |
| `ContentView` | Modified | Add `.preferredColorScheme(.dark)`, route to `MainTabView` |
| `MainTabView` | **New** | TabView shell, MiniPlayer safeAreaInset, library scan task |
| `RunHomeView` | **New** | Run tab landing — idle prompt or active run state |
| `Color+Theme.swift` | **New** | All semantic color tokens |
| `Font+Theme.swift` | **New** | All semantic type tokens |
| `Spacing.swift` | **New** | Spacing constants (xs, sm, md, lg, xl) |
| `PrimaryButtonStyle` | **New** | Accent capsule button (replaces hardcoded .green capsule in RunView) |
| `Assets.xcassets` | Modified | Add AppIcon, AccentGreen, AccentGreenDim, Wordmark |
| `PlaylistListView` | Modified | Remove toolbar gear ToolbarItem, adopt design tokens |
| `RunView` | Modified | Remove embedded `MiniPlayerView()`, remove `.preferredColorScheme(.dark)`, adopt tokens (replace `.green`, `.orange`, `.white.opacity`) |
| `MiniPlayerView` | Modified | Remove from per-view usage — now lives only at `MainTabView.safeAreaInset` |
| `SettingsView` | Modified | Adopt design tokens, now NavigationStack root in Settings tab |
| `LoginView` | Modified | Adopt dark design tokens |
| `CadenceDisplayView` | Modified | Replace `.white` / `.green` / `.orange` with tokens |

---

## Suggested Build Order

Dependencies determine order. Each step must complete before the next begins.

### Step 1 — Design tokens (no UI dependencies)

Create `BeatStep/DesignSystem/` group. Add `Color+Theme.swift`, `Font+Theme.swift`, `Spacing.swift`. Add `AccentGreen.colorset` and `AccentGreenDim.colorset` to `Assets.xcassets`. No existing files are modified.

**Why first:** Every subsequent step references tokens. Building tokens first means views adopt them once — no retroactive swap needed.

### Step 2 — App-level dark-mode enforcement

Add `.preferredColorScheme(.dark)` to `ContentView`. Remove the existing `.preferredColorScheme(.dark)` from `RunView` (line 38). Verify `LoginView`, `PlaylistListView`, and `SettingsView` render correctly in dark context.

**Why second:** Establishes the baseline before any new UI. Surfaces any light-mode assumptions in existing views while the surface area is still manageable.

### Step 3 — TabView shell (MainTabView)

Create `MainTabView.swift`. Extract `authenticatedView` logic into it. Wire three tabs (Library, Run, Settings). Move `MiniPlayerView` from `ContentView` ZStack overlay to `TabView.safeAreaInset`. Remove MiniPlayerView from `RunView`. Move gear toolbar item out of `PlaylistListView`, SettingsView becomes its own tab root. Move the `.task` library scan to `MainTabView`.

**Why third:** Tab navigation is the structural container. All view updates in later steps happen inside this shell. Building the shell first prevents double-touching views.

### Step 4 — Token adoption in existing views

Update `PlaylistListView`, `PlaylistDetailView`, `RunView`, `CadenceDisplayView`, `MiniPlayerView`, `SettingsView`, `LoginView`. Replace hardcoded `Color.black`, `.green`, `.orange`, `.white`, `.white.opacity(n)` with semantic tokens.

**Why fourth:** Token adoption is mechanical once tokens exist. Doing this after shell work ensures no view is touched twice.

### Step 5 — RunHomeView

Create `RunHomeView.swift` as the Run tab landing. Observe `RunEngineService.shared` for active run state. Show idle prompt or active run summary.

**Why fifth:** Requires both the TabView shell (Step 3) and tokens (Step 4) to be in place. Logically independent from the track count bug fix.

### Step 6 — Track count bug fix

Investigate `playlist.trackCount` displaying zero in `PlaylistListView`. Likely a `SpotifyPlaylist` model parsing issue (tracks.total vs top-level total field). Isolated to model + API response.

**Why sixth:** Bug fix is independent of design work. Placing it after token adoption avoids conflating cosmetic and logic diffs.

### Step 7 — App icon and wordmark

Add final icon assets to `AppIcon.appiconset`. Add wordmark to `Wordmark.imageset`. Verify icon appears correctly in Simulator and on-device.

**Why last:** Icon production doesn't affect any code. It's the final design artifact and can be completed in parallel with Step 6 by a separate effort.

---

## Integration Points

### Existing services — no changes required

| Service | v1.1 Impact | Notes |
|---------|-------------|-------|
| `RunEngineService` | Read-only | `RunHomeView` observes `isRunActive`; no write changes |
| `SpotifyPlayerService` | Unchanged | `MiniPlayerView` still observes `currentTrack` |
| `BPMCacheService` | Unchanged | Token adoption doesn't touch data layer |
| `SpotifyAuthService` | Unchanged | `ContentView` auth gate unchanged |
| `LibraryScanService` | Unchanged | `.task` call moves to `MainTabView`, same call site behavior |

### Internal boundaries introduced by v1.1

| Boundary | Communication | Notes |
|----------|---------------|-------|
| `MainTabView` → `MiniPlayerView` | Direct: `safeAreaInset` | Single instance; views no longer manage MiniPlayer lifecycle |
| `DesignSystem/` → all views | Static: `Color.accent`, `Font.displayLarge` | No runtime dependency, no re-render surface |
| `RunHomeView` → `RunEngineService` | `@Observable` observation | Reads `isRunActive`, `rampPhase`; no writes |

---

## Anti-Patterns to Avoid

### Anti-Pattern 1: Per-view preferredColorScheme

**What people do:** Keep `.preferredColorScheme(.dark)` on `RunView` and add it to every new view.
**Why it's wrong:** Any view missing the modifier shows light-mode during OS theme transitions or in previews.
**Do this instead:** One `.preferredColorScheme(.dark)` at `ContentView`, remove all per-view instances. RunView's current modifier is the only one to remove.

### Anti-Pattern 2: Hardcoded color literals alongside tokens

**What people do:** Add design system but leave `Color.black`, `.green`, `.white.opacity(0.5)` in existing views.
**Why it's wrong:** Design system has no authority — accent color changes require grep-and-replace instead of a token edit.
**Do this instead:** Token adoption pass (Step 4) replaces all hardcoded colors atomically in one commit.

### Anti-Pattern 3: Shared NavigationStack wrapping TabView

**What people do:** Wrap the entire `TabView` in a single `NavigationStack`.
**Why it's wrong:** Navigation path bleeds across tabs; deep-link destinations can push on wrong tab.
**Do this instead:** One `NavigationStack` per navigable tab (Library, Settings), none for Run tab.

### Anti-Pattern 4: MiniPlayerView duplicated per-view

**What people do:** Keep `MiniPlayerView()` inside `RunView` and add it to new tab roots.
**Why it's wrong:** Multiple instances cause state divergence and layout conflicts with the tab bar.
**Do this instead:** Single instance at `TabView.safeAreaInset(edge: .bottom)`. Remove the existing instance from `RunView`.

### Anti-Pattern 5: @Environment for static design tokens

**What people do:** `@Environment(\.colorTokens) var tokens` to propagate theme through the view tree.
**Why it's wrong:** Every subscriber re-renders on any token change; adds boilerplate for zero benefit on a fixed dark theme.
**Do this instead:** Static `Color` and `Font` extensions. No environment propagation needed.

---

## Scaling Considerations

This is a single-user iOS app. Scaling here means maintenance scale as the view count grows.

| Concern | Approach |
|---------|----------|
| New views need consistent styling | DesignSystem group is source of truth; new views import tokens |
| Accent color change | Edit one `AccentGreen.colorset` + `Color.accent` definition |
| Adding a 4th tab | Add tab item to `MainTabView`; MiniPlayer placement unaffected |
| Multiple themes (future) | Promote `Color.accent` etc. to `@Environment` at that point; current static approach is correct first step |

---

## Sources

- Direct codebase reading: `ContentView.swift`, `BeatStepApp.swift`, `RunView.swift`, `MiniPlayerView.swift`, `PlaylistListView.swift`, `SettingsView.swift` — verified 2026-03-23 (HIGH confidence)
- SwiftUI `TabView` + per-tab `NavigationStack` pattern — Apple WWDC 2022 "The SwiftUI cookbook for navigation" (HIGH confidence)
- `safeAreaInset` for persistent overlays — SwiftUI documentation, iOS 15+ (HIGH confidence)
- Asset Catalog single-swatch dark-only color configuration — Xcode documentation (HIGH confidence)
- `preferredColorScheme` placement best practice — SwiftUI documentation (HIGH confidence)
- Static Color extensions for design tokens — established SwiftUI community pattern, no Environment indirection needed for static themes (MEDIUM confidence — widely used pattern, not formally documented as "recommended" by Apple)

---

*Architecture research for: BeatStep v1.1 Dark by Design — design system, tab navigation, brand assets*
*Researched: 2026-03-23*
