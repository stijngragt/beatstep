# Phase 31: Settings + Skeleton States - Context

**Gathered:** 2026-03-26
**Status:** Ready for planning

<domain>
## Phase Boundary

Reorganize the Settings screen into discoverable grouped sections with SF Symbol icons, and replace ProgressView spinners with shimmer skeleton loading states in the Library views. Settings restructuring includes moving Running Zones to a sub-page. Skeleton coverage targets PlaylistListView and PlaylistDetailView.

</domain>

<decisions>
## Implementation Decisions

### Skeleton Design
- **D-01:** Gradient sweep shimmer — classic iOS pattern with a light gradient sweeping left-to-right across grey placeholder shapes
- **D-02:** Content-matched skeleton shapes — each skeleton mirrors the real row's structure (square for art, lines for title/subtitle, bar for coverage) to reduce layout shift
- **D-03:** Neutral grey color palette — shape fill ~#2A2A2A on dark background, shimmer peak ~#3A3A3A. No accent color tinting
- **D-04:** Fill visible area with skeleton rows (~6-8 rows for playlists) — no empty space below placeholders
- **D-05:** Fade crossfade transition from skeleton to content using BSAnimation.smooth

### Settings Visual Treatment
- **D-06:** Grouped inset List style — standard iOS rounded section cards with clear section headers
- **D-07:** SF Symbol icons next to each section header — all icons use heartbeat red (#FF4545), monochrome
- **D-08:** Running Zones moves to a sub-page via NavigationLink with chevron — keeps Settings compact

### Skeleton Coverage Scope
- **D-09:** PlaylistListView gets skeleton loading state (replaces ProgressView spinner)
- **D-10:** PlaylistDetailView gets skeleton loading state (replaces ProgressView spinner)
- **D-11:** RunTabView and Onboarding views keep their current ProgressView spinners — lower priority

### Settings Structure
Sections in order (from roadmap success criteria):
1. **Account** — Name, Plan, Disconnect Spotify (destructive)
2. **Run Defaults** — Running Zones (sub-page), No-BPM Tracks
3. **Permissions** — Motion Access, Apple Health, Open Settings button
4. **Debug** — Sensor Lab (when enabled via hidden toggle)
5. **About** — Version (dynamic, not hardcoded), hidden 5-tap debug toggle

### Claude's Discretion
- Exact SF Symbol names for each section
- Shimmer animation timing and gradient width
- Skeleton row spacing and corner radii
- Section header typography (existing design tokens)
- Whether "Disconnect Spotify" stays in Account or gets its own section
- Zone editing sub-page layout and navigation title

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Design System
- `BeatStep/DesignSystem/BSAnimation.swift` — Animation presets (.smooth for skeleton crossfade)
- `BeatStep/DesignSystem/BSHaptics.swift` — Haptic feedback tokens

### Settings (current)
- `BeatStep/Views/Settings/SettingsView.swift` — Current settings view to restructure
- `BeatStep/Views/Settings/ZoneSettingsRow.swift` — Zone row component to move to sub-page
- `BeatStep/Views/Settings/SensorLabView.swift` — Debug screen, stays behind hidden toggle

### Skeleton targets
- `BeatStep/Views/Library/PlaylistListView.swift` — Replace ProgressView with skeleton
- `BeatStep/Views/Library/PlaylistDetailView.swift` — Replace ProgressView with skeleton

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `BSAnimation.smooth` / `.gentle`: Spring and ease animations for skeleton crossfade transition
- `ZoneSettingsRow`: Existing zone editing component — can be reused in sub-page
- `PlaylistListView` row layout: Content-matched skeleton should mirror its structure (56pt art, title, subtitle, coverage bar)

### Established Patterns
- All views use design tokens (Color.textPrimary, Color.accent, Spacing.sm, etc.)
- List-based layouts with Section headers throughout the app
- `@AppStorage` for persisted settings (sensorLabEnabled, hasRequestedHealth, etc.)
- NavigationLink for drill-down pages (already used in Sensor Lab)

### Integration Points
- SettingsView is embedded in a NavigationStack via ContentView's tab bar
- PlaylistListView loading state triggered by `isLoading && playlists.isEmpty`
- PlaylistDetailView loading state triggered by `isLoading && tracks.isEmpty`

</code_context>

<specifics>
## Specific Ideas

- Skeleton for playlist rows should include: square placeholder for cover art, two text lines (title + subtitle), and a thin bar for the coverage indicator
- Settings version should be dynamic (read from bundle) instead of hardcoded "v1.4"
- SF Symbol icons should all be heartbeat red to maintain single-accent brand consistency

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 31-settings-skeleton-states*
*Context gathered: 2026-03-26*
