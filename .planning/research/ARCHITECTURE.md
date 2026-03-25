# Architecture Research: v1.6 Little Big Things Integration

**Domain:** iOS running music app -- UI polish milestone
**Researched:** 2026-03-25
**Confidence:** HIGH (full codebase read, all integration points verified against source)

## Current Architecture Snapshot

```
+---------------------------------------------------------------+
|                         ContentView                            |
|  AppState.resolve() -> .onboarding | .login | .authenticated  |
+---------------------------------------------------------------+
|                                                                |
|  TabView (Library | Run | Settings)                            |
|  +-------------------+  +----------------+  +---------------+  |
|  | NavigationStack   |  | NavigationStack|  | NavigationStack| |
|  | PlaylistListView  |  | RunTabView     |  | SettingsView  |  |
|  |  -> PlaylistDetail|  |  -> ActiveRun  |  |  -> SensorLab |  |
|  +-------------------+  +----------------+  +---------------+  |
|                                                                |
|  safeAreaInset: MiniPlayerView (when !isRunActive)             |
+---------------------------------------------------------------+
|                     Services (Singletons, @Observable)         |
|  RunEngineService | SpotifyAPIService | SpotifyPlayerService   |
|  CadenceService   | BPMCacheService   | LibraryScanService     |
|  SpotifyAuthService | GetSongBPMService | BPMDiscoveryService  |
+---------------------------------------------------------------+
|                     Data Layer                                 |
|  SwiftData: CachedBPM, ScannedPlaylist                         |
|  UserDefaults: RunZone, BPMTolerance, ZeroBPMFallback, etc.   |
|  Keychain: Spotify auth tokens                                 |
+---------------------------------------------------------------+
```

**Key patterns already established:**
- Singletons with `@Observable` for reactive state (RunEngineService, LibraryScanService, etc.)
- `SelectedTabKey` EnvironmentKey for cross-tab navigation
- Design tokens in `DesignTokens.swift` (BSColors, BSFonts, BSSpacing, BSRadius, BSComponents)
- `fullScreenCover` for ActiveRunView (prevents swipe-back, hides tab bar)
- Private row structs inside list views (PlaylistRow, TrackRow)

## v1.6 Feature Integration Map

### Feature 1: Contextual Scan Actions (replaces floating scan bar)

**What changes:** The global scan progress banner in `PlaylistListView` (lines 44-54) becomes per-row contextual actions with richer feedback.

**Existing touchpoints:**
- `PlaylistListView` -- global `scanProgress` banner at top of list, `.swipeActions` on each row calling `scanService.scanPlaylistByID()`
- `LibraryScanService` -- `scanningPlaylistID: String?` tracks active scan, `scanProgress: ScanProgress?` is observable
- `PlaylistRow` -- already shows per-row scan progress when `isScanning` matches

**Integration:**
- **Modify** `PlaylistListView`: Remove global scan banner (the `if let progress` HStack at lines 44-54). Row-level scan state already works via `scanService.scanningPlaylistID == playlist.id` comparison.
- **Modify** `PlaylistRow`: Add visible scan button (not just swipe) as trailing content. Show inline progress indicator when scanning. The data hooks already exist -- `isScanning` and `scanProgress` params are already passed.
- **No service changes.** `LibraryScanService` already exposes exactly the right observable state per-playlist.

**New components:** None. View-layer reshuffling of existing scan UI.

**Risk:** LOW.

---

### Feature 2: Library Search and Filter

**What changes:** Search bar and filter chips (All / Analyzed / Unanalyzed) on `PlaylistListView`.

**Existing touchpoints:**
- `PlaylistListView` -- `@State playlists: [SpotifyPlaylist]`, `coverageMap: [String: String]`, `coverageLoaded: Bool`
- `.navigationTitle("Your Library")` on the List -- `.searchable` attaches here

**Integration:**
- **Modify** `PlaylistListView`: Add `@State private var searchText = ""` and `@State private var filter: LibraryFilter = .all`. Add `.searchable(text: $searchText)` modifier. Replace `ForEach(playlists)` with `ForEach(filteredPlaylists)`.
- **New** `LibraryFilter` enum (3 cases: `.all`, `.analyzed`, `.unanalyzed`). Filter logic uses `coverageMap` presence: key exists = analyzed, absent = unanalyzed.
- **New** `LibraryFilterBar` view: Horizontal capsule row, same visual pattern as `ZonePickerView`. Placed above the list or as a list header.

