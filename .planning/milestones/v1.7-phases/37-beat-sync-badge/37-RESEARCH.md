# Phase 37: Beat Sync Badge - Research

**Researched:** 2026-03-27
**Domain:** SwiftUI view evolution, tempo normalization algorithm, SF Symbols
**Confidence:** HIGH

## Summary

This phase evolves the existing `SyncBadge` in `RunStatusBar.swift` to include SF Symbol icons alongside text labels, adds half/double-tempo normalization to `SyncQuality.from()`, and removes redundant sync quality display from `CadenceDisplayView`. The codebase is well-structured for these changes -- all touch points are identified and the existing capsule badge pattern from Phase 19 provides a direct template.

The key technical challenge is the tempo normalization algorithm: `SyncQuality.from(delta:tolerance:)` currently receives a pre-computed `cadenceDelta` from `RunEngineService` that does not account for half/double-tempo track matches. The normalization must compare SPM against both 0.5x and 2x of the track BPM and use the smallest delta. This logic should live in `SyncQuality.from()` (or a helper it calls) so the rest of the system continues using raw values.

**Primary recommendation:** Three focused tasks -- (1) add tempo normalization to SyncQuality model + tests, (2) evolve SyncBadge with SF Symbol icons, (3) remove sync display from CadenceDisplayView.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Evolve the existing `SyncBadge` in `RunStatusBar.swift` -- add an SF Symbol icon left of the existing text label inside the capsule: `[icon In Sync]`. Same capsule pattern as Phase 19 confidence badges (icon + text + color fill at 15% opacity).
- **D-02:** Keep text labels ("In Sync", "Drifting", "Mismatched") alongside icons -- unambiguous at a running glance.
- **D-03:** Waveform SF Symbol set: inSync: `waveform.path.ecg`, drifting: `waveform.badge.minus`, mismatched: `waveform.slash`
- **D-04:** Normalize SPM against track BPM before computing sync delta. Check if SPM is ~2x or ~0.5x the track BPM; if so, compare against the normalized value.
- **D-05:** Support half (0.5x) and double (2x) tempo multiples only.
- **D-06:** Normalization happens inside `SyncQuality.from(delta:tolerance:)` or a helper it calls.
- **D-07:** Keep the badge in `RunStatusBar` (top-right). No relocation.
- **D-08:** Remove sync quality color and label from `CadenceDisplayView`. Cadence display shows just the number and trend arrow.

### Claude's Discretion
- Exact normalization algorithm (pick closest multiple, or try both and use smaller delta)
- Icon sizing relative to `.labelText` font
- Whether normalization is a static method on `SyncQuality` or a standalone helper
- Animation behavior when sync quality changes (existing `BSAnimation.gentle` may suffice)
- How to handle the edge case where no track is playing (badge state when BPM is unavailable)

### Deferred Ideas (OUT OF SCOPE)
None -- discussion stayed within phase scope
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| SYNC-01 | Run screen shows a beat sync confidence badge reflecting how closely SPM matches current track BPM | SyncBadge evolution with SF Symbol + text + capsule pattern; tempo normalization ensures correct quality for half/double-tempo tracks |
| SYNC-02 | Badge updates reactively as cadence or track changes | RunEngineService.syncQuality is already a computed property on @Observable class; SwiftUI reactivity handles updates automatically |
</phase_requirements>

## Architecture Patterns

### Current Data Flow (unchanged by this phase)
```
CadenceService.currentSPM
    --> RunEngineService.latestCadence (polled every 2s)
    --> RunEngineService.adjustedCadence (applies TempoMode)
    --> RunEngineService.cadenceDelta (adjustedCadence - trackBPM)
    --> RunEngineService.syncQuality (SyncQuality.from(delta:tolerance:))
    --> ActiveRunView observes runEngine.syncQuality
        --> RunStatusBar.SyncBadge(quality:)
        --> CadenceDisplayView (D-08: remove this dependency)
```

### Normalization Strategy (Recommended)

The current `cadenceDelta` is `adjustedCadence - trackBPM` (line 108 of RunEngineService). This does NOT account for a track at 80 BPM matching a runner at 160 SPM.

**Recommended approach: Expand `SyncQuality.from()` signature.**

