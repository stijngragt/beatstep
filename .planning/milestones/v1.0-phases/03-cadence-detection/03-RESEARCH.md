# Phase 3: Cadence Detection - Research

**Researched:** 2026-03-20
**Domain:** CoreMotion / CMPedometer, SwiftUI run UI, real-time signal smoothing
**Confidence:** HIGH

## Summary

Phase 3 introduces real-time cadence detection via CMPedometer, a run session lifecycle (start/stop), and a dedicated run screen. CMPedometer is a stable, mature iOS API that provides `currentCadence` in steps per second -- multiply by 60 for SPM. The API delivers updates every 1-3 seconds while the user is moving, which is frequent enough for a rolling average with responsive smoothing.

BeatStep already has the `audio` UIBackgroundMode active (for Spotify playback), which means the app process stays alive in the background during a run. CMPedometer `startUpdates` continues delivering to an active process, so cadence detection will work in the background without any additional background mode configuration. This is a significant advantage -- no hacks needed.

The phase is self-contained: a new `CadenceService` singleton following established patterns, a `RunView` with dark high-contrast UI, and integration into the existing ContentView navigation. No external dependencies needed beyond CoreMotion (system framework).

**Primary recommendation:** Use CMPedometer.startUpdates(from:withHandler:) with a CadenceService singleton that maintains a rolling window of raw cadence samples, computes smoothed SPM, and derives trend direction. The run screen is a full-screen dark view with the mini-player embedded at the bottom.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- Explicit "Start Run" button to begin cadence detection -- no auto-detect from motion
- Dedicated run screen accessible from a new tab or prominent entry point on the main screen
- Pre-run flow: user selects playlist from library first, then navigates to run screen showing selected playlist context, then taps "Start Run"
- Explicit "Stop Run" button to end session -- clean return to normal app, no summary screen
- Run session is a simple start/stop concept -- no pause/resume, no stats persistence
- Cadence (SPM) number is the hero element -- large, front and center on the run screen
- Trend indicator uses arrow icons: up arrow (speeding up), horizontal (steady), down arrow (slowing down)
- Dark background with bright text for outdoor visibility and glanceability while running
- Mini-player remains visible at bottom of run screen for track info and playback controls
- Screen stays awake (prevent auto-lock) during an active run via `UIApplication.shared.isIdleTimerDisabled`
- Rolling average over ~5 seconds for balanced responsiveness
- Brief "Detecting..." settling period (~5 seconds) at run start before showing cadence numbers
- Trend indicator also uses sustained-change smoothing -- only shows "speeding up" / "slowing down" after cadence shifts consistently for ~5+ seconds, prevents arrow flickering
- When runner stops (no steps for ~5 seconds), show "Paused" state instead of cadence dropping to 0; cadence resumes when movement resumes
- Motion/pedometer permission requested on first "Start Run" tap
- If permission denied: block run start, show clear explanation, offer button to open iOS Settings
- Cadence detection continues in background via CMPedometer
- Motion permission only -- no location permission needed

### Claude's Discretion
- Exact run screen layout and typography sizing
- Tab bar design or navigation pattern for accessing the run screen
- "Detecting..." animation or indicator design
- "Paused" state visual design
- Error handling for CMPedometer failures
- Run screen color palette beyond "dark background, bright text"

### Deferred Ideas (OUT OF SCOPE)
None -- discussion stayed within phase scope
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| CAD-01 | App detects running cadence in real-time via CMPedometer | CMPedometer.startUpdates delivers currentCadence (NSNumber?, steps/sec) every 1-3 seconds; multiply by 60 for SPM. isCadenceAvailable() for device check. |
| CAD-02 | Cadence is smoothed with a rolling average to prevent jarring song switches | Rolling window of ~5 seconds of samples, compute weighted or simple average. Trend detection via sustained delta over 5+ seconds. |
| CAD-03 | Current cadence (SPM) is displayed during a run with trend indicator | RunView with dark UI, hero SPM display, arrow-based trend indicator, embedded MiniPlayerView |
</phase_requirements>

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| CoreMotion (CMPedometer) | System | Cadence detection via device motion coprocessor | Only Apple-supported API for step cadence; uses M-series coprocessor (low power) |
| SwiftUI | System (iOS 17+) | Run screen UI | Project standard; all existing views are SwiftUI |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| UIKit (UIApplication) | System | `isIdleTimerDisabled` to prevent screen lock during run | Set true on run start, false on run stop |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| CMPedometer | Raw CMMotionManager accelerometer | Much more complex, requires FFT/peak detection, CMPedometer does this for free |
| CMPedometer | HealthKit step queries | Not real-time, designed for historical data, cadence not available |