**Computed filtering:**
```swift
private var filteredPlaylists: [SpotifyPlaylist] {
    playlists
        .filter { searchText.isEmpty || $0.name.localizedCaseInsensitiveContains(searchText) }
        .filter { filter.matches(hasAnalysis: coverageMap[$0.id] != nil) }
}
```

**Risk:** LOW. `.searchable` is stable iOS 15+. Filter is client-side on loaded data.

---

### Feature 3: Run Menu Redesign with Custom Components

**What changes:** `RunTabView` (323 lines) gets decomposed into cohesive sub-components. Multi-zone selection replaces single-zone.

**Existing touchpoints:**
- `RunTabView` -- inline playlist display (cover art + name), `ZonePickerView` binding `selectedZoneId: Int?`, `TolerancePicker`, start button
- `ZonePickerView` -- single-select via `@Binding var selectedZoneId: Int?`
- `ActiveRunView` -- receives `selectedZoneId: Int?`
- `RunEngineService` -- works with single `targetBPM: Int` + `tolerance: BPMTolerance`

**Integration:**
- **New** `RunPlaylistCard` view: Extract the playlist display (cover art, name, "Your last playlist" subtitle, tap-to-library) from `RunTabView.loadedContent()` lines 158-199. Standalone reusable component.
- **Modify** `ZonePickerView`: Change binding from `Int?` to `Set<Int>`. Allow multiple capsule selections. Tapping a selected zone deselects it. Empty set = Free mode.
- **Modify** `RunTabView`: Replace `@State private var selectedZoneId: Int?` with `@State private var selectedZoneIds: Set<Int> = ...`. Compute merged BPM from selected zones. Pass resolved single BPM + expanded tolerance to engine.
- **Modify** `ActiveRunView`: Accept `selectedZoneIds: Set<Int>` instead of `Int?`. Display zone range label.

**Multi-zone resolution strategy:**
```
Selected zones: Z2 (165), Z3 (174), Z4 (178)
  -> targetBPM = midpoint = (165 + 178) / 2 = 171
  -> tolerance covers full range: (178 - 165) / 2 + base_tolerance
```
RunEngineService needs zero changes -- it already works with `targetBPM` + `tolerance`. Multi-zone is purely a view-layer concept that resolves to these two values.

**UserDefaults persistence:** Change `RunZone.selectedZoneId` (single Int?) to `RunZone.selectedZoneIds` (Set<Int>). Store as `[Int]` array in UserDefaults.

**Risk:** MEDIUM. Multi-zone changes the `ZonePickerView` API contract and touches `RunTabView`, `ActiveRunView`, and `RunZone` persistence. Needs careful testing of BPM range resolution.

---

### Feature 4: Playlist Card Redesign with Scan Quality Visibility

**What changes:** `PlaylistRow` gets richer coverage visualization.

**Existing touchpoints:**
- `PlaylistRow` (private struct in `PlaylistListView`) -- shows `coverageText: String?` as "15/20 BPM"
- `coverageMap: [String: String]` in `PlaylistListView`

**Integration:**
- **New** `CoverageInfo` struct: Replaces the string-based coverage. Contains `withBPM: Int, total: Int`, computed `ratio: Double`, computed `qualityColor: Color` (green >80%, yellow 40-80%, red <40%).
- **New** `ScanQualityBadge` view: Small visual indicator (progress ring or filled capsule) showing coverage ratio with color coding. Used in both `PlaylistRow` and potentially `RunPlaylistCard`.
- **Modify** `PlaylistListView`: Change `coverageMap: [String: String]` to `[String: CoverageInfo]`. Update `loadCoverageData()` to build richer data.
- **Modify** `PlaylistRow`: Replace text coverage with `ScanQualityBadge`. Make it an internal (not private) struct for reuse.

**Risk:** LOW. Visual redesign with slightly richer data model.

---

### Feature 5: Haptic System

**What changes:** Centralized haptic feedback definitions, applied across the app.

**No existing haptics anywhere in the codebase.**

**Integration:**
- **New** `BSHaptics` enum in `DesignSystem/BSHaptics.swift`: Static methods wrapping `UIImpactFeedbackGenerator`, `UISelectionFeedbackGenerator`, `UINotificationFeedbackGenerator`.

```swift
enum BSHaptics {
    static func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
    static func warning() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }
}
```

