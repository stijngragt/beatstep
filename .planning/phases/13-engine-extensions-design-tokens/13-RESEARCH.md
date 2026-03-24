# Phase 13: Engine Extensions + Design Tokens - Research

**Researched:** 2026-03-24
**Domain:** Swift @Observable computed properties, enum modeling, UserDefaults persistence, SwiftUI color tokens
**Confidence:** HIGH

## Summary

Phase 13 adds three computed properties to RunEngineService (syncQuality, cadenceDelta, tempoMode) and sync-state color aliases to DesignTokens. This is entirely within patterns the project already uses -- @Observable for reactive state, enums with rawValue String + CaseIterable for mode types, UserDefaults for persistence, and static Color extensions for tokens.

The key complexity is in the sync quality calculation (threshold math tied to BPMTolerance) and the half-tempo mode's effect on both matching ranking and delta/sync computation. The findMatchingTracks modification requires careful ranking logic rather than BPM transformation -- this is a locked decision.

**Primary recommendation:** Follow the exact patterns established by RunMode and BPMTolerance for the new TempoMode enum, extend RunEngineService with computed published properties, and alias existing state colors for sync tokens.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- tempoMode toggle (1:1 vs 1/2) persists via UserDefaults across runs
- Mode change takes effect at next song, not immediately -- current song keeps playing
- findMatchingTracks uses tempoMode as a ranking preference (NOT a BPM /2 transformation)
- In 1/2 mode, sync quality and delta compare cadence/2 to song BPM (not raw cadence)
- Guided mode: signed delta from zone target BPM (e.g., "+4 SPM", "-6 SPM") -- explicit +/- signs
- Free mode: sync quality label ("In Sync", "Drifting", "Mismatched") instead of a numeric delta
- Updates every cadence poll cycle (2 seconds) -- no additional smoothing beyond CadenceService's rolling average
- cadenceDelta is a published computed property on RunEngineService
- Thresholds tied to user's BPM tolerance setting (not fixed values)
- inSync: delta within tolerance range (e.g., <= 7 with normal tolerance)
- drifting: delta between 1x and 2x tolerance (e.g., 8-14 with normal tolerance)
- mismatched: delta beyond 2x tolerance (e.g., 15+ with normal tolerance)
- Compares cadence to current song's BPM (not to effective/target BPM)
- In 1/2 tempo mode: compares cadence/2 to song BPM (consistent with delta)

### Claude's Discretion
- Exact enum naming for SyncQuality and TempoMode types
- Whether to use a SyncQuality enum or struct
- How to structure the half-tempo ranking bias in findMatchingTracks
- Sync-state color token naming and exact color values (can reuse/alias stateSuccess/stateWarning/stateError or define sync-specific colors)

### Deferred Ideas (OUT OF SCOPE)
None -- discussion stayed within phase scope
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| PLR-04 | User can toggle between 1:1 and 1/2 tempo matching mid-run, which changes how songs are matched to cadence and updates the sync/delta display accordingly | TempoMode enum + UserDefaults persistence pattern + findMatchingTracks ranking modification + delta/sync recalculation with cadence/2 |
| CAD-01 | User sees a color-coded sync state indicator showing whether cadence is in-sync, drifting, or mismatched with the current song BPM | SyncQuality enum + threshold calculation tied to BPMTolerance + syncState color tokens in DesignTokens |
| CAD-02 | User sees a signed delta indicator ("+4 SPM" / "-6 SPM") near the cadence number in guided mode, and sync quality text in free mode | cadenceDelta computed property on RunEngineService, mode-aware display logic |
</phase_requirements>

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Swift @Observable | Swift 5.9+ | Reactive state for RunEngineService properties | Already used throughout project -- no Combine |
| SwiftUI Color | iOS 17+ | Design token color definitions | Existing pattern in DesignTokens.swift |
| UserDefaults | Foundation | TempoMode persistence | Established pattern (RunMode, BPMTolerance, RunZone) |
| XCTest | Xcode 16+ | Unit tests for engine logic | Existing test suite in BeatStepTests/ |

### Supporting
No additional libraries needed. This phase is pure Swift/SwiftUI with existing patterns.

## Architecture Patterns

### Recommended Project Structure
```
BeatStep/
├── Models/
│   ├── TempoMode.swift          # NEW: 1:1 vs 1/2 enum
│   └── SyncQuality.swift        # NEW: inSync/drifting/mismatched enum
├── Services/
│   └── RunEngineService.swift   # MODIFIED: new computed properties
├── DesignSystem/
│   └── DesignTokens.swift       # MODIFIED: sync-state color aliases
BeatStepTests/
├── RunEngineServiceTests.swift  # MODIFIED: new test cases
├── DesignTokenTests.swift       # MODIFIED: sync color tests
└── SyncQualityTests.swift       # NEW: threshold logic tests
```

