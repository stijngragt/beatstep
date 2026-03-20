# Phase 2: BPM Data Pipeline - Research

**Researched:** 2026-03-20
**Domain:** BPM data acquisition, caching (SwiftData), Spotify catalog search
**Confidence:** MEDIUM

## Summary

Phase 2 builds the BPM data pipeline: fetching BPM for the user's library tracks via GetSongBPM API, caching with SwiftData, and enabling Spotify catalog search for BPM-based discovery. The biggest technical risks are (1) GetSongBPM API coverage gaps and rate limits (not publicly documented) and (2) Spotify's deprecation of recommendations/audio-features endpoints meaning BPM-based catalog discovery must use GetSongBPM's `/tempo/` endpoint rather than Spotify directly.

The architecture is straightforward: a new `BPMService` singleton wraps GetSongBPM API calls, a `BPMCacheService` manages SwiftData persistence, and a `LibraryScanService` orchestrates background scanning of user-selected playlists. The existing `SpotifyAPIService` gets extended with a catalog search method for discovery. SwiftData is the right choice here -- it integrates natively with SwiftUI, supports `@Query` for reactive UI, and the data model is simple (track ID to BPM mapping).

**Primary recommendation:** Build a two-entity SwiftData model (CachedBPM for track-to-BPM mapping, ScannedPlaylist for tracking which playlists are scanned), with a dedicated `GetSongBPMService` that handles search-then-lookup pattern and rate limiting, and a `LibraryScanService` that orchestrates background scanning with progress reporting.

<user_constraints>

## User Constraints (from CONTEXT.md)

### Locked Decisions
- GetSongBPM as the sole BPM provider for now -- no multi-API fallback
- Tracks without BPM data are marked as unknown and excluded from BPM matching
- Coverage stat shown per playlist (e.g., "142 of 200 tracks have BPM") -- no per-track badges
- Background scan triggers automatically after first Spotify login
- Rescan on each app launch (delta only -- only fetch BPM for new/changed tracks)
- User picks which playlists to scan ("running playlists" model) -- not all playlists scanned automatically
- Subtle progress indicator on library screen: "Scanning BPM data... 142/200"
- Phase 2 builds the data layer only: Spotify catalog search-by-BPM API capability
- Pre-run UX that uses this capability comes in Phase 4 when the run flow exists
- Discovered tracks are saved to an auto-created "BeatStep Discoveries" playlist on Spotify
- Playlist auto-created silently on first discovery -- no confirmation prompt
- BPM number badge ("172 BPM") shown next to each track in playlist detail view; tracks without BPM show "--"
- Mini-player updated in Phase 2 to show real BPM (replacing the "-- BPM" placeholder from Phase 1)
- BPM cached permanently in SwiftData -- a song's BPM doesn't change, no TTL needed
- SwiftData for local storage

### Claude's Discretion
- BPM data model structure in SwiftData
- API rate limiting and batching strategy for GetSongBPM
- Error handling for API failures during scan
- Loading states during scan

### Deferred Ideas (OUT OF SCOPE)
None -- discussion stayed within phase scope

</user_constraints>

<phase_requirements>

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| BPM-01 | App acquires BPM data for songs via external API (not Spotify Audio Features) | GetSongBPM API endpoints documented: search + song lookup pattern; rate limiting strategy recommended |
| BPM-05 | App pre-scans and caches BPM data for user's Spotify library | SwiftData model design, LibraryScanService architecture, delta-scan strategy documented |
| SPOT-05 | App can discover new songs from Spotify catalog at matching BPM | Two-step discovery: GetSongBPM /tempo/ endpoint for BPM lookup + Spotify /search for playback URIs; "BeatStep Discoveries" playlist creation via Spotify API |

</phase_requirements>

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| SwiftData | iOS 17+ (built-in) | Local BPM cache persistence | Native Apple framework, integrates with SwiftUI @Query, no dependency needed |
| URLSession | iOS 17+ (built-in) | HTTP requests to GetSongBPM API | Already used in SpotifyAPIService, async/await pattern established |
| GetSongBPM API | v1 | BPM data source | Free API, JSON responses, search-by-title and lookup-by-BPM endpoints |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Spotify Web API | v1 | Catalog search, playlist creation | For SPOT-05 discovery and "BeatStep Discoveries" playlist |

