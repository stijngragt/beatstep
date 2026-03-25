# Phase 18: BPM Confidence Model - Research

**Researched:** 2026-03-25
**Domain:** SwiftData model extension, enum design, service refactoring
**Confidence:** HIGH

## Summary

Phase 18 adds confidence and source tracking to the existing CachedBPM SwiftData model and splits the single `cache()` method on BPMCacheService into two distinct write paths (`cacheFromAPI()` and `cacheManual()`). This is a data-layer-only change with no UI impact.

The implementation is straightforward: two new optional String? fields on CachedBPM (for SwiftData lightweight migration compatibility), two new enums (BPMConfidence, BPMSource), computed property accessors, and the write path split. The main risk area is ensuring the migration works cleanly and that existing test callers of `cache()` are updated.

**Primary recommendation:** Follow the established enum-with-String-rawValue pattern (RunMode, BPMTolerance) for BPMConfidence and BPMSource. Use optional String? stored properties with computed enum accessors for zero-cost lazy backfill.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- 3 confidence tiers: verified, approximate, manual as BPMConfidence enum with String rawValue
- All API-sourced BPM classified as .verified (no verified/approximate distinction now)
- .approximate exists in enum but has no source mapping yet (reserved for future)
- Confidence only set when bpm is non-nil; nil bpm tracks have nil confidence
- "No data" state remains bpm=nil + lookupAttempted=true (no .unknown enum case)
- Two separate methods: `cacheFromAPI()` and `cacheManual()` on BPMCacheService
- Each method auto-sets correct source and confidence; callers don't pass these
- Manual wins over API: `cacheFromAPI()` is no-op if track has .manual confidence
- Manual always overwrites API: `cacheManual()` replaces any BPM regardless of confidence
- Existing `cache()` method removed entirely; LibraryScanService updated to call `cacheFromAPI()`
- New fields stored as optional String? (`confidenceRaw`, `sourceRaw`) for lightweight migration
- Computed properties on CachedBPM return typed enums (BPMConfidence, BPMSource)
- Lazy backfill on read: nil confidenceRaw with non-nil bpm returns .verified; nil sourceRaw with non-nil bpm returns .api
- Zero startup cost: no eager migration or background backfill task
- BPMSource enum: .api, .manual
- Source and confidence decoupled but today map 1:1 (.api -> .verified, .manual -> .manual)
- BPMDiscoveryService uses GetSongBPM, so discovery results are .api source

### Claude's Discretion
- Exact computed property implementation for the enum accessors
- How cacheFromAPI() checks for existing manual confidence (fetch-then-skip vs predicate)
- Test structure and naming for the new write paths
- Whether to add convenience accessors (e.g., `isManual`, `isVerified`) on CachedBPM

### Deferred Ideas (OUT OF SCOPE)
None -- discussion stayed within phase scope.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| CONF-01 | BPM source tracked per cached track (verified / approximate / manual) | BPMConfidence + BPMSource enums, confidenceRaw/sourceRaw fields on CachedBPM, computed property accessors, split write paths |
| CONF-02 | Existing cached BPM records backfilled with default confidence on migration | Lazy backfill via computed properties (nil confidenceRaw + non-nil bpm -> .verified), SwiftData lightweight migration with optional String? fields |
</phase_requirements>

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| SwiftData | iOS 17+ | Persistent model storage | Already used for CachedBPM and ScannedPlaylist |
| XCTest | Built-in | Unit testing | Already used across 24 test files |

### Supporting
No new dependencies. This phase only extends existing SwiftData models and services.

## Architecture Patterns

### Recommended Project Structure
```
BeatStep/
├── Models/
│   ├── CachedBPM.swift          # Add confidenceRaw, sourceRaw fields + computed properties
│   ├── BPMConfidence.swift      # NEW: enum BPMConfidence: String, CaseIterable
│   └── BPMSource.swift          # NEW: enum BPMSource: String, CaseIterable
├── Services/
│   └── BPMCacheService.swift    # Replace cache() with cacheFromAPI() + cacheManual()
BeatStepTests/
├── BPMCacheServiceTests.swift   # Update existing + add confidence/source tests
├── BPMViewWiringTests.swift     # Update cache() calls to cacheFromAPI()
└── LibraryScanServiceTests.swift # Update cache() calls to cacheFromAPI()
```

