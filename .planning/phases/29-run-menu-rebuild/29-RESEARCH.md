# Phase 29: Run Menu Rebuild - Research

**Researched:** 2026-03-26
**Domain:** SwiftUI custom components, multi-selection UI, haptic feedback, BPM range merging
**Confidence:** HIGH

## Summary

Phase 29 transforms the Run tab from stock SwiftUI pickers to cohesive custom components with haptic feedback, and introduces multi-zone selection with merged BPM ranges. The codebase already has all the building blocks: `BSHaptics` for haptic feedback, `BSAnimation` for spring animations, `RunZone` model with UserDefaults persistence, `BPMTolerance` enum, and the `RunEngineService` that handles BPM matching. The work is primarily UI rebuild (replacing `ZonePickerView` and `TolerancePicker`) plus a model change to support `Set<Int>` zone IDs instead of a single `Int?`.

The critical architecture change is shifting from single-zone (`selectedZoneId: Int?`) to multi-zone (`selectedZoneIds: Set<Int>`). This affects persistence (UserDefaults), the zone-to-BPM mapping in `RunTabView.startRun()`, and the `ActiveRunView` initializer. The merged BPM range is computed as `min(selectedZones.map(\.bpm)) - tolerance ... max(selectedZones.map(\.bpm)) + tolerance`, which feeds into `RunEngineService` as the target BPM range for song matching.

**Primary recommendation:** Rebuild zone picker as a custom multi-select toggle grid, replace segmented tolerance picker with custom capsule selector, wire BSHaptics.selection() on every zone/tolerance tap, and compute merged BPM range from selected zones' floor/ceiling.

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| RUN-01 | Zone picker, tolerance selector, and playlist preview use cohesive custom components with haptic feedback | Custom capsule components replacing stock Picker, BSHaptics integration on every selection change |
| RUN-02 | User can select multiple zones -- BPM range merges from lowest zone floor to highest zone ceiling | Set<Int> zone selection model, merged BPM range computation, RunEngineService integration |
</phase_requirements>

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| SwiftUI | iOS 17+ | All UI components | Project standard, deployment target 17.0 |
| UIKit (UIImpactFeedbackGenerator) | iOS 17+ | Haptic feedback via BSHaptics | Already wrapped in BSHaptics enum |
| UserDefaults | Foundation | Zone selection persistence | Matches existing RunZone/BPMTolerance pattern |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| BSHaptics | Project token | Haptic feedback on selections | Every zone toggle and tolerance change |
| BSAnimation | Project token | Spring animations on selection state | Zone capsule scale/highlight transitions |
| DesignTokens | Project token | Color, spacing, radius, font tokens | All component styling |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Custom capsule grid | SwiftUI Picker with .menu style | Stock pickers can't support multi-select or custom haptics -- custom is required by RUN-01 |
| UserDefaults Set<Int> | SwiftData model | Overkill -- zone selection is a simple preference, matches existing pattern |

## Architecture Patterns

### Current Structure (before this phase)
```
BeatStep/
  Models/
    RunZone.swift           # Zone model with single selectedZoneId: Int?
    BPMTolerance.swift      # Tolerance enum with +-3/7/12
    RunMode.swift           # free/guided enum with targetBPM persistence
  Views/Run/
    RunTabView.swift        # Main run tab -- orchestrates all components
    ZonePickerView.swift    # Horizontal capsule scroll (single-select)
    TolerancePicker.swift   # Stock segmented Picker
    ActiveRunView.swift     # Full-screen run view (receives selectedZoneId: Int?)
  DesignSystem/
    BSHaptics.swift         # UIKit haptic wrappers
    BSAnimation.swift       # Spring animation presets
    DesignTokens.swift      # Color, font, spacing, radius tokens
```

### Target Structure (after this phase)
```
BeatStep/
  Models/
    RunZone.swift           # MODIFIED: selectedZoneIds: Set<Int>, mergedBPMRange computed property
    BPMTolerance.swift      # Unchanged model, new custom view
    RunMode.swift           # Unchanged
  Views/Run/
    RunTabView.swift        # MODIFIED: uses Set<Int>, displays merged BPM range, passes range to engine
    ZonePickerView.swift    # REBUILT: multi-select toggle grid with haptics and animations
    TolerancePicker.swift   # REBUILT: custom capsule selector (not stock Picker) with haptics
    ActiveRunView.swift     # MODIFIED: receives merged BPM range instead of single zoneId
```

### Pattern 1: Multi-Select Zone Toggle
**What:** Each zone capsule acts as an independent toggle (tap to add/remove from selection set). Visual state driven by `selectedZoneIds.contains(zone.id)`.
**When to use:** When user needs to select 0-N zones from a fixed set.
**Example:**
```swift
// Zone capsule as toggle with haptic feedback
Button {
    BSHaptics.selection()
    withAnimation(BSAnimation.snappy) {
        if selectedZoneIds.contains(zone.id) {
            selectedZoneIds.remove(zone.id)
        } else {
            selectedZoneIds.insert(zone.id)
        }
    }
} label: {
    ZoneCapsule(zone: zone, isSelected: selectedZoneIds.contains(zone.id))
}
```

