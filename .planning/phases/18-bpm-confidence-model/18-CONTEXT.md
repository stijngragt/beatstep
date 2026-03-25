# Phase 18: BPM Confidence Model - Context

**Gathered:** 2026-03-25
**Status:** Ready for planning

<domain>
## Phase Boundary

Extend the CachedBPM data model with confidence level and source tracking fields, and split BPMCacheService into separate API and manual write paths. This is the data foundation for v1.4 -- no UI changes in this phase. Phase 19 adds badges, Phase 20 adds the tap input that calls the manual write path.

</domain>

<decisions>
## Implementation Decisions

### Confidence levels
- 3 tiers as specced: verified, approximate, manual
- BPMConfidence enum with String rawValue (.verified, .approximate, .manual)
- All API-sourced BPM (GetSongBPM) is classified as .verified -- no verified/approximate distinction for now
- .approximate tier exists in the enum but has no source mapping yet (reserved for future heuristics like same-album inference)
- Confidence is only set when bpm is non-nil -- tracks with bpm=nil have nil confidence
- The "no data" state remains expressed by bpm=nil + lookupAttempted=true (no .unknown enum case)

### Write path separation
- Two separate methods: `cacheFromAPI()` and `cacheManual()` on BPMCacheService
- Each method automatically sets the correct source and confidence -- callers don't pass these
- Manual wins over API: if a track has .manual confidence, `cacheFromAPI()` is a no-op for BPM (preserves user's explicit correction)
- Manual always overwrites API: `cacheManual()` replaces any existing BPM regardless of current confidence (no confirmation prompt)
- The existing `cache()` method is removed entirely -- LibraryScanService updated to call `cacheFromAPI()`

### Migration strategy
- New fields stored as optional String? (`confidenceRaw`, `sourceRaw`) for SwiftData lightweight migration compatibility
- Computed properties on CachedBPM return typed enums (BPMConfidence, BPMSource)
- Lazy backfill on read: when confidenceRaw is nil and bpm is non-nil, computed property returns .verified -- no migration pass needed
- Similarly, nil sourceRaw with non-nil bpm returns .api
- Zero startup cost -- no eager migration or background backfill task

### Source tracking
- BPMSource enum with String rawValue: .api, .manual
- Two separate SwiftData fields: sourceRaw (String?) and confidenceRaw (String?)
- Source and confidence are decoupled -- source = where data came from, confidence = how reliable
- Today they map 1:1 (.api -> .verified, .manual -> .manual) but stored separately for future extensibility
- BPMDiscoveryService uses GetSongBPM under the hood, so discovery results are .api source

### Claude's Discretion
- Exact computed property implementation for the enum accessors
- How cacheFromAPI() checks for existing manual confidence (fetch-then-skip vs predicate)
- Test structure and naming for the new write paths
- Whether to add convenience accessors (e.g., `isManual`, `isVerified`) on CachedBPM

</decisions>

<specifics>
## Specific Ideas

No specific requirements -- open to standard approaches for the enum types and SwiftData field additions.

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- `CachedBPM` (Models/CachedBPM.swift): @Model with 6 fields -- add confidenceRaw and sourceRaw as optional String?
- `BPMCacheService` (Services/BPMCacheService.swift): singleton with cache(), getBPM(), clearCache(), hasLookup(), getDanceability(), coverageStats()
- `RunMode` / `BPMTolerance`: established enum-with-rawValue-String pattern to follow for BPMConfidence and BPMSource

### Established Patterns
- @Model with @Attribute(.unique) for SwiftData entities
- Singleton services with static shared instance
- Enum + String rawValue + CaseIterable for type-safe settings
- UserDefaults for simple preferences (not needed here -- these go in SwiftData)

### Integration Points
- `LibraryScanService` (lines 51, 61): only production caller of cache() -- update to cacheFromAPI()
- `BPMCacheServiceTests` + `BPMViewWiringTests` + `LibraryScanServiceTests`: test callers of cache() -- update to cacheFromAPI()
- `BeatStepApp.swift`: ModelContainer schema -- CachedBPM model changes picked up automatically by SwiftData
- Phase 20 (Tap BPM): will call cacheManual() -- method must exist but no caller in this phase

</code_context>

<deferred>
## Deferred Ideas

None -- discussion stayed within phase scope

</deferred>

---

*Phase: 18-bpm-confidence-model*
*Context gathered: 2026-03-25*
