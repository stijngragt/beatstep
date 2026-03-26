# Phase 28: Library Polish - Research

**Researched:** 2026-03-26
**Domain:** SwiftUI List, search, filtering, swipe actions, context menus
**Confidence:** HIGH

## Summary

Phase 28 transforms the Library tab from a basic playlist list into a searchable, filterable, visually-rich view. The existing `PlaylistListView.swift` (170 lines) is the sole file to modify, with `PlaylistRow` as an inline private struct that will be significantly redesigned. All required data (`tracksWithBPM`, `totalTracks`) already exists in the `ScannedPlaylist` SwiftData model. The design system tokens (colors, spacing, radii, animations, haptics) are fully established from Phase 27.

The main technical tasks are: (1) adding `.searchable` modifier with client-side filtering, (2) building filter chip UI with state management, (3) redesigning `PlaylistRow` with a coverage progress bar, (4) enriching the coverage data model from `String` to numeric values, (5) adding `.contextMenu` alongside existing `.swipeActions`, and (6) implementing a `deleteScan` method in `LibraryScanService`.

**Primary recommendation:** Keep all changes in `PlaylistListView.swift` and `LibraryScanService.swift`. Extract `PlaylistRow` to its own file only if it exceeds ~80 lines. Use existing design tokens everywhere -- no new token definitions needed.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- iOS native `.searchable` modifier -- pull-down search bar in navigation bar, collapses when not in use
- Filter chips (All / Analyzed / Unanalyzed) sit below search bar and scroll away with list content
- Client-side filtering only -- filter already-loaded playlists by name, no Spotify API search
- Search and filter stack -- searching within an active filter shows compound results
- Coverage bar: thin horizontal progress bar under playlist metadata showing BPM coverage percentage
- Color-coded bar: green (>80%), yellow (40-80%), red (<40%)
- Taller card height ~70pt (up from current 50pt) for breathing room with coverage bar
- Cover art scales up to ~56pt to match taller row proportions
- Unanalyzed playlists show subtle "Not analyzed" text in the coverage bar area (no empty bar)
- Text format: "42/50 BPM" alongside the bar with percentage
- Swipe-to-analyze retained AND long-press context menu added (dual entry points)
- Contextual swipe label: "Analyze" for unscanned, "Re-scan" for already scanned playlists
- Context menu items: Analyze BPM / Re-scan, Delete Scan (destructive style), Select for Run
- Delete Scan uses destructive button style, no confirmation alert
- "Select for Run" in context menu navigates to Run tab with playlist pre-loaded (uses existing SelectedTabKey)

### Claude's Discretion
- Coverage bar exact styling (height, corner radius, animation)
- Filter chip visual design (capsule shape, colors, selection state)
- Search debounce timing
- Empty state when search/filter returns no results
- Haptic feedback on filter/scan actions (BSHaptics tokens available)

### Deferred Ideas (OUT OF SCOPE)
None
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| LIB-01 | User can search playlists by name in real-time from Library view | `.searchable` modifier on NavigationStack, `@State searchText`, client-side `.filter` on playlist array |
| LIB-02 | User can filter playlists by status (All / Analyzed / Unanalyzed) | Filter chip enum + `@State`, compound filtering with search, coverage data lookup |
| LIB-03 | Playlist cards show scan quality with visual coverage indicator | Redesigned `PlaylistRow` with `ProgressView` or `GeometryReader` bar, numeric coverage data from `ScannedPlaylist` |
| LIB-04 | User can scan/delete scan via swipe action or context menu | `.contextMenu` modifier, contextual swipe labels, new `deleteScan` method in `LibraryScanService` |
</phase_requirements>

## Standard Stack

### Core (already in project)
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| SwiftUI | iOS 17+ | UI framework | Project minimum deployment target |
| SwiftData | iOS 17+ | Persistence for ScannedPlaylist | Already used for BPM cache and scan data |

### Supporting (already in project)
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| BSHaptics | n/a | Haptic feedback on filter/scan | Filter chip taps, scan actions |
| BSAnimation | n/a | Spring animations | Coverage bar fill, filter transitions |
| DesignTokens | n/a | Spacing, Color, Radius, Font, ComponentSize | All UI elements |

### No New Dependencies
This phase requires zero new libraries. Everything is built with SwiftUI primitives and existing design tokens.

## Architecture Patterns

### Recommended File Changes
```
BeatStep/
├── Views/Library/
│   ├── PlaylistListView.swift     # MODIFY: add search, filter, redesigned list
│   └── (PlaylistRow extracted if >80 lines)
├── Services/
│   └── LibraryScanService.swift   # MODIFY: add deleteScan method
└── DesignSystem/
    └── DesignTokens.swift         # MODIFY: add coverArtMedium = 56 if needed
```

