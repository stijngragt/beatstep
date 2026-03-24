# Phase 16: Active Run Assembly - Research

**Researched:** 2026-03-24
**Domain:** SwiftUI full-screen presentation, gesture handling, view composition
**Confidence:** HIGH

## Summary

Phase 16 assembles the final active run experience by composing the components built in Phases 13-15 (RunStatusBar, CadenceDisplayView, ZoneBandView, RampPhaseIndicator, RunPlayerView) into a new ActiveRunView presented as a fullScreenCover. The key technical challenges are: (1) presenting a full-screen modal that cannot be swiped away, (2) implementing a long-press-to-stop mechanism with visual progress ring, (3) hiding the MiniPlayer and tab bar during the run, and (4) wiring the existing RunView's hardcoded placeholder values to real RunEngineService data.

The current RunView already handles the run lifecycle (start/stop, cadence detection, permission flow) but uses hardcoded sync values (`syncQuality: .inSync, cadenceDelta: 0, isGuidedMode: false`) and lacks the full-screen presentation. The strategy is to create an ActiveRunView that composes all sub-components with live engine data, present it via `.fullScreenCover`, and conditionally hide the MiniPlayer.

**Primary recommendation:** Create ActiveRunView as a new composition view, trigger it from RunView when cadence becomes active, use `interactiveDismissDisabled(true)` on fullScreenCover, and add an `isActiveRunShowing` observable on RunEngineService to control MiniPlayer visibility.

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| RUN-01 | User sees a full-screen active run view (three-zone layout: status bar, hero cadence, player area) presented via fullScreenCover when cadence is detected | fullScreenCover with interactiveDismissDisabled; compose RunStatusBar + CadenceDisplayView + ZoneBandView + RampPhaseIndicator + RunPlayerView |
| RUN-02 | User can stop a run only via long-press (2-second hold with visual progress ring), preventing accidental mid-run stops | LongPressGesture with DragGesture simultaneously; circular progress ring animated over 2 seconds; no other dismiss paths |
</phase_requirements>

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| SwiftUI | iOS 17+ | View composition, fullScreenCover, gestures | Already used throughout app |
| @Observable | iOS 17+ | RunEngineService, CadenceService state tracking | Already the pattern in this project |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| SwiftUI.Animation | iOS 17+ | Progress ring animation, transitions | Long-press progress feedback |
| CoreMotion (indirect) | iOS 17+ | Cadence detection via CadenceService | Already running, just consuming state |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| fullScreenCover | NavigationStack push | fullScreenCover is correct -- covers tab bar, prevents back swipe |
| LongPressGesture | Custom GestureRecognizer | SwiftUI gesture is sufficient for 2-second hold |

## Architecture Patterns

### Recommended Project Structure
```
BeatStep/Views/Run/
├── ActiveRunView.swift          # NEW: Full-screen composition
├── LongPressStopButton.swift    # NEW: Long-press with progress ring
├── RunView.swift                # MODIFY: Add fullScreenCover trigger
├── RunStatusBar.swift           # EXISTS: No changes
├── CadenceDisplayView.swift     # EXISTS: No changes
├── ZoneBandView.swift           # EXISTS: No changes
├── RampPhaseIndicator.swift     # EXISTS: No changes
├── SyncBackgroundModifier.swift # EXISTS: No changes
└── ...

BeatStep/Views/Player/
├── RunPlayerView.swift          # EXISTS: No changes
├── MiniPlayerView.swift         # EXISTS: No changes (hidden via flag)

BeatStep/App/
├── ContentView.swift            # MODIFY: Hide MiniPlayer when active run showing
```

### Pattern 1: fullScreenCover with Dismiss Prevention
**What:** Present ActiveRunView as a modal that cannot be swiped away
**When to use:** When the run transitions from idle/detecting to active
**Example:**
```swift
// In RunView
.fullScreenCover(isPresented: $showActiveRun) {
    ActiveRunView(playlist: playlist, tracks: tracks)
        .interactiveDismissDisabled(true)
}
```
**Key detail:** `interactiveDismissDisabled(true)` on fullScreenCover prevents the swipe-down gesture. The only dismiss path is the long-press stop button calling `dismiss()` via `@Environment(\.dismiss)`.