### Alternatives Considered (Contingency Research per CONTEXT.md)
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| GetSongBPM | SongBPM (songbpm.com) | Different site, similar data -- appears to be related/mirror of GetSongBPM |
| GetSongBPM | Soundcharts Audio Features API | Commercial API with BPM/key/time signature; better coverage likely but paid tier required |
| GetSongBPM | MusicGPT API (docs.musicgpt.com) | Key & BPM extraction API; requires audio file upload, not metadata lookup -- different use case |
| GetSongBPM | AcousticBrainz | Stopped collecting data in 2022; existing data available via MusicBrainz IDs but no new tracks added; database is static |

**Note:** AcousticBrainz is not viable as primary due to no new data since 2022. Soundcharts is the strongest fallback if GetSongBPM proves insufficient. None are built in Phase 2 per locked decision.

**No new dependencies needed in project.yml** -- SwiftData is built into iOS 17 SDK, and HTTP networking uses URLSession.

## Architecture Patterns

### Recommended Project Structure
```
BeatStep/
  Models/
    CachedBPM.swift            # SwiftData @Model for track-to-BPM cache
    ScannedPlaylist.swift       # SwiftData @Model for user's selected playlists
    GetSongBPMResponse.swift    # Codable types for API responses
  Services/
    GetSongBPMService.swift     # API client for getsongbpm.com
    BPMCacheService.swift       # SwiftData read/write operations
    LibraryScanService.swift    # Orchestrates background BPM scanning
    SpotifyAPIService.swift     # Extended with catalog search + playlist creation
```

### Pattern 1: SwiftData @Model for BPM Cache
**What:** Separate SwiftData entity for BPM data, linked to Spotify tracks by ID -- not embedded in SpotifyTrack (which is a Codable struct from API)
**When to use:** Always. SpotifyTrack is a Codable API response model; CachedBPM is a persistence model. Mixing concerns creates problems.
**Example:**
```swift
import SwiftData

@Model
final class CachedBPM {
    @Attribute(.unique) var spotifyTrackID: String
    var trackName: String
    var artistName: String
    var bpm: Int?              // nil = lookup attempted, no result found
    var lookupAttempted: Bool   // true = we tried API, false = not yet scanned
    var lastUpdated: Date

    init(spotifyTrackID: String, trackName: String, artistName: String, bpm: Int? = nil, lookupAttempted: Bool = false) {
        self.spotifyTrackID = spotifyTrackID
        self.trackName = trackName
        self.artistName = artistName
        self.bpm = bpm
        self.lookupAttempted = lookupAttempted
        self.lastUpdated = Date()
    }
}
```

### Pattern 2: SwiftData ModelContainer in App + Service Access
**What:** Create ModelContainer at app root, pass context to services via singleton pattern
**When to use:** For services that need to read/write SwiftData outside of SwiftUI views
**Example:**
```swift
// In BeatStepApp.swift
@main
struct BeatStepApp: App {
    let container: ModelContainer

    init() {
        let schema = Schema([CachedBPM.self, ScannedPlaylist.self])
        let config = ModelConfiguration(schema: schema)
        container = try! ModelContainer(for: schema, configurations: [config])
        BPMCacheService.shared.setContainer(container)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
}

// In BPMCacheService
@MainActor
final class BPMCacheService {
    static let shared = BPMCacheService()
    private var container: ModelContainer?

    func setContainer(_ container: ModelContainer) {
        self.container = container
    }

    var context: ModelContext {
        container!.mainContext
    }
}
```

### Pattern 3: Two-Step GetSongBPM Lookup
**What:** Search by song title + artist to get GetSongBPM song ID, then fetch song details for tempo
**When to use:** For every track BPM lookup (this is how the API works)
**Example:**
```swift
// Step 1: Search
// GET https://api.getsongbpm.com/search/?api_key=KEY&type=song&lookup=Run+Boy+Run
// Response: { "search": [{ "id": "abc123", "title": "Run Boy Run", ... }] }

// Step 2: Get song details with BPM
// GET https://api.getsongbpm.com/song/?api_key=KEY&id=abc123
// Response: { "song": { "id": "abc123", "title": "Run Boy Run", "tempo": "168", ... } }
```

