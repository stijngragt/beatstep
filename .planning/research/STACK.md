# Stack Research

**Domain:** Native iOS running music-sync app (accelerometer cadence to Spotify BPM matching)
**Researched:** 2026-03-24
**Confidence:** HIGH (all v1.2 additions use first-party Apple APIs; no third-party libraries required)

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

## v1.1 Stack Additions: Dark by Design (Validated — Do Not Re-Research)

All v1.1 additions are first-party SwiftUI patterns working in production. See prior research file for full detail on design token architecture, dark mode Info.plist config, TabView with UITabBarAppearance, and app icon asset catalog setup.

---

## v1.2 Stack Additions: The Right Flow

All v1.2 capabilities use **zero new external dependencies**. Every item below is a first-party Apple pattern.

### Core Technologies (v1.2)

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| SwiftUI `.overlay` + `@AppStorage` | iOS 17+ | Onboarding flow gate and state persistence | `.overlay` presents onboarding above existing ContentView without modifying the NavigationStack or TabView. `@AppStorage("hasCompletedOnboarding")` persists state in UserDefaults with automatic SwiftUI binding — no manual UserDefaults reads needed. |
| SwiftUI `ScrollView` (horizontal, programmatic) with `ScrollPosition` | iOS 17+ | Multi-step onboarding screen progression | `ScrollPosition` (iOS 17) allows programmatic screen-to-screen navigation while disabling free swiping. Each step fills width via `.containerRelativeFrame([.horizontal])`. Cleaner than `TabView` which allows uncontrolled swiping; cleaner than `ZStack` with manual state. |
| `HealthKit` (`HKHealthStore`) | iOS 13+ | Apple Health permission request in onboarding | Only required for the permission-priming screen in onboarding. BeatStep does NOT need to read Health data — it reads motion from CoreMotion directly. `HKHealthStore.requestAuthorization(toShare: [], read: [HKQuantityType(.stepCount)])` triggers the iOS permission sheet, which is the value-framed moment: "BeatStep works better with Health access." |
| `SwiftUI.Picker` with `.segmented` style | iOS 17+ | BPM tolerance picker redesign (±3, ±7, ±12) | The existing `BPMTolerance.description` computed property already returns "±3 BPM" etc. Replace the three-label segmented control labels ("Tight (±3 BPM)") with just the delta values ("±3", "±7", "±12") — no model change needed, only the `TolerancePicker` view label. |
| `enum RunZone` (new model, no persistence API needed) | Swift / iOS 17+ | Zone-based running: Z1–Z5 + Free | Replace `PacePreset` with `RunZone`. Zone BPM defaults stored in `UserDefaults` via `@AppStorage` for user configurability. `RunZone` carries zone number, default BPM, display name, and color (maps to DesignTokens palette). No new persistence framework needed — SwiftData already used for BPM cache; `UserDefaults` is appropriate for simple scalar settings. |
| `safeAreaInset(edge: .bottom)` | iOS 15+ | Full-width Run CTA at bottom of Run tab | Already used in `ContentView` for `MiniPlayerView`. Apply same pattern to `RunTabView`: pin a full-width accent button above the safe area bottom edge. Button gets `.frame(maxWidth: .infinity)` before `.background` so the background fills the full width. |

### Supporting Libraries (v1.2)

None. All v1.2 work is first-party SwiftUI and Apple framework patterns.

### Development Tools (v1.2)

No new tools required. Existing Xcode project with Swift 6, SwiftData, and CoreMotion is sufficient.

---

## Zone Model Design

### RunZone enum replaces PacePreset

The existing `PacePreset` enum (easyJog/steady/tempo/fast/sprint/custom with hardcoded BPM) must be replaced by `RunZone` with user-configurable defaults:

```swift
enum RunZone: String, CaseIterable, Identifiable {
    case free
    case z1, z2, z3, z4, z5

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .free: return "Free"
        case .z1: return "Z1 — Recovery"
        case .z2: return "Z2 — Aerobic"
        case .z3: return "Z3 — Tempo"
        case .z4: return "Z4 — Threshold"
        case .z5: return "Z5 — Max Effort"
        }
    }

    var defaultBPM: Int? {
        switch self {
        case .free: return nil      // No target — music adapts to pace
        case .z1: return 150
        case .z2: return 160
        case .z3: return 170
        case .z4: return 180
        case .z5: return 190
        }
    }
}
```

BPM defaults are informed by the running cadence literature: recreational runners range 150–170 spm, with 180 spm as the widely-cited optimum for tempo running, and elite runners reaching up to 190–200 spm. These align with the existing `PacePreset` BPM values, so no RunEngine recalibration is needed.

Zone color mapping: use existing DesignTokens palette. Z1 → `textTertiary`, Z2 → `textSecondary`, Z3 → `stateWarning`, Z4 → `stateError`, Z5 → `accent`, Free → `stateSuccess`.

