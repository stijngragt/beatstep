# Phase 5: Guided Run + Polish - Research

**Researched:** 2026-03-23
**Domain:** Guided run mode, warm-up/cool-down ramping, smart song selection, catalog discovery
**Confidence:** HIGH

## Summary

Phase 5 extends the existing free run engine with a guided run mode (fixed target BPM), warm-up/cool-down ramping, and smarter song selection based on danceability data from GetSongBPM. All building blocks are already in the codebase: RunEngineService handles song matching and playback, BPMDiscoveryService handles catalog discovery via GetSongBPM + Spotify search, and the UI patterns (segmented controls, UserDefaults persistence) are established.

The key technical finding is that GetSongBPM's `/song/` endpoint returns a `danceability` field (integer, 0-100 scale) which can be used for smart ranking. There is no `energy` field, but danceability correlates well with energy for running music. This data needs to be fetched during the existing BPM scan and cached alongside BPM in the SwiftData CachedBPM model.

**Primary recommendation:** Extend RunEngineService with a `RunMode` enum (free/guided) and a ramp state machine (warmUp/atPace/coolDown), add danceability to BPM cache, and wire BPMDiscoveryService into the engine for on-demand pool expansion.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- Segmented control on RunView idle state: "Free" / "Guided" -- selecting Guided reveals target BPM configuration
- Target BPM set via named pace presets ("Easy Jog", "Steady", "Fast" etc.) with a "Custom" option that opens a numeric picker
- Tolerance picker (Tight/Normal/Loose) applies to both free run and guided run -- same behavior
- Persist last-used mode (Free/Guided) and last target BPM to UserDefaults between runs
- Always ramp in guided mode: ~3-5 min warm-up from ~140 BPM stepping up to target, ~3-5 min cool-down stepping back down
- Step-based progression: each new song is ~5-10 BPM closer to (or further from) target BPM
- Cool-down triggered manually via a "Cool Down" button
- Visual feedback: subtle phase label only -- "Warming up" / "At pace" / "Cooling down"
- Implicit from playlist -- no explicit mood/genre UI. The playlist is the preference.
- Among BPM matches, rank by energy + danceability data (higher energy during active running, lower during ramp phases)
- Energy/danceability data sourced from GetSongBPM API extras
- Smart selection applies to BOTH free run and guided run
- Auto-fallback: when playlist has fewer than ~3 songs matching current target BPM, auto-discover from Spotify catalog
- On-demand mid-run: discover as the pool runs low, not pre-run batch
- Discovered songs auto-saved to "BeatStep Discoveries" playlist
- Applies to BOTH free run and guided run modes

### Claude's Discretion
- Named pace preset values and labels
- Exact warm-up/cool-down duration and step increments
- How to integrate guided mode into RunEngineService (extend existing vs. new service)
- Cool Down button placement and styling
- Discovery batch size and rate limiting strategy
- Fallback behavior if GetSongBPM doesn't provide danceability data

### Deferred Ideas (OUT OF SCOPE)
None -- discussion stayed within phase scope
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| RUN-02 | Guided run mode -- user sets target BPM, app plays music at that tempo | RunEngineService needs RunMode enum, fixed targetBPM field, segmented control in RunView idle state, named pace presets with UserDefaults persistence |
| RUN-03 | Warm-up/cool-down ramp -- BPM gradually increases from warm-up to target pace, then decreases | Ramp state machine (warmUp/atPace/coolDown) in RunEngineService, step-based BPM progression per song, manual Cool Down button trigger |
| BPM-06 | When multiple songs match BPM, selection considers genre/mood preferences | GetSongBPM provides danceability (0-100), cache in CachedBPM model, rank matches by danceability (high for active, low for ramp phases) |
</phase_requirements>

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| SwiftUI | iOS 17+ | UI (segmented controls, pickers, phase labels) | Already used throughout app |
| SwiftData | iOS 17+ | CachedBPM model extension for danceability | Already used for BPM cache |
| Foundation (UserDefaults) | iOS 17+ | Persist run mode, target BPM | Established pattern from BPMTolerance |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| GetSongBPM API (via proxy) | Current | Danceability data for smart selection | During BPM scan and on-demand discovery |
| Spotify Web API | Feb 2026 | Search for discovered tracks, playlist management | On-demand discovery when pool runs low |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| GetSongBPM danceability | Spotify Audio Features energy/valence | Spotify deprecated audio-features for new apps (Nov 2024). Not available. |
| BPM-based step ramp | Time-based linear interpolation | Step-based (song-by-song) is more natural -- runner hears distinct progression per track. Simpler to implement. |

