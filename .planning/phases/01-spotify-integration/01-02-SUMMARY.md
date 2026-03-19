---
phase: 01-spotify-integration
plan: 02
subsystem: playback
tags: [spotify, sptappremote, swiftui, navigationstack, asyncimage, web-api, pagination]

# Dependency graph
requires:
  - phase: 01-spotify-integration/01
    provides: SpotifyAuthService, KeychainManager, AudioSessionService, model types, project scaffold
provides:
  - Full SpotifyPlayerService with SPTAppRemote lifecycle and delegate callbacks
  - SpotifyAPIService for playlist/track fetching with pagination
  - PlaylistListView with pagination, pull-to-refresh, and error states
  - PlaylistDetailView with track list and tap-to-play
  - MiniPlayerView with BPM placeholder, play/pause, and skip controls
  - SettingsView with user info and Spotify disconnect
  - Wired ContentView with auth gate, NavigationStack, toolbar, and mini-player overlay
affects: [02-bpm-data-pipeline]

# Tech tracking
tech-stack:
  added: []
  patterns: [NavigationStack with value-based NavigationLink, AsyncImage for remote artwork, safeAreaInset for mini-player spacing, ZStack overlay for persistent bottom bar]

key-files:
  created:
    - BeatStep/Services/SpotifyAPIService.swift
    - BeatStep/Views/Library/PlaylistListView.swift
    - BeatStep/Views/Library/PlaylistDetailView.swift
    - BeatStep/Views/Player/MiniPlayerView.swift
    - BeatStep/Views/Settings/SettingsView.swift
    - BeatStepTests/SpotifyAPIServiceTests.swift
  modified:
    - BeatStep/Services/SpotifyPlayerService.swift
    - BeatStep/Services/SpotifyAuthService.swift
    - BeatStep/App/ContentView.swift

key-decisions:
  - "SpotifyPlayerService inherits NSObject for SPTAppRemote delegate conformance"
  - "SPTAppRemoteTrack converted to our SpotifyTrack model in playerStateDidChange delegate"
  - "MiniPlayerView shows BPM placeholder (-- BPM) per CONTEXT.md; real BPM comes in Phase 2"
  - "clientID and redirectURL exposed as internal on SpotifyAuthService for shared access by PlayerService"

patterns-established:
  - "Value-based NavigationLink: NavigationLink(value:) with .navigationDestination(for:) for type-safe navigation"
  - "Pagination pattern: onAppear on last item triggers next page fetch, append to existing array"
  - "Mini-player overlay: ZStack with safeAreaInset to reserve scroll space below content"

requirements-completed: [SPOT-02, SPOT-04]

# Metrics
duration: 21min
completed: 2026-03-19
---

# Phase 1 Plan 02: Playback, Views & Wiring Summary

**Full SPTAppRemote playback service, Spotify Web API service, playlist browsing with pagination, mini-player with controls, settings with disconnect, all wired through NavigationStack with auth gate**

## Performance

- **Duration:** 21 min
- **Started:** 2026-03-19T16:06:37Z
- **Completed:** 2026-03-19T16:27:52Z
- **Tasks:** 3
- **Files modified:** 11

## Accomplishments
- SpotifyPlayerService fully implements SPTAppRemote lifecycle with delegate callbacks updating observable state (connect, disconnect, play, pause, skip, track change)
- SpotifyAPIService provides authenticated Web API calls for playlists and tracks with generic pagination support
- Complete UI: playlist list with cover art and pagination, track list with tap-to-play and now-playing highlight, mini-player with play/pause and skip, settings with disconnect
- 14 unit tests passing (9 from Plan 01 + 5 new API JSON parsing tests)
- Verified on physical device: all 18 manual verification steps passed

## Task Commits

Each task was committed atomically:

1. **Task 1: Replace SpotifyPlayerService stub with full implementation and create SpotifyAPIService** - `0ff5f5c` (feat)
2. **Task 2: Build all views and wire ContentView with auth gate** - `f5779c0` (feat)
3. **Task 3: Manual verification on physical device** - User approved (checkpoint, no code commit)

## Files Created/Modified
- `BeatStep/Services/SpotifyPlayerService.swift` - Full SPTAppRemote implementation with delegate callbacks
- `BeatStep/Services/SpotifyAPIService.swift` - Web API service for playlists and tracks with pagination
- `BeatStep/Services/SpotifyAuthService.swift` - Exposed clientID/redirectURL for shared access
- `BeatStep/Views/Library/PlaylistListView.swift` - Playlist list with pagination, pull-to-refresh, error states
- `BeatStep/Views/Library/PlaylistDetailView.swift` - Track list with tap-to-play, now-playing highlight, pagination
- `BeatStep/Views/Player/MiniPlayerView.swift` - Persistent mini-player with BPM placeholder and controls
- `BeatStep/Views/Settings/SettingsView.swift` - User info display and Spotify disconnect
- `BeatStep/App/ContentView.swift` - Auth gate, NavigationStack, toolbar, mini-player overlay
- `BeatStepTests/SpotifyAPIServiceTests.swift` - 5 API JSON parsing tests

## Decisions Made
- SpotifyPlayerService inherits NSObject for SPTAppRemote delegate conformance (required by Objective-C protocol)
- SPTAppRemoteTrack properties (name, uri, artist.name, album.name) converted to our SpotifyTrack model in delegate callback; id defaults to uri since SPTAppRemoteTrack lacks a Spotify ID
- MiniPlayerView shows "-- BPM" placeholder per CONTEXT.md design decision; real BPM data will be populated in Phase 2
- Made clientID and redirectURL internal (not private) on SpotifyAuthService so SpotifyPlayerService can share the same configuration

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Xcode developer tools path**
- **Found during:** Task 1
- **Issue:** Active developer directory pointed to CommandLineTools instead of Xcode.app
- **Fix:** Used DEVELOPER_DIR environment variable for xcodebuild invocations
- **Files modified:** None (runtime change only)
- **Verification:** All builds and tests pass

**2. [Rule 1 - Bug] iPhone 17 Pro simulator (inherited from Plan 01)**
- **Found during:** Task 1
- **Issue:** Plan specified iPhone 16 simulator but Xcode only has iPhone 17 series
- **Fix:** Used iPhone 17 Pro simulator for all builds and tests
- **Files modified:** None (runtime change only)

---

**Total deviations:** 2 auto-fixed (1 blocking, 1 bug)
**Impact on plan:** Minor runtime adjustments only. No code or scope changes.

## Issues Encountered
None beyond the auto-fixed deviations listed above.

## User Setup Required
Spotify Developer App registration is required for OAuth (documented in Plan 01). Client ID must be set in SpotifyAuthService.swift before testing auth.

## Next Phase Readiness
- Phase 1 complete: all Spotify integration requirements (SPOT-01 through SPOT-04) verified on device
- SpotifyPlayerService ready for Phase 4 to add cadence-based song queuing
- MiniPlayerView BPM placeholder ready for Phase 2 to populate with real BPM data
- SpotifyAPIService ready for Phase 2 to fetch track metadata for BPM lookups
- All model types and pagination patterns established for reuse

## Self-Check: PASSED

All 9 created/modified files verified on disk. Both task commits (0ff5f5c, f5779c0) verified in git log.

---
*Phase: 01-spotify-integration*
*Completed: 2026-03-19*
