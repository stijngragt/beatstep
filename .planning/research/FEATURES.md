# Feature Research

**Domain:** Debug tooling, manual BPM input, confidence indicators, and zero-BPM fallback for iOS running music app
**Researched:** 2026-03-25
**Confidence:** HIGH

## Scope Note

This file covers NEW features for v1.4 "Under The Hood" only. All v1.0-v1.3 features (cadence detection, BPM matching, Spotify playback, free/guided run, design system, tab nav, onboarding, zones, library analysis UX, active run screen with sync indicators, tempo toggle) are shipped and stable. Research below addresses: Sensor Lab debug screen, tap BPM input, BPM confidence indicators, and zero-BPM fallback behavior.

---

## Feature Landscape

### Table Stakes (Users Expect These)

Features that users of a BPM-matching app expect once they encounter tracks with missing or unreliable BPM data. Missing these = trust erosion.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| **BPM confidence indicator per track** | Users already see BPM badges on TrackRow. When some tracks show "128 BPM" from the API and others show "--", users need to understand why. DJ apps (rekordbox, beaTunes) universally show source quality badges. Without confidence, users cannot distinguish a verified BPM from a guess. | LOW | Add `bpmSource` field to `CachedBPM` model. Render as color-coded badge variant on existing `TrackRow`: green dot for API-verified, blue dot for manual tap, gray "--" for unknown. Builds on existing orange BPM badge styling. |
| **Zero-BPM fallback: skip by default** | Current `RunEngineService.findMatchingTracks` silently ignores tracks where `bpmMap[id] == nil` via `guard let bpm`. Users with niche libraries hit this constantly -- songs disappear from rotation with no explanation. The skip behavior is correct but must be made visible and configurable. | LOW | Current behavior already skips. Feature is making this explicit: show "N tracks skipped (no BPM)" in playlist header or pre-run summary. Add setting to control behavior. |
| **Configurable zero-BPM behavior** | Three options: skip (default, preserves current behavior), play regardless (treat as wildcard fill), shuffle unmatched (mix unknowns into rotation). Users with large unanalyzed libraries need the "play regardless" option to avoid empty playlists during runs. | LOW | UserDefaults-backed enum in Settings. "Skip" maps to current `guard let` logic. "Play regardless" adds nil-BPM tracks to fallback pool in `selectNextMatch`. Clean integration -- one `if` branch in existing method. |
| **Tap BPM input for tracks without data** | Songs without GetSongBPM results are dead weight in the library. Tap-to-detect is the universal manual override in every DJ tool, metronome app, and music production workflow. Research confirms: minimum 4 taps for display, 8 taps for stability, rolling average with outlier rejection. | MEDIUM | New modal sheet on long-press of TrackRow in `PlaylistDetailView`. Large tap area, running average of last 8 intervals, stddev-based stability indicator, save button. Writes to `CachedBPM` with `.manual` source. |

### Differentiators (Competitive Advantage)

Features that make BeatStep's algorithm observable, testable, and trustworthy -- beyond what any running music app offers.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| **Sensor Lab debug screen** | No running music app exposes raw sensor data. For the developer this is essential for tuning the cadence algorithm. For power users it builds trust by showing the algorithm is working. Hidden behind Settings toggle -- zero cognitive cost for casual users. | MEDIUM | New `SensorLabView` behind `@AppStorage("sensorLabEnabled")` toggle in SettingsView. Shows: raw CMPedometer cadence, rolling average SPM, step count, detection state, trend. All data reads from `CadenceService.shared` which is already `@Observable`. |
| **Configurable detection interval** | Default 5s rolling window (`CadenceService.windowDuration`) is tuned for running smoothness. For desk testing and development, 0.5-1s gives immediate feedback. This single parameter change transforms debugging speed. | LOW | Expose `windowDuration` as settable on `CadenceService` (currently `private let`). Add slider in Sensor Lab only (0.5s to 5.0s). Reset to 5.0 when Sensor Lab is dismissed to prevent accidental production use. |
| **Live confidence badge in RunPlayerView** | During a run, show whether the current song's BPM is API-verified or manually tapped. Micro-badge next to BPM display. Builds trust without cluttering. | LOW | One additional view element in `RunPlayerView` next to BPM. Reads `CachedBPM.bpmSource` via cache lookup. Depends on confidence badge existing in TrackRow first. |
| **Pre-run BPM coverage summary** | Before starting a run, show "42/50 tracks have BPM data. 8 tracks will be skipped." Gives users agency to fix coverage gaps before running. | LOW | Compute from existing `BPMCacheService.coverageStats(forTrackIDs:)` -- method already exists. Display in RunView before the Start button. |

