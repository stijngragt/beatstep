# Project Research Summary

**Project:** BeatStep v1.2 — The Right Flow
**Domain:** Native iOS running/music sync app (Swift 6 / SwiftUI)
**Researched:** 2026-03-24
**Confidence:** HIGH

## Executive Summary

BeatStep v1.2 is a focused UI-layer milestone on an already-working iOS fitness app. The app's core services — cadence detection (CoreMotion), Spotify playback (SpotifyiOS SDK + Web API), BPM matching (RunEngineService), and BPM caching (SwiftData) — are all stable and require zero changes. All 8 features in this milestone are SwiftUI view work that maps onto the existing service layer: new UI components, state gates in ContentView, and model enum additions. The recommended approach is incremental, dependency-ordered UI construction using exclusively first-party Apple APIs with no new external dependencies.

The key architectural decision is that zone-based running (Z1–Z5 + Free) is a thin UI wrapper: `RunZone` maps to the existing `RunMode` + `targetBPM` parameters at the call site in `RunView`. `RunEngineService` never changes. Similarly, onboarding is pure UI sequencing — it calls existing `authService.initiateAuth()` and `cadenceService.requestPermission()` methods that already work. The playlist analyzed state surfaces existing `ScannedPlaylist.tracksWithBPM` and `totalTracks` fields already persisted in SwiftData. Every feature has a natural seam into the codebase without requiring service rewrites.

The top risk is sequencing errors: specifically (1) placing the onboarding gate inside the TabView branch instead of at the ContentView root, causing a tab bar flash on first launch and firing `LibraryScanService.scanEnabledPlaylists()` before permissions are granted, and (2) deleting `PacePreset` without migrating its UserDefaults keys, silently resetting users' guided-mode BPM preferences to defaults on upgrade. Both are well-understood and easily avoided if addressed at the correct build phase.

---

## Key Findings

### Recommended Stack

BeatStep v1.2 requires zero new external dependencies. The full stack is first-party Apple APIs on iOS 17+, consistent with the existing project target. The only meaningful additions are HealthKit (permission request only — app never reads Health data) linked as Optional to avoid iPad crashes, and `ScrollPosition` + `.containerRelativeFrame` for the onboarding horizontal scroll flow.

**Core technologies:**
- `SwiftUI .overlay` + `@AppStorage` — onboarding gate and state persistence; avoids modifying NavigationStack/TabView structure
- `SwiftUI ScrollView (horizontal)` + `ScrollPosition` (iOS 17) — multi-step onboarding with programmatic forward-only progression; cleaner than TabView's free-swipe which cannot enforce forward-only navigation
- `HealthKit (HKHealthStore)` — permission pre-prompt in onboarding only; never reads Health data; requires `NSHealthShareUsageDescription` in Info.plist and Optional framework link for iPad compatibility
- `enum RunZone` (new model) — replaces `PacePreset`; zone BPM defaults stored per-key in UserDefaults via `@AppStorage`; `effectiveBPM` computed property reads override then falls back to default
- `safeAreaInset(edge: .bottom)` — full-width Run CTA; pattern already proven in ContentView for MiniPlayer; stacks correctly with MiniPlayer
- `SwiftUI.Picker` with `.segmented` — BPM tolerance redesign; no model changes required, label text only

### Expected Features

All 8 features are P1 for this milestone. Research confirms none require deep architectural change and all map cleanly onto existing service APIs.

**Must have (table stakes):**
- Value-framed permission screens — iOS users reflexively deny blind permission dialogs; Strava, Nike Run Club, Headspace all use pre-prompts; denial rates drop significantly with benefit framing before the system dialog fires
- Re-triggerable permissions from Settings — recovery path for users who denied on first launch; without it, they reach a dead end with no obvious fix
- Visible playlist analyzed/unanalyzed state — users cannot make informed playlist choices without knowing which playlists have BPM data; current state is invisible; `ScannedPlaylist.tracksWithBPM` already exists in the model
- Prominent full-width Run CTA — the primary action is starting a run; Nike Run Club, Runna, and Strava all use a full-width primary button for their core action
- Zone vocabulary (Z1–Z5 + Free) — users know this from Garmin, Apple Watch, Strava; generic effort labels feel toy-like and signal the app doesn't understand running

**Should have (competitive differentiators):**
- Inline analyze action on playlist row — competitors require navigating into a detail screen; an inline swipe action eliminates the context switch
- Zone BPM defaults with user-configurable overrides — runners with lactate test data or Garmin zone calibrations need to override defaults; turns zone selection from a rough guide into a personalized training tool
- BPM tolerance as segmented control showing ±delta — ±3/±7/±12 communicates exactly what the user gets; more understandable than named labels or a percentage

