# Stack Research

**Domain:** iOS debug tooling, manual BPM input, confidence tracking, fallback behavior
**Researched:** 2026-03-25
**Confidence:** HIGH

---

## Existing Stack (Validated -- Do Not Re-Research)

| Technology | Status |
|------------|--------|
| Swift 6 / SwiftUI + `@Observable` | Working |
| CoreMotion (CMPedometer) via CadenceService | Working |
| Spotify Web API (PKCE) via SpotifyPlayerService | Working |
| GetSongBPM API via Cloudflare Worker | Working |
| SwiftData (BPM cache) | Working |
| DesignTokens.swift (Color, Font, Spacing, Radius, ComponentSize) | Working |
| RunEngineService (cadence monitor, song-end monitor, BPM matching, ramp state machine) | Working |
| iOS 17.0 deployment target | Confirmed |

---

## v1.4 Stack Additions: Under The Hood

v1.4 requires **zero new external dependencies**. Every capability needed is available in CoreMotion and SwiftUI APIs already linked in the project.

### Core Technologies (v1.4)

| Technology | API | iOS Version | Purpose | Why This |
|------------|-----|-------------|---------|----------|
| CMMotionManager | `startAccelerometerUpdates(to:withHandler:)` | 4.0+ | Raw accelerometer x/y/z data stream for Sensor Lab waveform | Same CoreMotion framework already imported. CMPedometer gives processed steps; CMMotionManager gives raw accelerometer/gyro. Only way to expose raw sensor signal. |
| CMPedometer polling mode | `queryPedometerData(from:to:withHandler:)` | 8.0+ | Configurable detection interval for desk testing (0.5-1.0s) | Current `startUpdates(from:)` has system-controlled delivery frequency (~1-5s). `queryPedometerData` on a repeating Timer gives true configurable sub-second polling. Only way to get faster cadence updates. |
| SwiftUI Charts | `LineMark` + `Chart` | 16.0+ | Live accelerometer waveform visualization in Sensor Lab | Built-in since iOS 16. `LineMark` with a rolling window array gives a real-time waveform chart with axes, no custom drawing. |
| UIImpactFeedbackGenerator | `.impactOccurred()` | 10.0+ | Haptic confirmation on each BPM tap input | Already available via UIKit. One-line haptic. Confirms tap registration, helps user maintain rhythm accuracy. |
| SwiftData lightweight migration | Automatic | 17.0+ | Add `confidenceSource: String?` optional field to CachedBPM model | Adding an optional property with implicit nil default triggers automatic lightweight migration. Zero migration code needed -- no VersionedSchema, no SchemaMigrationPlan. |

### Supporting Patterns (no libraries)

| Pattern | Implementation | Purpose | Detail |
|---------|---------------|---------|--------|
| Tap BPM calculation | `Date.timeIntervalSince(_:)` arithmetic | Compute BPM from inter-tap intervals | Collect last N tap timestamps, average intervals, BPM = 60.0 / avgInterval. Discard outliers beyond 2x median. Minimum 4 taps for reliable result. ~15 lines of code total. |
| BPM confidence enum | `BPMConfidence: String, CaseIterable` | Type-safe confidence levels | `.verified` (exact API match), `.approximate` (fuzzy API match), `.manual` (user tap). Stored as raw String in SwiftData. |
| Zero-BPM fallback enum | `ZeroBPMFallback: String, CaseIterable` | Configurable behavior for tracks without BPM | `.skip` (current behavior), `.playRegardless` (include in pool), `.prompt` (surface UI). @AppStorage persistence -- same pattern as TempoMode. |
| Debug mode toggle | `@AppStorage("debugModeEnabled")` | Gate Sensor Lab screen behind Settings | Single boolean. Sensor Lab appears in Settings navigation when enabled. Ships in release builds -- not `#if DEBUG`. |
| Singleton CMMotionManager | `SensorLabService.shared` | One motion manager per app | Apple docs: "An app should create only a single instance of CMMotionManager." CadenceService owns CMPedometer (separate). Both run simultaneously without conflict. |

---

## Critical Implementation Details

### CMMotionManager vs CMPedometer -- Coexistence

These are independent CoreMotion subsystems. Both can run concurrently:
- **CMPedometer** (CadenceService) -- processes steps from the motion coprocessor, battery-efficient
- **CMMotionManager** (SensorLabService) -- raw accelerometer at configurable Hz, higher battery cost

SensorLabService should start/stop CMMotionManager only when the Sensor Lab screen is visible. Do NOT leave it running in the background.

