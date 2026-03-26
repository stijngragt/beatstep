# Architecture Research: v1.7 Beat Perfect Integration

**Domain:** iOS running music app -- responsive cadence, beat sync validation, bug fixes, collapsible player
**Researched:** 2026-03-26
**Confidence:** HIGH (all analysis based on current codebase inspection)

## System Overview: Current vs v1.7

```
┌─────────────────────────────────────────────────────────────────┐
│                        VIEW LAYER                                │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────┐   │
│  │ PlaylistList  │  │ ActiveRunView│  │ ContentView          │   │
│  │ View [MOD]   │  │ [MOD]        │  │ [MOD: player dock]   │   │
│  └──────┬───────┘  └──────┬───────┘  └──────────┬───────────┘   │
│         │                 │                      │               │
│  ┌──────┴───────┐  ┌──────┴───────┐  ┌──────────┴───────────┐   │
│  │ PlaylistRow   │  │ BeatSync     │  │ CollapsiblePlayer    │   │
│  │ [UNCHANGED]   │  │ Badge [NEW]  │  │ View [NEW]           │   │
│  └──────────────┘  └──────────────┘  └──────────────────────┘   │
├─────────────────────────────────────────────────────────────────┤
│                      SERVICE LAYER                               │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────┐   │
│  │ CadenceService│  │ RunEngine    │  │ LibraryScanService   │   │
│  │ [MOD]         │  │ Service [MOD]│  │ [MOD]                │   │
│  └──────────────┘  └──────────────┘  └──────────────────────┘   │
│  ┌──────────────┐  ┌──────────────┐                              │
│  │ SpotifyPlayer│  │ BPMCache     │                              │
│  │ Service      │  │ Service      │                              │
│  │ [UNCHANGED]  │  │ [UNCHANGED]  │                              │
│  └──────────────┘  └──────────────┘                              │
├─────────────────────────────────────────────────────────────────┤
│                      DATA LAYER                                  │
│  ┌──────────────┐  ┌──────────────┐                              │
│  │ ScannedPlay- │  │ CachedBPM    │                              │
│  │ list [UNCHG] │  │ [UNCHANGED]  │                              │
│  └──────────────┘  └──────────────┘                              │
└─────────────────────────────────────────────────────────────────┘
```

**Legend:** `[MOD]` = modify existing, `[NEW]` = new component, `[UNCHANGED]` = no changes needed

## Component Change Map

### UNCHANGED Components (no v1.7 work needed)

| Component | Why Unchanged |
|-----------|---------------|
| SpotifyPlayerService | Playback control API works; polling interval unrelated to cadence responsiveness |
| SpotifyAuthService | Auth flow unrelated to v1.7 features |
| BPMCacheService | Cache reads/writes are correct; analyzed state bug is in scan+view layer |
| ScannedPlaylist (model) | Schema is adequate; the bug is in how/when coverage data refreshes in views |
| CachedBPM (model) | No schema changes needed |
| BPMDiscoveryService | Discovery pipeline unrelated to v1.7 |
| GetSongBPMService | BPM lookup API unrelated to v1.7 |
| RunPlayerView | Existing in-run player is fine; collapsible player is for non-run state only |
| PlaylistRow | Row rendering is correct; the data flow into it is the issue |

### MODIFIED Components

| Component | What Changes | Why |
|-----------|-------------|-----|
| CadenceService | Reduce windowDuration, increase update frequency | 5s rolling window + 2s inactivity check = sluggish response |
| RunEngineService | Reduce cadence monitor polling, reduce debounce timer | 2s poll + 17s debounce = unresponsive cadence-to-song matching |
| ContentView | Replace `safeAreaInset` MiniPlayer with docked CollapsiblePlayerView | Current safeAreaInset overlaps tab bar content |
| PlaylistListView | Fix analyzed state reactivity after scan completes | Coverage data only updates on specific triggers, misses live scan completion |
| ActiveRunView | Add beat sync accuracy badge | New feature: visual validation of BPM-to-cadence accuracy |
| LibraryScanService | Publish scan completion to trigger view updates | Current completion path has gaps in notification |

### NEW Components

| Component | Responsibility | Location |
|-----------|---------------|----------|
| CollapsiblePlayerView | Expanded strip (title/BPM/controls) + collapsed thin handle | Views/Player/ |
| BeatSyncBadge | Visual accuracy indicator for beat-to-step match quality | Views/Run/ |