## Architecture Patterns

### Recommended Approach: Extend RunEngineService

Extend the existing `RunEngineService` singleton rather than creating a new service. The engine already owns song selection, cadence monitoring, and playback orchestration. Add guided mode as new state within the same service.

### Pattern 1: Run Mode Enum + Ramp State Machine

**What:** A `RunMode` enum (`.free` / `.guided(targetBPM: Int)`) and a `RampPhase` enum (`.warmUp` / `.atPace` / `.coolDown`) that drive song selection BPM targeting.

**When to use:** During guided runs, the effective BPM target changes based on ramp phase rather than following cadence.

```swift
enum RunMode: Equatable {
    case free
    case guided(targetBPM: Int)
}

enum RampPhase: String {
    case warmUp = "Warming up"
    case atPace = "At pace"
    case coolDown = "Cooling down"
}
```

**How ramp works:**
- Guided mode starts in `.warmUp` at ~140 BPM
- Each song steps ~5-10 BPM closer to target
- After enough steps to reach target BPM, transitions to `.atPace`
- When user taps "Cool Down", transitions to `.coolDown`
- Each subsequent song steps ~5-10 BPM back toward ~140 BPM
- When cool-down reaches ~140, stop the run

### Pattern 2: Smart Selection with Danceability Ranking

**What:** Replace `matches.randomElement()!` in `selectNextMatch` with ranked selection based on danceability score from cache.

**When to use:** Always (both free and guided modes).

```swift
// In selectNextMatch, after filtering matches:
let ranked = matches.sorted { trackA, trackB in
    let danceA = danceabilityMap[trackA.id] ?? 50
    let danceB = danceabilityMap[trackB.id] ?? 50

    if preferHighEnergy {
        return danceA > danceB  // Higher danceability first
    } else {
        return danceA < danceB  // Lower danceability for ramp
    }
}
// Pick top match (or weighted random from top 3 for variety)
```

**Ranking strategy by phase:**
- Free run (active): prefer higher danceability
- Guided warm-up: prefer lower danceability (building up)
- Guided at-pace: prefer higher danceability (peak energy)
- Guided cool-down: prefer lower danceability (winding down)

### Pattern 3: On-Demand Discovery Integration

**What:** Wire `BPMDiscoveryService.discoverTracks(atBPM:)` into RunEngineService to expand the pool when matches run low.

**When to use:** When `findMatchingTracks(forSPM:)` returns fewer than 3 unplayed matches.

```swift
// In selectNextMatch, after finding matches:
if matches.count < 3 && !isDiscovering {
    isDiscovering = true
    Task {
        let discovered = try? await BPMDiscoveryService.shared.discoverTracks(atBPM: effectiveBPM)
        if let tracks = discovered, !tracks.isEmpty {
            // Add to playlistTracks and bpmMap
            // Save to discovery playlist
            try? await BPMDiscoveryService.shared.saveToDiscoveryPlaylist(tracks: tracks)
        }
        isDiscovering = false
    }
}
```

### Pattern 4: Named Pace Presets

**What:** Predefined BPM targets with friendly names, plus a custom option.