### Pattern 1: Enum with String RawValue (Established)
**What:** Enums using String rawValues for type-safe persistence
**When to use:** Any categorical data stored in SwiftData or UserDefaults
**Example:**
```swift
// Follows exact pattern from RunMode.swift and BPMTolerance.swift
enum BPMConfidence: String, CaseIterable {
    case verified = "verified"
    case approximate = "approximate"
    case manual = "manual"
}

enum BPMSource: String, CaseIterable {
    case api = "api"
    case manual = "manual"
}
```

### Pattern 2: Optional String? Storage with Computed Enum Accessor
**What:** Store raw strings in SwiftData for lightweight migration, expose typed enums via computed properties
**When to use:** Adding enum-backed fields to existing SwiftData models without requiring a migration plan
**Example:**
```swift
// On CachedBPM @Model
var confidenceRaw: String?
var sourceRaw: String?

var confidence: BPMConfidence? {
    get {
        if let raw = confidenceRaw {
            return BPMConfidence(rawValue: raw)
        }
        // Lazy backfill: existing records with BPM but no confidence -> .verified
        return bpm != nil ? .verified : nil
    }
    set {
        confidenceRaw = newValue?.rawValue
    }
}

var source: BPMSource? {
    get {
        if let raw = sourceRaw {
            return BPMSource(rawValue: raw)
        }
        return bpm != nil ? .api : nil
    }
    set {
        sourceRaw = newValue?.rawValue
    }
}
```

### Pattern 3: Split Write Paths with Confidence Guards
**What:** Separate methods that automatically set source/confidence, with manual-wins-over-API logic
**When to use:** Preventing silent overwrites between data sources
**Example:**
```swift
func cacheFromAPI(trackID: String, name: String, artist: String, bpm: Int?) {
    let descriptor = FetchDescriptor<CachedBPM>(
        predicate: #Predicate { $0.spotifyTrackID == trackID }
    )

    if let existing = try? context.fetch(descriptor).first {
        // Manual wins: don't overwrite user-set BPM
        if existing.confidenceRaw == BPMConfidence.manual.rawValue {
            // Still update lookupAttempted but preserve manual BPM
            existing.lookupAttempted = true
            existing.lastUpdated = Date()
        } else {
            existing.bpm = bpm
            existing.confidenceRaw = bpm != nil ? BPMConfidence.verified.rawValue : nil
            existing.sourceRaw = bpm != nil ? BPMSource.api.rawValue : nil
            existing.lookupAttempted = true
            existing.lastUpdated = Date()
        }
    } else {
        let cached = CachedBPM(spotifyTrackID: trackID, trackName: name, artistName: artist, bpm: bpm, lookupAttempted: true)
        if bpm != nil {
            cached.confidenceRaw = BPMConfidence.verified.rawValue
            cached.sourceRaw = BPMSource.api.rawValue
        }
        context.insert(cached)
    }
    try? context.save()
}

func cacheManual(trackID: String, name: String, artist: String, bpm: Int) {
    let descriptor = FetchDescriptor<CachedBPM>(
        predicate: #Predicate { $0.spotifyTrackID == trackID }
    )

    if let existing = try? context.fetch(descriptor).first {
        existing.bpm = bpm
        existing.confidenceRaw = BPMConfidence.manual.rawValue
        existing.sourceRaw = BPMSource.manual.rawValue
        existing.lookupAttempted = true
        existing.lastUpdated = Date()
    } else {
        let cached = CachedBPM(spotifyTrackID: trackID, trackName: name, artistName: artist, bpm: bpm, lookupAttempted: true)
        cached.confidenceRaw = BPMConfidence.manual.rawValue
        cached.sourceRaw = BPMSource.manual.rawValue
        context.insert(cached)
    }
    try? context.save()
}
```

