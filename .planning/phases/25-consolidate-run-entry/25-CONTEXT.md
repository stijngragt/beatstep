# Phase 25: Consolidate Run Entry - Context

**Gathered:** 2026-03-25
**Status:** Ready for planning

<domain>
## Phase Boundary

Run tab is the single entry point for all runs. Kill the old RunView run screen, route Library's "Run with this playlist" to the Run tab with that playlist pre-loaded. No duplicate screens, no alternative run initiation paths.

Requirements: FLOW-01 (single entry point), FLOW-03 (Library routes to Run tab), FLOW-04 (old screen removed).

</domain>

<decisions>
## Implementation Decisions

### Library action design
- Replace the NavigationLink toolbar run icon in PlaylistDetailView with a prominent full-width CTA button in the playlist header area
- Button text: "Run with this playlist" with accent background, bold text — matches Start Run button style on Run tab
- Button is always visible regardless of BPM analysis state — zero-BPM fallback handles unanalyzed playlists
- Remove the figure.run toolbar icon entirely — CTA button is the single action
- Toolbar keeps only Scan BPM and Clear BPM

### Tab switch behavior
- Instant switch: tap CTA writes LastRunPlaylist, sets selectedTab = .run
- No toast, no animation delay — tab switches immediately
- RunTabView picks up new playlist on .onAppear via existing fetchPlaylistIfNeeded logic
- Library NavigationStack stays on PlaylistDetailView after switching — user returns to where they were

### Stale reference cleanup
- Delete RunView.swift entirely
- Remove NavigationLink to RunView in PlaylistDetailView toolbar (line 33-36)
- ActiveRunView stays — used by RunTabView and tests
- ActiveRunViewTests stay as-is
- PlaylistListView has no RunView references (confirmed clean)

### Tab selection mechanism
- Claude's Discretion: choose cleanest approach to pass tab selection binding from ContentView to PlaylistDetailView (Environment, @Binding chain, etc.)

### Claude's Discretion
- Tab selection binding architecture (Environment vs @Binding vs other)
- CTA button exact placement within playlist header (below track count)
- Loading state handling when Run tab fetches the newly-selected playlist

</decisions>

<specifics>
## Specific Ideas

- CTA button should feel like a sibling of the Run tab's Start Run button — same visual weight, accent fill, bold text
- The flow is: Library > PlaylistDetail > tap CTA > instant tab switch > Run tab shows playlist loading > ready to start (~0.5s)

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- `LastRunPlaylist`: UserDefaults wrapper with .name, .id, .imageURL — already used by RunTabView for playlist persistence
- `Tab` enum + `selectedTab` binding in ContentView — already supports programmatic tab switching
- `RunTabView.fetchPlaylistIfNeeded()`: Existing method that fetches playlist when LastRunPlaylist.id changes on .onAppear
- Start Run button styling in RunTabView (line 239-254): Reference for CTA button visual consistency

### Established Patterns
- `selectedTab = .library` already used in RunTabView for "Go to Library" button — reverse direction needed here
- `LastRunPlaylist` write + tab switch is the established routing mechanism (Phase 24 context confirmed this)
- fullScreenCover for ActiveRunView presentation

### Integration Points
- PlaylistDetailView needs access to tab selection (currently no binding — needs to be added)
- PlaylistDetailView toolbar: remove NavigationLink, toolbar keeps Scan + Clear
- PlaylistDetailView header: add CTA button below track count metadata

</code_context>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 25-consolidate-run-entry*
*Context gathered: 2026-03-25*