### Pattern 1: Enum with UserDefaults Persistence
**What:** Follow the exact RunMode/BPMTolerance pattern for TempoMode
**When to use:** All simple preference enums in this project

```swift
// Follow RunMode.swift pattern exactly
enum TempoMode: String, CaseIterable {
    case oneToOne = "oneToOne"
    case half = "half"

    var displayName: String {
        switch self {
        case .oneToOne: return "1:1"
        case .half: return "1/2"
        }
    }

    // MARK: - UserDefaults Persistence
    private static let key = "selectedTempoMode"

    static var saved: TempoMode {
        guard let raw = UserDefaults.standard.string(forKey: key),
              let value = TempoMode(rawValue: raw) else {
            return .oneToOne
        }
        return value
    }

    func save() {
        UserDefaults.standard.set(rawValue, forKey: TempoMode.key)
    }
}
```

### Pattern 2: SyncQuality Enum with Threshold Computation
**What:** Enum that computes from delta + tolerance, not stored directly
**When to use:** Derived state that depends on multiple inputs

```swift
enum SyncQuality: String, CaseIterable {
    case inSync
    case drifting
    case mismatched

    /// Compute sync quality from absolute delta and tolerance
    static func from(delta: Int, tolerance: BPMTolerance) -> SyncQuality {
        let absDelta = abs(delta)
        let range = tolerance.range
        if absDelta <= range {
            return .inSync
        } else if absDelta <= range * 2 {
            return .drifting
        } else {
            return .mismatched
        }
    }

    var displayLabel: String {
        switch self {
        case .inSync: return "In Sync"
        case .drifting: return "Drifting"
        case .mismatched: return "Mismatched"
        }
    }
}
```

### Pattern 3: Computed Properties on @Observable
**What:** syncQuality and cadenceDelta as computed vars that re-evaluate when dependencies change
**When to use:** Derived state on RunEngineService

Key insight: @Observable tracks access to stored properties. Computed properties that read stored properties automatically trigger observation updates. So `syncQuality` reading `currentMatchedTrack`, `tolerance`, and `tempoMode` will cause SwiftUI views to update when any of those change.

```swift
// On RunEngineService:
var tempoMode: TempoMode = .saved  // observable stored property

/// Raw signed delta between cadence and current song BPM
var cadenceDelta: Int {
    guard let trackBPM = currentTrackBPM else { return 0 }
    let cadence = adjustedCadence
    return cadence - trackBPM
}

var syncQuality: SyncQuality {
    return SyncQuality.from(delta: cadenceDelta, tolerance: tolerance)
}

/// Cadence adjusted for tempo mode (cadence/2 in half mode)
private var adjustedCadence: Int {
    let raw = CadenceService.shared.currentSPM
    switch tempoMode {
    case .oneToOne: return raw
    case .half: return raw / 2
    }
}

/// Current matched track's BPM from the bpmMap
private var currentTrackBPM: Int? {
    guard let track = currentMatchedTrack else { return nil }
    return bpmMap[track.id]
}
```

### Pattern 4: Ranking Preference in findMatchingTracks
**What:** Half-tempo mode boosts ranking of tracks near cadence/2 without filtering
**When to use:** tempoMode effect on track selection

The current `findMatchingTracks` filters tracks by checking targets `[spm, spm/2, spm*2]`. In half mode, we want to PREFER tracks near `spm/2` but still return all matches. This is a sort/ranking change, not a filter change.

```swift
// After filtering matches (same as today), sort with tempo mode preference:
func findMatchingTracks(forSPM spm: Int) -> [SpotifyTrack] {
    let targets = [spm, spm / 2, spm * 2]
    let range = tolerance.range

    var matches = playlistTracks.filter { track in
        guard let bpm = bpmMap[track.id] else { return false }
        return targets.contains { target in abs(bpm - target) <= range }
    }

    // Apply tempo mode ranking preference
    if tempoMode == .half {
        let preferredTarget = spm / 2
        matches.sort { trackA, trackB in
            let bpmA = bpmMap[trackA.id] ?? 0
            let bpmB = bpmMap[trackB.id] ?? 0
            return abs(bpmA - preferredTarget) < abs(bpmB - preferredTarget)
        }
    }

    return matches
}
```