- **Modify** views to call BSHaptics at interaction points:
  - `ZonePickerView` capsule tap -> `BSHaptics.selection()`
  - `RunTabView.startRun()` -> `BSHaptics.impact(.heavy)`
  - `LongPressStopButton` progress milestones -> `BSHaptics.impact(.light)`
  - `LongPressStopButton` completion -> `BSHaptics.success()`
  - Scan completion -> `BSHaptics.success()`
  - Filter/search interactions -> `BSHaptics.selection()`

**Risk:** LOW. Purely additive. No architectural changes.

---

### Feature 6: Animation System

**What changes:** Standardized animation tokens and transitions.

**Existing animations (ad-hoc):**
- `RunTabView`: `.animation(.easeInOut(duration: 0.2), value: selectedZoneId)`
- `SyncBackgroundModifier`: color shift animation
- `LongPressStopButton`: progress ring animation

**Integration:**
- **New** `BSAnimation` enum in `DesignSystem/BSAnimation.swift`:
```swift
enum BSAnimation {
    static let quick: Animation = .easeInOut(duration: 0.15)
    static let standard: Animation = .easeInOut(duration: 0.25)
    static let smooth: Animation = .spring(response: 0.35, dampingFraction: 0.8)
    static let entrance: Animation = .spring(response: 0.4, dampingFraction: 0.75)
}

enum BSTransition {
    static let fadeSlide: AnyTransition = .opacity.combined(with: .move(edge: .top))
    static let scale: AnyTransition = .scale.combined(with: .opacity)
}
```
- **New** `ShimmerModifier`: Skeleton loading shimmer for playlist/track loading states.
- **Modify** existing views: Replace hardcoded `.animation(.easeInOut(duration: 0.2))` with `BSAnimation.standard`. Apply consistent transitions to state changes.

**Risk:** LOW. Additive constants.

---

### Feature 7: Settings Screen Structure

**What changes:** `SettingsView` (136 lines, flat sections) reorganized into proper grouped sections.

**Current sections:** Account, Running Zones, Playback, Permissions, Disconnect, Sensor Lab (hidden), Version footer.

**Integration:**
- **Modify** `SettingsView`: Restructure into: Account, Run Defaults (zones + playback), Permissions, Debug (Sensor Lab), About (version + credits).
- **Extract** section views for clarity: `SettingsAccountSection`, `SettingsRunDefaultsSection`, `SettingsPermissionsSection`, `SettingsDebugSection`, `SettingsAboutSection`. These can be private structs within SettingsView or in a `Views/Settings/` subfolder.
- **Fix** hardcoded "v1.4" version string (line 114) -> read from `Bundle.main.infoDictionary`.

**Risk:** LOW. View-only reorganization.

---

### Feature 8: Pre-built Skip Queue

**What changes:** RunEngineService pre-computes the next track for instant skipping.

**Existing flow:**
```
skipToNextMatch() -> queueNextMatch() -> selectNextMatch(forSPM:) -> playTrack()
```
`selectNextMatch` is already synchronous (in-memory bpmMap filtering). The only async part is `SpotifyPlayerService.play(uri:)` which fires a network call to Spotify Web API.

**Integration:**
- **Modify** `RunEngineService`: Add `@ObservationIgnored private var preQueuedTrack: SpotifyTrack?`.
- **Modify** `playTrack()`: After playing current, compute and store next match: `preQueuedTrack = selectNextMatch(forSPM: effectiveBPM)`.
- **Modify** `skipToNextMatch()`: If `preQueuedTrack` exists, play it immediately and pre-compute the next one. Otherwise fall back to current behavior.
- **New** method on `SpotifyPlayerService`: `addToQueue(uri:)` using Spotify Web API `POST /me/player/queue?uri={uri}`. This pre-loads audio on Spotify's side for gapless transition.
- **Modify** `SpotifyPlayerService`: Add the queue endpoint call. This is a fire-and-forget optimization -- if it fails, skip still works via direct `play(uri:)`.

**Spotify queue API interaction concern:** When using `play(uri:)` to start a specific track, Spotify may or may not clear its internal queue. The safest approach: always use `play(uri:)` for the current track, use `addToQueue` only as a pre-loading hint. Never rely on Spotify's queue state for track selection.

**Risk:** MEDIUM. Spotify queue API behavior with direct `play` calls needs verification. Pre-computation is safe; pre-queueing is the risky part.

---

### Feature 9: Library Analysis Status Bug Fix

**What changes:** Fix stale analysis status display in library.

