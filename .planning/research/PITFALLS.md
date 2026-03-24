# Pitfalls Research

**Domain:** Onboarding flow, playlist analysis state UX, zone-based running — adding to existing SwiftUI iOS running music app
**Researched:** 2026-03-24
**Confidence:** HIGH

---

## Critical Pitfalls

### Pitfall 1: Onboarding Gate at Wrong View Hierarchy Level

**What goes wrong:**
The onboarding gate is added inside a tab or NavigationStack instead of at the `ContentView` root. Result: the tab bar flashes momentarily on first launch before the onboarding sheet covers it, or the onboarding dismisses to a half-initialised Run tab instead of a clean authenticated shell.

**Why it happens:**
ContentView already branches on `authService.isAuthenticated`. The natural instinct is to add a `hasCompletedOnboarding` check inside the authenticated branch's first tab, but that means the TabView and all its environment setup have already fired before onboarding appears.

**How to avoid:**
Add the onboarding gate at the same level as the `isAuthenticated` check in `ContentView.body`. The decision tree becomes:
1. Not authenticated → `LoginView`
2. Authenticated AND not onboarded → `OnboardingFlow` (fullScreenCover or direct view swap)
3. Authenticated AND onboarded → `TabView`

This prevents the TabView from ever rendering before onboarding completes. Store the completion flag in `@AppStorage` so it survives app termination.

**Warning signs:**
- Tab bar briefly visible before onboarding appears
- `LibraryScanService.scanEnabledPlaylists()` fires (via `.task` in `ContentView.authenticatedView`) before onboarding permissions are granted
- MiniPlayer safeAreaInset rendered during onboarding

**Phase to address:**
Onboarding flow phase — establish gate position before building any onboarding screens.

---

### Pitfall 2: PacePreset Enum Raw Values Become Invalid UserDefaults Keys After Replacement

**What goes wrong:**
`PacePreset` uses `RawRepresentable` string raw values (`"easyJog"`, `"steady"`, `"tempo"`, etc.) persisted to UserDefaults. When zone-based running replaces the effort-label system with a new enum (e.g. `RunZone`), any user who had a saved `PacePreset` preference will decode a stale raw value string. The `init?(rawValue:)` initializer returns `nil`, silently defaulting to `.free` mode, discarding the user's previous guided-mode preference.

**Why it happens:**
Both `RunMode` and `BPMTolerance` use `UserDefaults.standard` with raw string keys. If `PacePreset` is removed and replaced by a `RunZone` type with different case names, the key `"selectedPacePreset"` — or wherever it is written — holds a value the new enum cannot decode. The code gracefully falls back, but the user's setting is silently lost.

**How to avoid:**
Before removing `PacePreset`, audit every `UserDefaults.standard.set` and `UserDefaults.standard.string(forKey:)` call in `PacePresetPicker.swift` and `RunEngineService`. Map old preset cases to their closest zone equivalent and write a migration that reads the stale key and writes the new key before the old key is removed. Keep the old enum as a `fileprivate` migration-only type until the migration runs.

**Warning signs:**
- Guided mode defaults to wrong BPM on first launch after update
- `RunMode.savedTargetBPM` returns the fallback `160` for users who had set a different target

**Phase to address:**
Zone-based running phase — migration must run before `PacePreset` is deleted.

---

### Pitfall 3: SwiftData Schema Change Without VersionedSchema Crashes on Existing Install

**What goes wrong:**
If playlist analysis state tracking requires adding a new field to `ScannedPlaylist` (e.g. `analysisStatus: AnalysisStatus`, `lastAnalyzed: Date?`, or a new relationship), deploying without a `VersionedSchema` and `SchemaMigrationPlan` causes a crash on launch for users upgrading from v1.1. SwiftData's unversioned lightweight migration is unreliable for field additions with non-optional types.

**Why it happens:**
`BeatStepApp.init()` constructs the `ModelContainer` with a force-try (`try!`). Any schema mismatch that SwiftData cannot silently reconcile throws at that point, killing the app before the window renders. The existing schema was never wrapped in a `VersionedSchema`, making migration paths harder to express.

