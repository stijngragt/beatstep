---
phase: 02-bpm-data-pipeline
verified: 2026-03-20T00:30:00Z
status: human_needed
score: 13/13 must-haves verified
re_verification: true
prev_verification:
  previous_status: gaps_found
  previous_score: 10/13
  gaps_closed:
    - "LibraryScanService now calls GetSongBPMService.fetchBPM for each uncached track (not Spotify audio-features)"
    - "Cloudflare Worker proxy exists and GetSongBPMService routes all requests through proxyBaseURL"
    - "REQUIREMENTS.md accurately reflects functional status of BPM-01 and BPM-05 with gap-closure notes"
  gaps_remaining: []
  regressions: []
human_verification:
  - test: "Confirm BPM data displays in UI with live proxy and real API key"
    expected: "BPM badges show real numbers on tracks after scan; mini-player shows real BPM for current track; coverage stat updates"
    why_human: "End-to-end requires deployed Cloudflare Worker, configured Secrets.swift with proxy URL, and valid GetSongBPM API key. Cannot verify live data flow programmatically."
  - test: "Confirm scan progress banner appears during active scan"
    expected: "'Scanning BPM data... N/M' banner visible in playlist list view with spinner while scan runs"
    why_human: "Visual async behavior during per-track scan cannot be verified programmatically"
  - test: "Confirm BeatStep Discoveries playlist creation on first discovery save"
    expected: "Playlist created in user's Spotify account and reused on subsequent saves"
    why_human: "Requires live Spotify credentials with write scope and working GetSongBPM proxy"
---

# Phase 2: BPM Data Pipeline Verification Report

**Phase Goal:** Build the BPM data pipeline — SwiftData models, GetSongBPM API client, BPM cache, library scanning, and wire BPM data into all views.
**Verified:** 2026-03-20T00:30:00Z
**Status:** human_needed (all automated checks pass; end-to-end requires live API)
**Re-verification:** Yes — after gap closure plan 02-03

## Gap Closure Summary

The previous verification (score 10/13, `gaps_found`) identified three gaps:

1. LibraryScanService used Spotify audio-features instead of GetSongBPMService.fetchBPM (blocker — violated BPM-01)
2. No working BPM data source meant persistence infrastructure was functionally empty (partial)
3. REQUIREMENTS.md marked BPM-01 and BPM-05 as complete when they were functionally blocked (inaccurate)

Plan 02-03 addressed all three: deployed a Cloudflare Worker proxy to bypass bot protection on GetSongBPM, rewired LibraryScanService to use GetSongBPMService.fetchBPM per track, and updated REQUIREMENTS.md with accurate gap-closure notes.

**All three gaps are confirmed closed by codebase inspection.**

---

## Goal Achievement

### Observable Truths — Plan 02-01

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | GetSongBPM API responses decode correctly into Swift types | VERIFIED | `GetSongBPMResponse.swift` (50 lines): 7 Codable structs. Custom `init(from:)` in `GetSongBPMSearchResponse` handles both array (success) and dict (no-results) shapes — fixed in 02-03 |
| 2 | BPM data is cached in SwiftData and retrievable by Spotify track ID | VERIFIED (regression check) | `BPMCacheService.swift` unchanged from initial verification; `cache()`, `getBPM()`, `hasLookup()` all present |
| 3 | Two-step BPM lookup (search + song detail) works with rate limiting | VERIFIED | `GetSongBPMService.fetchBPM` uses `proxyBaseURL` for both search (`/search/`) and song-detail (`/song/`) requests. 300ms `Task.sleep` between calls present at line 76. Title-only search with client-side artist matching implemented |
| 4 | BPM data persists across app restarts without re-fetching from API | VERIFIED | SwiftData persistence wiring unchanged (correct). Scan path now calls `GetSongBPMService.shared.fetchBPM` which uses the proxy — real BPM values can now populate the cache |
| 5 | Tracks without BPM results are marked as lookupAttempted with nil bpm | VERIFIED | Per-track error handling in `LibraryScanService.scanPlaylist` (lines 56–65): catch block calls `BPMCacheService.shared.cache(..., bpm: nil)` per track. Error isolation is correct — one track failure does not affect others |

### Observable Truths — Plan 02-02

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 6 | User's selected playlists are scanned for BPM data in the background | VERIFIED (regression check) | `LibraryScanService.scanEnabledPlaylists()` unchanged; `ContentView` triggers it |
| 7 | Scan progress is visible on library screen | VERIFIED (regression check) | `scanProgress` set/incremented/cleared in `scanPlaylist`; `PlaylistListView` banner unchanged |
| 8 | BPM coverage stat shows per playlist | VERIFIED (regression check) | `updateScannedPlaylistCoverage` still called after scan loop; `PlaylistListView` coverage rendering unchanged |
| 9 | BPM badge appears next to each track in playlist detail view | VERIFIED (regression check) | `PlaylistDetailView` BPM badge rendering unchanged |
| 10 | Mini-player shows real BPM for current track instead of "-- BPM" placeholder | VERIFIED (regression check) | `MiniPlayerView` BPMCacheService reads unchanged |
| 11 | App can search GetSongBPM for songs at a specific BPM | VERIFIED (regression check) | `BPMDiscoveryService.discoverTracks(atBPM:)` calls `GetSongBPMService.shared.fetchSongsByBPM` which uses `proxyBaseURL` (line 99 of GetSongBPMService.swift) |
| 12 | Discovered tracks can be saved to a 'BeatStep Discoveries' Spotify playlist | VERIFIED (regression check) | `BPMDiscoveryService.saveToDiscoveryPlaylist` unchanged |
| 13 | Delta scan only fetches BPM for tracks not already in cache | VERIFIED | `LibraryScanService.scanPlaylist` line 27: `tracks.filter { !BPMCacheService.shared.hasLookup(forTrackID: $0.id) }` — delta filter present |

