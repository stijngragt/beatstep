# Architecture Research

**Domain:** iOS running music app -- v1.4 debug tooling, tap BPM, confidence tracking, zero-BPM fallback
**Researched:** 2026-03-25
**Confidence:** HIGH

## System Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                         Views Layer                             │
├─────────────┬──────────────┬──────────────┬─────────────────────┤
│  Settings   │  Library     │  Run Tab     │  Debug              │
│  Tab        │  Tab         │              │  (Sensor Lab)       │
│             │              │              │                     │
│ [+Debug     │ [+Confidence │ [+Zero-BPM   │ [NEW: full          │
│  toggle]    │  badges]     │  fallback    │  debug screen]      │
│ [+Fallback  │ [+Tap BPM   │  handling]   │                     │
│  picker]    │  sheet]      │              │                     │
├─────────────┴──────────────┴──────────────┴─────────────────────┤
│                      Services Layer                             │
├────────────────┬───────────────┬─────────────────────────────────┤
│ CadenceService │ RunEngine     │ BPMCacheService                 │
│                │ Service       │                                 │
│ [+debug        │ [+zero-BPM    │ [+confidence   [+manual BPM     │
│  interval]     │  fallback     │  field]         write]           │
│ [+raw data     │  policy]      │                                 │
│  exposure]     │               │                                 │
├────────────────┴───────────────┴─────────────────────────────────┤
│                      Data Layer                                  │
│  ┌──────────────┐  ┌──────────────┐                              │
│  │ CachedBPM    │  │ UserDefaults │                              │
│  │ (SwiftData)  │  │              │                              │
│  │ [+confidence │  │ [+debug      │                              │
│  │  +source]    │  │  settings]   │                              │
│  └──────────────┘  └──────────────┘                              │
└─────────────────────────────────────────────────────────────────┘
```

## New vs Modified Components

### New Components

| Component | Type | Responsibility |
|-----------|------|----------------|
| `SensorLabView` | View | Full debug screen: raw cadence samples, step count, detection interval slider, algorithm state, cadence window contents |
| `TapBPMView` | View | Tap-along interface for manual BPM entry, presented as sheet from playlist detail |
| `BPMConfidenceBadge` | View | Small color-coded capsule showing verified/approximate/manual/none confidence tier |
| `BPMConfidence` | Model (enum) | Confidence tiers: `.verified`, `.approximate`, `.manual`, `.none` with display properties |
| `ZeroBPMFallback` | Model (enum) | Fallback behavior: `.skip`, `.playRegardless`, `.prompt` with UserDefaults persistence |

### Modified Components

| Component | Modification | Why |
|-----------|-------------|-----|
| `CachedBPM` | Add `confidence: String?` and `source: String?` fields | Track how BPM was obtained (API verified, manual tap, etc). Foundation for all confidence features. |
| `BPMCacheService` | Add `cacheManualBPM(trackID:bpm:)` method. Update `cache()` to accept confidence/source params. | Support manual BPM entries from tap input and confidence tracking from API lookups. |
| `CadenceService` | Add configurable `windowDuration` (0.5-5.0s), expose `rawCadenceSample`, `sampleCount`, `stepCount`. | Sensor Lab needs raw data and faster-reacting averages for desk testing. |
| `LibraryScanService` | Pass confidence when caching: `"verified"` when BPM found, `"approximate"` when artist mismatch, `"none"` when nil. | Populate confidence data during the existing scan flow. |
| `RunEngineService` | Add `ZeroBPMFallback` policy to `selectNextMatch()`. Add `pendingFallbackTrack` for prompt mode. | Handle tracks with nil BPM according to user preference. |
| `SettingsView` | Add Debug Mode toggle + Sensor Lab NavigationLink. Add zero-BPM fallback Picker. | Entry points for new features. |
| `PlaylistDetailView` | Replace plain BPM badge in TrackRow with `BPMConfidenceBadge`. Add tap-BPM action for nil-BPM tracks. | Show confidence state and provide manual BPM entry point. |
| `ActiveRunView` | Observe `pendingFallbackTrack` for prompt-mode alert. | Handle the `.prompt` fallback when RunEngine encounters a zero-BPM track. |

## Recommended Project Structure

New files only -- existing folder structure is well-organized:

```
BeatStep/
├── Models/
│   ├── BPMConfidence.swift        # NEW: enum + computed property extension on CachedBPM
│   └── ZeroBPMFallback.swift      # NEW: fallback behavior enum with UserDefaults persistence
├── Services/
│   (CadenceService.swift)         # MODIFIED: debug interval, raw data exposure
│   (BPMCacheService.swift)        # MODIFIED: confidence-aware caching + manual BPM
│   (RunEngineService.swift)       # MODIFIED: zero-BPM fallback in selection
│   (LibraryScanService.swift)     # MODIFIED: write confidence on scan
├── Views/
│   ├── Debug/
│   │   └── SensorLabView.swift    # NEW: full debug/sensor lab screen
│   ├── Library/
│   │   ├── TapBPMView.swift       # NEW: tap-along BPM input sheet
│   │   └── BPMConfidenceBadge.swift  # NEW: confidence indicator capsule
│   │   (PlaylistDetailView.swift) # MODIFIED: confidence badges + tap BPM entry
│   └── Settings/
│       (SettingsView.swift)       # MODIFIED: debug toggle + fallback picker
```

### Structure Rationale

- **Debug/ folder:** Isolates debug tooling from production views. Only SensorLabView now but establishes the pattern.
- **BPMConfidenceBadge in Library/:** Displayed inline with tracks in playlist context, not a reusable design system primitive.
- **TapBPMView in Library/:** Invoked from playlist detail, writes to BPMCacheService -- it is a library workflow.
- **Models stay flat:** Two small enums do not warrant a subfolder. Matches the existing pattern (SyncQuality.swift, TempoMode.swift, etc).

## Architectural Patterns

### Pattern 1: SwiftData Lightweight Migration for Confidence Fields

**What:** Add `confidence: String?` and `source: String?` fields to the existing `CachedBPM` @Model.
**When to use:** Extending SwiftData models with new optional fields.
**Trade-offs:** SwiftData handles adding nullable fields as lightweight migration automatically -- no VersionedSchema needed. Existing records get `nil`, which maps cleanly to `BPMConfidence.none`.

**Implementation:**
```swift
// CachedBPM.swift -- add fields
@Model
final class CachedBPM {
    // ... existing fields ...
    var confidence: String?  // "verified", "approximate", "manual"
    var source: String?      // "getsongbpm", "manual_tap"
}

