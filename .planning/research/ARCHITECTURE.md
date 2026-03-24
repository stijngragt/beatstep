# Architecture Research

**Domain:** iOS music-sync running app — v1.2 feature integration
**Researched:** 2026-03-24
**Confidence:** HIGH (full codebase read, no external verification needed — integration research on known code)

---

## Existing Architecture (v1.1 Baseline)

### System Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                          App Entry                                   │
│   BeatStepApp — ModelContainer init, SpotifyAuthService env         │
│   ContentView — auth gate: LoginView vs TabView                     │
├──────────────────────┬──────────────────────┬───────────────────────┤
│   Library Tab        │   Run Tab            │   Settings Tab        │
│   PlaylistListView   │   RunTabView         │   SettingsView        │
│   PlaylistDetailView │   RunView            │                       │
│   (NavigationStack)  │   (NavigationStack)  │   (NavigationStack)   │
├──────────────────────┴──────────────────────┴───────────────────────┤
│                    Global: MiniPlayerView (safeAreaInset)            │
├─────────────────────────────────────────────────────────────────────┤
│                          Services Layer                              │
│  RunEngineService   CadenceService   LibraryScanService             │
│  SpotifyAuthService SpotifyAPIService SpotifyPlayerService          │
│  BPMCacheService    GetSongBPMService BPMDiscoveryService           │
│  AudioSessionService                                                │
├─────────────────────────────────────────────────────────────────────┤
│                          Data Layer                                  │
│  SwiftData: CachedBPM, ScannedPlaylist                              │
│  UserDefaults: RunMode, BPMTolerance, targetBPM, LastRunPlaylist    │
│  Keychain: Spotify tokens (via KeychainManager)                     │
└─────────────────────────────────────────────────────────────────────┘
```

### Existing Component Responsibilities

| Component | Responsibility | Observable Pattern |
|-----------|---------------|-------------------|
| `BeatStepApp` | ModelContainer init, auth env injection, scene-phase player lifecycle | `@main`, `App` |
| `ContentView` | Auth gate: `LoginView` vs authenticated TabView | `@Observable` env read |
| `RunEngineService` | Cadence→BPM matching, ramp state machine, song-end/cadence monitors | `@Observable` singleton |
| `CadenceService` | CMPedometer wrapper, rolling avg smoothing, permission management | `@Observable` singleton |
| `LibraryScanService` | BPM scan orchestration, `ScanProgress` publish | `@MainActor @Observable` singleton |
| `BPMCacheService` | SwiftData read/write for `CachedBPM` + `ScannedPlaylist` | Singleton, ModelContext holder |
| `GetSongBPMService` | Cloudflare proxy → GetSongBPM API | Async, throws |
| `BPMDiscoveryService` | Spotify catalog search for BPM-matched tracks when pool runs low | Async |
| `SpotifyAuthService` | PKCE OAuth, token storage, `isAuthenticated` publish | `@Observable` singleton, env object |
| `SpotifyAPIService` | REST calls: playlists, tracks, user | Async, throws |
| `SpotifyPlayerService` | Web API playback control, `currentTrack` publish | `@Observable` singleton |
| `AudioSessionService` | AVAudioSession category setup for background audio | Singleton |
| `DesignTokens.swift` | Color, Font, Spacing, Radius, ComponentSize tokens | Static extensions and enums |

### Existing Data Models of Interest for v1.2

| Model | Storage | v1.2 Status |
|-------|---------|-------------|
| `RunMode` (.free / .guided) | UserDefaults | **Keep** — engine-level concept; zone model sits above it |
| `PacePreset` (easyJog/steady/tempo/fast/sprint/custom) | UserDefaults via `RunMode.savedTargetBPM` | **Replace** with `RunZone` at UI layer |
| `BPMTolerance` (.tight / .normal / .loose) | UserDefaults | **Keep enum unchanged** — UI label format changes only |
| `ScannedPlaylist` | SwiftData `@Model` | **Unchanged** — `tracksWithBPM` + `totalTracks` + `lastScanned` already sufficient |
| `LastRunPlaylist` | UserDefaults (static enum) | **Keep** — read path in Run tab, write path in RunView already exists |
| `RampPhase` (.warmUp / .atPace / .coolDown) | In-memory in `RunEngineService` | **Unchanged** — zones map to these phases at run-start |

---

## v1.2 Integration Points

### Feature 1: Onboarding Flow

**Current state:** `LoginView` is the only pre-auth screen. It handles Spotify connect only. There is no motion/HealthKit permission framing. No onboarding completion tracking.

**New requirement:** Multi-step value-framed onboarding (Spotify + Apple Health permissions) that gates first launch and is re-triggerable from Settings.

**Where it plugs in:** `ContentView` is the auth gate today:

```
ContentView: isAuthenticated? → TabView : LoginView
```

For v1.2, add a second gate condition — `hasCompletedOnboarding` (UserDefaults bool):

```
ContentView appState:
  !hasCompletedOnboarding          → OnboardingFlow (new)
  hasCompletedOnboarding + !authed → LoginView (existing, or absorbed into onboarding)
  hasCompletedOnboarding + authed  → TabView (unchanged)
