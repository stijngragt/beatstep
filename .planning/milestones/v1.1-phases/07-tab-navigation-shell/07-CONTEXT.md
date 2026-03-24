# Phase 7: Tab Navigation Shell - Context

**Gathered:** 2026-03-23
**Status:** Ready for planning

<domain>
## Phase Boundary

Bottom tab bar with Library, Run, and Settings tabs — the structural navigation container for all screens. Each tab maintains its own navigation state. MiniPlayer persists across all tabs. This phase does NOT add Run tab playlist context (NAV-04, Phase 8) or migrate views to design tokens (Phase 8).

</domain>

<decisions>
## Implementation Decisions

### Tab Icons
- Library: `music.note.list` — music note with list lines
- Run: `waveform.path.ecg` — heartbeat/pulse wave, ties into heartbeat accent theme
- Settings: `gearshape` — consistent with current toolbar icon
- Selected state: `.fill` variant (e.g., `gearshape.fill`), unselected uses outline
- Selected tint: accent color (#FF4545)
- Unselected tint: textTertiary (white at 35% opacity)

### Tab Bar Appearance
- Labels shown below icons ("Library", "Run", "Settings")
- Translucent blur background (.ultraThinMaterial) — matches MiniPlayer's current material style
- No separator line between content and tab bar — blur provides visual separation (consistent with Phase 6 "no borders on surfaces" decision)

### Run Tab Default State
- When no run is active: centered "Start Run" CTA button
- Accent-filled (#FF4545) large pill/rounded button — bold, draws the eye
- Just the button, no subtitle or context (Phase 8 NAV-04 adds playlist context)
- When run IS active: embed existing RunView directly — reuse what's built

### Claude's Discretion
- MiniPlayer positioning relative to tab bar (safeAreaInset approach)
- NavigationStack per tab implementation details
- Start Run button exact sizing and padding
- Tab bar height and safe area handling
- How to restructure ContentView from single NavigationStack to TabView

</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- `MiniPlayerView`: Already built with .ultraThinMaterial background, 64pt height — needs repositioning above tab bar
- `RunView`: Complete run interface with BPM display, controls, mode picker — embed directly in Run tab
- `PlaylistListView`: Current Library root view — becomes Library tab root
- `SettingsView`: Already exists — becomes Settings tab root
- `ModePicker`, `PacePresetPicker`: Run configuration components, used within RunView
- `DesignTokens.swift`: All color/spacing/radius tokens available (`Color.accent`, `Spacing.*`, `Radius.*`, `ComponentSize.miniPlayerHeight`)

### Established Patterns
- SwiftUI throughout, `@Environment` for service injection
- `SpotifyAuthService` as `@State` in BeatStepApp, passed via `.environment()`
- `SpotifyPlayerService.shared` and `RunEngineService.shared` as singletons
- MiniPlayer uses `SpotifyPlayerService.shared.currentTrack != nil` for visibility

### Integration Points
- `ContentView.swift`: Currently has single NavigationStack + ZStack for MiniPlayer — this is the main file to restructure into TabView
- `BeatStepApp.swift`: App entry point with dark mode enforcement and SwiftData container — unchanged
- `Color.clear.frame(height: 64)` safeAreaInset in ContentView — needs to account for tab bar too
- Settings currently accessed via toolbar NavigationLink — toolbar item removed, becomes its own tab

</code_context>

<specifics>
## Specific Ideas

- waveform.path.ecg icon for Run tab deliberately chosen to echo the heartbeat theme of the #FF4545 accent color
- Tab bar blur treatment matches MiniPlayer blur — unified material language across bottom chrome
- No separator line carries forward the "no borders" philosophy from Phase 6 design decisions

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 07-tab-navigation-shell*
*Context gathered: 2026-03-23*
