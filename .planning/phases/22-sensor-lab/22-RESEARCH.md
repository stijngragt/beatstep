# Phase 22: Sensor Lab - Research

**Researched:** 2026-03-25
**Domain:** CoreMotion accelerometer + Swift Charts real-time visualization
**Confidence:** HIGH

## Summary

Phase 22 builds a hidden debug screen ("Sensor Lab") that exposes raw accelerometer data, cadence values, step counts, and algorithm state to developers and power users. The project already uses CoreMotion via CMPedometer in CadenceService for cadence detection. Sensor Lab needs CMMotionManager (different from CMPedometer) for raw accelerometer X/Y/Z data, plus Apple's Swift Charts framework for the real-time waveform chart.

The project targets iOS 17.0 and uses SwiftUI with the @Observable macro pattern. Swift Charts is a first-party Apple framework available since iOS 16, so no third-party charting libraries are needed. The main technical challenges are: (1) throttling accelerometer updates to avoid overwhelming SwiftUI redraws, (2) maintaining a rolling buffer of data points for the waveform, and (3) ensuring the accelerometer stops cleanly when Sensor Lab closes.

**Primary recommendation:** Use CMMotionManager for raw accelerometer data with a configurable update interval, Swift Charts LineMark for the waveform, and @AppStorage for the hidden debug toggle. Keep the service as a standalone @Observable class independent of the existing CadenceService.

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| SLAB-01 | Debug screen accessible via hidden settings toggle | @AppStorage boolean toggle in SettingsView, hidden behind tap-count gesture or conditional visibility |
| SLAB-02 | Sensor Lab displays raw accelerometer output, cadence, step count, algorithm state | CMMotionManager for accelerometer, CadenceService.shared for cadence/state, separate step counter via CMPedometer |
| SLAB-03 | Detection interval configurable from 0.5s to 5s in Sensor Lab | CMMotionManager.accelerometerUpdateInterval is settable at runtime, Slider bound to interval property |
| SLAB-04 | Real-time accelerometer waveform chart in Sensor Lab | Swift Charts LineMark with rolling buffer array, drawingGroup() for Metal-backed rendering |
</phase_requirements>

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| CoreMotion (CMMotionManager) | iOS 17 SDK | Raw accelerometer X/Y/Z data | First-party Apple framework, already have NSMotionUsageDescription in Info.plist |
| Swift Charts | iOS 17 SDK | Real-time waveform line chart | First-party Apple framework, no dependency needed, already available at deployment target |
| SwiftUI @Observable | iOS 17 SDK | Reactive state for sensor data service | Project-wide pattern (CadenceService, SpotifyAuthService all use @Observable) |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| CoreMotion (CMPedometer) | iOS 17 SDK | Step count data | Already used in CadenceService -- reuse for step count display |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Swift Charts | DGCharts (formerly Charts by Daniel Gindi) | Third-party dependency for a debug screen is overkill; Swift Charts is sufficient for a simple waveform |
| CMMotionManager pull | CMMotionManager push (handler queue) | Pull model simpler for variable intervals, but push is standard; use push with configurable interval |

**Installation:**
No additional packages needed. CoreMotion and Charts are system frameworks.

## Architecture Patterns

### Recommended Project Structure
```
BeatStep/
├── Services/
│   └── SensorLabService.swift      # @Observable, CMMotionManager lifecycle
├── Views/
│   └── Settings/
│       ├── SettingsView.swift       # Add hidden toggle (modify existing)
│       └── SensorLabView.swift      # Debug screen UI
├── Models/
│   └── AccelerometerSample.swift    # Lightweight struct for chart data
```