**Defer (v2+):**
- Zone auto-detection from Apple Health HR data — requires real-time HealthKit during runs and dynamic BPM target adjustment mid-run; substantial new system touching RunEngineService; out of scope for v1.2
- Per-zone playlist pairing and workout summary with zones run
- Auto-analyze all playlists on first launch (anti-feature — hits GetSongBPM API rate limits, terrible first-launch UX)

### Architecture Approach

v1.2 integration is entirely additive to a clean existing layered architecture: App Entry → Tab Views → Services → Data. All new work lives in the view layer or adds new model enums. The existing services form stable integration boundaries that do not change. `ContentView` gains a computed `appState: AppState` enum (onboarding / login / authenticated) as the single routing decision point. `RunEngineService` is completely untouched — zones map to its existing `runMode` + `targetBPM` parameters at the `RunView` call site only.

**New or modified components:**
1. `ContentView` — add computed `appState: AppState` enum routing to `OnboardingFlow` when `!hasCompletedOnboarding`
2. `OnboardingFlow` + 3 step views — new view hierarchy; TabView(.page) container; writes `onboardingCompleted` to UserDefaults on completion
3. `RunZone` enum — new model replacing `PacePreset`; `effectiveBPM` reads UserDefaults override or default BPM
4. `ZonePicker` — new component replacing `ModePicker` + `PacePresetPicker`; zone chip scroll UI
5. `RunView` + `RunTabView` — zone integration; `selectedZone: RunZone` replaces `runMode + selectedPreset + customBPM`; full-width CTA in RunTabView
6. `PlaylistListView` + `PlaylistRow` — `PlaylistCoverage` typed value (3 explicit states) replaces optional string; inline analyze closure propagated to parent
7. `SettingsView` — zone BPM defaults section; "Revisit Permissions" action

**Stable and unchanged (service boundaries):**
`RunEngineService`, `CadenceService`, `SpotifyAuthService`, `LibraryScanService`, `BPMCacheService`, `ScannedPlaylist`, `BPMTolerance`, `SwiftData schema` (no new non-optional fields)

### Critical Pitfalls

1. **Onboarding gate at wrong view hierarchy level** — Adding `hasCompletedOnboarding` inside the TabView branch causes a tab bar flash on first launch and fires `LibraryScanService.scanEnabledPlaylists()` before permissions are granted. Avoid: gate at the same level as `isAuthenticated` in `ContentView.body` using the computed `appState` enum. TabView must never render before onboarding completes.

2. **PacePreset UserDefaults migration missing** — Deleting `PacePreset` without migrating its raw string keys (`"easyJog"`, `"steady"`, etc.) silently defaults all returning users to the wrong BPM on upgrade. Avoid: write a migration in `BeatStepApp.init()` that reads stale keys and writes their `RunZone` equivalents before removing the enum. Keep `PacePreset` as a `fileprivate` migration-only type until migration runs.

3. **Zone BPM `effectiveBPM` not wired — Settings overrides silently ignored** — If `RunZone.defaultBPM` is used directly at the run-start call site instead of `RunZone.effectiveBPM`, Settings overrides have no effect. Avoid: design `effectiveBPM` as the single BPM resolution point from the start; never call `defaultBPM` outside of `effectiveBPM` itself.

4. **HealthKit read permission state is undetectable** — `HKHealthStore.authorizationStatus(for:)` returns `.notDetermined` for denied read access by design (iOS privacy protection). Code branching on `.denied` for read types never fires. Avoid: store "did we request" in `@AppStorage` not "was it granted." Re-triggerable onboarding links to iOS Settings rather than calling `requestAuthorization` again.

5. **Inline Analyze button gesture conflict with row navigation** — In a SwiftUI `List`, a `Button` with default `.automatic` style extends its tap area to fill the entire row, intercepting the `NavigationLink`. Avoid: apply `.buttonStyle(.plain)` to the Analyze button. Must verify on physical device — this conflict behaves differently in Simulator.

---

## Implications for Roadmap

Based on the dependency graph in ARCHITECTURE.md, cross-feature dependencies, and pitfall sequencing requirements, three phases are recommended.

### Phase 1: Foundation — Models, Quick Wins, Library UX

