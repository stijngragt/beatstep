# Phase 36: Responsive Cadence - Context

**Gathered:** 2026-03-27
**Status:** Ready for planning

<domain>
## Phase Boundary

Make cadence display and song selection respond fast enough that runners feel the app is tracking them in real time. Three measurable targets: display updates within 2s (CAD-01), song selection within 12s (CAD-02), steady-state jitter ≤5 SPM (CAD-03).

</domain>

<decisions>
## Implementation Decisions

### Cadence Display Responsiveness
- **D-01:** Shrink CadenceService rolling window from 5s to ~2-3s for snappy number updates. Prioritize fast feedback over ultra-smooth transitions.

### Song Selection Timing
- **D-02:** Reduce RunEngineService cadence debounce from 17s to ~8s. After 8 seconds at a sustained new pace, commit the change and start the next BPM-matched song. Total time from pace change to new song: ~10-12s.

### Steady-State Stability
- **D-03:** Add a dead zone filter to the cadence display — only update the displayed number when the new rolling average differs by ≥3 SPM from the currently shown value. Small fluctuations are swallowed, real pace changes show instantly.

### Claude's Discretion
- Exact window duration within the 2-3s range
- Dead zone threshold tuning (3 SPM is the starting point, adjust if tests show too much or too little filtering)
- Whether the cadence monitor poll interval (currently 2s) needs adjustment to support the faster window

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Core Services
- `BeatStep/Services/CadenceService.swift` — Rolling window, processCadenceSample(), windowDuration constant
- `BeatStep/Services/RunEngineService.swift` — startCadenceMonitor(), onCadenceChanged(), sustainedChangeTask debounce (17s), tolerance.range

### Display
- `BeatStep/Views/Run/CadenceDisplayView.swift` — Current cadence display rendering
- `BeatStep/Views/Run/ActiveRunView.swift` — Run screen layout where cadence appears

### Tests
- `BeatStepTests/CadenceServiceTests.swift` — Existing cadence processing tests
- `BeatStepTests/RunEngineServiceTests.swift` — Existing engine tests

### Requirements
- `.planning/REQUIREMENTS.md` — CAD-01, CAD-02, CAD-03 definitions

</canonical_refs>

<code_context>
## Existing Code Insights

### Key Constants to Tune
- `CadenceService.windowDuration = 5.0` → target ~2-3s (D-01)
- `RunEngineService.onCadenceChanged` debounce: `Task.sleep(for: .seconds(17))` → target ~8s (D-02)
- `RunEngineService.startCadenceMonitor` poll interval: `Task.sleep(for: .seconds(2))` → may need reduction
- `CadenceService.updateTrend` threshold: `5.0` SPM → relevant for jitter assessment

### Established Patterns
- CadenceService uses `processCadenceSample()` with rolling window average — this is the main hook for D-01 and D-03
- RunEngineService uses async Task debounce pattern for sustained change detection — modify timing for D-02
- Dead zone filter (D-03) is new — should be added in CadenceService between rolling average computation and `currentSPM` assignment

### Integration Points
- `CadenceService.currentSPM` is observed by RunEngineService and CadenceDisplayView
- Dead zone filter gates what gets published to `currentSPM`, so both consumers benefit automatically

</code_context>

<specifics>
## Specific Ideas

No specific requirements — parameter tuning phase with clear measurable targets.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 36-responsive-cadence*
*Context gathered: 2026-03-27*