### Pattern 1: Standalone @Observable Service
**What:** SensorLabService wraps CMMotionManager with published properties for acceleration, step count, and configurable interval.
**When to use:** Same singleton pattern as CadenceService -- `static let shared`.
**Example:**
```swift
// Based on project pattern from CadenceService.swift
@Observable
final class SensorLabService {
    static let shared = SensorLabService()

    var accelerationX: Double = 0
    var accelerationY: Double = 0
    var accelerationZ: Double = 0
    var stepCount: Int = 0
    var isRunning: Bool = false
    var detectionInterval: TimeInterval = 1.0  // 0.5 to 5.0

    @ObservationIgnored
    private var motionManager: CMMotionManager?
    @ObservationIgnored
    private var samples: [AccelerometerSample] = []

    private init() {}

    func startAccelerometer() {
        if motionManager == nil { motionManager = CMMotionManager() }
        motionManager?.accelerometerUpdateInterval = detectionInterval
        motionManager?.startAccelerometerUpdates(to: .main) { [weak self] data, _ in
            guard let self, let data else { return }
            self.accelerationX = data.acceleration.x
            self.accelerationY = data.acceleration.y
            self.accelerationZ = data.acceleration.z
            self.appendSample(data)
        }
        isRunning = true
    }

    func stopAccelerometer() {
        motionManager?.stopAccelerometerUpdates()
        motionManager = nil
        isRunning = false
    }
}
```

### Pattern 2: Rolling Buffer for Chart Data
**What:** Fixed-size array of recent samples that automatically evicts old entries, avoiding unbounded memory growth.
**When to use:** For the waveform chart data source.
**Example:**
```swift
struct AccelerometerSample: Identifiable {
    let id = UUID()
    let timestamp: TimeInterval  // relative seconds
    let x: Double
    let y: Double
    let z: Double
    var magnitude: Double { sqrt(x*x + y*y + z*z) }
}

// In SensorLabService:
private let maxSamples = 100

func appendSample(_ data: CMAccelerometerData) {
    let sample = AccelerometerSample(
        timestamp: data.timestamp,
        x: data.acceleration.x,
        y: data.acceleration.y,
        z: data.acceleration.z
    )
    samples.append(sample)
    if samples.count > maxSamples {
        samples.removeFirst(samples.count - maxSamples)
    }
}
```

### Pattern 3: Swift Charts Waveform
**What:** LineMark chart showing recent accelerometer magnitude over time.
**When to use:** For SLAB-04 real-time waveform display.
**Example:**
```swift
import Charts

struct AccelerometerChartView: View {
    let samples: [AccelerometerSample]

    var body: some View {
        Chart(samples) { sample in
            LineMark(
                x: .value("Time", sample.timestamp),
                y: .value("Magnitude", sample.magnitude)
            )
            .foregroundStyle(Color.accent)
        }
        .chartYScale(domain: 0...3)
        .drawingGroup()  // Metal-backed rendering for performance
        .frame(height: 200)
    }
}
```

### Pattern 4: Hidden Debug Toggle
**What:** @AppStorage boolean that shows/hides Sensor Lab navigation link in Settings.
**When to use:** SLAB-01 -- hidden toggle revealed by tapping version text 5 times.
**Example:**
```swift
// In SettingsView -- add to existing file
@AppStorage("sensorLabEnabled") private var sensorLabEnabled = false
@State private var tapCount = 0

// In body, add to Permissions section or after Disconnect:
Section {
    if sensorLabEnabled {
        NavigationLink("Sensor Lab") {
            SensorLabView()
        }
    }
}

// Hidden activation: tap app version text 5 times
Text("BeatStep v1.4")
    .font(.captionText)
    .foregroundStyle(Color.textTertiary)
    .onTapGesture {
        tapCount += 1
        if tapCount >= 5 {
            sensorLabEnabled.toggle()
            tapCount = 0
        }
    }
```

### Pattern 5: Cleanup on Disappear
**What:** Stop accelerometer when view disappears to prevent battery drain.
**When to use:** SLAB-05 (success criterion 5) -- closing Sensor Lab stops accelerometer.
**Example:**
```swift
struct SensorLabView: View {
    var body: some View {
        // ... content ...
        .onDisappear {
            SensorLabService.shared.stopAccelerometer()
        }
    }
}
```