```

Introduce a computed `appState: AppState` enum in `ContentView` to keep the gate readable:

```swift
enum AppState { case onboarding, login, authenticated }
```

**New component: `OnboardingFlow`**

A `TabView` with `.tabViewStyle(.page)` for swipe-through behavior. Page-style avoids back-button affordance on permission screens and matches iOS onboarding conventions.

Three screens inside:
1. `OnboardingValueView` — BEATSTEP brand, core value prop, "Get Started" advance
2. `OnboardingSpotifyView` — why Spotify; "Connect with Spotify" calls `authService.initiateAuth()` (existing); observe `authService.isAuthenticated` to auto-advance
3. `OnboardingHealthView` — why motion access matters; "Allow Motion Access" calls `CadenceService.shared.requestPermission()` (existing); writes `onboardingCompleted = true` to UserDefaults; `ContentView` re-evaluates

**Re-triggerable from Settings:** `SettingsView` gains a "Revisit Permissions" action that sets `onboardingCompleted = false` in UserDefaults. No navigation changes needed — `ContentView` re-evaluates on next render or scene re-activation.

**Service boundary:** No service changes required. Both `authService.initiateAuth()` and `CadenceService.requestPermission()` exist and work. Onboarding is purely a UI sequencing wrapper.

---

### Feature 2: Playlist Analyzed State + Inline Analyze Action

**Current state:**
- `PlaylistRow` in `PlaylistListView` shows `coverageText` only when `tracksWithBPM > 0` (partial/full)
- Analyze action is a toolbar button in `PlaylistDetailView` — not visible from the list
- `ScannedPlaylist` model already has `tracksWithBPM`, `totalTracks`, `lastScanned`

**New requirement:** Show analyzed/unanalyzed state on every row; inline analyze button for unanalyzed playlists.

**Three display states needed:**

| State | Condition | Display |
|-------|-----------|---------|
| Not analyzed | No `ScannedPlaylist` record OR `lastScanned == nil` | "Analyze" button inline |
| Partially analyzed | `tracksWithBPM > 0 && tracksWithBPM < totalTracks` | Coverage text + re-analyze option |
| Fully analyzed | `tracksWithBPM == totalTracks` | Coverage text (green) |

**`coverageMap` extension:** Today `coverageMap: [String: String]` in `PlaylistListView`. Replace with a typed value:

```swift
struct PlaylistCoverage {
    let coverageText: String
    let isFullyAnalyzed: Bool
    let isScanning: Bool
}
```

Map: `coverageMap: [String: PlaylistCoverage]`. `PlaylistRow` receives `coverage: PlaylistCoverage?` (nil = not analyzed).

**Inline analyze action:** `PlaylistRow` does not hold tracks — tracks are only loaded in `PlaylistDetailView`. The inline button must propagate the action up.

Approach: `PlaylistRow` receives an `onAnalyze: (() -> Void)?` closure. `PlaylistListView` passes a closure that calls `analyzePlaylist(_ playlist:)` — a new async function on `PlaylistListView` that:
1. Fetches tracks via `SpotifyAPIService.shared.fetchPlaylistTracks(...)`
2. Calls `LibraryScanService.shared.scanPlaylist(playlist, tracks:)` (unchanged)
3. Refreshes `coverageMap` on completion

`LibraryScanService.scanProgress` is already `@Observable` — `PlaylistListView` can observe it to show per-row scanning state without any service changes.

**No changes to `LibraryScanService`, `BPMCacheService`, or `ScannedPlaylist` model.**

---

### Feature 3: Zone-Based Running (Z1–5 + Free)

**Current state:**
- `RunMode` enum: `.free` / `.guided`
- `PacePreset` enum: five fixed BPMs + custom
- `RunEngineService` uses `runMode: RunMode` and `targetBPM: Int` (private, set from `RunMode.savedTargetBPM`)
- `ModePicker` shows segmented `free/guided`; `PacePresetPicker` shows chip scroll for guided mode

**New requirement:** Replace `free/guided + PacePreset` UI with Z1–5 + Free zone concepts, each with configurable BPM defaults in Settings.

**Key insight:** `RunEngineService` already works on exactly two parameters: `runMode` and `targetBPM`. Zone-based running maps directly to these. **`RunEngineService` does not change.**

**New model: `RunZone`**

```swift
enum RunZone: String, CaseIterable, Identifiable {
    case free
    case z1  // Active Recovery — default 150 BPM
    case z2  // Endurance — default 160 BPM
    case z3  // Tempo — default 170 BPM
    case z4  // Threshold — default 180 BPM
    case z5  // Max Effort — default 190 BPM
}
```

Each zone has:
- A display label ("Free", "Z1", "Z2" ... "Z5")
- A descriptive name ("Active Recovery", "Endurance", etc.)
- A default BPM (factory hardcoded; user-overridable via Settings)
- A mapping to `RunMode` (`.free` → `RunMode.free`; z1–z5 → `RunMode.guided`)

Zone BPM overrides stored in UserDefaults, one key per zone, using static computed properties on `RunZone` (same pattern as `RunMode.savedTargetBPM`).

**UI replacement in `RunView`:**

| Removed | Replaced with |
|---------|--------------|
| `@State private var runMode: RunMode` | `@State private var selectedZone: RunZone` |
| `@State private var selectedPreset: PacePreset` | (removed) |
| `@State private var customBPM: Int` | Moved to zone BPM override in Settings |
| `ModePicker(mode:)` | `ZonePicker(selectedZone:)` (new component) |
| `PacePresetPicker(selectedPreset:customBPM:)` | (removed from idle view) |

At run-start in `RunView.controlsSection`, zone maps to engine params:

```swift
runEngine.runMode = selectedZone == .free ? .free : .guided
if runEngine.runMode == .guided {
    RunMode.savedTargetBPM = selectedZone.effectiveBPM  // reads UserDefaults override or default
}
```

**Settings integration:** New `ZoneSettingsSection` or `ZoneSettingsView` in `SettingsView` — one stepper per zone (z1–z5) to override default BPM. Free zone has no BPM to configure.

---

### Feature 4: Improved Run Setup UI

**Full-width Run CTA in Run tab:**

Today `RunTabView` shows last-run playlist context and a non-functional "Start Run" button. The actual run-start lives in `PlaylistDetailView` → `RunView` (Library tab NavigationStack).

For v1.2, the Run tab should be a proper setup surface with a full-width CTA.

**Navigation architecture decision:**

Option A: Run tab stays as a context summary; "Start Run" navigates to `RunView` within the Run tab's own NavigationStack using `LastRunPlaylist` context (loads tracks on tap).

Option B: Run tab embeds a zone picker + playlist selector + full-width CTA; `RunView` is pushed within the Run tab's NavigationStack.

**Recommended: Option A (minimal structural change).** `RunTabView` gains a `ZonePicker` and a full-width `Start Run` button. On tap, it loads tracks for the last-used playlist (async via `SpotifyAPIService`) and pushes `RunView` inside the Run tab's NavigationStack. The Library path (`PlaylistDetailView` → `RunView`) continues to work unchanged.

This avoids moving `RunView` or creating duplicate navigation paths. The Run tab becomes the "quick start" surface for returning runners; the Library tab remains the "browse and start" path.

**BPM Tolerance picker — label format update:**

`TolerancePicker` currently shows `"Tight (±3 BPM)"` / `"Normal (±7 BPM)"` / `"Loose (±12 BPM)"`.

The requirement is `±3` / `±7` / `±12` as the visible labels. This is a **`TolerancePicker` view change only** — use `tolerance.description` (`"±3 BPM"`) instead of `"\(tolerance.displayName) (\(tolerance.description))"`. The `BPMTolerance` enum and `range` property are unchanged.

---

## Component Map: New vs Modified vs Unchanged

| Component | Status | What Changes |
|-----------|--------|--------------|
| `ContentView` | **Modified** | Add `appState` computed enum; route to `OnboardingFlow` |
| `LoginView` | **Modified or absorbed** | Potentially absorbed as step 2 of `OnboardingFlow`; keeps existing connect button logic |
| `OnboardingFlow` | **New** | `TabView(.page)` container with 3 steps; writes `onboardingCompleted` to UserDefaults |
| `OnboardingValueView` | **New** | Value prop + brand screen |
| `OnboardingSpotifyView` | **New** | Spotify permission framing; calls `authService.initiateAuth()` |
| `OnboardingHealthView` | **New** | Motion permission framing; calls `cadenceService.requestPermission()` |
| `PlaylistListView` | **Modified** | `analyzePlaylist()` async function; `coverageMap` type upgrade |
| `PlaylistRow` | **Modified** | Show analyzed state indicator; conditional inline analyze button via closure |
| `PlaylistDetailView` | **Minor** | Toolbar analyze button may be redundant; review and keep or remove |
| `RunTabView` | **Modified** | Add `ZonePicker`; full-width Start Run CTA; async track load + navigate |
| `RunView` | **Modified** | Replace `runMode`+`selectedPreset`+`customBPM` with `selectedZone: RunZone` |
| `ModePicker` | **Remove** | Superseded by `ZonePicker` |
| `PacePresetPicker` | **Remove** | Superseded by zone concept |
| `ZonePicker` | **New** | Zone chip picker (Free + Z1–Z5); same visual pattern as `PacePresetPicker` chips |
| `TolerancePicker` | **Modified** | Label format only: `±3 BPM` instead of `Tight (±3 BPM)` |
| `RunZone` | **New** | Zone enum; default BPMs; UserDefaults persistence per zone |
| `PacePreset` | **Deprecated** | Remove once `RunZone` fully replaces it |
| `SettingsView` | **Modified** | Add zone BPM defaults section; add "Revisit Permissions" action |
| `ZoneSettingsSection` | **New** | Stepper controls for per-zone BPM defaults |
| `RunEngineService` | **Unchanged** | Accepts `runMode` + `targetBPM`; zone mapping happens at call site only |
| `CadenceService` | **Unchanged** | Permission request already works |
| `SpotifyAuthService` | **Unchanged** | `initiateAuth()` already works |
| `LibraryScanService` | **Unchanged** | `scanPlaylist()` API is sufficient |
| `BPMCacheService` | **Unchanged** | No data model changes needed |
| `ScannedPlaylist` | **Unchanged** | `tracksWithBPM`, `totalTracks`, `lastScanned` already sufficient |
| `BPMTolerance` | **Unchanged** | Enum and `range` property unchanged |
| `DesignTokens.swift` | **Possibly extended** | Zone color tokens (Z1–Z5 spectrum) if zone chips need color coding |

---

## Data Flow Changes

### Onboarding → App Entry

```
App launch
  → BeatStepApp init
  → ContentView body
  → appState computed from:
       UserDefaults "onboardingCompleted" (bool)
       SpotifyAuthService.isAuthenticated (observable)

  appState == .onboarding → OnboardingFlow
    step 0: OnboardingValueView (advance via button)
    step 1: OnboardingSpotifyView
              → authService.initiateAuth()
              → on isAuthenticated == true: auto-advance
    step 2: OnboardingHealthView
              → cadenceService.requestPermission()
              → write UserDefaults "onboardingCompleted" = true
              → ContentView re-evaluates → .authenticated

  appState == .login → LoginView (unchanged)

  appState == .authenticated → TabView (unchanged)