// BPMConfidence.swift -- enum + computed property
enum BPMConfidence: String, CaseIterable {
    case verified     // API returned exact match (artist matched)
    case approximate  // API returned result (artist did not match)
    case manual       // User tapped BPM manually
    case none         // No BPM data / legacy record

    init(from cached: CachedBPM) {
        if let conf = cached.confidence, let value = BPMConfidence(rawValue: conf) {
            self = value
        } else if cached.bpm != nil {
            self = .approximate  // Legacy records with BPM but no confidence field
        } else {
            self = .none
        }
    }
}
```

**Why String storage over enum raw value:** SwiftData predicate queries work more reliably with String fields than enum raw values. The `BPMConfidence` enum provides type safety at the Swift layer while the model stores plain strings.

### Pattern 2: Debug Mode via UserDefaults Gate

**What:** A single `@AppStorage("debugModeEnabled")` bool gates visibility of the Sensor Lab NavigationLink in SettingsView. CadenceService reads the same flag to determine whether to use a shorter detection window.
**When to use:** User-togglable feature flags that persist across sessions.
**Trade-offs:** Simple, no build configuration needed. UserDefaults is appropriate because the requirement specifies "behind settings toggle" -- not a compile-time flag.

**Data flow:**
```
SettingsView toggle --> @AppStorage("debugModeEnabled")
                                |
              +-----------------+------------------+
              |                                    |
    SensorLabView visible              CadenceService reads flag
    in Settings nav                    to set windowDuration
```

### Pattern 3: Tap BPM as Modal Sheet with Cache Writeback

**What:** TapBPMView presented as `.sheet` from PlaylistDetailView. User taps a surface rhythmically, view computes BPM from tap intervals, on confirm it writes to BPMCacheService with `.manual` confidence.
**When to use:** Isolated input workflows that produce a single result value.
**Trade-offs:** Sheet keeps playlist context visible. Callback via dismiss + cache refresh avoids tight coupling.

**BPM calculation approach:**
```swift
// Track last N tap timestamps, compute average interval
// Minimum 4 taps required for reliable BPM
// Rolling window of last 8 taps for stability
// BPM = 60.0 / averageInterval

