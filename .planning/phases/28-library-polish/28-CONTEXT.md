# Phase 28: Library Polish - Context

**Gathered:** 2026-03-26
**Status:** Ready for planning

<domain>
## Phase Boundary

Users can find, filter, and manage playlists efficiently with visual scan quality feedback and native iOS interaction patterns. Covers: search, filter chips, playlist card redesign with coverage bar, and contextual scan/delete-scan actions replacing the floating scan bar.

</domain>

<decisions>
## Implementation Decisions

### Search + Filter UX
- iOS native `.searchable` modifier — pull-down search bar in navigation bar, collapses when not in use
- Filter chips (All / Analyzed / Unanalyzed) sit below search bar and scroll away with list content
- Client-side filtering only — filter already-loaded playlists by name, no Spotify API search
- Search and filter stack — searching within an active filter shows compound results (e.g., "Analyzed" + search "run" = only analyzed playlists matching "run")

### Playlist Card Redesign
- Coverage bar: thin horizontal progress bar under playlist metadata showing BPM coverage percentage
- Color-coded bar: green (>80%), yellow (40-80%), red (<40%)
- Taller card height ~70pt (up from current 50pt) for breathing room with coverage bar
- Cover art scales up to ~56pt to match taller row proportions
- Unanalyzed playlists show subtle "Not analyzed" text in the coverage bar area (no empty bar)
- Text format: "42/50 BPM" alongside the bar with percentage

### Scan Actions
- Swipe-to-analyze retained AND long-press context menu added (dual entry points)
- Contextual swipe label: "Analyze" for unscanned, "Re-scan" for already scanned playlists
- Context menu items: Analyze BPM / Re-scan, Delete Scan (destructive style), Select for Run
- Delete Scan uses destructive button style, no confirmation alert (re-scannable data, low risk)
- "Select for Run" in context menu navigates to Run tab with playlist pre-loaded (uses existing SelectedTabKey)

### Claude's Discretion
- Coverage bar exact styling (height, corner radius, animation)
- Filter chip visual design (capsule shape, colors, selection state)
- Search debounce timing
- Empty state when search/filter returns no results
- Haptic feedback on filter/scan actions (BSHaptics tokens available)

</decisions>

<specifics>
## Specific Ideas

- Coverage bar visual similar to the preview: filled portion with percentage text
- Filter chips should feel like iOS native — compact, tappable capsules
- "Select for Run" context menu action leverages the SelectedTabKey pattern from Phase 25

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- `PlaylistListView` (BeatStep/Views/Library/PlaylistListView.swift): Current library view with pagination, swipe-to-analyze, coverage map
- `PlaylistRow`: Inline component showing cover art, name, track count, scan status — will be redesigned
- `ScannedPlaylist` SwiftData model: Has `tracksWithBPM` / `totalTracks` fields ready for coverage calculation
- `BSHaptics` / `BSAnimation`: Design system tokens from Phase 27 for haptic feedback and animations
- `SelectedTabKey` EnvironmentKey: Cross-tab navigation from Library to Run tab (Phase 25)
- Design tokens: `Spacing`, `Radius`, `Color`, `ComponentSize` — all established

### Established Patterns
- SwiftData `FetchDescriptor` for `ScannedPlaylist` queries (used in `loadCoverageData()`)
- `.swipeActions` on list rows for contextual actions
- `.navigationDestination` for playlist detail navigation
- `LibraryScanService.shared` for scan operations with progress tracking
- Paginated loading with offset/limit pattern

### Integration Points
- `PlaylistListView` is the main view to modify — add `.searchable`, filter state, redesigned rows
- `coverageMap: [String: String]` needs richer data (numerics for bar calculation, not just text)
- `scanService.scanPlaylistByID` for triggering scans from context menu
- `ContentView` tab selection binding for "Select for Run" action

</code_context>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 28-library-polish*
*Context gathered: 2026-03-26*