**Rationale:** `RunZone` model must exist before any run UI can be built; it is the unblocking dependency for Phase 2. `TolerancePicker` label change is zero-risk and validates the tolerance approach early. Playlist analyzed state and inline analyze are fully independent of the zone work and can proceed in parallel within this phase. Writing the `PacePreset` migration code here, alongside `RunZone` creation, ensures the migration exists before the old enum is deleted.

**Delivers:** `RunZone` model with `effectiveBPM` UserDefaults resolution; `PacePreset` migration code; `BPMTolerance` segmented picker label update (±3/±7/±12); `PlaylistCoverage` typed 3-state value; playlist analyzed state indicator on all Library rows; inline swipe analyze action; zone BPM defaults section in `SettingsView`.

**Features:** Visible playlist analyzed/unanalyzed state, inline analyze action, BPM tolerance segmented control, zone BPM overrides in Settings.

**Pitfalls to address:** PacePreset migration (must run before enum deletion in Phase 2), SwiftData schema approach (add only optional fields — no `VersionedSchema` needed), inline Analyze button gesture conflict.

**Research flag:** Standard patterns — no research phase needed. All work is well-documented iOS patterns with clear codebase integration points fully specified in ARCHITECTURE.md.

---

### Phase 2: Core Run Experience — Zone Picker, RunView, Run Tab CTA

**Rationale:** Requires `RunZone` from Phase 1. This phase completes the user-visible running experience changes: replaces `ModePicker` + `PacePresetPicker` with `ZonePicker`, integrates zone selection into `RunView`, and adds the full-width CTA to `RunTabView`. Deletes `PacePreset` (after migration from Phase 1 is confirmed working).

**Delivers:** `ZonePicker` component; `RunView` updated with `selectedZone: RunZone` replacing `runMode + selectedPreset + customBPM`; `ModePicker` and `PacePresetPicker` removed; `PacePreset` deleted; `RunTabView` with `ZonePicker` + full-width Start Run CTA + async track load; zone→engine mapping at `RunView.controlsSection` call site only.

**Features:** Zone-based running (Z1–Z5 + Free), prominent full-width Run CTA, zone vocabulary that users recognize.

**Pitfalls to avoid:** Zone BPM resolution must use `effectiveBPM` not `defaultBPM` at call site (Pitfall 3). `RunEngineService` must not be modified. Zone mapping lives only at `RunView.controlsSection`.

**Research flag:** Standard patterns — zone-as-thin-wrapper is fully designed in ARCHITECTURE.md. `safeAreaInset` CTA pattern is already proven in the codebase. No research phase needed.

---

### Phase 3: Onboarding — First-Launch Flow + Re-Triggerable Permissions

**Rationale:** Onboarding is a UI sequencing wrapper over already-working services (`authService.initiateAuth()`, `cadenceService.requestPermission()`). Building it last means all features behind the gate are tested and functional before the gate is built. Requires clean-install simulator testing that is simpler to run as a final integration step. The re-trigger path in Settings requires the onboarding flow to be complete first.

**Delivers:** `AppState` computed enum in `ContentView`; `OnboardingFlow` + `OnboardingValueView` + `OnboardingSpotifyView` + `OnboardingHealthView` view hierarchy; `hasCompletedOnboarding` `@AppStorage` flag; HealthKit Optional framework link + `NSHealthShareUsageDescription` in Info.plist; "Revisit Permissions" action in `SettingsView`; re-trigger path deep-linking to iOS Settings; `LibraryScanService.scanEnabledPlaylists()` gated behind onboarding completion.

**Features:** Value-framed permission screens (Spotify + Apple Health), re-triggerable permissions from Settings.

**Pitfalls to address:** Onboarding gate at ContentView root not TabView branch (Pitfall 1), HealthKit "did we request" model not "was it granted" (Pitfall 4), re-trigger path is read/link-to-Settings only not re-requestAuthorization (Pitfall 7), LibraryScanService background scan gated behind onboarding flag.

**Research flag:** Requires careful testing on clean-install simulator and physical device for permission flows. The patterns are well-documented but the integration has multiple gotchas. Consider a brief research-phase check on Spotify Premium detection timing during onboarding (flagged in PITFALLS.md) before building `OnboardingSpotifyView`.

---

### Phase Ordering Rationale

- **Models before UI:** `RunZone` must exist before `ZonePicker` or `RunView` can be updated; creating it first unblocks all run UI work in Phase 2
- **Migration before deletion:** `PacePreset` migration code is written and tested in Phase 1 alongside `RunZone` creation; `PacePreset` is deleted in Phase 2 once migration is confirmed
- **Parallel workstreams in Phase 1:** Playlist state work is independent of zone model work and can be developed simultaneously by the same engineer in any order
- **Onboarding last:** Consistent with ARCHITECTURE.md recommendation — testing requires clean-install simulator; simpler to validate as the final integration step after all features behind the gate are already working

