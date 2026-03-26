# Stack Research: v1.7 Beat Perfect

**Domain:** iOS running music app -- responsive cadence, beat-sync accuracy, collapsible player
**Researched:** 2026-03-26
**Confidence:** HIGH

---

## Existing Stack (Validated -- Do Not Re-Research)

| Technology | Status |
|------------|--------|
| Swift 6 / SwiftUI + `@Observable` | Working |
| CoreMotion (CMPedometer + CMMotionManager) | Working |
| Spotify Web API (PKCE) via SpotifyPlayerService | Working |
| GetSongBPM API via Cloudflare Worker | Working |
| SwiftData (BPM cache + ScannedPlaylist) | Working |
| DesignTokens + BSHaptics + BSAnimation | Working |
| RunEngineService (cadence monitor, BPM matching, skip buffer, ramp) | Working |
| Swift Charts (SensorLab waveform) | Working |
| ShimmerModifier, FilterChipBar, PlaylistCardView | Working |
| iOS 17.0 deployment target | Confirmed |

---

## v1.7 Stack Verdict: Zero New Dependencies

Every v1.7 feature is achievable by tuning existing code and adding small new service classes. No new Swift packages, no new frameworks, no new APIs beyond what is already linked.

---

## Feature 1: Responsive Cadence (<2s Update)

### Root Cause Analysis

The current cadence pipeline has three latency layers stacked on top of each other:

| Layer | Current Value | Latency Contribution | Location |
|-------|--------------|---------------------|----------|
| CMPedometer callback | ~1-2s (system-controlled) | 1-2s | Cannot change -- Apple controls this |
| Rolling average window | 5.0s | Up to 5s (stale samples dilute new data) | `CadenceService.windowDuration` |
| RunEngine poll interval | 2.0s | Up to 2s (waits for next poll tick) | `RunEngineService.startCadenceMonitor()` Task.sleep |
| Sustained change debounce | 17.0s | 17s before song switch | `RunEngineService.onCadenceChanged()` Task.sleep |

**Worst case end-to-end:** A real pace change could take 2s (sensor) + 5s (window lag) + 2s (poll) + 17s (debounce) = **26 seconds** before triggering a song change. The screen update (latestCadence) skips the debounce but still suffers from 2s + 5s + 2s = **9 seconds** lag.

### Proposed Changes

| Parameter | Current | Proposed | Rationale |
|-----------|---------|----------|-----------|
| `windowDuration` | 5.0s | 2.5s | At 160 SPM (~2.67 steps/s), a 2.5s window contains ~6-7 samples. Enough for a stable rolling average while being responsive. Shorter than 2s risks jitter from single outlier steps |
| Poll interval | 2.0s | 1.0s | Halves the worst-case delay between CadenceService update and screen refresh. Minimal CPU cost (one property read per second) |
| Sustained debounce | 17.0s | 6.0s | 6s is roughly the length of one running music phrase (4 bars at 160 BPM). Enough to filter momentary sprint/stumble. Short enough that the user feels the app responding within 1-2 songs |

**Separate display from matching:** Currently `latestCadence` (for UI) and `sustainedSPM` (for song matching) both flow through the same debounce. Proposal: update `latestCadence` on every poll tick (1s) so the display is always current. Only gate `sustainedSPM` behind the 6s debounce. This is the most impactful change -- the user sees immediate cadence response even before a song switch happens.

### Technology Needed

None. This is three constant changes plus splitting a code path.

### Files Affected

| File | Change |
|------|--------|
| `CadenceService.swift` | `windowDuration: 5.0` to `2.5` |
| `RunEngineService.swift` | Poll sleep `2s` to `1s`, debounce `17s` to `6s`, split latestCadence update from sustainedSPM gate |

**Confidence:** HIGH -- Direct code analysis, Apple docs confirm CMPedometer pushes at ~1-2s.

---

## Feature 2: Beat-to-Step Accuracy Validation

### What This Means

BeatStep does **not** play audio locally -- Spotify handles playback. There is no audio buffer to analyze for beat transients. "Beat-to-step accuracy" means: given a track with known BPM, how closely do the runner's footstrikes land on the mathematical beat grid?

### Data Available

| Data | Source | Precision | Update Frequency |
|------|--------|-----------|-----------------|
| Step timestamps | CMPedometer `startUpdates` callback | ~10ms (system timer) | Every 1-2s (batched) |
| Track BPM | BPM cache (GetSongBPM) | Integer BPM | Static per track |
| Playback position | Spotify Web API `GET /me/player` `progress_ms` | ~200-500ms network latency | Polled |

### Algorithm: BeatSyncScorer

