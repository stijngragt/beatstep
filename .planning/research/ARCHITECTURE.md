# Architecture Research

**Domain:** iOS music-sync running app — v1.3 active run screen rebuild
**Researched:** 2026-03-24
**Confidence:** HIGH (full codebase read, integration research on known code)

---

## Existing Architecture (v1.2 Baseline)

### System Overview

```
+-------------------------------------------------------------------+
|                          App Entry                                  |
|   BeatStepApp -> ContentView                                       |
|   AppState.resolve() gates: onboarding -> login -> authenticated   |
+----------+-------------------+-------------------+----------------+
|  Library  |      Run          |    Settings        |               |
|  Tab      |      Tab          |    Tab             |               |
|  NavStack |      NavStack     |    NavStack        |               |
+----------+-------------------+-------------------+----------------+
|                 Global: MiniPlayerView (safeAreaInset)              |
+-------------------------------------------------------------------+
|                        Services Layer                               |
|  RunEngineService    CadenceService      SpotifyPlayerService      |
|  SpotifyAuthService  SpotifyAPIService   BPMCacheService           |
|  LibraryScanService  GetSongBPMService   BPMDiscoveryService       |
|  AudioSessionService                                               |
+-------------------------------------------------------------------+
|                      Persistence Layer                              |
|  SwiftData (BPM cache)  |  UserDefaults (zones, mode, tolerance)  |
|  Keychain (auth tokens) |  @AppStorage (onboarding flag)          |
+-------------------------------------------------------------------+
```

### Current Run Flow (v1.2)

```
RunTabView (zone/playlist selection)
    |
    +--[NavigationLink]--> RunView (active run screen)
                              |
                              +-- CadenceService.requestPermissionAndStart()
                              +-- RunEngineService.startRun(playlist:tracks:)
                              |       |
                              |       +-- Loads BPM map from cache
                              |       +-- Starts cadenceMonitor (polls CadenceService every 2s)
                              |       +-- Starts songEndMonitor (polls SpotifyPlayerService every 2s)
                              |       +-- Plays first matched track
                              |
                              +-- RunView.activeView shows CadenceDisplayView
                              +-- MiniPlayerView (global, separate from RunView)
```

### Key Observations About Current State

1. **RunView is monolithic** — handles idle, detecting, active, paused, permission-denied states plus all controls in a single 269-line view
2. **MiniPlayerView is global** — always shown via safeAreaInset on ContentView, not contextual to run state
3. **CadenceDisplayView is minimal** — just shows SPM number + trend arrow, no zone context, no sync indicator
4. **No half-tempo concept exists** — `findMatchingTracks` already checks `spm, spm/2, spm*2` but this is automatic with no user control
5. **Pause state is bare** — shows "Paused" text + "Resume running to continue" + dimmed last SPM
6. **No run timer exists** — no elapsed time tracking
7. **Album art is available** — SpotifyTrack.album.images exists but is not shown in RunView or MiniPlayerView

---

## v1.3 Architecture: What Changes

### New vs Modified Components

| Component | Status | Rationale |
|-----------|--------|-----------|
| `ActiveRunView` | **NEW** | Replaces RunView's active/paused states with a dedicated full-screen run experience |
| `RunPlayerView` | **NEW** | Integrated music player for ActiveRunView (album art, track info, controls, BPM) |
| `CadenceDisplayView` | **MODIFY** | Add zone band indicator, delta label ("+4 spm"), color-coded sync state |
| `RunStatusBar` | **NEW** | Compact bar showing zone name, BPM match quality, elapsed time |
| `RunView` | **MODIFY** | Simplify to only handle idle/detecting states; navigate to ActiveRunView on .active |
| `RunEngineService` | **MODIFY** | Add half-tempo mode toggle, expose sync quality metric, add elapsed time |
| `CadenceService` | **NO CHANGE** | Already provides currentSPM, trend, state (including .paused) |
| `SpotifyPlayerService` | **NO CHANGE** | Already provides currentTrack, isPaused, playback controls |
| `DesignTokens` | **MODIFY** | Add sync-state colors, possibly new font tokens for run screen |
| `MiniPlayerView` | **MODIFY** | Hide when ActiveRunView is displayed (RunPlayerView replaces it contextually) |

### Component Architecture