### Pattern 2: Merged BPM Range Display
**What:** When multiple zones selected, compute and display the merged range from lowest zone floor to highest zone ceiling.
**When to use:** Whenever selectedZoneIds.count > 0.
**Example:**
```swift
// Computed merged range from selected zones
var mergedBPMRange: ClosedRange<Int>? {
    let selectedZones = RunZone.saved.filter { selectedZoneIds.contains($0.id) }
    guard !selectedZones.isEmpty else { return nil }
    let floor = selectedZones.map(\.bpm).min()!
    let ceiling = selectedZones.map(\.bpm).max()!
    return floor...ceiling
}
```

### Pattern 3: Custom Tolerance Selector (replacing stock Picker)
**What:** Three horizontally arranged capsules for tight/normal/loose, styled identically to zone capsules but single-select.
**When to use:** Replace stock `.pickerStyle(.segmented)` for visual cohesion with zone picker.
**Example:**
```swift
HStack(spacing: Spacing.sm) {
    ForEach(BPMTolerance.allCases, id: \.self) { level in
        Button {
            BSHaptics.selection()
            withAnimation(BSAnimation.snappy) {
                tolerance = level
            }
            level.save()
        } label: {
            Text(level.displayName)
                .font(.captionBold)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
                .background(Capsule().fill(tolerance == level ? Color.accent : Color.surfaceElevated))
                .foregroundStyle(tolerance == level ? Color.textOnAccent : Color.textSecondary)
        }
    }
}
```

### Anti-Patterns to Avoid
- **Stock SwiftUI Picker for tolerance:** Cannot receive haptic feedback on selection change reliably, and `.segmented` style doesn't match the custom capsule aesthetic. Use Button-based capsules instead.
- **Single targetBPM for multi-zone:** Don't pick an average or midpoint. The engine should use the merged floor-to-ceiling range for matching.
- **Storing selectedZoneIds as Array:** Use Set<Int> for O(1) contains checks and natural deduplication. Persist as sorted Array in UserDefaults.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Haptic feedback | Custom UIKit generator management | BSHaptics.selection() / .light() | Already built in Phase 27, handles generator lifecycle |
| Spring animations | Custom withAnimation(.spring(...)) | BSAnimation.snappy / .smooth | Tokens ensure consistent feel across app |
| Zone data persistence | New SwiftData model | RunZone.saveAll() + UserDefaults | Matches existing pattern, no migration needed |
| BPM range display | Complex range math | Simple min/max over selected zone BPMs | Zones are already ordered by BPM in defaults |

## Common Pitfalls

### Pitfall 1: UserDefaults Set<Int> Encoding
**What goes wrong:** UserDefaults doesn't natively store `Set<Int>`. Storing as-is fails silently.
**Why it happens:** Set is not a property list type.
**How to avoid:** Convert to `Array<Int>` before storing, convert back to `Set<Int>` on read. Use `UserDefaults.standard.set(Array(ids), forKey:)`.
**Warning signs:** selectedZoneIds always empty after app restart.

### Pitfall 2: RunEngineService Single Target BPM
**What goes wrong:** RunEngineService currently uses a single `targetBPM: Int` for guided mode matching. Multi-zone needs a range.
**Why it happens:** The engine was built for single-zone selection.
**How to avoid:** When starting a run with multiple zones, set `RunMode.savedTargetBPM` to the midpoint of the merged range. The tolerance already expands the matching window. Alternatively, compute the merged floor/ceiling and use `tolerance.range` on top of the outer edges. The simplest correct approach: use the midpoint BPM and widen tolerance to cover the full zone spread.
**Warning signs:** Songs only matching one zone's BPM during a multi-zone run.

### Pitfall 3: Free Mode vs Multi-Zone Confusion
**What goes wrong:** User selects zones but also expects "Free" to be available. The current single-select has a "Free" capsule.
**Why it happens:** Multi-select toggle means deselecting all zones = free mode. No explicit "Free" button needed if empty selection = free.
**How to avoid:** When `selectedZoneIds.isEmpty`, treat as free mode. Show a "Free" indicator or allow deselecting all zones to return to free mode. The "Free" capsule can remain as a "deselect all" action.
**Warning signs:** User can't return to free mode after selecting zones.

### Pitfall 4: Haptic Feedback Overload
**What goes wrong:** Too many or too strong haptics make the experience annoying.
**Why it happens:** Adding haptics to every interaction without consideration.
**How to avoid:** Use `BSHaptics.selection()` (lightest) for zone toggles and tolerance changes. Reserve `.light()` or `.medium()` for the Start Run button. Never use `.heavy()` or `.success()` for routine selections.
**Warning signs:** Haptics feel "buzzy" or distracting during normal interaction.