**Recommended values:**
| Preset | BPM | Use Case |
|--------|-----|----------|
| Easy Jog | 150 | Warm-up pace, slow jog |
| Steady | 160 | Comfortable running pace |
| Tempo | 170 | Training pace |
| Fast | 180 | Race pace |
| Sprint | 190 | High intensity |
| Custom | User-set | Any specific BPM |

### Recommended Project Structure Changes

```
BeatStep/
├── Models/
│   ├── CachedBPM.swift          # Add danceability: Int? field
│   ├── RunMode.swift             # NEW: RunMode enum
│   ├── RampPhase.swift           # NEW: RampPhase enum
│   └── PacePreset.swift          # NEW: Named pace presets
├── Services/
│   ├── RunEngineService.swift    # Extend with guided mode, ramp, smart selection, discovery
│   ├── BPMDiscoveryService.swift # Already exists, wire into engine
│   └── GetSongBPMService.swift   # Parse danceability from song response
└── Views/Run/
    ├── RunView.swift             # Add mode picker, target BPM UI, cool down button, phase label
    ├── ModePicker.swift          # NEW: Free/Guided segmented control
    └── PacePresetPicker.swift    # NEW: Target BPM preset picker
```

### Anti-Patterns to Avoid
- **Separate GuidedRunEngine service:** Don't create a parallel service -- the core loop (cadence monitor, song-end monitor, playback) is identical. Only the BPM target source differs.
- **Pre-run batch discovery:** Don't discover all songs before starting. The user wants to start running immediately. Discover on-demand as the pool depletes.
- **Showing target BPM number:** User decision explicitly says no target BPM number on screen -- only phase labels ("Warming up" / "At pace" / "Cooling down").

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| BPM discovery | Custom Spotify search by BPM | `BPMDiscoveryService.discoverTracks(atBPM:)` | Already built and tested in Phase 2 |
| Discovery playlist management | Manual playlist creation logic | `BPMDiscoveryService.saveToDiscoveryPlaylist()` | Already handles create-on-first-use pattern |
| Tolerance matching | New BPM matching logic | Existing `findMatchingTracks(forSPM:)` | Already handles direct + half/double matching with tolerance |
| UserDefaults persistence pattern | New persistence layer | Follow `BPMTolerance.saved` / `.save()` pattern | Proven, simple, consistent |

## Common Pitfalls

### Pitfall 1: SwiftData Schema Migration for Danceability
**What goes wrong:** Adding `danceability: Int?` to CachedBPM crashes on existing installs if schema migration is not handled.
**Why it happens:** SwiftData lightweight migration handles adding optional properties automatically, but only if the default is nil.
**How to avoid:** Declare as `var danceability: Int? = nil` (optional with nil default). SwiftData handles this as a lightweight migration automatically. No `VersionedSchema` needed.
**Warning signs:** Crash on launch after update with "failed to migrate" error.

### Pitfall 2: Discovery During Active Run Blocks Main Thread
**What goes wrong:** Discovery involves network calls (GetSongBPM + Spotify search), which could block song selection.
**Why it happens:** BPMDiscoveryService is `@MainActor`. Calling it during run could cause UI freeze.
**How to avoid:** Fire discovery as a background `Task`, don't `await` it in the selection path. Use an `isDiscovering` flag to prevent duplicate requests. Discovered tracks get added to the pool asynchronously.
**Warning signs:** UI freezing during a run when pool is low.

### Pitfall 3: Ramp Overshooting Target BPM
**What goes wrong:** If step size is 10 BPM and target is 175, stepping from 170 to 180 overshoots.
**Why it happens:** Fixed step sizes don't align with all targets.
**How to avoid:** Clamp the effective BPM to target during warm-up (never exceed) and to warm-up BPM during cool-down (never go below). The last step before target should snap to exact target.
**Warning signs:** Music suddenly faster/slower than target pace.

