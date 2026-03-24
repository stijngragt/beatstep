# Phase 6: Design System Foundation - Context

**Gathered:** 2026-03-23
**Status:** Ready for planning

<domain>
## Phase Boundary

Enforce dark-mode-only UI globally, define color/typography/spacing design tokens in Swift, and get user approval on token definitions before any view migration begins. This phase does NOT migrate existing views to tokens -- that's Phase 8.

</domain>

<decisions>
## Implementation Decisions

### Accent Color
- Primary accent is #FF4545 (vibrant warm red / peach-red) -- heartbeat association, distances from Spotify's green
- Single accent color with opacity variants (no separate lighter/darker shades)
- Opacity levels used for subtle backgrounds (~15%), secondary emphasis (~60%), and full accent (100%)
- Spotify login button keeps Spotify brand green (#1DB954) as a named SpotifyBrand token -- do not use app accent for third-party auth

### Background Levels
- Near-black base (not true #000000) -- softer, allows subtle surface differentiation
- 3 levels with subtle steps between them (small jumps, not dramatic contrast)
- Surfaces (cards, sheets) differentiated by background shade only -- no borders
- System elements (alerts, sheets, OAuth webview) use iOS system dark appearance, not custom overrides

### Typography Scale
- SF Pro for all text; SF Pro Rounded for numeric displays (BPM, cadence numbers)
- Body text at 16pt (slightly larger than iOS default for running-context readability)
- BPM display at hero size (48-56pt) in SF Pro Rounded -- dominant focal point on run screen
- Headings in Bold weight
- Captions smaller (13pt) AND lighter color -- hierarchy through both size and color

### Token Organization
- Tokens defined as Swift Color and Font extensions with static properties (e.g., Color.accent, Font.heading)
- Semantic/role-based naming: Color.textPrimary, Color.surfaceBase, etc. -- describes purpose, not visual
- All tokens in a single DesignTokens.swift file
- Swift code only -- no Asset Catalog color sets
- Spacing tokens also in the same file (padding scale, corner radii, component sizing)

### Dark Mode Enforcement
- Global dark mode via Info.plist + window-level override (DARK-01)
- Remove all conditional light/dark styling code (DARK-02) -- grep for preferredColorScheme should return zero hits outside AppEntry
- System UI elements (alerts, sheets) rely on iOS dark mode -- no custom overriding of system elements

### Claude's Discretion
- Exact hex values for the 3 background levels (within near-black range, subtle steps)
- Exact text color opacity levels for primary/secondary/tertiary
- Specific padding scale values and corner radii
- State colors (success/warning/error) -- derive from accent or choose complementary
- How to structure the DS-05 approval gate (how to present tokens for user review)

</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- No existing token infrastructure -- building from scratch
- LoginView has a local `spotifyGreen` constant that will become the SpotifyBrand token

### Established Patterns
- SwiftUI throughout, no UIKit views -- extensions on SwiftUI types are idiomatic
- RunView already uses Color.black.ignoresSafeArea() as dark background approach
- Views use inline .foregroundStyle/.font modifiers -- tokens replace these inline values

### Integration Points
- BeatStepApp.swift: Window-level dark mode override goes here
- Info.plist: UIUserInterfaceStyle = Dark for global enforcement
- 9 view files with hardcoded colors to be migrated in Phase 8: RunView, PacePresetPicker, MiniPlayerView, PlaylistDetailView, CadenceDisplayView, BeatStepApp, PlaylistListView, ContentView, LoginView
- RunView line 37: Only existing .preferredColorScheme(.dark) call -- will be replaced by global enforcement

</code_context>

<specifics>
## Specific Ideas

- Accent color #FF4545 chosen specifically to reference a heartbeat -- aligns with running/fitness domain
- Deliberately NOT green to avoid Spotify brand association -- BeatStep should have its own visual identity
- Near-black backgrounds (not true black) for softer, more refined dark aesthetic

</specifics>

<deferred>
## Deferred Ideas

None -- discussion stayed within phase scope

</deferred>

---

*Phase: 06-design-system-foundation*
*Context gathered: 2026-03-23*
