# Phase 2: BPM Data Pipeline - Context

**Gathered:** 2026-03-20
**Status:** Ready for planning

<domain>
## Phase Boundary

Source BPM data for the user's Spotify library via external API (GetSongBPM), cache it locally with SwiftData, and build the data layer for BPM-based song discovery from the Spotify catalog. The pre-run UX that uses discovery comes in Phase 4 -- this phase builds the pipeline and API capability.

</domain>

<decisions>
## Implementation Decisions

### BPM source & fallbacks
- GetSongBPM as the sole BPM provider for now -- no multi-API fallback
- Tracks without BPM data are marked as unknown and excluded from BPM matching
- Coverage stat shown per playlist (e.g., "142 of 200 tracks have BPM") + per-track BPM badges in detail view
- Researcher should investigate 2-3 alternative BPM APIs (coverage, rate limits, pricing) as contingency research, but we don't build them

### Library scan timing
- Background scan triggers automatically after first Spotify login
- Rescan on each app launch (delta only -- only fetch BPM for new/changed tracks)
- User picks which playlists to scan ("running playlists" model) -- not all playlists scanned automatically
- Subtle progress indicator on library screen: "Scanning BPM data... 142/200"

### BPM discovery
- Phase 2 builds the data layer only: Spotify catalog search-by-BPM API capability
- Pre-run UX that uses this capability comes in Phase 4 when the run flow exists
- Discovered tracks are saved to an auto-created "BeatStep Discoveries" playlist on Spotify
- Playlist auto-created silently on first discovery -- no confirmation prompt

### Data display & caching
- BPM number badge ("172 BPM") shown next to each track in playlist detail view; tracks without BPM show "--"
- Mini-player updated in Phase 2 to show real BPM (replacing the "-- BPM" placeholder from Phase 1)
- BPM cached permanently in SwiftData -- a song's BPM doesn't change, no TTL needed
- SwiftData for local storage (integrates well with SwiftUI, good for structured track-to-BPM mappings)

### Claude's Discretion
- BPM data model structure in SwiftData
- API rate limiting and batching strategy for GetSongBPM
- Error handling for API failures during scan
- Loading states during scan

</decisions>

<specifics>
## Specific Ideas

- "Running playlists" concept: user marks which playlists to scan, not all playlists scanned by default
- Discovered catalog tracks saved to a dedicated "BeatStep Discoveries" Spotify playlist -- persists across runs
- The coverage stat per playlist is the primary way users understand BPM data availability
- Fits the "turn it on and go" philosophy -- scanning happens automatically in background, BPM data is ready before the run

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- `SpotifyTrack` model (Models/SpotifyTrack.swift): Needs BPM field addition, currently has id, name, uri, durationMs, artists, album
- `SpotifyAPIService` (Services/SpotifyAPIService.swift): Authenticated request infrastructure ready for reuse -- can extend for catalog search
- `MiniPlayerView` (Views/Player/MiniPlayerView.swift): Has "-- BPM" placeholder ready for real data
- `PlaylistDetailView` (Views/Library/PlaylistDetailView.swift): Track list view where BPM badges will be added
- `KeychainManager` (Utilities/KeychainManager.swift): Token storage, reusable for API key storage if needed

### Established Patterns
- Singleton services (`SpotifyAPIService.shared`, `SpotifyPlayerService.shared`)
- Async/await for all API calls
- `PaginatedResponse<T>` generic for paginated Spotify API responses
- SwiftUI with `@Observable` pattern (via SpotifyPlayerService)

### Integration Points
- `SpotifyAPIService` -- extend with catalog search endpoint
- `SpotifyTrack` -- add BPM property (either on model or as a separate SwiftData entity linked by track ID)
- `PlaylistDetailView` -- add BPM badge to track rows
- `MiniPlayerView` -- wire up real BPM from cache
- `PlaylistListView` -- add coverage stat per playlist

</code_context>

<deferred>
## Deferred Ideas

None -- discussion stayed within phase scope

</deferred>

---

*Phase: 02-bpm-data-pipeline*
*Context gathered: 2026-03-20*