### Pattern 5: Color Token Aliases
**What:** Sync-state colors aliasing existing state colors
**When to use:** DesignTokens extension

```swift
// In DesignTokens.swift, add sync-state aliases:
extension Color {
    // Sync State (aliases for downstream views)
    static let syncInSync = Color.stateSuccess      // green
    static let syncDrifting = Color.stateWarning     // yellow
    static let syncMismatched = Color.stateError     // red
}
```

### Anti-Patterns to Avoid
- **BPM /2 transformation in findMatchingTracks:** Do NOT halve the SPM input. The decision is locked: tempoMode is a ranking preference, not a BPM transformation. Halving SPM would double-halve since the filter already checks spm/2.
- **Storing syncQuality as a property:** It should be computed from delta + tolerance, not set manually. This prevents stale state.
- **Adding Combine publishers:** Project uses @Observable, not Combine. No PassthroughSubject or @Published.
- **Immediate song switch on tempoMode change:** Locked decision -- mode change takes effect at next song.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Sync threshold logic | Custom threshold manager | SyncQuality.from(delta:tolerance:) static method | Single source of truth, tied directly to BPMTolerance |
| Tempo mode persistence | Custom file storage | UserDefaults (same as RunMode) | Established project pattern, simple key-value |
| Reactive property updates | Manual notification system | @Observable computed properties | Framework handles dependency tracking automatically |
| Color token system | Custom theme manager | Static Color extensions | Existing DesignTokens.swift pattern |

## Common Pitfalls

### Pitfall 1: Stale Cadence in Computed Properties
**What goes wrong:** syncQuality and cadenceDelta read CadenceService.shared.currentSPM, but @Observable won't track cross-object reads automatically in computed properties if the other object's property isn't accessed through an observation context.
**Why it happens:** @Observable tracks property access on the same object. CadenceService is a separate @Observable singleton.
**How to avoid:** RunEngineService's cadence monitor already polls every 2 seconds and updates sustainedSPM. Use sustainedSPM (or a new `latestCadence` stored property updated in the monitor loop) rather than reading CadenceService directly in computed properties. This way @Observable correctly tracks the dependency.
**Warning signs:** syncQuality/cadenceDelta not updating in SwiftUI views despite cadence changing.

### Pitfall 2: Double-Halving in Track Matching
**What goes wrong:** If tempoMode == .half causes findMatchingTracks to receive spm/2, AND the filter already checks spm/2 as a target, tracks at spm/4 would match.
**Why it happens:** Misunderstanding the ranking-only requirement.
**How to avoid:** Locked decision -- tempoMode affects RANKING within results, not the SPM input to findMatchingTracks. The filter targets remain [spm, spm/2, spm*2] regardless of mode.
**Warning signs:** In half mode, songs playing at unexpected BPMs (e.g., 40 BPM tracks for a 160 SPM runner).

### Pitfall 3: Delta Comparison Target Confusion
**What goes wrong:** cadenceDelta compares against effectiveBPM (which uses ramp target in guided mode) instead of current song BPM.
**Why it happens:** effectiveBPM is used for song SELECTION, but delta shows difference from what's PLAYING.
**How to avoid:** Locked decision -- delta compares cadence to currentMatchedTrack's BPM (from bpmMap), not to effectiveBPM or targetBPM.
**Warning signs:** In guided warm-up, delta showing huge numbers because it's comparing to target instead of the actual playing song.

### Pitfall 4: Integer Division in Half-Tempo
**What goes wrong:** `cadence / 2` with odd cadence values loses precision (e.g., 171/2 = 85, not 85.5).
**Why it happens:** Swift integer division truncates.
**How to avoid:** This is acceptable -- all BPM values in the project are integers. The truncation matches how BPMTolerance.range works. No action needed, but be aware rounding behavior is floor-division.

### Pitfall 5: Testing Singleton State Leaks
**What goes wrong:** Tests modify RunEngineService.shared state and leak between test cases.
**Why it happens:** Singleton pattern means all tests share one instance.
**How to avoid:** Existing pattern: setUp() calls engine.stopRun() to reset state. New test helpers (setTempoModeForTesting) should follow same pattern. tearDown() calls stopRun() which should also reset tempoMode to default.
**Warning signs:** Tests passing individually but failing when run together.

## Code Examples

