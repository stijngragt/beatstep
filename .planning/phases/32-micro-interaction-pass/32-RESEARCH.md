# Phase 32: Micro-Interaction Pass - Research

**Researched:** 2026-03-26
**Domain:** SwiftUI haptic feedback, spring animations, transition modifiers
**Confidence:** HIGH

## Summary

This phase applies BSHaptics and BSAnimation design tokens across all views in the app. Currently only 4 of ~27 view files use BSHaptics and 5 use BSAnimation. The work is mechanical: scan each view, add haptic calls to interactive elements, apply animation tokens to state changes, and add `.transition(.opacity)` to all conditional view appearances. The one area requiring care is the run screen, where rapid cadence/BPM updates must NOT trigger spring animations on number displays.

The design system tokens (BSHaptics and BSAnimation) are already built and proven in ZonePickerView, TolerancePicker, and PlaylistListView. The established pattern is `BSHaptics.selection()` followed by `withAnimation(BSAnimation.snappy) { ... }` for user-initiated selections. This phase extends that pattern everywhere.

**Primary recommendation:** Work view-by-view through the app, applying the haptic mapping from CONTEXT.md decisions D-01 through D-05 and animation mapping from D-06 through D-08. Start with run screen animation scoping (highest risk of jank), then sweep remaining views.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Standard button taps (Start Run, Disconnect Spotify, Open Settings, scan actions) use `BSHaptics.light()`
- **D-02:** Picker and toggle changes continue using `BSHaptics.selection()` (already established in ZonePickerView, TolerancePicker)
- **D-03:** Destructive actions (Disconnect Spotify, Reset Zones to Defaults) use `BSHaptics.warning()` for distinct double-tap feel
- **D-04:** Success confirmations (run start, BPM save, scan complete) use `BSHaptics.success()`
- **D-05:** During active run, haptics fire ONLY on user actions (skip, play/pause, tempo toggle, stop) -- NOT on cadence updates or sync state changes. Prevents haptic fatigue during 30+ minute runs.
- **D-06:** Layered animation mapping: .snappy for taps/selections, .smooth for content transitions, .gentle for background shifts, .quick for micro-feedback, .page for NavigationLink push transitions
- **D-07:** All conditional view appearances (if/else branches) get `.transition(.opacity)` -- consistent crossfade everywhere
- **D-08:** Run screen animation scoping: animate UI chrome (sync badge color, zone band position, ramp phase transitions) but do NOT animate number text (cadence SPM, BPM display, delta indicator). Numbers snap instantly.

### Claude's Discretion
- Specific file-by-file inventory of which views need haptics/animations added (researcher scans codebase)
- Whether to batch haptic additions by view or by interaction type
- Order of implementation (run screen scoping first vs haptics first)
- Whether onboarding transitions need special treatment beyond .opacity

### Deferred Ideas (OUT OF SCOPE)
None -- discussion stayed within phase scope
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| POL-02 | Every tap, selection, and state change has appropriate haptic feedback and fluid spring animations | Full codebase audit identifies 16 views needing changes; BSHaptics and BSAnimation tokens already built; CONTEXT.md decisions D-01 through D-08 provide exact mapping |

Note: POL-02 is referenced in ROADMAP.md but not yet defined in REQUIREMENTS.md. The phase success criteria from the roadmap serve as the functional definition.
</phase_requirements>

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| UIKit (UIImpactFeedbackGenerator, UISelectionFeedbackGenerator, UINotificationFeedbackGenerator) | iOS 17+ | Haptic feedback | Apple's only supported haptic API; already wrapped in BSHaptics |
| SwiftUI Animation | iOS 17+ | Spring animations, transitions | Native; already wrapped in BSAnimation tokens |

No external dependencies needed. Everything uses the existing BSHaptics and BSAnimation design system tokens.

## Architecture Patterns

### File-by-File Inventory

Complete audit of every view file, what it needs, and current state:

**ALREADY DONE (no changes needed):**
| File | BSHaptics | BSAnimation | Transitions |
|------|-----------|-------------|-------------|
| ZonePickerView.swift | selection() x2 | snappy x2 | n/a |
| TolerancePicker.swift | selection() | snappy | n/a |
| PlaylistListView.swift | medium() x3, warning(), selection() | smooth, snappy | .opacity x3 |
| PlaylistDetailView.swift | -- | smooth | .opacity x3 |
| PlaylistListSkeleton.swift | -- | -- | n/a (skeleton) |
| PlaylistDetailSkeleton.swift | -- | -- | n/a (skeleton) |

