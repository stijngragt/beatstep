# Phase 23: Sensor Lab Step Count Fix - Research

**Researched:** 2026-03-25
**Domain:** CoreMotion CMPedometer step count wiring in SwiftUI
**Confidence:** HIGH

## Summary

Phase 23 closes the single gap identified in the v1.4 milestone audit: SLAB-02 is partial because `SensorLabService.stepCount` is declared (line 13) and reset (line 51) but never written. The view at `SensorLabView.swift` line 34 displays `service.stepCount`, which always shows 0.

The fix is straightforward. CMPedometer already runs in `CadenceService` and delivers `CMPedometerData` containing `numberOfSteps`. The simplest correct approach is to add a `@Published`-equivalent step count property to `CadenceService` (which already processes pedometer data) and bind SensorLabView to it, rather than adding a second CMPedometer instance in SensorLabService.

**Primary recommendation:** Expose a live `stepCount` property on `CadenceService`, update it in `handlePedometerData`, read it in SensorLabView, and remove the orphaned `stepCount` from SensorLabService.

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| SLAB-02 | Sensor Lab displays raw accelerometer output, cadence, step count, algorithm state | stepCount is the only missing piece. Accelerometer, cadence, and state already display correctly. Fix requires exposing step count from CadenceService and binding it in SensorLabView. |
</phase_requirements>

## Architecture Analysis

### Current State

**SensorLabService** (`BeatStep/Services/SensorLabService.swift`):
- Line 13: `var stepCount: Int = 0` -- declared, never written
- Line 51: `stepCount = 0` -- reset on stop, but never incremented
- Manages accelerometer only (CMMotionManager), has no pedometer

**CadenceService** (`BeatStep/Services/CadenceService.swift`):
- Line 18: `private var pedometer: CMPedometer?` -- owns the pedometer
- Line 30: `private var previousStepCount: Int?` -- tracks steps for cadence fallback calculation
- Line 115-136: `handlePedometerData(_:)` -- receives `data.numberOfSteps` but only uses it for cadence delta, never exposes it
- Has `@Observable` macro, so adding a public property auto-notifies SwiftUI

**SensorLabView** (`BeatStep/Views/Settings/SensorLabView.swift`):
- Line 5: `private var service: SensorLabService { .shared }`
- Line 6: `private var cadence: CadenceService { .shared }` -- already imported
- Line 28: Reads `cadence.currentSPM`
- Line 31: Reads `cadence.state`
- Line 34: Reads `service.stepCount` -- this is the broken line

### Fix Architecture

**Option A (recommended): Expose stepCount from CadenceService**
- Add `var stepCount: Int = 0` to CadenceService observable state
- Update `handlePedometerData` to set `stepCount = data.numberOfSteps.intValue`
- Reset to 0 in `stopDetecting()`
- Change SensorLabView line 34 from `service.stepCount` to `cadence.stepCount`
- Remove `stepCount` from SensorLabService (dead code cleanup)

**Why Option A:** CadenceService already owns the CMPedometer. Adding a second pedometer in SensorLabService would be wasteful and create permission/lifecycle complexity. The view already references `cadence` for SPM and state, so reading stepCount from the same source is natural.

**Option B (rejected): Add CMPedometer to SensorLabService**
- Would create a second pedometer instance
- Would need separate permission handling
- Would duplicate lifecycle management
- Over-engineered for a single integer property

## Standard Stack

No new libraries needed. This fix uses only existing infrastructure:

| Component | Already Present | Purpose |
|-----------|----------------|---------|
| CoreMotion CMPedometer | CadenceService | Provides numberOfSteps |
| @Observable macro | Both services | SwiftUI auto-binding |
| SwiftUI LabeledContent | SensorLabView | Display widget |

## Architecture Patterns

### Pattern: Single Source of Truth for Pedometer Data

CadenceService is the single owner of CMPedometer. All pedometer-derived data (cadence, step count) should flow through it. SensorLabService handles accelerometer data only.

