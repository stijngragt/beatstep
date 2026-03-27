# Phase 36: Responsive Cadence - Research

**Researched:** 2026-03-27
**Domain:** iOS pedometer cadence processing, rolling window signal processing, async debounce tuning
**Confidence:** HIGH

## Summary

This phase is a parameter-tuning and filter-addition phase. All three requirements (CAD-01, CAD-02, CAD-03) target existing code paths with well-understood behavior. The changes are: (1) shrink `CadenceService.windowDuration` from 5s to ~2-3s, (2) reduce `RunEngineService.onCadenceChanged` debounce from 17s to ~8s, and (3) add a dead zone filter in `CadenceService.processCadenceSample()` to gate `currentSPM` updates.

No new libraries are needed. No architectural changes required. The existing test infrastructure covers the affected code paths and needs extension for the new dead zone filter behavior. The cadence monitor poll interval (2s) should be evaluated -- with a 2-3s window, sampling every 2s may be borderline. A 1s poll interval gives better display responsiveness at negligible cost.

**Primary recommendation:** Tune three constants, add a dead zone filter (~10 lines of logic), update existing tests, and add new tests for dead zone behavior.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Shrink CadenceService rolling window from 5s to ~2-3s for snappy number updates. Prioritize fast feedback over ultra-smooth transitions.
- **D-02:** Reduce RunEngineService cadence debounce from 17s to ~8s. After 8 seconds at a sustained new pace, commit the change and start the next BPM-matched song. Total time from pace change to new song: ~10-12s.
- **D-03:** Add a dead zone filter to the cadence display -- only update the displayed number when the new rolling average differs by >=3 SPM from the currently shown value. Small fluctuations are swallowed, real pace changes show instantly.

### Claude's Discretion
- Exact window duration within the 2-3s range
- Dead zone threshold tuning (3 SPM is the starting point, adjust if tests show too much or too little filtering)
- Whether the cadence monitor poll interval (currently 2s) needs adjustment to support the faster window

### Deferred Ideas (OUT OF SCOPE)
None
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| CAD-01 | User sees cadence update on screen within 2 seconds of a real pace change | Shrink windowDuration to 2.5s + reduce poll interval to 1s = sub-2s display response |
| CAD-02 | Song selection responds to sustained cadence changes within 12 seconds | Reduce debounce from 17s to 8s + existing buffer invalidation = ~10-12s total |
| CAD-03 | Cadence display remains stable during steady-state running (no jitter) | Dead zone filter in processCadenceSample gates currentSPM updates to >=3 SPM change |
</phase_requirements>

## Standard Stack

No new libraries needed. All changes are to existing Swift code.

### Core (Existing)
| Component | Location | Purpose | Change Needed |
|-----------|----------|---------|---------------|
| CadenceService | `BeatStep/Services/CadenceService.swift` | Rolling window cadence processing | Window duration + dead zone filter |
| RunEngineService | `BeatStep/Services/RunEngineService.swift` | Cadence monitoring + song selection debounce | Debounce timing + poll interval |

### No Additions Required
This is purely a tuning phase. No packages, no new files, no new dependencies.

## Architecture Patterns

### Pattern 1: Dead Zone Filter (New)
**What:** A hysteresis filter that prevents small fluctuations from propagating to the displayed cadence value.
**When to use:** Between rolling average computation and `currentSPM` assignment in `processCadenceSample()`.
**Why it works:** CMPedometer cadence naturally fluctuates by 1-3 SPM even at steady pace. Without filtering, the display constantly flickers between e.g. 170 and 172, which feels jittery to the runner.

**Implementation location:** `CadenceService.processCadenceSample()`, after line 95 (rolling average computation), before line 96 (`currentSPM` assignment).

```swift
// In processCadenceSample(), after computing avgSPM:
let rounded = Int(avgSPM.rounded())
let deadZone = 3  // SPM threshold

// Only update displayed value if change exceeds dead zone
if abs(rounded - currentSPM) >= deadZone || currentSPM == 0 {
    currentSPM = rounded
}
```

