# Phase 12: Onboarding - Research

**Researched:** 2026-03-24
**Domain:** SwiftUI onboarding flow, iOS permission priming, HealthKit integration, UserDefaults state management
**Confidence:** HIGH

## Summary

Phase 12 builds a first-launch onboarding flow that frames permissions as user benefits before triggering system dialogs, plus a Settings recovery path for denied permissions. All required services already exist and work -- `SpotifyAuthService.initiateAuth()` handles Spotify OAuth, `CadenceService.requestPermissionAndStart()` handles CoreMotion permission, and the HealthKit integration is permission-request-only (BeatStep never reads Health data; cadence comes from CoreMotion's CMPedometer). The work is purely UI sequencing atop existing service APIs.

The critical architectural decision is that the onboarding gate must live at the `ContentView` root level via a computed `AppState` enum -- not inside the TabView branch. This prevents the tab bar from flashing on first launch and prevents `LibraryScanService.scanEnabledPlaylists()` from firing before permissions are granted. The existing `ContentView` already gates on `authService.isAuthenticated`; onboarding adds a second condition (`hasCompletedOnboarding` via `@AppStorage`) evaluated before the auth check.

The HealthKit integration scope is minimal: add `HealthKit.framework` as an Optional link in project.yml, add `NSHealthShareUsageDescription` to Info.plist, and call `HKHealthStore().requestAuthorization(toShare: [], read: [HKQuantityType(.stepCount)])` during onboarding. The key pitfall is that HealthKit cannot distinguish "never asked" from "denied" for read types -- the re-trigger flow must use a "did we request" `@AppStorage` flag, not HealthKit's `authorizationStatus`.

**Primary recommendation:** Build a 3-screen horizontal ScrollView onboarding (Spotify value-frame, Health/Motion value-frame, Zones explainer) gated at ContentView root via `AppState` enum. Re-trigger from Settings links to iOS Settings app, not re-requesting authorization.

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| ONBD-01 | User sees a value-framed Spotify permission screen before the system OAuth dialog on first launch | AppState enum routing in ContentView; OnboardingSpotifyView calls existing `authService.initiateAuth()` after value framing; Spotify Premium check runs post-auth during onboarding |
| ONBD-02 | User sees a value-framed Apple Health permission screen before the system HealthKit dialog on first launch | HealthKit.framework Optional link + NSHealthShareUsageDescription; OnboardingHealthView frames benefit then calls `HKHealthStore().requestAuthorization()`; skippable since CMPedometer works independently |
| ONBD-03 | User sees a brief skippable "how zones work" screen during onboarding | OnboardingZonesView showing Z1-Z5 zone concept with skip button; positioned after permissions in flow |
| ONBD-04 | User can re-trigger permission setup from Settings when permissions were denied or revoked | "Revisit Permissions" section in SettingsView; links to iOS Settings via `UIApplication.openSettingsURLString` for denied permissions; uses `@AppStorage("hasRequestedMotion")` / `@AppStorage("hasRequestedHealth")` flags |
</phase_requirements>

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| SwiftUI `@AppStorage` | iOS 17+ | Onboarding completion flag, permission-requested flags | Automatic UserDefaults binding with SwiftUI reactivity; already used in project |
| SwiftUI `ScrollView` (horizontal) + `ScrollPosition` | iOS 17+ | Multi-step onboarding with programmatic forward-only navigation | Cleaner than TabView (which allows free swiping); `scrollTargetBehavior(.viewAligned)` gives page-snap |
| `.containerRelativeFrame([.horizontal])` | iOS 17+ | Each onboarding page fills screen width | Standard iOS 17 layout API |
| HealthKit (`HKHealthStore`) | iOS 13+ | Apple Health permission request only | Permission priming screen; BeatStep never reads Health data |
| CoreMotion (`CMPedometer.authorizationStatus()`) | iOS 11+ | Motion permission state check | Already used by CadenceService |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `UIApplication.openSettingsURLString` | iOS 8+ | Deep-link to app's iOS Settings for permission recovery | Re-trigger path in Settings for denied permissions |
| `HKHealthStore.isHealthDataAvailable()` | iOS 13+ | Guard before requesting HealthKit authorization | Skip Health permission screen on iPad or devices without HealthKit |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Horizontal ScrollView | `TabView(.page)` | TabView allows free swiping, cannot enforce forward-only progression |
| Root view swap via AppState | `.fullScreenCover` overlay | Sheets are dismissible; onboarding should not be bypassed |
| OnboardingKit (third-party) | Native SwiftUI | Zero benefit; adds dependency; does not use BeatStep design tokens |

### Installation

Add to `project.yml` under `BeatStep` target dependencies:
```yaml
- sdk: HealthKit.framework
  embed: false
  link: optional
```

Add to `project.yml` Info.plist properties:
```yaml
NSHealthShareUsageDescription: "BeatStep can sync with Apple Health to improve your running experience."
```

No package manager changes needed -- HealthKit is a system framework.

## Architecture Patterns

### Recommended Project Structure
```
BeatStep/Views/Onboarding/
  OnboardingFlow.swift          # ScrollView container + page state management
  OnboardingSpotifyView.swift   # Spotify value frame + connect button
  OnboardingHealthView.swift    # Health/Motion value frame + permission button
  OnboardingZonesView.swift     # Brief zones explainer (skippable)
```

### Pattern 1: AppState Enum Root Gate
**What:** `ContentView` computes `appState: AppState` from `@AppStorage("hasCompletedOnboarding")` and `authService.isAuthenticated`, routing to one of three root views.
**When to use:** When gating access where the flow should not be dismissible.
**Example:**
```swift
// Source: Architecture research + existing ContentView pattern
enum AppState {
    case onboarding
    case login
    case authenticated
}

// In ContentView
@AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

private var appState: AppState {
    guard hasCompletedOnboarding else { return .onboarding }
    guard authService.isAuthenticated else { return .login }
    return .authenticated
}

var body: some View {
    Group {
        switch appState {
        case .onboarding:
            OnboardingFlow()
        case .login:
            LoginView()
        case .authenticated:
            authenticatedView
        }
    }
}
```

### Pattern 2: Forward-Only Onboarding with ScrollPosition
**What:** Horizontal ScrollView with `ScrollPosition` for programmatic page advancement. User cannot swipe backward.
**When to use:** Multi-step flows requiring sequential completion.
**Example:**
```swift
// Source: Apple Developer Documentation - ScrollPosition (iOS 17)
struct OnboardingFlow: View {
    @State private var currentPage = 0
    @State private var scrollPosition = ScrollPosition()
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: 0) {
                OnboardingSpotifyView(onContinue: { advanceTo(1) })
                    .containerRelativeFrame([.horizontal])
                OnboardingHealthView(onContinue: { advanceTo(2) })
                    .containerRelativeFrame([.horizontal])
                OnboardingZonesView(onComplete: { complete() })
                    .containerRelativeFrame([.horizontal])
            }
            .scrollTargetLayout()
        }
        .scrollPosition($scrollPosition)
        .scrollTargetBehavior(.viewAligned)
        .scrollDisabled(true) // Prevent free swiping
    }

    private func advanceTo(_ page: Int) {
        currentPage = page
        withAnimation {
            scrollPosition.scrollTo(id: page)
        }
    }

    private func complete() {
        hasCompletedOnboarding = true
    }
}
```

### Pattern 3: Permission-Requested Tracking (Not Permission-Granted)
**What:** Store `@AppStorage("hasRequestedHealth")` and `@AppStorage("hasRequestedMotion")` booleans. Never rely on HealthKit's `authorizationStatus` for read types.
**When to use:** Any permission where the OS does not reliably report denial state (HealthKit read types).
**Example:**
```swift
// Source: Apple Developer Docs - HealthKit authorizationStatus behavior
@AppStorage("hasRequestedHealth") private var hasRequestedHealth = false

func requestHealthPermission() {
    guard HKHealthStore.isHealthDataAvailable() else { return }
    let store = HKHealthStore()
    let stepType = HKQuantityType(.stepCount)
    store.requestAuthorization(toShare: [], read: [stepType]) { success, error in
        DispatchQueue.main.async {
            self.hasRequestedHealth = true
            // Do NOT check authorizationStatus -- it returns .notDetermined even when denied
        }
    }
}
```

### Pattern 4: Re-Trigger as Link-to-Settings
**What:** The "Revisit Permissions" action in Settings opens the iOS Settings app where users can manage permissions. It does not re-call `requestAuthorization`.
**When to use:** Permission recovery for denied permissions.
**Example:**
```swift
// Source: Apple Developer Documentation
Button("Open Settings") {
    if let url = URL(string: UIApplication.openSettingsURLString) {
        UIApplication.shared.open(url)
    }
}
```

### Anti-Patterns to Avoid
- **Onboarding as `.fullScreenCover` on TabView:** Sheet is dismissible; tab bar and services initialize behind it; `LibraryScanService` fires prematurely.
- **Checking `HKHealthStore.authorizationStatus(for:)` for read types:** Returns `.notDetermined` even when denied. Code branching on `.denied` for read types never fires.
- **Re-calling `requestAuthorization` on re-trigger:** iOS only shows the system dialog once per permission type. Subsequent calls are no-ops. Link to Settings instead.
- **Placing onboarding gate inside `authenticatedView`:** Tab bar flashes, MiniPlayer renders, background scan fires before user completes onboarding.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Page-based onboarding navigation | Custom ZStack with offset tracking | `ScrollView(.horizontal)` + `ScrollPosition` + `scrollDisabled(true)` | Apple provides page-snap behavior and programmatic scrolling since iOS 17 |
| Permission state persistence | UserDefaults manual read/write | `@AppStorage` with boolean flags | Automatic SwiftUI binding eliminates manual sync |
| Deep-link to iOS Settings | Custom URL scheme construction | `UIApplication.openSettingsURLString` | System constant; always points to app's Settings page |
| HealthKit availability check | Try-catch around requestAuthorization | `HKHealthStore.isHealthDataAvailable()` | Returns false on iPad and devices without HealthKit sensor |

**Key insight:** Onboarding is UI sequencing, not new service logic. Every permission request method already exists in the codebase. The value is in framing and flow, not new capability.

## Common Pitfalls

### Pitfall 1: Onboarding Gate at Wrong View Hierarchy Level
**What goes wrong:** Gate placed inside authenticated TabView branch; tab bar flashes on first launch; `LibraryScanService.scanEnabledPlaylists()` fires before onboarding completes.
**Why it happens:** `ContentView` already branches on `isAuthenticated`; natural instinct is to add onboarding check inside the authenticated branch.
**How to avoid:** Place the `hasCompletedOnboarding` check BEFORE the `isAuthenticated` check using the `AppState` enum. TabView must never render until onboarding completes.
**Warning signs:** Tab bar briefly visible; library scan fires in console before permissions granted; MiniPlayer safeAreaInset visible during onboarding.

### Pitfall 2: HealthKit Read Authorization Status is Undetectable
**What goes wrong:** Re-trigger flow shows "Permission Granted" or "Permission Denied" for Health, but the state is always wrong for denied users.
**Why it happens:** `HKHealthStore.authorizationStatus(for:)` returns `.notDetermined` for denied read types by iOS design (privacy protection).
**How to avoid:** Track "did we request" in `@AppStorage`, not "was it granted." Re-trigger flow shows "Open Settings" link, never displays Health permission status.
**Warning signs:** Code calling `authorizationStatus` and branching on `.denied` -- that branch never fires for read types.

### Pitfall 3: LibraryScanService Fires Before Onboarding Completes
**What goes wrong:** The `.task` in `ContentView.authenticatedView` calls `LibraryScanService.shared.scanEnabledPlaylists()` -- this fires as soon as the user is authenticated, which in the current flow is DURING onboarding (Spotify connect is step 1).
**Why it happens:** The current gate flow is: not authenticated -> LoginView, authenticated -> TabView with `.task`. If onboarding makes the user authenticate first, the authenticated branch fires immediately.
**How to avoid:** The `AppState` enum ensures that `authenticatedView` (and its `.task`) never renders until `hasCompletedOnboarding == true`. The gate check order is: onboarding first, then auth, then tabs.
**Warning signs:** Network requests in console during onboarding; scan progress appearing before user has seen any playlists.

### Pitfall 4: Spotify Premium Detection Timing
**What goes wrong:** User completes Spotify auth during onboarding, but Premium check only happens later. Non-Premium user gets through onboarding, sees tabs, then hits a dead end trying to play.
**Why it happens:** The current `SpotifyAuthService.checkPremiumStatus()` already runs after token exchange. But if it fails or the user is Free tier, the onboarding flow needs to handle it gracefully.
**How to avoid:** After `authService.initiateAuth()` completes in the onboarding Spotify screen, observe `authService.isAuthenticated` AND `authService.authError`. If Premium check fails, show the error inline on the Spotify onboarding screen (reuse existing `LoginView` error handling pattern). Do not advance past the Spotify screen until Premium is confirmed.
**Warning signs:** Non-Premium user gets past onboarding; no error shown until they try to start playback.

### Pitfall 5: OnboardingFlow View Not Dismissed Reactively
**What goes wrong:** Setting `hasCompletedOnboarding = true` does not immediately swap the view because the `@AppStorage` change is not observed properly.
**Why it happens:** If `OnboardingFlow` sets the flag but `ContentView` does not re-evaluate its `appState` computed property.
**How to avoid:** `@AppStorage` in `ContentView` triggers automatic re-render. Ensure the flag is set from the main thread. The computed `appState` property is re-evaluated on every body call since `@AppStorage` is a `DynamicProperty`.
**Warning signs:** Onboarding appears stuck on last screen after tapping "Get Started."

## Code Examples

### ContentView with AppState Gate
```swift
// Source: Existing ContentView pattern + ARCHITECTURE.md
struct ContentView: View {
    @Environment(SpotifyAuthService.self) private var authService
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    private var appState: AppState {
        guard hasCompletedOnboarding else { return .onboarding }
        guard authService.isAuthenticated else { return .login }
        return .authenticated
    }

    var body: some View {
        Group {
            switch appState {
            case .onboarding:
                OnboardingFlow()
            case .login:
                LoginView()
            case .authenticated:
                authenticatedView
            }
        }
        .onAppear {
            AudioSessionService.shared.setupAudioSession()
            if hasCompletedOnboarding {
                SpotifyAuthService.shared.checkExistingAuth()
            }
        }
    }
}
```

### Onboarding Spotify Screen Value Frame
```swift
// Source: Design pattern from existing LoginView + UX best practices
struct OnboardingSpotifyView: View {
    @Environment(SpotifyAuthService.self) private var authService
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()

            // SF Symbol icon
            Image(systemName: "music.note.list")
                .font(.system(size: ComponentSize.iconLarge))
                .foregroundStyle(Color.spotifyBrand)

            // Value framing
            Text("Your Music Library")
                .font(.heading)
                .foregroundStyle(Color.textPrimary)

            Text("BeatStep picks songs that match your running cadence from your Spotify playlists.")
                .font(.bodyText)
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.xl)

            Spacer()

            // Connect button (reuses LoginView pattern)
            Button {
                authService.initiateAuth()
            } label: {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "music.note")
                    Text("Connect with Spotify")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.md)
                .background(Color.spotifyBrand)
                .foregroundStyle(Color.textOnAccent)
                .clipShape(RoundedRectangle(cornerRadius: Radius.pill))
            }
            .padding(.horizontal, Spacing.xl)

            // Error display (from LoginView pattern)
            if let error = authService.authError {
                Text(error)
                    .font(.captionText)
                    .foregroundStyle(Color.stateError)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.xl)
            }
        }
        .onChange(of: authService.isAuthenticated) { _, isAuth in
            if isAuth { onContinue() }
        }
    }
}
```

### HealthKit Permission Request
```swift
// Source: Apple Developer Documentation - Authorizing access to health data
import HealthKit

func requestHealthPermission() {
    guard HKHealthStore.isHealthDataAvailable() else {
        // iPad or device without Health -- skip
        hasRequestedHealth = true
        return
    }
    let store = HKHealthStore()
    let stepType = HKQuantityType(.stepCount)
    store.requestAuthorization(toShare: [], read: [stepType]) { success, error in
        DispatchQueue.main.async {
            self.hasRequestedHealth = true
            // Never check authorizationStatus for read types
        }
    }
}
```

### Settings Revisit Permissions Section
```swift
// Source: Existing SettingsView pattern
Section("Permissions") {
    // Motion
    HStack {
        Text("Motion Access")
            .foregroundStyle(Color.textSecondary)
        Spacer()
        Text(CMPedometer.authorizationStatus() == .authorized ? "Granted" : "Check Settings")
            .font(.captionText)
            .foregroundStyle(CMPedometer.authorizationStatus() == .authorized ? Color.stateSuccess : Color.stateWarning)
    }

    // Health (cannot detect denied -- show generic guidance)
    if HKHealthStore.isHealthDataAvailable() {
        HStack {
            Text("Apple Health")
                .foregroundStyle(Color.textSecondary)
            Spacer()
            Text(hasRequestedHealth ? "Requested" : "Not Yet")
                .font(.captionText)
                .foregroundStyle(Color.textSecondary)
        }
    }

    // Open Settings
    Button("Open Settings") {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
    .foregroundStyle(Color.accent)
}
```

### project.yml HealthKit Addition
```yaml
# Under BeatStep target dependencies, add:
- sdk: HealthKit.framework
  embed: false
  link: optional
```

```yaml
# Under BeatStep target info.properties, add:
NSHealthShareUsageDescription: "BeatStep can sync with Apple Health to improve your running experience."
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `TabView(.page)` for onboarding | `ScrollView` + `ScrollPosition` + `scrollDisabled(true)` | iOS 17 (2023) | Enforces forward-only progression; prevents uncontrolled swiping |
| Manual UserDefaults for state | `@AppStorage` with SwiftUI reactivity | iOS 14 (2020) | Automatic view re-render on state change |
| HealthKit write+read for fitness apps | HealthKit read-only (or permission-only) | N/A | BeatStep uses permission priming only; zero Health data read |

**Deprecated/outdated:**
- `TabView(.page)` for onboarding: still works but cannot prevent backward swiping or enforce step completion order
- Checking `HKHealthStore.authorizationStatus` for denied read state: has never worked; iOS returns `.notDetermined` by design

## Open Questions

1. **Spotify Premium detection during onboarding**
   - What we know: `SpotifyAuthService.checkPremiumStatus()` runs automatically after token exchange. If user is Free tier, `authError` is set and `isAuthenticated` remains `false`.
   - What's unclear: Whether the error messaging is user-friendly enough for the onboarding context (current error is "BeatStep requires Spotify Premium").
   - Recommendation: The existing flow handles this correctly -- the Spotify onboarding screen should observe `authError` and display it inline, preventing advancement. May want to add a "Try Different Account" button (already exists in LoginView error pattern). LOW risk.

2. **Onboarding screen count and ordering**
   - What we know: Requirements specify 3 screens (Spotify, Health, Zones). The ARCHITECTURE.md research suggested a welcome/value prop screen as screen 0.
   - What's unclear: Whether a dedicated welcome screen adds value or just adds friction.
   - Recommendation: Skip the welcome screen. The Spotify screen IS the first screen -- it frames the value ("Your music library, matched to your stride") before asking for Spotify connect. Three screens total: Spotify, Health/Motion, Zones. Fewer screens = higher completion rate.

3. **Motion permission vs Health permission screen separation**
   - What we know: CMPedometer (motion) and HealthKit (Health) are separate permission types. BeatStep needs motion; Health is optional/future.
   - What's unclear: Whether to combine into one "Fitness Permissions" screen or separate them.
   - Recommendation: Single screen. Frame it as "Motion & Health" -- request CMPedometer permission first (essential), then HealthKit (optional, skippable). Two separate system dialogs will fire sequentially, but the user sees one BeatStep screen.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | XCTest (built-in) |
| Config file | BeatStepTests target in project.yml |
| Quick run command | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BeatStepTests 2>&1 \| tail -20` |
| Full suite command | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 \| tail -50` |

### Phase Requirements to Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| ONBD-01 | AppState routes to onboarding when hasCompletedOnboarding is false | unit | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BeatStepTests/OnboardingTests -x` | Wave 0 |
| ONBD-02 | HealthKit permission request called with correct types (toShare empty, read stepCount) | unit | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BeatStepTests/OnboardingTests -x` | Wave 0 |
| ONBD-03 | Zones explainer screen is skippable (onComplete fires) | unit | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BeatStepTests/OnboardingTests -x` | Wave 0 |
| ONBD-04 | Settings "Open Settings" URL is correct | unit | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BeatStepTests/OnboardingTests -x` | Wave 0 |
| GATE | LibraryScanService does not fire when hasCompletedOnboarding is false | unit | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BeatStepTests/OnboardingTests -x` | Wave 0 |

### Sampling Rate
- **Per task commit:** Quick run of OnboardingTests
- **Per wave merge:** Full test suite
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] `BeatStepTests/OnboardingTests.swift` -- covers ONBD-01 through ONBD-04 + gate behavior
- [ ] Test for AppState enum routing logic (onboarding -> login -> authenticated precedence)
- [ ] Test that hasCompletedOnboarding flag prevents authenticated view from rendering