### Pitfall 4: Discovery Rate Limiting
**What goes wrong:** Too many GetSongBPM API calls during a run, hitting rate limits.
**Why it happens:** Each discovery batch triggers 10+ API calls (1 tempo search + 10 Spotify searches).
**How to avoid:** Limit discovery to once per effective BPM change. Use `isDiscovering` guard. Batch size of 5-8 is sufficient. The existing 300ms delay between Spotify searches is adequate.
**Warning signs:** API 429 errors mid-run.

### Pitfall 5: Cadence Monitor Conflicts with Guided Mode
**What goes wrong:** In guided mode, the engine should use the ramp BPM target, not the runner's actual cadence, for song selection.
**Why it happens:** Free run mode selects songs based on sustainedSPM (cadence). Guided mode should select based on effectiveBPM (ramp target).
**How to avoid:** Extract an `effectiveBPM` computed property that returns sustainedSPM in free mode and the ramp-calculated BPM in guided mode. Use this everywhere instead of sustainedSPM directly.
**Warning signs:** Guided mode songs matching runner's actual pace instead of the target pace.

## Code Examples

### GetSongBPM Song Response with Danceability
```json
// Source: GetSongBPM API documentation (https://getsongbpm.com/api)
{
  "song": {
    "id": "o2r0L",
    "title": "Master of Puppets",
    "tempo": "220",
    "time_sig": "4/4",
    "key_of": "Em",
    "open_key": "2m",
    "danceability": 55,
    "acousticness": 0,
    "artist": { "id": "nZR", "name": "Metallica" }
  }
}
```

### Extending GetSongBPMSong Model
```swift
// Add danceability to existing model
struct GetSongBPMSong: Codable {
    let id: String
    let title: String?
    let tempo: String?
    let artist: GetSongBPMArtist?
    let album: GetSongBPMAlbum?
    let danceability: Int?  // 0-100 scale, NEW
}
```

### UserDefaults Persistence Pattern (established)
```swift
// Follow existing BPMTolerance pattern for RunMode + targetBPM
enum RunMode: String, CaseIterable {
    case free, guided

    private static let key = "selectedRunMode"

    static var saved: RunMode {
        guard let raw = UserDefaults.standard.string(forKey: key),
              let value = RunMode(rawValue: raw) else { return .free }
        return value
    }

    func save() {
        UserDefaults.standard.set(rawValue, forKey: RunMode.key)
    }
}
```

