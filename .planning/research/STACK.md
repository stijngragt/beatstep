# Stack Research

**Domain:** iOS UI polish -- custom components, haptics, animations, search/filter, loading skeletons, playback queue
**Researched:** 2026-03-25
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
| DesignTokens.swift (Color, Font, Spacing, Radius, ComponentSize) | Working |
| RunEngineService (cadence monitor, BPM matching, ramp state) | Working |
| Swift Charts (SensorLab waveform) | Working |
| iOS 17.0 deployment target | Confirmed |

---

## v1.6 Stack Additions: Little Big Things

v1.6 requires **zero new external dependencies**. Every capability is available in SwiftUI and UIKit APIs already linked. This is a pure UI polish milestone.

### Core Technologies (v1.6)

| Technology | API | iOS Version | Purpose | Why This |
|------------|-----|-------------|---------|----------|
| `.sensoryFeedback()` modifier | `View.sensoryFeedback(_:trigger:)` | 17.0+ | Haptic feedback on zone selection, tolerance change, run start, skip | Native SwiftUI haptics -- declarative, no UIKit boilerplate. Fires when trigger value changes. Replaces `UIImpactFeedbackGenerator` for all new v1.6 haptics. |
| `.searchable()` modifier | `View.searchable(text:placement:prompt:)` | 15.0+ | Library playlist search and track filtering | Built into NavigationStack. Zero custom UI needed for search bar placement, keyboard management, cancel button. Already the standard SwiftUI pattern. |
| `.redacted(reason: .placeholder)` | `View.redacted(reason:)` | 14.0+ | Loading skeleton states for playlist rows, track lists, run tab | Built-in placeholder rendering. Combined with a shimmer ViewModifier for animated loading states. No library needed -- 20 lines of custom code. |
| `SwiftUI.Animation` spring presets | `.spring(.bouncy)`, `.spring(.snappy)` | 17.0+ | Component transitions, zone picker selection, tolerance appear/disappear | iOS 17 added named spring presets. `.bouncy` for selection feedback, `.snappy` for UI element insertion. Replaces `.easeInOut` for more physical feel. |
| `withAnimation` + `.transition()` | `.asymmetric(insertion:removal:)` | 13.0+ | Conditional view appearance (tolerance picker, filter chips, loading states) | Already used in RunTabView for tolerance. Extend pattern to all conditional UI elements. |
| `.swipeActions()` modifier | `View.swipeActions(edge:allowsFullSwipe:)` | 15.0+ | Contextual scan actions on playlist rows | Already used in PlaylistListView. Extend to contextual actions (analyze, remove, info) replacing floating scan bar. |
| `.contextMenu()` modifier | `View.contextMenu { }` | 13.0+ | Long-press actions on tracks (tap BPM, play, details) | Built-in iOS context menu with haptic feedback. Better than custom sheet for secondary actions. |
| `@Namespace` + `matchedGeometryEffect` | `View.matchedGeometryEffect(id:in:)` | 14.0+ | Animated zone picker selection indicator | Smooth capsule/highlight transition between selected items. Creates "sliding selection" effect without manual frame calculations. |

### Supporting Patterns (no libraries)

| Pattern | Implementation | Purpose | Detail |
|---------|---------------|---------|--------|
| Shimmer ViewModifier | Custom `ViewModifier` with `LinearGradient` + `.mask` + phase animation | Animated loading skeletons | ~20 lines. Uses `.onAppear` with repeating animation to move gradient across redacted views. `.screen` blend mode adds luminosity. |
| Filter chip component | Custom `FilterChipView` using existing capsule pattern from ZonePickerView | All/Analyzed/Unanalyzed library filter | Reuse the exact capsule selection pattern from ZonePickerView. Horizontal ScrollView with capsules. |
| Multi-zone selection | `Set<Int>` binding instead of `Int?` on ZonePickerView | Select multiple zones for merged BPM range | Change `@Binding var selectedZoneId: Int?` to `@Binding var selectedZoneIds: Set<Int>`. Compute merged BPM range from union of selected zones. |
| Pre-built skip queue | Local `[SpotifyTrack]` buffer in RunEngineService | Instant skip without async delay | Pre-compute next 2-3 matches when a song starts. On skip, pop from buffer + play immediately, then replenish buffer async. Spotify `addToQueue` API is unreliable for this -- use local buffer with `play(uri:)`. |
| Debounced search | `Task` with `Task.sleep` in `.onChange(of: searchText)` | Avoid filtering on every keystroke | 300ms debounce. Cancel previous task on new input. Filter `playlists` array by name match. Standard async pattern, no Combine needed. |
| Component extraction | Dedicated view files for reusable components | PlaylistCard, ZonePicker, ToleranceSelector, FilterChips | Extract from existing inline code in RunTabView and PlaylistListView into standalone views in a `Components/` directory. |