**How to avoid:**
- Add only optional fields (`Date?`, `String?`) or fields with default values to `ScannedPlaylist` — SwiftData handles these without a migration plan.
- If a non-optional field or enum type must be added, wrap the current schema in `SchemaV1`, define `SchemaV2` with the new field, and write a `MigrationStage.lightweight` plan. Release an intermediate build first if the install base is significant.
- Change the `try!` in `BeatStepApp.init()` to a `do/catch` that deletes and recreates the store on failure as a last-resort recovery.

**Warning signs:**
- App crash on launch in TestFlight after schema change, but works clean install
- Xcode console shows "NSMigrationError" or SwiftData predicate mismatch errors

**Phase to address:**
Playlist analysis state phase — schema changes must be evaluated before any new `@Model` fields are committed.

---

### Pitfall 4: HealthKit Cannot Confirm Denied Read Permission — Onboarding Shows Wrong State

**What goes wrong:**
The re-triggerable onboarding (from Settings) shows a "Grant Permission" button for Apple Health, but the user already granted it. Or worse: the user denied it, and the app cannot detect this, so the onboarding shows "permission granted" when Health data is unavailable.

**Why it happens:**
HealthKit intentionally does not expose whether read authorization was denied — `HKHealthStore.authorizationStatus(for:)` returns `.notDetermined` for denied read types, to protect user privacy. This is documented behavior, not a bug, but it is widely misunderstood. Apps cannot distinguish "user never asked" from "user denied read."

**How to avoid:**
- Store the fact that the app has *requested* Health permission in `@AppStorage`, not the permission result.
- In onboarding, show: "We'll ask for access" (pre-request) or "Permission requested" (post-request). Never show "Permission granted/denied" for Health read access.
- In the re-triggerable onboarding, link directly to `UIApplication.openSettingsURLString` so the user can correct denied permissions themselves. Do not try to detect or display the current state.
- Keep Apple Health as an optional enhancement — the app's core cadence detection via `CMPedometer` does not require HealthKit.

**Warning signs:**
- Settings onboarding screen shows contradictory permission state
- Code calling `HKHealthStore.authorizationStatus(for:)` and branching on `.denied` — that branch never fires for read types

**Phase to address:**
Onboarding flow phase — permission model must be designed around this limitation from the start.

---

### Pitfall 5: Inline Analyze Button in List Row Conflicts With Row Navigation Tap

**What goes wrong:**
Adding an "Analyze" button inline with a playlist row in `PlaylistListView` causes the entire row tap to trigger the analyze action (or both actions simultaneously) instead of navigating to the playlist detail. SwiftUI's `List` extends button tap areas to fill the entire row by default.

**Why it happens:**
When a `Button` uses the default `.automatic` style inside a `List` row, SwiftUI treats the row as the button's tap target. If the row also has a `NavigationLink` or an `.onTapGesture`, there is a gesture priority conflict where the list row intercepts the tap before the individual button sees it — or both fire.

**How to avoid:**
- Apply `.buttonStyle(.plain)` or `.buttonStyle(.borderless)` explicitly to the Analyze button. This removes SwiftUI's row-wide tap area extension.
- Use `.contentShape(Rectangle())` on the button's label if the tap area needs to be explicitly sized.
- Wrap the row navigation in `NavigationLink(value:)` (programmatic) rather than `NavigationLink(destination:)` so gesture ownership is cleaner.
- Test on device, not just Simulator — list row gesture conflicts can behave differently in the two environments.

**Warning signs:**
- Tapping anywhere on the row triggers analyze instead of navigation
- Both navigation and analyze fire on a single tap
- Works in Simulator but fails on device (or vice versa)

**Phase to address:**
Playlist analysis state phase — button placement and gesture architecture must be resolved before building the inline UI.

---

### Pitfall 6: Zone BPM Defaults Baked Into the Enum Instead of User-Configurable Storage