**NEEDS HAPTICS ADDED:**
| File | Interactive Elements | Haptic Token | Notes |
|------|---------------------|--------------|-------|
| SettingsView.swift | "Disconnect Spotify" button | warning() (D-03) | Destructive action |
| SettingsView.swift | "Open Settings" button | light() (D-01) | Standard button tap |
| SettingsView.swift | Version label 5-tap easter egg | selection() (D-02) | Selection-style on each tap |
| RunDefaultsView.swift | "Reset to Defaults" button | warning() (D-03) | Destructive action |
| RunDefaultsView.swift | Picker onChange | selection() (D-02) | Picker change |
| RunTabView.swift | "Start Run" button | success() (D-04) | Run start confirmation |
| RunTabView.swift | "Go to Library" button | light() (D-01) | Standard button tap |
| RunTabView.swift | "Retry" button | light() (D-01) | Standard button tap |
| ActiveRunView.swift | Tempo mode toggle | light() (D-01) | User action during run (D-05) |
| ActiveRunView.swift | "Cool Down" button | light() (D-01) | User action during run (D-05) |
| RunPlayerView.swift | Play/Pause button | light() (D-01) | User action during run (D-05) |
| RunPlayerView.swift | Skip button | light() (D-01) | User action during run (D-05) |
| MiniPlayerView.swift | Play/Pause button | light() (D-01) | Standard button tap |
| MiniPlayerView.swift | Skip button | light() (D-01) | Standard button tap |
| TapBPMView.swift | Tap zone | Already has raw UIImpactFeedbackGenerator | Migrate to BSHaptics.light() |
| TapBPMView.swift | Outlier tap | Already has raw UINotificationFeedbackGenerator | Migrate to BSHaptics.error() |
| TapBPMView.swift | Save button | Already has raw UINotificationFeedbackGenerator | Migrate to BSHaptics.success() |
| TapBPMView.swift | Reset button | light() (D-01) | Standard button tap |
| OnboardingSpotifyView.swift | "Connect with Spotify" button | light() (D-01) | Standard button tap |
| OnboardingSpotifyView.swift | "Try Different Account" button | light() (D-01) | Standard button tap |
| OnboardingHealthView.swift | "Allow Permissions" button | light() (D-01) | Standard button tap |
| OnboardingHealthView.swift | "Continue" button | light() (D-01) | Standard button tap |
| OnboardingHealthView.swift | "Skip" button | light() (D-01) | Standard button tap |
| OnboardingPlaylistView.swift | Playlist row tap | light() (D-01) | Standard button tap |
| OnboardingPlaylistView.swift | "Continue" (analysis complete) | success() (D-04) | Scan complete confirmation |
| OnboardingZonesView.swift | "Get Started" button | success() (D-04) | Onboarding complete |
| OnboardingZonesView.swift | "Skip" button | light() (D-01) | Standard button tap |
| LongPressStopButton.swift | Long press complete | success() (D-04) | Run stop confirmation |
| ZoneSettingsRow.swift | Expand/collapse tap | selection() (D-02) | Toggle-style interaction |
| ZoneSettingsRow.swift | Stepper changes | selection() (D-02) | Value change |
| SensorLabView.swift | Slider changes | selection() (D-02) | Value change (debug only, low priority) |

**NEEDS ANIMATION TOKEN MIGRATION:**
| File | Current Animation | Target Token | Notes |
|------|------------------|--------------|-------|
| SyncBackgroundModifier.swift | .easeInOut(duration: 0.6) | BSAnimation.gentle | D-06: background shift |
| RunStatusBar.swift (SyncBadge) | .easeInOut(duration: 0.3) | BSAnimation.gentle | D-06: background/badge shift |
| ZoneBandView.swift | .easeInOut(duration: 0.3) | BSAnimation.smooth | D-06: content transition (position indicator) |
| RampPhaseIndicator.swift | .easeInOut(duration: 0.5) | BSAnimation.smooth | D-06: content transition (progress bar) |
| ZoneSettingsRow.swift | .easeInOut(duration: 0.2) | BSAnimation.snappy | D-06: tap/toggle interaction |
| OnboardingFlow.swift | .easeInOut(duration: 0.35) | BSAnimation.page | D-06: page transition |
| LongPressStopButton.swift | .easeOut(duration: 0.2) | BSAnimation.quick | D-06: micro-feedback (cancel reset) |
| TapBPMView.swift | .default, .easeOut(0.15), .easeIn(0.1) | BSAnimation.quick | D-06: micro-feedback (tap flash) |
| TapBPMView.swift (stable label) | .default | BSAnimation.smooth | D-06: content appearance |