### Computing cadenceDelta for Guided vs Free Mode
```swift
// Guided mode: signed delta from current song BPM
// Free mode: same computation, but UI shows syncQuality label instead of number

var cadenceDelta: Int {
    guard let track = currentMatchedTrack,
          let trackBPM = bpmMap[track.id] else { return 0 }
    let cadence: Int
    switch tempoMode {
    case .oneToOne: cadence = CadenceService.shared.currentSPM
    case .half: cadence = CadenceService.shared.currentSPM / 2
    }
    return cadence - trackBPM
}
```

### Updating Cadence Monitor to Refresh Computed State
```swift
// In startCadenceMonitor, the existing 2-second poll already reads currentSPM.
// Store it as a tracked property so computed properties re-fire:

var latestCadence: Int = 0  // @Observable tracked

// In the monitor loop:
let currentSPM = await MainActor.run { CadenceService.shared.currentSPM }
self.latestCadence = currentSPM  // triggers syncQuality/cadenceDelta recomputation
```

### stopRun Reset for New Properties
```swift
func stopRun() {
    // ... existing resets ...
    latestCadence = 0
    // Note: tempoMode persists across runs (UserDefaults), do NOT reset it here
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Combine @Published | @Observable (Swift 5.9) | WWDC 2023 | Project already uses @Observable throughout |
| ObservableObject protocol | @Observable macro | WWDC 2023 | Computed properties auto-track dependencies |

No deprecated patterns apply -- this phase uses the same stack the project already relies on.

## Open Questions

1. **Guided mode delta: from song BPM or zone target BPM?**
   - CONTEXT.md says: "signed delta from zone target BPM" in the decisions section
   - CONTEXT.md also says: "Compares cadence to current song's BPM (not to effective/target BPM)" in thresholds
   - These appear contradictory. The threshold decision (compare to song BPM) was more specific and later in the discussion.
   - Recommendation: Use current song BPM as the comparison target for BOTH delta and sync quality. The "zone target BPM" language in the display decision likely refers to the display context (showing delta near cadence during guided mode), not the comparison target. If planner needs clarification, flag this.

2. **Should tempoMode be reset on stopRun?**
   - What we know: "persists via UserDefaults across runs" -- strongly suggests it survives run stop/start.
   - Recommendation: Do NOT reset tempoMode in stopRun(). It is a user preference like RunMode and BPMTolerance.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | XCTest (Xcode 16+) |
| Config file | BeatStepTests target in Xcode project |
| Quick run command | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BeatStepTests/RunEngineServiceTests` |
| Full suite command | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16'` |

### Phase Requirements to Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| PLR-04 | TempoMode toggle persists and affects findMatchingTracks ranking | unit | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BeatStepTests/RunEngineServiceTests` | Partially (file exists, new tests needed) |
| PLR-04 | findMatchingTracks prefers half-BPM tracks in half mode | unit | same | Partially |
| CAD-01 | SyncQuality computes correctly from delta + tolerance | unit | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BeatStepTests/SyncQualityTests` | No (new file) |
| CAD-01 | Sync-state color tokens exist in DesignTokens | unit | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BeatStepTests/DesignTokenTests` | Partially |
| CAD-02 | cadenceDelta computed correctly for guided/free modes | unit | RunEngineServiceTests | Partially |
| CAD-02 | Half-tempo mode halves cadence for delta computation | unit | RunEngineServiceTests | No (new tests) |

### Sampling Rate
- **Per task commit:** `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BeatStepTests/RunEngineServiceTests -only-testing:BeatStepTests/SyncQualityTests -only-testing:BeatStepTests/DesignTokenTests`
- **Per wave merge:** `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16'`
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] `BeatStepTests/SyncQualityTests.swift` -- covers CAD-01 threshold logic
- [ ] New test cases in `RunEngineServiceTests.swift` -- covers PLR-04 (tempoMode ranking), CAD-02 (cadenceDelta)
- [ ] New test cases in `DesignTokenTests.swift` -- covers CAD-01 (sync color tokens exist)

## Sources

### Primary (HIGH confidence)
- Project source code: RunEngineService.swift, BPMTolerance.swift, RunMode.swift, DesignTokens.swift, CadenceService.swift
- Project test code: RunEngineServiceTests.swift, DesignTokenTests.swift
- Phase context: 13-CONTEXT.md (locked decisions and discretion areas)

### Secondary (MEDIUM confidence)
- Swift @Observable documentation (training data, verified by project usage patterns)

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - project already uses all required patterns, no new dependencies
- Architecture: HIGH - direct extension of existing RunEngineService with established patterns
- Pitfalls: HIGH - identified from reading actual code and understanding the locked decisions

**Research date:** 2026-03-24
**Valid until:** 2026-04-24 (stable -- no external dependencies, pure project-internal work)
