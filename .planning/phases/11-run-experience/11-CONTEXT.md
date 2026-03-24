# Phase 11: Run Experience - Context

**Gathered:** 2026-03-24
**Status:** Ready for planning

<domain>
## Phase Boundary

Zone picker replaces effort labels (PacePreset) with Zone 1–5 + Free as a unified run mode selector. Full-width Start Run CTA pinned to bottom of Run tab. No new run engine logic — zones map to existing `runMode` + `targetBPM` parameters. Onboarding is Phase 12.

</domain>

<decisions>
## Implementation Decisions

### Zone picker design
- Horizontal scroll of capsule buttons — same pattern as current PacePresetPicker
- Replaces BOTH PacePresetPicker AND ModePicker — single unified picker
- Zone capsules show "Z1 Recovery" on first line, BPM value ("155") on second line
- "Free" is a capsule in the same picker alongside Z1–Z5, styled identically but without BPM subtitle
- BPM values reflect user-customized values from Settings (RunZone.saved), not hardcoded defaults
- Selected capsule uses surfaceOverlay fill (brighter); unselected uses surfaceElevated — same as current PacePresetPicker
- No hero BPM display — the capsule BPM is sufficient
- Selected zone persists between launches via UserDefaults

### Full-width CTA
- Full-width Start Run button pinned to bottom of RunTabView (always visible, not scrolling)
- Accent red (#FF4545) background — matches brand, not green
- Only visible when a previous playlist exists (LastRunPlaylist)
- When no playlist: hide CTA, show "Select a playlist from Library to start" message (current behavior minus capsule button)
- RunView's existing full-width green Start Run button unchanged

### Free mode handling
- "Free" is a zone option in the unified picker — no separate Free/Guided toggle
- Selecting Free = free run (no target BPM), selecting Z1–Z5 = guided run at zone BPM
- ModePicker component removed — no longer needed
- PacePresetPicker component removed — replaced by zone picker

### Tolerance picker on RunTabView
- Tolerance picker (±3/±7/±12 BPM) appears on RunTabView below zone picker when Z1–Z5 is selected
- Hidden when Free is selected (no target BPM = no tolerance needed)

### Claude's Discretion
- Exact zone picker component implementation (new ZonePickerView or refactor PacePresetPicker)
- How to map zone selection to existing RunEngineService parameters (runMode + targetBPM)
- Whether to deprecate or delete PacePreset enum
- Animation/transition when tolerance picker shows/hides based on zone selection
- Layout spacing between cover art, zone picker, tolerance picker, and CTA

</decisions>

<specifics>
## Specific Ideas

No specific requirements — open to standard approaches

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- `PacePresetPicker`: horizontal capsule scroll pattern to replicate for zones (then remove)
- `RunZone` model: already has `displayLabel` ("Z1 Recovery"), `bpm`, `saved` (UserDefaults), `defaults`
- `TolerancePicker`: existing segmented control with ±BPM labels — move to RunTabView
- `LastRunPlaylist`: existing UserDefaults wrapper for persisting last-used playlist

### Established Patterns
- UserDefaults for simple settings (BPMTolerance, RunMode, RunZone BPMs)
- Design tokens: `Color.accent`, `Color.surfaceOverlay`, `Color.surfaceElevated`, `Spacing.*`
- Capsule button styling with conditional fill for selected state

### Integration Points
- `RunTabView`: add zone picker, tolerance picker, replace capsule button with full-width pinned CTA
- `RunView`: update to use zone selection instead of PacePreset; remove ModePicker and PacePresetPicker
- `RunEngineService`: receives `runMode` (.free/.guided) and `targetBPM` — zone maps to these
- `PacePreset` enum + `ModePicker`: candidates for removal after zone picker replaces their function

</code_context>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 11-run-experience*
*Context gathered: 2026-03-24*
