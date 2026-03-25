# Feature Research: v1.6 Little Big Things

**Domain:** iOS running music app -- UI polish, custom components, micro-interactions
**Researched:** 2026-03-25
**Confidence:** HIGH (patterns verified against SwiftUI docs and existing codebase)

## Feature Landscape

### Table Stakes (Users Expect These)

Features that feel broken or incomplete if missing from a polished v1.6.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Library search | Any list >10 items needs search. Users with 50+ playlists cannot find what they need. | LOW | SwiftUI `.searchable()` modifier -- 15 lines of code. Computed property filters `playlists` array by name. Already have `PlaylistListView` with List. |
| Library filter (All / Analyzed / Unanalyzed) | Users need to find unanalyzed playlists to scan them. Currently requires scrolling and reading status text on each row. | LOW | `.searchScopes()` modifier with enum, or segmented Picker above the list. Filter the same computed property used for search. |
| Settings screen structure | Current Settings is a flat list mixing account, zones, playback, permissions, and debug. Users expect grouped organization like Apple's Settings app. | LOW | Already using `List` with `Section`. Just reorganize into: Account, Running (zones + tolerance defaults), Playback, Permissions, About. Add version/build at bottom. |
| Skeleton/loading states | ProgressView spinners feel unfinished. Shimmer placeholders show users content is coming and where it will appear. | MEDIUM | `.redacted(reason: .placeholder)` built into SwiftUI. Add shimmer modifier (10-line custom ViewModifier with gradient animation). Apply to PlaylistRow and TrackRow shapes during loading. |
| Analysis status bug fix | Existing bug where playlist analysis state displays incorrectly. Users cannot trust what they see. | LOW | Debug existing `coverageMap` logic in PlaylistListView. Likely race condition between `loadCoverageData()` and scan completion notification. |

### Differentiators (Competitive Advantage)

Features that make BeatStep feel intentionally designed vs. a hobby project.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Contextual scan actions replacing floating bar | Scan actions appear where relevant (swipe on playlist row, toolbar in detail view) instead of a persistent floating bar that covers content. Feels native, not bolted-on. | MEDIUM | Already have swipe-to-analyze on PlaylistListView rows. Add `.contextMenu` on playlist rows for Analyze/Clear. Add toolbar button on PlaylistDetailView (partially exists). Remove any floating scan bar overlay. |
| Custom zone picker with haptics | Current ZonePickerView is capsule buttons with no tactile feedback. Adding `.sensoryFeedback(.selection, trigger: selectedZoneId)` makes zone switching feel physical. | LOW | SwiftUI `.sensoryFeedback()` modifier (iOS 17+). One line per interactive component. Add to ZonePickerView, TolerancePicker, and half-tempo toggle. |
| Multi-zone selection with merged BPM range | Select Zone 2 + Zone 3 to get a merged 150-170 BPM range. No running app does this -- they force a single zone. Lets runners target a range naturally. | HIGH | Change `selectedZoneId: Int?` to `selectedZoneIds: Set<Int>`. Compute merged BPM range from min/max of selected zones. Update RunEngineService tolerance to use merged range. Requires rethinking zone capsule selection UX (multi-select vs single-select). |
| Playlist card redesign with scan quality | Show BPM coverage as a visual progress ring or bar on the playlist card, not just "42/50 BPM" text. Color-code by quality: green (>80% coverage), yellow (50-80%), red (<50%). | MEDIUM | New `PlaylistCard` component replacing `PlaylistRow`. Add a small circular progress indicator or horizontal bar showing coverage percentage. Use existing `coverageMap` data, parse the "X/Y" string into percentage. |
| Micro-interaction pass (transitions) | `.animation()` on state changes, `.transition()` on view insertions. Loading->content uses `.transition(.opacity)`. Zone picker selection uses `.spring()`. Makes UI feel alive. | MEDIUM | Audit every state change in RunTabView, PlaylistListView, PlaylistDetailView. Add `.animation(.spring(duration: 0.3))` to value changes. Add `.transition(.blurReplace)` or `.transition(.opacity)` to conditional views. |
| Pre-built skip queue | Pre-compute next 2-3 songs so skip is instant instead of requiring API call + BPM match computation on tap. | MEDIUM | Add `private var upcomingQueue: [SpotifyTrack] = []` to RunEngineService. After playing a track, immediately compute next 2-3 matches and store. On skip, pop from queue and play. Refill queue after each pop. No Spotify queue API needed -- just local pre-computation. |
| Run menu redesign with custom components | Replace system Picker segmented controls with custom capsule components matching the zone picker style. Unified visual language across Run tab. | MEDIUM | Build `BeatStepSegmentedControl` reusable component using HStack of capsule buttons (same pattern as ZonePickerView). Replace `TolerancePicker` segmented control. Add haptics on selection. |