Change `SyncQuality.from(delta:tolerance:)` to `SyncQuality.from(spm:trackBPM:tolerance:)`. This lets the factory method internally compute the normalized delta by trying the raw BPM, 0.5x, and 2x, then picking the smallest absolute delta. The `cadenceDelta` computed property in RunEngineService then passes raw values and the normalization is encapsulated.

Alternative: Keep the `delta`-based signature and add a separate `normalizedDelta(spm:trackBPM:)` static method that RunEngineService calls before passing to `from()`. This keeps the factory method pure but splits the logic.

**Recommendation:** Use the expanded signature approach. It is simpler, keeps normalization co-located with the quality computation, and matches D-06 ("normalization happens inside `SyncQuality.from()` or a helper it calls").

```swift
// Recommended new factory method
static func from(spm: Int, trackBPM: Int, tolerance: BPMTolerance) -> SyncQuality {
    let candidates = [trackBPM, trackBPM * 2, trackBPM / 2].filter { $0 > 0 }
    let bestDelta = candidates.map { abs(spm - $0) }.min() ?? abs(spm - trackBPM)

    let range = tolerance.range
    if bestDelta <= range {
        return .inSync
    } else if bestDelta <= range * 2 {
        return .drifting
    } else {
        return .mismatched
    }
}
```

**Key insight:** We compare SPM against `[trackBPM, trackBPM*2, trackBPM/2]`, NOT `[spm, spm/2, spm*2]` against trackBPM. This matches how `findMatchingTracks` works (line 228: `let targets = [spm, spm / 2, spm * 2]` -- it checks if trackBPM is near any of those, which is mathematically equivalent). Either direction works, but comparing against multiples of trackBPM is clearer for the sync quality context.

### SyncBadge Evolution Pattern

Current SyncBadge (RunStatusBar.swift:26-41):
```swift
private struct SyncBadge: View {
    let quality: SyncQuality
    var body: some View {
        Text(quality.displayLabel)
            .font(.labelText)
            .foregroundStyle(quality.color)
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xxs)
            .background(Capsule().fill(quality.color.opacity(0.15)))
            .animation(BSAnimation.gentle, value: quality)
    }
}
```

Target pattern (icon + text in HStack):
```swift
private struct SyncBadge: View {
    let quality: SyncQuality
    var body: some View {
        HStack(spacing: Spacing.xxs) {
            Image(systemName: quality.iconName)
            Text(quality.displayLabel)
        }
        .font(.labelText)
        .foregroundStyle(quality.color)
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xxs)
        .background(Capsule().fill(quality.color.opacity(0.15)))
        .animation(BSAnimation.gentle, value: quality)
    }
}
```

### CadenceDisplayView Simplification (D-08)

Remove:
1. The `syncQuality` parameter entirely
2. The `else` branch showing `syncQuality.displayLabel` in free mode (lines 26-29)
3. The `.foregroundStyle(syncQuality.color)` on the SPM number (line 16) -- replace with a neutral color

Keep:
1. `cadenceDelta` and `isGuidedMode` for the delta label in guided mode
2. Trend arrow (independent of sync quality)
3. The SPM number display

**Decision needed for Claude's discretion:** What color should the SPM number use after removing syncQuality color? Options:
- `Color.textPrimary` (white) -- clean, lets the badge be the sole sync indicator
- Keep passing syncQuality just for the number color but remove the label -- partial cleanup

**Recommendation:** Use `Color.textPrimary` for the SPM number. This matches D-08's intent ("the big number should stand alone") and makes the badge the single source of sync info.

### No-Track Edge Case

When no track is playing (`currentMatchedTrack == nil`), `cadenceDelta` returns 0 and `syncQuality` returns `.inSync`. This is misleading.

**Recommendation:** Either hide the badge when no track is playing, or add a `.noTrack` display state. Hiding is simpler and aligns with "the badge shows sync quality between SPM and track BPM" -- if there is no track, there is no sync to show.

Implementation: `RunStatusBar` already receives `syncQuality`. Add an optional `isTrackPlaying: Bool` parameter, or make the badge visibility conditional in `ActiveRunView`.

### File Changes Summary

