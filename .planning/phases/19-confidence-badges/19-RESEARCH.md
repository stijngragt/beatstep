# Phase 19: Confidence Badges - Research

**Researched:** 2026-03-25
**Domain:** SwiftUI view layer -- confidence-aware BPM badges
**Confidence:** HIGH

## Summary

Phase 19 is a purely visual/UI phase that consumes the data model established in Phase 18. The `BPMConfidence` enum and `CachedBPM.confidence` computed property already exist. The work is: (1) plumb confidence data from `BPMCacheService` through `PlaylistDetailView` to `TrackRow`, and (2) render the correct icon + color per confidence level inside the existing capsule badge pattern.

The existing `getBPM(forTrackID:)` returns only `Int?`, so a new service method is needed to return both BPM and confidence together. The `bpmCache` dictionary type in `PlaylistDetailView` must change from `[String: Int?]` to carry confidence. `TrackRow` needs a confidence parameter added to its init.

**Primary recommendation:** Add a lightweight `BPMInfo` struct (bpm: Int?, confidence: BPMConfidence?) as the return type of a new service method, change `bpmCache` to `[String: BPMInfo]`, and switch on confidence in TrackRow to select icon/color.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- Confidence icon sits inside the existing BPM capsule, left of the BPM text: `[icon X BPM]`
- Single compact element per track row -- no separate icon outside the capsule
- No-BPM tracks also get a capsule (muted) for consistent row alignment
- Verified: green (reuse `stateSuccess` token)
- Manual: yellow (reuse `stateWarning` token)
- Approximate: blue (new token -- subtle blue tone for "inferred/heuristic")
- No BPM: gray capsule at ~35% opacity (dim but same shape)
- SF Symbol icons: `checkmark.seal.fill` (verified), `hand.raised.fill` (manual), `tilde` (approximate)
- No BPM: no icon, just `-- BPM` text in muted gray
- No action hint yet (Phase 20 adds tap BPM interaction)

### Claude's Discretion
- Data plumbing approach (how confidence reaches TrackRow -- tuple, struct, or direct CachedBPM access)
- Exact blue color token value for approximate confidence
- Icon sizing relative to labelText font
- Exact capsule padding adjustments for icon + text
- Whether to show the approximate badge now (enum exists but no source maps to it yet) or defer rendering

### Deferred Ideas (OUT OF SCOPE)
None -- discussion stayed within phase scope.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| CONF-03 | Playlist view shows confidence badge per track (icon-based: checkmark / tilde / hand) | New `BPMInfo` struct + service method plumbs confidence to `TrackRow`; switch on `BPMConfidence` selects icon + color per locked decisions |
</phase_requirements>

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| SwiftUI | iOS 17+ | View layer | Already in use throughout the app |
| SF Symbols | 5.0+ | Icons | `checkmark.seal.fill`, `hand.raised.fill`, `tilde` -- system icons, no asset management |
| SwiftData | iOS 17+ | Data layer | Already used for CachedBPM model |

### Supporting
No new libraries needed. This is purely a view-layer change consuming existing data.

## Architecture Patterns

### Data Flow: Service -> View -> Row

```
BPMCacheService
  .getBPMInfo(forTrackID:) -> BPMInfo?   // NEW method
       |
PlaylistDetailView
  @State bpmCache: [String: BPMInfo]     // CHANGED type
       |
TrackRow(track:index:isPlaying:bpmInfo:)  // CHANGED param
       |
  switch bpmInfo.confidence -> icon + color
```

### Pattern 1: Lightweight Value Struct for View Data

**What:** A simple struct carrying `bpm: Int?` and `confidence: BPMConfidence?` to avoid passing the full SwiftData model object to views.

**Why not pass CachedBPM directly:** CachedBPM is a `@Model` class -- passing it into a `private struct TrackRow` creates ownership ambiguity, and the view only needs two fields. A value type is cleaner.

**Why not a tuple:** Tuples can't conform to `Equatable`/`Hashable` easily. A named struct is more readable and extensible if Phase 20 needs to add tap-BPM state.

```swift
struct BPMInfo: Equatable {
    let bpm: Int?
    let confidence: BPMConfidence?

    static let empty = BPMInfo(bpm: nil, confidence: nil)
}
```

### Pattern 2: Confidence Badge as Inline Switch

**What:** TrackRow switches on confidence to produce the right icon + color, all within the existing capsule pattern.