**What goes wrong:**
Zone BPM defaults are hardcoded as `switch` cases in the `RunZone` (or replacement) enum. When the requirement says "user-configurable overrides in Settings," the implementation stores overrides in UserDefaults but reads them in the wrong place — the enum computes a value, the Settings screen writes a UserDefaults key, but the run engine reads the enum value directly without checking UserDefaults. Customisation silently has no effect.

**Why it happens:**
The existing `PacePreset.bpm` computed property pattern is a static lookup on the enum. Copying that pattern for zones and then bolting on UserDefaults later creates a dual source of truth. The enum default is read by one code path; the UserDefaults override is read (or not read) by another.

**How to avoid:**
Design the zone BPM resolution as a single function from the start: `RunZone.effectiveBPM(for zone: RunZone) -> Int` that checks UserDefaults for an override, falls back to the hardcoded default. `RunEngineService.targetBPM` must call this function — never the raw enum property. Keep the default values in a static constant, not as part of the enum's `rawValue`, so they can be overridden without touching the persisted identity of the zone.

**Warning signs:**
- Settings screen saves zone BPM changes but runs still use wrong BPM
- Zone BPM override key in UserDefaults exists but `effectiveBPM` in `RunEngineService` returns the hardcoded value

**Phase to address:**
Zone-based running phase — architecture for BPM resolution must be settled before the Settings override UI is built.

---

### Pitfall 7: Onboarding Re-Trigger From Settings Presents Over Active Tab State

**What goes wrong:**
Tapping "Redo Onboarding" in Settings presents the onboarding flow via `.fullScreenCover`. When the user dismisses it, they are returned to the Settings tab — but if the onboarding requested permissions mid-flow, there is a window where the underlying LibraryScanService or RunEngineService is also running (the app was already authenticated). Partial state from the onboarding (e.g. a new permission grant changing what CMPedometer can do) is not reflected until the next app launch.

**Why it happens:**
Full-screen covers are purely presentational — they don't pause the underlying app. Services continue running. If onboarding grants a HealthKit permission that unlocks step-counting features, the already-initialised `CadenceService` doesn't know to re-check until someone triggers it.

**How to avoid:**
- After re-triggerable onboarding dismisses, post a `NotificationCenter` notification or toggle an `@AppStorage` flag that causes the appropriate services to re-check their permission states.
- Keep the re-triggerable onboarding read-only for already-granted permissions — it should only offer the Settings deep-link for denied states, not re-request authorization. This eliminates the re-grant scenario entirely.
- The primary value of re-triggerable onboarding is explaining what each permission does and linking to Settings — not calling `requestAuthorization` again.

**Warning signs:**
- Permission granted during re-trigger flow has no effect until app restart
- CMPedometer authorization status changes not observed by CadenceService

**Phase to address:**
Onboarding flow phase (re-trigger path) — design the re-trigger as a read/link flow, not a re-request flow.

---

## Technical Debt Patterns

Shortcuts that seem reasonable but create long-term problems.

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Keep `PacePreset` alongside new `RunZone` temporarily | Avoids migration complexity | Two parallel zone systems, both partially active; `RunEngineService` logic forks | Never — clean cut required, migration code is safer |
| Store onboarding completion as a single Bool (`hasSeenOnboarding`) | Simple to implement | Cannot distinguish "saw onboarding but skipped Health permission" vs "fully completed"; re-trigger flow breaks | MVP only if phase count is simple |
| Infer analysis state from `ScannedPlaylist.tracksWithBPM > 0` instead of explicit enum | No schema change needed | Cannot distinguish "never analyzed" from "analyzed, zero results" — empty playlist shows wrong UI state | Never — add the explicit status field |
| Hard-code zone BPM defaults in the `RunZone` enum rawValue | Zero UserDefaults reads per BPM lookup | Cannot override without changing code; Settings override screen cannot be wired without refactor | Acceptable only for initial scaffolding, must be replaced before Settings UI is built |

---

## Integration Gotchas

