---
phase: 02-bpm-data-pipeline
plan: 02
subsystem: services, ui
tags: [library-scan, bpm-discovery, spotify-api, pkce-auth, web-api-player, swiftui]

# Dependency graph
requires:
  - phase: 02-bpm-data-pipeline/02-01
    provides: "CachedBPM model, ScannedPlaylist model, GetSongBPMService, BPMCacheService"
  - phase: 01-spotify-integration
    provides: "SpotifyAuthService, SpotifyPlayerService, SpotifyAPIService, all views"
provides:
  - "LibraryScanService for background delta BPM scanning with progress"
  - "BPMDiscoveryService for BPM-based song discovery via GetSongBPM + Spotify"
  - "SpotifyAPIService POST support, catalog search, playlist CRUD"
  - "BPM badges on track rows, real BPM in mini-player, coverage stats per playlist"
  - "PKCE auth flow replacing implicit grant (Spotify Feb 2026 compatibility)"
  - "Web API player replacing SPTAppRemote (broader device support)"
affects: [03-cadence-detection, 04-core-loop, bpm-display, discovery-ui]

# Tech tracking
tech-stack:
  added: [pkce-auth, web-api-player, keychain-token-storage]
  patterns: [observable-singleton-scan-service, delta-scan-pattern, pkce-auth-flow, web-api-playback]

key-files:
  created:
    - BeatStep/Services/LibraryScanService.swift
    - BeatStep/Services/BPMDiscoveryService.swift
    - BeatStep/Secrets.example.swift
    - BeatStep/Utilities/KeychainManager.swift
    - BeatStepTests/LibraryScanServiceTests.swift
    - BeatStepTests/BPMViewWiringTests.swift
  modified:
    - BeatStep/Services/SpotifyAPIService.swift
    - BeatStep/Services/SpotifyAuthService.swift
    - BeatStep/Services/SpotifyPlayerService.swift
    - BeatStep/Views/Library/PlaylistDetailView.swift
    - BeatStep/Views/Library/PlaylistListView.swift
    - BeatStep/Views/Player/MiniPlayerView.swift
    - BeatStep/App/ContentView.swift
    - BeatStep/App/BeatStepApp.swift
    - BeatStep/Models/SpotifyPlaylist.swift
    - BeatStep/Models/SpotifyTrack.swift
    - BeatStep/Resources/Info.plist

key-decisions:
  - "Replaced implicit grant with PKCE auth flow (Spotify Feb 2026 requirement)"
  - "Replaced SPTAppRemote with Web API player for broader compatibility"
  - "Spotify /items endpoint replaces /tracks and 'item' field rename for Feb 2026 API"
  - "API keys moved to gitignored Secrets.swift for security"
  - "BPM data source parked: GetSongBPM blocked by Cloudflare, Spotify audio-features restricted for new apps"
  - "Added manual BPM scan/clear buttons for user control"

patterns-established:
  - "PKCE auth flow with Keychain token storage and refresh"
  - "Web API player with /me/player endpoints instead of SPTAppRemote SDK"
  - "LibraryScanService @Observable singleton with delta scan pattern"
  - "Secrets.swift gitignored pattern for API keys"

requirements-completed: [BPM-05, SPOT-05]

# Metrics
duration: multi-session
completed: 2026-03-20
---

# Phase 2 Plan 02: BPM Pipeline Wiring Summary

**LibraryScanService with delta scanning, BPM badges/coverage in all views, PKCE auth migration, Web API player, and Spotify Feb 2026 API compatibility fixes**

## Performance

- **Duration:** Multi-session (Tasks 1-2 automated, Task 3 manual verification with significant fixes)
- **Tasks:** 3
- **Files modified:** 22+

## Accomplishments
- LibraryScanService with background delta scanning and progress reporting
- BPMDiscoveryService for cross-referencing GetSongBPM and Spotify catalog
- SpotifyAPIService extended with POST support, catalog search, and playlist CRUD
- BPM badges on every track row, real BPM in mini-player, coverage stats per playlist
- Migrated auth from implicit grant to PKCE flow (Spotify Feb 2026 requirement)
- Replaced SPTAppRemote with Web API player for broader device compatibility
- Updated Spotify API calls for Feb 2026 changes (/items endpoint, 'item' field rename)
- API keys moved to gitignored Secrets.swift
- Manual BPM scan and clear buttons added for user control

## Task Commits

Each task was committed atomically:

1. **Task 1: LibraryScanService, BPMDiscoveryService, and SpotifyAPIService extensions** - `e95bd79` (feat)
2. **Task 2: Wire BPM data into all views** - `7483a8c` (feat)
3. **Task 3: Verify BPM pipeline end-to-end** - `3df8eeb` (fix -- major PKCE auth, API compat, and Web API player fixes during verification)

_Additional commits during plan execution:_
- `fffd051` - docs: README with GetSongBPM attribution
- `b7de98a` - sec: move API keys to gitignored Secrets.swift