### Pattern 4: Background Scan with Progress
**What:** LibraryScanService iterates playlist tracks, checks cache, fetches missing BPMs
**When to use:** On app launch (delta scan) and after playlist selection
**Example:**
```swift
@Observable
final class LibraryScanService {
    var scanProgress: ScanProgress?

    struct ScanProgress {
        let playlistID: String
        var scanned: Int
        var total: Int
        var isComplete: Bool { scanned >= total }
    }

    func scanPlaylist(_ playlist: SpotifyPlaylist, tracks: [SpotifyTrack]) async {
        let uncached = tracks.filter { !BPMCacheService.shared.hasLookup(for: $0.id) }
        scanProgress = ScanProgress(playlistID: playlist.id, scanned: 0, total: uncached.count)

        for track in uncached {
            let bpm = try? await GetSongBPMService.shared.fetchBPM(title: track.name, artist: track.artistName)
            BPMCacheService.shared.cache(trackID: track.id, name: track.name, artist: track.artistName, bpm: bpm)
            scanProgress?.scanned += 1
        }

        scanProgress = nil
    }
}
```

### Pattern 5: Spotify Catalog Search + Playlist Creation for Discovery
**What:** Use Spotify search API to find tracks, use GetSongBPM /tempo/ to find songs at a BPM, cross-reference
**When to use:** For SPOT-05 discovery capability
**Example:**
```swift
// Discovery approach:
// 1. GetSongBPM /tempo/ endpoint: GET https://api.getsongbpm.com/tempo/?api_key=KEY&bpm=170
//    Returns list of songs at that BPM
// 2. For each result, search Spotify: GET https://api.spotify.com/v1/search?q=track:SongTitle+artist:ArtistName&type=track&limit=1
//    Gets Spotify URI for playback
// 3. Add to "BeatStep Discoveries" playlist via Spotify API

// Spotify playlist creation (one-time):
// POST https://api.spotify.com/v1/users/{user_id}/playlists
// Body: { "name": "BeatStep Discoveries", "description": "Songs discovered by BeatStep", "public": false }

// Add tracks to playlist:
// POST https://api.spotify.com/v1/playlists/{playlist_id}/tracks
// Body: { "uris": ["spotify:track:xxx"] }
```

### Anti-Patterns to Avoid
- **Embedding BPM in SpotifyTrack:** SpotifyTrack is a Codable API model. Adding a mutable BPM field breaks its clean API-response nature. Use a separate SwiftData entity.
- **Scanning all playlists automatically:** User explicitly picks "running playlists" -- do not scan everything. This respects API rate limits and user intent.
- **Blocking UI on scan:** Scanning is background work. The UI must remain responsive with a subtle progress indicator, not a modal/blocking state.
- **Calling GetSongBPM without rate limiting:** The API is free -- abusing it risks account suspension. Implement delays between batched requests.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Local persistence | Custom file-based cache or UserDefaults | SwiftData @Model | SwiftData gives reactive queries, indexing, migration support, SwiftUI integration |
| API rate limiting | Manual timer/queue | Simple async semaphore + delay pattern | Keep it simple -- a 200-500ms delay between requests is sufficient for free API |
| JSON decoding | Manual JSON parsing | Swift Codable with JSONDecoder | Already established pattern in codebase |
| Spotify playlist CRUD | Raw URLRequest building | Extend SpotifyAPIService.authenticatedRequest | Reuse existing auth + error handling infrastructure |

**Key insight:** The codebase already has clean patterns (singleton services, async/await, Codable) -- extend them rather than introducing new paradigms.

## Common Pitfalls

### Pitfall 1: GetSongBPM Search Mismatches
**What goes wrong:** Song title from Spotify doesn't match GetSongBPM's database entry (e.g., "Run Boy Run - Live Version" vs "Run Boy Run")
**Why it happens:** Different metadata standards between Spotify and GetSongBPM
**How to avoid:** Strip common suffixes (Remastered, Live, Remix, feat., etc.) before searching. If title-artist search fails, fall back to title-only search (API does this automatically). Mark unmatched tracks as `lookupAttempted = true, bpm = nil`.
**Warning signs:** Low BPM coverage rates during testing (below 60-70%)

### Pitfall 2: Rate Limiting / Account Suspension
**What goes wrong:** GetSongBPM suspends API key for excessive requests
**Why it happens:** Free API with unspecified rate limits; scanning hundreds of tracks fires rapid requests
**How to avoid:** Batch requests with 200-500ms delay between calls. Each track requires 2 API calls (search + song detail), so a 200-track playlist = 400 requests. At 300ms delay = ~2 minutes. Show progress to user.
**Warning signs:** 429 responses or account suspension notice