```
RunView (simplified: idle + detecting only)
    |
    +--[state == .active]--> ActiveRunView (fullScreenCover or NavigationDestination)
                                |
                                +-- RunStatusBar
                                |     +-- Zone label (e.g. "Z2 Endurance")
                                |     +-- Match quality indicator
                                |     +-- Elapsed time
                                |
                                +-- CadenceDisplayView (enhanced)
                                |     +-- Big SPM number (center stage)
                                |     +-- Zone band indicator (visual target range)
                                |     +-- Delta label ("+4 spm" / "-2 spm")
                                |     +-- Sync color (green=matched, yellow=drifting, red=off)
                                |     +-- Trend arrow (existing)
                                |
                                +-- RunPlayerView (integrated)
                                |     +-- Album art (from SpotifyTrack.album.images)
                                |     +-- Song name + artist
                                |     +-- Track BPM badge
                                |     +-- Play/pause + skip controls
                                |     +-- Half-tempo toggle (1:1 / 1/2)
                                |
                                +-- Run controls (cool down, stop)
                                |
                                +-- PauseOverlayView (conditional)
                                      +-- Shown when CadenceService.state == .paused
                                      +-- Semi-transparent overlay
                                      +-- "Paused" messaging
                                      +-- Last SPM dimmed
                                      +-- Music continues playing
```

---

## Architectural Patterns

### Pattern 1: State-Driven View Transition

**What:** RunView detects when CadenceService transitions to `.active` and presents ActiveRunView. This separates pre-run setup from the active run experience.

**Why this way:** RunView currently handles 5 states in one view, making it increasingly complex. Splitting pre-run (idle, detecting) from active-run (active, paused) creates cleaner boundaries. The active run screen has fundamentally different layout needs (full-screen, no nav bar, always-on display).

**Implementation:**
```swift
// RunView simplified
var body: some View {
    ZStack {
        Color.surfaceBase.ignoresSafeArea()
        switch cadenceService.state {
        case .idle: idleView
        case .detecting: detectingView
        case .active, .paused:
            EmptyView() // ActiveRunView presented as fullScreenCover
        }
    }
    .fullScreenCover(isPresented: $showActiveRun) {
        ActiveRunView(playlist: playlist, tracks: tracks)
    }
    .onChange(of: cadenceService.state) { _, newState in
        if newState == .active { showActiveRun = true }
    }
}
```

**Trade-offs:** fullScreenCover vs NavigationDestination. fullScreenCover is better because: (a) the active run screen should fill the entire screen with no tab bar or nav bar, (b) dismissing returns cleanly to the run setup, (c) no back gesture that could accidentally end the run.

### Pattern 2: Sync Quality as Derived State