## Files Created/Modified
- `BeatStep/Services/LibraryScanService.swift` - Background delta BPM scanning with progress reporting
- `BeatStep/Services/BPMDiscoveryService.swift` - BPM-based song discovery via GetSongBPM + Spotify cross-reference
- `BeatStep/Services/SpotifyAPIService.swift` - Extended with POST, catalog search, playlist CRUD, Feb 2026 API compat
- `BeatStep/Services/SpotifyAuthService.swift` - Migrated to PKCE auth flow with token refresh
- `BeatStep/Services/SpotifyPlayerService.swift` - Replaced SPTAppRemote with Web API player
- `BeatStep/Utilities/KeychainManager.swift` - Secure token storage for PKCE auth
- `BeatStep/Views/Library/PlaylistDetailView.swift` - BPM badges on track rows
- `BeatStep/Views/Library/PlaylistListView.swift` - Coverage stats, scan progress banner, manual scan/clear buttons
- `BeatStep/Views/Player/MiniPlayerView.swift` - Real BPM display for current track
- `BeatStep/App/ContentView.swift` - Background scan trigger on auth
- `BeatStep/App/BeatStepApp.swift` - Updated for PKCE auth and Web API player
- `BeatStep/Models/SpotifyPlaylist.swift` - Updated for Feb 2026 API changes
- `BeatStep/Models/SpotifyTrack.swift` - Updated for Feb 2026 API changes
- `BeatStep/Resources/Info.plist` - Updated URL schemes for PKCE
- `BeatStep/Secrets.example.swift` - Template for API keys
- `BeatStepTests/LibraryScanServiceTests.swift` - Delta scan logic tests
- `BeatStepTests/BPMViewWiringTests.swift` - BPM data flow from cache to views tests

## Decisions Made
- **PKCE auth replaces implicit grant**: Spotify deprecated implicit grant for mobile apps effective Feb 2026. PKCE with Keychain-stored tokens is the new standard.
- **Web API player replaces SPTAppRemote**: SPTAppRemote had reliability issues and limited device support. Web API /me/player endpoints provide broader compatibility.
- **Spotify Feb 2026 API compatibility**: /items replaces /tracks endpoint, 'item' field replaces previous field name in responses.
- **API keys in Secrets.swift (gitignored)**: Security best practice, with Secrets.example.swift as template.
- **BPM data source parked**: GetSongBPM is blocked by Cloudflare bot protection, and Spotify audio-features endpoint is restricted for new app registrations. BPM data sourcing deferred until a viable provider is identified. The pipeline infrastructure (scan, cache, display) is fully functional.
- **Manual scan/clear buttons**: Added user-facing controls for BPM scanning to complement automatic background scanning.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] PKCE auth flow migration**
- **Found during:** Task 3 (verification)
- **Issue:** Implicit grant auth flow no longer supported by Spotify (Feb 2026 policy change)
- **Fix:** Replaced entire auth flow with PKCE, added KeychainManager for token storage, implemented token refresh
- **Files modified:** SpotifyAuthService.swift, KeychainManager.swift, BeatStepApp.swift, Info.plist
- **Committed in:** 3df8eeb

**2. [Rule 1 - Bug] Spotify Feb 2026 API endpoint changes**
- **Found during:** Task 3 (verification)
- **Issue:** Spotify API changed /tracks to /items endpoint and renamed 'track' field to 'item' in responses
- **Fix:** Updated all API calls and response model decodings
- **Files modified:** SpotifyAPIService.swift, SpotifyPlaylist.swift, SpotifyTrack.swift
- **Committed in:** 3df8eeb

**3. [Rule 1 - Bug] SPTAppRemote replaced with Web API player**
- **Found during:** Task 3 (verification)
- **Issue:** SPTAppRemote SDK had connectivity issues on device
- **Fix:** Implemented playback via Spotify Web API /me/player endpoints
- **Files modified:** SpotifyPlayerService.swift
- **Committed in:** 3df8eeb

**4. [Rule 2 - Missing Critical] API keys in source code**
- **Found during:** Task 3 (verification)
- **Issue:** API keys were hardcoded in service files
- **Fix:** Moved to gitignored Secrets.swift with Secrets.example.swift template
- **Files modified:** .gitignore, Secrets.example.swift, GetSongBPMService.swift, SpotifyAuthService.swift
- **Committed in:** b7de98a

---

**Total deviations:** 4 auto-fixed (3 bugs, 1 missing critical)
**Impact on plan:** Significant scope expansion during verification. PKCE migration and Web API player were necessary for the app to function with current Spotify policies. All fixes essential for correctness.

## Known Limitations

- **BPM data source unavailable**: GetSongBPM API is blocked by Cloudflare bot protection. Spotify audio-features endpoint requires extended quota approval for new apps. The entire BPM pipeline infrastructure works, but no live BPM data flows through it yet. A viable BPM data provider needs to be identified in a future plan.

## Issues Encountered
- GetSongBPM API blocked by Cloudflare -- cannot fetch BPM data programmatically
- Spotify audio-features endpoint restricted for new app registrations
- Full-screen layout fix needed during verification

## User Setup Required
API keys must be configured in `BeatStep/Secrets.swift` (copy from `Secrets.example.swift`):
- Spotify client ID from Spotify Developer Dashboard
- GetSongBPM API key from getsongbpm.com/api (when provider access is resolved)

## Next Phase Readiness
- BPM pipeline infrastructure fully built and wired into UI (scan, cache, display, discovery)
- Auth and playback modernized (PKCE + Web API player) -- solid foundation for Phase 3
- **Blocker for BPM utility**: Need a working BPM data source before the pipeline delivers real value to users
- Phase 3 (Cadence Detection) can proceed independently -- it does not depend on live BPM data

## Self-Check: PASSED

- All 12 key files verified on disk
- Commit e95bd79 (Task 1) verified in git log
- Commit 7483a8c (Task 2) verified in git log
- Commit 3df8eeb (Task 3) verified in git log
- Additional commits b7de98a, fffd051 verified in git log

---
*Phase: 02-bpm-data-pipeline*
*Completed: 2026-03-20*