## Integration Analysis: Feature by Feature

### Feature 1: Responsive Cadence Detection (<2s)

**Root cause of current sluggishness:**

1. `CadenceService.windowDuration = 5.0` -- rolling average over 5 seconds smooths too aggressively
2. `CadenceService` inactivity timer checks every 2.0 seconds
3. `RunEngineService.startCadenceMonitor()` polls `CadenceService.currentSPM` every 2 seconds via `Task.sleep(for: .seconds(2))`
4. `RunEngineService.onCadenceChanged()` debounces with a 17-second `Task.sleep` before committing sustained change

**Total worst-case latency:** 5s (window) + 2s (poll) + 17s (debounce) = 24 seconds from real cadence change to song match update.

**Changes needed:**

| Component | Property/Method | Current | Target | Rationale |
|-----------|----------------|---------|--------|-----------|
| CadenceService | windowDuration | 5.0s | 3.0s | Faster rolling avg while retaining smoothing |
| CadenceService | inactivity timer interval | 2.0s | 2.0s (keep) | Inactivity detection timing is fine |
| RunEngineService | cadence poll (startCadenceMonitor) | 2s sleep | 1s sleep | Halve poll interval for faster pickup |
| RunEngineService | sustained debounce (onCadenceChanged) | 17s sleep | 8s sleep | Commit sustained changes sooner |

**Expected result:** Worst-case drops from 24s to 12s. Typical case (CMPedometer delivers ~1Hz): 3s (window) + 1s (poll) = 4s from real change to screen update. The 8s debounce only gates *song switching*, not the displayed cadence.

**Key insight:** Two separate responsiveness paths exist:
1. **Display path** (fast): CMPedometer -> CadenceService.processCadenceSample() -> @Observable currentSPM -> ActiveRunView CadenceDisplayView. This is already ~1-3s. Reducing windowDuration to 3s makes it faster.
2. **Song switch path** (slow): CadenceService -> RunEngineService poll -> debounce -> sustainedSPM commit -> buffer invalidation -> new song. This is the 24s path that drops to 12s.

**What stays:** CadenceService's processCadenceSample() logic, trend calculation, state machine (idle/detecting/active/paused). RunEngineService's buffer/selection/matching logic. All unchanged.

---

### Feature 2: Beat-to-Step Accuracy Validation

**What it is:** A visual indicator showing how well the current song's BPM matches the runner's actual cadence.

**Data already available (no service changes needed):**
- `RunEngineService.cadenceDelta` -- signed delta between adjusted cadence and track BPM
- `RunEngineService.syncQuality` -- enum derived from delta + tolerance (inSync/drifting/mismatched)
- `RunEngineService.currentTrackBPM` -- from bpmMap lookup
- `BPMCacheService` confidence field on CachedBPM -- verified/approximate/manual source

**New component: BeatSyncBadge**

Combines sync quality with BPM confidence to show accuracy. For known-BPM tracks (confidence: verified), the badge shows high-confidence sync state. For approximate/manual BPM tracks, it shows a qualified state.

**Integration point in ActiveRunView:**

```
ActiveRunView body VStack
  Zone 2: Hero cadence area
    ├── RampPhaseIndicator (guided only)
    ├── CadenceDisplayView (existing)
    ├── BeatSyncBadge [NEW]
    │     reads: runEngine.syncQuality, runEngine.currentTrackBPM,
    │            BPMCacheService confidence for current track
    └── ZoneBandView (guided only)
```

**Data flow:**
```
CadenceService.currentSPM
    |  (polled by RunEngineService)
RunEngineService.adjustedCadence  <->  RunEngineService.currentTrackBPM
    |  (derived)
RunEngineService.cadenceDelta -> SyncQuality
    |  (read by view)
BeatSyncBadge renders accuracy state
```

**What stays:** All RunEngineService computed properties. SyncQuality enum. CadenceDisplayView. Zero service-layer changes.

---

### Feature 3: Analyzed State Fix

**Bug:** After scanning a playlist, the PlaylistListView filter (Analyzed/Unanalyzed) does not reliably update. Playlists may still show as "Not analyzed" after scan completion.

**Root cause analysis:**