**Installation:**
No additional packages needed. CoreMotion is a system framework. Add to project.yml:
```yaml
- sdk: CoreMotion.framework
```

## Architecture Patterns

### Recommended Project Structure
```
BeatStep/
├── Services/
│   └── CadenceService.swift          # CMPedometer wrapper, smoothing, trend
├── Models/
│   └── RunSession.swift              # Run state enum, cadence data model
├── Views/
│   └── Run/
│       ├── RunView.swift             # Main run screen (dark, glanceable)
│       ├── CadenceDisplayView.swift  # Hero SPM number + trend arrow
│       └── RunControlsView.swift     # Start/Stop button
```

### Pattern 1: CadenceService Singleton
**What:** `@Observable` singleton following established `.shared` pattern (like SpotifyPlayerService, BPMCacheService)
**When to use:** All cadence-related state and logic
**Example:**
```swift
// Follows project patterns: @Observable, static shared, private init
import CoreMotion

@Observable
final class CadenceService {
    static let shared = CadenceService()

    // MARK: - Observable State
    var currentSPM: Int = 0
    var trend: CadenceTrend = .steady
    var state: CadenceState = .idle  // .idle, .detecting, .active, .paused
    var permissionDenied = false

    // MARK: - Private
    private let pedometer = CMPedometer()
    private var cadenceWindow: [(timestamp: Date, cadence: Double)] = []
    private let windowDuration: TimeInterval = 5.0
    private var lastStepTime: Date?
    private var trendHistory: [Double] = []

    private init() {}

    // MARK: - Lifecycle
    func startDetecting() {
        guard CMPedometer.isCadenceAvailable() else { return }
        state = .detecting

        pedometer.startUpdates(from: Date()) { [weak self] data, error in
            guard let self, let data else { return }
            DispatchQueue.main.async {
                self.processPedometerData(data)
            }
        }
    }

    func stopDetecting() {
        pedometer.stopUpdates()
        cadenceWindow.removeAll()
        trendHistory.removeAll()
        state = .idle
        currentSPM = 0
        trend = .steady
    }

    // MARK: - Processing
    private func processPedometerData(_ data: CMPedometerData) {
        let now = Date()
        lastStepTime = now

        if let cadence = data.currentCadence?.doubleValue {
            let spm = cadence * 60.0  // Convert steps/sec to steps/min
            cadenceWindow.append((timestamp: now, cadence: spm))
        }

        // Prune old samples outside window
        cadenceWindow.removeAll { now.timeIntervalSince($0.timestamp) > windowDuration }

        // Calculate smoothed SPM
        guard !cadenceWindow.isEmpty else { return }
        let avgSPM = cadenceWindow.map(\.cadence).reduce(0, +) / Double(cadenceWindow.count)
        currentSPM = Int(avgSPM.rounded())

        // Transition from detecting to active after settling period
        if state == .detecting {
            state = .active
        }

        updateTrend(currentAvg: avgSPM)
    }
}
```

### Pattern 2: Run State Machine
**What:** Simple enum-driven state for the run session
**When to use:** Controlling UI display and CadenceService behavior
```swift
enum CadenceState {
    case idle       // Not running, run screen in pre-run mode
    case detecting  // First ~5 seconds, showing "Detecting..."
    case active     // Cadence locked, showing SPM + trend
    case paused     // No steps detected for ~5 seconds
}

enum CadenceTrend {
    case speedingUp
    case steady
    case slowingDown
}
```