```swift
// Inside TrackRow body
if let bpm = bpmInfo.bpm, let confidence = bpmInfo.confidence {
    HStack(spacing: Spacing.xxs) {
        Image(systemName: confidence.iconName)
        Text("\(bpm) BPM")
    }
    .font(.labelText)
    .fontWeight(.bold)
    .foregroundStyle(confidence.color)
    .padding(.horizontal, 6)
    .padding(.vertical, Spacing.xxs)
    .background(Capsule().fill(confidence.color.opacity(0.15)))
} else {
    // No BPM state
    Text("-- BPM")
        .font(.labelText)
        .fontWeight(.bold)
        .foregroundStyle(Color.textTertiary)
        .padding(.horizontal, 6)
        .padding(.vertical, Spacing.xxs)
        .background(Capsule().fill(Color.textTertiary.opacity(0.15)))
}
```

### Pattern 3: Computed Properties on BPMConfidence Enum

**What:** Add `iconName` and `color` computed properties to `BPMConfidence` to centralize the mapping. Keeps TrackRow clean.

```swift
extension BPMConfidence {
    var iconName: String {
        switch self {
        case .verified: return "checkmark.seal.fill"
        case .approximate: return "tilde"
        case .manual: return "hand.raised.fill"
        }
    }

    var color: Color {
        switch self {
        case .verified: return .stateSuccess
        case .approximate: return .stateApproximate  // new token
        case .manual: return .stateWarning
        }
    }
}
```

### Anti-Patterns to Avoid
- **Passing CachedBPM (@Model) to TrackRow:** Creates unnecessary coupling between view and data layer. Use a value type.
- **Hardcoding icon/color in TrackRow:** Scatter the mapping. Centralize on the enum instead.
- **Fetching CachedBPM inside TrackRow:** Views should not call services. Data flows down from parent.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Icon selection per confidence | Manual if-else chain | Computed property on enum | Single source of truth, easy to extend |
| Color per confidence | Inline color literals | DesignTokens + enum computed property | Consistent with project design system |
| Badge layout | Custom frame math | HStack + Capsule (existing pattern) | Already proven in current TrackRow |

## Common Pitfalls

### Pitfall 1: Forgetting to Update bpmCache After Scan
**What goes wrong:** After `scanBPM()`, the cache reload still uses `getBPM()` (returns Int?) instead of the new method.
**How to avoid:** Update ALL call sites where `bpmCache` is populated (lines 186, 201 in current code) to use the new `getBPMInfo()` method.

### Pitfall 2: Approximate Confidence Rendering Before Any Source Maps to It
**What goes wrong:** The `approximate` case exists in the enum but currently no code path produces it. Rendering it is harmless but untestable in real use.
**How to avoid:** Render it anyway (the enum case exists, the view should handle all cases). Mark test as covering the code path via unit test with manually-set confidence. This future-proofs the view for when a source does produce approximate confidence.

### Pitfall 3: No-BPM vs Nil-Confidence Confusion
**What goes wrong:** A track with `bpm: nil` but `lookupAttempted: true` has `confidence: nil`. A track never looked up also has `confidence: nil`. The view must treat both the same way (muted capsule).
**How to avoid:** The view key is `bpmInfo.bpm == nil` -- show muted capsule. Don't try to distinguish "not yet looked up" from "looked up, no BPM found" in this phase.

### Pitfall 4: SF Symbol `tilde` Availability
**What goes wrong:** The `tilde` SF Symbol was introduced in iOS 16/SF Symbols 4. Should be available on iOS 17+ target but worth verifying in Xcode.
**How to avoid:** Verify in Xcode's SF Symbols browser that `tilde` exists. Fallback: `tilde.circle` or `questionmark` if needed.

## Code Examples

### New Service Method
```swift
// In BPMCacheService.swift
func getBPMInfo(forTrackID trackID: String) -> BPMInfo {
    let descriptor = FetchDescriptor<CachedBPM>(
        predicate: #Predicate { $0.spotifyTrackID == trackID }
    )
    guard let cached = try? context.fetch(descriptor).first else {
        return .empty
    }
    return BPMInfo(bpm: cached.bpm, confidence: cached.confidence)
}
```

### New Color Token
```swift
// In DesignTokens.swift, inside Color extension
static let stateApproximate = Color(red: 0.35, green: 0.55, blue: 0.95)  // subtle blue
```

### Updated TrackRow Init
```swift
private struct TrackRow: View {
    let track: SpotifyTrack
    let index: Int
    let isPlaying: Bool
    let bpmInfo: BPMInfo   // was: let bpm: Int?
    // ...
}
```

