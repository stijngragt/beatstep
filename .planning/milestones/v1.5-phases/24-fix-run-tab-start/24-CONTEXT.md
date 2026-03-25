# Phase 24: Fix Run Tab Start - Context

**Gathered:** 2026-03-25
**Status:** Ready for planning

<domain>
## Phase Boundary

Make the Run tab's Start Run button work reliably. User taps Start Run and a run begins with the selected playlist, zone, and tolerance. Returning users see their last-used settings pre-loaded. Run tab is the config screen — no intermediate RunView step.

Requirements: FLOW-02 (button works), FLOW-05 (last settings pre-loaded).

</domain>

<decisions>
## Implementation Decisions

### Start flow
- Start Run taps go straight to ActiveRunView via fullScreenCover — skip RunView entirely
- Run tab IS the config screen (playlist, zone, tolerance shown and editable)
- Same fullScreenCover pattern as existing RunView → ActiveRunView transition (Phase 15/16)
- RunView in Library tab stays as-is for Phase 24 (Phase 25 removes it)

### Playlist data loading
- Eager fetch: load full playlist + tracks on Run tab .onAppear using LastRunPlaylist.id
- Start Run tap is instant — data already in memory
- On fetch failure: disable Start Run button with subtle message ("Couldn't load playlist")
- Manual retry only (retry button or pull-to-refresh) — no auto-retry or background polling
- Re-fetch on .onAppear if LastRunPlaylist.id changed since last fetch

### No-playlist state
- Show "Pick a playlist to get started" with "Go to Library" button
- "Go to Library" programmatically switches to Library tab (not NavigationLink)
- Start Run button disabled when no playlist
- Stale playlist (deleted/private on Spotify): clear LastRunPlaylist, treat as no-playlist state

### Playlist change
- Playlist row on Run tab is tappable — switches to Library tab
- Run tab reads LastRunPlaylist on .onAppear and re-fetches if ID changed
- Phase 25 will add the Library → Run tab routing (write LastRunPlaylist + switch tab)
- For Phase 24: user picks in Library, starts a run there which writes LastRunPlaylist, then Run tab picks it up next time

### Settings persistence
- Zone and tolerance save to UserDefaults immediately on change (not just on Start)
- Tolerance already has this via TolerancePicker — ensure zone picker matches
- On .onAppear: load zone from RunZone.selectedZoneId, tolerance from BPMTolerance.saved

### Claude's Discretion
- Loading state design while playlist fetches on tab appear
- Exact retry button placement and styling
- How to structure the playlist fetch (existing SpotifyAPIService methods)
- Error message copy for disabled Start button states

</decisions>

<specifics>
## Specific Ideas

- Run tab replaces RunView as the pre-run config screen — one tap to go
- The fullScreenCover pattern from Phase 15/16 is the proven approach for ActiveRunView presentation
- "Go to Library" should feel like a natural tab switch, not a modal or push navigation

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- `RunTabView.swift`: Already shows playlist name/image, zone picker, tolerance picker — needs wiring to engine
- `ActiveRunView.swift`: Full run screen with three-zone layout, already works via fullScreenCover
- `RunEngineService.startRun(playlist:tracks:)`: Existing method that starts the run engine
- `LastRunPlaylist`: UserDefaults wrapper with .name, .id, .imageURL — already persists last playlist
- `RunZone.selectedZoneId`: Static var persisting selected zone
- `BPMTolerance.saved`: Static var persisting tolerance
- `TolerancePicker`: Already saves on change

### Established Patterns
- fullScreenCover for active run (prevents swipe-back, hides tab bar)
- UserDefaults for simple state persistence (RunZone, BPMTolerance, LastRunPlaylist)
- TabView with per-tab NavigationStack — programmatic tab selection via @State binding
- RunView.swift lines 213-228: The working start-run logic (set engine mode/tolerance, save playlist, call startRun)

### Integration Points
- RunTabView needs to call RunEngineService.startRun(playlist:tracks:) with fetched data
- RunTabView needs to set runEngine.runMode, runEngine.tolerance before starting
- ContentView tab selection binding — needed for "Go to Library" programmatic tab switch
- SpotifyAPIService — for fetching playlist + tracks from saved ID
- CadenceService.requestPermissionAndStart() — must be called before run starts

</code_context>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 24-fix-run-tab-start*
*Context gathered: 2026-03-25*
