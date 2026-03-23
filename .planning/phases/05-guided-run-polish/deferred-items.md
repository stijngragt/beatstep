# Deferred Items - Phase 05

## Pre-existing Test Failures

### SpotifyAuthServiceTests.testTrackParsing / SpotifyAPIServiceTests.testPlaylistTrackDecoding
- **Issue:** Mock data uses `"track"` JSON key but `PlaylistTrackItem` model uses `"item"` key (Spotify Feb 2026 API rename)
- **Impact:** 2 test failures in SpotifyAuth/API test suites (crash on force-unwrap nil)
- **Fix:** Update mock JSON data in `MockSpotifyResponses.swift` to use `"item"` instead of `"track"` key
- **Not fixed because:** Pre-existing, not caused by Phase 5 changes