---

## Critical Implementation Details

### Haptic Feedback Strategy with `.sensoryFeedback()`

iOS 17 introduced `.sensoryFeedback()` as the SwiftUI-native replacement for `UIImpactFeedbackGenerator`. Use it because the codebase targets iOS 17+ and it is declarative -- no `prepare()` / `impactOccurred()` lifecycle.

```swift
// Zone picker selection -- medium impact on selection change
ZonePickerView(selectedZoneIds: $selectedZoneIds)
    .sensoryFeedback(.selection, trigger: selectedZoneIds)

// Run start -- success feedback
Button("Start Run") { startRun() }
    .sensoryFeedback(.success, trigger: showActiveRun)

// Skip song -- light impact
Button { Task { await runEngine.skipToNextMatch() } } label: { ... }
    .sensoryFeedback(.impact(weight: .light), trigger: runEngine.currentMatchedTrack?.id)
```

Available feedback types for v1.6:
- `.selection` -- zone picker, tolerance change, filter chip tap
- `.success` -- run start, scan complete
- `.impact(weight: .light)` -- skip, swipe action trigger
- `.warning` -- long-press stop progress start

**Exception:** Keep `UIImpactFeedbackGenerator` in TapBPMView (v1.4) -- it fires on imperative tap events, not state changes. `.sensoryFeedback()` requires a trigger binding.

### Library Search + Filter Implementation

The `.searchable()` modifier attaches to the NavigationStack content, not the List. For BeatStep's library:

```swift
// PlaylistListView
@State private var searchText = ""
@State private var activeFilter: LibraryFilter = .all

enum LibraryFilter: String, CaseIterable {
    case all = "All"
    case analyzed = "Analyzed"
    case unanalyzed = "Unanalyzed"
}

var filteredPlaylists: [SpotifyPlaylist] {
    var result = playlists

    // Apply text search
    if !searchText.isEmpty {
        result = result.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    // Apply filter
    switch activeFilter {
    case .all: break
    case .analyzed: result = result.filter { coverageMap[$0.id] != nil }
    case .unanalyzed: result = result.filter { coverageMap[$0.id] == nil }
    }

    return result
}

// In body:
playlistList
    .searchable(text: $searchText, prompt: "Search playlists")
```

Search is client-side over already-fetched playlists. No Spotify API search needed -- the user's library is already loaded via paginated fetch.

### Loading Skeleton Pattern

Build once, use everywhere. The skeleton is a ViewModifier combining `.redacted()` with a shimmer animation:

```swift
struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = -1

    func body(content: Content) -> some View {
        content
            .redacted(reason: .placeholder)
            .overlay(
                LinearGradient(
                    colors: [.clear, Color.white.opacity(0.15), .clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .rotationEffect(.degrees(15))
                .offset(x: phase * 400)
                .mask(content.redacted(reason: .placeholder))
            )
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}

// Usage:
PlaylistRow(playlist: .placeholder, ...)
    .shimmer()
```

Create `.placeholder` static instances on models (SpotifyPlaylist, SpotifyTrack) that provide dummy data for redacted rendering.

### Pre-Built Skip Queue

The current RunEngineService plays songs via `play(uri:)` one at a time. On skip, it calls `queueNextMatch()` which runs `selectNextMatch()` + `playTrack()` -- both are fast (in-memory), but the Spotify API `play()` call has ~300-500ms latency.

The pre-built queue buffers the next match locally:

```swift
// In RunEngineService
@ObservationIgnored
private var skipBuffer: [SpotifyTrack] = []

// After playing a track, pre-compute next matches:
private func replenishBuffer() {
    skipBuffer.removeAll()
    for _ in 0..<2 {
        if let next = selectNextMatch(forSPM: effectiveBPM) {
            skipBuffer.append(next)
        }
    }
}

func skipToNextMatch() async {
    guard isRunActive, !isQueueingNext else { return }
    isQueueingNext = true
    defer { isQueueingNext = false }

    if let buffered = skipBuffer.first {
        skipBuffer.removeFirst()
        await playTrack(buffered)
        // Replenish in background
        replenishBuffer()
    } else {
        await queueNextMatch()
    }
}
```

**Do NOT use Spotify's `POST /me/player/queue` endpoint** for the skip buffer. That endpoint adds to Spotify's internal queue which we cannot clear or reorder. If cadence changes between queue addition and playback, the queued song may no longer match. Keep the buffer local and use `play(uri:)` for each song.

### Spotify Queue API -- What Is Available

| Endpoint | Method | What It Does | Usable for BeatStep? |
|----------|--------|--------------|---------------------|
| `POST /me/player/queue` | POST | Add one track to end of Spotify queue | NO -- cannot clear/reorder, stale if cadence changes |
| `GET /me/player/queue` | GET | Read current queue (max 20 items) | MAYBE -- useful for debugging, not for skip buffer |

The Spotify queue API has known limitations: no clear/remove endpoint, max 20 items returned, execution order not guaranteed when combined with other player endpoints. The local buffer pattern is more reliable for BeatStep's dynamic BPM matching.

### Multi-Zone Selection with Merged BPM Range

Current: `selectedZoneId: Int?` -- single zone or Free.
New: `selectedZoneIds: Set<Int>` -- multiple zones, merged range.

```swift
// Compute merged BPM range
var mergedBPMRange: ClosedRange<Int>? {
    guard !selectedZoneIds.isEmpty else { return nil }
    let zones = RunZone.saved.filter { selectedZoneIds.contains($0.id) }
    guard let minBPM = zones.map(\.bpm).min(),
          let maxBPM = zones.map(\.bpm).max() else { return nil }
    return minBPM...maxBPM
}
```

RunEngineService needs to accept a BPM range instead of a single target. This changes `targetBPM: Int` to `targetBPMRange: ClosedRange<Int>`.

---

## Integration Points Summary

| Existing Code | Change | Risk |
|---------------|--------|------|
| ZonePickerView | `Int?` -> `Set<Int>`, multi-select, `matchedGeometryEffect` indicator | MEDIUM -- binding type change propagates to RunTabView |
| TolerancePicker | Extract to component, add `.sensoryFeedback` | LOW -- additive |
| PlaylistListView | Add `.searchable()`, filter chips, shimmer loading, redesigned rows | MEDIUM -- significant view restructure |
| PlaylistDetailView | Add `.contextMenu()` on track rows | LOW -- additive |
| RunTabView | Redesigned layout, custom components, haptics | MEDIUM -- visual restructure |
| RunEngineService | Pre-built skip buffer, BPM range support for multi-zone | MEDIUM -- core matching logic touched |
| SpotifyPlayerService | No changes needed | NONE |
| SettingsView | Restructured sections (account, defaults, debug, about) | LOW -- layout only |
| DesignTokens | Add animation duration tokens, possibly new component sizes | LOW -- additive |
| ContentView | No changes needed | NONE |

---

