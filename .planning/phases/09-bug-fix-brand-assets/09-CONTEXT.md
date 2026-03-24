# Phase 9: Bug Fix + Brand Assets - Context

**Gathered:** 2026-03-24
**Status:** Ready for planning

<domain>
## Phase Boundary

Fix the track count display bug (BUG-01), create an app icon (BRAND-01), and establish a wordmark (BRAND-02). This is the final phase of v1.1 "Dark by Design" — polish and brand identity, no new features.

</domain>

<decisions>
## Implementation Decisions

### Track Count Bug (BUG-01)
- When Spotify returns null for tracks/tracks.total, hide the count entirely — don't show "0 tracks"
- When Spotify explicitly returns total=0, show "0 tracks" — that's accurate (empty playlist)
- Change `trackCount` from `Int` to `Int?` — nil means unknown, 0 means genuinely empty
- Both PlaylistListView and PlaylistDetailView need the conditional display

### App Icon (BRAND-01)
- Abstract mark concept — not a letterform or literal symbol
- Heartbeat pulse / ECG shape — ties to #FF4545 accent and Run tab's waveform.path.ecg icon
- #FF4545 mark on near-black background (Color.surfaceBase range)
- Ultra-minimal — just the pulse mark and background, no glow/shadow/container
- Code-generated SVG/PDF — programmatic vector path, no external design tool
- Pulse mark lives on the icon only — not reused inside the app

### Wordmark (BRAND-02)
- "BEATSTEP" in SF Pro Bold, all caps
- White text (Color.textPrimary) — icon carries the accent color
- Wide letter-spacing (tracking) for premium/athletic feel
- Appears on login screen only — replaces the existing "BeatStep" Text() in LoginView
- Other screens continue using standard navigation titles

### Brand Cohesion
- Icon and wordmark are independent treatments — pulse mark on icon, typography for wordmark
- No pulse mark inside the app — brand is carried by accent color (#FF4545) and wordmark
- Login screen is the single brand moment: wordmark replaces current text, same position

### Claude's Discretion
- Exact pulse wave path geometry and proportions
- Exact letter-spacing value for the wordmark
- Icon background shade (within near-black range matching surfaceBase)
- How to generate and export icon at all required iOS sizes (29pt–1024pt)

</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- `DesignTokens.swift`: Color.accent (#FF4545), Color.surfaceBase (0.067 white), Color.textPrimary (white) — all icon/wordmark colors already defined
- `LoginView.swift`: Existing "BeatStep" Text() at line 14 area — wordmark replaces this with new styling
- `SpotifyPlaylist.swift`: `trackCount` computed property (line 23) — change return type from Int to Int?

### Established Patterns
- Design tokens as static Color/Font extensions — wordmark font token fits here
- SwiftUI throughout — icon can be generated via SwiftUI Canvas or Shape path
- No Asset Catalog currently in use — will need to create AppIcon.appiconset for the icon

### Integration Points
- `PlaylistListView.swift:175` — "\\(playlist.trackCount) tracks" display, needs conditional
- `PlaylistDetailView.swift:137` — same track count display pattern
- `LoginView.swift` — wordmark replaces existing branding Text()
- Asset Catalog needs creation for app icon (no existing .xcassets found)

</code_context>

<specifics>
## Specific Ideas

- Heartbeat pulse chosen to echo the #FF4545 accent color's heartbeat association (established in Phase 6) and the Run tab's waveform.path.ecg icon (Phase 7)
- Wide tracking on all-caps wordmark follows Peloton/Nike athletic brand convention
- Code-generated icon keeps everything in the codebase — easy to iterate on the pulse shape

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 09-bug-fix-brand-assets*
*Context gathered: 2026-03-24*