PlaylistListView line 204-209 already has an onChange observer:
```swift
.onChange(of: scanService.scanningPlaylistID) { oldValue, newValue in
    if oldValue != nil && newValue == nil {
        loadCoverageData()
    }
}
```

This was added in v1.6 (Feature 9 from previous architecture research). However, the bug persists. Two remaining gaps:

**Gap 1: Background scan path.** `ContentView.task { await LibraryScanService.shared.scanEnabledPlaylists() }` runs on app launch. This iterates enabled playlists, calling `scanPlaylistByID()` for each. Between scans, `scanningPlaylistID` transitions nil -> ID -> nil -> ID -> nil. If PlaylistListView is not yet mounted (user hasn't tapped Library tab), the onChange never fires. When the user later navigates to Library, `.task` calls `loadCoverageData()` -- BUT only when `playlists.isEmpty`. If playlists were already loaded from a previous session, `.task` does NOT re-run `loadCoverageData()`.

**Gap 2: Timing race.** In `LibraryScanService.scanPlaylistByID()`, the sequence is:
```swift
await scanPlaylist(playlist, tracks: allTracks)  // writes SwiftData
scanningPlaylistID = nil  // triggers onChange
```
The SwiftData `context.save()` inside `updateScannedPlaylistCoverage()` and the `@Observable` notification for `scanningPlaylistID = nil` are on the same main actor. However, `loadCoverageData()` in PlaylistListView does a fresh `context.fetch()`. If the save has not flushed, the fetch returns stale data.

**Fix approach (two-part):**

| Component | Change | Purpose |
|-----------|--------|---------|
| LibraryScanService | Add `var scanCompletionCount: Int = 0`, increment after each `scanPlaylist()` completes (after SwiftData save) | Reliable completion signal independent of scanningPlaylistID timing |
| PlaylistListView | Add `.onChange(of: scanService.scanCompletionCount) { loadCoverageData() }` | Catches all scan completions including background scans |
| PlaylistListView | In `.task`, always call `loadCoverageData()` (remove the `playlists.isEmpty` guard for coverage loading) | Ensures fresh coverage on every tab appearance |

**What stays:** ScannedPlaylist model, BPMCacheService, PlaylistRow rendering, filter logic, existing onChange for scanningPlaylistID (keep as belt-and-suspenders).

---

### Feature 4: Player Covering Bottom Nav Bar

**Current architecture:**
```swift
// ContentView.authenticatedView (line 90-94)
TabView(selection: $selectedTab) { ... }
    .safeAreaInset(edge: .bottom) {
        if SpotifyPlayerService.shared.currentTrack != nil && !RunEngineService.shared.isRunActive {
            MiniPlayerView()
        }
    }
```

**Problem:** `safeAreaInset(edge: .bottom)` is designed to inset content within the safe area. When applied to a TabView, it adds space above the tab bar and renders MiniPlayerView in that space. However, both the tab bar and MiniPlayerView use translucent materials (`.systemUltraThinMaterial` and `.ultraThinMaterial`), creating visual layering confusion. The mini player visually sits on top of the tab bar rather than above it, and the two blur layers compound.

**Fix: Replace safeAreaInset with VStack docking.**

```swift
// ContentView.authenticatedView (after fix)
VStack(spacing: 0) {
    TabView(selection: $selectedTab) { ... }
        .tint(Color.accent)

    if SpotifyPlayerService.shared.currentTrack != nil && !RunEngineService.shared.isRunActive {
        CollapsiblePlayerView()
            .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}
.animation(BSAnimation.smooth, value: SpotifyPlayerService.shared.currentTrack != nil)
```

**Why VStack over safeAreaInset:** The player is a docked UI element, not a safe area inset. VStack places it as a distinct layer between tab content and the tab bar. This matches the standard pattern used by Spotify and Apple Music.

**Layout impact:** With VStack, the player no longer pushes tab content up via safe area. Tab content scrolls normally behind the tab bar. The player occupies its own vertical space. This is the correct behavior -- the player should not affect content layout.

**Tab bar appearance:** The existing tab bar appearance config in `ContentView.init()` (lines 32-38) remains unchanged. The tab bar renders at the bottom as normal; CollapsiblePlayerView sits directly above it.

---

### Feature 5: Collapsible Player Strip

**Two visual states:**

| State | Height | Content | Trigger |
|-------|--------|---------|---------|
| Expanded | ~60pt | BPM badge, track title, artist, play/pause, skip | Default; swipe up from collapsed |
| Collapsed | ~12pt | Thin capsule handle, optional progress dot | Swipe down from expanded; tap to expand |

**New component: CollapsiblePlayerView**

```
CollapsiblePlayerView
  @State isCollapsed: Bool = false
  |
  |- Expanded state (isCollapsed == false):
  |    Same content as current MiniPlayerView:
  |    HStack: BPM badge | VStack(title, artist) | Spacer | play/pause, skip
  |    + DragGesture: swipe down (translation.height > 30) -> collapse
  |
  |- Collapsed state (isCollapsed == true):
  |    Capsule handle (40pt wide, 4pt tall, centered)
  |    Optional: tiny track name or animated progress dot
  |    + Tap gesture -> expand
  |    + DragGesture: swipe up (translation.height < -20) -> expand
  |
  |- Background: .ultraThinMaterial (expanded), Color.surfaceElevated (collapsed)
  |- Animation: BSAnimation.snappy for state transitions
```

**Gesture approach:** Use DragGesture.onEnded with translation threshold, matching the existing project pattern (per key decision: "Timer-based progress over GestureState -- DragGesture.onEnded gives reliable cancel; GestureState resets too eagerly").

**Data dependencies:** Same as MiniPlayerView -- reads `SpotifyPlayerService.shared` (currentTrack, isPaused) and `BPMCacheService.shared.getBPM()`. The skip action routes through `RunEngineService.shared.skipToNextMatch()` when run is active, otherwise `SpotifyPlayerService.shared.skipNext()`.

**MiniPlayerView disposition:** Delete after CollapsiblePlayerView is verified. No other code references MiniPlayerView except ContentView.

---

## New Components Summary

| Component | File Location | Purpose |
|-----------|---------------|---------|
| CollapsiblePlayerView | `Views/Player/CollapsiblePlayerView.swift` | Docked player with expand/collapse |
| BeatSyncBadge | `Views/Run/BeatSyncBadge.swift` | Visual beat-to-step accuracy indicator |

## Modified Components Summary

| Component | What Changes | Scope |
|-----------|-------------|-------|
| CadenceService | windowDuration 5->3, may adjust trend window | Small (constant changes) |
| RunEngineService | Poll interval 2s->1s, debounce 17s->8s | Small (constant changes) |
| ContentView | Replace safeAreaInset with VStack + CollapsiblePlayerView | Medium (layout restructure) |
| PlaylistListView | Add scanCompletionCount observer, always load coverage | Small (observer addition) |
| LibraryScanService | Add scanCompletionCount published property | Small (one property) |
| ActiveRunView | Add BeatSyncBadge to Zone 2 | Small (one view addition) |
| MiniPlayerView | Deprecated, deleted after CollapsiblePlayerView verified | Removal |

## Recommended Build Order

```
Phase 1: Analyzed State Fix (LibraryScanService + PlaylistListView)
   |  Pure bug fix, smallest scope, high trust impact
   |  No dependencies on other features
   |
Phase 2: Player Dock Fix (ContentView layout restructure)
   |  Fix the nav bar overlap bug
   |  Creates the VStack layout that CollapsiblePlayerView needs
   |
Phase 3: Collapsible Player Strip (CollapsiblePlayerView replaces MiniPlayerView)
   |  Depends on Phase 2 layout
   |  Delete MiniPlayerView after verification
   |
Phase 4: Responsive Cadence Detection (CadenceService + RunEngineService tuning)
   |  Should be done after player layout is stable
   |  so testing during runs is not confounded by UI bugs
   |
Phase 5: Beat Sync Accuracy Badge (BeatSyncBadge + ActiveRunView)
   |  Purely additive view component
   |  Benefits from responsive cadence (Phase 4) being in place
   |  to validate the badge updates promptly
```

**Ordering rationale:**
- **Phase 1 first:** Bug fix with zero risk, unblocks Library tab trust. Small scope means quick win.
- **Phase 2 before 3:** Collapsible player depends on the VStack dock layout. Fix the structural bug first, then build the new component.
- **Phase 3 before 4:** Get the player UI finalized before tuning cadence responsiveness, so run testing can use the final player layout.
- **Phase 4 before 5:** The beat sync badge is most meaningful when cadence is responsive. Testing the badge with sluggish cadence would give misleading UX impressions.
- **Phase 5 last:** Purely additive, read-only view. Lowest risk, highest dependency on other features being stable.

## Anti-Patterns to Avoid

### Anti-Pattern 1: Replacing @Observable Polling with Combine Publishers

**What people do:** Refactor the CadenceService -> RunEngineService polling to use Combine publishers for "reactive" cadence flow.
**Why it is wrong:** The app uses @Observable consistently. Mixing Combine publishers creates two observation systems with different lifecycle semantics.
**Do this instead:** Keep the polling pattern. Reduce the interval. The 1s poll is well within acceptable overhead.

### Anti-Pattern 2: SwiftData @Query for Coverage Data

**What people do:** Replace manual `loadCoverageData()` with @Query in PlaylistListView.
**Why it is wrong:** @Query requires the model container in the SwiftUI environment. Current architecture accesses SwiftData through `BPMCacheService.shared.context`. Adding @Query requires threading the container through ContentView -- a larger refactor with no proportional benefit.
**Do this instead:** Keep pull-based pattern but trigger it reliably via scanCompletionCount.

### Anti-Pattern 3: Complex Gesture State for Collapsible Player

**What people do:** Use GestureState or complex drag tracking for collapse/expand.
**Why it is wrong:** Per existing key decision: "DragGesture.onEnded gives reliable cancel; GestureState resets too eagerly."
**Do this instead:** Simple @State Bool + DragGesture.onEnded with translation threshold. Use `withAnimation(BSAnimation.snappy)` for transitions.

### Anti-Pattern 4: Reducing Debounce Below 5 Seconds

**What people do:** Set the sustained change debounce to 3s or less for "instant" responsiveness.
**Why it is wrong:** CMPedometer cadence fluctuates naturally by +/-5 SPM within a single stride cycle. Sub-5s debounce triggers song changes on normal running variance.
**Do this instead:** Use 8s debounce. Fast enough to feel responsive, slow enough to filter natural variance.

### Anti-Pattern 5: Pushing Collapse State Into a Service

**What people do:** Create a `PlayerStateService` or add `isCollapsed` to SpotifyPlayerService to centralize player state.
**Why it is wrong:** Collapse/expand is a view-local interaction concern. No other component needs to know whether the player is collapsed. Centralizing it creates unnecessary coupling.
**Do this instead:** Keep `@State isCollapsed` local to CollapsiblePlayerView. If ContentView needs to expand the player on track change, use `.onChange(of: playerService.currentTrack)` to reset the state.

## Integration Points

### External Services

| Service | Integration Impact | Notes |
|---------|-------------------|-------|
| Spotify Web API | None | No v1.7 changes to playback or auth |
| GetSongBPM API | None | BPM lookup unchanged |
| CMPedometer | Indirect | CadenceService reads it same way; window tuning is internal |

### Internal Boundaries

| Boundary | Communication | v1.7 Change |
|----------|---------------|-------------|
| CadenceService -> RunEngineService | Polling (read currentSPM) | Poll interval: 2s -> 1s |
| CadenceService -> ActiveRunView | @Observable reads (currentSPM, trend) | Unchanged; faster updates from shorter window |
| RunEngineService -> ActiveRunView | @Observable reads (syncQuality, cadenceDelta, etc.) | New: BeatSyncBadge reads same properties |
| LibraryScanService -> PlaylistListView | @Observable scanningPlaylistID + manual loadCoverageData() | Add: scanCompletionCount trigger |
| ContentView -> Player | safeAreaInset conditional rendering | Replace: VStack + CollapsiblePlayerView |
| SpotifyPlayerService -> CollapsiblePlayerView | @Observable reads (currentTrack, isPaused) | New view consumer, same data |

## Sources

- Direct codebase inspection: CadenceService.swift (182 lines), RunEngineService.swift (620 lines), ContentView.swift (99 lines), MiniPlayerView.swift (94 lines), PlaylistListView.swift (312 lines), LibraryScanService.swift (173 lines), ScannedPlaylist.swift (25 lines), SpotifyPlayerService.swift (200 lines), ActiveRunView.swift (162 lines)
- PROJECT.md key decisions and architecture context (166 lines of validated decisions)
- SwiftUI safeAreaInset behavior: Apple Developer documentation (HIGH confidence)

---
*Architecture research for: BeatStep v1.7 Beat Perfect*
*Researched: 2026-03-26*