**What:** Compute sync quality from the delta between CadenceService.currentSPM and RunEngineService.effectiveBPM (or the current track's BPM), rather than storing it separately.

**Why this way:** Sync quality is a function of two existing values. Making it a computed property keeps the source of truth in cadence + engine services without adding another observable to synchronize.

**Implementation:**
```swift
// On RunEngineService
enum SyncQuality {
    case locked    // within +/-3 SPM of target
    case drifting  // within tolerance range
    case off       // outside tolerance
}

var syncQuality: SyncQuality {
    let delta = abs(CadenceService.shared.currentSPM - effectiveBPM)
    if delta <= 3 { return .locked }
    if delta <= tolerance.range { return .drifting }
    return .off
}

var cadenceDelta: Int {
    CadenceService.shared.currentSPM - effectiveBPM
}
```

**Trade-offs:** Reading CadenceService from RunEngineService couples them, but they are already coupled (RunEngineService already reads CadenceService.currentSPM in startRun). This just makes the relationship explicit as a user-facing metric.

### Pattern 3: Half-Tempo as Engine Mode, Not View Logic

**What:** Half-tempo matching is a RunEngineService concern. When enabled, the engine divides the runner's detected SPM by 2 before matching songs, so a runner at 170 SPM gets 85 BPM tracks.

**Why this way:** The existing `findMatchingTracks` already checks `spm/2` and `spm*2`, but it does so simultaneously (any match is valid). Half-tempo mode should ONLY match at half the cadence (plus tolerance), which is a matching algorithm change, not a UI filter.

**Implementation:**
```swift
// On RunEngineService
enum TempoMode: String {
    case full    // 1:1 - match songs at runner's SPM
    case half    // 1:2 - match songs at half runner's SPM
}

var tempoMode: TempoMode = .full

// Modified effectiveBPM
var effectiveBPM: Int {
    let baseBPM: Int
    switch runMode {
    case .free:
        baseBPM = sustainedSPM
    case .guided:
        // ... existing ramp logic
        baseBPM = targetBPM // simplified
    }

    switch tempoMode {
    case .full: return baseBPM
    case .half: return baseBPM / 2
    }
}

// findMatchingTracks simplified when tempoMode is explicit
func findMatchingTracks(forSPM spm: Int) -> [SpotifyTrack] {
    let target: Int
    switch tempoMode {
    case .full: target = spm
    case .half: target = spm / 2
    }
    // Match only against target (no more spm/2, spm*2 auto-detection)
    return playlistTracks.filter { track in
        guard let bpm = bpmMap[track.id] else { return false }
        return abs(bpm - target) <= tolerance.range
    }
}
```

**Trade-offs:** Removing the automatic spm/2 and spm*2 matching means the engine is stricter, which could reduce match pool. Mitigation: keep `findClosestTrack` as fallback, and surface pool size so the user knows when to toggle modes.

**Important design decision:** When half-tempo is active, a runner at 170 SPM wants songs at ~85 BPM. This means their feet hit every other beat. The cadence display should still show their actual SPM (170), but the match target should show 85 BPM. The UI needs to make this relationship clear.

### Pattern 4: Pause State as Overlay, Not Navigation

**What:** When CadenceService.state transitions to `.paused`, show a semi-transparent overlay on ActiveRunView rather than navigating to a different view.

**Why this way:**
- The runner stopped momentarily (water break, intersection) and will resume
- Music should keep playing (controlled by SpotifyPlayerService, independent of cadence)
- All run state is preserved (elapsed time continues, engine stays active)
- Quick visual feedback: "we noticed you stopped" without disruption
- Resume is automatic when CadenceService detects steps again (.paused -> .active)

**Implementation:**
```swift
// Inside ActiveRunView
ZStack {
    // Normal run content (always rendered)
    VStack { ... }

    // Pause overlay
    if cadenceService.state == .paused {
        PauseOverlayView(lastSPM: cadenceService.currentSPM)
            .transition(.opacity)
    }
}
.animation(.easeInOut(duration: 0.3), value: cadenceService.state)
```

**Trade-offs:** The overlay approach means run controls (stop, cool down) remain accessible under the overlay. This is intentional -- a runner might want to stop the run while paused. The overlay should be translucent enough to see controls through it, or provide its own stop button.

---

## Data Flow

### Active Run Data Flow (v1.3)

```
CMPedometer (CoreMotion)
    |
    v
CadenceService
    |-- currentSPM (rolling average)
    |-- state (.idle/.detecting/.active/.paused)
    |-- trend (.speedingUp/.steady/.slowingDown)
    |
    v
RunEngineService (reads CadenceService.currentSPM)
    |-- effectiveBPM (cadence adjusted for tempoMode + guided ramp)
    |-- syncQuality (NEW: derived from SPM vs effectiveBPM)
    |-- cadenceDelta (NEW: signed difference)
    |-- tempoMode (NEW: .full or .half)
    |-- currentMatchedTrack
    |-- rampPhase (guided mode)
    |-- isRunActive
    |-- elapsedTime (NEW)
    |
    +--[song selection]--> SpotifyPlayerService.play(uri:)
    |
    v
SpotifyPlayerService
    |-- currentTrack (polled every 3s)
    |-- isPaused
    |
    v
ActiveRunView (observes all three services via @Observable)
    |-- RunStatusBar (zone, match quality, time)
    |-- CadenceDisplayView (SPM, delta, sync color, zone band)
    |-- RunPlayerView (track info, album art, controls, BPM, tempo toggle)
    |-- PauseOverlayView (when state == .paused)
```

### New State: Elapsed Time

**Where:** RunEngineService. Add a `runStartTime: Date?` set in `startRun()`, cleared in `stopRun()`. Compute `elapsedTime` as `Date().timeIntervalSince(runStartTime)`. The view uses a SwiftUI `TimelineView` or `Text(timerInterval:)` for live updates without polling.

```swift
// RunEngineService addition
var runStartTime: Date?

// In startRun():
runStartTime = Date()

// In stopRun():
runStartTime = nil
```

```swift
// In RunStatusBar (SwiftUI handles the ticking):
if let start = runEngine.runStartTime {
    Text(start, style: .timer)
        .font(.captionBold)
        .foregroundStyle(Color.textSecondary)
}
```

### New State: Sync Quality Colors

| Sync State | Condition | Color | Token Name |
|------------|-----------|-------|------------|
| Locked | delta <= 3 | Green (.stateSuccess) | existing |
| Drifting | delta <= tolerance.range | Yellow (.stateWarning) | existing |
| Off | delta > tolerance.range | Red accent (.accent) | existing |

All colors already exist in DesignTokens. No new tokens needed for sync state.

---

## Integration Points

### ActiveRunView Presentation

| Concern | Approach |
|---------|----------|
| Tab bar visibility | fullScreenCover hides tab bar automatically |
| MiniPlayer overlap | MiniPlayerView should check `RunEngineService.shared.isRunActive` and hide when active run screen is showing |
| Navigation stack | ActiveRunView is presented modally, not pushed onto RunTab's NavigationStack |
| Screen wake | `UIApplication.shared.isIdleTimerDisabled = true` (already done in RunView, move to ActiveRunView) |
| Dismiss | Only via explicit "Stop Run" button, not swipe gesture (disable interactiveDismissDisabled) |

### MiniPlayer vs RunPlayerView

```
When ActiveRunView is NOT showing:
    MiniPlayerView visible (safeAreaInset) -- existing behavior

When ActiveRunView IS showing:
    MiniPlayerView hidden (isRunActive check)
    RunPlayerView visible (inside ActiveRunView) -- richer, with album art and tempo toggle
```

Implementation: Modify ContentView's safeAreaInset condition:
```swift
.safeAreaInset(edge: .bottom) {
    if SpotifyPlayerService.shared.currentTrack != nil
       && !RunEngineService.shared.isRunActive {
        MiniPlayerView()
    }
}
```

### Half-Tempo Toggle Mid-Run

The toggle must be switchable mid-run without restarting the run. When toggled:
1. `RunEngineService.tempoMode` changes
2. `effectiveBPM` recalculates immediately
3. `pendingRematch` is set to true so next song matches new target
4. Sync quality display updates instantly (derived property)
5. Current song keeps playing until it ends

No forced track skip on toggle. The mismatch is visible in sync quality, and the next song will match correctly.

---

## Component Boundaries

| Component | Owns | Reads From | Writes To |
|-----------|------|------------|-----------|
| ActiveRunView | Layout, presentation, dismiss | CadenceService, RunEngineService, SpotifyPlayerService | RunEngineService (stop, skip, tempoMode) |
| RunStatusBar | Zone label, match badge, timer | RunEngineService (rampPhase, syncQuality, runStartTime), RunZone | Nothing |
| CadenceDisplayView | SPM display, delta, zone band, sync color | CadenceService (SPM, trend), RunEngineService (effectiveBPM, syncQuality, cadenceDelta) | Nothing |
| RunPlayerView | Album art, track info, BPM, controls | SpotifyPlayerService (track, isPaused), BPMCacheService (track BPM), RunEngineService (tempoMode) | SpotifyPlayerService (play/pause, skip), RunEngineService (tempoMode toggle) |
| PauseOverlayView | Pause messaging, dimmed SPM | CadenceService (currentSPM) | Nothing |

---

## Recommended Build Order

Build order follows dependency chains: service changes before views, inner components before containers.

### Phase 1: RunEngine Extensions

Modify `RunEngineService` to add:
- `TempoMode` enum and `tempoMode` property
- `syncQuality` computed property
- `cadenceDelta` computed property
- `runStartTime` tracking
- Modified `findMatchingTracks` to respect `tempoMode`
- `setTempoMode()` method that sets `pendingRematch = true`

**Why first:** All new views depend on these data points. Building views without the data means placeholder logic that gets rewritten.

### Phase 2: Enhanced CadenceDisplayView

Expand CadenceDisplayView with:
- Zone band indicator (visual bar showing target range)
- Delta label ("+4 spm" signed offset from target)
- Sync-state color on SPM number
- Keep existing trend arrow

**Why second:** This is the center-stage component of the new run screen. It is self-contained (just needs SPM + engine state as inputs) and can be previewed independently.

### Phase 3: RunPlayerView

Build the integrated player:
- Album art from `SpotifyTrack.album.images`
- Track name + artist
- BPM badge (from BPMCacheService)
- Play/pause + skip controls (mirror MiniPlayerView logic)
- Half-tempo toggle button

**Why third:** Independent component, no dependency on ActiveRunView layout. Can be previewed standalone.

### Phase 4: RunStatusBar + PauseOverlayView

Build supporting components:
- RunStatusBar: zone label, match quality badge, elapsed time
- PauseOverlayView: translucent overlay with pause messaging

**Why fourth:** Small, focused components. RunStatusBar needs runStartTime from Phase 1. PauseOverlayView is trivial.

### Phase 5: ActiveRunView Assembly

Compose all components into the full-screen run experience:
- Wire up ActiveRunView with RunStatusBar + CadenceDisplayView + RunPlayerView
- Add PauseOverlayView as conditional overlay
- Add run controls (stop, cool down)
- fullScreenCover presentation from RunView
- Hide MiniPlayerView when active run showing
- Move idle timer disable to ActiveRunView
- Disable interactive dismiss

**Why last:** This is pure composition. All building blocks exist from Phases 1-4. Integration testing validates the full flow.

---

## Anti-Patterns to Avoid

### Anti-Pattern 1: Polling for UI Updates

**What people do:** Timer-based polling to update elapsed time or sync quality displays.
**Why it is wrong:** Wastes CPU, causes jank, fights SwiftUI's declarative model.
**Do this instead:** Use `Text(date, style: .timer)` for elapsed time (SwiftUI handles updates). Use `@Observable` on RunEngineService -- SwiftUI re-renders when `syncQuality` or `cadenceDelta` change because their inputs (currentSPM, effectiveBPM) are already observable.

### Anti-Pattern 2: Fat View with Inline Logic

**What people do:** Compute sync quality, delta, zone band ranges inside the view body.
**Why it is wrong:** Breaks testability, makes the view hard to reason about, duplicates logic.
**Do this instead:** All derived state lives on RunEngineService. Views just read properties. Engine is testable without UI.

### Anti-Pattern 3: Duplicating MiniPlayerView Logic

**What people do:** Copy-paste MiniPlayerView controls into RunPlayerView.
**Why it is wrong:** Two implementations of play/pause/skip diverge over time.
**Do this instead:** Both views call the same SpotifyPlayerService and RunEngineService methods. The shared logic is already in the services. The views just differ in layout.

### Anti-Pattern 4: Pausing Music When Cadence Pauses

**What people do:** Automatically pause Spotify when the runner stops.
**Why it is wrong:** Runner might be at a water stop, intersection, or tying shoes. Stopping music feels broken. Music and cadence are independent concerns.
**Do this instead:** Show pause overlay, keep music playing. If runner explicitly taps pause on RunPlayerView, that pauses music (user intent, not inferred).

---

## File Structure (New/Modified)

```
BeatStep/
  Services/
    RunEngineService.swift          # MODIFY: tempoMode, syncQuality, cadenceDelta, runStartTime
  Views/
    Run/
      RunView.swift                 # MODIFY: simplify to idle/detecting, present ActiveRunView
      ActiveRunView.swift           # NEW: full-screen active run experience
      RunStatusBar.swift            # NEW: zone + match + time bar
      RunPlayerView.swift           # NEW: integrated player with album art + tempo toggle
      PauseOverlayView.swift        # NEW: translucent pause state overlay
      CadenceDisplayView.swift      # MODIFY: zone band, delta, sync color
    Player/
      MiniPlayerView.swift          # MODIFY: hide when isRunActive (one-line change)
  DesignSystem/
    DesignTokens.swift              # MODIFY: potentially add run-specific component sizes
  Models/
    RunSession.swift                # MODIFY: add TempoMode enum (or new file)
```

4 new files, 5 modified files. Zero new services.

---

## Sources

- Full codebase read of BeatStep v1.2 (12 Swift source files in Services/, 7 in Views/, 10 in Models/)
- All architecture decisions derived from existing code patterns (singleton @Observable services, design token system, fullScreenCover precedent in onboarding)
- SwiftUI `Text(date, style: .timer)` is iOS 14+ built-in (no external dependency)

---
*Architecture research for: BeatStep v1.3 "In The Zone" active run experience*
*Researched: 2026-03-24*