### Pattern 1: Searchable + Client-Side Filtering
**What:** Use `.searchable` on the NavigationStack content, bind to `@State searchText`, compute filtered results inline.
**When to use:** When filtering already-loaded in-memory data.
**Example:**
```swift
@State private var searchText = ""

enum PlaylistFilter: String, CaseIterable {
    case all = "All"
    case analyzed = "Analyzed"
    case unanalyzed = "Unanalyzed"
}
@State private var activeFilter: PlaylistFilter = .all

private var filteredPlaylists: [SpotifyPlaylist] {
    var result = playlists

    // Apply status filter
    switch activeFilter {
    case .all: break
    case .analyzed:
        result = result.filter { coverageData[$0.id] != nil }
    case .unanalyzed:
        result = result.filter { coverageData[$0.id] == nil }
    }

    // Apply search
    if !searchText.isEmpty {
        result = result.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    return result
}

// Applied to List's parent:
.searchable(text: $searchText, prompt: "Search playlists")
```

### Pattern 2: Coverage Data Model Upgrade
**What:** Replace `coverageMap: [String: String]` with a richer struct that carries numeric data for the coverage bar.
**When to use:** When the row needs both numeric (bar width) and text (label) representations.
**Example:**
```swift
struct PlaylistCoverage {
    let tracksWithBPM: Int
    let totalTracks: Int

    var percentage: Double {
        guard totalTracks > 0 else { return 0 }
        return Double(tracksWithBPM) / Double(totalTracks)
    }

    var statusColor: Color {
        switch percentage {
        case 0.8...: return .stateSuccess   // green >80%
        case 0.4...: return .stateWarning   // yellow 40-80%
        default:     return .stateError     // red <40%
        }
    }

    var text: String { "\(tracksWithBPM)/\(totalTracks) BPM" }
}

// Replace: @State private var coverageMap: [String: String] = [:]
// With:    @State private var coverageData: [String: PlaylistCoverage] = [:]
```

### Pattern 3: Coverage Progress Bar
**What:** Thin colored bar showing BPM scan coverage percentage.
**Example:**
```swift
// Inside PlaylistRow
GeometryReader { geometry in
    ZStack(alignment: .leading) {
        // Background track
        RoundedRectangle(cornerRadius: 2)
            .fill(Color.surfaceOverlay)
            .frame(height: 4)

        // Filled portion
        RoundedRectangle(cornerRadius: 2)
            .fill(coverage.statusColor)
            .frame(width: geometry.size.width * coverage.percentage, height: 4)
    }
}
.frame(height: 4)
```

### Pattern 4: Context Menu with Conditional Actions
**What:** `.contextMenu` alongside `.swipeActions` for dual entry points.
**Example:**
```swift
.contextMenu {
    if coverageData[playlist.id] != nil {
        Button { /* re-scan */ } label: {
            Label("Re-scan", systemImage: "arrow.clockwise")
        }
        Button(role: .destructive) { /* delete scan */ } label: {
            Label("Delete Scan", systemImage: "trash")
        }
    } else {
        Button { /* analyze */ } label: {
            Label("Analyze BPM", systemImage: "waveform.badge.magnifyingglass")
        }
    }
    Button { /* select for run */ } label: {
        Label("Select for Run", systemImage: "figure.run")
    }
}
```

### Pattern 5: Delete Scan Implementation
**What:** New method on `LibraryScanService` to remove a `ScannedPlaylist` record.
**Example:**
```swift
// In LibraryScanService.swift
func deleteScan(playlistID: String) {
    let context = BPMCacheService.shared.context
    let descriptor = FetchDescriptor<ScannedPlaylist>(
        predicate: #Predicate { $0.spotifyPlaylistID == playlistID }
    )
    guard let existing = try? context.fetch(descriptor).first else { return }
    context.delete(existing)
    try? context.save()
}
```

### Pattern 6: Select for Run (Cross-Tab Navigation)
**What:** Use `SelectedTabKey` environment value to switch to Run tab.
**Example:**
```swift
@Environment(\.selectedTab) private var selectedTab

// In context menu action:
Button {
    selectedTab.wrappedValue = .run
    // RunTabView will need to accept a playlist parameter via environment or similar
} label: {
    Label("Select for Run", systemImage: "figure.run")
}
```

