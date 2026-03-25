---
phase: 27-foundation-fixes
plan: 01
subsystem: api
tags: [spotify, codable, backward-compat, dev-mode]

requires:
  - phase: none
    provides: none
provides:
  - Backward-compatible PlaylistTrackItem decoder (item + track keys)
  - Graceful SpotifyUser.isPremium when product field absent
  - Updated addTracksToPlaylist endpoint (/items)
  - Search limit capped at 10 (Dev Mode)
affects: [spotify-integration, playback, playlist-management]

tech-stack:
  added: []
  patterns: [dual-key-decoder, defensive-nil-defaults]

key-files:
  created: []
  modified:
    - BeatStep/Models/SpotifyTrack.swift
    - BeatStep/Models/SpotifyUser.swift
    - BeatStep/Services/SpotifyAPIService.swift
    - BeatStepTests/Mocks/MockSpotifyResponses.swift
    - BeatStepTests/SpotifyAPIServiceTests.swift

key-decisions:
  - "PlaylistTrackItem tries 'item' first, falls back to 'track' for backward compat"
  - "isPremium defaults true when product is nil (Dev Mode implies Premium subscription)"

patterns-established:
  - "Dual-key decoder: try new key first, fallback to legacy key"

requirements-completed: [INF-01]

duration: 6min
completed: 2026-03-25
---

# Phase 27 Plan 01: Spotify API Models Summary

**Backward-compatible PlaylistTrackItem decoder, Dev Mode isPremium default, /items endpoint, and search limit cap**

## Performance

- **Duration:** 6 min
- **Started:** 2026-03-25T22:21:56Z
- **Completed:** 2026-03-25T22:28:06Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments
- PlaylistTrackItem decodes both "item" (Feb 2026) and legacy "track" JSON keys
- SpotifyUser.isPremium returns true when product field is absent (Dev Mode)
- addTracksToPlaylist endpoint updated from /tracks to /items
- Search limit capped at 10 (Dev Mode maximum)
- Pre-existing testPlaylistTrackDecoding failure resolved
- 4 new tests added, all 9 Spotify tests pass

## Task Commits

Each task was committed atomically:

1. **Task 1 (RED): Add failing tests** - `311a807` (test)
2. **Task 1 (GREEN): Implement model fixes** - `fee5654` (feat)
3. **Task 2: Update endpoints and search limit** - `d6b83a4` (fix)

_Note: Task 1 used TDD flow with separate RED/GREEN commits_

## Files Created/Modified
- `BeatStep/Models/SpotifyTrack.swift` - Custom init(from:) decoding both "item" and "track" keys
- `BeatStep/Models/SpotifyUser.swift` - isPremium handles nil product (Dev Mode)
- `BeatStep/Services/SpotifyAPIService.swift` - /items endpoint, search limit cap at 10
- `BeatStepTests/Mocks/MockSpotifyResponses.swift` - Updated to Feb 2026 format, added devModeUser mock
- `BeatStepTests/SpotifyAPIServiceTests.swift` - 4 new tests for backward compat and user decoding
- `BeatStep.xcodeproj/project.pbxproj` - Added missing OnboardingPlaylistView reference

## Decisions Made
- PlaylistTrackItem tries "item" first, falls back to "track" for backward compat
- isPremium defaults true when product is nil (Dev Mode implies Premium subscription)
- Added explicit encode(to:) to satisfy Codable conformance with dual CodingKeys

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] OnboardingPlaylistView.swift missing from Xcode project**
- **Found during:** Task 1 (build failed before tests could run)
- **Issue:** OnboardingPlaylistView.swift existed on disk but was not added to BeatStep.xcodeproj, causing "Cannot find 'OnboardingPlaylistView' in scope" build error
- **Fix:** Added PBXBuildFile, PBXFileReference, and group/sources entries to project.pbxproj
- **Files modified:** BeatStep.xcodeproj/project.pbxproj
- **Verification:** Build succeeds, all tests pass
- **Committed in:** 311a807 (Task 1 RED commit)

**2. [Rule 1 - Bug] PlaylistTrackItem Encodable conformance broken by dual CodingKeys**
- **Found during:** Task 1 GREEN phase (build failed)
- **Issue:** Adding "track" to CodingKeys broke auto-synthesized Encodable (no stored property matches "track")
- **Fix:** Added explicit encode(to:) that only encodes the "item" key
- **Files modified:** BeatStep/Models/SpotifyTrack.swift
- **Verification:** Build succeeds, all tests pass
- **Committed in:** fee5654 (Task 1 GREEN commit)

---

**Total deviations:** 2 auto-fixed (1 blocking, 1 bug)
**Impact on plan:** Both auto-fixes necessary for build/correctness. No scope creep.

## Issues Encountered
- xcodebuild required DEVELOPER_DIR override (xcode-select pointed to CommandLineTools)
- iPhone 16 simulator unavailable, used iPhone 17 Pro instead

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Spotify API models fully compatible with Feb 2026 Dev Mode responses
- Pre-existing test failure resolved, test suite green
- Ready for any phase depending on Spotify integration

---
*Phase: 27-foundation-fixes*
*Completed: 2026-03-25*
