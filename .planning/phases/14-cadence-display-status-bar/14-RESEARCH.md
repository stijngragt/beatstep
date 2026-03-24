# Phase 14: Cadence Display + Status Bar - Research

**Researched:** 2026-03-24
**Domain:** SwiftUI component design, @Observable data binding, design tokens, SwiftUI animations
**Confidence:** HIGH

## Summary

Phase 14 builds four standalone SwiftUI view components that consume the engine state added in Phase 13 (syncQuality, cadenceDelta, tempoMode, rampPhase). All data sources already exist on RunEngineService as @Observable properties -- this phase is purely view-layer work with no engine changes needed.

The four deliverables are: (1) a RunStatusBar showing zone name + sync quality badge, (2) a zone band visualization showing cadence position within the target BPM range, (3) a background color shift based on sync state, and (4) ramp phase progress display. All components should work in SwiftUI previews with mock data, independent of the full run screen assembly (which is Phase 16).

The existing CadenceDisplayView will be enhanced rather than replaced -- it already shows SPM + trend arrow. The new components sit around it in the run screen layout but are built and previewed independently.

**Primary recommendation:** Build each component as a pure view taking explicit parameters (not reading RunEngineService.shared directly), making them fully previewable. The parent view (Phase 16) will wire them to the engine singleton.

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| RUN-03 | User sees current zone name and sync quality badge in the status bar during a run | RunStatusBar component consuming RunZone name + SyncQuality with color-coded badge using syncInSync/syncDrifting/syncMismatched tokens |
| CAD-03 | User sees a zone band visualization showing where current cadence sits within the target zone BPM range (guided mode only) | ZoneBandView with position indicator, reading zone.bpm + tolerance.range for band bounds + latestCadence for position |
| CAD-04 | User perceives a subtle background color shift based on sync state (in-sync vs drifting) as subconscious feedback | Background modifier using SyncQuality to interpolate between syncInSync/syncDrifting/syncMismatched at low opacity |
| CAD-05 | User sees ramp phase progress (warm-up / at-pace / cool-down) during guided mode runs | RampPhaseIndicator reading rampPhase.displayLabel with visual progress context from effectiveBPM vs targetBPM |
</phase_requirements>

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| SwiftUI | iOS 17+ | All view components | Project standard, @Observable integration |
| @Observable | Swift 5.9+ | Reactive data from RunEngineService | Already used throughout project |

### Supporting
No additional libraries needed. This phase uses only SwiftUI primitives and existing design tokens.

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Custom gauge for zone band | SwiftUI Gauge | Gauge styling is limited on iOS 17; custom view gives full control over appearance |
| Core Animation for background shift | SwiftUI .animation | SwiftUI animation is sufficient for subtle opacity/color transitions and consistent with project patterns |

## Architecture Patterns

### Recommended Project Structure
```
BeatStep/
  Views/
    Run/
      CadenceDisplayView.swift   # MODIFIED: add delta display, sync color
      RunStatusBar.swift          # NEW: zone name + sync quality badge
      ZoneBandView.swift          # NEW: zone band visualization (guided only)
      RampPhaseIndicator.swift    # NEW: warm-up/at-pace/cool-down progress
      SyncBackgroundModifier.swift # NEW: background color shift view modifier
```

### Pattern 1: Pure View Components with Explicit Parameters
**What:** Views take data as init parameters, not reading singletons directly
**When to use:** All new components in this phase

This pattern makes views previewable without requiring RunEngineService.shared to be in a specific state.

```swift
struct RunStatusBar: View {
    let zoneName: String?          // nil in free mode
    let syncQuality: SyncQuality

    var body: some View {
        HStack {
            if let zoneName {
                Text(zoneName)
                    .font(.captionBold)
                    .foregroundStyle(Color.textPrimary)
            }
            Spacer()
            SyncBadge(quality: syncQuality)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
    }
}

// Preview works without engine state:
#Preview {
    RunStatusBar(zoneName: "Z3 Tempo", syncQuality: .inSync)
        .background(Color.surfaceBase)
}
```

### Pattern 2: SwiftUI View Modifier for Background Color Shift
**What:** A view modifier that applies a subtle background color overlay based on sync state
**When to use:** CAD-04 background color shift requirement

```swift
struct SyncBackgroundModifier: ViewModifier {
    let syncQuality: SyncQuality

    private var backgroundColor: Color {
        switch syncQuality {
        case .inSync: return Color.syncInSync
        case .drifting: return Color.syncDrifting
        case .mismatched: return Color.syncMismatched
        }
    }

    func body(content: Content) -> some View {
        content
            .background(
                backgroundColor.opacity(0.08)
                    .ignoresSafeArea()
                    .animation(.easeInOut(duration: 0.6), value: syncQuality)
            )
    }
}

extension View {
    func syncBackground(_ quality: SyncQuality) -> some View {
        modifier(SyncBackgroundModifier(syncQuality: quality))
    }
}
```