Common mistakes when connecting to external services or system APIs.

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| HealthKit read permission | Checking `authorizationStatus` to decide whether to show a permission UI | Store "did we request" in `@AppStorage`; never rely on read authorization status |
| CMPedometer authorization | Not calling `CMPedometer.authorizationStatus()` before starting updates, assuming Motion access is always available | Check `authorizationStatus()` on startup; gate CadenceService start on `.authorized` |
| Spotify PKCE auth | Conflating "user has Spotify" with "user has Spotify Premium" — onboarding grants Spotify auth but Premium check only happens on first playback attempt | Add a post-auth Premium check early in onboarding so the user learns about the requirement before they pick a playlist and hit a run |
| `LibraryScanService.scanEnabledPlaylists()` (fires in `.task` on `ContentView`) | Scan fires before user has seen Library and enabled any playlists, generating no-op API calls on first launch | Gate the background scan behind the onboarding completion flag so it only starts once the user has had a chance to enable playlists |

---

## Performance Traps

Patterns that work at small scale but fail as usage grows.

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| Computing playlist analysis coverage by fetching all `CachedBPM` rows on every list render | Library tab lags when scrolling through 20+ playlists | Cache the coverage ratio in `ScannedPlaylist.tracksWithBPM` (already exists) and update it after each scan — never recalculate in a list `ForEach` | At 10+ playlists with 50+ tracks each |
| Triggering a full BPM scan inline from the Library list row's Analyze button without debounce | Multiple rapid taps queue duplicate scan tasks; API rate limits hit | Add an `isAnalyzing: Bool` flag per playlist in `ScannedPlaylist` (or in the view model); disable the button while the scan is in-flight | Immediately — no scale threshold |
| Storing per-zone BPM overrides as individual UserDefaults keys per zone | Fine for 6 zones | If zones are renamed or re-ordered, stale keys accumulate and the wrong defaults are read | After any zone model change |

---

## UX Pitfalls

Common user experience mistakes for these specific features.

| Pitfall | User Impact | Better Approach |
|---------|-------------|-----------------|
| Onboarding permission screens without value framing ("Allow Motion Access" with no context) | Users decline permissions they would grant if they understood why | Frame each permission screen around the benefit: "BeatStep detects your running cadence using your phone's motion sensor — this is what syncs your music to your stride." Show the value before the system dialog fires |
| Zone picker shows zone names (Z1–Z5) without BPM range context | Users don't know which zone matches their pace intent | Show zone name + BPM range inline: "Z3 — 155–165 BPM" |
| BPM tolerance segmented control shows labels ("Tight", "Normal", "Loose") without ±BPM deltas | Users cannot make an informed choice | Requirement already calls for ±BPM deltas — implement as primary label, not secondary caption |
| "Analyze" button triggers immediately on tap without feedback | User taps, nothing appears to happen, taps again — double scan | Show immediate inline progress state (spinner or progress fraction) on first tap; disable button during scan |
| Re-triggerable onboarding accessible only by scrolling to the bottom of Settings | Users who need to re-grant permissions cannot find it | Put "Permissions" as a named Settings section, not buried in "About" or "Advanced" |

---

## "Looks Done But Isn't" Checklist

Things that appear complete but are missing critical pieces.

- [ ] **Onboarding gate:** Verify `LibraryScanService.scanEnabledPlaylists()` does NOT fire on first launch before onboarding completes — check the `.task` in `ContentView.authenticatedView`
- [ ] **Zone replacement:** Verify `RunEngineService.effectiveBPM` reads from the new zone resolution function, not from a stale `PacePreset` reference or hardcoded fallback
- [ ] **Analysis state UI:** Verify "unanalyzed" state is distinct from "analyzed with zero BPM results" — both must have different copy and actions
- [ ] **Re-triggerable onboarding:** Verify the Settings trigger path shows accurate current permission states — test with Motion denied, Health denied, both granted, neither granted
- [ ] **Inline analyze button:** Verify tapping the row still navigates while tapping the Analyze button only triggers analysis — test on physical device, not Simulator
- [ ] **BPM tolerance segmented control:** Verify the `BPMTolerance.saved` value is read on every `RunTabView` appearance, not just on first init — if the user changes tolerance in Settings and returns to Run tab, the control must reflect the change
- [ ] **Zone BPM overrides:** Verify changing a zone's BPM in Settings immediately affects a run started after the change, without requiring an app restart