### Pitfall 3: SwiftData Threading Issues
**What goes wrong:** Crashes when accessing ModelContext from background thread
**Why it happens:** ModelContext is not thread-safe; must stay on the thread that created it
**How to avoid:** Use `@MainActor` for BPMCacheService, or create a separate ModelContext for background work using `ModelContext(container)`. For scanning, batch cache writes on MainActor.
**Warning signs:** EXC_BAD_ACCESS crashes during background scan

### Pitfall 4: Spotify Search Limit Reduction (Feb 2026)
**What goes wrong:** Spotify search now returns max 10 results per request (was 50)
**Why it happens:** Spotify Web API Feb 2026 changes reduced search limit from 50 to 10
**How to avoid:** When searching Spotify catalog for discovered tracks, use specific queries (`track:"Song Title" artist:"Artist Name"`) to maximize first-result accuracy. Limit=1 is fine for matching.
**Warning signs:** Unexpected pagination needed or empty results

### Pitfall 5: Delta Scan Logic Errors
**What goes wrong:** Tracks get re-scanned unnecessarily on every launch, wasting API calls
**Why it happens:** Not properly tracking which tracks have been looked up (including failed lookups)
**How to avoid:** The `lookupAttempted` flag on CachedBPM distinguishes "never tried" from "tried but no result". Delta scan only fetches BPM for tracks NOT in the CachedBPM table at all.
**Warning signs:** Slow app launch, excessive API usage

## Code Examples

### GetSongBPM API Service
```swift
// Source: Verified from GetSongBPM API docs + community usage
final class GetSongBPMService {
    static let shared = GetSongBPMService()

    private let baseURL = "https://api.getsongbpm.com"
    private let apiKey: String  // Store in Keychain or config

    // Search for a song and get its BPM
    func fetchBPM(title: String, artist: String) async throws -> Int? {
        // Step 1: Search for the song
        let query = "\(title) \(artist)"
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? title
        let searchURL = URL(string: "\(baseURL)/search/?api_key=\(apiKey)&type=song&lookup=\(query)")!

        let (searchData, _) = try await URLSession.shared.data(from: searchURL)
        let searchResponse = try JSONDecoder().decode(GetSongBPMSearchResponse.self, from: searchData)

        guard let firstResult = searchResponse.search.first else { return nil }

        // Rate limit delay
        try await Task.sleep(nanoseconds: 300_000_000) // 300ms

        // Step 2: Get song details with BPM
        let songURL = URL(string: "\(baseURL)/song/?api_key=\(apiKey)&id=\(firstResult.id)")!
        let (songData, _) = try await URLSession.shared.data(from: songURL)
        let songResponse = try JSONDecoder().decode(GetSongBPMSongResponse.self, from: songData)

        guard let tempoString = songResponse.song.tempo,
              let tempo = Int(tempoString) else { return nil }
        return tempo
    }

    // Search songs by BPM (for discovery - SPOT-05)
    func fetchSongsByBPM(_ bpm: Int) async throws -> [GetSongBPMSong] {
        let url = URL(string: "\(baseURL)/tempo/?api_key=\(apiKey)&bpm=\(bpm)")!
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(GetSongBPMTempoResponse.self, from: data)
        return response.tempo
    }
}
```

### GetSongBPM Response Models
```swift
// Source: Verified from API usage examples and Perl wrapper library
struct GetSongBPMSearchResponse: Codable {
    let search: [GetSongBPMSearchResult]
}

struct GetSongBPMSearchResult: Codable {
    let id: String
    let title: String?
    let artist: GetSongBPMArtist?
}

struct GetSongBPMSongResponse: Codable {
    let song: GetSongBPMSong
}

struct GetSongBPMSong: Codable {
    let id: String
    let title: String?
    let tempo: String?          // BPM as string, e.g. "168"
    let artist: GetSongBPMArtist?
    let album: GetSongBPMAlbum?
}

struct GetSongBPMArtist: Codable {
    let id: String?
    let name: String?
}

struct GetSongBPMAlbum: Codable {
    let title: String?
}

struct GetSongBPMTempoResponse: Codable {
    let tempo: [GetSongBPMSong]
}
```