**Score: 13/13 truths verified**

---

## Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `bpm-proxy/src/index.ts` | Cloudflare Worker proxying requests to api.getsongbpm.com | VERIFIED | 68 lines. Handles GET/OPTIONS/non-GET. Strips client `api_key`, injects server-side key from `env.GETSONGBPM_API_KEY`. Browser-like headers to avoid bot detection. CORS headers present. |
| `bpm-proxy/wrangler.toml` | Worker config (name, compatibility_date, main) | VERIFIED | `name = "bpm-proxy"`, `main = "src/index.ts"`, `compatibility_date = "2026-03-20"` |
| `bpm-proxy/package.json` | Minimal package with wrangler devDependency | VERIFIED | `wrangler ^4.0.0` devDependency; `deploy` and `dev` scripts |
| `BeatStep/Services/GetSongBPMService.swift` | API client using proxyBaseURL for all requests | VERIFIED | `proxyBaseURL = Secrets.getSongBPMProxyURL` at line 7. All three endpoints (`/search/`, `/song/`, `/tempo/`) use `proxyBaseURL`. No `api_key` query param in client requests (proxy injects it). |
| `BeatStep/Services/LibraryScanService.swift` | Scan path using GetSongBPMService.fetchBPM per track | VERIFIED | 150 lines. Per-track loop at lines 42–68 calls `GetSongBPMService.shared.fetchBPM`. No reference to `fetchBatchAudioFeatures` in this file. |
| `BeatStep/Secrets.example.swift` | Documents new getSongBPMProxyURL config key | VERIFIED | Line 9: `static let getSongBPMProxyURL = "YOUR_CLOUDFLARE_WORKER_URL"` with comment |
| `BeatStep/Models/GetSongBPMResponse.swift` | Handles dict vs array response shapes | VERIFIED | Custom `init(from:)` decodes array on success, returns empty array on dict (no-results case) |
| `BeatStep/Services/BPMCacheService.swift` | SwiftData CRUD for BPM cache | VERIFIED (unchanged) | Confirmed present from prior verification |
| `BeatStep/Models/CachedBPM.swift` | SwiftData @Model | VERIFIED (unchanged) | Confirmed present from prior verification |
| `BeatStep/Models/ScannedPlaylist.swift` | SwiftData @Model | VERIFIED (unchanged) | Confirmed present from prior verification |
| `.planning/REQUIREMENTS.md` | Accurate status for BPM-01, BPM-05, SPOT-05 | VERIFIED | BPM-01 marked `[x]` with note "functionally complete after 02-03 gap closure"; BPM-05 marked `[x]` with note "scan uses GetSongBPM via proxy"; traceability table shows all three as "Complete (02-03 gap closure)" |

---

## Key Link Verification

### Plan 02-03 Key Links (previously failed)

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `BeatStep/Services/LibraryScanService.swift` | `BeatStep/Services/GetSongBPMService.swift` | `fetchBPM(title:artist:)` call for each uncached track | VERIFIED | Pattern `GetSongBPMService.shared.fetchBPM` found at line 45. No `fetchBatchAudioFeatures` reference in LibraryScanService. |
| `BeatStep/Services/GetSongBPMService.swift` | `bpm-proxy/src/index.ts` | HTTP requests to `proxyBaseURL` instead of direct api.getsongbpm.com | VERIFIED | `proxyBaseURL` used in all 3 endpoint calls (lines 59, 79, 99). Direct `baseURL` property kept but unused in production paths. |

### Plan 02-01 and 02-02 Key Links (previously verified — regression check)

| From | To | Via | Status |
|------|----|-----|--------|
| `GetSongBPMService.swift` | `GetSongBPMResponse.swift` | JSONDecoder decodes API responses | VERIFIED |
| `BPMCacheService.swift` | `CachedBPM.swift` | SwiftData ModelContext operations | VERIFIED |
| `BeatStepApp.swift` | `BPMCacheService.swift` | ModelContainer via setContainer | VERIFIED |
| `LibraryScanService.swift` | `BPMCacheService.swift` | hasLookup + cache calls | VERIFIED |
| `PlaylistDetailView.swift` | `BPMCacheService.swift` | getBPM per track in loadTracks | VERIFIED |
| `MiniPlayerView.swift` | `BPMCacheService.swift` | getBPM onAppear and onChange | VERIFIED |
| `BPMDiscoveryService.swift` | `GetSongBPMService.swift` | fetchSongsByBPM (discovery path) | VERIFIED |
| `BPMDiscoveryService.swift` | `SpotifyAPIService.swift` | searchTrack, createPlaylist, addTracksToPlaylist | VERIFIED |

