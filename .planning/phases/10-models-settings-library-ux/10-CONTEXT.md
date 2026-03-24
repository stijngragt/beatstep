# Phase 10: Models, Settings & Library UX - Context

**Gathered:** 2026-03-24
**Status:** Ready for planning

<domain>
## Phase Boundary

Zone model and BPM defaults, per-zone configuration in Settings, playlist analyzed-state visibility in Library with inline swipe-to-analyze, and tolerance picker showing ±BPM deltas. No run flow changes (Phase 11) or onboarding (Phase 12).

</domain>

<decisions>
## Implementation Decisions

### Playlist analyzed indicator
- Fraction text as secondary label: "42/60 BPM" next to track count (e.g., "60 tracks · 42/60 BPM")
- Unanalyzed playlists show "Not analyzed" in the same position (muted text)
- Analyzed fraction uses accent red (#FF4545); "Not analyzed" uses warning color
- No binary threshold — always show exact fraction. "Not analyzed" only when zero lookups done
- Builds on existing `ScannedPlaylist.coverageText` pattern and `coverageMap` in `PlaylistListView`

### Inline analyze trigger
- Trailing swipe action on playlist rows — iOS-native `.swipeActions` pattern
- Swipe button color: accent red (#FF4545)
- Available on ALL playlists (not just unanalyzed) — re-analyze catches newly added tracks
- During analysis: replace fraction text with spinner + "Analyzing 12/35" using existing `ScanProgress` model
- After analysis completes: return to fraction display ("28/35 BPM")

### Zone settings in Settings
- "Running Zones" section inline in SettingsView list (not a sub-screen)
- Each zone as a row: "Z1 Recovery — 155 BPM", "Z2 Endurance — 165 BPM", etc.
- Tap a zone row to reveal inline Stepper for ±1 BPM adjustments
- "Reset to Defaults" button at bottom of section — no confirmation required
- Locked defaults: Z1=155, Z2=165, Z3=174, Z4=178, Z5=185
- Persisted in UserDefaults with fallback to compiled-in defaults

### Tolerance picker labels
- Segments show only "±3 BPM", "±7 BPM", "±12 BPM" — drop "Tight"/"Normal"/"Loose" names
- Stays in Run tab (per-run setting, not global)
- Small "BPM Tolerance" caption label above the segmented control
- Update `BPMTolerance.displayName` to return "±N BPM" format

### Claude's Discretion
- Zone model struct design (enum vs struct, Codable conformance)
- Stepper range validation (100–220 BPM)
- Exact spacing and typography for zone rows in Settings
- How to extract analyze logic from PlaylistDetailView into reusable service method

</decisions>

<specifics>
## Specific Ideas

No specific requirements — open to standard approaches

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- `BPMTolerance` enum: already has ±3/±7/±12 values, UserDefaults persistence, `.segmented` picker — needs label update only
- `TolerancePicker`: existing SwiftUI view with `.pickerStyle(.segmented)` — update text format
- `ScannedPlaylist` SwiftData model: tracks `tracksWithBPM`/`totalTracks` with `coverageText` computed property
- `PlaylistListView.coverageMap`: already maps playlist IDs to coverage text — extend to show "Not analyzed"
- `LibraryScanService.ScanProgress`: model for scan state (playlistName, scanned, total)
- `PacePreset` enum: current effort labels to be replaced by zone model

### Established Patterns
- UserDefaults for simple settings persistence (BPMTolerance uses this)
- SwiftData for cached data (ScannedPlaylist, CachedBPM)
- Design tokens: `Color.accent`, `Color.stateWarning`, `Color.textSecondary`, `Spacing.*`, `Font.captionText`
- Singleton services with `.shared` pattern

### Integration Points
- `SettingsView`: add "Running Zones" section between Account and Disconnect
- `PlaylistListView`: add `.swipeActions` to ForEach, extend coverageMap logic
- `PlaylistRow`: update coverage display with accent color and "Not analyzed" state
- `RunTabView` / `RunView`: tolerance picker label update (Phase 10), zone picker is Phase 11

</code_context>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 10-models-settings-library-ux*
*Context gathered: 2026-03-24*
