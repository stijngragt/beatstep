# Phase 4: Deferred Items

## Pre-existing Test Failures

1. **SpotifyAuthServiceTests.testTrackParsing** (line 88) -- Force unwrap crash on `response.items[0].track!`. The `PlaylistTrackItem` struct uses `item` field (Feb 2026 API rename) but the mock response data likely still uses `track` field. Not caused by Phase 4 changes.
