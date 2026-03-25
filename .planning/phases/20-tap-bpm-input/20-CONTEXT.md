# Phase 20: Tap BPM Input - Context

**Gathered:** 2026-03-25
**Status:** Ready for planning

<domain>
## Phase Boundary

Manual BPM entry via tap-along interface for any track in playlist view. User taps along with the music to set BPM, which is saved via the existing `cacheManual()` write path from Phase 18 and reflected as a manual confidence badge from Phase 19. No mid-run tap BPM — this is a library-only feature.

</domain>

<decisions>
## Implementation Decisions

### Entry point
- Tapping the BPM capsule badge opens the tap interface (both `-- BPM` and existing confidence badges)
- All tracks are tappable — not just no-BPM tracks — so users can correct wrong API values
- Row tap still plays the track; badge tap opens tap BPM — two distinct gesture zones on TrackRow
- Opens as a half-sheet (`presentationDetents(.medium)`) — lightweight, playlist stays visible behind

### Tap screen layout
- Full-width tap zone dominating the bottom of the sheet — "tap anywhere" design, maximum surface area
- Header area shows: track name, artist, live BPM value, and tap count (e.g. "5/8 taps")
- Bottom bar has Reset button (left) and Save button (right)
- Save enabled after 4 taps (early save allowed) — not gated on full 8-tap stabilization
- Reset button for explicit do-over, plus 3-second inactivity auto-reset per TAP-02

### Stability feedback
- 8-dot progress indicator: filled dots = taps counted, hollow = remaining
- After 8 taps, "Stable" checkmark label appears next to dots
- BPM updates live on every valid tap — user sees it converge in real-time
- Outlier rejection: tap zone shakes briefly, dot doesn't fill, error haptic buzz
- Normal tap: tap zone flashes, dot fills, light impact haptic

### Playback
- Auto-play the track via Spotify when tap sheet opens (if already playing, no change)
- Playback is required — tap interface disabled if Spotify can't play the track
- Track keeps playing after sheet dismisses — user controls via MiniPlayer
- Haptic feedback: light impact on valid tap, error notification on outlier, success notification on save

### Save flow
- Save triggers: success haptic → sheet auto-dismisses → playlist row updates to manual badge immediately
- `bpmCache` dict in PlaylistDetailView refreshes after save (existing pattern from Phase 19)

### Claude's Discretion
- Exact outlier rejection algorithm (IQR, standard deviation, or percentage threshold)
- Tap zone visual design (color, animation on tap)
- Exact sheet height within `.medium` detent
- How to handle the first tap (no interval yet — show "--" for BPM)
- SwiftUI sheet presentation mechanics and state management

</decisions>

<specifics>
## Specific Ideas

- Full-width tap zone rather than a button — maximum tap target, minimal aiming
- Live BPM convergence gives the user confidence the algorithm is working
- The shake animation on outlier rejection is a brief, subtle feedback — not aggressive

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- `BPMCacheService.cacheManual(trackID:name:artist:bpm:)`: ready-to-use write path for saving tapped BPM
- `BPMCacheService.getBPMInfo(forTrackID:)`: returns BPMInfo struct for immediate badge refresh
- `BPMConfidence` enum with `.manual` case, `hand.raised.fill` icon, `.stateWarning` color
- `BPMInfo` struct: immutable data carrier with `bpm: Int?` and `confidence: BPMConfidence?`
- `TrackRow`: existing BPM capsule badge — needs separate tap gesture on the badge vs the row
- `DesignTokens`: Spacing, Radius, Color tokens for consistent styling
- `SpotifyPlayerService.shared`: playback control for auto-play on sheet open

### Established Patterns
- Half-sheet via `.sheet()` + `presentationDetents([.medium])` (standard SwiftUI)
- Haptic feedback via `UIImpactFeedbackGenerator` and `UINotificationFeedbackGenerator`
- `@State` for local view state, `@Observable` services for shared state
- Capsule badge pattern: `.font(.labelText)`, `.fontWeight(.bold)`, `Capsule().fill(color.opacity(0.15))`

### Integration Points
- `TrackRow` badge tap gesture → presents TapBPMView sheet with track info
- `PlaylistDetailView.bpmCache` dict → refresh entry after save
- `SpotifyPlayerService.shared.play(uri:contextURI:)` → auto-play on sheet open
- `BPMCacheService.shared.cacheManual()` → persist tapped BPM

</code_context>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 20-tap-bpm-input*
*Context gathered: 2026-03-25*