### Anti-Features (Commonly Requested, Often Problematic)

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| **Zero-BPM prompt during run** | "Let me decide per-song whether to play unknowns" | Interrupts the running experience. Cannot safely interact with phone while running. The entire BeatStep premise is hands-free flow. Every prompt is a broken stride. | Pre-run: show count of unmatched tracks. Settings: choose skip or play-regardless globally. Decision happens before the run, not during. |
| **Auto-BPM via microphone analysis** | "Just listen to the song and detect BPM automatically" | Requires audio analysis SDK (Essentia, aubio), adds 5-10MB binary size, significant battery drain, and accuracy is unreliable for complex rhythms. Cannot access Spotify audio stream directly -- would need to record from mic during playback, which is fragile and quality-dependent. | Tap BPM is simpler, user-controlled, and handles the 5% of tracks GetSongBPM misses. API covers 95%+ of mainstream tracks. |
| **Sensor Lab always visible** | "Show debug data on the run screen" | Clutters the carefully designed three-zone ActiveRunView layout. Information overload during exercise. Conflicts with the focused, glanceable run screen. | Sensor Lab is a separate screen accessed from Settings only. Run screen stays clean. Developer can split-screen on iPad or check between runs. |
| **Export sensor data to CSV** | "Let me analyze my cadence patterns" | Scope creep into workout analytics territory. PROJECT.md explicitly excludes post-run analytics. Opens the door to feature requests for charts, trends, comparisons. | Sensor Lab is for live observation only. Users who want analytics have Strava, Apple Health, Garmin Connect. |
| **Editable BPM text field** | "Let me just type the number" | Users rarely know exact BPM. Tap interface is more natural and produces confidence metadata (interval consistency). Text input gives false precision with zero confidence signal. Also requires keyboard which is hostile on a music input screen. | Tap BPM with visual feedback of stabilizing value. Display final integer BPM after save. If user knows exact BPM, they can tap at that tempo. |
| **Batch tap BPM workflow** | "Let me fix all unanalyzed tracks at once" | Requires playing each track, tapping along, confirming, advancing. Complex flow with many error states. Easy to mis-tap on wrong song. | Single-track tap is sufficient for v1.4. If demand exists, batch workflow is a future milestone. Most users only have 5-10 unanalyzed tracks. |

---

## Feature Dependencies

```
[BPM Source Enum on CachedBPM]  <-- FOUNDATION, build first
    |
    +---> [BPM Confidence Badge in TrackRow]
    |         |
    |         +---> [Live Confidence Badge in RunPlayerView] (same data, different location)
    |
    +---> [Tap BPM Input] (writes .manual source on save)
    |
    +---> [Pre-run BPM Coverage Summary] (counts by source type)

[Sensor Lab Toggle in Settings]
    |
    +---> [SensorLabView] (reads CadenceService.shared directly)
              |
              +---> [Configurable Detection Interval] (modifies CadenceService.windowDuration)

[Zero-BPM Fallback Config]  <-- STANDALONE, no dependencies on other v1.4 features
    (integrates into existing RunEngineService.selectNextMatch)
```

### Dependency Notes

