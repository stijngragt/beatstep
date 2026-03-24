# Phase 11: Run Experience - Research

**Researched:** 2026-03-24
**Domain:** SwiftUI view replacement and run mode unification
**Confidence:** HIGH

## Summary

Phase 11 replaces two separate run configuration components (ModePicker and PacePresetPicker) with a single unified ZonePickerView that presents Zone 1-5 and Free as capsule buttons in a horizontal scroll. It also restructures RunTabView to pin a full-width Start Run CTA at the bottom and conditionally show the TolerancePicker. The RunZone model already exists with persistence, display labels, and user-customizable BPM values -- the work is purely UI replacement and wiring.

The key insight is that selecting a zone maps directly to existing RunEngineService parameters: selecting Z1-Z5 sets `runMode = .guided` and `RunMode.savedTargetBPM = zone.bpm`, while selecting Free sets `runMode = .free`. No engine changes needed. The PacePreset enum, PacePresetPicker, and ModePicker become dead code and should be removed.

**Primary recommendation:** Build a new ZonePickerView modeled on PacePresetPicker's capsule pattern, add selected-zone persistence to UserDefaults, rewire RunTabView layout with pinned CTA, then clean up removed components and their tests.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- Horizontal scroll of capsule buttons -- same pattern as current PacePresetPicker
- Replaces BOTH PacePresetPicker AND ModePicker -- single unified picker
- Zone capsules show "Z1 Recovery" on first line, BPM value ("155") on second line
- "Free" is a capsule in the same picker alongside Z1-Z5, styled identically but without BPM subtitle
- BPM values reflect user-customized values from Settings (RunZone.saved), not hardcoded defaults
- Selected capsule uses surfaceOverlay fill (brighter); unselected uses surfaceElevated
- No hero BPM display
- Selected zone persists between launches via UserDefaults
- Full-width Start Run button pinned to bottom of RunTabView (always visible, not scrolling)
- Accent red (#FF4545) background -- matches brand, not green
- Only visible when a previous playlist exists (LastRunPlaylist)
- When no playlist: hide CTA, show "Select a playlist from Library to start" message
- RunView's existing full-width green Start Run button unchanged
- "Free" is a zone option in the unified picker -- no separate Free/Guided toggle
- Selecting Free = free run (no target BPM), selecting Z1-Z5 = guided run at zone BPM
- ModePicker component removed
- PacePresetPicker component removed
- Tolerance picker appears on RunTabView below zone picker when Z1-Z5 is selected
- Hidden when Free is selected

### Claude's Discretion
- Exact zone picker component implementation (new ZonePickerView or refactor PacePresetPicker)
- How to map zone selection to existing RunEngineService parameters (runMode + targetBPM)
- Whether to deprecate or delete PacePreset enum
- Animation/transition when tolerance picker shows/hides based on zone selection
- Layout spacing between cover art, zone picker, tolerance picker, and CTA

### Deferred Ideas (OUT OF SCOPE)
None
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| RUN-01 | User selects a running zone (Zone 1-5 or Free) instead of effort labels | ZonePickerView replaces PacePresetPicker+ModePicker; RunZone model already provides displayLabel and persisted BPM values |
| RUN-02 | User sees a full-width Run CTA at the bottom of the Run tab | RunTabView restructured with pinned bottom CTA using Color.accent (#FF4545), conditionally shown based on LastRunPlaylist.name |
</phase_requirements>

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| SwiftUI | iOS 17+ | All UI components | Project standard; @Observable pattern already used |
| UserDefaults | Foundation | Zone selection persistence | Consistent with RunZone, RunMode, BPMTolerance patterns |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| XCTest | Built-in | Unit tests for zone selection model | Testing zone-to-runMode mapping logic |

No new dependencies required. Everything uses existing framework capabilities.

## Architecture Patterns

### Recommended Project Structure
```
BeatStep/
├── Models/
│   ├── RunZone.swift          # EXISTS - add selectedZone persistence
│   ├── RunMode.swift          # EXISTS - no changes needed
│   ├── PacePreset.swift       # DELETE after migration
│   └── BPMTolerance.swift     # EXISTS - no changes
├── Views/Run/
│   ├── ZonePickerView.swift   # NEW - unified zone + free picker
│   ├── RunTabView.swift       # MODIFY - new layout with pinned CTA
│   ├── RunView.swift          # MODIFY - use zone selection, remove ModePicker/PacePresetPicker
│   ├── TolerancePicker.swift  # EXISTS - no changes (moved to RunTabView context)
│   ├── ModePicker.swift       # DELETE
│   └── PacePresetPicker.swift # DELETE
└── Services/
    └── RunEngineService.swift # NO CHANGES - receives runMode + targetBPM as before
```

### Pattern 1: Zone Selection Model
**What:** Extend RunZone with a static `selectedZone` property persisted to UserDefaults. Use an enum or Int to represent the selection, where `nil` or a sentinel value (e.g., 0) means "Free".
**When to use:** Whenever the selected zone needs to be read or written.
**Example:**
```swift
// Add to RunZone.swift
extension RunZone {
    private static let selectedKey = "selectedRunZoneId"

    /// Returns the selected zone ID, or nil for Free mode.
    static var selectedZoneId: Int? {
        get {
            let value = UserDefaults.standard.integer(forKey: selectedKey)
            return value > 0 ? value : nil  // 0 = Free
        }
        set {
            UserDefaults.standard.set(newValue ?? 0, forKey: selectedKey)
        }
    }
}
```

### Pattern 2: Zone-to-RunEngine Mapping
**What:** When a zone is selected, derive `RunMode` and `targetBPM` from it. Free = `.free`, Z1-Z5 = `.guided` with zone BPM.
**When to use:** At run start (in RunView's start button action) and when persisting selection.
**Example:**
```swift
// In RunView or wherever startRun is triggered:
if let zoneId = RunZone.selectedZoneId,
   let zone = RunZone.saved.first(where: { $0.id == zoneId }) {
    runEngine.runMode = .guided
    RunMode.savedTargetBPM = zone.bpm
} else {
    runEngine.runMode = .free
}
```

### Pattern 3: Pinned Bottom CTA Layout
**What:** Use a VStack with Spacer or a ZStack with .bottom alignment to pin the CTA button, keeping it outside any ScrollView.
**When to use:** RunTabView layout restructure.
**Example:**
```swift
// RunTabView lastRunContent pattern:
VStack(spacing: 0) {
    // Scrollable content area
    ScrollView {
        VStack(spacing: Spacing.lg) {
            // Cover art
            // Playlist name
            // Zone picker
            // Tolerance picker (conditional)
        }
    }

    // Pinned CTA at bottom -- outside ScrollView
    Button { /* start run */ } label: {
        Text("Start Run")
            .font(.title3.weight(.bold))
            .foregroundStyle(Color.textOnAccent)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Radius.lg)
                    .fill(Color.accent)
            )
    }
    .padding(.horizontal, Spacing.xl)
    .padding(.bottom, Spacing.md)
}
```

### Pattern 4: Capsule Button with Two Lines
**What:** Zone capsule buttons show displayLabel on line 1 and BPM on line 2. Reuse PacePresetPicker's capsule styling pattern.
**Example:**
```swift
private func zoneButton(_ zone: RunZone, isSelected: Bool) -> some View {
    Button {
        selectedZoneId = zone.id
    } label: {
        VStack(spacing: Spacing.xxs) {
            Text(zone.displayLabel)
                .font(.captionBold)
            Text("\(zone.bpm)")
                .font(.labelText)
                .foregroundStyle(Color.textSecondary)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(
            Capsule().fill(
                isSelected ? Color.surfaceOverlay : Color.surfaceElevated
            )
        )
        .foregroundStyle(isSelected ? Color.textPrimary : Color.textSecondary)
    }
}

// Free button -- same style, no BPM subtitle
private func freeButton(isSelected: Bool) -> some View {
    Button {
        selectedZoneId = nil
    } label: {
        Text("Free")
            .font(.captionBold)
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(
                Capsule().fill(
                    isSelected ? Color.surfaceOverlay : Color.surfaceElevated
                )
            )
            .foregroundStyle(isSelected ? Color.textPrimary : Color.textSecondary)
    }
}
```

### Anti-Patterns to Avoid
- **Modifying RunEngineService:** Zones are a UI-layer concept that maps to existing `runMode` + `targetBPM`. Do not add zone awareness to the engine.
- **Hardcoding BPM values in the picker:** Always read from `RunZone.saved` so user customizations from Settings are reflected.
- **Keeping PacePreset alive:** Delete it cleanly rather than leaving dead code. The zone model fully replaces its function.
- **Putting the CTA inside a ScrollView:** The CTA must always be visible/accessible, so it must be outside any scrolling container.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Zone data with defaults and persistence | Custom struct from scratch | Extend existing `RunZone` model | Already has persistence, display labels, defaults |
| Capsule button styling | New button style | Copy PacePresetPicker's pattern verbatim | Proven pattern, matches design system |
| Run mode determination | Complex zone-to-mode logic | Simple if/else on selectedZoneId | Free = nil, anything else = guided with zone.bpm |

## Common Pitfalls

### Pitfall 1: Forgetting to update RunMode.savedTargetBPM on zone change
**What goes wrong:** User selects a zone on RunTabView but the BPM isn't persisted, so RunView/RunEngine uses stale value.
**Why it happens:** Zone selection and BPM persistence are in different models.
**How to avoid:** When zone selection changes, immediately write `RunMode.savedTargetBPM = zone.bpm` and `RunMode.guided.save()`. When Free is selected, save `RunMode.free.save()`.
**Warning signs:** BPM mismatch between zone picker display and actual run behavior.

### Pitfall 2: RunView still referencing PacePresetPicker after deletion
**What goes wrong:** Build errors after removing PacePresetPicker and ModePicker from RunView.
**Why it happens:** RunView.idleView currently uses both ModePicker and PacePresetPicker.
**How to avoid:** RunView.idleView must be updated to read from persisted zone selection instead. It should show the selected zone info (read-only or via ZonePickerView) rather than the old pickers.
**Warning signs:** Compile errors referencing deleted types.

### Pitfall 3: Free capsule vertical alignment with zone capsules
**What goes wrong:** Free capsule (single line) is shorter than zone capsules (two lines), creating visual misalignment.
**Why it happens:** Free has no BPM subtitle.
**How to avoid:** Use `.frame(minHeight:)` or add vertical padding to match zone capsule height. Alternatively, match the VStack structure with an invisible spacer.
**Warning signs:** Capsules at different heights in the horizontal scroll.

### Pitfall 4: Tolerance picker appearing/disappearing abruptly
**What goes wrong:** Jarring layout shift when switching between Free and a zone.
**Why it happens:** No animation on the conditional show/hide.
**How to avoid:** Wrap the tolerance picker in `if selectedZoneId != nil` with `.animation(.easeInOut(duration: 0.2), value: selectedZoneId)` on the parent container.
**Warning signs:** Content jumping without smooth transition.

### Pitfall 5: Start Run navigation from RunTabView
**What goes wrong:** The CTA button on RunTabView needs to navigate to RunView with the last playlist's data, but RunTabView doesn't have the tracks.
**Why it happens:** RunTabView only stores LastRunPlaylist metadata (name, id, imageURL), not the track list.
**How to avoid:** The CTA likely needs to load playlist tracks or navigate through the existing Library flow. Check how the current start flow works -- RunView receives `playlist` and `tracks` as parameters. The RunTabView CTA may need to fetch tracks or use a stored playlist reference. **This is the trickiest integration point.**
**Warning signs:** CTA button with no navigation action or crashing on tap.

## Code Examples

### ZonePickerView (complete component)
```swift
struct ZonePickerView: View {
    @Binding var selectedZoneId: Int?  // nil = Free

    private var zones: [RunZone] { RunZone.saved }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.sm) {
                // Zone capsules
                ForEach(zones) { zone in
                    zoneButton(zone, isSelected: selectedZoneId == zone.id)
                }
                // Free capsule
                freeButton(isSelected: selectedZoneId == nil)
            }
            .padding(.horizontal, Spacing.xs)
        }
    }

    // ... button implementations from Pattern 4 above
}
```

### RunTabView restructured layout (lastRunContent)
```swift
private func lastRunContent(name: String) -> some View {
    VStack(spacing: 0) {
        // Scrollable content
        VStack(spacing: Spacing.lg) {
            // Cover art (existing)
            // Playlist name (existing)
            // "Your last playlist" hint (existing)

            // Zone picker (NEW)
            ZonePickerView(selectedZoneId: $selectedZoneId)

            // Tolerance picker -- only when zone selected (NEW location)
            if selectedZoneId != nil {
                TolerancePicker(tolerance: $tolerance)
                    .padding(.horizontal, Spacing.xl)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }

        Spacer()

        // Pinned CTA (NEW -- full width, accent red)
        Button { /* navigate to RunView */ } label: {
            Text("Start Run")
                .font(.title3.weight(.bold))
                .foregroundStyle(Color.textOnAccent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: Radius.lg)
                        .fill(Color.accent)  // #FF4545
                )
        }
        .padding(.horizontal, Spacing.xl)
        .padding(.bottom, Spacing.md)
    }
    .animation(.easeInOut(duration: 0.2), value: selectedZoneId)
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| PacePreset enum (Easy Jog, Steady, etc.) | RunZone model (Z1-Z5 with custom BPM) | Phase 10 (v1.2) | Zones are user-customizable, fitness-aligned |
| Separate ModePicker + PacePresetPicker | Unified ZonePickerView | Phase 11 (this phase) | Single interaction point; Free is a zone option |
| Capsule "Start Run" button | Full-width pinned CTA | Phase 11 (this phase) | More prominent, always accessible |

**Deprecated/outdated after this phase:**
- `PacePreset` enum: replaced by `RunZone` model -- DELETE
- `PacePresetPicker`: replaced by `ZonePickerView` -- DELETE
- `ModePicker`: Free/Guided toggle absorbed into zone picker -- DELETE
- `PacePresetTests.swift`: DELETE with the enum

## Open Questions

1. **RunTabView CTA navigation to RunView**
   - What we know: RunView requires `playlist: SpotifyPlaylist` and `tracks: [SpotifyTrack]` as init parameters. RunTabView only has `LastRunPlaylist` metadata (name, id, imageURL).
   - What's unclear: How does the CTA button navigate to RunView with the required data? Does it need to fetch the playlist/tracks from Spotify API first?
   - Recommendation: The CTA button action should re-fetch the playlist by ID from SpotifyAPIService, matching what the Library flow does. Or treat the CTA as non-functional for now (note says "non-functional per Phase 7 decision") and defer full navigation wiring. Check the current RunView navigation flow from Library tab for reference.

2. **RunView idle state after zone migration**
   - What we know: RunView.idleView currently shows ModePicker and conditional PacePresetPicker. These are being removed.
   - What's unclear: Should RunView still show a zone picker in its idle state, or just show the selected zone as read-only info?
   - Recommendation: RunView idle state should show the selected zone label (read-only) since zone selection now happens on RunTabView. The tolerance picker can remain on RunView for last-minute adjustment, or it can be removed from RunView since it's now on RunTabView.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | XCTest (built-in) |
| Config file | Xcode project test target (BeatStepTests) |
| Quick run command | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BeatStepTests 2>&1 \| tail -20` |
| Full suite command | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 \| tail -40` |

### Phase Requirements to Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| RUN-01 | Zone selection persists and maps to runMode+targetBPM | unit | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BeatStepTests/RunZoneTests -only-testing:BeatStepTests/ZoneSelectionTests` | Partially (RunZoneTests exists; ZoneSelectionTests needed) |
| RUN-02 | CTA visibility conditional on LastRunPlaylist | unit | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BeatStepTests/LastRunPlaylistTests` | Yes (LastRunPlaylistTests exists) |

### Sampling Rate
- **Per task commit:** Run RunZoneTests + any new zone selection tests
- **Per wave merge:** Full test suite
- **Phase gate:** Full suite green before verify

### Wave 0 Gaps
- [ ] `BeatStepTests/ZoneSelectionTests.swift` -- covers selectedZoneId persistence, zone-to-runMode mapping, Free mode selection
- [ ] Verify PacePresetTests.swift can be safely deleted after PacePreset enum removal (no other code references it)

## Sources

### Primary (HIGH confidence)
- Direct codebase inspection of all relevant files:
  - `RunTabView.swift` -- current layout and LastRunPlaylist usage
  - `PacePresetPicker.swift` -- capsule button pattern to replicate
  - `ModePicker.swift` -- component to be removed
  - `RunZone.swift` -- zone model with persistence
  - `RunMode.swift` -- free/guided enum with savedTargetBPM
  - `RunView.swift` -- current idle state with ModePicker + PacePresetPicker
  - `RunEngineService.swift` -- targetBPM read from RunMode.savedTargetBPM
  - `DesignTokens.swift` -- Color.accent is #FF4545, all spacing/radius tokens
  - `TolerancePicker.swift` -- existing segmented control
  - `BPMTolerance.swift` -- persistence pattern
  - `LastRunPlaylist.swift` -- name/id/imageURL persistence

### Secondary (MEDIUM confidence)
- None needed -- all patterns are established in the existing codebase

### Tertiary (LOW confidence)
- None

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- pure SwiftUI with existing patterns, no new dependencies
- Architecture: HIGH -- direct codebase analysis, all integration points verified
- Pitfalls: HIGH -- identified from actual code structure and data flow analysis

**Research date:** 2026-03-24
**Valid until:** 2026-04-24 (stable -- internal codebase, no external dependency changes)
