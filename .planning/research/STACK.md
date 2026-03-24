# Stack Research

**Domain:** iOS running app -- active run screen, integrated music player, cadence visualization, half-tempo matching, pause state UX
**Researched:** 2026-03-24
**Confidence:** HIGH

---

## Existing Stack (Validated -- Do Not Re-Research)

| Technology | Status |
|------------|--------|
| Swift 6 / SwiftUI + `@Observable` | Working |
| CoreMotion (CMPedometer) via CadenceService | Working |
| Spotify Web API (PKCE) via SpotifyPlayerService | Working |
| GetSongBPM API via Cloudflare Worker | Working |
| SwiftData (BPM cache) | Working |
| DesignTokens.swift (Color, Font, Spacing, Radius, ComponentSize) | Working |
| RunEngineService (cadence monitor, song-end monitor, BPM matching, ramp state machine) | Working |
| iOS 17.0 deployment target | Confirmed |

---

## v1.3 Stack Additions: In The Zone

v1.3 requires **zero new external dependencies**. Every capability needed is available in SwiftUI's iOS 17 built-in APIs.

### Core Technologies (v1.3)

| Technology | API | iOS Version | Purpose | Why This |
|------------|-----|-------------|---------|----------|
| Numeric text animation | `.contentTransition(.numericText())` | 17.0+ | Animate SPM counter digit changes (e.g., 164 to 168) with per-digit rolling transition | Built into SwiftUI. Digits animate individually with direction awareness (counts up vs down). Far cleaner than custom per-digit animation code. Already at target. |
| Phase-driven animations | `.phaseAnimator(_:content:animation:)` | 17.0+ | Pulse effect on sync state, breathing animation for pause state, cadence indicator color transitions | Already used in RunView detecting state (`detectingView` opacity pulse). Extend same pattern to more states. Zero learning curve. |
| Keyframe animations | `KeyframeAnimator` | 17.0+ | Multi-property choreography if needed (simultaneous scale + opacity + offset on BPM match events) | Reserve for cases where phaseAnimator is insufficient. Available at deployment target but use sparingly -- phaseAnimator handles most cases. |
| Haptic feedback | `.sensoryFeedback(_:trigger:)` | 17.0+ | Tactile confirmation on long-press-to-end completion, half-tempo toggle, zone transitions mid-run | Native SwiftUI modifier. Declarative -- attach to view, specify trigger value. Note: no iPad haptic support (acceptable for running app). |
| Async image loading | `AsyncImage(url:content:placeholder:)` | 15.0+ | Album art from Spotify CDN in run screen music player | Built-in SwiftUI. SpotifyTrack already has `album.images` array with 3 sizes (640px, 300px, 64px). Use 300px for run screen. |
| Long press gesture | `.onLongPressGesture(minimumDuration:onPressingChanged:)` | 15.0+ | Long-press-to-end run with visual progress ring | `onPressingChanged` callback fires with `Bool` indicating press state. Drive a circular `ProgressView` or custom `trim()` arc from a timer started when pressing begins. |
| Periodic UI updates | `TimelineView(.periodic(every: 1))` | 15.0+ | Run elapsed time display (HH:MM:SS) in status bar | Declarative periodic view updates. Cleaner than `Timer.publish` + `.onReceive` -- no Combine needed, stays in SwiftUI paradigm. |
| Color interpolation | `.contentTransition(.interpolate)` | 17.0+ | Smooth color transition on cadence sync state changes (synced/close/off) | Animates between color values without explicit `withAnimation` wrapping. Pair with `animation(.easeInOut)` for smooth state-driven color shifts. |

### Supporting Patterns (no libraries)

| Pattern | Implementation | Purpose | Detail |
|---------|---------------|---------|--------|
| Album art caching | `NSCache<NSURL, UIImage>` thin wrapper (~30 lines) | Prevent re-fetch on state transitions | AsyncImage does NOT cache between view reloads. On the run screen, the same album art persists across pause/resume/sync state changes. A simple in-memory cache avoids redundant network calls. |
| Sync state computation | `SyncState` enum on RunEngineService | Single source of truth for cadence indicator colors | Compare `CadenceService.currentSPM` vs `RunEngineService.effectiveBPM` with tolerance thresholds. Three states: `.synced` (within tolerance), `.close` (within 2x tolerance), `.off` (beyond). Drives color + haptic feedback. |
| Half-tempo flag | `Bool` on RunEngineService | Toggle 1:1 vs 1:2 step-to-beat ratio | `findMatchingTracks` already checks `spm`, `spm/2`, `spm*2`. Half-tempo mode changes `effectiveBPM` to use `sustainedSPM / 2` as primary. This is a ~3-line change in the computed property. |
| Run elapsed time | `Date` on RunEngineService | HH:MM:SS display via TimelineView | Store `runStartDate` at `startRun()`. Compute elapsed on each TimelineView tick. Reset on `stopRun()`. |
| Long-press progress | `@State private var isPressing = false` + Timer | Circular progress ring fills over 2-second hold | On `onPressingChanged: true`, start a 2-second animation filling a `Circle().trim()`. On release before completion, reset. On completion, stop run. Pair with `.sensoryFeedback(.success, trigger: runEnded)`. |

