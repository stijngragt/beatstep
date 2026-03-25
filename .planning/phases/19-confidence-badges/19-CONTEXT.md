# Phase 19: Confidence Badges - Context

**Gathered:** 2026-03-25
**Status:** Ready for planning

<domain>
## Phase Boundary

Show BPM confidence visually per track in playlist detail view. Each track's BPM capsule gets a confidence icon and color based on its BPMConfidence level. Tracks without BPM data are visually distinguishable. No new data model changes — this phase consumes the confidence/source fields from Phase 18.

</domain>

<decisions>
## Implementation Decisions

### Badge placement
- Confidence icon sits inside the existing BPM capsule, left of the BPM text: `[icon X BPM]`
- Single compact element per track row — no separate icon outside the capsule
- No-BPM tracks also get a capsule (muted) for consistent row alignment

### Color per confidence
- Verified: green (reuse `stateSuccess` token)
- Manual: yellow (reuse `stateWarning` token)
- Approximate: blue (new token — subtle blue tone for "inferred/heuristic")
- No BPM: gray capsule at ~35% opacity (dim but same shape)

### SF Symbol icons
- Verified: `checkmark.seal.fill` — "certified by API"
- Manual: `hand.raised.fill` — "user set this"
- Approximate: `tilde` — "estimated"
- No BPM: no icon, just `-- BPM` text in muted gray

### No-BPM state
- Muted gray capsule with `[-- BPM]` text at reduced opacity
- Same capsule shape as confidence badges for visual consistency
- No action hint yet (Phase 20 adds tap BPM interaction)

### Claude's Discretion
- Data plumbing approach (how confidence reaches TrackRow — tuple, struct, or direct CachedBPM access)
- Exact blue color token value for approximate confidence
- Icon sizing relative to labelText font
- Exact capsule padding adjustments for icon + text
- Whether to show the approximate badge now (enum exists but no source maps to it yet) or defer rendering

</decisions>

<specifics>
## Specific Ideas

No specific references — open to standard approaches for SwiftUI capsule badges with SF Symbols.

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- `TrackRow` (Views/Library/PlaylistDetailView.swift:216): existing BPM badge with yellow capsule — modify to accept confidence and switch icon/color
- `BPMConfidence` (Models/BPMConfidence.swift): 3-case enum (verified/approximate/manual) with String rawValue
- `CachedBPM.confidence` (Models/CachedBPM.swift:18): computed property returning typed BPMConfidence? with lazy backfill
- `DesignTokens` (DesignSystem/DesignTokens.swift): stateSuccess (green), stateWarning (yellow), stateError (red) — reuse green and yellow, add blue

### Established Patterns
- Capsule badge with `.font(.labelText)`, `.fontWeight(.bold)`, horizontal/vertical padding, `Capsule().fill(color.opacity(0.15))` background
- Color tokens as static extensions on `Color`
- SF Symbols via `Image(systemName:)` at matching font size

### Integration Points
- `PlaylistDetailView.bpmCache: [String: Int?]` — needs to also carry confidence (currently only Int?)
- `BPMCacheService.shared.getBPM(forTrackID:)` — may need a sibling method or the view fetches CachedBPM directly
- `TrackRow(track:index:isPlaying:bpm:)` init — needs confidence parameter added

</code_context>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 19-confidence-badges*
*Context gathered: 2026-03-25*