### Anti-Patterns to Avoid
- **Reusing CadenceService for accelerometer data:** CadenceService uses CMPedometer, not CMMotionManager. They are separate APIs. Don't mix them -- create a standalone service.
- **Unbounded sample array:** Without a max size, continuous accelerometer data will consume memory indefinitely. Always cap the rolling buffer.
- **Updating on every accelerometer callback at high frequency:** At 0.5s interval this is fine (2 Hz), but if someone sets it low, ensure chart updates don't stall the main thread. drawingGroup() mitigates this.
- **Forgetting to stop on disappear:** CMMotionManager will keep the accelerometer active and drain battery if not explicitly stopped.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Waveform chart | Custom Canvas/Path drawing | Swift Charts LineMark | Handles axes, scaling, animations automatically |
| Accelerometer access | Raw device sensor APIs | CMMotionManager | Handles calibration, threading, power management |
| Persistent toggle state | UserDefaults wrapper | @AppStorage | Project convention, already used throughout |

**Key insight:** This is a debug screen -- it should be simple, functional, and use standard APIs. No need for custom rendering or elaborate architecture.

## Common Pitfalls

### Pitfall 1: CMMotionManager Must Be Singleton-ish
**What goes wrong:** Creating multiple CMMotionManager instances leads to undefined behavior.
**Why it happens:** Apple docs state only one instance should exist per app.
**How to avoid:** Use the shared singleton pattern (SensorLabService.shared) with lazy init of the manager.
**Warning signs:** Erratic or missing accelerometer data.

### Pitfall 2: Accelerometer Doesn't Work in Simulator
**What goes wrong:** CMMotionManager.isAccelerometerAvailable returns false on simulator.
**Why it happens:** Simulator has no physical accelerometer.
**How to avoid:** Add a check and show "Device Required" message in simulator. Consider mock data for development.
**Warning signs:** Blank/zero data on all fields.

### Pitfall 3: Swift Charts Performance with High-Frequency Updates
**What goes wrong:** Chart becomes sluggish with many data points updating rapidly.
**Why it happens:** Swift Charts recomputes layout on every state change.
**How to avoid:** Use drawingGroup() modifier, cap samples at ~100, and don't update faster than needed (the 0.5s minimum interval helps).
**Warning signs:** Dropped frames, UI lag when chart is visible.

### Pitfall 4: Detection Interval Change Requires Restart
**What goes wrong:** Changing accelerometerUpdateInterval while updates are active may not take effect.
**Why it happens:** CMMotionManager reads interval at start time.
**How to avoid:** Stop and restart accelerometer updates when interval changes.
**Warning signs:** Interval slider has no visible effect on update rate.

### Pitfall 5: Thread Safety with Main Queue Updates
**What goes wrong:** UI updates from background queue cause crashes or visual glitches.
**Why it happens:** CMMotionManager handler runs on the queue you specify.
**How to avoid:** Use OperationQueue.main for the handler queue parameter, matching CadenceService's DispatchQueue.main.async pattern.
**Warning signs:** Purple runtime warnings about publishing changes from background threads.

## Code Examples

### Complete SensorLabView Layout
```swift
struct SensorLabView: View {
    private var service: SensorLabService { .shared }
    private var cadenceService: CadenceService { .shared }

    var body: some View {
        List {
            Section("Accelerometer") {
                LabeledContent("X", value: String(format: "%.4f g", service.accelerationX))
                LabeledContent("Y", value: String(format: "%.4f g", service.accelerationY))
                LabeledContent("Z", value: String(format: "%.4f g", service.accelerationZ))
            }

            Section("Cadence") {
                LabeledContent("SPM", value: "\(cadenceService.currentSPM)")
                LabeledContent("State", value: "\(cadenceService.state)")
                LabeledContent("Steps", value: "\(service.stepCount)")
            }

            Section("Waveform") {
                AccelerometerChartView(samples: service.samples)
                    .listRowInsets(EdgeInsets())
            }

            Section("Detection Interval") {
                VStack {
                    Slider(value: Binding(
                        get: { service.detectionInterval },
                        set: { service.updateInterval($0) }
                    ), in: 0.5...5.0, step: 0.5)
                    Text(String(format: "%.1fs", service.detectionInterval))
                        .font(.captionText)
                        .foregroundStyle(Color.textSecondary)
                }
            }
        }
        .navigationTitle("Sensor Lab")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            service.startAccelerometer()
        }
        .onDisappear {
            service.stopAccelerometer()
        }
    }
}
```