**Root cause analysis from code:**
- `PlaylistListView.loadCoverageData()` fetches `ScannedPlaylist` records and builds `coverageMap`.
- It runs on `.task` (initial load) and `.refreshable` (pull-to-refresh).
- After a swipe-to-scan completes (`scanPlaylistByID`), `loadCoverageData()` is called in the `.swipeActions` Task closure.
- BUT: if the user navigates away and back, or if a background scan completes (via `scanEnabledPlaylists` in ContentView `.task`), `coverageMap` is stale.
- Missing: no observation of `LibraryScanService.scanningPlaylistID` changes. When scan finishes (`scanningPlaylistID` goes to nil), coverage should reload.

**Fix:**
- **Modify** `PlaylistListView`: Add `.onChange(of: scanService.scanningPlaylistID)` observer. When it transitions to `nil` (scan completed), call `loadCoverageData()`.

```swift
.onChange(of: scanService.scanningPlaylistID) { oldValue, newValue in
    if oldValue != nil && newValue == nil {
        loadCoverageData()
    }
}
```

**Risk:** LOW. Single observer addition.

---

## New Components Summary

| Component | File Location | Purpose |
|-----------|---------------|---------|
| `BSHaptics` | `DesignSystem/BSHaptics.swift` | Centralized haptic feedback |
| `BSAnimation` | `DesignSystem/BSAnimation.swift` | Animation/transition tokens |
| `ShimmerModifier` | `DesignSystem/ShimmerModifier.swift` | Loading skeleton effect |
| `LibraryFilter` | `Models/LibraryFilter.swift` | All/Analyzed/Unanalyzed enum |
| `CoverageInfo` | `Models/CoverageInfo.swift` | Rich coverage data struct |
| `LibraryFilterBar` | `Views/Library/LibraryFilterBar.swift` | Filter chip row |
| `ScanQualityBadge` | `Views/Library/ScanQualityBadge.swift` | Visual coverage indicator |
| `RunPlaylistCard` | `Views/Run/RunPlaylistCard.swift` | Extracted playlist card |

## Modified Components Summary

| Component | What Changes | Scope |
|-----------|-------------|-------|
| `PlaylistListView` | Search, filter, remove global banner, richer coverage data, scan completion observer | Major |
| `PlaylistRow` | Extract to internal, inline scan button, `ScanQualityBadge` | Major |
| `RunTabView` | Extract `RunPlaylistCard`, multi-zone binding, haptics | Major |
| `ZonePickerView` | Multi-select `Set<Int>` binding | Medium |
| `ActiveRunView` | Accept `Set<Int>` zone IDs | Small |
| `RunEngineService` | `preQueuedTrack` pre-computation | Medium |
| `SpotifyPlayerService` | `addToQueue(uri:)` endpoint | Small |
| `SettingsView` | Section restructuring, dynamic version | Medium |
| `RunZone` | `selectedZoneIds` persistence (Set<Int>) | Small |
| `LongPressStopButton` | Haptic calls at progress milestones | Small |
| `DesignTokens.swift` | No changes (new tokens go in separate files) | None |

## Unchanged Components

| Component | Reason |
|-----------|--------|
| `ContentView` / `AppState` | No routing changes |
| `BPMCacheService` | No schema changes |
| `CadenceService` | No cadence logic changes |
| `GetSongBPMService` | No API changes |
| `BPMDiscoveryService` | No discovery changes |
| `Onboarding views` | Complete in v1.5 |
| `TapBPMEngine` / `TapBPMView` | Complete in v1.4 |
| `SensorLabView` / `SensorLabService` | Complete in v1.4 |

## Recommended Build Order

```
Phase 1: Design System Foundation (BSHaptics, BSAnimation, ShimmerModifier)
    No dependencies. All later features reference these tokens.
        |
Phase 2: Analysis Bug Fix
    Add .onChange observer to PlaylistListView for scan completion.
    Quick win. Ensures accurate coverage data for all later features.
        |
Phase 3: Coverage Data Model (CoverageInfo, LibraryFilter)
    Foundation structs needed by library search AND playlist card redesign.
        |
    +---+---+
    |       |
Phase 4a: Library Search + Filter       Phase 4b: Playlist Card Redesign
    .searchable + LibraryFilterBar          ScanQualityBadge + PlaylistRow rework
    Uses CoverageInfo, LibraryFilter        Uses CoverageInfo
    |       |
    +---+---+
        |
Phase 5: Contextual Scan Actions
    Per-row scan UI. Builds on redesigned PlaylistRow from 4b.
        |
Phase 6: Run Menu Redesign
    RunPlaylistCard + multi-zone + layout. Independent of library work
    but benefits from design tokens in Phase 1.
        |
Phase 7: Settings Screen Structure
    Section reorganization. Independent, can be moved earlier.
        |
Phase 8: Pre-built Skip Queue
    RunEngineService pre-queue + SpotifyPlayerService.addToQueue.
    Highest risk (Spotify API behavior). Build last to allow investigation.
        |
Phase 9: Micro-interaction Pass
    Sprinkle BSHaptics + BSAnimation across ALL modified views.
    Must come last -- all views need to be in final form.
```