### Pattern 3: Zone Band Visualization
**What:** A horizontal bar showing where current cadence sits within the zone's BPM range
**When to use:** CAD-03, guided mode only

The zone band needs three inputs: the zone's target BPM, the tolerance range (defines the band width), and current cadence. The band spans from (targetBPM - tolerance) to (targetBPM + tolerance), with the cadence indicator positioned proportionally.

```swift
struct ZoneBandView: View {
    let targetBPM: Int
    let toleranceRange: Int
    let currentCadence: Int
    let syncQuality: SyncQuality

    private var bandMin: Int { targetBPM - toleranceRange }
    private var bandMax: Int { targetBPM + toleranceRange }

    /// Position from 0.0 to 1.0 within the band, clamped
    private var position: Double {
        let range = Double(bandMax - bandMin)
        guard range > 0 else { return 0.5 }
        let raw = Double(currentCadence - bandMin) / range
        return min(max(raw, 0.0), 1.0)
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // Band background
                Capsule()
                    .fill(Color.surfaceOverlay)

                // Center zone indicator
                Capsule()
                    .fill(syncQuality.color.opacity(0.3))

                // Cadence position indicator
                Circle()
                    .fill(syncQuality.color)
                    .frame(width: 12, height: 12)
                    .offset(x: position * (geo.size.width - 12))
                    .animation(.easeInOut(duration: 0.3), value: currentCadence)
            }
        }
        .frame(height: 12)
    }
}
```

### Pattern 4: Ramp Phase Indicator
**What:** Shows current ramp phase with progress context
**When to use:** CAD-05, guided mode only

```swift
struct RampPhaseIndicator: View {
    let rampPhase: RampPhase
    let effectiveBPM: Int
    let targetBPM: Int

    private var progress: Double {
        switch rampPhase {
        case .warmUp:
            let start = 140
            let range = Double(targetBPM - start)
            guard range > 0 else { return 1.0 }
            return min(Double(effectiveBPM - start) / range, 1.0)
        case .atPace:
            return 1.0
        case .coolDown:
            let start = 140
            let range = Double(targetBPM - start)
            guard range > 0 else { return 0.0 }
            return max(Double(effectiveBPM - start) / range, 0.0)
        }
    }

    var body: some View {
        VStack(spacing: Spacing.xs) {
            Text(rampPhase.displayLabel)
                .font(.captionBold)
                .foregroundStyle(Color.textSecondary)

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.surfaceOverlay)
                    Capsule()
                        .fill(Color.accent)
                        .frame(width: geo.size.width * progress)
                        .animation(.easeInOut(duration: 0.5), value: effectiveBPM)
                }
            }
            .frame(height: 4)
        }
    }
}
```

### Pattern 5: SyncQuality Color Helper Extension
**What:** Convenience extension on SyncQuality to get the corresponding color token
**When to use:** All views that need sync-state coloring

```swift
extension SyncQuality {
    var color: Color {
        switch self {
        case .inSync: return .syncInSync
        case .drifting: return .syncDrifting
        case .mismatched: return .syncMismatched
        }
    }
}
```

This extension bridges the model layer (SyncQuality enum) to the design system (Color tokens). It belongs on the model since it maps 1:1 to existing tokens.

### Anti-Patterns to Avoid
- **Reading RunEngineService.shared in view init:** Makes previews impossible. Pass data as parameters instead.
- **Using Combine/PassthroughSubject:** Project uses @Observable exclusively. No Combine.
- **Adding new color values for sync states:** Sync colors already exist as aliases in DesignTokens (syncInSync, syncDrifting, syncMismatched). Use those tokens.
- **Building the full run screen layout:** That is Phase 16. This phase builds standalone, previewable components only.
- **Heavy animations on cadence updates:** Updates happen every 2 seconds. Subtle transitions (0.3-0.6s easeInOut) are appropriate. No spring animations or complex choreography.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Color for sync state | Switch statement in every view | `SyncQuality.color` extension + existing tokens | Single source of truth, already defined in DesignTokens |
| Badge/pill shape | Custom path drawing | `Capsule()` with text | SwiftUI Capsule is the idiomatic pill shape |
| Animated transitions | Manual withAnimation blocks | `.animation(_:value:)` modifier | Declarative, less error-prone, automatic cancellation |
| Position calculation | Manual pixel math | GeometryReader + proportional positioning | Adapts to any screen width |

## Common Pitfalls