### Pattern 2: Three-Zone Layout
**What:** Vertical layout with status bar (top), hero cadence (center), player (bottom)
**When to use:** ActiveRunView body composition
**Example:**
```swift
VStack(spacing: 0) {
    // Zone 1: Status bar
    RunStatusBar(zoneName: zoneName, syncQuality: runEngine.syncQuality)

    Spacer()

    // Zone 2: Hero cadence area
    VStack(spacing: Spacing.md) {
        if runEngine.runMode == .guided, let phase = runEngine.rampPhase {
            RampPhaseIndicator(rampPhase: phase, effectiveBPM: runEngine.effectiveBPM, targetBPM: targetBPM)
        }
        CadenceDisplayView(
            spm: cadenceService.currentSPM,
            trend: cadenceService.trend,
            syncQuality: runEngine.syncQuality,
            cadenceDelta: runEngine.cadenceDelta,
            isGuidedMode: runEngine.runMode == .guided
        )
        if runEngine.runMode == .guided {
            ZoneBandView(targetBPM: targetBPM, toleranceRange: runEngine.tolerance.range,
                         currentCadence: runEngine.adjustedCadence, syncQuality: runEngine.syncQuality)
        }
    }

    Spacer()

    // Zone 3: Player + Stop
    if let track = runEngine.currentMatchedTrack {
        RunPlayerView(track: track, isPaused: playerService.isPaused,
                      trackBPM: runEngine.currentTrackBPM,
                      onPlayPause: { playerService.togglePlayPause() },
                      onSkip: { Task { await runEngine.skipToNextMatch() } })
    }

    LongPressStopButton()
        .padding(.bottom, Spacing.lg)
}
.syncBackground(runEngine.syncQuality)
```

### Pattern 3: Long-Press Stop with Progress Ring
**What:** A stop button that requires 2-second press with visual countdown
**When to use:** Only dismiss path from ActiveRunView
**Example:**
```swift
struct LongPressStopButton: View {
    @State private var isPressed = false
    @State private var progress: CGFloat = 0
    let duration: TimeInterval = 2.0
    var onStop: () -> Void

    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(Color.surfaceOverlay, lineWidth: 4)

            // Progress ring
            Circle()
                .trim(from: 0, to: progress)
                .stroke(Color.stateError, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))

            // Stop icon
            Image(systemName: "stop.fill")
                .font(.system(size: 20))
                .foregroundStyle(isPressed ? Color.stateError : Color.textSecondary)
        }
        .frame(width: 56, height: 56)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isPressed {
                        isPressed = true
                        withAnimation(.linear(duration: duration)) {
                            progress = 1.0
                        }
                    }
                }
                .onEnded { _ in
                    isPressed = false
                    if progress >= 0.95 {
                        onStop()
                    }
                    withAnimation(.easeOut(duration: 0.2)) {
                        progress = 0
                    }
                }
        )
    }
}
```
**Note:** Using DragGesture(minimumDistance: 0) instead of LongPressGesture because it gives continuous feedback (onChanged fires immediately on touch down). A Timer-based approach with `onChanged`/`onEnded` may be more reliable for detecting exact 2-second hold completion.

### Pattern 4: MiniPlayer Visibility Control
**What:** Hide MiniPlayer when ActiveRunView is showing
**When to use:** In ContentView's safeAreaInset
**Example:**
```swift
// In ContentView
.safeAreaInset(edge: .bottom) {
    if SpotifyPlayerService.shared.currentTrack != nil && !RunEngineService.shared.isRunActive {
        MiniPlayerView()
    }
}
```
**Key insight:** RunEngineService already has `isRunActive` boolean. Use this directly -- no new state needed for MiniPlayer hiding. When the fullScreenCover is presented, the tab bar is automatically hidden. MiniPlayer needs explicit hiding because it's in a safeAreaInset overlay.