### Zone BPM UserDefaults Persistence

Store per-zone overrides as individual `@AppStorage` keys rather than encoding to JSON:

```
"zoneBPM_z1" → Int (default 150)
"zoneBPM_z2" → Int (default 160)
"zoneBPM_z3" → Int (default 170)
"zoneBPM_z4" → Int (default 180)
"zoneBPM_z5" → Int (default 190)
```

A `ZoneSettingsService` (or Settings section in `SettingsView`) reads/writes these keys. `RunZone.bpm(forUser:)` resolves override → default.

---

## Onboarding Flow Architecture

### State gate pattern

```swift
// In ContentView
@AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

var body: some View {
    Group {
        if authService.isAuthenticated {
            authenticatedView
        } else {
            LoginView()
        }
    }
    .overlay {
        if !hasCompletedOnboarding {
            OnboardingFlow(isComplete: $hasCompletedOnboarding)
                .transition(.opacity)
        }
    }
}
```

The overlay presents before authentication — users see the value proposition before being sent to Spotify login. This is the correct UX order: prime the value, request permissions, then authenticate.

### Permission priming sequence

1. **Welcome screen** — value proposition, "Your music, your stride"
2. **Motion access screen** — explain why cadence detection needs motion; trigger `CMMotionActivityManager.authorizationStatus` check; button triggers the actual permission request
3. **Apple Health screen** — explain the benefit ("Works better with Health sync"); trigger `HKHealthStore().requestAuthorization(...)`; skip allowed
4. **Spotify screen** — "Connect your music"; routes to existing `LoginView` / `SpotifyAuthService.initiateAuth()`

### Re-triggerable from Settings

Add "Permissions" section to `SettingsView` with individual "Re-authorize" buttons. Each button triggers the OS permission dialog again (for motion and Health). For Spotify, re-auth is already handled by the Disconnect/Reconnect pattern. Set `hasCompletedOnboarding = false` via `@AppStorage` to replay full flow on request.

---

## HealthKit Integration Scope

**BeatStep does NOT read Health data.** The only reason to integrate HealthKit is to surface the Apple Health permission dialog in onboarding as a value-framing moment. If the user declines, the app functions identically — CoreMotion's `CMPedometer` does not require Health authorization.

Required Info.plist additions:

```xml
<key>NSHealthShareUsageDescription</key>
<string>BeatStep can read your step data from Apple Health to improve cadence accuracy when your phone is pocketed.</string>
```

Do NOT add `NSHealthUpdateUsageDescription` — BeatStep never writes to Health.

Required framework: `HealthKit.framework` linked as Optional (not Required) so the app does not crash on devices where HealthKit is unavailable (e.g., iPad). Check `HKHealthStore.isHealthDataAvailable()` before calling `requestAuthorization`.

---

## BPM Tolerance Picker Redesign

No model changes. `BPMTolerance` enum and its `range` / `description` properties are correct as-is.

Change is isolated to `TolerancePicker.swift`: replace `"\(level.displayName) (\(level.description))"` labels with just `level.description` ("±3 BPM", "±7 BPM", "±12 BPM") or even shorter ("±3", "±7", "±12") for the segmented control.

Segmented control character count matters — the current labels ("Tight (±3 BPM)") are long enough to compress on small screens. Shorter labels fix this without any model or logic changes.

---

## Full-Width Run CTA

Pattern: `.safeAreaInset(edge: .bottom)` on the `NavigationStack` wrapping `RunTabView`, or within `RunTabView` itself using a `VStack` with a `Spacer` pushing the button down. The `safeAreaInset` approach is preferred because it keeps the button visible even when the MiniPlayer is shown (both stack in the safe area inset chain).

```swift
// In RunTabView or its NavigationStack
.safeAreaInset(edge: .bottom) {
    Button { /* start run */ } label: {
        Text("Start Run")
            .font(.bodyBold)
            .foregroundStyle(Color.textOnAccent)
            .frame(maxWidth: .infinity)
            .frame(height: ComponentSize.buttonHeight)
            .background(Color.accent)
            .clipShape(RoundedRectangle(cornerRadius: Radius.pill))
    }
    .padding(.horizontal, Spacing.md)
    .padding(.bottom, Spacing.sm)
}
```

Note: `ComponentSize.buttonHeight` (52) is already defined in `DesignTokens.swift`. No new token needed.

---

## Analyzed State UX

`ScannedPlaylist` already has `tracksWithBPM`, `totalTracks`, and `lastScanned` fields. No model changes needed.

The visual change is in `PlaylistListView` (Library tab): surface the existing `coverageText` property as a pill or badge on each playlist row. An "Analyze" button inline with the row calls the existing `LibraryScanService.shared.scan(playlist:)` flow.