*(Note: Permission dialog tests are manual-only on device; automated tests cover the routing logic and flag management)*

## Sources

### Primary (HIGH confidence)
- Apple Developer Documentation: [Authorizing access to health data](https://developer.apple.com/documentation/healthkit/authorizing-access-to-health-data) -- HealthKit permission flow and authorizationStatus limitations
- Apple Developer Documentation: [NSHealthShareUsageDescription](https://developer.apple.com/documentation/BundleResources/Information-Property-List/NSHealthShareUsageDescription) -- Info.plist key requirement
- Apple Developer Documentation: [Configuring HealthKit access](https://developer.apple.com/documentation/xcode/configuring-healthkit-access) -- Optional framework linking
- Apple Developer Documentation: [CMPedometer.authorizationStatus()](https://developer.apple.com/documentation/coremotion/cmpedometer/1613955-authorizationstatus) -- Motion permission check
- Direct codebase read: `ContentView.swift`, `LoginView.swift`, `SpotifyAuthService.swift`, `CadenceService.swift`, `SettingsView.swift`, `LibraryScanService.swift`, `project.yml`, `Info.plist`
- Prior v1.2 research: `.planning/research/ARCHITECTURE.md`, `PITFALLS.md`, `STACK.md`, `SUMMARY.md`

### Secondary (MEDIUM confidence)
- [Rivera Labs: Building a Better Onboarding Flow in SwiftUI for iOS 18+](https://www.riveralabs.com/blog/swiftui-onboarding/) -- ScrollPosition + forward-only patterns
- [App Onboarding Best Practices for iOS Developers 2025](https://ravi6997.medium.com/app-onboarding-best-practices-for-ios-developers-f65e29327a58) -- Completion rate impact of screen count
- [UserOnboard: Permission Priming Pattern](https://www.useronboard.com/onboarding-ux-patterns/permission-priming/) -- Pre-prompt UX pattern
- [Cocoacasts: Managing Permissions With HealthKit](https://cocoacasts.com/managing-permissions-with-healthkit) -- HealthKit authorization patterns
- [App Store Review Guidelines 5.1.1](https://developer.apple.com/app-store/review/guidelines/) -- Permission request requirements

### Tertiary (LOW confidence)
- Permission denial rate reduction claims from pre-prompts -- industry-cited but not independently verified; directionally consistent across sources

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- all first-party Apple APIs; project already targets iOS 17+; HealthKit Optional link is well-documented
- Architecture: HIGH -- based on direct codebase read; `ContentView` gate pattern proven; service APIs already exist
- Pitfalls: HIGH -- 5 specific pitfalls identified from codebase inspection, Apple docs, and prior research; all have prevention strategies

**Research date:** 2026-03-24
**Valid until:** 2026-04-24 (stable -- first-party Apple APIs with no expected changes)