---

## Recovery Strategies

When pitfalls occur despite prevention, how to recover.

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| Onboarding gate at wrong level, tab bar visible on first launch | LOW | Move gate to `ContentView` root branch; no data migration needed |
| `PacePreset` raw values broken by zone rename, users lose saved preference | LOW | Write migration in `BeatStepApp.init()` before `ModelContainer` setup; map stale string to default zone |
| SwiftData `ScannedPlaylist` schema crash on upgrade | MEDIUM | Add try/catch around `ModelContainer` creation; on failure, delete store and recreate; users lose scan history but app launches |
| HealthKit permission state shown incorrectly in re-trigger flow | LOW | Replace status display with link-to-settings pattern; remove permission detection code |
| Inline Analyze button fires row navigation | LOW | Add `.buttonStyle(.plain)` to the Analyze button; 1-line fix |

---

## Pitfall-to-Phase Mapping

How roadmap phases should address these pitfalls.

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| Onboarding gate at wrong view level | Onboarding flow (Phase 1) | First launch on clean install: tab bar must never be visible before onboarding completes |
| PacePreset raw value migration | Zone-based running (before enum deletion) | Upgrade install from v1.1 build preserves last-used BPM preference |
| SwiftData schema crash on upgrade | Playlist analysis state (before adding fields) | TestFlight upgrade from v1.1 — app launches without crash; existing scan data intact |
| HealthKit cannot detect denied read | Onboarding flow (permission screen design) | Test with Health denied in device Settings — onboarding shows correct "Open Settings" CTA, not wrong state |
| Inline Analyze button gesture conflict | Playlist analysis state | Physical device test: row tap navigates, button tap only triggers analyze |
| Zone BPM override ignored by run engine | Zone-based running (settings integration) | Change zone BPM in Settings, start run — effectiveBPM matches the overridden value |
| Re-trigger onboarding causes service state drift | Onboarding flow (re-trigger path design) | Grant Motion permission via re-trigger — CadenceService reflects new state without restart |

---

## Sources

- Apple Developer Documentation: [Authorizing access to health data](https://developer.apple.com/documentation/healthkit/authorizing-access-to-health-data)
- Apple Developer Documentation: [CMPedometer](https://developer.apple.com/documentation/coremotion/cmpedometer)
- Apple Developer Documentation: [fullScreenCover](https://developer.apple.com/documentation/swiftui/view/fullscreencover(ispresented:ondismiss:content:))
- Apple Developer Documentation: [Restoring your app's state with SwiftUI](https://developer.apple.com/documentation/swiftui/restoring-your-app-s-state-with-swiftui)
- Apple HIG: [Onboarding](https://developer.apple.com/design/human-interface-guidelines/onboarding)
- Donny Wals: [A Deep Dive into SwiftData migrations](https://www.donnywals.com/a-deep-dive-into-swiftdata-migrations/)
- Nil Coalescing: [Multiple buttons in SwiftUI List rows](https://nilcoalescing.com/blog/MultipleButtonsInListRows/)
- Emre Havan / Fit Records: [Building a Scalable Apple Health Authorization Management View](https://medium.com/fit-records/building-a-scalable-apple-health-authorization-management-view-for-ios-54012e34318a)
- Cocoacasts: [Managing Permissions With HealthKit](https://cocoacasts.com/managing-permissions-with-healthkit)
- Atomic Robot: [An Unauthorized Guide to SwiftData Migrations](https://atomicrobot.com/blog/an-unauthorized-guide-to-swiftdata-migrations/)
- Codebase inspection: `BeatStepApp.swift`, `ContentView.swift`, `RunEngineService.swift`, `BPMCacheService.swift`, `ScannedPlaylist.swift`, `PacePreset.swift`, `RunMode.swift`, `BPMTolerance.swift`, `RunTabView.swift`, `LoginView.swift`

---
*Pitfalls research for: BeatStep v1.2 — onboarding flow, playlist analysis state UX, zone-based running*
*Researched: 2026-03-24*