### Pitfall 1: Zone Band Shows in Free Mode
**What goes wrong:** ZoneBandView renders when there's no zone target, showing a meaningless band
**Why it happens:** Not gating on runMode or selectedZoneId
**How to avoid:** ZoneBandView should only appear when the parent passes non-nil zone data. The view itself doesn't need to know about runMode -- just make it require a targetBPM parameter that the parent only provides in guided mode.
**Warning signs:** Band visible during free runs, or band showing with default values.

### Pitfall 2: Background Color Shift Too Aggressive
**What goes wrong:** Bright colored backgrounds are distracting during a run
**Why it happens:** Using full opacity for the sync color
**How to avoid:** Keep opacity very low (0.05-0.10). The requirement says "subtle" and "subconscious." A barely-perceptible tint is correct. Test in dark room conditions.
**Warning signs:** Background color drawing attention away from the SPM number.

### Pitfall 3: SyncQuality.color Import Issues
**What goes wrong:** SyncQuality is in Models/ (Foundation import) but Color requires SwiftUI
**Why it happens:** Adding a SwiftUI-dependent property to a Foundation-only file
**How to avoid:** Either add `import SwiftUI` to SyncQuality.swift (acceptable since it's iOS-only), or put the color extension in a separate file in the Views or DesignSystem directory. Putting `import SwiftUI` in the model file is the simpler approach and consistent with how the project uses DesignTokens (which imports SwiftUI).
**Warning signs:** Compile error about Color not found in SyncQuality.swift.

### Pitfall 4: GeometryReader Taking Full Space
**What goes wrong:** ZoneBandView expands to fill all available space because GeometryReader is greedy
**Why it happens:** GeometryReader proposes its parent's full size to its content
**How to avoid:** Constrain with `.frame(height: N)` on the GeometryReader, and set an explicit width via padding on the parent.
**Warning signs:** Zone band stretching vertically or pushing other content off screen.

### Pitfall 5: Preview Not Working Due to Missing Dependencies
**What goes wrong:** Preview crashes because SyncQuality or other types can't be resolved
**Why it happens:** Missing target membership for model files in the preview target
**How to avoid:** All model files (SyncQuality, TempoMode, RampPhase, RunZone, BPMTolerance) should already have BeatStep target membership from previous phases. Verify before adding new views.
**Warning signs:** "Cannot find type 'SyncQuality' in scope" in preview canvas.

### Pitfall 6: Ramp Progress Calculation Mismatch
**What goes wrong:** Progress bar doesn't match the actual ramp calculation in RunEngineService
**Why it happens:** Duplicating the warm-up start value (140) and step size (8) instead of deriving from engine state
**How to avoid:** The view should compute progress from effectiveBPM and targetBPM, not from ramp song count. The engine already computes effectiveBPM -- the view just shows where it is relative to target.
**Warning signs:** Progress bar jumps or shows 100% when ramp is still in progress.

## Code Examples

### Enhanced CadenceDisplayView with Delta and Sync Color
```swift
struct CadenceDisplayView: View {
    let spm: Int
    let trend: CadenceTrend
    let syncQuality: SyncQuality
    let cadenceDelta: Int
    let isGuidedMode: Bool

    var body: some View {
        VStack(spacing: Spacing.xs) {
            HStack(alignment: .firstTextBaseline, spacing: Spacing.md) {
                Text("\(spm)")
                    .font(.displaySPM)
                    .foregroundStyle(syncQuality.color)

                trendArrow
            }

            // Delta or sync label below SPM
            if isGuidedMode {
                deltaLabel
            } else {
                Text(syncQuality.displayLabel)
                    .font(.captionBold)
                    .foregroundStyle(syncQuality.color)
            }

            Text("SPM")
                .font(.displaySecondary)
                .foregroundStyle(Color.textSecondary)
        }
    }

    private var deltaLabel: some View {
        Text(cadenceDelta >= 0 ? "+\(cadenceDelta)" : "\(cadenceDelta)")
            .font(.captionBold)
            .foregroundStyle(syncQuality.color)
    }

    // ... trendArrow unchanged
}
```

### Sync Quality Badge (used in RunStatusBar)
```swift
struct SyncBadge: View {
    let quality: SyncQuality

    var body: some View {
        Text(quality.displayLabel)
            .font(.labelText)
            .foregroundStyle(quality.color)
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xxs)
            .background(
                Capsule()
                    .fill(quality.color.opacity(0.15))
            )
            .animation(.easeInOut(duration: 0.3), value: quality)
    }
}
```

### Preview Examples
```swift
#Preview("Status Bar - In Sync") {
    RunStatusBar(zoneName: "Z3 Tempo", syncQuality: .inSync)
        .background(Color.surfaceBase)
}

#Preview("Status Bar - Free Mode") {
    RunStatusBar(zoneName: nil, syncQuality: .drifting)
        .background(Color.surfaceBase)
}

#Preview("Zone Band") {
    ZoneBandView(
        targetBPM: 174,
        toleranceRange: 7,
        currentCadence: 170,
        syncQuality: .inSync
    )
    .padding(.horizontal, Spacing.xl)
    .background(Color.surfaceBase)
}

#Preview("Ramp Phase - Warming Up") {
    RampPhaseIndicator(
        rampPhase: .warmUp,
        effectiveBPM: 156,
        targetBPM: 174
    )
    .padding(.horizontal, Spacing.xl)
    .background(Color.surfaceBase)
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| ObservableObject + @Published | @Observable macro | WWDC 2023 (Swift 5.9) | Project already uses @Observable -- computed properties auto-track |
| .foregroundColor() | .foregroundStyle() | iOS 17 | Project already uses foregroundStyle |

No deprecated patterns apply. All SwiftUI APIs used are current for iOS 17+.

## Open Questions

1. **Should CadenceDisplayView SPM number be colored by sync state?**
   - What we know: CAD-04 says "subtle background color shift." The SPM number could also be tinted by sync state (green when in sync, etc.)
   - What's unclear: Whether coloring the number itself is too aggressive vs the "subtle" requirement
   - Recommendation: Color the SPM number by sync state (it's the primary metric -- seeing green/yellow/red instantly communicates state). Keep the background shift very subtle (low opacity) as a secondary reinforcement. These are different feedback channels that don't conflict.

2. **Zone band width: should it extend beyond tolerance range?**
   - What we know: The band shows "where current cadence sits within the target zone BPM range"
   - What's unclear: Whether the band should show just the inSync zone (tolerance range) or the full drifting zone (2x tolerance)
   - Recommendation: Show the full visible range as 2x tolerance (the "drifting" zone boundary). The center section can be highlighted as the "inSync" zone. This gives the runner more context about how far they are from ideal.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | XCTest (Xcode 16+) |
| Config file | BeatStepTests target in Xcode project |
| Quick run command | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BeatStepTests` |
| Full suite command | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16'` |

### Phase Requirements to Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| RUN-03 | RunStatusBar renders zone name and sync badge | unit (view model logic) | Quick run | No (new file) |
| CAD-03 | ZoneBandView position calculates correctly from cadence/target/tolerance | unit | Quick run | No (new file) |
| CAD-04 | SyncBackgroundModifier returns correct color for each SyncQuality case | unit | Quick run | No (new file) |
| CAD-05 | RampPhaseIndicator progress computes correctly for warmUp/atPace/coolDown | unit | Quick run | No (new file) |
| CAD-03 | SyncQuality.color returns correct design token color | unit | Quick run | No (new test) |

### Sampling Rate
- **Per task commit:** `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16'`
- **Per wave merge:** Full suite
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] `BeatStepTests/CadenceDisplayTests.swift` -- covers view logic: delta formatting, zone band position calculation, ramp progress computation, SyncQuality.color mapping
- [ ] SyncQuality.color extension -- needs import SwiftUI, testable via existing SyncQualityTests or new file

