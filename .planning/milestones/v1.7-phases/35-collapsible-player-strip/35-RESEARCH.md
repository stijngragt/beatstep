# Phase 35: Collapsible Player Strip - Research

**Researched:** 2026-03-26
**Domain:** SwiftUI interactive gestures, two-state layout, @AppStorage persistence
**Confidence:** HIGH

## Summary

This phase adds collapse/expand behavior to the existing MiniPlayerView. The player transitions between a 64pt expanded strip (current state) and a 20pt collapsed pill handle via interactive drag gestures with cross-fade animation. The UI spec (35-UI-SPEC.md) is thorough and locked -- dimensions, colors, gesture thresholds, and accessibility labels are all defined.

The core technical challenge is implementing an interactive drag that smoothly interpolates height and opacity while coordinating with SwiftUI's `safeAreaInset` system. The existing codebase already uses `DragGesture(minimumDistance: 0)` for the LongPressStopButton and `@AppStorage` for state persistence, so both patterns are established. The main risk is gesture conflict between the drag-to-collapse and the existing play/pause/skip button taps in the expanded state.

**Primary recommendation:** Create a `CollapsiblePlayerView` wrapper around `MiniPlayerView` that owns the drag gesture, collapsed state, and height interpolation. Keep `MiniPlayerView` unchanged as the content layer. Wire collapsed state into `miniPlayerInset` via `@AppStorage("playerCollapsed")`.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- D-01: Swipe down on expanded player to collapse + tap toggle as alternative
- D-02: Swipe up on collapsed handle to expand + tap toggle as alternative
- D-03: Interactive drag -- player follows finger during swipe, snaps to collapsed/expanded at threshold
- D-04: BSHaptics.light() fires when drag crosses threshold and snaps to new state
- D-05: Pill bar only -- centered capsule shape (~36pt wide, 4pt tall), no track name or play indicator
- D-06: Full-width ultraThinMaterial background bar (same as expanded state), just thinner (~20pt total height)
- D-07: Keep existing top shadow on collapsed state
- D-08: Fade + shrink -- content fades out and bar height shrinks simultaneously during interactive drag
- D-09: Cross-fade between content and pill handle during drag
- D-10: Default state on fresh install: expanded
- D-11: Always remember last user choice via @AppStorage

### Claude's Discretion
- Drag threshold distance (e.g., 40pt vs percentage-based)
- Spring animation parameters for snap-to-state
- Exact collapsed bar height and pill dimensions
- Hit target area for the collapsed handle
- Whether DragGesture or custom gesture approach is best
- How the safeAreaInset height changes between states

### Deferred Ideas (OUT OF SCOPE)
None.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| PLAY-02 | User can collapse the player to a thin drag handle via swipe-down or tap | DragGesture + @AppStorage pattern; CollapsiblePlayerView wrapper manages state transition |
| PLAY-03 | User can expand the collapsed player via swipe-up or tap on handle | Symmetric drag gesture on collapsed handle; tap gesture as alternative path |
| PLAY-04 | Collapsed player shows minimal indicator (handle) that doesn't obstruct tab navigation | 20pt collapsed height with 44pt invisible hit target; safeAreaInset adjusts per state |
</phase_requirements>

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| SwiftUI | iOS 17+ | UI framework | Project target, all views are SwiftUI |
| DragGesture | SwiftUI built-in | Interactive drag tracking | Already used in LongPressStopButton; reliable onChanged/onEnded |
| @AppStorage | SwiftUI built-in | Bool persistence | Established pattern in codebase (6 existing usages) |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| BSAnimation | Project token | Spring animations for snap | `.smooth` for collapse/expand transitions |
| BSHaptics | Project token | Haptic feedback on threshold cross | `.light()` on snap |
| DesignTokens | Project token | Spacing, ComponentSize constants | All dimension values |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| DragGesture | GestureState | GestureState resets eagerly -- project already learned this lesson (CONTEXT notes timer-based over GestureState) |
| @AppStorage | @SceneStorage | @SceneStorage doesn't persist across app restarts -- requirement D-11 requires cross-restart persistence |

## Architecture Patterns

