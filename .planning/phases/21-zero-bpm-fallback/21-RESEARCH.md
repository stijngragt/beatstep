# Phase 21: Zero-BPM Fallback - Research

**Researched:** 2026-03-25
**Domain:** SwiftUI settings UI + RunEngineService track selection logic
**Confidence:** HIGH

## Summary

Phase 21 adds user-configurable behavior for tracks without BPM data during an active run. Currently, `RunEngineService` silently skips nil-BPM tracks because `findMatchingTracks(forSPM:)` uses `guard let bpm = bpmMap[track.id] else { return false }` -- tracks without a BPM entry simply never match. The fallback to `findClosestTrack(forSPM:)` also uses the same guard, so nil-BPM tracks are excluded from every selection path.

The implementation requires: (1) a new `ZeroBPMFallback` enum persisted via UserDefaults following the project's established pattern (identical to `BPMTolerance`, `RunMode`, `TempoMode`), (2) a new Settings row in `SettingsView`, and (3) modification to `RunEngineService` to consult the fallback setting when encountering nil-BPM tracks.

**Primary recommendation:** Follow the exact enum + UserDefaults persistence pattern used by `BPMTolerance`/`RunMode`/`TempoMode`. Wire the setting into `selectNextMatch` and `findClosestTrack` rather than `findMatchingTracks`, since the fallback applies to the "what to do when a nil-BPM track is the next candidate" decision, not the matching algorithm itself.

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| FALL-01 | User can configure zero-BPM behavior in Settings (skip / play regardless / prompt) | New `ZeroBPMFallback` enum with UserDefaults persistence; new section in `SettingsView` with Picker |
| FALL-02 | Run engine respects configured fallback when encountering nil-BPM tracks | Modify `selectNextMatch` to include nil-BPM tracks based on fallback setting; `.skip` preserves current behavior as default |
</phase_requirements>

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| SwiftUI | iOS 17+ | Settings UI (Picker) | Already used throughout the app |
| UserDefaults | Foundation | Persist fallback preference | Project pattern for all enum settings |

### Supporting
No additional libraries needed. This phase uses only existing project infrastructure.

## Architecture Patterns

### Established Enum + Persistence Pattern

Every settings enum in this project follows the same structure. The new `ZeroBPMFallback` enum MUST follow this pattern exactly:

```swift
// Source: BeatStep/Models/BPMTolerance.swift, RunMode.swift, TempoMode.swift
enum ZeroBPMFallback: String, CaseIterable {
    case skip = "skip"
    case playRegardless = "playRegardless"
    case prompt = "prompt"

    var displayName: String {
        switch self {
        case .skip: return "Skip"
        case .playRegardless: return "Play Anyway"
        case .prompt: return "Ask Me"
        }
    }

    // MARK: - UserDefaults Persistence
    private static let key = "zeroBPMFallback"

    static var saved: ZeroBPMFallback {
        guard let raw = UserDefaults.standard.string(forKey: key),
              let value = ZeroBPMFallback(rawValue: raw) else {
            return .skip  // Default matches current behavior
        }
        return value
    }

    func save() {
        UserDefaults.standard.set(rawValue, forKey: ZeroBPMFallback.key)
    }
}
```

### Run Engine Integration Points

The current flow in `RunEngineService` where nil-BPM tracks are excluded:

1. **`startRun`** (line 108): Builds `bpmMap` -- only tracks with non-nil BPM get entries. Tracks with `bpm == nil` in `CachedBPM` are excluded from the map.
2. **`findMatchingTracks(forSPM:)`** (line 193): `guard let bpm = bpmMap[track.id] else { return false }` -- this is the primary filter that skips nil-BPM tracks.
3. **`findClosestTrack(forSPM:)`** (line 214): Same guard pattern -- nil-BPM tracks never considered as fallback.
4. **`selectNextMatch(forSPM:)`** (line 243): Calls both methods above, then falls through to `return nil` if nothing matches.