```
1. From BPM, compute beat interval: beatInterval = 60.0 / bpm (e.g., 0.375s at 160 BPM)
2. Establish beat grid start from playback position:
   beatGridOrigin = trackStartTime - (progressMs / 1000.0)
3. For each step timestamp:
   timeInTrack = stepTimestamp - beatGridOrigin
   nearestBeat = round(timeInTrack / beatInterval) * beatInterval
   offset = abs(timeInTrack - nearestBeat)
   normalizedOffset = offset / (beatInterval / 2)  // 0.0 = on beat, 1.0 = maximally off
   stepScore = 1.0 - normalizedOffset
4. Rolling average of last 16-32 step scores = sync accuracy percentage
```

### Key Constraint: Spotify progress_ms Latency

The Spotify Web API `progress_ms` field has 200-500ms of network round-trip latency. This means the beat grid origin is approximate. However, since we are computing a **statistical alignment score** over many steps (not single-step precision), this latency becomes noise that averages out. A window of 16-32 steps provides a stable accuracy reading.

**Calibration approach:** Poll `progress_ms` once when a new track starts playing. Use `Date()` at the time of that poll as the reference. Then extrapolate beat positions forward using the known BPM. Re-calibrate on each new track start. This avoids continuous polling latency.

### Implementation

| Component | Type | Lines (est.) | Purpose |
|-----------|------|-------------|---------|
| `BeatSyncScorer` | Service class | ~80 | Core scoring algorithm, rolling window, calibration |
| Step timestamp exposure | CadenceService change | ~10 | Publish `lastStepTimestamp: Date?` property |
| Score display | ActiveRunView change | ~20 | Show sync percentage in run screen (e.g., "87% on beat") |

### Technology Needed

| Technology | Version | Already In Project | Purpose |
|------------|---------|-------------------|---------|
| Foundation Date/TimeInterval | iOS 2.0+ | Yes | Sub-millisecond timestamp math |
| CMPedometer step events | iOS 8+ | Yes | Step timing source |
| Spotify `progress_ms` | Web API | Yes | Playback position for beat grid origin |

**No new frameworks.** Pure arithmetic on existing data streams.

### What NOT to Use

| Avoid | Why |
|-------|-----|
| AudioKit / AVAudioEngine | No local audio stream. Spotify handles playback. These would add 10MB+ for zero value |
| Accelerometer peak detection for step timing | CMPedometer already detects steps with Apple's ML pipeline. Building custom step detection from raw accelerometer data is months of work |
| Core Haptics for beat-aligned feedback | Tempting but out of scope. The ~200-500ms Spotify progress_ms latency makes precise beat-aligned haptics unreliable. Defer to a future milestone |

**Confidence:** HIGH -- Standard signal processing pattern. All data sources already available.

---

## Feature 3: Collapsible Player Strip

### Current Architecture

```
ContentView.authenticatedView:
  TabView(selection:)
    ...three tabs...
  .safeAreaInset(edge: .bottom) {
    if currentTrack != nil && !isRunActive {
      MiniPlayerView()  // Always fully visible, ~56pt height
    }
  }
```

### Proposed Architecture

```
ContentView.authenticatedView:
  TabView(selection:)
    ...three tabs...
  .safeAreaInset(edge: .bottom) {
    if currentTrack != nil && !isRunActive {
      CollapsiblePlayerStrip(isExpanded: $playerExpanded)
      // Uses DragGesture for swipe-down collapse / swipe-up expand
    }
  }
```

### Two-State Design

| State | Height | Content | Trigger |
|-------|--------|---------|---------|
| **Expanded** (default) | ~56pt | BPM badge + track name + artist + play/pause + skip | Swipe up on collapsed bar, or tap |
| **Collapsed** | ~20pt | Thin handle bar with truncated track title | Swipe down on expanded bar |

No "full screen now playing" state. That is a separate feature, out of scope for v1.7.

### Implementation Pattern

```swift
struct CollapsiblePlayerStrip: View {
    @Binding var isExpanded: Bool
    @GestureState private var dragOffset: CGFloat = 0

    var body: some View {
        VStack(spacing: 0) {
            // Handle indicator
            Capsule()
                .frame(width: 36, height: 4)
                .foregroundStyle(Color.textTertiary)
                .padding(.top, Spacing.xs)

            if isExpanded {
                MiniPlayerView()  // Existing view, unchanged
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            } else {
                // Collapsed: just track title
                CollapsedPlayerBar()
                    .transition(.opacity)
            }
        }
        .background(Rectangle().fill(.ultraThinMaterial))
        .gesture(
            DragGesture()
                .onEnded { value in
                    let velocity = value.predictedEndTranslation.height - value.translation.height
                    if value.translation.height > 40 || velocity > 300 {
                        withAnimation(BSAnimation.smooth) { isExpanded = false }
                    } else if value.translation.height < -40 || velocity < -300 {
                        withAnimation(BSAnimation.smooth) { isExpanded = true }
                    }
                }
        )
        .onTapGesture {
            if !isExpanded {
                withAnimation(BSAnimation.smooth) { isExpanded = true }
            }
        }
    }
}
```

