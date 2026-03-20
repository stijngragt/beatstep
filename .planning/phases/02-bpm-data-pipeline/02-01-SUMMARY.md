---
phase: 02-bpm-data-pipeline
plan: 01
subsystem: database, api
tags: [swiftdata, getsongbpm, bpm-cache, codable, urlsession]

# Dependency graph
requires:
  - phase: 01-spotify-integration
    provides: "SpotifyTrack model, SpotifyAPIService, app entry point"
provides:
  - "CachedBPM SwiftData model for track-to-BPM persistence"
  - "ScannedPlaylist SwiftData model for user-selected running playlists"
  - "GetSongBPM API response types (search, song, tempo)"
  - "GetSongBPMService with two-step BPM lookup and rate limiting"
  - "BPMCacheService singleton for SwiftData CRUD operations"
  - "ModelContainer initialization in BeatStepApp"
affects: [02-02-PLAN, bpm-display, library-scan, discovery]

# Tech tracking
tech-stack:
  added: [SwiftData]
  patterns: [swiftdata-model-container-singleton, two-step-api-lookup, title-sanitization-regex]

key-files:
  created:
    - BeatStep/Models/CachedBPM.swift
    - BeatStep/Models/ScannedPlaylist.swift
    - BeatStep/Models/GetSongBPMResponse.swift
    - BeatStep/Services/GetSongBPMService.swift
    - BeatStep/Services/BPMCacheService.swift
    - BeatStepTests/Mocks/MockGetSongBPMResponses.swift
    - BeatStepTests/ModelDecodingTests.swift
    - BeatStepTests/GetSongBPMServiceTests.swift
    - BeatStepTests/BPMCacheServiceTests.swift
  modified:
    - BeatStep/App/BeatStepApp.swift

key-decisions:
  - "BPMCacheService uses singleton with setContainer pattern for SwiftData access outside views"
  - "GetSongBPMService title sanitization strips Remastered/Live/feat/Deluxe suffixes via regex"
  - "coverageStats takes trackIDs array (not playlist) for flexible usage"

patterns-established:
  - "SwiftData ModelContainer created at app init, passed to services via setContainer"
  - "Two-step API lookup pattern: search then detail with 300ms rate limit delay"
  - "@MainActor singleton for SwiftData service (BPMCacheService)"
  - "In-memory ModelContainer for unit testing SwiftData operations"

requirements-completed: [BPM-01, BPM-05]

# Metrics
duration: 4min
completed: 2026-03-20
---

# Phase 2 Plan 01: BPM Data Foundation Summary

**SwiftData models for BPM caching, GetSongBPM API client with two-step lookup and title sanitization, BPMCacheService for CRUD, all with 19 new unit tests**

## Performance

- **Duration:** 4 min
- **Started:** 2026-03-20T07:52:03Z
- **Completed:** 2026-03-20T07:56:30Z
- **Tasks:** 2
- **Files modified:** 10

## Accomplishments
- CachedBPM and ScannedPlaylist SwiftData models with unique constraints and coverage text
- GetSongBPM Codable response types for search, song, and tempo endpoints
- GetSongBPMService with title sanitization, two-step lookup, and 300ms rate limiting
- BPMCacheService with insert/update, getBPM, hasLookup, and coverageStats
- ModelContainer initialized in BeatStepApp with both schemas
- 19 new tests all passing, 30 total tests green

## Task Commits

Each task was committed atomically:

1. **Task 1: SwiftData models, response types, decoding tests** - `a7586dc` (feat)
2. **Task 2: GetSongBPMService and BPMCacheService with tests** - `47ea7e9` (feat)

## Files Created/Modified
- `BeatStep/Models/CachedBPM.swift` - SwiftData @Model for track-to-BPM cache with unique spotifyTrackID
- `BeatStep/Models/ScannedPlaylist.swift` - SwiftData @Model for user-selected running playlists with coverageText
- `BeatStep/Models/GetSongBPMResponse.swift` - Codable types for all GetSongBPM API responses
- `BeatStep/Services/GetSongBPMService.swift` - API client with search, song detail, tempo endpoints, title sanitization
- `BeatStep/Services/BPMCacheService.swift` - @MainActor SwiftData CRUD singleton for BPM cache
- `BeatStep/App/BeatStepApp.swift` - Added ModelContainer init with CachedBPM and ScannedPlaylist schemas
- `BeatStepTests/Mocks/MockGetSongBPMResponses.swift` - JSON fixtures for search, song, tempo responses
- `BeatStepTests/ModelDecodingTests.swift` - 7 tests for Codable decoding and coverage text
- `BeatStepTests/GetSongBPMServiceTests.swift` - 11 tests for response decoding and title sanitization
- `BeatStepTests/BPMCacheServiceTests.swift` - 8 tests for SwiftData CRUD with in-memory container

## Decisions Made
- BPMCacheService uses singleton with setContainer pattern (matches established SpotifyAPIService.shared pattern)
- GetSongBPMService title sanitization uses NSRegularExpression for broad pattern matching
- coverageStats takes trackIDs array rather than playlist ID for flexible caller usage
- API key stored as static constant placeholder (moved to config later per plan)

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Added Foundation import to SwiftData model files**
- **Found during:** Task 1 (SwiftData models)
- **Issue:** CachedBPM and ScannedPlaylist used Date type but only imported SwiftData (no Foundation)
- **Fix:** Added `import Foundation` to both model files
- **Files modified:** BeatStep/Models/CachedBPM.swift, BeatStep/Models/ScannedPlaylist.swift
- **Verification:** Build succeeded after fix
- **Committed in:** a7586dc (Task 1 commit)

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** Minor import fix, no scope change.

## Issues Encountered
None

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- BPM data foundation complete: models, API client, cache service all tested
- Plan 02-02 can build LibraryScanService, discovery service, and UI wiring on top of these services
- GetSongBPM API key placeholder needs real key before live testing

## Self-Check: PASSED

- All 9 created files exist on disk
- Commit a7586dc (Task 1) verified in git log
- Commit 47ea7e9 (Task 2) verified in git log
- Full test suite: 30/30 tests passing

---
*Phase: 02-bpm-data-pipeline*
*Completed: 2026-03-20*