**NEEDS ANIMATION SCOPING (Run Screen - D-08):**
| File | Component | Action | Notes |
|------|-----------|--------|-------|
| CadenceDisplayView.swift | SPM number text | Ensure NO animation on spm value | Numbers must snap instantly |
| CadenceDisplayView.swift | Delta label | Ensure NO animation on cadenceDelta | Numbers must snap instantly |
| CadenceDisplayView.swift | Trend arrow | BSAnimation.quick on trend change | Icon state change |
| ActiveRunView.swift | Conditional views (RampPhaseIndicator, ZoneBandView, RunPlayerView, Cool Down button) | Add .transition(.opacity) + scoped .animation | Prevent full-body animations from cascading |

**NEEDS .transition(.opacity) ADDED (D-07):**
| File | Conditional View | Current State |
|------|-----------------|---------------|
| SettingsView.swift | `if let user = authService.currentUser` (Account section) | No transition |
| SettingsView.swift | `if sensorLabEnabled` (Debug section) | No transition |
| RunTabView.swift | `if/else` state switching (noPlaylist/loading/loaded/error) | No transition |
| RunTabView.swift | `if let range = RunZone.mergedBPMRange(...)` | No transition |
| ActiveRunView.swift | `if runEngine.runMode == .guided, let phase = ...` (RampPhaseIndicator) | No transition |
| ActiveRunView.swift | `if runEngine.runMode == .guided` (ZoneBandView) | No transition |
| ActiveRunView.swift | `if let track = ...` (RunPlayerView) | No transition |
| ActiveRunView.swift | `if runEngine.runMode == .guided && rampPhase != .coolDown` (Cool Down button) | No transition |
| RunPlayerView.swift | `if let bpm = trackBPM` | No transition |
| MiniPlayerView.swift | `if let track = playerService.currentTrack` (entire view) | No transition |
| MiniPlayerView.swift | `if let bpm = currentBPM` / else | No transition |
| OnboardingSpotifyView.swift | `if authService.isCheckingAuth` / `else if error` | No transition |
| OnboardingSpotifyView.swift | `if !authService.isCheckingAuth` (connect button) | No transition |
| OnboardingHealthView.swift | `if permissionsRequested` / else (continue vs allow button) | No transition |
| OnboardingPlaylistView.swift | `if isLoading` / `else if selected` / `else` (state switching) | No transition |
| OnboardingPlaylistView.swift | `if analysisComplete` / else (within analyzing state) | No transition |
| ZoneSettingsRow.swift | `if isExpanded` (stepper) | No transition |
| RunStatusBar.swift | `if let zoneName` | No transition |
| CadenceDisplayView.swift | `if isGuidedMode` / else (delta vs sync label) | No transition -- but per D-08, do NOT animate number text |

### Pattern 1: Haptic + Animation Combo
**What:** Standard pattern for user-initiated interactions
**When to use:** Every button tap, picker change, toggle
**Example:**
```swift
// Source: BeatStep/Views/Run/ZonePickerView.swift (existing pattern)
Button {
    BSHaptics.selection()
    withAnimation(BSAnimation.snappy) {
        // state change
    }
} label: { ... }
```

### Pattern 2: Haptic-Only (No Animation)
**What:** Haptic feedback without animation wrapper
**When to use:** When the state change triggers no visual animation, or animation is handled elsewhere
**Example:**
```swift
Button {
    BSHaptics.light()
    // action that navigates or triggers external effect
} label: { ... }
```

### Pattern 3: Transition on Conditional Views
**What:** `.transition(.opacity)` on conditionally appearing views with scoped animation
**When to use:** Every if/else branch that shows/hides a view
**Example:**
```swift
// Source: BeatStep/Views/Library/PlaylistDetailView.swift (existing pattern)
if isLoading {
    skeletonView
        .transition(.opacity)
} else {
    contentView
        .transition(.opacity)
}
// parent container:
.animation(BSAnimation.smooth, value: isLoading)
```

### Pattern 4: Animation Scoping on Run Screen
**What:** Apply `.animation()` to specific values only; exclude number displays
**When to use:** ActiveRunView and its children where rapid data updates flow
**Example:**
```swift
// Animate chrome, not numbers
SyncBadge(quality: syncQuality)
    .animation(BSAnimation.gentle, value: syncQuality)

// CadenceDisplayView: NO .animation() modifier on the view
// Numbers snap instantly via default SwiftUI behavior
```