### Recommended Project Structure
```
BeatStep/Views/Player/
  MiniPlayerView.swift          # UNCHANGED -- existing content layer
  CollapsiblePlayerView.swift   # NEW -- wrapper managing collapse/expand
BeatStep/DesignSystem/
  DesignTokens.swift            # ADD 4 new ComponentSize constants
BeatStep/App/
  ContentView.swift             # MODIFY miniPlayerInset to use CollapsiblePlayerView
```

### Pattern 1: Wrapper View with Interpolated State
**What:** `CollapsiblePlayerView` wraps `MiniPlayerView` and a pill handle in a ZStack. A `@State private var dragOffset: CGFloat = 0` tracks finger position. Height and opacity are computed from drag progress.
**When to use:** When adding interactive behavior to an existing static view without modifying it.
**Example:**
```swift
struct CollapsiblePlayerView: View {
    @AppStorage("playerCollapsed") private var isCollapsed = false
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging = false

    private let expandedHeight = ComponentSize.miniPlayerHeight    // 64
    private let collapsedHeight = ComponentSize.miniPlayerCollapsedHeight // 20
    private let dragThreshold: CGFloat = 40

    private var baseHeight: CGFloat {
        isCollapsed ? collapsedHeight : expandedHeight
    }

    /// Current height during drag or at rest
    private var currentHeight: CGFloat {
        let target = baseHeight + (isCollapsed ? -dragOffset : dragOffset)
        return min(max(target, collapsedHeight), expandedHeight)
    }

    /// 0.0 = collapsed, 1.0 = expanded
    private var expandProgress: CGFloat {
        let range = expandedHeight - collapsedHeight
        guard range > 0 else { return 0 }
        return (currentHeight - collapsedHeight) / range
    }

    var body: some View {
        ZStack {
            // Expanded content
            MiniPlayerView()
                .opacity(expandProgress)

            // Collapsed pill handle
            Capsule()
                .fill(Color.textTertiary)
                .frame(width: ComponentSize.dragHandleWidth,
                       height: ComponentSize.dragHandleHeight)
                .opacity(1 - expandProgress)
        }
        .frame(height: currentHeight)
        .frame(maxWidth: .infinity)
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 4, y: -2)
        )
        .contentShape(Rectangle()) // Full area is tappable/draggable
        .gesture(dragGesture)
        .onTapGesture { toggleState() }
        .accessibilityLabel(isCollapsed
            ? "Music player, collapsed. Tap or swipe up to expand."
            : "Music player. Swipe down to minimize.")
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 8)
            .onChanged { value in
                isDragging = true
                dragOffset = value.translation.height
                // Haptic at threshold crossing
                checkThresholdCrossing()
            }
            .onEnded { value in
                isDragging = false
                let shouldToggle = abs(value.translation.height) > dragThreshold
                if shouldToggle {
                    withAnimation(BSAnimation.smooth) {
                        isCollapsed.toggle()
                    }
                }
                withAnimation(BSAnimation.smooth) {
                    dragOffset = 0
                }
            }
    }

    private func toggleState() {
        BSHaptics.light()
        withAnimation(BSAnimation.smooth) {
            isCollapsed.toggle()
        }
    }
}
```

### Pattern 2: Conditional safeAreaInset Height
**What:** The `miniPlayerInset` ViewBuilder reads `@AppStorage("playerCollapsed")` to return different inset heights.
**When to use:** When the docked element changes size and scroll content must adjust.
**Example:**
```swift
@AppStorage("playerCollapsed") private var playerCollapsed = false

@ViewBuilder
private var miniPlayerInset: some View {
    if miniPlayerVisible {
        CollapsiblePlayerView()
            .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}
```
Note: The `safeAreaInset` height adjusts automatically because `CollapsiblePlayerView.frame(height:)` changes with state. SwiftUI propagates the new inset when the frame height changes.

### Pattern 3: Gesture Priority for Button Protection
**What:** Play/pause and skip buttons in `MiniPlayerView` must remain tappable in expanded state. The tap-to-collapse must not intercept button taps.
**When to use:** When a container gesture and child buttons coexist.
**Example:**
```swift
// Option A: Use simultaneousGesture for drag, onTapGesture on background only
// Option B: In CollapsiblePlayerView, apply tap gesture with .allowsHitTesting
//           on an overlay that excludes the button area
// Option C: Use .highPriorityGesture on buttons (already Button type,
//           which SwiftUI prioritizes over parent gestures by default)
```
**Recommendation:** SwiftUI `Button` already has higher gesture priority than parent `onTapGesture`. The tap-to-collapse on the CollapsiblePlayerView container will NOT intercept Button taps. No special handling needed -- just verify in testing.