### Ramp BPM Calculation
```swift
// Step-based warm-up progression
func effectiveTargetBPM(phase: RampPhase, targetBPM: Int, songsPlayed: Int, stepSize: Int = 8) -> Int {
    let warmUpStart = 140
    switch phase {
    case .warmUp:
        let rampedBPM = warmUpStart + (songsPlayed * stepSize)
        return min(rampedBPM, targetBPM)  // Clamp to target
    case .atPace:
        return targetBPM
    case .coolDown:
        let cooledBPM = targetBPM - (songsPlayed * stepSize)
        return max(cooledBPM, warmUpStart)  // Clamp to warm-up BPM
    }
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Spotify Audio Features (energy, valence) | GetSongBPM danceability field | Nov 2024 (Spotify deprecation) | Must use GetSongBPM for audio attributes. Only danceability + acousticness available. |
| Spotify Recommendations API | GetSongBPM tempo endpoint + Spotify search | Nov 2024 | BPMDiscoveryService already implements this pattern |
| `matches.randomElement()` | Danceability-ranked selection | Phase 5 (new) | Smart selection replaces pure random |

## Open Questions

1. **Danceability field availability across songs**
   - What we know: GetSongBPM API returns `danceability: Int` in song endpoint response
   - What's unclear: Coverage -- do all songs have danceability data, or is it sometimes null/missing?
   - Recommendation: Parse as `Int?`, fallback to 50 (neutral) when missing. This is already the pattern for BPM (optional in cache).

2. **Cool-down auto-stop behavior**
   - What we know: Cool-down is manually triggered. User decision says ramp back to ~140 BPM.
   - What's unclear: Should the run auto-stop when cool-down reaches warm-up BPM, or keep playing at ~140?
   - Recommendation: Auto-stop the run when cool-down completes (reaches warm-up BPM). This provides a clean end to the guided session.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | XCTest (built-in, Xcode 15+) |
| Config file | BeatStepTests target in project.pbxproj |
| Quick run command | `xcodebuild test -project BeatStep.xcodeproj -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BeatStepTests 2>&1 \| tail -20` |
| Full suite command | `xcodebuild test -project BeatStep.xcodeproj -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 \| tail -40` |

### Phase Requirements to Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| RUN-02 | Guided mode selects songs at fixed target BPM (not cadence) | unit | `xcodebuild test ... -only-testing:BeatStepTests/RunEngineServiceTests/testGuidedModeUsesTargetBPM` | No -- Wave 0 |
| RUN-02 | Named pace presets map to correct BPM values | unit | `xcodebuild test ... -only-testing:BeatStepTests/PacePresetTests` | No -- Wave 0 |
| RUN-03 | Warm-up ramp steps BPM toward target per song | unit | `xcodebuild test ... -only-testing:BeatStepTests/RunEngineServiceTests/testWarmUpRampProgression` | No -- Wave 0 |
| RUN-03 | Cool-down ramp steps BPM away from target | unit | `xcodebuild test ... -only-testing:BeatStepTests/RunEngineServiceTests/testCoolDownRampProgression` | No -- Wave 0 |
| RUN-03 | Ramp clamps to target (no overshoot) | unit | `xcodebuild test ... -only-testing:BeatStepTests/RunEngineServiceTests/testRampClampsToTarget` | No -- Wave 0 |
| BPM-06 | Smart selection ranks by danceability (high for active) | unit | `xcodebuild test ... -only-testing:BeatStepTests/RunEngineServiceTests/testSmartSelectionRanksByDanceability` | No -- Wave 0 |
| BPM-06 | Smart selection uses low danceability during ramp phases | unit | `xcodebuild test ... -only-testing:BeatStepTests/RunEngineServiceTests/testSmartSelectionLowDanceabilityForRamp` | No -- Wave 0 |
| BPM-06 | Missing danceability falls back to neutral (50) | unit | `xcodebuild test ... -only-testing:BeatStepTests/RunEngineServiceTests/testMissingDanceabilityFallback` | No -- Wave 0 |

### Sampling Rate
- **Per task commit:** Quick test of relevant test class
- **Per wave merge:** Full suite
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] `BeatStepTests/RunEngineServiceTests.swift` -- extend with guided mode, ramp, and smart selection tests (file exists, tests don't)
- [ ] `BeatStepTests/PacePresetTests.swift` -- covers RUN-02 preset mapping
- [ ] No framework install needed -- XCTest already configured

## Sources

### Primary (HIGH confidence)
- Project codebase: RunEngineService.swift, BPMDiscoveryService.swift, GetSongBPMService.swift, RunView.swift, BPMTolerance.swift, CachedBPM.swift -- direct source code analysis
- GetSongBPM API documentation (https://getsongbpm.com/api) -- confirmed danceability field in song response

### Secondary (MEDIUM confidence)
- Spotify API deprecation announcement (https://developer.spotify.com/blog/2024-11-27-changes-to-the-web-api) -- audio-features/recommendations deprecated for new apps
- GetSongBPM API response structure from WebSearch -- danceability integer field confirmed by multiple sources

### Tertiary (LOW confidence)
- Danceability coverage across GetSongBPM catalog -- unknown what percentage of songs have this field populated. Fallback strategy recommended.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - extending existing codebase with established patterns
- Architecture: HIGH - RunEngineService structure is well understood, extension approach is clear
- Pitfalls: HIGH - identified from direct code analysis (SwiftData migration, @MainActor, ramp math)
- Smart selection data: MEDIUM - danceability field confirmed but coverage unknown

**Research date:** 2026-03-23
**Valid until:** 2026-04-23 (stable domain, no external API changes expected)