### Anti-Patterns to Avoid
- **Storing enums directly in SwiftData:** SwiftData with enum-typed properties requires a migration plan when the property is new. Use optional String? for lightweight migration.
- **Eager migration on startup:** Running a background task to backfill all records adds startup cost and complexity. The lazy-backfill computed property approach is zero-cost.
- **Single method with source parameter:** Having callers pass .api or .manual defeats the purpose of enforcing correct metadata. The split method pattern makes incorrect usage a compile error.
- **Checking `confidence` computed property in write path:** Use `confidenceRaw` directly to avoid triggering the lazy backfill default when checking for manual overrides.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Schema migration | Custom migration scripts or backfill jobs | SwiftData lightweight migration with optional String? fields | SwiftData handles adding optional fields automatically; lazy backfill on read eliminates migration code entirely |
| Enum persistence | Custom encoder/decoder | String rawValue + computed property | Established project pattern; SwiftData stores String? natively |

**Key insight:** The lazy-backfill-on-read approach means there is literally zero migration code. Adding optional String? fields to a @Model triggers SwiftData's automatic lightweight migration. The computed properties handle the "backfill" transparently.

## Common Pitfalls

### Pitfall 1: SwiftData Predicate Limitations with Enums
**What goes wrong:** Using enum values directly inside #Predicate closures causes compile errors because SwiftData predicates only support basic types.
**Why it happens:** #Predicate requires Foundation-compatible types (String, Int, Bool, etc.).
**How to avoid:** Always compare against `confidenceRaw` (String?) in predicates, never the computed `confidence` (BPMConfidence?) property.
**Warning signs:** Compile error mentioning "not supported in predicate."

### Pitfall 2: Forgetting to Update All cache() Call Sites
**What goes wrong:** Build breaks in tests or LibraryScanService after removing cache().
**Why it happens:** Three test files and one service file currently call `cache()`.
**How to avoid:** Search all callers before removing the method. Known callers:
- `LibraryScanService.swift` lines 51, 61 (production)
- `BPMCacheServiceTests.swift` (8 calls)
- `BPMViewWiringTests.swift` (5 calls)
- `LibraryScanServiceTests.swift` (4 calls)

### Pitfall 3: Lazy Backfill Default vs Explicit Nil
**What goes wrong:** Confusion between "old record, never had confidence set" (should default to .verified) and "new record with nil BPM" (should have nil confidence).
**Why it happens:** Both cases have `confidenceRaw == nil`.
**How to avoid:** The computed property already handles this: it checks `bpm != nil` before returning the default. Records with nil BPM correctly return nil confidence.

### Pitfall 4: cacheFromAPI Overwrite Check Using Computed Property
**What goes wrong:** Checking `existing.confidence == .manual` triggers the lazy backfill which returns `.verified` for old records (correct), but the indirection is unnecessary.
**Why it happens:** The computed property adds a layer of abstraction.
**How to avoid:** Check `existing.confidenceRaw == BPMConfidence.manual.rawValue` directly in the write path for clarity and to avoid any edge cases.

### Pitfall 5: cacheManual BPM Parameter Should Be Non-Optional
**What goes wrong:** Allowing nil BPM in cacheManual() makes no semantic sense (user tapped a BPM, it must have a value).
**Why it happens:** Copy-pasting from cacheFromAPI signature.
**How to avoid:** `cacheManual(trackID:name:artist:bpm:)` should take `bpm: Int` (non-optional), not `bpm: Int?`.

## Code Examples

### Existing Enum Pattern to Follow
```swift
// Source: BeatStep/Models/BPMTolerance.swift
enum BPMTolerance: String, CaseIterable {
    case tight = "tight"
    case normal = "normal"
    case loose = "loose"
    // ... computed properties for display
}
```

### Existing CachedBPM Model (Before)
```swift
// Source: BeatStep/Models/CachedBPM.swift
@Model
final class CachedBPM {
    @Attribute(.unique) var spotifyTrackID: String
    var trackName: String
    var artistName: String
    var bpm: Int?
    var lookupAttempted: Bool
    var lastUpdated: Date
    var danceability: Int?
}
```

### Existing cache() Method (Will Be Removed)
```swift
// Source: BeatStep/Services/BPMCacheService.swift
func cache(trackID: String, name: String, artist: String, bpm: Int?) {
    // fetch-or-insert pattern with save
}
```