### Anti-Patterns to Avoid
- **GestureState for drag offset:** GestureState resets to initial value when the gesture is interrupted (e.g., system gesture conflict). Use plain `@State` with manual reset in `onEnded`.
- **Animating safeAreaInset value directly:** Don't try to animate the spacing parameter of `.safeAreaInset()`. Instead, animate the frame height of the view inside the inset -- SwiftUI propagates this automatically.
- **Separate expanded/collapsed view trees:** Don't use `if/else` to switch between two different views. Use a single ZStack with opacity-controlled layers so the transition is seamless during interactive drag.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Spring animation | Custom timing curves | `BSAnimation.smooth` | Already tuned for the project; spring with 0.45 response, 0.85 damping |
| Haptic feedback | UIImpactFeedbackGenerator directly | `BSHaptics.light()` | Consistent with all other haptics in the app |
| State persistence | UserDefaults manually | `@AppStorage("playerCollapsed")` | SwiftUI-native, auto-triggers view updates |
| Drag threshold logic | Velocity-based calculations | Simple distance threshold (40pt) | UI spec locks this; velocity adds complexity without user benefit |

## Common Pitfalls

### Pitfall 1: Drag Direction Ambiguity
**What goes wrong:** Horizontal scrolling in list views beneath the player triggers the vertical drag gesture.
**Why it happens:** DragGesture captures all directions by default.
**How to avoid:** Use `minimumDistance: 8` (already in UI spec) and consider checking that `abs(translation.height) > abs(translation.width)` in onChanged before committing to the drag.
**Warning signs:** Player starts collapsing when user scrolls horizontally in a tab.

### Pitfall 2: safeAreaInset Height Desync
**What goes wrong:** Content scroll area doesn't update when player collapses/expands, leaving a gap or overlap.
**Why it happens:** The safeAreaInset view's frame height must change for SwiftUI to recalculate the inset. If the height is hardcoded or doesn't animate, the content jumps.
**How to avoid:** Let CollapsiblePlayerView own its frame height via `.frame(height: currentHeight)`. The safeAreaInset container picks up the height automatically. Wrap state changes in `withAnimation(BSAnimation.smooth)`.
**Warning signs:** Content snaps to new position instead of animating, or content doesn't adjust at all.

### Pitfall 3: Tap Gesture Eating Button Taps
**What goes wrong:** Tap-to-collapse on the player container intercepts play/pause button taps.
**Why it happens:** Parent tap gesture fires before child button gesture.
**How to avoid:** SwiftUI `Button` has built-in gesture priority over parent `onTapGesture`. Verify this works. If not, move tap-to-collapse to an overlay behind the buttons, or use `.simultaneousGesture` only on the non-button areas.
**Warning signs:** Tapping play/pause collapses the player instead of toggling playback.

### Pitfall 4: Drag Offset Not Resetting on Cancellation
**What goes wrong:** Player gets stuck at an intermediate height after an interrupted gesture.
**Why it happens:** `onEnded` doesn't fire if the gesture is cancelled (e.g., incoming call).
**How to avoid:** Also reset `dragOffset` in `onDisappear` or use `.onChange(of: isDragging)` as a safety net. The LongPressStopButton pattern (Timer + manual state) shows this project prefers explicit cleanup.
**Warning signs:** Player is stuck between expanded and collapsed after a phone call or notification.

### Pitfall 5: Haptic Fires Multiple Times During Drag
**What goes wrong:** BSHaptics.light() fires repeatedly as the user drags back and forth across the threshold.
**Why it happens:** No debounce on threshold crossing detection.
**How to avoid:** Track a `@State private var hasPassedThreshold = false` flag. Set to true on first crossing, reset in onEnded. Only fire haptic when transitioning from false to true.
**Warning signs:** User feels multiple taps while dragging slowly near the threshold.

## Code Examples