```
CMPedometer --data--> CadenceService --stepCount--> SensorLabView
                                     --currentSPM--> SensorLabView
                                     --state------> SensorLabView

CMMotionManager --data--> SensorLabService --accel xyz--> SensorLabView
                                           --samples----> SensorLabView (chart)
```

### Pattern: @Observable Property Addition

Adding a property to an `@Observable` class automatically notifies SwiftUI views. No `@Published` wrapper needed (that is Combine/ObservableObject).

```swift
@Observable
final class CadenceService {
    var stepCount: Int = 0  // SwiftUI auto-tracks reads
    // ...
    private func handlePedometerData(_ data: CMPedometerData) {
        stepCount = data.numberOfSteps.intValue
        // ... existing cadence logic
    }
}
```

### Anti-Patterns to Avoid

- **Second CMPedometer instance:** Do not create a pedometer in SensorLabService. One pedometer per app is sufficient.
- **Timer-based polling:** Do not poll for step count. CMPedometer delivers updates via its callback.
- **Keeping orphaned property:** Do not leave `stepCount` on SensorLabService after moving the read to CadenceService. Dead code should be removed.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Step counting | Custom accelerometer peak detection | CMPedometer.numberOfSteps | Apple's ML-tuned algorithm, handles pocket/wrist/etc. |
| Data binding | Manual delegate/callback from CadenceService | @Observable property | SwiftUI observation is automatic |

## Common Pitfalls

### Pitfall 1: CadenceService Not Running When Sensor Lab Opens
**What goes wrong:** If the user opens Sensor Lab without an active run, CadenceService may not be detecting, so stepCount stays 0.
**Why it happens:** CadenceService.startDetecting() is called when a run starts, not when Sensor Lab opens.
**How to avoid:** SensorLabView.onAppear should call `cadence.requestPermissionAndStart()` if not already active. onDisappear should stop only if SensorLab started it (not if a run was already going).
**Warning signs:** stepCount always 0 on device even when walking.

### Pitfall 2: numberOfSteps is Cumulative From Start
**What goes wrong:** `CMPedometerData.numberOfSteps` is cumulative from the `startUpdates(from:)` date, not per-update delta.
**Why it happens:** CMPedometer counts total steps since monitoring began.
**How to avoid:** This is actually the desired behavior for a "step count" display. Just assign directly: `stepCount = data.numberOfSteps.intValue`.

### Pitfall 3: Removing stepCount From SensorLabService Breaks Tests
**What goes wrong:** `SensorLabServiceTests.testStopAccelerometerResetsState` (line 64) and `testInitialState` (line 89) both assert `stepCount == 0`.
**How to avoid:** Remove those assertions when removing the property. The tests otherwise remain valid.

### Pitfall 4: CadenceService.startDetecting Guards on isCadenceAvailable
**What goes wrong:** Line 54 has `guard CMPedometer.isCadenceAvailable() else { return }`. On some devices, cadence may not be available but step counting is.
**How to avoid:** The guard should check `CMPedometer.isStepCountingAvailable()` as an alternative path, or the step count feature should not depend on cadence availability. Review whether this guard should be relaxed.

## Code Examples

### Adding stepCount to CadenceService

```swift
// In CadenceService observable state section:
var stepCount: Int = 0

// In handlePedometerData:
private func handlePedometerData(_ data: CMPedometerData) {
    let now = Date()
    lastStepTime = now
    stepCount = data.numberOfSteps.intValue  // <-- ADD THIS LINE

    if let cadence = data.currentCadence?.doubleValue {
        // ... existing cadence logic
    }
}

// In stopDetecting:
func stopDetecting() {
    // ... existing cleanup
    stepCount = 0
}
```

### Updating SensorLabView

```swift
// Change line 34 from:
Text("\(service.stepCount)")
// To:
Text("\(cadence.stepCount)")
```