**Modification strategy:**
- Add a `zeroBPMFallback` property to `RunEngineService` (loaded from `ZeroBPMFallback.saved` at run start)
- In `selectNextMatch`, after the normal matching flow, if no track was selected OR as a parallel pool, consider nil-BPM tracks based on the fallback setting
- For `.skip`: current behavior (no change needed in matching logic)
- For `.playRegardless`: include nil-BPM tracks in the candidate pool, placed after BPM-matched tracks in priority
- For `.prompt`: this is the complex case -- requires an async callback or published state to surface a prompt to the UI during an active run

### Settings View Structure

`SettingsView` currently has sections: Account, Running Zones, Permissions, Disconnect. Add a new "Playback" section between Running Zones and Permissions:

```swift
Section("Playback") {
    Picker("No-BPM Tracks", selection: $zeroBPMFallback) {
        ForEach(ZeroBPMFallback.allCases, id: \.self) { option in
            Text(option.displayName).tag(option)
        }
    }
}
```

### Anti-Patterns to Avoid
- **Modifying `findMatchingTracks` directly**: This method should remain BPM-only. Nil-BPM fallback logic belongs in `selectNextMatch` where the decision tree lives.
- **Using @AppStorage for RunEngineService**: The engine is not a view. Follow the `static var saved` pattern used by all other model enums.
- **Alert-based prompt during run**: SwiftUI alerts block the run flow. If implementing prompt, use a published state property that the ActiveRunView observes, not a blocking alert.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Settings persistence | Custom file storage | UserDefaults via enum pattern | Project convention, lightweight |
| Settings picker UI | Custom toggle/button group | SwiftUI `Picker` | Native, accessible, consistent |

## Common Pitfalls

### Pitfall 1: Default Must Be Skip
**What goes wrong:** Choosing any default other than `.skip` changes behavior for existing users without their consent.
**Why it happens:** `.playRegardless` seems "friendlier" but breaks the current expectation.
**How to avoid:** Default is `.skip` -- this is explicitly called out in the success criteria.

### Pitfall 2: Prompt Fallback Complexity
**What goes wrong:** The "prompt" option requires pausing the run engine's track selection to wait for user input, creating async complexity.
**Why it happens:** The run engine's `selectNextMatch` is synchronous and called from multiple places.
**How to avoid:** STATE.md already flags this: "Prompt fallback UX during active run may need deferral if skip + playRegardless cover the need." Consider implementing prompt as a published state that pauses auto-advance rather than blocking selection. Alternatively, for prompt mode: skip the track but surface a banner/toast showing the skipped track with a "Play Anyway" action button. This avoids blocking the engine.
**Warning signs:** If the implementation requires making `selectNextMatch` async just for the prompt case, the design is too invasive.

### Pitfall 3: Nil-BPM Tracks Starving BPM-Matched Tracks
**What goes wrong:** In `.playRegardless` mode, if most tracks lack BPM, they could dominate playback over well-matched tracks.
**Why it happens:** If nil-BPM tracks are mixed into the same pool as matched tracks.
**How to avoid:** Use nil-BPM tracks only as a fallback pool -- prefer BPM-matched tracks first, then fill gaps with nil-BPM tracks when no match exists.

### Pitfall 4: Played Track Set Not Tracking Nil-BPM Tracks
**What goes wrong:** Nil-BPM tracks played via fallback don't get added to `playedTrackIDs`, causing repeats.
**How to avoid:** Ensure any track played through the fallback path is added to `playedTrackIDs` just like normal selections.

## Code Examples

### Current Nil-BPM Exclusion (what exists today)
```swift
// Source: BeatStep/Services/RunEngineService.swift:108-113
// In startRun -- only tracks WITH bpm get into the map
for track in tracks {
    if let bpm = BPMCacheService.shared.getBPM(forTrackID: track.id) {
        map[track.id] = bpm
    }
}
```

```swift
// Source: BeatStep/Services/RunEngineService.swift:192-194
// In findMatchingTracks -- guard excludes nil-BPM tracks
var matches = playlistTracks.filter { track in
    guard let bpm = bpmMap[track.id] else { return false }
    return targets.contains { target in abs(bpm - target) <= range }
}
```

