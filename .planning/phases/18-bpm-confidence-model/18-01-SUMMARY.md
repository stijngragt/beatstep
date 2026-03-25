---
phase: 18-bpm-confidence-model
plan: 01
subsystem: database
tags: [swiftdata, enum, bpm, confidence, migration]

# Dependency graph
requires: []
provides:
  - BPMConfidence enum (verified/approximate/manual)
  - BPMSource enum (api/manual)
  - CachedBPM confidenceRaw/sourceRaw fields with lazy backfill
  - cacheFromAPI() and cacheManual() write paths on BPMCacheService
  - Manual-wins-over-API guard in cacheFromAPI()
affects: [18-02, 19-confidence-badges, 20-tap-bpm-input]

# Tech tracking
tech-stack:
  added: []
  patterns: [lazy-backfill-on-read, split-write-paths, raw-string-plus-computed-enum]

key-files:
  created:
    - BeatStep/Models/BPMConfidence.swift
    - BeatStep/Models/BPMSource.swift
    - BeatStepTests/BPMConfidenceModelTests.swift
    - BeatStepTests/BPMCacheWritePathTests.swift
  modified:
    - BeatStep/Models/CachedBPM.swift
    - BeatStep/Services/BPMCacheService.swift
    - BeatStep/Services/LibraryScanService.swift
    - BeatStepTests/BPMCacheServiceTests.swift
    - BeatStepTests/BPMViewWiringTests.swift
    - BeatStepTests/LibraryScanServiceTests.swift

key-decisions:
  - "Lazy backfill pattern: nil raw + non-nil bpm returns .verified/.api without migration"
  - "Write paths use confidenceRaw (String?) directly, never computed property, to avoid backfill defaults"
  - "Updated existing test files to cacheFromAPI in this plan (Rule 3) since removal of cache() broke compilation"

patterns-established:
  - "Raw String? + computed enum accessor: store optional String in SwiftData, expose typed enum via computed property"
  - "Manual-wins guard: check confidenceRaw == manual.rawValue before API overwrite"

requirements-completed: [CONF-01, CONF-02]

# Metrics
duration: 9min
completed: 2026-03-25
---

# Phase 18 Plan 01: BPM Confidence Model Summary

**BPMConfidence/BPMSource enums with lazy backfill on CachedBPM and split cacheFromAPI/cacheManual write paths**

## Performance

- **Duration:** 9 min
- **Started:** 2026-03-25T09:06:55Z
- **Completed:** 2026-03-25T09:16:31Z
- **Tasks:** 2
- **Files modified:** 10

## Accomplishments
- BPMConfidence enum (verified/approximate/manual) and BPMSource enum (api/manual) following RunMode pattern
- CachedBPM extended with confidenceRaw/sourceRaw optional String fields for lightweight SwiftData migration
- Lazy backfill on read: existing records with bpm but no raw fields return .verified/.api automatically
- cacheFromAPI() with manual-wins guard and cacheManual() that always overwrites
- 18 new tests across two test files (12 model tests, 6 write path tests)

## Task Commits

Each task was committed atomically:

1. **Task 1: Create BPMConfidence and BPMSource enums, extend CachedBPM model** - `2744a9f` (feat)
2. **Task 2: Split cache() into cacheFromAPI() and cacheManual(), update LibraryScanService** - `b0d70a8` (feat)

## Files Created/Modified
- `BeatStep/Models/BPMConfidence.swift` - Enum with verified/approximate/manual cases
- `BeatStep/Models/BPMSource.swift` - Enum with api/manual cases
- `BeatStep/Models/CachedBPM.swift` - Added confidenceRaw/sourceRaw fields and computed accessors with lazy backfill
- `BeatStep/Services/BPMCacheService.swift` - Replaced cache() with cacheFromAPI() and cacheManual()
- `BeatStep/Services/LibraryScanService.swift` - Updated both call sites to cacheFromAPI()
- `BeatStepTests/BPMConfidenceModelTests.swift` - 12 tests for enums, backfill, setters, convenience accessors
- `BeatStepTests/BPMCacheWritePathTests.swift` - 6 tests for write paths and manual-wins guard
- `BeatStepTests/BPMCacheServiceTests.swift` - Renamed cache() to cacheFromAPI() calls
- `BeatStepTests/BPMViewWiringTests.swift` - Renamed cache() to cacheFromAPI() calls
- `BeatStepTests/LibraryScanServiceTests.swift` - Renamed cache() to cacheFromAPI() calls

## Decisions Made
- Lazy backfill pattern avoids migration cost: nil raw + non-nil bpm returns .verified/.api on read
- Write paths use confidenceRaw (String?) directly to avoid triggering backfill defaults during writes
- Updated existing test files in this plan (originally scoped for 18-02) since removing cache() broke compilation

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Updated existing test files to use cacheFromAPI()**
- **Found during:** Task 2 (split write paths)
- **Issue:** Removing cache() broke compilation of BPMCacheServiceTests, BPMViewWiringTests, and LibraryScanServiceTests
- **Fix:** Mechanical rename of cache() to cacheFromAPI() in all three test files
- **Files modified:** BeatStepTests/BPMCacheServiceTests.swift, BeatStepTests/BPMViewWiringTests.swift, BeatStepTests/LibraryScanServiceTests.swift
- **Verification:** Full build succeeds, all new tests pass
- **Committed in:** b0d70a8 (Task 2 commit)

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** Necessary for compilation after removing cache(). Plan 18-02 can focus on adding new confidence/source tests rather than mechanical renames.

## Issues Encountered
- xcodebuild required DEVELOPER_DIR override since active developer directory pointed to CommandLineTools instead of Xcode.app
- iPhone 16 simulator unavailable (Xcode 26 beta with iOS 26.2); used iPhone 17 Pro simulator

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Data model foundation complete for Phase 18 Plan 02 (test suite expansion)
- cacheManual() ready for Phase 20 (Tap BPM Input) to call
- Confidence enums ready for Phase 19 (Confidence Badges) to display

---
*Phase: 18-bpm-confidence-model*
*Completed: 2026-03-25*
