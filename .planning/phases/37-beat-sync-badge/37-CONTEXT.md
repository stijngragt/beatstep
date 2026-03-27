# Phase 37: Beat Sync Badge - Context

**Gathered:** 2026-03-27
**Status:** Ready for planning

<domain>
## Phase Boundary

Runners see at a glance how well their current stride matches the playing track's beat. Evolve the existing SyncBadge into a beat sync confidence badge with SF Symbol icons, real-time reactivity, and half/double-tempo normalization. Remove redundant sync quality display from CadenceDisplayView so the badge is the single source of sync info.

</domain>

<decisions>
## Implementation Decisions

### Badge design
- **D-01:** Evolve the existing `SyncBadge` in `RunStatusBar.swift` — add an SF Symbol icon left of the existing text label inside the capsule: `[icon In Sync]`. Same capsule pattern as Phase 19 confidence badges (icon + text + color fill at 15% opacity).
- **D-02:** Keep text labels ("In Sync", "Drifting", "Mismatched") alongside icons — unambiguous at a running glance.
- **D-03:** Waveform SF Symbol set:
  - inSync: `waveform.path.ecg` (heartbeat rhythm — "your stride is on beat")
  - drifting: `waveform.badge.minus` (signal degrading)
  - mismatched: `waveform.slash` (no sync)

### Tempo matching logic
- **D-04:** Normalize SPM against track BPM before computing sync delta. Check if SPM is ~2x or ~0.5x the track BPM; if so, compare against the normalized value. This prevents false mismatches for half-tempo and double-tempo track matches.
- **D-05:** Support half (0.5x) and double (2x) tempo multiples only. No triple or other exotic multiples — running cadences (140-190 SPM) make these impractical.
- **D-06:** Normalization happens inside `SyncQuality.from(delta:tolerance:)` or a helper it calls — the rest of the system continues to use raw SPM/BPM values.

### Badge placement
- **D-07:** Keep the badge in `RunStatusBar` (top-right). No relocation — already established position that runners know.
- **D-08:** Remove sync quality color and label from `CadenceDisplayView`. The cadence display shows just the number and trend arrow. The badge in the status bar is the single source of sync quality information. This reduces visual noise.

### Claude's Discretion
- Exact normalization algorithm (pick closest multiple, or try both and use smaller delta)
- Icon sizing relative to `.labelText` font
- Whether normalization is a static method on `SyncQuality` or a standalone helper
- Animation behavior when sync quality changes (existing `BSAnimation.gentle` may suffice)
- How to handle the edge case where no track is playing (badge state when BPM is unavailable)

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Sync Quality Model
- `BeatStep/Models/SyncQuality.swift` — Current 3-tier enum with `from(delta:tolerance:)` computation
- `BeatStep/Models/SyncQuality+Color.swift` — Color mapping for each tier (syncInSync, syncDrifting, syncMismatched)

### Current Badge & Display
- `BeatStep/Views/Run/RunStatusBar.swift` — Contains `SyncBadge` (private struct) — this is what gets evolved
- `BeatStep/Views/Run/CadenceDisplayView.swift` — Currently shows syncQuality color and label — D-08 removes this
- `BeatStep/Views/Run/ActiveRunView.swift` — Run screen layout, passes syncQuality to both RunStatusBar and CadenceDisplayView

### Sync Computation
- `BeatStep/Services/RunEngineService.swift` — `syncQuality` computed property at line 112, `cadenceDelta` computation
- `BeatStep/Services/CadenceService.swift` — `currentSPM` observed by RunEngineService

### Design Patterns (from Phase 19)
- Phase 19 confidence badges used capsule with SF Symbol + text + color fill at 0.15 opacity
- `BeatStep/DesignSystem/DesignTokens.swift` — stateSuccess, stateWarning, stateError tokens; sync color tokens

### Requirements
- `.planning/REQUIREMENTS.md` — SYNC-01, SYNC-02 definitions

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `SyncBadge` (RunStatusBar.swift:26): private struct with capsule + text + color — evolve to add icon
- `SyncQuality` enum: 3 cases with color, displayLabel, and static factory method
- `SyncBackgroundModifier`: full-screen background color based on sync quality — unaffected by this phase
- Phase 19 capsule pattern: `Image(systemName:)` + `Text()` in `HStack` inside `Capsule().fill(color.opacity(0.15))`

### Established Patterns
- Capsule badges use `.font(.labelText)`, `.fontWeight(.bold)`, `Spacing.sm` horizontal / `Spacing.xxs` vertical padding
- Color tokens as static extensions on `Color`
- SF Symbols at matching font size via `Image(systemName:).font(.labelText)`
- `BSAnimation.gentle` for sync quality transitions

### Integration Points
- `RunEngineService.syncQuality` is the single computed source — all views observe this
- `RunEngineService.cadenceDelta` feeds `SyncQuality.from()` — tempo normalization goes here or in the factory method
- `CadenceDisplayView` receives `syncQuality` parameter — D-08 removes this dependency

</code_context>

<specifics>
## Specific Ideas

- Waveform icon set ties the badge to the rhythm/beat concept visually
- Removing sync info from CadenceDisplayView declutters the hero area — the big number should stand alone
- Half/double-tempo normalization ensures a runner at 160 SPM with an 80 BPM track sees "In Sync" not "Mismatched"

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 37-beat-sync-badge*
*Context gathered: 2026-03-27*