### Research Flags

Phases needing deeper research during planning:
- **Phase 3 (Onboarding):** Consider `/gsd:research-phase` specifically for: (1) Spotify Premium detection timing during onboarding — whether to surface it there or leave to playback is an unresolved product decision, and (2) exact code placement for gating `LibraryScanService.scanEnabledPlaylists()` behind the onboarding completion flag without restructuring ContentView's authenticated branch.

Phases with standard patterns (skip research-phase):
- **Phase 1:** All patterns are well-documented Apple APIs; codebase integration points are fully mapped in ARCHITECTURE.md; `PlaylistCoverage` type design is fully specified
- **Phase 2:** Zone-as-thin-wrapper is explicitly designed in ARCHITECTURE.md; no API questions remain; `safeAreaInset` CTA pattern already in the codebase

---

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | All first-party Apple APIs; iOS 17+ target already established; no version conflicts; HealthKit Optional link pattern is documented; zero new external dependencies |
| Features | MEDIUM-HIGH | Feature list is clear and well-scoped; zone BPM defaults use research-derived cadence values (MEDIUM — individual variation is ±15 SPM; user-configurable overrides mitigate this) |
| Architecture | HIGH | Based on direct codebase read of all Swift source files; component boundaries clearly identified; integration points fully specified; no external verification needed |
| Pitfalls | HIGH | 7 specific actionable pitfalls with phase assignments; recovery strategies for each; derived from both codebase inspection and Apple Developer documentation |

**Overall confidence:** HIGH

### Gaps to Address

- **Zone BPM default values diverge between research files:** STACK.md recommends (Z1: 150, Z2: 160, Z3: 170, Z4: 180, Z5: 190); FEATURES.md recommends (Z1: 155, Z2: 165, Z3: 174, Z4: 178, Z5: 185). Since all values are user-configurable, either set works as starting defaults. Pick one set during Phase 1 implementation and document the decision; this does not block any work.

- **Spotify Premium detection timing:** PITFALLS.md flags that onboarding grants Spotify auth but Premium check only happens on first playback attempt. Whether to surface this proactively during onboarding or leave it to the existing playback error path is an unresolved product decision. Address before building `OnboardingSpotifyView` in Phase 3.

- **LibraryScanService gate placement:** The `.task` in `ContentView.authenticatedView` fires the background scan on every authenticated launch. How to gate this behind `hasCompletedOnboarding` without restructuring the authenticated branch needs a brief design pass at the start of Phase 3. The condition is clear; the exact code location is not specified in the research.

---

## Sources

### Primary (HIGH confidence)

- Apple Developer Documentation: Authorizing access to health data — HealthKit permission flow and authorizationStatus limitations for read types
- Apple Developer Documentation: NSHealthShareUsageDescription — Info.plist key requirement
- Apple Developer Documentation: Configuring HealthKit access — Optional framework linking to prevent iPad crash
- Apple Developer Documentation: SegmentedPickerStyle — native segmented control API
- Apple Developer Documentation: CMPedometer — authorization check before starting updates
- Apple HIG: Onboarding — permission priming best practices
- Direct codebase read: all Swift source files under `/BeatStep/` — architecture integration research on the live codebase

### Secondary (MEDIUM confidence)

- Rivera Labs: Building a Better Onboarding Flow in SwiftUI for iOS 18+ — ScrollPosition + overlay patterns
- magnuskahr: Better placements of bottom buttons in SwiftUI — safeAreaInset for bottom CTA
- Running Writings / TrainingPeaks: Science of cadence and finding your perfect run cadence — zone BPM default value ranges
- Donny Wals: A Deep Dive into SwiftData migrations — migration strategy for enum replacement
- Nil Coalescing: Multiple buttons in SwiftUI List rows — gesture conflict and `.buttonStyle(.plain)` resolution
- UserOnboard: Permission Priming Pattern — pre-prompt UX pattern with denial rate context
- App Onboarding Best Practices for iOS Developers 2025 — completion rate impact of extra onboarding screens

### Tertiary (LOW confidence)

- Permission denial rate reduction claims — industry-cited but hard to verify independently; directionally consistent across multiple sources

---
*Research completed: 2026-03-24*
*Ready for roadmap: yes*