### Anti-Patterns to Avoid
- **Animating cadence/BPM numbers with springs:** Numbers update every 1-2 seconds during a run. Spring animations on rapidly changing numbers cause visual stacking/jank. Use `.contentTransition(.numericText())` if any transition is desired (already used in TapBPMView).
- **Implicit animations cascading to children:** Adding `.animation()` to ActiveRunView body would animate everything including numbers. Scope animations to specific values on specific views.
- **Haptics on observing state changes:** Never fire haptics in `.onChange(of: cadenceService.currentSPM)` or similar observed values. Only on direct user actions.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Haptic feedback | Raw UIImpactFeedbackGenerator calls | BSHaptics.light/medium/heavy/selection/success/warning/error() | Consistent token usage; TapBPMView currently has raw calls that need migration |
| Spring animations | Inline .spring() parameters | BSAnimation.snappy/smooth/gentle/quick/page | Consistent timing across app |
| View transitions | Custom opacity/scale modifiers | .transition(.opacity) | D-07 mandates consistent crossfade everywhere |

## Common Pitfalls

### Pitfall 1: Animation Jank on Run Screen
**What goes wrong:** Adding `.animation()` at ActiveRunView level causes cadence numbers and delta values to spring-animate on every update, creating jittery visuals during runs.
**Why it happens:** SwiftUI's `.animation()` modifier applies to ALL animatable properties in the subtree unless scoped.
**How to avoid:** Use `.animation(BSAnimation.gentle, value: syncQuality)` on specific views (RunStatusBar, SyncBackgroundModifier) and explicitly avoid adding animation modifiers to CadenceDisplayView.
**Warning signs:** Numbers appearing to "slide" or "bounce" during active testing.

### Pitfall 2: Missing Animation Driver for Transitions
**What goes wrong:** Adding `.transition(.opacity)` without a corresponding `withAnimation()` or `.animation(_, value:)` means the transition never actually animates.
**Why it happens:** SwiftUI transitions only animate when the insertion/removal happens inside an animation context.
**How to avoid:** Pair every `.transition(.opacity)` with either `withAnimation { }` on the state change or `.animation(BSAnimation.smooth, value: stateProperty)` on the parent.
**Warning signs:** Views still appearing/disappearing abruptly despite having `.transition()`.

### Pitfall 3: Haptic Fatigue
**What goes wrong:** Firing haptics on every cadence update or sync quality change during a 30+ minute run.
**Why it happens:** Observing `@Observable` properties that update frequently and adding haptics in onChange handlers.
**How to avoid:** D-05 is clear: haptics during runs ONLY on skip, play/pause, tempo toggle, stop, cool down. Never on observed data changes.
**Warning signs:** Phone vibrating continuously during a run.

### Pitfall 4: TapBPMView Raw Haptics
**What goes wrong:** TapBPMView already uses raw UIImpactFeedbackGenerator/UINotificationFeedbackGenerator instead of BSHaptics tokens.
**Why it happens:** It was written before BSHaptics existed or before the convention was established.
**How to avoid:** Migrate all 3 raw haptic calls to BSHaptics equivalents as part of this phase.
**Warning signs:** Any direct UIFeedbackGenerator usage outside BSHaptics.swift.

### Pitfall 5: Onboarding Page Transitions
**What goes wrong:** OnboardingFlow.advanceTo() uses `.easeInOut(duration: 0.35)` instead of BSAnimation.page.
**Why it happens:** Written before animation tokens existed.
**How to avoid:** Replace with BSAnimation.page (.spring(response: 0.5, dampingFraction: 0.9)) which is specifically designed for page transitions.
**Warning signs:** Any raw animation values outside BSAnimation.swift.

## Code Examples

### Adding Haptic to a Button
```swift
// SettingsView.swift - Disconnect Spotify (destructive)
Button(role: .destructive) {
    BSHaptics.warning()
    SpotifyPlayerService.shared.disconnect()
    SpotifyAuthService.shared.disconnect()
} label: {
    HStack {
        Spacer()
        Text("Disconnect Spotify")
        Spacer()
    }
}
```

### Adding Transition to Conditional View
```swift
// ActiveRunView.swift - RunPlayerView conditional appearance
if let track = runEngine.currentMatchedTrack {
    RunPlayerView(
        track: track,
        isPaused: playerService.isPaused,
        trackBPM: runEngine.currentTrackBPM,
        onPlayPause: { playerService.togglePlayPause() },
        onSkip: { Task { await runEngine.skipToNextMatch() } }
    )
    .padding(.horizontal, Spacing.md)
    .transition(.opacity)
}
```