### Anti-Features (Commonly Requested, Often Problematic)

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| Spotify queue API integration for skip | "Use Spotify's Add to Queue endpoint for seamless skipping" | Spotify queue API is append-only, buggy on iOS (documented community issues with queue truncation and skip-to-wrong-track), and does not support clearing/replacing queue. Playing a song after queuing skips to queued song unexpectedly. | Pre-compute matches locally and use `play(uri:)` directly. Current approach already works -- just pre-compute the next matches ahead of time. |
| Floating action bar for scan | "Persistent scan button visible everywhere" | Covers list content, conflicts with tab bar, non-native iOS pattern. Apple's HIG has no floating action bar concept. | Contextual: swipe actions on rows, toolbar buttons in detail views, context menus on long-press. Actions appear where relevant. |
| Custom animated transitions between all screens | "Page curl, slide, bounce for every navigation" | Over-animation causes motion sickness, slows perceived performance, makes app feel gimmicky. Apple's HIG: "Don't animate too many things at once." | Subtle spring animations on value changes. Default NavigationStack push/pop. `.matchedGeometryEffect` only for hero transitions (e.g., album art from card to run screen). |
| Inline search with real-time API calls | "Search Spotify catalog from library screen" | Adds API rate limit pressure, scope creep (this is library management, not discovery), and network-dependent UX in a screen that should work with cached data. | Local-only search filtering the already-fetched playlist list. Discovery is a separate feature (already exists via BPMDiscoveryService during runs). |
| Draggable/reorderable queue UI | "Let users manually reorder upcoming songs" | Contradicts core value -- BeatStep picks music that matches your stride. Manual ordering defeats automatic BPM matching. Adds complexity for a feature that undermines the product. | Show upcoming queue as read-only preview (next 2-3 songs). Users can skip, but ordering is algorithmic. |

## Feature Dependencies

```
[Library Search]
    (independent -- no dependencies)

[Library Filter]
    (independent -- enhances search but works alone)

[Settings Restructure]
    (independent -- no dependencies)

[Contextual Scan Actions]
    └──requires──> [Analysis Status Bug Fix]
                       (fix must land first so scan results display correctly)

[Playlist Card Redesign]
    └──requires──> [Analysis Status Bug Fix]
                       (card shows coverage data -- must be accurate)

[Custom Zone Picker with Haptics]
    (independent -- enhances existing ZonePickerView)

[Run Menu Redesign]
    └──requires──> [Custom Zone Picker with Haptics]
                       (zone picker pattern informs reusable segment component)
    └──enhances──> [Multi-Zone Selection]
                       (redesigned components enable multi-select UX)

[Multi-Zone Selection]
    └──requires──> [Run Menu Redesign]
                       (needs new multi-select capsule component)
    └──requires──> RunEngineService tolerance changes

[Micro-Interaction Pass]
    └──requires──> [All UI features complete]
                       (haptics/transitions added as final polish layer)

[Skeleton Loading States]
    (independent -- apply to any loading view)

[Pre-Built Skip Queue]
    (independent -- internal RunEngineService change, no UI dependency)
```

### Dependency Notes