## What NOT to Add

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| Lottie / animation libraries | Custom components need only spring animations and transitions. Lottie imports a rendering engine for pre-made animations -- overkill for selection indicators and transitions. | SwiftUI `.animation()`, `.transition()`, `matchedGeometryEffect` |
| SwiftUI-Shimmer package | The shimmer effect is ~20 lines of custom ViewModifier. Adding a dependency for this is unnecessary. | Custom `ShimmerModifier` using `LinearGradient` + `.redacted()` |
| Spotify `POST /me/player/queue` for skip buffer | Cannot clear or reorder Spotify's queue. If cadence changes, queued songs become stale. No remove API exists. | Local `[SpotifyTrack]` buffer with `play(uri:)` |
| Combine for search debounce | Codebase uses `@Observable` + async/await exclusively. Adding `Combine` for `.debounce` creates a second reactive paradigm. | `Task.sleep(for: .milliseconds(300))` with task cancellation |
| CoreHaptics | Complex engine for custom haptic patterns (waveforms, sustained vibrations). BeatStep needs only standard feedback types. | `.sensoryFeedback()` modifier (selection, impact, success, warning) |
| `UIImpactFeedbackGenerator` for new haptics | Works but requires imperative prepare/fire lifecycle. `.sensoryFeedback()` is declarative and aligns with SwiftUI patterns. | `.sensoryFeedback()` -- except in TapBPMView where imperative firing is needed |
| Third-party search/filter libraries | `.searchable()` handles search bar, keyboard, cancel. Filtering is array operations. | Built-in `.searchable()` + `Array.filter()` |
| `ScrollPosition` (iOS 18) | Requires iOS 18+. Project targets iOS 17. | `ScrollViewReader` with `scrollTo()` (iOS 17 compatible, already used) |
| NavigationTransition / custom push animations | iOS 18+ API. Requires minimum deployment bump. | `.transition()` + `.matchedGeometryEffect()` for shared-element-like effects |
| Algolia / search indexing | Library has max ~500 playlists, already in memory. Full-text search over in-memory array is instant. | `localizedCaseInsensitiveContains` on playlist name |

---

## Alternatives Considered

| Recommended | Alternative | When to Use Alternative |
|-------------|-------------|-------------------------|
| `.sensoryFeedback()` | `UIImpactFeedbackGenerator` | When haptic must fire on imperative event (not state change). Already used in TapBPMView. Keep for that one case. |
| `.redacted()` + custom shimmer | `ProgressView` spinner | Never for list items -- spinners are for whole-screen states. Skeletons show layout shape, better UX. Keep `ProgressView` only for full-screen initial loads. |
| Local skip buffer | Spotify queue API | If Spotify ever adds clear/reorder queue endpoints. Currently not available. |
| `matchedGeometryEffect` for selection | Manual frame tracking with `GeometryReader` | If matchedGeometryEffect causes glitches (rare). Start with matched geometry, fall back to manual only if bugs appear. |
| `.searchable()` on NavigationStack | Custom search bar in toolbar | If `.searchable()` placement doesn't work with existing NavigationStack structure. Unlikely given standard setup. |
| Client-side playlist filter | Spotify search API | If user has 1000+ playlists and wants to search across ALL Spotify. v1.6 scope is filtering loaded playlists only. |
| `Set<Int>` for multi-zone | Array of zone IDs | Set gives O(1) contains checks and automatic deduplication. Array has no advantage here. |
| Named spring presets (`.bouncy`, `.snappy`) | Custom `Spring(response:dampingFraction:)` | If specific spring tuning is needed after visual review. Start with presets, tune only if feel is wrong. |

---

## Design Token Additions

DesignTokens.swift needs small extensions for v1.6 animation and component patterns:

```swift
// MARK: - Animation Tokens
enum AnimationDuration {
    static let quick: Double = 0.15     // Haptic-paired feedback
    static let standard: Double = 0.25  // State transitions
    static let smooth: Double = 0.4     // Layout shifts, skeleton fade
}

// MARK: - Additional Component Sizes
extension ComponentSize {
    static let filterChipHeight: CGFloat = 32
    static let searchBarHeight: CGFloat = 36
    static let skeletonRowHeight: CGFloat = 50  // Match PlaylistRow height
}
```

---

## Version Compatibility

| API | Minimum iOS | BeatStep Target (17.0) | Status |
|-----|-------------|------------------------|--------|
| `.sensoryFeedback()` | 17.0 | 17.0 | Available |
| `.searchable()` | 15.0 | 17.0 | Available |
| `.redacted(reason:)` | 14.0 | 17.0 | Available |
| `.spring(.bouncy)` presets | 17.0 | 17.0 | Available |
| `.swipeActions()` | 15.0 | 17.0 | Already in use |
| `.contextMenu()` | 13.0 | 17.0 | Available |
| `matchedGeometryEffect` | 14.0 | 17.0 | Available |
| `@Namespace` | 14.0 | 17.0 | Available |

No compatibility concerns. Every API needed predates or matches the iOS 17.0 deployment target.

---

## New Files to Create