- **BPM Confidence Badge requires BPM Source Enum:** The `CachedBPM` SwiftData model must gain a `bpmSource` field before any UI can display confidence. This is the data foundation -- build first, everything else layers on top.
- **Tap BPM writes to BPM Source Enum:** Tap results are saved as `.manual` source. Without the enum, tap BPM has no way to record provenance distinct from API results.
- **Live Confidence Badge depends on TrackRow badge:** Same data model, same rendering logic, different placement (`RunPlayerView` vs `TrackRow`). Build TrackRow version first, extract shared badge component, reuse in run screen.
- **Configurable Detection Interval depends on Sensor Lab:** The interval slider lives inside Sensor Lab UI. Sensor Lab toggle and view must exist first.
- **Zero-BPM Fallback is fully standalone:** Integrates directly into `RunEngineService.selectNextMatch` with a UserDefaults-backed enum. No dependency on confidence badges, tap BPM, or sensor lab. Can be built in parallel.
- **Pre-run Coverage Summary uses existing method:** `BPMCacheService.coverageStats(forTrackIDs:)` already returns `(withBPM: Int, total: Int)`. Just needs a UI element in `RunView`.

---

## MVP Definition (v1.4 Scope)

### Must Build

- [ ] **BPM source enum on CachedBPM model** -- Foundation for all confidence features. SwiftData lightweight migration adds `bpmSource: String` with default mapping: existing records with `bpm != nil` get `.api`, records with `bpm == nil` get `.none`.
- [ ] **BPM confidence badge in TrackRow** -- Color-coded indicator replacing uniform orange badge: green (API-verified), blue (manual tap), gray (no BPM). Integrates into existing `PlaylistDetailView` TrackRow.
- [ ] **Tap BPM input sheet** -- Modal from long-press on track. Large tap target, rolling 8-interval average, outlier rejection (2x stddev), stability indicator, save when stddev < 5 BPM. Writes `.manual` source.
- [ ] **Zero-BPM fallback setting** -- Picker in Settings: Skip (default), Play Regardless. Stored in UserDefaults. Integrates into `RunEngineService.selectNextMatch`.
- [ ] **Sensor Lab screen** -- New view behind `@AppStorage` toggle in Settings. Displays: raw cadence SPM, state, trend, step count, window sample count.
- [ ] **Configurable detection interval** -- Slider in Sensor Lab (0.5s-5.0s). Modifies `CadenceService.windowDuration`. Resets to 5.0 on Sensor Lab dismiss.

### Add After Validation (v1.4.x)

- [ ] **Live confidence badge in RunPlayerView** -- Micro-badge next to BPM in run screen player area. One view addition once TrackRow badge component exists.
- [ ] **Pre-run BPM coverage summary** -- "42/50 tracks matched" in RunView. Uses existing `coverageStats` method.

### Future Consideration (v1.5+)

- [ ] **Batch tap BPM workflow** -- Queue unanalyzed tracks, play snippets, tap along. Only if demand materializes.
- [ ] **Sensor Lab accelerometer graph** -- Real-time chart of raw accelerometer data (requires CMMotionManager, separate from CMPedometer).

---

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| BPM source enum (model migration) | HIGH | LOW | P1 |
| Confidence badge in TrackRow | HIGH | LOW | P1 |
| Tap BPM input | HIGH | MEDIUM | P1 |
| Zero-BPM fallback setting | MEDIUM | LOW | P1 |
| Sensor Lab screen | MEDIUM | MEDIUM | P1 |
| Configurable detection interval | LOW (developer tool) | LOW | P1 |
| Live confidence in RunPlayerView | LOW | LOW | P2 |
| Pre-run coverage summary | MEDIUM | LOW | P2 |
| Batch tap BPM | MEDIUM | HIGH | P3 |

**Priority key:**
- P1: Must have for v1.4 milestone
- P2: Should have, add when possible
- P3: Nice to have, future consideration

---

## Implementation Details

### Tap BPM Algorithm