### Pattern 3: Permission Flow
**What:** Request motion permission on first "Start Run" tap, handle denial gracefully
**When to use:** Before calling `pedometer.startUpdates`
```swift
// CMPedometer permission is requested implicitly on first startUpdates call.
// Check authorization status via CMMotionActivityManager.authorizationStatus()
// Note: CMPedometer itself doesn't have a standalone authorization check --
// the system prompts on first use. Handle the error callback for denial.

func requestPermissionAndStart() {
    // CMPedometer.authorizationStatus() available iOS 11+
    let status = CMPedometer.authorizationStatus()
    switch status {
    case .authorized:
        startDetecting()
    case .notDetermined:
        // Will trigger system prompt
        startDetecting()
    case .denied, .restricted:
        permissionDenied = true
    @unknown default:
        startDetecting()
    }
}
```

### Pattern 4: Navigation to Run Screen
**What:** Entry point from playlist selection to run screen
**When to use:** Pre-run flow -- user picks playlist, then enters run mode
```swift
// Option: NavigationLink from PlaylistDetailView to RunView
// RunView receives the selected playlist as context
NavigationLink("Run with this Playlist") {
    RunView(playlist: playlist)
}
```

### Anti-Patterns to Avoid
- **Raw accelerometer for cadence:** CMPedometer does the signal processing on the motion coprocessor. Never hand-roll step detection from CMMotionManager.
- **Timer-based polling:** Do NOT use a Timer to poll CMPedometer. Use `startUpdates(from:withHandler:)` which pushes data.
- **Main thread pedometer init:** The handler runs on an internal queue. Always dispatch UI updates to `DispatchQueue.main.async`.
- **Forgetting stopUpdates:** Always call `pedometer.stopUpdates()` when the run ends. Leaking pedometer updates drains battery.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Step detection | Accelerometer FFT/peak detection | CMPedometer | Motion coprocessor does this at near-zero CPU cost |
| Cadence calculation | Custom step-interval math | CMPedometerData.currentCadence | Apple provides it directly, already filtered |
| Screen keep-awake | Custom timer/notification hack | UIApplication.shared.isIdleTimerDisabled | One-liner system API |
| Motion permission | Custom permission manager | CMPedometer.authorizationStatus() + system prompt | System handles the dialog |

**Key insight:** CMPedometer abstracts all the hard signal processing. The service layer is thin -- mainly smoothing/trend logic on top of Apple's cadence values.

## Common Pitfalls

### Pitfall 1: currentCadence is nil
**What goes wrong:** CMPedometerData.currentCadence is an optional NSNumber. It can be nil even when steps are detected (e.g., during very slow walking, or the first few updates).
**Why it happens:** The motion coprocessor needs a few steps to calculate cadence. Historical queries always return nil for currentCadence.
**How to avoid:** Guard against nil gracefully. During the "Detecting..." phase, expect nils. Only update the rolling window when cadence is non-nil. Can fall back to calculating cadence from numberOfSteps delta / time delta.
**Warning signs:** SPM showing 0 intermittently during active running.

### Pitfall 2: Cadence units are steps per SECOND
**What goes wrong:** Displaying raw currentCadence value (e.g., "2.8") instead of SPM (168).
**Why it happens:** Apple documents cadence as steps per second, not per minute.
**How to avoid:** Always multiply by 60: `let spm = cadence.doubleValue * 60.0`
**Warning signs:** Cadence values in single digits.

### Pitfall 3: Handler not on main thread
**What goes wrong:** Updating @Observable properties from the pedometer handler causes threading issues.
**Why it happens:** CMPedometer delivers updates on an internal operation queue, not the main thread.
**How to avoid:** Wrap all state mutations in `DispatchQueue.main.async { }` or use `@MainActor`.
**Warning signs:** Purple runtime warnings in Xcode, inconsistent UI updates.