---

## Design Token Extensions

Existing `DesignTokens.swift` needs small additions:

### New Color Tokens

| Token | Value | Purpose |
|-------|-------|---------|
| `Color.syncGood` | `Color.stateSuccess` (reuse) | Cadence synced with BPM target -- green |
| `Color.syncClose` | `Color.stateWarning` (reuse) | Cadence within 2x tolerance -- yellow |
| `Color.syncOff` | `Color.accent` (reuse heartbeat red) | Cadence outside tolerance -- red |

These are semantic aliases, not new color values. They map to existing palette colors but communicate intent in the run screen context.

### New Font Tokens

| Token | Value | Purpose |
|-------|-------|---------|
| `Font.displayDelta` | `.system(size: 18, weight: .bold, design: .monospaced)` | Delta indicator text: "+4 spm", "-2 spm" |

### New Component Size Tokens

| Token | Value | Purpose |
|-------|-------|---------|
| `ComponentSize.albumArtRun` | `80` | Album art in run screen player (between existing small 44 and large 200) |
| `ComponentSize.longPressRing` | `72` | Long-press progress ring diameter |

---

## RunEngineService Extensions

```swift
// New observable properties:
var runStartDate: Date?              // Set at startRun(), nil at stopRun()
var isHalfTempo: Bool = false        // Toggled mid-run by user
var syncState: SyncState = .off      // Updated by cadence monitor

enum SyncState: Equatable {
    case synced   // |cadence - effectiveBPM| <= tolerance
    case close    // |cadence - effectiveBPM| <= tolerance * 2
    case off      // |cadence - effectiveBPM| > tolerance * 2
}

// Modified effectiveBPM computed property:
var effectiveBPM: Int {
    switch runMode {
    case .free:
        return isHalfTempo ? sustainedSPM / 2 : sustainedSPM
    case .guided:
        // existing ramp logic unchanged
        let base = /* existing calculation */
        return isHalfTempo ? base / 2 : base
    }
}
```

### CadenceService -- no changes needed

Already exposes `currentSPM`, `trend` (speedingUp/steady/slowingDown), `state` (idle/detecting/active/paused). The v1.3 run screen reads these existing properties.

### SpotifyPlayerService -- no changes needed

Already exposes `currentTrack` (with `album.images` for art), `isPaused`. The run screen player reads these same properties.

### SpotifyTrack -- already has album art

`SpotifyTrack.album.images` is `[SpotifyImage]?`. Spotify returns 3 sizes: 640px, 300px, 64px. For the run screen player at `ComponentSize.albumArtRun` (80pt), use the 300px image (closest to 80pt * 3x scale = 240px).

---

## Integration Points Summary

| v1.3 Feature | Existing Code Touched | Change Type |
|---|---|---|
| Active run screen layout | `RunView.swift` | Rebuild -- new layout with status bar, center cadence, player |
| Cadence visualization | `CadenceDisplayView.swift` | Enhance -- add `.contentTransition(.numericText())`, sync color, delta text |
| Integrated music player | New view (e.g., `RunPlayerView.swift`) | New -- album art, song/artist, BPM badge, playback controls |
| Run status bar | New view (e.g., `RunStatusBar.swift`) | New -- zone label, BPM match indicator, elapsed time |
| Half-tempo toggle | `RunEngineService.swift`, `RunView.swift` | Small -- add `isHalfTempo` flag, toggle button in run UI |
| Pause/idle state | `RunView.swift` | Rebuild -- deliberate pause design with breathing animation |
| Long-press-to-end | `RunView.swift` | Replace -- replace stop button with long-press gesture + progress ring |
| Sync state | `RunEngineService.swift` | Add -- `SyncState` enum, update in cadence monitor loop |
| Elapsed time | `RunEngineService.swift`, `RunStatusBar` | Add -- `runStartDate`, `TimelineView` in status bar |
| Design tokens | `DesignTokens.swift` | Extend -- add sync colors, delta font, component sizes |

---