**Key details:**
- The `currentSPM == 0` check ensures the first reading always publishes (startup case)
- Dead zone applies to `currentSPM` only; `avgSPM` still flows to `updateTrend()` unfiltered so trend detection remains sensitive
- Both RunEngineService (via `startCadenceMonitor`) and CadenceDisplayView observe `currentSPM`, so both consumers benefit from the filter automatically

### Pattern 2: Constant Tuning
**What:** Change numeric constants in existing async patterns.
**Where:** Two locations:
1. `CadenceService.windowDuration`: `5.0` -> `2.5` (recommended within 2-3s range)
2. `RunEngineService.onCadenceChanged`: `Task.sleep(for: .seconds(17))` -> `Task.sleep(for: .seconds(8))`

### Pattern 3: Poll Interval Adjustment (Discretionary)
**What:** The cadence monitor in `RunEngineService.startCadenceMonitor()` polls `CadenceService.shared.currentSPM` every 2 seconds.
**Analysis:** With a 2.5s window, the rolling average updates continuously as CMPedometer fires (roughly every 1s). The 2s poll interval in RunEngineService is for song selection debounce purposes only -- it does NOT affect the display update speed. CadenceDisplayView observes `currentSPM` directly via `@Observable`, so display updates are immediate when `currentSPM` changes.
**Recommendation:** The 2s poll interval can stay. It controls how often RunEngineService checks for cadence changes that might trigger song selection. Even at 2s polls, the total time budget is: 2s poll latency + 8s debounce = 10s, which is within the 12s CAD-02 target. Reducing to 1s gives a 9s total but adds no meaningful UX improvement. Keep at 2s unless testing reveals edge cases.

### Anti-Patterns to Avoid
- **Filtering trend input:** The dead zone must NOT filter the value passed to `updateTrend()`. Trend detection needs the raw rolling average to detect directional changes early. Only gate `currentSPM` (the displayed/published value).
- **Coupling window size to poll interval:** Window duration and poll interval serve different purposes. Don't assume they need to match.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Signal smoothing | Custom IIR/EIR filter | Rolling window average (already exists) | The rolling window is simple, testable, and sufficient for cadence |
| Hysteresis filter | Complex state machine | Simple dead zone threshold check | A 3-line if-statement is all that's needed; overengineering adds test burden |

## Common Pitfalls

### Pitfall 1: Dead Zone Blocks Initial Reading
**What goes wrong:** If the dead zone filter checks `abs(newValue - currentSPM) >= threshold` without handling `currentSPM == 0`, the first cadence reading (e.g., 170) has delta 170 which passes, but a poorly written check like `currentSPM != 0 && abs(...) < threshold` could invert the logic.
**How to avoid:** Always include `|| currentSPM == 0` as an explicit bypass for the initial state. Test this case explicitly.

### Pitfall 2: Trend Detection Becomes Sluggish
**What goes wrong:** If the dead zone filter is applied before `updateTrend()`, the trend arrows stop responding to gradual changes because they only see stale values.
**How to avoid:** Call `updateTrend(currentAvg: avgSPM)` with the raw rolling average, BEFORE or independent of the dead zone filter on `currentSPM`.

### Pitfall 3: Debounce Cancellation Race
**What goes wrong:** The existing `onCadenceChanged` cancels and restarts `sustainedChangeTask` on each call. With a shorter 8s debounce, it's more likely that a brief cadence fluctuation near the tolerance boundary causes rapid cancel/restart cycles.
**How to avoid:** This is already handled correctly in the existing code -- the guard `significantChange` check prevents re-triggering within tolerance. No change needed, but verify this behavior in tests with the new 8s timing.

### Pitfall 4: Window Too Short for CMPedometer Update Rate
**What goes wrong:** CMPedometer delivers updates roughly every 1 second. A 2s window might only contain 1-2 samples, making the "rolling average" essentially a raw reading.
**How to avoid:** Use 2.5s (the middle of the 2-3s range). This typically captures 2-3 samples -- enough for meaningful averaging while staying responsive. Test with simulated 1-sample windows to ensure graceful behavior.