**Ordering rationale:**
- **Phase 1 first:** Design system tokens are referenced by everything else.
- **Phase 2 early:** Bug fix ensures data correctness before building features that depend on coverage data.
- **Phase 3 before 4a/4b:** Both library features need the shared data model.
- **4a and 4b can parallel:** Search and card redesign are independent views that share the data model.
- **Phase 5 after 4b:** Contextual scan actions build on the redesigned `PlaylistRow`.
- **Phase 6 independent:** Run menu work does not depend on library features.
- **Phase 8 last (before 9):** Skip queue is the riskiest feature and is isolated from other work.
- **Phase 9 strictly last:** Haptic/animation pass touches every view and must happen after all views are finalized to avoid rework.

## Anti-Patterns to Avoid

### Anti-Pattern 1: God ViewModifier for Haptics

**What people do:** Create a `.hapticFeedback(type:)` modifier that tries to detect interaction context.
**Why it is wrong:** SwiftUI modifiers cannot reliably distinguish tap vs. long-press vs. selection. Wrong feedback or missed triggers.
**Do this instead:** Explicit `BSHaptics.selection()` calls at action sites. Haptics are intentional design choices.

### Anti-Pattern 2: Multi-Zone as RunEngine Concept

**What people do:** Push zone IDs and multi-zone logic into `RunEngineService`.
**Why it is wrong:** RunEngine works with `targetBPM: Int` + `tolerance: BPMTolerance`. Zones are a UI concept. Adding zone awareness to the engine couples it to the view model.
**Do this instead:** Resolve multi-zone to a single BPM + tolerance at the `RunTabView` layer. Pass resolved values to the engine. Same pattern as current single-zone implementation.

### Anti-Pattern 3: Spotify Queue as Source of Truth

**What people do:** Use Spotify's queue API to track "next track" and read it back.
**Why it is wrong:** Spotify's queue is opaque. User actions in Spotify app, other devices, or Connect sessions can modify it unpredictably.
**Do this instead:** Keep `preQueuedTrack` in `RunEngineService` as the source of truth. Use queue API only as an audio pre-loading optimization. Always fall back to direct `play(uri:)`.

### Anti-Pattern 4: Observable Service for Animation State

**What people do:** Create an `AnimationService` singleton that views observe.
**Why it is wrong:** Animations are view-local concerns. Centralizing creates unnecessary re-renders and coupling.
**Do this instead:** Use `BSAnimation` as a namespace of constants. Each view applies its own `.animation()` using these tokens.

### Anti-Pattern 5: Modifying DesignTokens.swift for New Token Types

**What people do:** Add haptic and animation tokens to the existing `DesignTokens.swift` file.
**Why it is wrong:** `DesignTokens.swift` (84 lines) contains Color, Font, Spacing, Radius, and ComponentSize tokens. Adding unrelated categories bloats it and makes it hard to navigate.
**Do this instead:** Create separate files: `BSHaptics.swift`, `BSAnimation.swift`. Same folder (`DesignSystem/`), separate concerns.

## Sources

- Full codebase read: all 65 Swift files in `/Users/stijngragt/Projects/beatstep/BeatStep/`
- `.planning/PROJECT.md`: v1.6 requirements and architectural decisions
- SwiftUI `.searchable`: stable since iOS 15, works with NavigationStack (HIGH confidence)
- `UIFeedbackGenerator` APIs: stable since iOS 10 (HIGH confidence)
- Spotify Web API `POST /me/player/queue`: documented endpoint (MEDIUM confidence -- interaction with direct `play` calls needs verification)
- SwiftUI `@Observable` singleton pattern: established throughout codebase, verified working (HIGH confidence)

---
*Architecture research for: BeatStep v1.6 Little Big Things*
*Researched: 2026-03-25*