```

### Zone Selection → Run Start

```
RunTabView / RunView idle state
  → ZonePicker: user selects zone (e.g. Z3)
  → selectedZone = .z3
  → zone.effectiveBPM reads UserDefaults override or default (170)

  "Start Run" tapped
  → RunView.controlsSection:
       runEngine.runMode = .guided (zone != .free)
       RunMode.savedTargetBPM = selectedZone.effectiveBPM
       runEngine.tolerance = tolerance
       LastRunPlaylist.* = playlist data
       cadenceService.requestPermissionAndStart()
       Task { await runEngine.startRun(playlist:, tracks:) }

  → RunEngineService (internal logic unchanged)
       reads runMode == .guided
       reads targetBPM from RunMode.savedTargetBPM
       ramp state machine starts from .warmUp phase
```

### Playlist Analyzed State

```
PlaylistListView.task
  → loadPlaylists() — Spotify API fetch (unchanged)
  → loadCoverageData()
       → SwiftData FetchDescriptor<ScannedPlaylist>
       → build coverageMap: [String: PlaylistCoverage]
            PlaylistCoverage { coverageText, isFullyAnalyzed, isScanning }

  → PlaylistRow(playlist:, coverage: coverageMap[playlist.id], onAnalyze: {})

  coverage == nil (not analyzed):
    → show "Analyze" button inline
    → onAnalyze closure tapped

  → PlaylistListView.analyzePlaylist(_ playlist: SpotifyPlaylist) async
       → SpotifyAPIService.shared.fetchPlaylistTracks(...)  [all pages]
       → LibraryScanService.shared.scanPlaylist(playlist, tracks:)
            → scanProgress published (observed by PlaylistListView)
            → coverageMap updates per row while scanning
       → loadCoverageData() refresh on completion