| File | Type | Purpose |
|------|------|---------|
| `Components/PlaylistCardView.swift` | View | Redesigned playlist row with scan quality visibility |
| `Components/FilterChipBar.swift` | View | Horizontal scrolling filter chips (All/Analyzed/Unanalyzed) |
| `Components/ShimmerModifier.swift` | ViewModifier | Reusable shimmer/skeleton loading animation |
| `Components/ZonePickerView.swift` | View (move) | Refactored zone picker with multi-select + matchedGeometryEffect |
| `Components/ToleranceSelector.swift` | View (move) | Refactored tolerance picker as custom component (not Picker/segmented) |
| Updated `RunTabView.swift` | View | Rebuilt run menu with new components, haptics |
| Updated `PlaylistListView.swift` | View | Search, filter, skeleton loading, redesigned rows |
| Updated `SettingsView.swift` | View | Restructured sections with proper grouping |
| Updated `RunEngineService.swift` | Service | Skip buffer, BPM range matching for multi-zone |

---

## Key Takeaway

v1.6 is a zero-dependency milestone. All capabilities come from SwiftUI APIs available on iOS 17: `.sensoryFeedback()` for haptics, `.searchable()` for search, `.redacted()` + custom shimmer for skeletons, spring presets for animations, `matchedGeometryEffect` for selection indicators. The skip queue is a local buffer pattern, not a Spotify API feature. The work is extracting components, adding polish modifiers, and restructuring views -- not adding packages.

---

## Sources

- [SensoryFeedback in SwiftUI](https://appmakers.dev/sensoryfeedback-in-swiftui/) -- `.sensoryFeedback()` modifier API, feedback types, trigger pattern (HIGH confidence)
- [How to add haptic effects using sensory feedback](https://www.hackingwithswift.com/quick-start/swiftui/how-to-add-haptic-effects-using-sensory-feedback) -- iOS 17 haptics replacing UIFeedbackGenerator (HIGH confidence)
- [SwiftUI Search Bar Best Practices](https://www.swiftyplace.com/blog/swiftui-search-bar-best-practices-and-examples) -- `.searchable()` placement, tokens, suggestions (HIGH confidence)
- [searchable(text:tokens:) Apple Docs](https://developer.apple.com/documentation/swiftui/view/searchable(text:tokens:suggestedtokens:placement:prompt:token:)-9q3oc) -- official API reference (HIGH confidence)
- [SwiftUI Redacted Magic -- Shimmer/Skeleton Loading](https://medium.com/@naqeeb-ahmed/swiftui-redacted-magic-achieve-shimmer-skeleton-loading-effect-with-just-one-line-of-code-5b203b540dad) -- `.redacted()` + gradient shimmer pattern (MEDIUM confidence)
- [Avanderlee -- Redacted View Modifier](https://www.avanderlee.com/swiftui/redacted-view-modifier/) -- best practices for placeholder views (HIGH confidence)
- [Mastering SwiftUI Animations in iOS 17+](https://medium.com/@sanjaychavare1/mastering-swiftui-animations-in-ios-17-smooth-transitions-matchedgeometryeffect-beyond-03b89be3f463) -- spring presets, matchedGeometryEffect patterns (MEDIUM confidence)
- [Spotify Web API -- Add to Queue](https://developer.spotify.com/documentation/web-api/reference/add-to-queue) -- endpoint limitations, no clear/remove (HIGH confidence)
- [Spotify Web API -- Get Queue](https://developer.spotify.com/documentation/web-api/reference/get-queue) -- max 20 items, read-only (HIGH confidence)
- [Spotify Queue endpoint needs polish](https://community.spotify.com/t5/Spotify-for-Developers/Spotify-Web-API-Queue-endpoint-needs-polish/td-p/5493505) -- community reports on queue API limitations (MEDIUM confidence)
- Codebase inspection: DesignTokens.swift, ZonePickerView.swift, TolerancePicker.swift, RunTabView.swift, PlaylistListView.swift, PlaylistDetailView.swift, RunEngineService.swift, SpotifyPlayerService.swift, SettingsView.swift, ContentView.swift, BeatStepApp.swift

---
*Stack research for: BeatStep v1.6 Little Big Things -- UI polish, custom components, haptics, animations, search, loading skeletons, playback queue*
*Researched: 2026-03-25*