private func computeBPM() -> Int? {
    guard tapTimestamps.count >= 4 else { return nil }
    let recent = tapTimestamps.suffix(8)
    let intervals = zip(recent, recent.dropFirst()).map { $1.timeIntervalSince($0) }
    let avgInterval = intervals.reduce(0, +) / Double(intervals.count)
    guard avgInterval > 0 else { return nil }
    return Int((60.0 / avgInterval).rounded())
}
```

### Pattern 4: Zero-BPM Fallback as RunEngine Policy

**What:** A `ZeroBPMFallback` enum stored in UserDefaults, read by RunEngineService during song selection.
**When to use:** Configurable behavior that affects core engine logic.

**Implementation detail for each mode:**

```swift
enum ZeroBPMFallback: String, CaseIterable {
    case skip            // Current behavior -- tracks without BPM excluded from matching
    case playRegardless  // Include nil-BPM tracks at end of candidate list
    case prompt          // Ask user before playing a nil-BPM track
}
```

**How each mode integrates with selectNextMatch:**

- **`.skip`** -- No change. Current `guard let bpm = bpmMap[track.id]` already excludes nil-BPM tracks.
- **`.playRegardless`** -- After finding BPM-matched candidates, append nil-BPM tracks as fallback pool. They sort to end, only played when no BPM-matched tracks remain.
- **`.prompt`** -- When no BPM-matched tracks remain and nil-BPM tracks exist, set `pendingFallbackTrack` on RunEngineService. ActiveRunView observes this and shows an alert. User confirms (play track) or skips (continue selection).

**Critical design note for `.prompt`:** RunEngineService must NOT block or await user input. The `pendingFallbackTrack` property is observed by ActiveRunView. Meanwhile, the engine plays the last matched track longer or remains silent briefly. This keeps the non-UI service layer free of SwiftUI.

## Data Flow

### BPM Confidence Data Flow

```
GetSongBPMService.fetchBPM()
    | returns Int?
    v
LibraryScanService
    | bpm != nil, artist matched  --> confidence = "verified"
    | bpm != nil, artist fallback --> confidence = "approximate"
    | bpm == nil                  --> confidence = "none"
    v
BPMCacheService.cache(trackID:, bpm:, confidence:, source:)
    v
CachedBPM (SwiftData)
    v
PlaylistDetailView reads cache
    v
BPMConfidenceBadge displays tier with color
```

### Manual BPM (Tap) Data Flow

```
PlaylistDetailView
    | user taps "Set BPM" on a nil-BPM track
    | .sheet(item: trackForTapBPM)
    v
TapBPMView(track: track)
    | user taps surface rhythmically
    | computes rolling BPM from last 8 taps
    | user confirms
    v
BPMCacheService.shared.cacheManualBPM(trackID:, bpm:)
    | writes confidence = "manual", source = "manual_tap"
    v
CachedBPM updated
    v
PlaylistDetailView refreshes bpmCache dict
    v
BPMConfidenceBadge shows "manual" state (distinct color)
```

### Zero-BPM Fallback Data Flow

```
RunEngineService.selectNextMatch(forSPM:)
    | iterates playlistTracks
    | finds tracks with bpmMap[id] == nil
    v
ZeroBPMFallback.saved (UserDefaults)
    |-- .skip       --> exclude from candidates (current behavior)
    |-- .playRegardless --> append to end of candidate list
    |-- .prompt     --> set pendingFallbackTrack on RunEngineService
                         |
                         v
                    ActiveRunView observes pendingFallbackTrack
                         | shows alert: "No BPM for [track]. Play anyway?"
                         |-- confirm --> RunEngineService plays track
                         |-- skip    --> RunEngineService continues
```

### Sensor Lab Data Flow

```
CadenceService (modified)
    |-- .currentSPM          (existing: rolling average)
    |-- .rawCadenceSample     (NEW: last unsmoothed value)
    |-- .stepCount            (NEW: cumulative steps since start)
    |-- .windowDuration       (NEW: configurable 0.5-5.0s)
    |-- .sampleCount          (NEW: samples in current window)
    |-- .state                (existing)
    |-- .trend                (existing)
         |
         v