### Anti-Patterns to Avoid
- **Adding navigation bar to ActiveRunView:** fullScreenCover should be chrome-free. No navigation bar, no back button. Only the long-press stop.
- **Using sheet instead of fullScreenCover:** Sheet allows swipe dismiss and doesn't cover the tab bar.
- **Putting stop logic in onDisappear:** The stop should be explicit via long-press, not tied to view lifecycle. RunView.onDisappear already handles cleanup, but ActiveRunView dismissal should trigger it.
- **Duplicating engine state in ActiveRunView:** Read directly from RunEngineService.shared and CadenceService.shared. No @State copies of sync data.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Swipe dismiss prevention | Custom gesture overrides | `interactiveDismissDisabled(true)` | Built-in SwiftUI modifier, works on fullScreenCover |
| Tab bar hiding during run | Manual tab bar manipulation | `fullScreenCover` presentation | Automatically covers the tab bar |
| Circular progress animation | Frame-by-frame drawing | `Circle().trim(from:to:)` with `withAnimation(.linear)` | SwiftUI handles smooth interpolation |
| Screen idle prevention | Custom timer | `UIApplication.shared.isIdleTimerDisabled = true` | Already used in RunView |

## Common Pitfalls

### Pitfall 1: fullScreenCover Not Actually Preventing Dismiss
**What goes wrong:** Using `.sheet` or forgetting `interactiveDismissDisabled` allows swipe-down dismiss
**Why it happens:** Easy to confuse sheet and fullScreenCover behavior
**How to avoid:** Always use `.fullScreenCover` + `.interactiveDismissDisabled(true)` together
**Warning signs:** User can swipe down to dismiss during a run

### Pitfall 2: Progress Ring Animation Not Canceling Properly
**What goes wrong:** User lifts finger but progress ring continues or completes
**Why it happens:** `withAnimation` doesn't cancel when gesture ends -- the animation continues
**How to avoid:** Use a Timer-based approach for the progress ring. Start a repeating timer on press, update progress manually, cancel timer on release. Check elapsed time >= 2 seconds for completion.
**Warning signs:** Ring fills even after finger lifted

### Pitfall 3: RunView onDisappear Firing When fullScreenCover Presented
**What goes wrong:** RunView.onDisappear stops the run engine when ActiveRunView appears
**Why it happens:** Presenting fullScreenCover may trigger the presenting view's onDisappear
**How to avoid:** Guard the cleanup in RunView.onDisappear with a check like `if !runEngine.isRunActive`. Or move run lifecycle management (start/stop) entirely into the ActiveRunView.
**Warning signs:** Run stops immediately when ActiveRunView appears

### Pitfall 4: MiniPlayer Flashing Between Transitions
**What goes wrong:** MiniPlayer briefly appears during the transition to/from fullScreenCover
**Why it happens:** `isRunActive` toggles at a different time than the fullScreenCover animation
**How to avoid:** Set `isRunActive = true` before presenting fullScreenCover, and dismiss fullScreenCover before setting `isRunActive = false`
**Warning signs:** Brief MiniPlayer flash during run start/end

### Pitfall 5: Hardcoded Values in Existing RunView Active State
**What goes wrong:** Current RunView.activeView passes hardcoded `.inSync`, `0` delta, `false` guided mode
**Why it happens:** Phase 14 noted "uses default sync parameters until Phase 16 wiring"
**How to avoid:** ActiveRunView must wire real values from RunEngineService: `runEngine.syncQuality`, `runEngine.cadenceDelta`, `runEngine.runMode == .guided`
**Warning signs:** Cadence display always shows "In Sync" regardless of actual state

## Code Examples

### Wiring Real Data to CadenceDisplayView
```swift
// CURRENT (hardcoded in RunView.activeView):
CadenceDisplayView(
    spm: cadenceService.currentSPM,
    trend: cadenceService.trend,
    syncQuality: .inSync,       // HARDCODED
    cadenceDelta: 0,            // HARDCODED
    isGuidedMode: false         // HARDCODED
)

// CORRECT (in ActiveRunView):
CadenceDisplayView(
    spm: cadenceService.currentSPM,
    trend: cadenceService.trend,
    syncQuality: runEngine.syncQuality,
    cadenceDelta: runEngine.cadenceDelta,
    isGuidedMode: runEngine.runMode == .guided
)
```