---

## Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|-------------|--------|----------|
| BPM-01 | 02-01, 02-03 | App acquires BPM data via external API (not Spotify Audio Features) | SATISFIED | GetSongBPMService routes through Cloudflare Worker proxy. LibraryScanService calls `fetchBPM` per track. SpotifyAPIService.`fetchBatchAudioFeatures` exists as a method but is NOT called from the scan path. REQUIREMENTS.md updated with gap-closure note. |
| BPM-05 | 02-01, 02-02, 02-03 | App pre-scans and caches BPM data for user's Spotify library | SATISFIED | LibraryScanService.scanEnabledPlaylists() scans all enabled playlists. Delta scan filters uncached tracks. BPMCacheService persists results in SwiftData. Scan uses GetSongBPMService (via proxy) not Spotify audio-features. REQUIREMENTS.md updated. |
| SPOT-05 | 02-02 | App can discover new songs from Spotify catalog at matching BPM | SATISFIED | BPMDiscoveryService.discoverTracks(atBPM:) calls GetSongBPMService.fetchSongsByBPM (via proxy) then cross-references with SpotifyAPIService.searchTrack. saveToDiscoveryPlaylist creates/reuses "BeatStep Discoveries" playlist. |

No orphaned requirements for Phase 2 found in REQUIREMENTS.md.

---

## Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `BeatStep/Services/GetSongBPMService.swift` | 6 | `private let baseURL = "https://api.getsongbpm.com"` — dead code, no production path uses it | Info | Not a functional issue. `proxyBaseURL` is used in all endpoints. `baseURL` is unreachable dead code. Could be removed for clarity but causes no harm. |
| `bpm-proxy/wrangler.toml` | (all) | No `[vars]` or `[secrets]` section — GETSONGBPM_API_KEY must be set via `wrangler secret put` | Info | Correct by design (secrets should not be in wrangler.toml). Comment in file documents the setup step. User setup required before first deploy. |

No blockers or warnings found.

---

## Human Verification Required

### 1. BPM Display End-to-End

**Test:** Deploy the Cloudflare Worker (`cd bpm-proxy && npm install && npx wrangler deploy`). Set `GETSONGBPM_API_KEY` secret (`npx wrangler secret put GETSONGBPM_API_KEY`). Update `BeatStep/Secrets.swift` with the deployed worker URL in `getSongBPMProxyURL`. Build and run app. Authenticate with Spotify, navigate to a playlist, tap "Scan BPM".
**Expected:** BPM badges show real numbers after scan completes. Coverage stat updates. Mini-player shows real BPM when a scanned track plays.
**Why human:** Requires a deployed Cloudflare Worker, configured Secrets.swift, and valid API credentials. Cannot verify live data flow programmatically.

### 2. Scan Progress Banner Visibility

**Test:** Trigger a scan on a playlist with many uncached tracks and immediately navigate to the playlist list view.
**Expected:** "Scanning BPM data... N/M" banner visible at the top of the list with a spinner while scan runs.
**Why human:** Visual async behavior during the per-track scan loop cannot be verified programmatically.

### 3. Discovery Playlist Creation

**Test:** Call `BPMDiscoveryService.discoverTracks(atBPM: 170)` then `saveToDiscoveryPlaylist(tracks:)` with the result.
**Expected:** "BeatStep Discoveries" playlist created in the user's Spotify library. Subsequent saves add to the same playlist (playlist ID persisted in UserDefaults).
**Why human:** Requires live Spotify credentials with write scope and a working GetSongBPM proxy deployment.

---

## Gap Closure Confirmation

| Previous Gap | Resolution | Evidence |
|---|---|---|
| LibraryScanService used Spotify audio-features instead of GetSongBPMService.fetchBPM | CLOSED | `GetSongBPMService.shared.fetchBPM` called at LibraryScanService.swift:45. `fetchBatchAudioFeatures` not present in LibraryScanService. |
| Both BPM data sources blocked at runtime (no real BPM data flowing) | CLOSED (infrastructure) | Cloudflare Worker proxy in `bpm-proxy/src/index.ts` (68 lines, substantive). GetSongBPMService routes all requests through `proxyBaseURL`. Proxy uses browser-like headers to bypass Cloudflare bot detection. End-to-end requires human verification with live deploy. |
| REQUIREMENTS.md marked BPM-01 and BPM-05 as complete when functionally blocked | CLOSED | BPM-01 and BPM-05 marked `[x]` in REQUIREMENTS.md with notes referencing 02-03 gap closure. Traceability table updated. |

---

_Verified: 2026-03-20T00:30:00Z_
_Verifier: Claude (gsd-verifier)_
_Re-verification: Yes (after plan 02-03 gap closure)_