```

---

## Architectural Patterns

### Pattern 1: Zone as Thin Wrapper Over Guided Mode

**What:** `RunZone` is a UI-facing model. It converts to `RunMode` + `targetBPM` at the run-start call site. `RunEngineService` never knows about zones.

**When to use:** When adding a richer UI concept that maps exactly to an existing engine parameter interface.

**Trade-offs:** Maintains clean engine boundary; requires explicit zone→engine mapping at the call site. One place: `RunView.controlsSection`. Keep the mapping there — don't push it into `RunZone` as an `applyToEngine()` method (that would create a service dependency in the model).

### Pattern 2: Onboarding as Root-Swap via Computed AppState

**What:** `ContentView` computes `appState: AppState` enum from UserDefaults + `SpotifyAuthService.isAuthenticated`. Onboarding replaces the root view — not a sheet or overlay.

**When to use:** Gating access where the flow should not be dismissable until steps complete.

**Trade-offs:** `ContentView` carries more conditions. A computed enum keeps this readable. The pattern is already proven in the codebase (`isAuthenticated` gate).

```swift
private var appState: AppState {
    guard UserDefaults.standard.bool(forKey: "onboardingCompleted") else { return .onboarding }
    guard authService.isAuthenticated else { return .login }
    return .authenticated
}
```

### Pattern 3: PlaylistCoverage as Typed Value, Not Optional String

**What:** Replace `coverageMap: [String: String?]` with `coverageMap: [String: PlaylistCoverage]` where `PlaylistCoverage` encodes the three states explicitly.

**When to use:** When a view needs to distinguish between "data not present" and "data present in different states."

**Trade-offs:** Small type proliferation. Worth it — `PlaylistRow` becomes a dumb display component that switches on an explicit type rather than optional string presence.

### Pattern 4: Inline Analyze via Closure Callback

**What:** `PlaylistRow` receives `onAnalyze: (() -> Void)?`. The closure calls up to `PlaylistListView`, which owns track loading + scan orchestration.

**When to use:** When a list row needs to trigger data operations but should not own data loading logic itself.

**Trade-offs:** Closure threading from row → parent view. Standard SwiftUI pattern. `LibraryScanService.scanProgress` observable handles progress feedback without a callback chain.

---

## Anti-Patterns to Avoid

### Anti-Pattern 1: Zones in RunEngineService

**What people do:** Add `selectedZone` property to `RunEngineService`; make the engine zone-aware.

**Why it's wrong:** `RunEngineService` is tested and working. Zones are a UX concept that map to existing parameters. Adding zone logic to the engine creates two places where BPM targets are resolved and couples UI concepts to the engine.

**Do this instead:** Zone→engine mapping lives entirely in `RunView.controlsSection` at run-start.

### Anti-Pattern 2: Track Loading Inside PlaylistRow

**What people do:** Give `PlaylistRow` a closure that loads tracks and calls `LibraryScanService`.

**Why it's wrong:** Row-level data fetching creates N concurrent requests as the user scrolls past unanalyzed playlists. Pagination and error handling belong at the parent view level.

**Do this instead:** `onAnalyze` closure propagates to `PlaylistListView`, which owns the fetch + scan orchestration serially.

### Anti-Pattern 3: Onboarding as Dismissable Sheet

**What people do:** Present onboarding as `.fullScreenCover` or `.sheet` on the main tab view.

**Why it's wrong:** Sheets can be dismissed. First-launch onboarding that gates permissions should not be bypassed.

**Do this instead:** `ContentView` root-swap via computed `appState`. Onboarding is the root, not an overlay.

### Anti-Pattern 4: Duplicating PacePreset Logic Into RunZone

**What people do:** Copy PacePreset's BPM values directly into RunZone as hardcoded constants.

**Why it's wrong:** Zone BPMs must be user-configurable (Settings requirement). Hardcoding them in the enum defeats that.

**Do this instead:** `RunZone` has a `defaultBPM` (factory constant) and an `effectiveBPM` computed property that reads from UserDefaults override, falling back to `defaultBPM`. Same pattern as `RunMode.savedTargetBPM`.

---

## Recommended Build Order

Dependencies determine order:

| Step | Component | Depends On | Rationale |
|------|-----------|-----------|-----------|
| 1 | `RunZone` model | Nothing | Unblocks RunView, Settings, ZonePicker |
| 2 | `TolerancePicker` label update | Nothing | Isolated, zero-risk, confirms tolerance approach |
| 3 | `ZonePicker` component | `RunZone` | Pure UI, no service deps; parallels step 2 |
| 4 | `RunView` zone integration | `RunZone`, `ZonePicker` | Core run-path change; replaces `ModePicker` + `PacePresetPicker` |
| 5 | `RunTabView` full-width CTA | `RunZone`, `ZonePicker` | Run tab setup surface; async track load pattern |
| 6 | Zone BPM defaults in `SettingsView` | `RunZone` | Can run parallel to steps 4–5 |
| 7 | `PlaylistCoverage` type + `PlaylistListView` analyzed state | Nothing | Independent of zone work |
| 8 | Inline analyze action | Step 7 | Depends on `PlaylistCoverage` type |
| 9 | Onboarding flow | All above working | Tests on clean-install simulator; final integration layer |

**Rationale for onboarding last:** Onboarding wraps `authService.initiateAuth()` and `cadenceService.requestPermission()` — both already work. Onboarding is UI-only sequencing. Testing requires a clean-install simulator with no prior auth state, which is simpler to validate as a final integration step after all features function correctly behind the gate.

---

## Integration Boundaries Summary

| New Feature | Touches | Does NOT Touch |
|-------------|---------|----------------|
| Onboarding | `ContentView`, new `OnboardingFlow/` files, `SettingsView` | All services, all data models |
| Analyzed state | `PlaylistListView`, `PlaylistRow`, new `PlaylistCoverage` type | `LibraryScanService`, `ScannedPlaylist`, `BPMCacheService` |
| Zone running | New `RunZone`, new `ZonePicker`, `RunView`, `RunTabView`, `SettingsView` | `RunEngineService`, `CadenceService`, `BPMCacheService` |
| Tolerance UI | `TolerancePicker` label format only | `BPMTolerance` enum, `RunEngineService` |
| Full-width CTA | `RunTabView` layout + async track load | All services |

---

## Sources

- Direct read of all Swift source files under `/BeatStep/` — HIGH confidence
- No external references needed; this is integration research on a fully-known codebase

---

*Architecture research for: BeatStep v1.2 — onboarding, analyzed state, zone running, run setup UX*
*Researched: 2026-03-24*