| File | Change |
|------|--------|
| `BeatStep/Models/SyncQuality.swift` | Add `iconName` computed property, add/modify `from()` with normalization |
| `BeatStep/Views/Run/RunStatusBar.swift` | Evolve `SyncBadge` to HStack with icon + text |
| `BeatStep/Views/Run/CadenceDisplayView.swift` | Remove `syncQuality` param, remove sync label, use neutral color |
| `BeatStep/Views/Run/ActiveRunView.swift` | Update `CadenceDisplayView` call site (remove syncQuality arg), update `RunEngineService.syncQuality` call |
| `BeatStep/Services/RunEngineService.swift` | Update `syncQuality` computed property to pass spm + trackBPM |
| `BeatStepTests/SyncQualityTests.swift` | Add normalization tests (half-tempo, double-tempo, edge cases) |
| `BeatStepTests/CadenceDisplayTests.swift` | Update tests for removed syncQuality dependency |

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Tempo normalization | Custom BPM ratio detection | Simple min-delta over [1x, 0.5x, 2x] candidates | Covers all practical running cadence ranges (140-190 SPM) |
| Icon rendering | Custom icon views | SF Symbols via `Image(systemName:)` | System-consistent, auto-scales with Dynamic Type |
| Badge animation | Custom animation timing | `BSAnimation.gentle` (already used) | Established token, 0.3s easeInOut |

## Common Pitfalls

### Pitfall 1: SF Symbol Name Typos
**What goes wrong:** SF Symbol renders as empty/invisible if name is wrong. No compile-time error.
**Why it happens:** SF Symbol names are stringly typed.
**How to avoid:** Verify each symbol name in the SF Symbols Mac app before implementation. The names from D-03 (`waveform.path.ecg`, `waveform.badge.minus`, `waveform.slash`) need runtime verification -- I could not confirm `waveform.badge.minus` exists in SF Symbols via web sources. It may be `waveform.path.badge.minus` instead.
**Warning signs:** Badge renders with text but no icon, or layout shifts unexpectedly.

### Pitfall 2: Normalization Double-Application
**What goes wrong:** If normalization is applied in both `RunEngineService.cadenceDelta` and `SyncQuality.from()`, the delta gets double-normalized.
**Why it happens:** The `adjustedCadence` property already applies TempoMode (half-tempo for cadence). The new normalization checks track BPM multiples. These are different concerns but could interact.
**How to avoid:** The new `SyncQuality.from(spm:trackBPM:tolerance:)` should receive `adjustedCadence` (TempoMode-adjusted) and raw `trackBPM`. TempoMode adjusts the runner's cadence; normalization adjusts the track BPM comparison. Keep them separate.
**Warning signs:** Runner at 160 SPM with TempoMode=half and track at 80 BPM gets wrong quality.

### Pitfall 3: CadenceDisplayView Free Mode Shows Nothing
**What goes wrong:** After removing the sync label from free mode, the space between the SPM number and "SPM" label is empty.
**Why it happens:** The current layout has a `Group` that shows either `deltaLabel` (guided) or `syncQuality.displayLabel` (free). Removing the free-mode content leaves a gap.
**How to avoid:** Either remove the `Group` entirely in free mode (collapse the spacing) or show the delta label in both modes.
**Warning signs:** Empty vertical space in the cadence display during free mode runs.

### Pitfall 4: Division by Zero in Normalization
**What goes wrong:** If `trackBPM` is 0 (possible for unanalyzed tracks), `trackBPM / 2` produces 0 and the normalization candidates include 0.
**How to avoid:** Filter candidates to `> 0`, or guard early with `guard trackBPM > 0`.

## Code Examples

### SyncQuality.iconName Property
```swift
// Add to SyncQuality.swift
var iconName: String {
    switch self {
    case .inSync: return "waveform.path.ecg"      // Verify in SF Symbols app
    case .drifting: return "waveform.badge.minus"   // Verify -- may be waveform.path.badge.minus
    case .mismatched: return "waveform.slash"       // Verify in SF Symbols app
    }
}
```

### Updated RunEngineService.syncQuality
```swift
// Replace current computed property (line 112)
var syncQuality: SyncQuality {
    guard let trackBPM = currentTrackBPM else { return .inSync } // or handle no-track case
    return SyncQuality.from(spm: adjustedCadence, trackBPM: trackBPM, tolerance: tolerance)
}
```