*(View rendering tests are limited in XCTest without ViewInspector. Focus tests on the computation logic: position calculation, progress calculation, color mapping, delta formatting. Visual correctness verified via SwiftUI previews.)*

## Sources

### Primary (HIGH confidence)
- Project source code: RunEngineService.swift (syncQuality, cadenceDelta, tempoMode, rampPhase, effectiveBPM, latestCadence all verified as existing observable properties)
- Project source code: DesignTokens.swift (syncInSync, syncDrifting, syncMismatched tokens verified)
- Project source code: SyncQuality.swift (displayLabel verified)
- Project source code: RampPhase.swift (displayLabel verified: "Warming up", "At pace", "Cooling down")
- Project source code: RunZone.swift (displayLabel verified: "Z1 Recovery", etc.)
- Project source code: CadenceDisplayView.swift (existing structure analyzed for enhancement)
- Phase 13 RESEARCH.md and plans (locked decisions about sync thresholds, delta computation)

### Secondary (MEDIUM confidence)
- SwiftUI GeometryReader, Capsule, animation APIs (training data, verified by project usage patterns)

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - pure SwiftUI with existing design tokens, no new dependencies
- Architecture: HIGH - follows established project patterns (pure views, design tokens, @Observable)
- Pitfalls: HIGH - identified from reading actual code structure and understanding view/engine boundary

**Research date:** 2026-03-24
**Valid until:** 2026-04-24 (stable -- pure UI components with no external dependencies)