### Pattern Rationale

- **@State + .onEnded over @GestureState:** Matches existing LongPressStopButton pattern (Key Decision in PROJECT.md). `DragGesture.onEnded` gives reliable end detection. `@GestureState` resets too eagerly for collapse/expand.
- **Velocity threshold (300 pt/s):** Standard iOS swipe speed. Fast flick collapses/expands regardless of distance.
- **Position threshold (40pt):** Slow deliberate drag needs to travel 40pt to trigger. Prevents accidental collapse from small touch movements.
- **BSAnimation.smooth:** Already the project's standard spring animation for layout transitions.

### Player Covering Nav Bar Fix

The current `.safeAreaInset(edge: .bottom)` approach in ContentView is architecturally correct -- it pushes tab content up rather than overlapping. If there is an overlap bug, likely causes:

1. **Conditional rendering race:** When `currentTrack` transitions from nil to non-nil, the safeAreaInset height change may not animate smoothly, causing a frame where content overlaps
2. **Tab bar height mismatch:** The UITabBar appearance configuration in `ContentView.init()` may not account for the additional safeAreaInset height

Investigation during implementation will determine root cause. The fix is likely a `.animation()` modifier on the safeAreaInset content or explicit padding adjustment, not an architecture change.

### Technology Needed

| Technology | Already In Project | Purpose |
|------------|-------------------|---------|
| SwiftUI DragGesture | Yes | Swipe detection |
| BSAnimation.smooth | Yes | Spring animation for expand/collapse |
| .safeAreaInset | Yes | Bottom bar positioning |
| .transition(.opacity) | Yes | Crossfade between states |

**No new frameworks.**

**Confidence:** HIGH -- Standard SwiftUI drag gesture pattern. All building blocks already in the codebase.

---

## Feature 4: Analyzed State Bug Fix

### Likely Root Cause (Needs Investigation)

The "analyzed state updates after scan" bug suggests SwiftData observation is not propagating changes to the view layer. Likely scenarios:

1. **SwiftData @Query not re-evaluating:** If PlaylistListView uses a computed filter over SwiftData results, the filter may not re-fire when underlying data changes
2. **In-memory cache stale:** BPMCacheService may have stale in-memory data that does not reflect SwiftData writes from a scan operation
3. **PlaylistFilter predicate timing:** The All/Analyzed/Unanalyzed filter may evaluate before scan results are persisted

### Technology Needed

None new. This is a SwiftData observation / cache invalidation debugging task.

**Confidence:** MEDIUM -- Root cause not yet confirmed. Multiple plausible causes.

---

## Integration Points Summary

| Existing Code | Change | Risk |
|---------------|--------|------|
| CadenceService.swift | Reduce windowDuration 5.0 to 2.5, expose lastStepTimestamp | LOW -- parameter change + one new property |
| RunEngineService.swift | Poll 2s to 1s, debounce 17s to 6s, split display/matching updates | MEDIUM -- core timing logic, needs thorough testing |
| ContentView.swift | Wrap MiniPlayerView in CollapsiblePlayerStrip, add @State playerExpanded | LOW -- additive wrapper |
| MiniPlayerView.swift | No internal changes | NONE |
| ActiveRunView.swift | Add beat-sync score display | LOW -- additive UI element |
| New: BeatSyncScorer.swift | ~80 line service for step-to-beat alignment scoring | LOW -- isolated new code |
| New: CollapsiblePlayerStrip.swift | ~60 line wrapper view with DragGesture | LOW -- isolated new code |
| New: CollapsedPlayerBar.swift | ~20 line thin bar view | LOW -- trivial view |

---