### Interval Update with Restart
```swift
// In SensorLabService
func updateInterval(_ newInterval: TimeInterval) {
    detectionInterval = newInterval
    if isRunning {
        stopAccelerometer()
        startAccelerometer()
    }
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Third-party Charts (DGCharts) | Swift Charts (first-party) | iOS 16 / WWDC 2022 | No dependency needed for charting |
| ObservableObject + @Published | @Observable macro | iOS 17 / WWDC 2023 | Project already uses this pattern |
| CMDeviceMotion (sensor fusion) | CMAccelerometerData (raw) | N/A | For debug purposes raw accelerometer data is appropriate |

## Open Questions

1. **Multi-axis vs magnitude for waveform**
   - What we know: Accelerometer provides X, Y, Z independently
   - What's unclear: Should the waveform show all three axes (three lines) or just the combined magnitude?
   - Recommendation: Show magnitude as default single line. Simpler, still diagnostic. Three-axis can be a future enhancement.

2. **Step count source**
   - What we know: CadenceService uses CMPedometer for cadence. CMPedometer also provides numberOfSteps.
   - What's unclear: Should Sensor Lab start its own CMPedometer instance or read from CadenceService?
   - Recommendation: Read CadenceService.shared state when a run is active. For standalone Sensor Lab testing (no run active), start a local CMPedometer in SensorLabService.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | XCTest (project standard) |
| Config file | BeatStepTests target in Xcode project |
| Quick run command | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BeatStepTests/SensorLabServiceTests` |
| Full suite command | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16'` |

### Phase Requirements to Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| SLAB-01 | Hidden toggle persists via @AppStorage | unit | `xcodebuild test ... -only-testing:BeatStepTests/SensorLabServiceTests/testTogglePersistence` | No -- Wave 0 |
| SLAB-02 | Service exposes acceleration, cadence, step count, state | unit | `xcodebuild test ... -only-testing:BeatStepTests/SensorLabServiceTests/testServiceProperties` | No -- Wave 0 |
| SLAB-03 | Interval update triggers stop+restart | unit | `xcodebuild test ... -only-testing:BeatStepTests/SensorLabServiceTests/testIntervalUpdate` | No -- Wave 0 |
| SLAB-04 | Chart data buffer caps at maxSamples | unit | `xcodebuild test ... -only-testing:BeatStepTests/SensorLabServiceTests/testBufferCap` | No -- Wave 0 |

### Sampling Rate
- **Per task commit:** Quick run command for SensorLabServiceTests
- **Per wave merge:** Full test suite
- **Phase gate:** Full suite green before verification

### Wave 0 Gaps
- [ ] `BeatStepTests/SensorLabServiceTests.swift` -- covers SLAB-01 through SLAB-04 service logic
- [ ] Note: Accelerometer hardware tests are manual-only (simulator has no accelerometer). Unit tests should cover buffer logic, interval management, and state transitions using mock data.

## Sources

### Primary (HIGH confidence)
- Apple CoreMotion documentation -- CMMotionManager API, accelerometerUpdateInterval
- Apple Swift Charts documentation -- LineMark, drawingGroup
- Project source: CadenceService.swift -- existing CoreMotion usage pattern
- Project source: SettingsView.swift -- existing @AppStorage and navigation pattern
- Project source: DesignTokens.swift -- color/font/spacing tokens
- Project source: Info.plist -- NSMotionUsageDescription already present

### Secondary (MEDIUM confidence)
- Apple Developer Forums -- Swift Charts real-time update performance considerations
- createwithswift.com -- CMMotionManager SwiftUI integration patterns
- advancedswift.com -- Motion data access patterns in Swift

### Tertiary (LOW confidence)
- None

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- all first-party Apple frameworks, already in use or available at iOS 17 target
- Architecture: HIGH -- follows established project patterns (@Observable singleton, @AppStorage, NavigationStack)
- Pitfalls: HIGH -- well-documented CoreMotion gotchas, verified against Apple docs

**Research date:** 2026-03-25
**Valid until:** 2026-04-25 (stable -- all first-party frameworks, unlikely to change)