```swift
// SensorLabService -- raw accelerometer at 50Hz
motionManager.accelerometerUpdateInterval = 1.0 / 50.0
motionManager.startAccelerometerUpdates(to: .main) { data, error in
    guard let data = data else { return }
    // data.acceleration.x, .y, .z -- G-forces
}
```

### Configurable Cadence Interval -- Polling Approach

`CMPedometer.startUpdates(from:)` does NOT accept an interval parameter. The system decides delivery frequency (typically every 1-5 seconds). For desk testing with sub-second updates:

```swift
// Poll pedometer data at configurable interval
private var pollingTimer: Timer?

func startDebugPolling(interval: TimeInterval) {
    let startDate = Date()
    pollingTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
        self.pedometer.queryPedometerData(from: startDate, to: Date()) { data, error in
            guard let data = data else { return }
            // Process step count delta since last query
        }
    }
}
```

The debug interval only affects the Sensor Lab display frequency. Production CadenceService remains unchanged -- it continues using `startUpdates(from:)` for battery-efficient detection.

### CachedBPM Model Change

Current model has 7 properties. Add one optional property:

```swift
@Model
final class CachedBPM {
    // ... existing properties unchanged ...
    var confidenceSource: String?  // "verified", "approximate", "manual"
}
```

This is a **lightweight migration**. SwiftData automatically handles adding optional properties with nil defaults. No VersionedSchema needed. No migration plan needed. The field just appears as nil on existing records.

### RunEngineService Zero-BPM Fallback Integration

Current `selectNextMatch(forSPM:)` filters tracks by `bpmMap[track.id]`. Tracks without BPM in the map are excluded. For fallback:

```swift
// In selectNextMatch, after existing matching logic:
if matches.isEmpty {
    switch ZeroBPMFallback.saved {
    case .skip:
        return nil  // Current behavior
    case .playRegardless:
        // Include tracks without BPM data in the pool
        let noBPMTracks = playlistTracks.filter { bpmMap[$0.id] == nil }
        return noBPMTracks.filter { !playedTrackIDs.contains($0.id) }.randomElement()
    case .prompt:
        // Set flag for UI to display prompt
        zeroBPMPromptNeeded = true
        return nil
    }
}
```

---

## Integration Points Summary

| Existing Code | Change | Risk |
|---------------|--------|------|
| CachedBPM model | Add `confidenceSource: String?` | LOW -- lightweight migration, additive |
| BPMCacheService | Add `cacheWithConfidence()`, `getConfidence()` | LOW -- additive methods |
| GetSongBPMService | Set confidence to `verified` or `approximate` based on match quality | LOW -- adding parameter to existing call |
| CadenceService | No changes to production code. Debug polling is a separate code path in SensorLabService. | NONE |
| RunEngineService | Add `ZeroBPMFallback` check in `selectNextMatch()` | MEDIUM -- core matching logic touched |
| SettingsView | Add debug mode toggle, zero-BPM fallback picker | LOW -- additive UI |
| PlaylistDetailView TrackRow | Show confidence badge color next to BPM | LOW -- visual-only change |
| New: SensorLabService | New singleton owning CMMotionManager | LOW -- isolated new service |
| New: SensorLabView | New debug screen (Charts waveform, step data, interval slider) | LOW -- new view |
| New: TapBPMView | New sheet for tap-to-BPM input | LOW -- new view |

---

## What NOT to Add

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| AudioKit / audio libraries | Tap BPM is timestamp math, not audio analysis. AudioKit is 50MB+ for something that takes 15 lines. | `Date.timeIntervalSince(_:)` |
| DGCharts / third-party charting | SwiftUI Charts is built-in, maintained by Apple, sufficient for a debug waveform. | `import Charts` + `LineMark` |
| Combine for sensor streams | Codebase uses @Observable exclusively. Introducing Combine creates two reactive paradigms. | @Observable properties on SensorLabService |
| CoreHaptics for tap feedback | Complex API for custom haptic patterns. Single discrete tap needs one line. | `UIImpactFeedbackGenerator(.medium).impactOccurred()` |
| os.signpost / MetricKit | Overkill -- Sensor Lab is a visual debug screen for the user, not performance profiling for developers. | @Observable properties displayed in SwiftUI views |
| SwiftData VersionedSchema | Not needed for adding optional properties. Would add unnecessary boilerplate. | Just add the optional field. Lightweight migration handles it. |
| Separate SwiftData model for confidence | Over-engineering. Confidence is a property of BPM data, not a separate entity. | String field on existing CachedBPM model |
| `#if DEBUG` for Sensor Lab | Users need Sensor Lab in release builds for real-device desk testing. Compiler flags strip code from release. | `@AppStorage` boolean toggle in Settings |
| CMSensorRecorder | Designed for background batch recording (up to 12hrs), not real-time display. | CMMotionManager for live data |