- **Contextual Scan Actions requires Analysis Status Bug Fix:** If scan results do not display correctly, contextual scan triggers will show wrong state and confuse users. Fix the data first.
- **Playlist Card Redesign requires Analysis Status Bug Fix:** Card redesign adds visual coverage indicators. If underlying data is wrong, the visual indicators lie to the user.
- **Run Menu Redesign requires Custom Zone Picker with Haptics:** The zone picker capsule pattern becomes the reusable `BeatStepSegmentedControl`. Build the pattern first, then extract and reuse.
- **Multi-Zone Selection requires Run Menu Redesign:** Multi-select UX needs the new capsule component to support toggle behavior (tap to add/remove from selection set).
- **Micro-Interaction Pass requires all UI features:** Adding animations to components that will be replaced or redesigned is wasted work. Polish last.

## Phase Ordering Recommendation

### Phase A: Foundations (bug fix + infrastructure)

- [ ] Analysis status bug fix -- unblocks card redesign and contextual actions
- [ ] Skeleton loading states -- applies across all views, no dependency on other features
- [ ] Pre-built skip queue -- internal engine change, improves run experience immediately

### Phase B: Library Polish

- [ ] Library search (`.searchable()`)
- [ ] Library filter (segmented scope: All / Analyzed / Unanalyzed)
- [ ] Contextual scan actions (swipe + context menu + toolbar, remove floating bar)
- [ ] Playlist card redesign (coverage visualization, quality badges)

### Phase C: Run Tab Rebuild

- [ ] Custom zone picker with haptics (`.sensoryFeedback()` on existing component)
- [ ] Run menu redesign (reusable `BeatStepSegmentedControl`, replace system Picker)
- [ ] Multi-zone selection (Set-based selection, merged BPM range)
- [ ] Settings screen restructure (grouped sections)

### Phase D: Final Polish

- [ ] Micro-interaction pass (spring animations, transitions, haptics audit)

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| Analysis status bug fix | HIGH | LOW | P1 |
| Library search | HIGH | LOW | P1 |
| Library filter | MEDIUM | LOW | P1 |
| Pre-built skip queue | HIGH | MEDIUM | P1 |
| Custom zone picker with haptics | MEDIUM | LOW | P1 |
| Contextual scan actions | MEDIUM | MEDIUM | P1 |
| Settings restructure | LOW | LOW | P1 |
| Skeleton loading states | MEDIUM | MEDIUM | P2 |
| Playlist card redesign | MEDIUM | MEDIUM | P2 |
| Run menu redesign | MEDIUM | MEDIUM | P2 |
| Micro-interaction pass | MEDIUM | MEDIUM | P2 |
| Multi-zone selection | LOW | HIGH | P3 |

**Priority key:**
- P1: Core polish that fixes pain points or is trivially cheap
- P2: Meaningful improvement, build after P1 stabilizes
- P3: Nice differentiator but high complexity relative to value

## Implementation Notes

### Library Search

Use SwiftUI's `.searchable(text: $searchText)` on the List inside `PlaylistListView`. Filter with computed property:

```swift
var filteredPlaylists: [SpotifyPlaylist] {
    let filtered = searchText.isEmpty ? playlists : playlists.filter {
        $0.name.localizedCaseInsensitiveContains(searchText)
    }
    switch filterScope {
    case .all: return filtered
    case .analyzed: return filtered.filter { coverageMap[$0.id] != nil }
    case .unanalyzed: return filtered.filter { coverageMap[$0.id] == nil }
    }
}
```

### Haptics Strategy

Use `.sensoryFeedback()` (iOS 17+) exclusively -- no UIKit feedback generators needed. BeatStep already requires iOS 17 (uses @Observable). Apply to:

- Zone capsule tap: `.sensoryFeedback(.selection, trigger: selectedZoneId)`
- Tolerance change: `.sensoryFeedback(.selection, trigger: tolerance)`
- Start Run button: `.sensoryFeedback(.impact(weight: .medium), trigger: showActiveRun)`
- Long-press stop completion: `.sensoryFeedback(.success, trigger: runStopped)`
- Skip song: `.sensoryFeedback(.impact(weight: .light), trigger: skipCount)`

### Pre-Built Skip Queue

Add to RunEngineService:

```swift
@ObservationIgnored
private var upcomingQueue: [SpotifyTrack] = []

private func refillQueue() {
    let spm = effectiveBPM
    upcomingQueue = (0..<3).compactMap { _ in
        selectNextMatch(forSPM: spm)
    }
}

func skipToNextMatch() async {
    guard isRunActive, !isQueueingNext else { return }
    if let next = upcomingQueue.first {
        upcomingQueue.removeFirst()
        await playTrack(next)
        // Refill in background
        Task { refillQueue() }
    } else {
        await queueNextMatch()
    }
}
```

### Contextual Actions Pattern

Replace any floating scan bar with native iOS patterns:

1. **PlaylistListView rows:** Already has `.swipeActions`. Add `.contextMenu` with Analyze + View Details.
2. **PlaylistDetailView:** Already has toolbar Scan button. Add "Scan All" and "Clear All" to toolbar menu.
3. **Long-press on playlist row:** `.contextMenu { Button("Analyze BPM") { ... } }`

### Settings Organization

Restructure into clear groups following Apple's Settings pattern:

| Section | Contents |
|---------|----------|
| Account | Name, Plan, Disconnect |
| Running | Zones (NavigationLink to zone editor), Default tolerance |
| Playback | No-BPM track behavior, Tempo matching default |
| Permissions | Motion, Health, Open Settings |
| About | Version, Build, Sensor Lab (hidden toggle) |

## Competitor Feature Analysis

| Feature | Spotify | Apple Music | Nike Run Club | BeatStep Approach |
|---------|---------|-------------|---------------|-------------------|
| Library search | Full-text with suggestions | Full-text with categories | N/A (no music library) | Local filter on playlist name -- sufficient for 50-200 playlists |
| Playlist status indicators | Download status icon | Download/sync badge | N/A | BPM coverage ring/bar -- unique to our domain |
| Haptic feedback | Scrubber, skip, like | Scrubber, volume | Pace alerts | Zone selection, tolerance, run lifecycle events |
| Settings organization | Grouped sections, deep navigation | Grouped sections | Simple list | Grouped sections -- Account, Running, Playback, Permissions, About |
| Queue management | Full queue view, drag to reorder | Up Next with reorder | N/A | Read-only upcoming 2-3 songs, algorithmic ordering |
| Skip responsiveness | ~100ms (pre-buffered audio) | ~100ms (pre-buffered) | N/A | Currently: ~500ms (API call). Target: ~100ms (pre-computed queue) |

## Sources

- [SwiftUI searchable modifier -- Hacking with Swift](https://www.hackingwithswift.com/quick-start/swiftui/how-to-add-a-search-bar-to-filter-your-data)
- [SwiftUI searchScopes -- swiftyplace](https://www.swiftyplace.com/blog/how-to-use-search-scopes-in-swiftui-to-improve-search-on-ios-and-macos)
- [SwiftUI sensoryFeedback -- Hacking with Swift](https://www.hackingwithswift.com/quick-start/swiftui/how-to-add-haptic-effects-using-sensory-feedback)
- [Sensory feedback in SwiftUI -- Swift with Majid](https://swiftwithmajid.com/2023/10/10/sensory-feedback-in-swiftui/)
- [SwiftUI context menus -- Hacking with Swift](https://www.hackingwithswift.com/quick-start/swiftui/how-to-show-a-context-menu)
- [SwiftUI swipe actions -- Hacking with Swift](https://www.hackingwithswift.com/quick-start/swiftui/how-to-add-custom-swipe-action-buttons-to-a-list-row)
- [SwiftUI shimmer/skeleton loading -- Medium](https://medium.com/@Ajay_iOS/swiftui-micro-interaction-shimmer-placeholder-animation-in-10-lines-61348d380863)
- [SwiftUI Form/Settings patterns -- TDTrails](https://thedocutrails.com/2024/06/16/swiftui-settings-page-tutorial-organizing-options-with-sections-and-lists/)
- [Spotify queue API limitations -- GitHub](https://github.com/spotify/web-api/issues/15)
- [Spotify skip buffering architecture -- Medium](https://medium.com/@arpanp99/from-buffer-to-business-model-the-engineering-of-spotify-skips-c0f6dd36a554)

---
*Feature research for: BeatStep v1.6 Little Big Things*
*Researched: 2026-03-25*