### SwiftData ScannedPlaylist Model
```swift
import SwiftData

@Model
final class ScannedPlaylist {
    @Attribute(.unique) var spotifyPlaylistID: String
    var name: String
    var isEnabled: Bool         // User toggle for "running playlist"
    var totalTracks: Int
    var tracksWithBPM: Int      // For coverage stat
    var lastScanned: Date?

    init(spotifyPlaylistID: String, name: String, isEnabled: Bool = false, totalTracks: Int = 0) {
        self.spotifyPlaylistID = spotifyPlaylistID
        self.name = name
        self.isEnabled = isEnabled
        self.totalTracks = totalTracks
        self.tracksWithBPM = 0
        self.lastScanned = nil
    }

    var coverageText: String {
        "\(tracksWithBPM) of \(totalTracks) tracks have BPM"
    }
}
```

### Extending SpotifyAPIService for Catalog Search + Playlist Creation
```swift
extension SpotifyAPIService {
    // Search Spotify catalog for a specific track (for discovery cross-reference)
    func searchTrack(title: String, artist: String, limit: Int = 1) async throws -> [SpotifyTrack] {
        let query = "track:\(title) artist:\(artist)"
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? title
        let url = URL(string: "\(baseURL)/search?q=\(query)&type=track&limit=\(limit)")!

        struct SearchResponse: Decodable {
            let tracks: PaginatedResponse<SpotifyTrack>
        }
        let response: SearchResponse = try await authenticatedRequest(url: url)
        return response.tracks.items
    }

    // Create a playlist on user's Spotify account
    func createPlaylist(userID: String, name: String, description: String) async throws -> SpotifyPlaylist {
        let url = URL(string: "\(baseURL)/users/\(userID)/playlists")!
        // POST request with JSON body -- extend authenticatedRequest for POST
        // Body: { "name": name, "description": description, "public": false }
    }

    // Add tracks to a playlist
    func addTracksToPlaylist(playlistID: String, uris: [String]) async throws {
        let url = URL(string: "\(baseURL)/playlists/\(playlistID)/tracks")!
        // POST with body: { "uris": uris }
    }
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Spotify Audio Features API for BPM | External BPM APIs (GetSongBPM etc.) | Nov 2024 | Spotify deprecated audio-features; must use third-party for BPM data |
| Spotify Recommendations API with target_tempo | GetSongBPM /tempo/ + Spotify /search cross-reference | Nov 2024 | Recommendations endpoint deprecated for new apps; discovery requires two-API approach |
| Spotify search limit=50 | Spotify search limit=10 max | Feb 2026 | Pagination needed for search results; use precise queries to minimize |
| Core Data for local persistence | SwiftData | WWDC 2023 (iOS 17) | SwiftData is Apple's recommended replacement; macro-based, SwiftUI-native |

**Deprecated/outdated:**
- Spotify Audio Features endpoint: Returns 403 for new apps since Nov 2024
- Spotify Recommendations endpoint: Deprecated Nov 2024, no longer functional for new apps
- AcousticBrainz: Stopped collecting data in 2022, static database only

## Open Questions

1. **GetSongBPM API Rate Limits**
   - What we know: Free API, requires attribution link, no publicly documented rate limit
   - What's unclear: Exact requests/minute or requests/day before throttling or suspension
   - Recommendation: Start conservative (300ms between requests), monitor for 429 responses, adjust. Test with ~100 tracks early.

2. **GetSongBPM Coverage for Running Music**
   - What we know: Database has broad catalog of popular music with BPM data
   - What's unclear: Coverage percentage for typical Spotify playlists (especially niche genres)
   - Recommendation: Test coverage early in implementation with real playlists. If below 50%, investigate Soundcharts API as fallback.

3. **GetSongBPM /tempo/ Endpoint Pagination**
   - What we know: Endpoint exists and returns songs at a specific BPM
   - What's unclear: Whether it supports BPM ranges (e.g., 168-172) or only exact values; pagination parameters
   - Recommendation: Test endpoint during implementation. If no range support, query multiple exact BPMs (e.g., 168, 169, 170, 171, 172).

4. **GetSongBPM API Key Storage**
   - What we know: API requires api_key parameter; app already has KeychainManager
   - What's unclear: Whether API key should be bundled in app or fetched from server
   - Recommendation: For v1, store in app bundle (Info.plist or build config). Not a secret -- free API with attribution requirement. Can be extracted from app binary but risk is low.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | XCTest (built-in, iOS 17) |
| Config file | BeatStepTests target in project.yml |
| Quick run command | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BeatStepTests` |
| Full suite command | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16'` |