SensorLabView reads all properties via @Observable
    | displays real-time values with labels
    | windowDuration slider writes back to CadenceService
    | reset button clears step count
```

**Key insight about "configurable detection interval":** CMPedometer delivers updates event-driven (on each step batch), NOT on a fixed polling interval. The "detection interval" requirement maps to adjusting `windowDuration` on CadenceService -- the rolling average window. Shorter window = faster reaction but noisier. Longer window = smoother but laggier. The current 5.0s default is tuned for running. Debug mode with 0.5-1.0s enables desk testing with hand taps.

## Integration Points

### CachedBPM Model Extension (Foundation)

Every downstream feature depends on confidence data being available in the model.

| Consumer | Reads | Writes | When |
|----------|-------|--------|------|
| `BPMConfidenceBadge` | `confidence` field | -- | Track list rendering |
| `RunEngineService` | `bpm` nil check | -- | Song selection (zero-BPM fallback) |
| `TapBPMView` | -- | `confidence = "manual"` | After tap-along confirm |
| `LibraryScanService` | -- | `confidence = "verified"/"approximate"` | During BPM scan |
| `PlaylistDetailView` | `confidence` via cache | -- | Rendering track rows |

### CadenceService Debug Extension

| Change | Impact | Risk |
|--------|--------|------|
| Configurable `windowDuration` | Affects rolling average responsiveness. Does NOT restart pedometer. | LOW -- changing a numeric parameter |
| Raw data exposure (`rawCadenceSample`) | New `@ObservationIgnored` property set in `handlePedometerData`, exposed via getter | NONE -- additive |
| Step count tracking (`stepCount`) | Already available from `CMPedometerData.numberOfSteps`, just needs to be stored and published | NONE -- additive |
| Sample count in window | `cadenceWindow.count` exposed as computed property | NONE -- already computed internally |

### RunEngineService Fallback Policy

Currently `findMatchingTracks` and `selectNextMatch` skip nil-BPM tracks via `guard let bpm = bpmMap[track.id]`. The fallback policy intercepts this.

| Mode | Change to `selectNextMatch` | Complexity |
|------|---------------------------|------------|
| `.skip` | No change -- current behavior | None |
| `.playRegardless` | After BPM-matched candidates, collect nil-BPM tracks and append | Low |
| `.prompt` | Return nil + set `pendingFallbackTrack`, view handles alert | Medium (needs view coordination) |

### SettingsView Additions

```swift
// Debug section (new)
Section("Developer") {
    Toggle("Debug Mode", isOn: $debugModeEnabled)

    if debugModeEnabled {
        NavigationLink("Sensor Lab") {
            SensorLabView()
        }
    }
}

// Playback section (new or merged with existing)
Section("Playback") {
    Picker("Unknown BPM Tracks", selection: $zeroBPMFallback) {
        ForEach(ZeroBPMFallback.allCases, id: \.self) { mode in
            Text(mode.displayLabel)
        }
    }
}
```

### PlaylistDetailView Changes

Two modifications to TrackRow:

1. **BPM badge becomes BPMConfidenceBadge** -- reads confidence from cache, shows colored capsule with tier label
2. **Tap BPM action** -- for tracks with `bpm == nil`, show a tap target or long-press action that opens TapBPMView sheet

```swift
// In PlaylistDetailView
@State private var trackForTapBPM: SpotifyTrack?

// In TrackRow or track action
.onLongPressGesture {
    if bpm == nil {
        trackForTapBPM = track
    }
}
.sheet(item: $trackForTapBPM) { track in
    TapBPMView(track: track) {
        // Refresh cache on dismiss
        bpmCache[track.id] = BPMCacheService.shared.getBPM(forTrackID: track.id)
    }
}
```

## Suggested Build Order

Dependencies flow downward -- each phase builds on the previous:

```
Phase 1: BPM Confidence Model + Service Layer
    CachedBPM +confidence +source fields (SwiftData migration)
    BPMConfidence enum
    BPMCacheService.cacheManualBPM() + updated cache() signature
    LibraryScanService writes confidence during scan
    --- Foundation: all other features read/write these fields ---

Phase 2: BPM Confidence Badges in UI
    BPMConfidenceBadge view component
    PlaylistDetailView / TrackRow integration
    --- Depends on Phase 1 model ---

