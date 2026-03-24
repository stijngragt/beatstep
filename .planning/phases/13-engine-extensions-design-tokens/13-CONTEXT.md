# Phase 13: Engine Extensions + Design Tokens - Context

**Gathered:** 2026-03-24
**Status:** Ready for planning

<domain>
## Phase Boundary

Extend RunEngineService with three new computed properties (syncQuality, cadenceDelta, tempoMode) and add sync-state color aliases to DesignTokens. This phase is pure engine + token work -- no UI views are built here (those are Phases 14-16).

</domain>

<decisions>
## Implementation Decisions

### Half-tempo matching
- tempoMode toggle (1:1 vs 1/2) persists via UserDefaults across runs
- Toggle placement: near the cadence display (Phase 14+ will build the UI, but the engine property + persistence is Phase 13)
- Mode change takes effect at next song, not immediately -- current song keeps playing
- findMatchingTracks uses tempoMode as a ranking preference (already decided: NOT a BPM /2 transformation)
- In 1/2 mode, sync quality and delta compare cadence/2 to song BPM (not raw cadence)

### Cadence delta display logic
- Guided mode: signed delta from zone target BPM (e.g., "+4 SPM", "-6 SPM") -- explicit +/- signs
- Free mode: sync quality label ("In Sync", "Drifting", "Mismatched") instead of a numeric delta
- Updates every cadence poll cycle (2 seconds) -- no additional smoothing beyond CadenceService's rolling average
- cadenceDelta is a published computed property on RunEngineService

### Sync quality thresholds
- Thresholds tied to user's BPM tolerance setting (not fixed values)
- inSync: delta within tolerance range (e.g., <= 7 with normal tolerance)
- drifting: delta between 1x and 2x tolerance (e.g., 8-14 with normal tolerance)
- mismatched: delta beyond 2x tolerance (e.g., 15+ with normal tolerance)
- Compares cadence to current song's BPM (not to effective/target BPM)
- In 1/2 tempo mode: compares cadence/2 to song BPM (consistent with delta)

### Claude's Discretion
- Exact enum naming for SyncQuality and TempoMode types
- Whether to use a SyncQuality enum or struct
- How to structure the half-tempo ranking bias in findMatchingTracks
- Sync-state color token naming and exact color values (can reuse/alias stateSuccess/stateWarning/stateError or define sync-specific colors)

</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- `RunEngineService` (Services/RunEngineService.swift): @Observable singleton with existing run lifecycle, cadence monitoring (2s poll), and BPM matching
- `BPMTolerance` (Models/BPMTolerance.swift): .tight(3), .normal(7), .loose(12) with UserDefaults persistence -- sync thresholds should reference this
- `RunMode` (Models/RunMode.swift): .free/.guided with UserDefaults persistence -- tempoMode can follow same pattern
- `CadenceService` (Services/CadenceService.swift): publishes currentSPM (rolling 5s average), trend, state
- `DesignTokens` (DesignSystem/DesignTokens.swift): already has stateSuccess (green), stateWarning (yellow), stateError (red) -- candidates for sync-state aliases

### Established Patterns
- @Observable for reactive state (no Combine)
- UserDefaults for simple preference persistence (RunMode, BPMTolerance, RunZone)
- Enum with rawValue String + CaseIterable for mode/setting types
- Testing via internal methods + ForTesting helpers on RunEngineService

### Integration Points
- `findMatchingTracks(forSPM:)` -- needs tempoMode ranking preference added
- `effectiveBPM` -- may need tempoMode awareness for guided mode delta calculation
- `currentMatchedTrack` -- its BPM (via bpmMap) is needed for sync quality comparison
- `tolerance.range` -- used as base for sync quality thresholds

</code_context>

<specifics>
## Specific Ideas

No specific references -- open to standard approaches for enum types and computed properties.

</specifics>

<deferred>
## Deferred Ideas

None -- discussion stayed within phase scope

</deferred>

---

*Phase: 13-engine-extensions-design-tokens*
*Context gathered: 2026-03-24*