### Phase Requirements to Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| BPM-01 | GetSongBPM API response decoding | unit | `xcodebuild test -only-testing:BeatStepTests/GetSongBPMServiceTests` | No - Wave 0 |
| BPM-01 | BPM lookup two-step flow (search + song detail) | unit (mocked) | `xcodebuild test -only-testing:BeatStepTests/GetSongBPMServiceTests` | No - Wave 0 |
| BPM-05 | CachedBPM SwiftData model CRUD | unit | `xcodebuild test -only-testing:BeatStepTests/BPMCacheServiceTests` | No - Wave 0 |
| BPM-05 | Delta scan logic (skip already-cached tracks) | unit | `xcodebuild test -only-testing:BeatStepTests/LibraryScanServiceTests` | No - Wave 0 |
| BPM-05 | Coverage stat calculation | unit | `xcodebuild test -only-testing:BeatStepTests/ScannedPlaylistTests` | No - Wave 0 |
| SPOT-05 | Spotify catalog search response decoding | unit | `xcodebuild test -only-testing:BeatStepTests/SpotifyAPIServiceTests` | Partial (file exists, test needs adding) |
| SPOT-05 | GetSongBPM /tempo/ endpoint decoding | unit | `xcodebuild test -only-testing:BeatStepTests/GetSongBPMServiceTests` | No - Wave 0 |

### Sampling Rate
- **Per task commit:** Quick run command on affected test files
- **Per wave merge:** Full test suite
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] `BeatStepTests/GetSongBPMServiceTests.swift` -- covers BPM-01, SPOT-05 (API response decoding, mock responses)
- [ ] `BeatStepTests/BPMCacheServiceTests.swift` -- covers BPM-05 (SwiftData CRUD with in-memory container)
- [ ] `BeatStepTests/LibraryScanServiceTests.swift` -- covers BPM-05 (delta scan logic)
- [ ] `BeatStepTests/Mocks/MockGetSongBPMResponses.swift` -- mock JSON responses for GetSongBPM API
- [ ] SwiftData test setup: in-memory `ModelContainer` configuration for unit tests

## Sources

### Primary (HIGH confidence)
- Spotify Web API documentation - search endpoint, playlist CRUD, Feb 2026 changes
- Apple SwiftData documentation - @Model, ModelContainer, ModelContext, @Query
- GetSongBPM API (getsongbpm.com/api) - endpoints and authentication (verified via community code)

### Secondary (MEDIUM confidence)
- [GitHub: iandioch/songchallenge](https://github.com/iandioch/songchallenge/blob/master/get_track_bpms.py) - Verified GetSongBPM API search + song endpoints, response format
- [GitHub: ology/WebService-GetSongBPM](https://github.com/ology/WebService-GetSongBPM) - Perl wrapper confirming API endpoint structure
- [Yate Docs: GetSongBPM](https://2manyrobots.com/YateResources/docs/GetSongBPM.html) - Search matching behavior (title-artist, title-only fallback)
- [HackingWithSwift SwiftData tutorials](https://www.hackingwithswift.com/quick-start/swiftdata/) - ModelContainer patterns, @Query usage
- [Medium: SwiftData outside views](https://levelup.gitconnected.com/swiftui-use-swiftdata-outside-a-view-in-a-manager-class-viewmodel-d6659e7d3ad9) - Service singleton pattern with ModelContainer
- [Spotify Nov 2024 deprecation announcement](https://developer.spotify.com/blog/2024-11-27-changes-to-the-web-api/) - Audio Features + Recommendations deprecated
- [Spotify Feb 2026 migration guide](https://developer.spotify.com/documentation/web-api/tutorials/february-2026-migration-guide) - Search limit reduced to 10

### Tertiary (LOW confidence)
- GetSongBPM `/tempo/` endpoint details -- confirmed to exist but exact parameters (range support, pagination) not fully documented
- GetSongBPM rate limits -- not publicly documented anywhere; conservative approach recommended

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - SwiftData and URLSession are well-documented Apple frameworks; GetSongBPM API structure verified via multiple sources
- Architecture: HIGH - Patterns follow established codebase conventions (singleton services, async/await, Codable)
- Pitfalls: MEDIUM - Rate limits unverified; API coverage unknown until tested with real data
- GetSongBPM /tempo/ endpoint: LOW - Exists but parameters not fully documented; needs implementation-time validation

**Research date:** 2026-03-20
**Valid until:** 2026-04-20 (30 days -- APIs are stable but GetSongBPM could change without notice)