### Recommended Integration Pattern for selectNextMatch
```swift
// After existing matching logic returns nil:
func selectNextMatch(forSPM spm: Int) -> SpotifyTrack? {
    // ... existing matching logic ...

    // If still no match and fallback allows nil-BPM tracks
    if zeroBPMFallback == .playRegardless {
        let nilBPMTracks = playlistTracks.filter { bpmMap[$0.id] == nil && !playedTrackIDs.contains($0.id) }
        if let track = nilBPMTracks.first {
            playedTrackIDs.insert(track.id)
            return track
        }
    }

    return nil
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Hard-coded skip of nil-BPM | User-configurable fallback | Phase 21 | Users with sparse BPM libraries can still enjoy run mode |

## Open Questions

1. **Prompt UX during active run**
   - What we know: Skip and playRegardless are straightforward. Prompt requires UI interaction during an active run.
   - What's unclear: Best UX pattern -- blocking alert vs non-blocking banner vs skipping with "undo" option.
   - Recommendation: Implement prompt as a non-blocking approach: skip the track, show a transient banner "Skipped [Track Name] (no BPM) -- Tap to play anyway". This keeps the engine synchronous and avoids blocking the run. If this proves too complex, prompt can be deferred (noted as a concern in STATE.md).

2. **Nil-BPM track identification at run start**
   - What we know: `startRun` builds `bpmMap` only for tracks with BPM. Tracks not in `bpmMap` are implicitly nil-BPM.
   - What's unclear: Whether to build an explicit `nilBPMTrackIDs` set for clarity.
   - Recommendation: No separate set needed. `playlistTracks.filter { bpmMap[$0.id] == nil }` is sufficient and self-documenting.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | XCTest (Xcode built-in) |
| Config file | BeatStepTests target in Xcode project |
| Quick run command | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BeatStepTests/RunEngineServiceTests -quiet` |
| Full suite command | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' -quiet` |

### Phase Requirements -> Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| FALL-01 | ZeroBPMFallback enum has 3 cases, default is skip | unit | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BeatStepTests/ZeroBPMFallbackTests -quiet` | No -- Wave 0 |
| FALL-01 | Settings view shows fallback picker | unit | Manual verification (UI) | manual-only: SwiftUI view layout |
| FALL-02 | selectNextMatch skips nil-BPM tracks when fallback=skip | unit | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BeatStepTests/RunEngineServiceTests -quiet` | Partial -- existing tests verify skip implicitly |
| FALL-02 | selectNextMatch includes nil-BPM tracks when fallback=playRegardless | unit | Same as above | No -- Wave 0 |
| FALL-02 | Prompt mode triggers UI state when nil-BPM track encountered | unit | Same as above | No -- Wave 0 |

### Sampling Rate
- **Per task commit:** `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BeatStepTests/RunEngineServiceTests -quiet`
- **Per wave merge:** `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' -quiet`
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] `BeatStepTests/ZeroBPMFallbackTests.swift` -- covers FALL-01 enum + persistence
- [ ] New tests in `RunEngineServiceTests.swift` -- covers FALL-02 engine behavior per fallback mode

## Sources

### Primary (HIGH confidence)
- Direct codebase inspection: `RunEngineService.swift` -- complete understanding of matching pipeline
- Direct codebase inspection: `BPMTolerance.swift`, `RunMode.swift`, `TempoMode.swift` -- established enum + persistence pattern
- Direct codebase inspection: `SettingsView.swift` -- current settings structure
- Direct codebase inspection: `RunEngineServiceTests.swift` -- existing test patterns and helpers

### Secondary (MEDIUM confidence)
- STATE.md blocker note: "Prompt fallback UX during active run may need deferral if skip + playRegardless cover the need"

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - pure SwiftUI + UserDefaults, identical to existing patterns
- Architecture: HIGH - clear integration points identified in RunEngineService
- Pitfalls: HIGH - prompt complexity is the only risk, well-documented in STATE.md

**Research date:** 2026-03-25
**Valid until:** 2026-04-25 (stable -- no external dependencies)