### Pitfall 4: Not stopping updates on run end
**What goes wrong:** Battery drain, potential crashes if service is deallocated.
**Why it happens:** Forgetting to call `pedometer.stopUpdates()`.
**How to avoid:** Always pair start/stop. Call stop in `stopDetecting()` and also in deinit/onDisappear as safety net.
**Warning signs:** Elevated battery usage in Instruments.

### Pitfall 5: Idle timer not reset on run end
**What goes wrong:** Screen never auto-locks again after a run.
**Why it happens:** Setting `isIdleTimerDisabled = true` without resetting to `false`.
**How to avoid:** Reset in `stopDetecting()` and in RunView.onDisappear.
**Warning signs:** User's phone screen stays on indefinitely after closing run screen.

### Pitfall 6: Background cadence stops without audio background mode
**What goes wrong:** CMPedometer stops delivering updates when app backgrounds.
**Why it happens:** iOS suspends apps without active background modes.
**How to avoid:** BeatStep already has `audio` UIBackgroundMode for Spotify. As long as audio is playing, the process stays alive and CMPedometer continues. No additional background mode needed.
**Warning signs:** Cadence freezes when phone is pocketed (only if audio somehow stops).

## Code Examples

### CMPedometer Availability Check
```swift
// Check before showing run-related UI
func isCadenceSupported() -> Bool {
    return CMPedometer.isStepCountingAvailable() && CMPedometer.isCadenceAvailable()
}
```

### Rolling Average Smoothing
```swift
// Simple rolling average over a time window
private func computeSmoothedSPM() -> Double? {
    let now = Date()
    // Keep only samples within window
    cadenceWindow.removeAll { now.timeIntervalSince($0.timestamp) > windowDuration }
    guard !cadenceWindow.isEmpty else { return nil }
    return cadenceWindow.map(\.cadence).reduce(0, +) / Double(cadenceWindow.count)
}
```

### Trend Detection with Sustained Change
```swift
// Only change trend after sustained shift over ~5 seconds
private func updateTrend(currentAvg: Double) {
    trendHistory.append(currentAvg)

    // Keep last N samples (roughly 5 seconds at ~1 update/sec)
    let maxSamples = 5
    if trendHistory.count > maxSamples {
        trendHistory.removeFirst(trendHistory.count - maxSamples)
    }

    guard trendHistory.count >= 3 else {
        trend = .steady
        return
    }

    let first = trendHistory.first!
    let last = trendHistory.last!
    let delta = last - first
    let threshold: Double = 5.0  // SPM change threshold

    if delta > threshold {
        trend = .speedingUp
    } else if delta < -threshold {
        trend = .slowingDown
    } else {
        trend = .steady
    }
}
```

### Paused State Detection
```swift
// Timer-based check for no steps received
private func startInactivityMonitor() {
    // Check every 2 seconds if lastStepTime is stale
    inactivityTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
        guard let self else { return }
        if let last = self.lastStepTime,
           Date().timeIntervalSince(last) > 5.0,
           self.state == .active {
            DispatchQueue.main.async {
                self.state = .paused
            }
        }
    }
}
```

### Dark Run Screen Layout
```swift
struct RunView: View {
    let playlist: SpotifyPlaylist
    private var cadenceService: CadenceService { .shared }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                // Hero cadence display
                switch cadenceService.state {
                case .idle:
                    startRunPrompt
                case .detecting:
                    detectingView
                case .active:
                    cadenceDisplay
                case .paused:
                    pausedView
                }

                Spacer()

                // Stop button (when running)
                if cadenceService.state != .idle {
                    stopButton
                }
            }
        }
        .preferredColorScheme(.dark)
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
            cadenceService.stopDetecting()
        }
    }
}
```