No new APIs or services required.

---

## What NOT to Add

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| Third-party onboarding library (OnboardingKit, etc.) | Zero benefit over native SwiftUI; adds dependency; doesn't use BeatStep's design tokens | `ScrollView` + `ScrollPosition` + `.overlay` pattern |
| `TabView` with `.tabViewStyle(.page)` for onboarding | Allows uncontrolled free-swiping between screens; hard to enforce forward-only flow | Horizontal `ScrollView` with `scrollTargetBehavior(.viewAligned)` and `ScrollPosition` |
| Full HealthKit integration (workout sessions, HRV, etc.) | Out of scope per PROJECT.md — no workout tracking, no analytics | Permission request only; read nothing |
| Core Data / additional SwiftData models for zone settings | Overkill for 5 integer values | `@AppStorage` / `UserDefaults` with per-zone keys |
| Custom segmented control library | Native `Picker` with `.segmented` supports simple text labels cleanly; shorter label text is the fix | Shorten `BPMTolerance` display labels |
| `NSHealthUpdateUsageDescription` | BeatStep never writes to Health | Only add `NSHealthShareUsageDescription` |

---

## Version Compatibility

| Feature | Min iOS | Notes |
|---------|---------|-------|
| `@AppStorage` | iOS 14 | Standard UserDefaults binding |
| `ScrollPosition` | iOS 17 | Required for programmatic horizontal scroll navigation |
| `.containerRelativeFrame([.horizontal])` | iOS 17 | Each onboarding page fills container width |
| `scrollTargetBehavior(.viewAligned)` | iOS 17 | Snap-to-page behavior |
| `HKHealthStore.requestAuthorization` | iOS 13 | Standard HealthKit permission |
| `HKHealthStore.isHealthDataAvailable()` | iOS 13 | Availability check before calling HealthKit |
| `safeAreaInset(edge:)` | iOS 15 | Already used in ContentView for MiniPlayer |
| `HealthKit.framework` as Optional link | Xcode 14+ | Prevents crash on iPad/non-Health devices |

Project already targets iOS 17+ (based on `ScrollPosition` usage being available and existing code patterns). All v1.2 additions are within this target.

---

## Integration Points

| v1.2 Feature | Existing Code Touched | Change Type |
|---|---|---|
| Onboarding flow | `ContentView.swift` | Add `.overlay` gate with `@AppStorage` |
| Zone model | `PacePreset.swift` | Replace enum; update callers in RunEngine |
| Zone settings | `SettingsView.swift` | Add Zone BPM section |
| Tolerance picker | `TolerancePicker.swift` | Change label text only |
| Analyzed state | `PlaylistListView` (Library views) | Surface existing `ScannedPlaylist` fields |
| Full-width Run CTA | `RunTabView.swift` | Restructure button into `safeAreaInset` |
| Info.plist | `Info.plist` | Add `NSHealthShareUsageDescription` |
| App target | Xcode project file | Add `HealthKit.framework` as optional |

---

## Sources

- [Apple Developer: Authorizing access to health data](https://developer.apple.com/documentation/healthkit/authorizing-access-to-health-data) — HealthKit permission flow (HIGH confidence)
- [Apple Developer: NSHealthShareUsageDescription](https://developer.apple.com/documentation/BundleResources/Information-Property-List/NSHealthShareUsageDescription) — Info.plist key requirement (HIGH confidence)
- [Apple Developer: Configuring HealthKit access](https://developer.apple.com/documentation/xcode/configuring-healthkit-access) — Optional framework linking (HIGH confidence)
- [Apple Developer: SegmentedPickerStyle](https://developer.apple.com/documentation/swiftui/segmentedpickerstyle) — Native segmented control API (HIGH confidence)
- [Rivera Labs: Building a Better Onboarding Flow in SwiftUI for iOS 18+](https://www.riveralabs.com/blog/swiftui-onboarding/) — ScrollPosition + overlay patterns (MEDIUM confidence)
- [magnuskahr: Better placements of bottom buttons in SwiftUI](https://www.magnuskahr.dk/posts/2022/10/better-placements-of-bottom-buttons-in-swiftui/) — safeAreaInset for bottom CTA (MEDIUM confidence)
- [Running Writings: Science of cadence](https://runningwritings.com/2026/01/science-of-cadence.html) — Cadence range 150–190 spm for zone BPM defaults (MEDIUM confidence)
- [TrainingPeaks: Finding Your Perfect Run Cadence](https://www.trainingpeaks.com/blog/finding-your-perfect-run-cadence/) — 180 spm as widely-cited tempo optimum (MEDIUM confidence)

---
*Stack research for: BeatStep v1.2 The Right Flow — onboarding, zone model, analyzed state UX, tolerance picker, Run CTA*
*Researched: 2026-03-24*