### Pitfall 5: ActiveRunView Signature Change
**What goes wrong:** ActiveRunView currently takes `selectedZoneId: Int?`. Changing to `Set<Int>` breaks the initializer.
**Why it happens:** The active run view displays zone name and target BPM derived from the single zone.
**How to avoid:** Update ActiveRunView to accept the merged BPM range (or selected zone IDs set). Derive display text from the zone set (e.g., "Z1-Z3" or "Recovery - Tempo"). Keep changes minimal -- the active run view mainly needs the target BPM, which becomes the midpoint of merged range.

## Code Examples

### Multi-Zone Selection Persistence
```swift
// In RunZone.swift -- add alongside existing selectedZoneId
private static let selectedIdsKey = "selectedRunZoneIds"

static var selectedZoneIds: Set<Int> {
    get {
        guard let array = UserDefaults.standard.array(forKey: selectedIdsKey) as? [Int] else {
            // Migration: read old single selectedZoneId
            if let single = selectedZoneId {
                return [single]
            }
            return []
        }
        return Set(array)
    }
    set {
        UserDefaults.standard.set(Array(newValue).sorted(), forKey: selectedIdsKey)
    }
}
```

### Merged BPM Range Computation
```swift
// In RunTabView or as RunZone static method
static func mergedBPMRange(for zoneIds: Set<Int>) -> ClosedRange<Int>? {
    let zones = saved.filter { zoneIds.contains($0.id) }
    guard let min = zones.map(\.bpm).min(),
          let max = zones.map(\.bpm).max() else { return nil }
    return min...max
}
```

### RunEngine Integration for Multi-Zone
```swift
// In RunTabView.startRun() -- replace single zone logic
if !selectedZoneIds.isEmpty {
    let zones = RunZone.saved.filter { selectedZoneIds.contains($0.id) }
    let floor = zones.map(\.bpm).min() ?? 160
    let ceiling = zones.map(\.bpm).max() ?? 160
    let midpoint = (floor + ceiling) / 2

    runEngine.runMode = .guided
    runEngine.tolerance = tolerance
    RunMode.savedTargetBPM = midpoint
} else {
    runEngine.runMode = .free
    runEngine.tolerance = tolerance
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Stock SwiftUI Picker (.segmented) | Custom Button-based capsules | This phase | Visual cohesion with zone picker |
| Single zone selection (Int?) | Multi-zone selection (Set<Int>) | This phase | Enables merged BPM range matching |
| No haptic feedback on Run tab | BSHaptics on every selection | Phase 27 (tokens), Phase 29 (integration) | Tactile confirmation of every action |

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | XCTest (built-in) |
| Config file | BeatStepTests target in Xcode project |
| Quick run command | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BeatStepTests` |
| Full suite command | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16'` |

### Phase Requirements -> Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| RUN-01 | Zone picker is custom component (not stock Picker) | manual-only | Visual inspection | N/A |
| RUN-01 | Tolerance selector is custom component | manual-only | Visual inspection | N/A |
| RUN-01 | Zone selection triggers haptic | manual-only | Haptics require device | N/A |
| RUN-02 | Multi-zone selectedZoneIds persistence round-trip | unit | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BeatStepTests/ZoneSelectionTests` | Exists (needs new test cases) |
| RUN-02 | Merged BPM range computes floor-to-ceiling | unit | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BeatStepTests/RunZoneTests` | Exists (needs new test cases) |
| RUN-02 | Empty zone selection = free mode | unit | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BeatStepTests/ZoneSelectionTests` | Exists (needs new test cases) |
| RUN-02 | Engine receives correct midpoint BPM for multi-zone | unit | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BeatStepTests/RunEngineServiceTests` | Exists (needs new test cases) |

### Sampling Rate
- **Per task commit:** Quick run on ZoneSelectionTests + RunZoneTests
- **Per wave merge:** Full test suite
- **Phase gate:** Full suite green before verify

### Wave 0 Gaps
- [ ] New test cases in `ZoneSelectionTests.swift` for multi-zone persistence (Set<Int> round-trip, empty set = free mode, migration from single Int?)
- [ ] New test cases in `RunZoneTests.swift` for `mergedBPMRange(for:)` computation
- [ ] No new test files needed -- extend existing test files

## Sources

### Primary (HIGH confidence)
- Codebase analysis: RunTabView.swift, ZonePickerView.swift, TolerancePicker.swift, RunZone.swift, BPMTolerance.swift, RunEngineService.swift, BSHaptics.swift, BSAnimation.swift, DesignTokens.swift
- Existing test files: RunZoneTests.swift, ZoneSelectionTests.swift, BPMToleranceTests.swift

### Secondary (MEDIUM confidence)
- Apple UIKit documentation: UIImpactFeedbackGenerator, UISelectionFeedbackGenerator (stable API since iOS 10)
- SwiftUI Button + custom styling patterns (standard iOS 17 approach)

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - all libraries already in use in the project
- Architecture: HIGH - clear path from single-select to multi-select, all integration points identified
- Pitfalls: HIGH - identified from direct codebase analysis (UserDefaults encoding, engine integration, ActiveRunView signature)

**Research date:** 2026-03-26
**Valid until:** 2026-04-26 (stable -- no external dependency changes expected)