### Updated PlaylistDetailView Cache
```swift
@State private var bpmCache: [String: BPMInfo] = [:]

// In loadTracks:
bpmCache[track.id] = BPMCacheService.shared.getBPMInfo(forTrackID: track.id)

// In TrackRow call site:
TrackRow(
    track: track,
    index: index + 1,
    isPlaying: playerService.currentTrack?.uri == track.uri,
    bpmInfo: bpmCache[track.id] ?? .empty
)
```

## Discretion Recommendations

### Data Plumbing: Use BPMInfo Struct
Recommended over tuple (readability, Equatable conformance) and over passing CachedBPM directly (unnecessary coupling). See Pattern 1 above.

### Blue Color Token Value
Recommend `Color(red: 0.35, green: 0.55, blue: 0.95)` -- a cool medium-blue that reads as "informational" against dark backgrounds, distinct from green (success) and yellow (warning). Named `stateApproximate` to fit the existing `stateSuccess`/`stateWarning`/`stateError` pattern.

### Icon Sizing
Use `.font(.labelText)` on the Image (same as the text). SF Symbols automatically size to match the font, so no explicit frame needed. The icon will be the same optical height as "BPM" text.

### Capsule Padding
Current padding is `.horizontal: 6, .vertical: Spacing.xxs (2)`. With an icon added, the horizontal padding can remain the same -- the HStack spacing of `Spacing.xxs` between icon and text handles the internal gap. No adjustment needed.

### Approximate Badge: Render Now
The enum case exists. The view should handle all cases defensively. Render it with the blue badge. If no tracks ever have `.approximate` confidence today, that is fine -- the code path is tested and ready for when they do.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | XCTest (iOS 17+) |
| Config file | BeatStepTests target in Xcode project |
| Quick run command | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BeatStepTests/BPMConfidenceBadgeTests 2>&1 \| tail -20` |
| Full suite command | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 \| tail -40` |

### Phase Requirements -> Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| CONF-03a | Verified track shows checkmark.seal.fill icon name | unit | `xcodebuild test -only-testing:BeatStepTests/BPMConfidenceBadgeTests/testVerifiedIconName` | No -- Wave 0 |
| CONF-03b | Manual track shows hand.raised.fill icon name | unit | `xcodebuild test -only-testing:BeatStepTests/BPMConfidenceBadgeTests/testManualIconName` | No -- Wave 0 |
| CONF-03c | Approximate track shows tilde icon name | unit | `xcodebuild test -only-testing:BeatStepTests/BPMConfidenceBadgeTests/testApproximateIconName` | No -- Wave 0 |
| CONF-03d | Verified color maps to stateSuccess | unit | same pattern | No -- Wave 0 |
| CONF-03e | Manual color maps to stateWarning | unit | same pattern | No -- Wave 0 |
| CONF-03f | Approximate color maps to stateApproximate | unit | same pattern | No -- Wave 0 |
| CONF-03g | getBPMInfo returns confidence from service | unit | same pattern | No -- Wave 0 |
| CONF-03h | getBPMInfo returns .empty for unknown track | unit | same pattern | No -- Wave 0 |

### Sampling Rate
- **Per task commit:** Quick run on BPMConfidenceBadgeTests
- **Per wave merge:** Full test suite
- **Phase gate:** Full suite green before verification

### Wave 0 Gaps
- [ ] `BeatStepTests/BPMConfidenceBadgeTests.swift` -- covers CONF-03 (icon/color mapping + service method)
- [ ] `BeatStep/Models/BPMInfo.swift` -- new value struct (production code, not test, but needed before tests)

## Open Questions

1. **SF Symbol `tilde` verification**
   - What we know: `tilde` was added in SF Symbols 4 (iOS 16). App targets iOS 17+.
   - What's unclear: Whether it renders well at `.labelText` (11pt) size -- it may be very small.
   - Recommendation: Verify in Xcode during implementation. If too small, consider `tilde.circle` as alternative.

## Sources

### Primary (HIGH confidence)
- Project source code: `BPMConfidence.swift`, `CachedBPM.swift`, `BPMCacheService.swift`, `DesignTokens.swift`, `PlaylistDetailView.swift` -- all read directly
- `19-CONTEXT.md` -- user decisions and code context

### Secondary (MEDIUM confidence)
- SF Symbols availability (training data): `tilde` added in SF Symbols 4 / iOS 16

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- no new libraries, pure SwiftUI view changes
- Architecture: HIGH -- data plumbing pattern is straightforward, existing patterns to follow
- Pitfalls: HIGH -- codebase is small and fully read; all integration points identified

**Research date:** 2026-03-25
**Valid until:** 2026-04-25 (stable -- no external dependencies)