### Anti-Patterns to Avoid
- **Don't use `GeometryReader` at row level for sizing:** It causes layout thrashing in Lists. Use fixed frame sizes for the row; only use GeometryReader inside the progress bar which is constrained to a fixed height.
- **Don't debounce search with Combine:** SwiftUI's `.searchable` already handles input efficiently. A simple computed property is sufficient for client-side filtering of <500 playlists.
- **Don't create a separate ViewModel:** The existing pattern uses `@State` in the view. Stay consistent -- this is a SwiftUI-first project, not MVVM.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Search bar | Custom TextField in nav bar | `.searchable(text:prompt:)` | Handles pull-down behavior, keyboard, cancel button automatically |
| Progress bar | Custom drawing/Canvas | `GeometryReader` + `RoundedRectangle` | Simple, animatable, design-token compatible |
| Swipe actions | Custom gesture recognizers | `.swipeActions(edge:)` | Native List behavior, consistent with iOS patterns |
| Context menu | Custom overlay/popover | `.contextMenu {}` | OS-rendered, haptic feedback built in, accessibility free |

## Common Pitfalls

### Pitfall 1: coverageMap Race Condition
**What goes wrong:** `loadCoverageData()` reads from SwiftData on main thread while scan updates happen concurrently.
**Why it happens:** `ScannedPlaylist` updates happen during scan, but `coverageData` dictionary is only refreshed at specific points.
**How to avoid:** Keep the existing `onChange(of: scanService.scanningPlaylistID)` trigger to reload coverage after scan completes. Also reload after `deleteScan`.
**Warning signs:** Stale coverage numbers after scan completes.

### Pitfall 2: Filter Chips Scrolling with List
**What goes wrong:** If filter chips are placed inside the `List` as a header, they scroll away. If placed outside, they always show (not desired per CONTEXT.md -- they should scroll away with content).
**Why it happens:** SwiftUI `List` sections vs sticky headers vs inline content behave differently.
**How to avoid:** Place filter chips as the first item in the List (inside a `Section` with no header, or as a plain row with `.listRowSeparator(.hidden)`). This makes them scroll naturally with content.
**Warning signs:** Chips stuck at top or appearing above search bar.

### Pitfall 3: .searchable Placement
**What goes wrong:** `.searchable` must be applied to the correct view in the hierarchy to integrate with NavigationStack's search bar.
**Why it happens:** It needs to be on a view inside `NavigationStack`, typically on the `List` or its immediate parent.
**How to avoid:** Apply `.searchable` to the `playlistList` computed property or the `Group` in the body, inside the existing `NavigationStack` in `ContentView`.
**Warning signs:** Search bar not appearing, or appearing in wrong position.

### Pitfall 4: Pagination + Filtering Mismatch
**What goes wrong:** When filtering, the last-item trigger for pagination fires on the wrong item, or filtered results hide the trigger item.
**Why it happens:** `onAppear` for pagination checks `playlist.id == playlists.last?.id` but the user sees `filteredPlaylists`.
**How to avoid:** Keep pagination trigger on the UNFILTERED list's last item. The `ForEach` iterates `filteredPlaylists`, but the pagination `onAppear` should still check against `playlists.last?.id` (the raw data).
**Warning signs:** No new pages loading when scrolling through filtered results, or infinite loading.

### Pitfall 5: Context Menu + NavigationLink Conflict
**What goes wrong:** `.contextMenu` on a `NavigationLink` row can interfere -- long press triggers context menu instead of navigation.
**Why it happens:** Gesture conflict between NavigationLink tap and contextMenu long-press.
**How to avoid:** This is standard SwiftUI behavior and works correctly -- NavigationLink handles tap, contextMenu handles long-press. No special handling needed. Just apply `.contextMenu` on the `NavigationLink` or its content.
**Warning signs:** If both fire simultaneously (unlikely with standard modifiers).

## Code Examples

### Coverage Bar Component
```swift
struct CoverageBar: View {
    let coverage: PlaylistCoverage

    var body: some View {
        HStack(spacing: Spacing.sm) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.surfaceOverlay)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(coverage.statusColor)
                        .frame(width: geometry.size.width * coverage.percentage)
                }
            }
            .frame(height: 4)

            Text(coverage.text)
                .font(.captionText)
                .foregroundStyle(Color.textSecondary)
        }
    }
}
```

### Filter Chip Row
```swift
struct FilterChipRow: View {
    @Binding var activeFilter: PlaylistFilter

    var body: some View {
        HStack(spacing: Spacing.sm) {
            ForEach(PlaylistFilter.allCases, id: \.self) { filter in
                Button {
                    BSHaptics.selection()
                    withAnimation(BSAnimation.snappy) {
                        activeFilter = filter
                    }
                } label: {
                    Text(filter.rawValue)
                        .font(.captionBold)
                        .padding(.horizontal, Spacing.md)
                        .padding(.vertical, Spacing.xs)
                        .background(
                            activeFilter == filter ? Color.accent : Color.surfaceOverlay,
                            in: Capsule()
                        )
                        .foregroundStyle(
                            activeFilter == filter ? Color.textOnAccent : Color.textSecondary
                        )
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
    }
}
```

