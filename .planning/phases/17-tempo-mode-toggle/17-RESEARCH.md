# Phase 17: Tempo Mode Toggle - Research

**Researched:** 2026-03-24
**Domain:** SwiftUI toggle UI, RunEngineService integration
**Confidence:** HIGH

## Summary

Phase 17 is a small gap closure phase. The entire engine backend for tempo mode switching already exists in `RunEngineService` (the `tempoMode` property, `adjustedCadence` computation, `findMatchingTracks` half-tempo ranking, and `TempoMode` enum with UserDefaults persistence). The only missing piece is a visible UI control that lets the user tap to switch between 1:1 and 1:2 tempo matching mid-run.

The existing codebase follows a consistent pattern: `ActiveRunView` reads directly from `RunEngineService.shared` with no `@State` copies. All controls use design tokens (font tokens, color tokens, spacing tokens) and large touch targets (56pt+). The "Cool Down" button in `ActiveRunView` (lines 86-98) provides an exact template for adding a similar action button.

**Primary recommendation:** Add a single toggle button near the player controls in Zone 3 of `ActiveRunView` that reads `runEngine.tempoMode` and mutates it on tap. Persist via `tempoMode.save()`. One plan, one file change (ActiveRunView.swift), minimal test additions.

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| PLR-04 | User can toggle between 1:1 and 1/2 tempo matching mid-run, which changes how songs are matched to cadence and updates the sync/delta display accordingly | Engine backend fully exists (tempoMode property, adjustedCadence, cadenceDelta, findMatchingTracks ranking). Only needs UI toggle button in ActiveRunView that mutates `runEngine.tempoMode` and calls `.save()`. |
</phase_requirements>

## Standard Stack

### Core (already in project)
| Library | Version | Purpose | Status |
|---------|---------|---------|--------|
| SwiftUI | iOS 17+ | View framework | Already used everywhere |
| @Observable | iOS 17+ | Reactive state on RunEngineService | Already wired |

### No new dependencies needed
This phase requires zero new libraries. Everything is built with existing SwiftUI primitives and the project's design token system.

## Architecture Patterns

### Existing Pattern: Direct Service Access
`ActiveRunView` reads from singletons directly -- no `@State` copies, no view model layer:
```swift
private var runEngine: RunEngineService { .shared }
// Then in body:
runEngine.tempoMode  // reads current mode
runEngine.tempoMode = .half  // mutates (triggers @Observable update)
```

### Existing Pattern: Action Buttons in Zone 3
The "Cool Down" button (ActiveRunView lines 86-98) is the exact template:
```swift
Button {
    runEngine.startCoolDown()
} label: {
    Label("Cool Down", systemImage: "arrow.down.heart")
        .font(.bodyBold)
        .foregroundStyle(Color.textPrimary)
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.md)
        .background(Capsule().fill(Color.stateWarning.opacity(0.8)))
        .padding(.horizontal, Spacing.xl)
}
```

### Recommended Toggle Placement
The toggle should go in Zone 3 (player + controls area) of `ActiveRunView`, near the RunPlayerView. Two viable positions:

1. **Between RunPlayerView and Cool Down / Stop button** -- inline with the vertical flow
2. **Inside RunPlayerView near the BPM label** -- contextually near the tempo info

**Recommendation:** Position 1 (between player and stop). Reasons:
- Consistent with Cool Down button placement pattern
- Does not require modifying RunPlayerView's interface (which takes immutable data + callbacks)
- Keeps RunPlayerView a pure display component
- Larger, easier-to-hit button while running

### Toggle UI Design
Use a compact pill-style button showing current mode. The two states:
- **1:1** -- one footstrike per beat (normal)
- **1:2** -- two footstrikes per beat (half-tempo matching)

```swift
Button {
    let newMode: TempoMode = runEngine.tempoMode == .oneToOne ? .half : .oneToOne
    runEngine.tempoMode = newMode
    newMode.save()
} label: {
    Label(runEngine.tempoMode.displayName, systemImage: "metronome")
        .font(.bodyBold)
        .foregroundStyle(Color.textPrimary)
        .padding(.vertical, Spacing.sm)
        .padding(.horizontal, Spacing.lg)
        .background(Capsule().fill(Color.surfaceOverlay))
}
```

### Anti-Patterns to Avoid
- **Do NOT add @State for tempoMode:** `RunEngineService` is `@Observable` -- read directly from it
- **Do NOT modify RunPlayerView's init signature:** Keep it a pure display component with callbacks
- **Do NOT create a new file for the toggle:** It is a single button inside ActiveRunView's existing layout

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Toggle animation | Custom animation logic | SwiftUI `.animation(.default)` on label | Built-in handles state transitions |
| Persistence | New persistence layer | `TempoMode.save()` (already exists) | UserDefaults persistence already implemented |
| Reactive updates | Manual observation | `@Observable` on RunEngineService | Already set up -- mutating tempoMode triggers view update |

## Common Pitfalls

### Pitfall 1: Forgetting to persist
**What goes wrong:** Toggle works during the run but resets on next app launch
**Why it happens:** `runEngine.tempoMode = newMode` updates the in-memory property but does not persist
**How to avoid:** Always call `newMode.save()` after setting the property
**Warning signs:** tempoMode resets to .oneToOne after app restart