Phase 3: Tap BPM Input
    TapBPMView (tap-along interface)
    PlaylistDetailView sheet integration
    --- Depends on Phase 1 for write, Phase 2 for display ---

Phase 4: Zero-BPM Fallback
    ZeroBPMFallback enum + UserDefaults persistence
    RunEngineService fallback policy in selectNextMatch()
    SettingsView fallback picker
    ActiveRunView prompt alert (for .prompt mode)
    --- Depends on Phase 1 for confidence awareness ---

Phase 5: Sensor Lab
    CadenceService debug extensions (windowDuration, raw data)
    SensorLabView
    SettingsView debug toggle + NavigationLink
    --- Independent of Phases 1-4, last because dev tooling ---
```

**Ordering rationale:**
- **Phase 1 first:** Data model change that every other feature depends on. SwiftData migration must land before anything reads the new fields.
- **Phase 2 before Phase 3:** Tap BPM needs confidence badges to show results. Building badges first gives the tap flow visual feedback immediately.
- **Phase 3 before Phase 4:** Tap BPM is the primary way users resolve zero-BPM tracks. Having it available makes the fallback config more useful.
- **Phase 4 before Phase 5:** Zero-BPM fallback is user-facing functionality that completes the BPM data quality story.
- **Phase 5 last:** Sensor Lab is debug/developer tooling with no dependencies on other features. Could be built in parallel with Phases 2-4 if needed.

## Anti-Patterns

### Anti-Pattern 1: Storing Confidence as Computed Property

**What people do:** Derive confidence from existing fields (`bpm != nil && lookupAttempted` = verified) instead of persisting it.
**Why it is wrong:** Cannot distinguish "API returned exact BPM with artist match" from "user tapped BPM" from "API returned best-guess." The provenance matters for trust signals.
**Do this instead:** Store `confidence` and `source` as persisted fields on CachedBPM. Compute the display tier from these explicit values.

### Anti-Pattern 2: Making Sensor Lab a Separate Tab

**What people do:** Add Sensor Lab as a 4th tab in the TabView for easy access during development.
**Why it is wrong:** Pollutes the 3-tab information architecture, requires removing later, visible to all users.
**Do this instead:** Gate behind a Settings toggle. NavigationLink push within Settings tab. Discoverable for power users without being prominent.

### Anti-Pattern 3: Blocking Song Selection for Prompt Fallback

**What people do:** Make `selectNextMatch()` async and await user input when encountering a zero-BPM track in prompt mode.
**Why it is wrong:** RunEngineService is a non-view service. Blocking selection freezes the run experience while waiting for UI interaction.
**Do this instead:** Set a published `pendingFallbackTrack` property. Skip the track in selection. ActiveRunView observes the property and presents an alert. On user response, either play the track directly or continue.

### Anti-Pattern 4: Restarting CMPedometer for Interval Changes

**What people do:** Call `stopUpdates()` + `startUpdates(from:)` when the user changes detection interval in Sensor Lab.
**Why it is wrong:** CMPedometer is event-driven, not polling-based. Restarting loses the step count baseline and creates a data gap.
**Do this instead:** Keep pedometer running continuously. Change `windowDuration` for the rolling average and the inactivity timer threshold. These are processing parameters, not pedometer parameters.

### Anti-Pattern 5: Tap BPM Saving Without Confirmation

**What people do:** Auto-save BPM as soon as enough taps are collected.
**Why it is wrong:** User might still be finding the rhythm. Early taps are often off. Auto-saving captures bad data.
**Do this instead:** Show live BPM preview as user taps, require explicit "Save" button press. Minimum 4 taps before save is enabled. Last 8 taps used for calculation to filter out early outliers.

## Sources

- BeatStep v1.3 codebase: CadenceService.swift, RunEngineService.swift, BPMCacheService.swift, CachedBPM.swift, PlaylistDetailView.swift, SettingsView.swift, LibraryScanService.swift, GetSongBPMService.swift
- Apple CMPedometer: event-driven step delivery, not interval-polled (currentCadence property on CMPedometerData)
- SwiftData lightweight migration: new optional fields handled automatically without VersionedSchema
- @Observable pattern used throughout existing codebase for reactive state

---
*Architecture research for: BeatStep v1.4 "Under The Hood" -- debug tooling, tap BPM, confidence, zero-BPM fallback*
*Researched: 2026-03-25*