## Code Examples

### Change 1: Window Duration (CadenceService.swift, line 23)
```swift
// Before:
private let windowDuration: TimeInterval = 5.0

// After:
private let windowDuration: TimeInterval = 2.5
```

### Change 2: Dead Zone Filter (CadenceService.swift, processCadenceSample)
```swift
func processCadenceSample(_ spm: Double, at timestamp: Date) {
    cadenceWindow.append((timestamp: timestamp, cadence: spm))
    cadenceWindow.removeAll { timestamp.timeIntervalSince($0.timestamp) > windowDuration }

    guard !cadenceWindow.isEmpty else { return }
    let avgSPM = cadenceWindow.map(\.cadence).reduce(0, +) / Double(cadenceWindow.count)

    // Dead zone filter: only update displayed SPM when change is significant
    let rounded = Int(avgSPM.rounded())
    let deadZone = 3
    if abs(rounded - currentSPM) >= deadZone || currentSPM == 0 {
        currentSPM = rounded
    }

    // State transitions (unchanged)
    if state == .detecting { state = .active }
    if state == .paused { state = .active }

    lastStepTime = timestamp
    updateTrend(currentAvg: avgSPM)  // Raw average, NOT filtered
}
```

### Change 3: Debounce Duration (RunEngineService.swift, onCadenceChanged, line 500)
```swift
// Before:
try? await Task.sleep(for: .seconds(17))

// After:
try? await Task.sleep(for: .seconds(8))
```

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | XCTest (built-in) |
| Config file | Xcode project scheme |
| Quick run command | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BeatStepTests/CadenceServiceTests` |
| Full suite command | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16'` |

### Phase Requirements -> Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| CAD-01 | Cadence display updates within 2s of pace change | unit | `xcodebuild test ... -only-testing:BeatStepTests/CadenceServiceTests/testWindowPrunesOldSamplesWithNewDuration` | No -- Wave 0 |
| CAD-02 | Song selection responds within 12s of sustained change | unit | `xcodebuild test ... -only-testing:BeatStepTests/RunEngineServiceTests/testDebounceDuration` | No -- Wave 0 |
| CAD-03 | No jitter >5 SPM during steady state | unit | `xcodebuild test ... -only-testing:BeatStepTests/CadenceServiceTests/testDeadZoneFiltersSmallFluctuations` | No -- Wave 0 |

### Sampling Rate
- **Per task commit:** Run CadenceServiceTests + RunEngineServiceTests
- **Per wave merge:** Full test suite
- **Phase gate:** Full suite green before verify-work

### Wave 0 Gaps
- [ ] `CadenceServiceTests` -- add tests for: dead zone filters fluctuations <3 SPM, dead zone passes changes >=3 SPM, dead zone passes initial reading (currentSPM == 0), window pruning at 2.5s boundary, trend still detects changes through dead zone
- [ ] `RunEngineServiceTests` -- add test for: evaluateCadenceChange still works correctly (existing), debounce timing expectation update

## Sources

### Primary (HIGH confidence)
- Direct code inspection of `CadenceService.swift` (182 lines) -- full understanding of rolling window, processCadenceSample, updateTrend
- Direct code inspection of `RunEngineService.swift` (620 lines) -- full understanding of cadence monitor, debounce, buffer system
- Direct code inspection of `CadenceDisplayView.swift` (110 lines) -- confirmed it reads `currentSPM` directly
- Existing test files: `CadenceServiceTests.swift`, `RunEngineServiceTests.swift` -- confirmed test patterns and helpers

### Secondary (MEDIUM confidence)
- CMPedometer update frequency (~1s) based on Apple documentation and training data. Real-device behavior may vary slightly but 2.5s window should capture 2-3 samples minimum.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - no new dependencies, all changes to existing code
- Architecture: HIGH - dead zone filter is a well-understood signal processing pattern, implementation is ~5 lines
- Pitfalls: HIGH - all pitfalls derived from direct code analysis of the specific functions being modified

**Research date:** 2026-03-27
**Valid until:** 2026-04-27 (stable -- no external dependencies that change)