### New DesignTokens Constants
```swift
// Add to ComponentSize enum in DesignTokens.swift
static let miniPlayerCollapsedHeight: CGFloat = 20
static let dragHandleWidth: CGFloat = 36
static let dragHandleHeight: CGFloat = 4
static let dragHandleCornerRadius: CGFloat = 2
```

### ContentView Integration
```swift
// ContentView.swift - replace miniPlayerInset
@AppStorage("playerCollapsed") private var playerCollapsed = false

@ViewBuilder
private var miniPlayerInset: some View {
    if miniPlayerVisible {
        CollapsiblePlayerView()
            .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}
```

### Threshold Crossing Haptic Pattern
```swift
@State private var hasPassedThreshold = false

// In DragGesture.onChanged:
let crossed = abs(value.translation.height) > dragThreshold
if crossed && !hasPassedThreshold {
    BSHaptics.light()
    hasPassedThreshold = true
} else if !crossed && hasPassedThreshold {
    hasPassedThreshold = false
}

// In DragGesture.onEnded:
hasPassedThreshold = false
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| GestureState for drag | @State + manual reset | Project convention (LongPressStopButton) | Avoids eager reset bugs |
| Raw UIKit haptics | BSHaptics tokens | v1.6 design system | Consistent haptic language |
| Global safeAreaInset on TabView | Per-tab safeAreaInset | Phase 34 | Each tab gets its own inset -- collapse/expand must work on all tabs |

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | XCTest (Xcode built-in) |
| Config file | BeatStepTests/ directory |
| Quick run command | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BeatStepTests/CollapsiblePlayerTests -quiet` |
| Full suite command | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' -quiet` |

### Phase Requirements -> Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| PLAY-02 | Collapse via drag/tap changes state | unit | `xcodebuild test -only-testing:BeatStepTests/CollapsiblePlayerTests -quiet` | Wave 0 |
| PLAY-03 | Expand via drag/tap changes state | unit | same as above | Wave 0 |
| PLAY-04 | Collapsed height and token values correct | unit | `xcodebuild test -only-testing:BeatStepTests/DesignTokenTests -quiet` | Partial (token tests exist, need new constants) |

### Sampling Rate
- **Per task commit:** `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BeatStepTests/CollapsiblePlayerTests -quiet`
- **Per wave merge:** Full suite
- **Phase gate:** Full suite green before verify

### Wave 0 Gaps
- [ ] `BeatStepTests/CollapsiblePlayerTests.swift` -- covers PLAY-02, PLAY-03 (expand progress calculation, threshold logic, state toggle)
- [ ] Update `DesignTokenTests.swift` -- add assertions for new ComponentSize constants (miniPlayerCollapsedHeight, dragHandleWidth, dragHandleHeight, dragHandleCornerRadius)

**Testable logic to extract:** The expand progress calculation (`(currentHeight - collapsedHeight) / range`) and threshold crossing logic should be `static` functions on `CollapsiblePlayerView` (same pattern as `LongPressStopButton.progress`) so they can be unit tested without UI.

## Sources

### Primary (HIGH confidence)
- Project codebase: `MiniPlayerView.swift`, `ContentView.swift`, `LongPressStopButton.swift`, `DesignTokens.swift`, `BSHaptics.swift`, `BSAnimation.swift`
- Phase 35 UI Spec: `.planning/phases/35-collapsible-player-strip/35-UI-SPEC.md` -- complete visual/interaction contract
- Phase 35 CONTEXT.md: All locked decisions (D-01 through D-11)
- Phase 34 CONTEXT.md: Per-tab safeAreaInset pattern established

### Secondary (MEDIUM confidence)
- SwiftUI DragGesture + Button gesture priority behavior -- based on established SwiftUI behavior (iOS 17+), Button has built-in priority over parent tap gestures

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - all SwiftUI built-in, no new dependencies
- Architecture: HIGH - wrapping existing view, established patterns in codebase
- Pitfalls: HIGH - gesture conflict and safeAreaInset coordination are well-understood SwiftUI topics; project has prior art (LongPressStopButton)

**Research date:** 2026-03-26
**Valid until:** 2026-04-26 (stable -- SwiftUI iOS 17 APIs, no fast-moving dependencies)