### LibraryScanService Call Sites to Update
```swift
// Source: BeatStep/Services/LibraryScanService.swift, lines 51 and 61
BPMCacheService.shared.cache(
    trackID: track.id,
    name: track.name,
    artist: track.artistName,
    bpm: bpm  // or nil on error
)
// BECOMES:
BPMCacheService.shared.cacheFromAPI(
    trackID: track.id,
    name: track.name,
    artist: track.artistName,
    bpm: bpm
)
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Single cache() method | Split cacheFromAPI() + cacheManual() | This phase | Prevents silent overwrite of user-set BPM |
| No confidence tracking | Confidence enum on every BPM record | This phase | Enables Phase 19 confidence badges |
| Enum-typed SwiftData properties | Optional String? with computed enum accessor | SwiftData best practice | Avoids migration plan requirement |

## Open Questions

1. **Convenience accessors on CachedBPM**
   - What we know: `isManual`, `isVerified` etc. are pure sugar over `confidence == .manual`
   - What's unclear: Whether Phase 19 (badges) or Phase 20 (tap BPM) would benefit enough to justify them now
   - Recommendation: Add them -- they cost nothing and make call sites more readable. Claude's discretion per CONTEXT.md.

2. **cacheFromAPI manual-check implementation**
   - What we know: Need to check if existing record has .manual confidence before overwriting
   - What's unclear: Whether to fetch-then-check (current pattern) or use a predicate filter
   - Recommendation: Use fetch-then-check (matches existing pattern in BPMCacheService). The fetch is needed anyway to update other fields. Claude's discretion per CONTEXT.md.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | XCTest (built-in) |
| Config file | Xcode project (BeatStepTests target) |
| Quick run command | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BeatStepTests/BPMCacheServiceTests 2>&1 \| tail -20` |
| Full suite command | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 \| tail -40` |

### Phase Requirements -> Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| CONF-01 | cacheFromAPI sets .verified confidence and .api source | unit | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BeatStepTests/BPMCacheServiceTests` | Exists but needs new test methods |
| CONF-01 | cacheManual sets .manual confidence and .manual source | unit | Same as above | Needs new test methods |
| CONF-01 | cacheFromAPI is no-op when existing record has .manual confidence | unit | Same as above | Needs new test method |
| CONF-01 | cacheManual overwrites API-sourced BPM | unit | Same as above | Needs new test method |
| CONF-02 | Existing records with bpm non-nil return .verified confidence via computed property | unit | Same as above | Needs new test method |
| CONF-02 | Existing records with bpm nil return nil confidence | unit | Same as above | Needs new test method |
| CONF-02 | Lazy backfill returns .api source for old records | unit | Same as above | Needs new test method |

### Sampling Rate
- **Per task commit:** Quick run BPMCacheServiceTests only
- **Per wave merge:** Full test suite
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] New test methods in `BPMCacheServiceTests.swift` for confidence/source tracking (7 new tests)
- [ ] Update existing `BPMCacheServiceTests` calls from `cache()` to `cacheFromAPI()`
- [ ] Update existing `BPMViewWiringTests` calls from `cache()` to `cacheFromAPI()`
- [ ] Update existing `LibraryScanServiceTests` calls from `cache()` to `cacheFromAPI()`

## Sources

### Primary (HIGH confidence)
- Project source code: CachedBPM.swift, BPMCacheService.swift, LibraryScanService.swift, RunMode.swift, BPMTolerance.swift
- Project test files: BPMCacheServiceTests.swift, BPMViewWiringTests.swift, LibraryScanServiceTests.swift
- SwiftData lightweight migration: [Hacking with Swift](https://www.hackingwithswift.com/quick-start/swiftdata/lightweight-vs-complex-migrations), [Donny Wals](https://www.donnywals.com/a-deep-dive-into-swiftdata-migrations/)

### Secondary (MEDIUM confidence)
- SwiftData migration behavior with optional String? fields confirmed across multiple sources: adding optional properties triggers automatic lightweight migration without a SchemaMigrationPlan

### Tertiary (LOW confidence)
- None

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - No new dependencies, only extending existing SwiftData model
- Architecture: HIGH - Following established project patterns (enum+rawValue, @Model, singleton service)
- Pitfalls: HIGH - All pitfalls identified from direct code inspection of existing callers

**Research date:** 2026-03-25
**Valid until:** 2026-04-25 (stable domain, no external dependencies changing)