### Pitfall 2: Touch target too small for running
**What goes wrong:** Runner can't hit the toggle with bouncing phone and sweaty fingers
**How to avoid:** Minimum 44pt touch target (Apple HIG), ideally 56pt+ matching existing controls. Use full-width capsule like the Cool Down button, or at minimum padded pill.
**Warning signs:** Button is a small text-only element

### Pitfall 3: No visual feedback of active mode
**What goes wrong:** User taps but can't tell which mode is active
**How to avoid:** Show the current mode text (1:1 or 1/2) prominently. Consider differentiated background color for half mode.

## Code Examples

### Toggle Button (recommended implementation)
```swift
// Inside ActiveRunView body, Zone 3 VStack, before LongPressStopButton
Button {
    let newMode: TempoMode = runEngine.tempoMode == .oneToOne ? .half : .oneToOne
    runEngine.tempoMode = newMode
    newMode.save()
} label: {
    Label {
        Text("Tempo \(runEngine.tempoMode.displayName)")
    } icon: {
        Image(systemName: "metronome")
    }
    .font(.bodyBold)
    .foregroundStyle(Color.textPrimary)
    .frame(maxWidth: .infinity)
    .padding(.vertical, Spacing.md)
    .background(Capsule().fill(Color.surfaceOverlay))
    .padding(.horizontal, Spacing.xl)
}
```

### Engine reads already wired
These already work with no changes needed:
```swift
// RunEngineService.swift (existing)
var adjustedCadence: Int {
    switch tempoMode {
    case .oneToOne: return latestCadence
    case .half: return latestCadence / 2
    }
}

var cadenceDelta: Int {
    guard let trackBPM = currentTrackBPM else { return 0 }
    return adjustedCadence - trackBPM
}

var syncQuality: SyncQuality {
    SyncQuality.from(delta: cadenceDelta, tolerance: tolerance)
}
```

When `tempoMode` changes, `adjustedCadence` changes, which changes `cadenceDelta`, which changes `syncQuality`. The entire chain is reactive through `@Observable`.

## State of the Art

| Aspect | Status | Notes |
|--------|--------|-------|
| TempoMode enum | Complete | `.oneToOne`, `.half`, `displayName`, `save()`, `saved` |
| Engine integration | Complete | `adjustedCadence`, `cadenceDelta`, `syncQuality` all use tempoMode |
| findMatchingTracks ranking | Complete | Half mode sorts by proximity to spm/2 |
| UserDefaults persistence | Complete | `TempoMode.save()` and `TempoMode.saved` |
| UI toggle | Missing | This is the only gap |

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | XCTest (Xcode built-in) |
| Config file | BeatStepTests target in Xcode project |
| Quick run command | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BeatStepTests/ActiveRunViewTests -quiet` |
| Full suite command | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' -quiet` |

### Phase Requirements to Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| PLR-04 | Toggle button exists and switches tempoMode | unit | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BeatStepTests/ActiveRunViewTests -quiet` | Partial (ActiveRunViewTests.swift exists) |
| PLR-04 | tempoMode mutation triggers sync chain update | unit | Already covered by RunEngineServiceTests (half-tempo tests exist) | Yes |
| PLR-04 | TempoMode persistence works | unit | Already covered by SyncQualityTests (tempoMode tests exist) | Yes |

### Sampling Rate
- **Per task commit:** Quick run of ActiveRunViewTests
- **Per wave merge:** Full test suite
- **Phase gate:** Full suite green before verify

### Wave 0 Gaps
- [ ] Add tempo toggle test to `BeatStepTests/ActiveRunViewTests.swift` -- verify toggle button presence and mode switching behavior

## Open Questions

1. **Label wording: "Tempo 1:1" vs "1:1 Mode" vs just "1:1"**
   - What we know: TempoMode.displayName returns "1:1" and "1/2"
   - Recommendation: Use "Tempo 1:1" / "Tempo 1/2" with metronome icon for clarity

2. **Should the toggle be visible only when a track is playing?**
   - What we know: The Cool Down button is always visible (when conditions met). RunPlayerView only shows when `currentMatchedTrack != nil`.
   - Recommendation: Show toggle always (even before first track matches) -- the user may want to set mode preference immediately

## Sources

### Primary (HIGH confidence)
- `BeatStep/Services/RunEngineService.swift` -- tempoMode property, adjustedCadence, cadenceDelta, syncQuality chain
- `BeatStep/Models/TempoMode.swift` -- enum with displayName, save(), saved
- `BeatStep/Views/Run/ActiveRunView.swift` -- current Zone 3 layout, Cool Down button template
- `BeatStep/Views/Player/RunPlayerView.swift` -- player component interface (immutable data + callbacks)
- `BeatStep/DesignSystem/DesignTokens.swift` -- font, color, spacing, radius tokens
- `.planning/v1.3-MILESTONE-AUDIT.md` -- gap identification and fix scope

### Secondary (HIGH confidence)
- `BeatStepTests/RunEngineServiceTests.swift` -- existing half-tempo engine tests (lines 398-524)
- `BeatStepTests/SyncQualityTests.swift` -- existing TempoMode model tests (lines 74-97)

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- no new dependencies, all patterns established in codebase
- Architecture: HIGH -- follows exact existing patterns (Cool Down button, direct service access)
- Pitfalls: HIGH -- well-understood SwiftUI patterns, small surface area

**Research date:** 2026-03-24
**Valid until:** 2026-04-24 (stable -- no external dependencies, all internal code)