### Info.plist Configuration (project.yml)
```yaml
# Add to BeatStep target info properties:
NSMotionUsageDescription: "BeatStep needs motion access to detect your running cadence and match music to your pace."

# Add to dependencies:
- sdk: CoreMotion.framework
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| CMStepCounter (deprecated) | CMPedometer | iOS 8 (2014) | CMPedometer is the only supported API |
| CMPedometer without cadence | CMPedometer with currentCadence | iOS 9 (2015) | Cadence available without raw accelerometer processing |
| UIApplication.isIdleTimerDisabled | Same API, still current | Stable | No changes needed |
| CMMotionActivityManager auth | CMPedometer.authorizationStatus() | iOS 11 (2017) | Direct auth check on CMPedometer class |

**Deprecated/outdated:**
- CMStepCounter: Deprecated since iOS 8. Use CMPedometer.
- Spotify Audio Features for tempo: Deprecated Nov 2024. Already handled in Phase 2.

## Open Questions

1. **CMPedometer update frequency under load**
   - What we know: Documentation says "every few seconds" during movement. Community reports 1-3 second intervals.
   - What's unclear: Exact frequency is device-dependent and undocumented.
   - Recommendation: Design the rolling window to be time-based (5 seconds), not sample-count-based. This handles variable update rates gracefully.

2. **Fallback when currentCadence is nil but numberOfSteps changes**
   - What we know: currentCadence can be nil even when steps are counted.
   - What's unclear: How frequently this happens during running (vs walking).
   - Recommendation: Implement a fallback: compute cadence from `(currentSteps - previousSteps) / timeDelta * 60` when currentCadence is nil. This provides a backup signal.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | XCTest (built-in, iOS 17+) |
| Config file | project.yml BeatStepTests target |
| Quick run command | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BeatStepTests/CadenceServiceTests` |
| Full suite command | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16'` |

### Phase Requirements to Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| CAD-01 | CadenceService starts/stops CMPedometer, processes data | unit (mocked pedometer) | `xcodebuild test ... -only-testing:BeatStepTests/CadenceServiceTests` | No -- Wave 0 |
| CAD-02 | Rolling average smoothing produces stable SPM, trend detection | unit (pure logic) | `xcodebuild test ... -only-testing:BeatStepTests/CadenceServiceTests/testSmoothing` | No -- Wave 0 |
| CAD-03 | RunView displays SPM, trend arrows, states correctly | manual (UI) | Manual: launch app, start run, verify display | N/A -- manual |

### Sampling Rate
- **Per task commit:** Quick run command (CadenceServiceTests only)
- **Per wave merge:** Full suite command
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] `BeatStepTests/CadenceServiceTests.swift` -- covers CAD-01, CAD-02 (smoothing logic, state transitions, trend detection)
- [ ] `BeatStepTests/Mocks/MockCMPedometer.swift` -- mock pedometer data for unit testing without device motion

## Sources

### Primary (HIGH confidence)
- [CMPedometer Apple Documentation](https://developer.apple.com/documentation/coremotion/cmpedometer) - API surface, methods, availability checks
- [CMPedometerData Apple Documentation](https://developer.apple.com/documentation/coremotion/cmpedometerdata) - currentCadence property (NSNumber?, steps/sec)
- [currentCadence Apple Documentation](https://developer.apple.com/documentation/coremotion/cmpedometerdata/currentcadence) - Type and unit confirmation
- [NSMotionUsageDescription Apple Documentation](https://developer.apple.com/documentation/bundleresources/information-property-list/nsmotionusagedescription) - Required Info.plist key

### Secondary (MEDIUM confidence)
- [Apple Developer Forums - CMPedometer background](https://developer.apple.com/forums/thread/30339) - Background behavior with audio mode
- [DevFright CMPedometer tutorial](https://www.devfright.com/how-to-use-the-cmpedometer-for-counting-steps/) - Implementation patterns
- [Core Motion CMPedometer Medium article](https://medium.com/@Cordavi/core-motions-cmpedometer-8421cf3c24ca) - Practical usage notes

### Tertiary (LOW confidence)
- None -- all findings verified against Apple documentation or multiple community sources

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - CMPedometer is a stable system framework with well-documented API
- Architecture: HIGH - Follows established project patterns (singleton, @Observable, SwiftUI)
- Pitfalls: HIGH - Well-known issues documented across multiple sources (nil cadence, threading, units)

**Research date:** 2026-03-20
**Valid until:** 2026-06-20 (stable system framework, unlikely to change)