### Scoping Animation on Run Screen
```swift
// RunStatusBar.swift - animate badge color, not zone text
SyncBadge(quality: syncQuality)
    .animation(BSAnimation.gentle, value: syncQuality)

// ZoneBandView.swift - animate position indicator
Circle()
    .fill(syncQuality.color)
    .frame(width: 12, height: 12)
    .offset(x: normalizedPosition * (geo.size.width - 12))
    .animation(BSAnimation.smooth, value: currentCadence)
```

### Migrating Raw Haptics in TapBPMView
```swift
// Before (raw):
let generator = UIImpactFeedbackGenerator(style: .light)
generator.impactOccurred()

// After (token):
BSHaptics.light()

// Before (raw):
let generator = UINotificationFeedbackGenerator()
generator.notificationOccurred(.success)

// After (token):
BSHaptics.success()
```

## Implementation Order Recommendation

1. **Run screen animation scoping first** (ActiveRunView, CadenceDisplayView, RunStatusBar, ZoneBandView, RampPhaseIndicator, SyncBackgroundModifier) -- highest risk, needs careful testing
2. **Token migration** (TapBPMView raw haptics, ZoneSettingsRow raw animation, OnboardingFlow raw animation, LongPressStopButton raw animation) -- standardize existing code
3. **Haptic additions by view** (SettingsView, RunDefaultsView, RunTabView, ActiveRunView controls, RunPlayerView, MiniPlayerView, all Onboarding views, SensorLabView)
4. **Transition additions** (all conditional views identified above) -- mechanical sweep

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Xcode Previews (visual inspection) |
| Config file | n/a -- Previews are inline |
| Quick run command | Build and run in Xcode Simulator |
| Full suite command | Manual interaction test on all screens |

### Phase Requirements to Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| POL-02a | All buttons provide haptic feedback | manual-only | Run app, tap every button | n/a |
| POL-02b | View transitions use spring animations from BSAnimation | manual-only | Navigate between screens, observe animations | n/a |
| POL-02c | Conditional views use .transition(.opacity) | manual-only | Trigger state changes, observe crossfades | n/a |
| POL-02d | Run screen numbers snap instantly (no jank) | manual-only | Start run with varying cadence, observe number updates | n/a |

**Justification for manual-only:** Haptic feedback and visual animation quality cannot be verified through unit tests. They require physical device or simulator interaction. However, a code-level verification can confirm BSHaptics/BSAnimation usage:

```bash
# Verify no raw UIFeedbackGenerator usage outside BSHaptics.swift
grep -r "UIImpactFeedbackGenerator\|UISelectionFeedbackGenerator\|UINotificationFeedbackGenerator" BeatStep/Views/

# Verify no raw animation values outside BSAnimation.swift
grep -r "\.spring(response:\|\.easeInOut(duration:\|\.easeOut(duration:" BeatStep/Views/
```

### Wave 0 Gaps
None -- no test infrastructure needed. Verification is code-grep for token compliance + manual interaction.

## Open Questions

1. **CadenceDisplayView trend arrow animation**
   - What we know: The trend arrow (up/down/right) changes based on cadence trend
   - What's unclear: Whether `.animation(BSAnimation.quick, value: trend)` on the trend arrow is desirable or if it should also snap instantly like the numbers
   - Recommendation: Use BSAnimation.quick -- it's 0.15s easeOut, subtle enough not to distract but provides visual feedback that the icon changed

2. **OnboardingPlaylistView state transitions**
   - What we know: It has 3 major states (loading, picker, analyzing) that switch via if/else
   - What's unclear: Whether simple .opacity transition is enough or if the analyzing state deserves something more (e.g., .opacity + .scale)
   - Recommendation: Keep .opacity per D-07 for consistency. The analyzing state already has a ProgressView scale effect that provides visual interest.

## Sources

### Primary (HIGH confidence)
- BSHaptics.swift -- full API surface (7 static methods wrapping 3 UIKit feedback generators)
- BSAnimation.swift -- full API surface (5 animation presets: snappy, smooth, gentle, quick, page)
- Codebase audit -- all 27 view files read and inventoried
- CONTEXT.md decisions D-01 through D-08 -- exact haptic and animation mapping

### Secondary (MEDIUM confidence)
- Apple SwiftUI documentation on `.animation(_:value:)` scoping behavior and `.transition()` requirements

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - all tools already exist in the project (BSHaptics, BSAnimation)
- Architecture: HIGH - patterns established in ZonePickerView, PlaylistListView, PlaylistDetailView
- Pitfalls: HIGH - run screen jank is a known SwiftUI animation scoping issue; inventory-based approach eliminates missed views

**Research date:** 2026-03-26
**Valid until:** 2026-04-26 (stable -- SwiftUI animation API is mature, project tokens are fixed)