## What NOT to Add

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| Lottie / Rive animation library | Every animation is achievable with built-in phaseAnimator, keyframeAnimator, contentTransition. Adding a dependency for animations on a run screen that must stay responsive is unnecessary weight and complexity. | `.phaseAnimator`, `.contentTransition(.numericText())`, `KeyframeAnimator` |
| SDWebImage / Kingfisher / Nuke | Album art is one image at a time (current track). These libraries solve list-scrolling performance with dozens of images -- not relevant here. | `AsyncImage` + thin NSCache wrapper (~30 lines) |
| CoreHaptics | Low-level haptic pattern authoring. Overkill for discrete feedback events (toggle, completion, zone change). | `.sensoryFeedback()` modifier |
| Combine (Timer.publish, PassthroughSubject) | Codebase uses Swift Observation exclusively. Introducing Combine creates two reactive paradigms and training overhead. | `TimelineView` for periodic updates, `@Observable` for state, async/await for async work |
| SwiftUI Charts | No data visualization in v1.3. The cadence zone band is a simple shape (progress bar), not a chart. | Custom `Capsule` / `RoundedRectangle` with `.frame(width:)` |
| Custom audio session changes | Background audio already configured in Info.plist (`UIBackgroundModes: audio`). AudioSessionService already handles session setup. Run screen does not alter audio behavior. | Existing infrastructure |
| UIKit gesture recognizers | SwiftUI's `onLongPressGesture` with `onPressingChanged` provides everything needed for the long-press-to-end pattern. Dropping to UIKit adds bridging complexity. | `.onLongPressGesture(minimumDuration:onPressingChanged:)` |
| Third-party circular progress view | A `Circle().trim(from: 0, to: progress)` with `.animation` is ~10 lines of SwiftUI. No library needed. | Native `Circle().trim()` + `.rotationEffect` |

---

## Alternatives Considered

| Recommended | Alternative | When to Use Alternative |
|-------------|-------------|------------------------|
| `AsyncImage` + NSCache | Kingfisher | If BeatStep later adds a scrollable track history with many images. Not needed for single-image run player. |
| `.sensoryFeedback()` | `UIImpactFeedbackGenerator` | Only if targeting iOS < 17. BeatStep targets 17.0. |
| `TimelineView` | `Timer.publish` + `.onReceive` | If Combine is already in the codebase (it is not) or if sub-second precision is needed (it is not -- 1-second ticks suffice). |
| `.contentTransition(.numericText())` | Custom per-digit animation view | If non-standard digit animation is needed (slot machine effect). Built-in numericText handles the SPM counter perfectly. |
| `phaseAnimator` for continuous effects | `withAnimation` + State toggles | For one-shot user-triggered animations. phaseAnimator is better for continuous state-driven cycles (pulse, breathe, glow). |
| `Circle().trim()` for progress ring | `ProgressView(.circular)` | If you want system-styled indeterminate progress. For determinate long-press progress with custom styling, `Circle().trim()` gives full control. |

---

## Version Compatibility

| API | Minimum iOS | BeatStep Target (17.0) | Status |
|-----|-------------|------------------------|--------|
| `.contentTransition(.numericText())` | 17.0 | 17.0 | Available |
| `.contentTransition(.numericText(countsDown:))` | 17.0 | 17.0 | Available |
| `.phaseAnimator` | 17.0 | 17.0 | Already in use (RunView) |
| `KeyframeAnimator` | 17.0 | 17.0 | Available |
| `.sensoryFeedback()` | 17.0 | 17.0 | Available |
| `AsyncImage` | 15.0 | 17.0 | Available |
| `TimelineView` | 15.0 | 17.0 | Available |
| `.onLongPressGesture(minimumDuration:onPressingChanged:)` | 15.0 | 17.0 | Available |
| `@Observable` macro | 17.0 | 17.0 | Already in use |
| `.contentTransition(.interpolate)` | 17.0 | 17.0 | Available |

---

## Key Takeaway

v1.3 requires zero new dependencies. Every capability -- numeric animations, phase-driven effects, haptic feedback, image loading, gesture handling, periodic updates -- is built into SwiftUI at iOS 17. The work is composing these APIs into a cohesive run screen, not adding libraries.

---

## Sources

- [Apple: PhaseAnimator](https://developer.apple.com/documentation/swiftui/phaseanimator) -- confirmed iOS 17.0+, cycling phase animation (HIGH confidence)
- [Apple: contentTransition numericText](https://developer.apple.com/documentation/SwiftUI/ContentTransition/numericText(countsDown:)) -- confirmed iOS 17.0+, per-digit animation (HIGH confidence)
- [Apple: SensoryFeedback](https://developer.apple.com/documentation/swiftui/sensoryfeedback) -- confirmed iOS 17.0+, no iPad haptics (HIGH confidence)
- [Apple: AsyncImage](https://developer.apple.com/documentation/swiftui/asyncimage) -- confirmed no built-in cache between reloads (HIGH confidence)
- [Apple: LongPressGesture](https://developer.apple.com/documentation/swiftui/longpressgesture) -- confirmed onPressingChanged callback (HIGH confidence)
- [Apple: onLongPressGesture](https://developer.apple.com/documentation/swiftui/view/onlongpressgesture(minimumduration:perform:onpressingchanged:)) -- press tracking API (HIGH confidence)
- Codebase inspection: RunEngineService.swift (effectiveBPM already supports spm/2), CadenceService.swift (exposes state/trend/currentSPM), SpotifyPlayerService.swift (exposes currentTrack with album.images), SpotifyTrack.swift (Album has images array), DesignTokens.swift (existing token structure), RunView.swift (current layout and phaseAnimator usage), MiniPlayerView.swift (existing player pattern)

---
*Stack research for: BeatStep v1.3 In The Zone -- run screen, music player, cadence visualization, half-tempo, pause state*
*Researched: 2026-03-24*
