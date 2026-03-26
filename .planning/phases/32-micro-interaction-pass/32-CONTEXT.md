# Phase 32: Micro-Interaction Pass - Context

**Gathered:** 2026-03-26
**Status:** Ready for planning

<domain>
## Phase Boundary

Add haptic feedback and spring animations to every interactive element in the app using BSHaptics and BSAnimation design tokens. Scope every animation on the run screen to prevent jank from rapid cadence updates. Add explicit transitions to all conditional view appearances.

</domain>

<decisions>
## Implementation Decisions

### Haptic Mapping
- **D-01:** Standard button taps (Start Run, Disconnect Spotify, Open Settings, scan actions) use `BSHaptics.light()`
- **D-02:** Picker and toggle changes continue using `BSHaptics.selection()` (already established in ZonePickerView, TolerancePicker)
- **D-03:** Destructive actions (Disconnect Spotify, Reset Zones to Defaults) use `BSHaptics.warning()` for distinct double-tap feel
- **D-04:** Success confirmations (run start, BPM save, scan complete) use `BSHaptics.success()`
- **D-05:** During active run, haptics fire ONLY on user actions (skip, play/pause, tempo toggle, stop) — NOT on cadence updates or sync state changes. Prevents haptic fatigue during 30+ minute runs.

### Animation Token Selection
- **D-06:** Layered animation mapping:
  - `.snappy` for taps and selections (user-initiated, already used in ZonePicker/TolerancePicker)
  - `.smooth` for content transitions (loading states, view swaps, already used for skeleton crossfade)
  - `.gentle` for background shifts (SyncBackgroundModifier color changes)
  - `.quick` for micro-feedback (badge updates, icon state changes)
  - `.page` for NavigationLink push transitions
- **D-07:** All conditional view appearances (if/else branches) get `.transition(.opacity)` — consistent crossfade everywhere, extending the pattern established in Phase 31 skeleton loading
- **D-08:** Run screen animation scoping: animate UI chrome (sync badge color, zone band position, ramp phase transitions) but do NOT animate number text (cadence SPM, BPM display, delta indicator). Numbers update too frequently for spring animations and must snap instantly.

### Claude's Discretion
- Specific file-by-file inventory of which views need haptics/animations added (researcher scans codebase)
- Whether to batch haptic additions by view or by interaction type
- Order of implementation (run screen scoping first vs haptics first)
- Whether onboarding transitions need special treatment beyond .opacity

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Design System Tokens
- `BeatStep/DesignSystem/BSHaptics.swift` — 7 haptic tokens: light, medium, heavy, selection, success, warning, error
- `BeatStep/DesignSystem/BSAnimation.swift` — 5 animation presets: snappy, smooth, gentle, quick, page

### Established Patterns (reference implementations)
- `BeatStep/Views/Run/ZonePickerView.swift` — BSHaptics.selection() + withAnimation(BSAnimation.snappy) pattern for picker changes
- `BeatStep/Views/Run/TolerancePicker.swift` — Same .selection() + .snappy pattern
- `BeatStep/Views/Library/PlaylistListView.swift` — BSHaptics.medium() for swipe actions, .animation(BSAnimation.smooth) for loading
- `BeatStep/Views/Library/PlaylistDetailView.swift` — .transition(.opacity) + .animation(BSAnimation.smooth) crossfade pattern

### Run Screen (animation scoping targets)
- `BeatStep/Views/Run/ActiveRunView.swift` — Main run screen, needs animation scoping
- `BeatStep/Views/Run/CadenceDisplayView.swift` — Cadence number display (NO animation)
- `BeatStep/Views/Run/RunStatusBar.swift` — Sync badge (animate color), zone name
- `BeatStep/Views/Run/ZoneBandView.swift` — Zone position indicator (animate position)
- `BeatStep/Views/Run/RampPhaseIndicator.swift` — Ramp phase transitions (animate)
- `BeatStep/Views/Run/SyncBackgroundModifier.swift` — Background color shift (use .gentle)
- `BeatStep/Views/Run/LongPressStopButton.swift` — Stop button with progress ring

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `BSHaptics` enum: 7 static methods wrapping UIImpactFeedbackGenerator, UISelectionFeedbackGenerator, UINotificationFeedbackGenerator
- `BSAnimation` enum: 5 animation presets (snappy/smooth/gentle/quick/page) as static Animation values
- `ShimmerModifier`: Already uses animation patterns, not directly relevant but shows .repeatForever pattern

### Established Patterns
- Haptic + animation combo: `BSHaptics.selection()` followed by `withAnimation(BSAnimation.snappy) { }` in ZonePickerView
- Loading crossfade: `.transition(.opacity)` on branches + `.animation(BSAnimation.smooth, value:)` on Group
- Swipe action haptics: `BSHaptics.medium()` in PlaylistListView swipe handlers

### Integration Points
- **Views needing haptics added:** SettingsView (buttons), RunDefaultsView (reset button), RunTabView (Start Run), ActiveRunView (skip/play/pause/stop), TapBPMView (save), OnboardingFlow (continue buttons), SensorLabView
- **Views needing animation scoping:** ActiveRunView (exclude cadence/BPM numbers), RunStatusBar (animate sync badge), ZoneBandView (animate position)
- **Views needing transitions:** Any if/else conditional appearance without explicit .transition()

### Current Adoption
- BSHaptics used in 4 of ~20 view files
- BSAnimation used in 5 of ~20 view files
- Most views have no haptic feedback or token-based animations

</code_context>

<specifics>
## Specific Ideas

No specific requirements — standard application of design tokens across all views following the established patterns.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 32-micro-interaction-pass*
*Context gathered: 2026-03-26*