### Redesigned PlaylistRow Layout
```swift
// Height: 70pt, cover art: 56pt
HStack(spacing: Spacing.md) {
    // Cover art (56pt)
    coverArtView
        .frame(width: 56, height: 56)
        .clipShape(RoundedRectangle(cornerRadius: Radius.sm))

    VStack(alignment: .leading, spacing: Spacing.xxs) {
        Text(playlist.name)
            .font(.bodyText)
            .fontWeight(.semibold)
            .lineLimit(1)

        if let count = playlist.trackCount {
            Text("\(count) tracks")
                .font(.captionText)
                .foregroundStyle(Color.textSecondary)
        }

        // Coverage bar OR "Not analyzed" text
        if let coverage = coverageData {
            CoverageBar(coverage: coverage)
        } else if coverageLoaded {
            Text("Not analyzed")
                .font(.captionText)
                .foregroundStyle(Color.textTertiary)
        }
    }
}
.frame(height: 70)
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Custom search TextField | `.searchable` modifier | iOS 15+ (project uses 17+) | Native pull-down search, no custom UI |
| `.contextMenu` with preview | `.contextMenu` (simple) | iOS 16+ | Simpler API sufficient for this use case |

## Open Questions

1. **"Select for Run" playlist pre-loading mechanism**
   - What we know: `SelectedTabKey` switches tabs. `RunTabView` accepts `selectedTab` binding.
   - What's unclear: How to pass the selected playlist ID to `RunTabView` when switching. May need an `@AppStorage` or environment-based playlist ID.
   - Recommendation: Use `@AppStorage("lastSelectedPlaylistID")` or a shared observable to pass playlist ID. Investigate `RunTabView` init during implementation.

2. **ComponentSize.coverArtSmall is 44pt, need 56pt**
   - What we know: Current token is `coverArtSmall = 44`. New design calls for 56pt.
   - What's unclear: Whether to add a new token or use inline value.
   - Recommendation: Add `coverArtMedium: CGFloat = 56` to `ComponentSize` for reuse. Update row height constant similarly if not already tokenized.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | XCTest (iOS 17+) |
| Config file | BeatStepTests target in Xcode project |
| Quick run command | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BeatStepTests/LibraryScanServiceTests -quiet` |
| Full suite command | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' -quiet` |

### Phase Requirements to Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| LIB-01 | Search filters playlists by name | unit | Test `filteredPlaylists` computed property with search text | No -- Wave 0 |
| LIB-02 | Filter chips filter by analyzed status | unit | Test `filteredPlaylists` with filter enum states | No -- Wave 0 |
| LIB-03 | Coverage bar shows correct percentage/color | unit | Test `PlaylistCoverage` struct (percentage, statusColor) | No -- Wave 0 |
| LIB-04 | Delete scan removes ScannedPlaylist record | unit | `xcodebuild test -only-testing:BeatStepTests/LibraryScanServiceTests/testDeleteScan -quiet` | No -- Wave 0 |

### Sampling Rate
- **Per task commit:** Quick run targeting modified test files
- **Per wave merge:** Full test suite
- **Phase gate:** Full suite green before verify

### Wave 0 Gaps
- [ ] `BeatStepTests/PlaylistFilterTests.swift` -- covers LIB-01 + LIB-02 (filtering logic)
- [ ] `BeatStepTests/PlaylistCoverageTests.swift` -- covers LIB-03 (coverage model, color thresholds)
- [ ] Add `testDeleteScan` to existing `LibraryScanServiceTests.swift` -- covers LIB-04

## Sources

### Primary (HIGH confidence)
- Codebase analysis: `PlaylistListView.swift`, `LibraryScanService.swift`, `ScannedPlaylist.swift`, `DesignTokens.swift`, `BSHaptics.swift`, `BSAnimation.swift`, `ContentView.swift`
- SwiftUI `.searchable` modifier -- standard iOS 15+ API, well-documented
- SwiftUI `.contextMenu` modifier -- standard iOS 13+ API
- SwiftUI `.swipeActions` modifier -- standard iOS 15+ API

### Secondary (MEDIUM confidence)
- Filter chip scrolling behavior in SwiftUI Lists -- verified through common pattern knowledge

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- all SwiftUI built-in, no external deps
- Architecture: HIGH -- existing codebase patterns are clear and consistent
- Pitfalls: HIGH -- based on direct codebase analysis of current implementation

**Research date:** 2026-03-26
**Valid until:** 2026-04-26 (stable SwiftUI APIs, no fast-moving deps)