---

## Alternatives Considered

| Recommended | Alternative | When to Use Alternative |
|-------------|-------------|-------------------------|
| CMMotionManager for raw accel | CMDeviceMotion (sensor fusion) | If you need attitude/rotation-rate/gravity-separated acceleration. For raw waveform display, plain accelerometer is simpler and sufficient. |
| Timer + queryPedometerData for configurable interval | Modifying CadenceService.startUpdates | Never -- startUpdates has no interval parameter. Modifying CadenceService risks breaking production detection. Keep debug path separate. |
| String field on CachedBPM | Enum stored as Int | String is more readable in debug/database inspection. Performance difference is negligible for a BPM cache. |
| @AppStorage for fallback preference | SwiftData settings model | Only if settings become complex enough to warrant a dedicated model. For a single enum preference, @AppStorage is simpler. |
| SwiftUI Charts LineMark | Custom Canvas drawing | Only if Charts performance is insufficient at 50Hz. Start with Charts, optimize to Canvas if frame drops observed. |

---

## Version Compatibility

| API | Minimum iOS | BeatStep Target (17.0) | Status |
|-----|-------------|------------------------|--------|
| CMMotionManager | 4.0 | 17.0 | Available |
| CMPedometer.queryPedometerData | 8.0 | 17.0 | Available |
| SwiftUI Charts (LineMark) | 16.0 | 17.0 | Available |
| UIImpactFeedbackGenerator | 10.0 | 17.0 | Available |
| SwiftData lightweight migration | 17.0 | 17.0 | Available |
| @AppStorage | 14.0 | 17.0 | Available |
| @Observable | 17.0 | 17.0 | Already in use |

No compatibility concerns. Every API needed predates or matches the iOS 17.0 deployment target.

---

## New Files to Create

| File | Type | Purpose |
|------|------|---------|
| `SensorLabService.swift` | Service (@Observable) | CMMotionManager singleton, raw accelerometer data, debug cadence polling |
| `SensorLabView.swift` | View | Debug screen with accelerometer waveform (Charts), step count, cadence, interval slider |
| `TapBPMView.swift` | View | Tap-to-BPM input sheet with tap counter, live BPM display, save action |
| `BPMConfidence.swift` | Model (enum) | `verified` / `approximate` / `manual` confidence levels |
| `ZeroBPMFallback.swift` | Model (enum) | `skip` / `playRegardless` / `prompt` with @AppStorage persistence |

---

## Key Takeaway

v1.4 is a zero-dependency milestone. CMMotionManager (already in CoreMotion) provides raw accelerometer data. CMPedometer polling provides configurable intervals. SwiftUI Charts provides waveform visualization. Date arithmetic provides tap BPM. SwiftData lightweight migration provides confidence tracking. UserDefaults provides fallback persistence. The work is wiring these existing APIs into new services and views, not adding packages.

---

## Sources

- [CMMotionManager | Apple Developer Documentation](https://developer.apple.com/documentation/coremotion/cmmotionmanager) -- accelerometer API, update intervals, singleton requirement (HIGH confidence)
- [Core Motion | Apple Developer Documentation](https://developer.apple.com/documentation/coremotion/) -- framework overview, CMPedometer vs CMMotionManager independence (HIGH confidence)
- [Hacking with Swift -- Core Motion accelerometer](https://www.hackingwithswift.com/example-code/system/how-to-use-core-motion-to-read-accelerometer-data) -- push vs pull patterns (HIGH confidence)
- [Using Core Motion within SwiftUI](https://www.createwithswift.com/using-core-motion-within-a-swiftui-application/) -- SwiftUI integration patterns (HIGH confidence)
- [SwiftData lightweight vs complex migrations](https://www.hackingwithswift.com/quick-start/swiftdata/lightweight-vs-complex-migrations) -- optional property = automatic migration (HIGH confidence)
- [Apple Developer Forums -- SwiftData migration](https://developer.apple.com/forums/thread/738812) -- community confirmation of lightweight migration behavior (MEDIUM confidence)
- Codebase inspection: CadenceService.swift (CMPedometer usage, startUpdates pattern), CachedBPM.swift (current model schema), BPMCacheService.swift (cache/fetch patterns), RunEngineService.swift (selectNextMatch logic, bpmMap filtering), SettingsView.swift (existing toggle/picker patterns), PlaylistDetailView.swift (TrackRow BPM badge display)

---
*Stack research for: BeatStep v1.4 Under The Hood -- debug tooling, tap BPM, confidence, fallback*
*Researched: 2026-03-25*