## What NOT to Add

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| AudioKit / AVAudioEngine | No local audio buffer to analyze. Spotify plays audio. 10MB+ dependency for zero value | Mathematical beat grid from known BPM + progress_ms |
| CMMotionManager for cadence | Raw accelerometer needs custom step detection ML. CMPedometer already does this | Keep CMPedometer, tune downstream processing |
| Combine / AsyncSequence pipelines | Adds second reactive paradigm to @Observable codebase. Over-engineering for what is parameter tuning | Keep @Observable + Task.sleep polling pattern |
| Core Haptics | Beat-aligned haptics require sub-50ms timing precision. Spotify progress_ms has 200-500ms latency. Would feel wrong | Defer to future milestone if/when local audio analysis becomes available |
| Third-party gesture libraries (SwiftUIX) | DragGesture handles collapse/expand cleanly. One gesture does not justify a dependency | Native SwiftUI DragGesture |
| Timer-based cadence (replacing CMPedometer) | Event-driven is more efficient and accurate than polling | Keep CMPedometer event-driven callback |
| BottomSheet packages | CollapsiblePlayerStrip is two states (expanded/collapsed), not a multi-detent sheet. 60 lines of code, not a framework | Custom DragGesture + state toggle |
| Spotify Playback SDK (iOS) | Would give local audio access for beat detection, but Spotify deprecated the iOS SDK and it conflicts with Web API player control | Stay on Web API |

---

## Alternatives Considered

| Recommended | Alternative | When to Use Alternative |
|-------------|-------------|-------------------------|
| Tune CadenceService window (5s to 2.5s) | Replace CMPedometer with CMMotionManager + peak detection | Never for v1.7. Only if Apple deprecates CMPedometer or cadence detection quality degrades |
| Mathematical beat grid scoring | Audio FFT beat detection via AVAudioEngine | Only if BeatStep ever plays audio locally (e.g., Apple Music integration with local files) |
| DragGesture for collapse | `.presentationDetents([.fraction(0.05), .fraction(0.1)])` sheet | If the player were presented as a sheet. It is a safeAreaInset, so sheet detents do not apply |
| 6s sustained debounce | No debounce (immediate song switch) | Never. Immediate switching would cause rapid song changes during pace fluctuations |
| Single poll for progress_ms (on track start) | Continuous progress_ms polling | Only if beat-sync accuracy needs to account for Spotify playback drift. Start with single calibration, add continuous only if drift is measured |

---

## Version Compatibility

| Component | Minimum iOS | Notes |
|-----------|-------------|-------|
| CMPedometer.currentCadence | iOS 9+ | Long-stable. No concerns |
| DragGesture | iOS 13+ | SwiftUI 1.0 |
| @Observable | iOS 17+ | Already required by app |
| .safeAreaInset | iOS 15+ | Already used |
| Date.timeIntervalSinceReferenceDate | iOS 2.0+ | Foundation core |

All features compatible with existing iOS 17+ deployment target.

---

## New Files to Create

| File | Type | Lines (est.) | Purpose |
|------|------|-------------|---------|
| `Services/BeatSyncScorer.swift` | Service | ~80 | Step-to-beat alignment scoring algorithm |
| `Views/Player/CollapsiblePlayerStrip.swift` | View | ~60 | Expand/collapse wrapper with DragGesture |
| `Views/Player/CollapsedPlayerBar.swift` | View | ~20 | Thin collapsed state bar |

---

## Key Takeaway

v1.7 is an **algorithmic tuning + UI pattern** milestone, not a dependency milestone. The cadence responsiveness fix is three constant changes. The beat-sync scorer is ~80 lines of timestamp math. The collapsible player is a standard drag gesture wrapper. The analyzed state bug is a SwiftData observation issue. None of these require new packages, frameworks, or APIs.

---

## Sources

- [CMPedometer Apple Documentation](https://developer.apple.com/documentation/coremotion/cmpedometer) -- Confirmed startUpdates callback is system-paced, not developer-configurable
- [CMPedometerData.currentCadence](https://developer.apple.com/documentation/coremotion/cmpedometerdata/currentcadence) -- Cadence as steps/second NSNumber
- [startUpdates(from:withHandler:)](https://developer.apple.com/documentation/coremotion/cmpedometer/1613950-startupdates) -- Handler fires on system schedule (~1-2s during movement)
- [Core Motion's CMPedometer (Medium)](https://medium.com/@Cordavi/core-motions-cmpedometer-8421cf3c24ca) -- Real-world update frequency observations
- [SwiftUI Drag Gesture (Design+Code)](https://designcode.io/swiftui-handbook-drag-gesture/) -- DragGesture patterns for expand/collapse
- [Swipe to Dismiss pattern (Medium)](https://medium.com/@jpmtech/add-swipe-to-dismiss-to-any-view-using-swiftui-262fb53f8bf5) -- Velocity and translation thresholds for swipe detection
- Direct code analysis: CadenceService.swift (5s window, CMPedometer callback), RunEngineService.swift (2s poll, 17s debounce, cadence monitor), MiniPlayerView.swift (current layout), ContentView.swift (safeAreaInset architecture), SensorLabService.swift (CMMotionManager isolation)

---
*Stack research for: BeatStep v1.7 Beat Perfect -- responsive cadence, beat-sync accuracy, collapsible player*
*Researched: 2026-03-26*