Based on research of tap tempo implementations (bpm-finder.net, taptempo.io, metronomeonline.org):

1. **Minimum taps:** 4 to display a value (3 intervals minimum). Show "Keep tapping..." placeholder until threshold met.
2. **Rolling window:** Last 8 tap intervals. Compute mean interval in milliseconds, convert to BPM: `60000 / meanIntervalMs`.
3. **Outlier rejection:** Discard intervals that deviate more than 2x standard deviation from the rolling mean. This handles accidental double-taps and hesitation pauses.
4. **Stability display:** Show live BPM updating with each tap. Show stability indicator based on standard deviation -- "Stabilizing..." when stddev > 5 BPM, "Stable" with checkmark when stddev <= 5 BPM.
5. **Save threshold:** Enable save button only when stddev <= 5 BPM and minimum 4 taps received. Prevents saving unreliable values.
6. **Inactivity reset:** If no tap for 3 seconds, reset the session. Show "Timed out -- tap again to restart."
7. **UX layout:** Large tap target (full-width button covering lower 40% of sheet). Haptic feedback (`UIImpactFeedbackGenerator.light`) on each tap. Display: large BPM number center, tap count + stability status below, song name + artist at top for context, Save + Cancel buttons.
8. **Accuracy expectation:** Typically within +/-2 BPM with 6-8 consistent taps. This is sufficient for BPM matching with the existing tolerance ranges (+-3, +-7, +-12).

### CachedBPM Model Migration

Current `CachedBPM` fields: `spotifyTrackID`, `trackName`, `artistName`, `bpm: Int?`, `lookupAttempted: Bool`, `lastUpdated: Date`, `danceability: Int?`.

Add: `bpmSource: String` (String for SwiftData compatibility, mapped to enum in app code).

```swift
enum BPMSource: String, Codable {
    case api        // GetSongBPM returned a value
    case manual     // User tapped BPM
    case none       // Lookup attempted, no result (bpm is nil)
}
```

**Migration strategy:** SwiftData lightweight migration. New field with default value. Backfill logic on first launch: iterate cached records, set `.api` where `bpm != nil && lookupAttempted`, set `.none` where `bpm == nil && lookupAttempted`, set `.none` for all others. This runs once.

**Integration points:**
- `BPMCacheService.cache()` must accept `bpmSource` parameter. Default to `.api` for existing call sites (GetSongBPM lookups).
- New `BPMCacheService.cacheManualBPM()` method for tap input that sets `.manual`.
- `BPMCacheService.getSource(forTrackID:)` new query method for badge rendering.

### Sensor Lab Data Points

All data reads from `CadenceService.shared` which is `@Observable`:

| Data Point | Source Property | Display | Needs Exposure |
|------------|----------------|---------|----------------|
| Current SPM | `currentSPM` | Large number, updates live | No -- already public |
| State | `state` | Badge: idle/detecting/active/paused | No -- already public |
| Trend | `trend` | Arrow icon: up/steady/down | No -- already public |
| Permission | `permissionDenied` | Status badge | No -- already public |
| Window duration | `windowDuration` | Slider + value label | YES -- currently `private let` |
| Samples in window | `cadenceWindow.count` | "N samples in window" | YES -- currently private |
| Step count | CMPedometer `numberOfSteps` | Counter | YES -- not exposed |
| Raw cadence | CMPedometer `currentCadence` | SPM before averaging | YES -- not exposed |

Four properties need exposure. Options:
1. **Computed read-only properties** (preferred): `var sampleCount: Int`, `var rawCadence: Double?`, settable `var windowDuration`. Keep `cadenceWindow` array private.
2. **Debug-only struct**: `CadenceService.debugSnapshot` returns a frozen copy of internal state. Cleaner but adds a type.

Recommend option 1 -- simpler, three computed properties plus making `windowDuration` a `var`.

### Zero-BPM Fallback Integration