### Simplified CadenceDisplayView
```swift
struct CadenceDisplayView: View {
    let spm: Int
    let trend: CadenceTrend
    let cadenceDelta: Int
    let isGuidedMode: Bool

    var body: some View {
        VStack(spacing: Spacing.xs) {
            HStack(alignment: .firstTextBaseline, spacing: Spacing.md) {
                Text("\(spm)")
                    .font(.displaySPM)
                    .foregroundStyle(Color.textPrimary)
                trendArrow
            }

            if isGuidedMode {
                deltaLabel
            }

            Text("SPM")
                .font(.displaySecondary)
                .foregroundStyle(Color.textSecondary)
        }
    }
    // ... trendArrow and deltaLabel unchanged
}
```

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | XCTest (built-in) |
| Config file | Xcode project (BeatStepTests target) |
| Quick run command | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BeatStepTests/SyncQualityTests -quiet` |
| Full suite command | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' -quiet` |

### Phase Requirements -> Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| SYNC-01 | Normalization picks smallest delta across 1x/0.5x/2x | unit | `xcodebuild test ... -only-testing:BeatStepTests/SyncQualityTests` | Exists but needs new tests |
| SYNC-01 | Badge shows icon + text + correct color per quality tier | manual | Visual inspection in Xcode previews | N/A |
| SYNC-02 | syncQuality updates when cadence changes | unit | `xcodebuild test ... -only-testing:BeatStepTests/SyncQualityTests` | Exists but needs new tests |
| SYNC-02 | syncQuality updates when track changes | unit | RunEngineService computed property test | Exists |

### Sampling Rate
- **Per task commit:** `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BeatStepTests/SyncQualityTests -quiet`
- **Per wave merge:** Full test suite
- **Phase gate:** Full suite green before verification

### Wave 0 Gaps
- [ ] `BeatStepTests/SyncQualityTests.swift` -- add normalization tests (half-tempo inSync, double-tempo inSync, raw-tempo still works, zero BPM guard)
- [ ] `BeatStepTests/CadenceDisplayTests.swift` -- update for removed syncQuality parameter

## Open Questions

1. **SF Symbol name verification for `waveform.badge.minus`**
   - What we know: `waveform` base symbol exists in the codebase; `waveform.path.ecg` is well-known. `waveform.badge.minus` could not be confirmed via web sources.
   - What's unclear: Whether the exact name is `waveform.badge.minus` or `waveform.path.badge.minus`
   - Recommendation: Verify in SF Symbols Mac app before implementation. If `waveform.badge.minus` does not exist, use `waveform.path.badge.minus` or `waveform.badge.exclamationmark` as fallback.

2. **CadenceDisplayView free mode content after removing sync label**
   - What we know: Currently shows sync quality label in free mode; D-08 removes it
   - What's unclear: Whether to show nothing (collapse space) or show delta in both modes
   - Recommendation: Show nothing in free mode (no delta, no sync label). The SPM number + trend arrow + "SPM" label is sufficient. Collapse the Group.

3. **No-track badge state**
   - What we know: When no track is playing, cadenceDelta is 0, syncQuality is .inSync (misleading)
   - Recommendation: Hide the SyncBadge when `currentMatchedTrack` is nil. Simple conditional in RunStatusBar or ActiveRunView.

## Sources

### Primary (HIGH confidence)
- `BeatStep/Models/SyncQuality.swift` -- current 3-tier enum with factory method
- `BeatStep/Views/Run/RunStatusBar.swift` -- current SyncBadge implementation
- `BeatStep/Views/Run/CadenceDisplayView.swift` -- current sync quality display
- `BeatStep/Services/RunEngineService.swift` -- cadenceDelta and syncQuality computed properties
- `BeatStep/DesignSystem/DesignTokens.swift` -- font tokens, spacing, color tokens
- `BeatStep/DesignSystem/BSAnimation.swift` -- animation tokens

### Secondary (MEDIUM confidence)
- [SF Symbols - Apple Developer](https://developer.apple.com/sf-symbols/) -- symbol availability for iOS 17+
- [SF Symbols Online Browser](https://github.com/andrewtavis/sf-symbols-online) -- partial symbol name verification

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- all changes are within existing SwiftUI/SF Symbols patterns already used in the codebase
- Architecture: HIGH -- data flow is well-understood, touch points are identified, normalization algorithm is straightforward
- Pitfalls: HIGH -- all identified from direct code reading; SF Symbol name verification is the only LOW-confidence item

**Research date:** 2026-03-27
**Valid until:** 2026-04-27 (stable -- iOS/SwiftUI patterns, no fast-moving dependencies)