### Zone Name Derivation
```swift
// Derive zone name from selectedZoneId (passed from RunView)
private var zoneName: String? {
    guard let zoneId = selectedZoneId,
          let zone = RunZone.saved.first(where: { $0.id == zoneId }) else {
        return nil  // Free mode -- no zone name
    }
    return zone.displayLabel
}
```

### Timer-Based Long Press (More Reliable Than Animation)
```swift
@State private var pressTimer: Timer?
@State private var pressStart: Date?
@State private var progress: CGFloat = 0

func startPress() {
    pressStart = Date()
    pressTimer = Timer.scheduledTimer(withTimeInterval: 1/60, repeats: true) { _ in
        guard let start = pressStart else { return }
        let elapsed = Date().timeIntervalSince(start)
        progress = min(CGFloat(elapsed / 2.0), 1.0)
        if progress >= 1.0 {
            cancelPress()
            onStop()
        }
    }
}

func cancelPress() {
    pressTimer?.invalidate()
    pressTimer = nil
    pressStart = nil
    withAnimation(.easeOut(duration: 0.2)) { progress = 0 }
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| UIKit presentViewController | SwiftUI fullScreenCover | iOS 14+ | Declarative presentation |
| isModalInPresentation | interactiveDismissDisabled | iOS 15+ | SwiftUI-native dismiss prevention |
| UILongPressGestureRecognizer | SwiftUI gestures + DragGesture | iOS 13+ | Declarative gesture handling |

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | XCTest (Xcode 16) |
| Config file | BeatStepTests target in Xcode project |
| Quick run command | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BeatStepTests/ActiveRunViewTests -quiet` |
| Full suite command | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' -quiet` |

### Phase Requirements -> Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| RUN-01 | ActiveRunView composes status bar, cadence display, player with live data | unit | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BeatStepTests/ActiveRunViewTests -quiet` | No -- Wave 0 |
| RUN-02 | Long-press progress calculation reaches 1.0 at 2 seconds | unit | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BeatStepTests/LongPressStopTests -quiet` | No -- Wave 0 |

### Sampling Rate
- **Per task commit:** Quick run command for changed test files
- **Per wave merge:** Full suite command
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] `BeatStepTests/ActiveRunViewTests.swift` -- covers RUN-01 (wiring verification: syncQuality, cadenceDelta, isGuidedMode come from engine)
- [ ] `BeatStepTests/LongPressStopTests.swift` -- covers RUN-02 (progress calculation: 0s=0%, 1s=50%, 2s=100%)

## Open Questions

1. **RunView lifecycle when fullScreenCover presents**
   - What we know: RunView.onDisappear currently calls `runEngine.stopRun()`. fullScreenCover may trigger onDisappear on the presenting view.
   - What's unclear: Whether iOS 17 fires onDisappear for the presenting view during fullScreenCover presentation
   - Recommendation: Guard onDisappear cleanup with `if !runEngine.isRunActive` or restructure so ActiveRunView owns the stop lifecycle

2. **Cool Down button placement in ActiveRunView**
   - What we know: Current RunView has Cool Down + Stop buttons for guided mode
   - What's unclear: Whether Cool Down should be a separate button or integrated into the long-press area
   - Recommendation: Keep Cool Down as a regular tap button above the long-press stop, matching the current RunView pattern but without requiring long-press

## Sources

### Primary (HIGH confidence)
- Project source code: RunView.swift, ContentView.swift, RunEngineService.swift, RunPlayerView.swift, CadenceDisplayView.swift, RunStatusBar.swift, ZoneBandView.swift, RampPhaseIndicator.swift, MiniPlayerView.swift
- Phase 14 decisions: [14-02] "RunView call site uses default sync parameters until Phase 16 wiring"

### Secondary (MEDIUM confidence)
- SwiftUI fullScreenCover + interactiveDismissDisabled: Apple documentation, standard SwiftUI pattern since iOS 15
- DragGesture(minimumDistance: 0) for continuous press tracking: well-established SwiftUI pattern

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- all components exist, just need composition
- Architecture: HIGH -- three-zone layout and fullScreenCover are well-understood patterns
- Pitfalls: HIGH -- identified from direct code review (hardcoded values, onDisappear behavior)

**Research date:** 2026-03-24
**Valid until:** 2026-04-24 (stable SwiftUI patterns, unlikely to change)