Current behavior in `RunEngineService.findMatchingTracks(forSPM:)`:
```swift
guard let bpm = bpmMap[track.id] else { return false }
```
Tracks without BPM silently excluded.

New behavior based on `ZeroBPMFallback` setting:

```swift
enum ZeroBPMFallback: String {
    case skip           // Current behavior -- exclude nil-BPM tracks
    case playRegardless // Add nil-BPM tracks to end of match list as filler
}
```

- **Skip**: No change to `findMatchingTracks`. Current `guard let` logic preserved.
- **Play Regardless**: In `selectNextMatch`, after normal matching fails (no BPM-matched tracks left), fall back to tracks with `bpmMap[id] == nil` in random order. These never affect sync quality computation (delta shows 0, sync state shows neutral).

Integration is minimal: one `if` branch in `selectNextMatch` after the existing "pool exhausted" logic.

---

## Competitor Feature Analysis

| Feature | DJ Apps (rekordbox, beaTunes) | Running Music Apps (TrailMix, RockMyRun) | Metronome Apps (Live BPM) | BeatStep v1.4 |
|---------|-------------------------------|------------------------------------------|---------------------------|---------------|
| BPM confidence | Color-coded badges (green/yellow/red) by analysis confidence | Not shown -- BPM is invisible to user | N/A | Color-coded dot: green (API), blue (manual), gray (none) |
| Manual BPM input | Tap tempo + text field | Not available | Tap-only interface | Tap tempo only -- text field is anti-feature |
| Debug/sensor view | Hidden developer menu (Traktor), analysis log (beaTunes) | Not available | Live waveform display | Sensor Lab behind settings toggle |
| Zero-BPM handling | Warning on import, require manual fix before use | Invisible -- unknown tracks silently excluded or included | N/A | Configurable: skip or play regardless, with pre-run visibility |
| Detection interval config | Analysis quality presets | Not configurable | Not applicable | Slider in Sensor Lab (0.5-5.0s), developer-facing |

---

## Sources

- [Live BPM: Tap Tempo & Counter - App Store](https://apps.apple.com/us/app/live-bpm-tap-tempo-counter/id6480474508) -- Reference tap BPM interface
- [Pro Tap Tempo: Accurate BPM Detection Tips](https://metronomeonline.org/blog/pro-tap-tempo-accurate-bpm-detection-tips) -- Algorithm: 8-tap window, outlier filtering, stabilization
- [Tap Tempo - Real-time BPM Detection](https://bpm-finder.net/tool/tap-tempo) -- Minimum 3 taps, stddev-based confidence
- [TapTempo.io](https://taptempo.io/) -- Rolling average, inactivity reset pattern
- [beaTunes](https://www.beatunes.com/en/) -- BPM confidence scoring and metadata quality indicators
- [Automatic BPM and Key Detection (2025)](https://stemsplit.io/blog/bpm-key-detection-feature) -- Confidence scoring for automated BPM analysis
- [Garmin Forums: Cadence drops to zero](https://forums.garmin.com/sports-fitness/running-multisport/f/forerunner-965/370223/running-power-and-cadence-randomly-drop-to-zero-in-the-middle-of-a-run) -- Real-world zero-cadence scenarios
- [Building SwiftUI debugging utilities - Swift by Sundell](https://www.swiftbysundell.com/articles/building-swiftui-debugging-utilities/) -- Debug screen patterns in SwiftUI
- [MBXHub Audio Features](https://mbxhub.com/12sfaq.htm) -- Confidence score 0-1 for mood/BPM estimates, dashboard display
- Codebase analysis: `CadenceService.swift`, `BPMCacheService.swift`, `CachedBPM.swift`, `RunEngineService.swift`, `PlaylistDetailView.swift`, `SettingsView.swift`

---
*Feature research for: BeatStep v1.4 "Under The Hood" -- debug tooling, tap BPM, confidence indicators, zero-BPM fallback*
*Researched: 2026-03-25*