### Ensuring CadenceService Runs in Sensor Lab

```swift
// In SensorLabView:
.onAppear {
    SensorLabService.shared.startAccelerometer()
    CadenceService.shared.requestPermissionAndStart()
}
.onDisappear {
    SensorLabService.shared.stopAccelerometer()
    CadenceService.shared.stopDetecting()
}
```

### Removing Orphaned Property from SensorLabService

```swift
// Remove from SensorLabService:
// var stepCount: Int = 0     (line 13)
// stepCount = 0              (line 51)
```

### Updating Tests

```swift
// In SensorLabServiceTests.testStopAccelerometerResetsState:
// Remove: XCTAssertEqual(service.stepCount, 0)

// In SensorLabServiceTests.testInitialState:
// Remove: XCTAssertEqual(service.stepCount, 0)

// Add new test in CadenceServiceTests or SensorLabServiceTests:
func testStepCountUpdatesFromPedometerData() {
    // CadenceService.processCadenceSample doesn't set stepCount
    // so a new internal method or direct property set test is needed
}
```

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | XCTest (built-in) |
| Config file | BeatStepTests target in Xcode project |
| Quick run command | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BeatStepTests/SensorLabServiceTests 2>&1 \| tail -20` |
| Full suite command | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 \| tail -40` |

### Phase Requirements to Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| SLAB-02 (step count) | CadenceService.stepCount updates when pedometer data arrives | unit | Quick run command above | Partially (SensorLabServiceTests exists, CadenceService step count test does not) |
| SLAB-02 (step count) | stepCount resets to 0 on stopDetecting | unit | Same | No |
| SLAB-02 (step count) | SensorLabView displays cadence.stepCount | manual-only | Device walkthrough | N/A |

### Sampling Rate
- **Per task commit:** Quick run command (SensorLabServiceTests)
- **Per wave merge:** Full suite
- **Phase gate:** Full suite green before verify

### Wave 0 Gaps
- [ ] CadenceService step count test -- need internal method or direct property test for stepCount assignment
- [ ] Update existing SensorLabServiceTests to remove orphaned stepCount assertions

## Open Questions

1. **CadenceService lifecycle in Sensor Lab**
   - What we know: SensorLabView currently only starts/stops the accelerometer. CadenceService is started by the run engine.
   - What's unclear: Should Sensor Lab independently start/stop CadenceService, or should it assume it is already running?
   - Recommendation: Start CadenceService in onAppear, stop in onDisappear. This makes Sensor Lab self-contained for desk testing.

2. **isCadenceAvailable guard**
   - What we know: CadenceService.startDetecting() guards on `CMPedometer.isCadenceAvailable()`. Step counting works on more devices than cadence.
   - What's unclear: Whether this guard prevents step count from working on simulator or cadence-unavailable devices.
   - Recommendation: Check during implementation. If step count is needed without cadence, the guard may need `|| CMPedometer.isStepCountingAvailable()`.

## Sources

### Primary (HIGH confidence)
- `BeatStep/Services/SensorLabService.swift` -- read directly, confirmed stepCount never written
- `BeatStep/Services/CadenceService.swift` -- read directly, confirmed pedometer data flow
- `BeatStep/Views/Settings/SensorLabView.swift` -- read directly, confirmed binding to service.stepCount
- `BeatStepTests/SensorLabServiceTests.swift` -- read directly, identified assertions to update
- `.planning/v1.4-MILESTONE-AUDIT.md` -- gap identification and fix options

### Secondary (MEDIUM confidence)
- Apple CMPedometer documentation (from training data) -- numberOfSteps is cumulative from start date

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- no new libraries, pure wiring fix
- Architecture: HIGH -- code read directly, single source of truth pattern is clear
- Pitfalls: HIGH -- identified from direct code analysis (lifecycle, guard, test breakage)

**Research date:** 2026-03-25
**Valid until:** 2026-04-25 (stable -- internal wiring fix, no external dependencies)
