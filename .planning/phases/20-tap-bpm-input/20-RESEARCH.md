# Phase 20: Tap BPM Input - Research

**Researched:** 2026-03-25
**Domain:** SwiftUI tap-tempo BPM detection with rolling average and outlier rejection
**Confidence:** HIGH

## Summary

This phase implements a tap-tempo BPM interface presented as a half-sheet from the playlist detail view. The core algorithm is straightforward: collect tap timestamps, compute intervals, apply a rolling average over the last 8 intervals, reject outliers, and display a live converging BPM value. All persistence infrastructure already exists via `BPMCacheService.cacheManual()` and the manual confidence badge from Phase 19.

The main technical work involves: (1) a `TapBPMEngine` class that encapsulates the tap-tempo algorithm with outlier rejection, (2) a `TapBPMView` SwiftUI sheet with a large tap zone, progress dots, and live BPM display, and (3) wiring the BPM badge in `TrackRow` as a separate tap gesture that presents the sheet.

**Primary recommendation:** Build a pure-logic `TapBPMEngine` (testable, no UI) that owns all timing/math, then a thin SwiftUI view that drives it. Use percentage-deviation outlier rejection (simpler than IQR for streaming data). The engine is the only new testable unit; the view is standard SwiftUI composition.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- Entry point: tapping the BPM capsule badge opens the tap interface (both `-- BPM` and existing confidence badges)
- All tracks are tappable -- not just no-BPM tracks -- so users can correct wrong API values
- Row tap still plays the track; badge tap opens tap BPM -- two distinct gesture zones on TrackRow
- Opens as a half-sheet (`presentationDetents(.medium)`) -- lightweight, playlist stays visible behind
- Full-width tap zone dominating the bottom of the sheet -- "tap anywhere" design
- Header area shows: track name, artist, live BPM value, and tap count (e.g. "5/8 taps")
- Bottom bar has Reset button (left) and Save button (right)
- Save enabled after 4 taps (early save allowed) -- not gated on full 8-tap stabilization
- Reset button for explicit do-over, plus 3-second inactivity auto-reset per TAP-02
- 8-dot progress indicator: filled dots = taps counted, hollow = remaining
- After 8 taps, "Stable" checkmark label appears next to dots
- BPM updates live on every valid tap
- Outlier rejection: tap zone shakes briefly, dot doesn't fill, error haptic buzz
- Normal tap: tap zone flashes, dot fills, light impact haptic
- Auto-play the track via Spotify when tap sheet opens
- Playback is required -- tap interface disabled if Spotify can't play the track
- Track keeps playing after sheet dismisses
- Haptic feedback: light impact on valid tap, error notification on outlier, success notification on save
- Save triggers: success haptic, sheet auto-dismisses, playlist row updates to manual badge immediately
- `bpmCache` dict in PlaylistDetailView refreshes after save (existing pattern from Phase 19)

### Claude's Discretion
- Exact outlier rejection algorithm (IQR, standard deviation, or percentage threshold)
- Tap zone visual design (color, animation on tap)
- Exact sheet height within `.medium` detent
- How to handle the first tap (no interval yet -- show "--" for BPM)
- SwiftUI sheet presentation mechanics and state management

### Deferred Ideas (OUT OF SCOPE)
None
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| TAP-01 | User can tap along with a song to set its BPM via a large tap area | TapBPMView with full-width tap zone, badge tap gesture on TrackRow, half-sheet presentation, auto-play on open, save via cacheManual() |
| TAP-02 | Tap BPM uses rolling 8-interval average with 3-second inactivity reset | TapBPMEngine with rolling window of last 8 intervals, Timer-based 3s inactivity detection, auto-reset clears all state |
| TAP-03 | Erratic taps filtered via outlier rejection with stabilization indicator | Percentage-deviation outlier rejection (>40% from current median), 8-dot progress with "Stable" label, shake + error haptic on rejection |
</phase_requirements>

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| SwiftUI | iOS 17+ | View layer, sheet presentation, animations | Already used throughout app |
| Foundation | iOS 17+ | Date/TimeInterval for tap timing | Standard library |
| UIKit | iOS 17+ | Haptic feedback generators | UIImpactFeedbackGenerator, UINotificationFeedbackGenerator |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| SwiftData | iOS 17+ | BPM persistence (existing) | Via BPMCacheService.cacheManual() -- already built |

### Alternatives Considered
None -- this phase uses only platform frameworks already in the project.

## Architecture Patterns

### Recommended Project Structure
```
BeatStep/
├── Services/
│   └── TapBPMEngine.swift          # Pure-logic tap tempo engine
├── Views/
│   └── Library/
│       ├── PlaylistDetailView.swift # Modified: sheet presentation, badge tap
│       └── TapBPMView.swift         # New: tap BPM half-sheet UI
```

### Pattern 1: Pure-Logic Engine + Thin View
**What:** Separate all BPM calculation, outlier rejection, and state management into a testable `TapBPMEngine` class. The view observes this engine and renders state.
**When to use:** Always -- this is the project's established pattern (see `SpotifyPlayerService`, `BPMCacheService`).

```swift
@Observable
final class TapBPMEngine {
    // Published state the view reads
    private(set) var currentBPM: Int?
    private(set) var tapCount: Int = 0
    private(set) var isStable: Bool = false
    private(set) var lastTapWasOutlier: Bool = false

    // Internal state
    private var tapTimestamps: [Date] = []
    private var intervals: [TimeInterval] = []
    private var inactivityTimer: Timer?

    private let maxIntervals = 8
    private let inactivityTimeout: TimeInterval = 3.0
    private let outlierThreshold: Double = 0.40  // 40% deviation from median

    func tap() {
        let now = Date()
        resetInactivityTimer()

        guard let lastTap = tapTimestamps.last else {
            // First tap -- no interval yet
            tapTimestamps.append(now)
            tapCount = 1
            lastTapWasOutlier = false
            return
        }

        let interval = now.timeIntervalSince(lastTap)

        // Reject unreasonable intervals (< 0.2s = 300 BPM, > 2s = 30 BPM)
        guard interval >= 0.2 && interval <= 2.0 else {
            lastTapWasOutlier = true
            return
        }

        // Outlier check against existing intervals
        if !intervals.isEmpty && isOutlier(interval) {
            lastTapWasOutlier = true
            return
        }

        // Valid tap
        tapTimestamps.append(now)
        intervals.append(interval)

        // Keep rolling window of last 8
        if intervals.count > maxIntervals {
            intervals.removeFirst()
        }

        tapCount = min(intervals.count + 1, maxIntervals + 1)
        lastTapWasOutlier = false
        isStable = intervals.count >= maxIntervals

        // Calculate BPM from average interval
        let avgInterval = intervals.reduce(0, +) / Double(intervals.count)
        currentBPM = Int(round(60.0 / avgInterval))
    }

    func reset() {
        tapTimestamps.removeAll()
        intervals.removeAll()
        currentBPM = nil
        tapCount = 0
        isStable = false
        lastTapWasOutlier = false
        inactivityTimer?.invalidate()
    }

    var canSave: Bool {
        intervals.count >= 3  // 4 taps = 3 intervals
    }

    private func isOutlier(_ interval: TimeInterval) -> Bool {
        let sorted = intervals.sorted()
        let median = sorted[sorted.count / 2]
        let deviation = abs(interval - median) / median
        return deviation > outlierThreshold
    }

    private func resetInactivityTimer() {
        inactivityTimer?.invalidate()
        inactivityTimer = Timer.scheduledTimer(withTimeInterval: inactivityTimeout, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.reset()
            }
        }
    }
}
```

### Pattern 2: Gesture Zones on TrackRow
**What:** The BPM badge capsule gets its own `.onTapGesture` that presents the tap sheet, while the row's existing `.onTapGesture` continues to play the track. The badge gesture must use `.highPriorityGesture` or be attached directly to the badge view to prevent the row gesture from swallowing it.
**When to use:** For separating badge tap from row tap.

```swift
// In TrackRow -- badge becomes a Button or gets .onTapGesture
// The badge view needs to be extracted and given its own tap handler

// In PlaylistDetailView -- the row tap is already .onTapGesture on the row
// Solution: Make the badge a Button, which naturally captures taps before the row gesture

// Badge as Button approach:
Button {
    selectedTrackForTap = track
} label: {
    HStack(spacing: Spacing.xxs) {
        Image(systemName: confidence.iconName)
        Text("\(bpm) BPM")
    }
    .font(.labelText)
    .fontWeight(.bold)
    .foregroundStyle(confidence.color)
    .padding(.horizontal, 6)
    .padding(.vertical, Spacing.xxs)
    .background(Capsule().fill(confidence.color.opacity(0.15)))
}
.buttonStyle(.plain)
```

### Pattern 3: Sheet Presentation with Callback
**What:** Half-sheet presented via `.sheet()` modifier with a completion callback to refresh the bpmCache.
**When to use:** For the tap BPM sheet that needs to communicate the saved BPM back to the playlist view.

```swift
// In PlaylistDetailView:
@State private var tapBPMTrack: SpotifyTrack?

.sheet(item: $tapBPMTrack) { track in
    TapBPMView(
        track: track,
        playlistURI: "spotify:playlist:\(playlist.id)",
        onSave: { savedBPM in
            bpmCache[track.id] = BPMCacheService.shared.getBPMInfo(forTrackID: track.id)
        }
    )
    .presentationDetents([.medium])
}
```

### Anti-Patterns to Avoid
- **Using `CADisplayLink` for timing:** Overkill. `Date()` timestamps are accurate enough for human tapping (human precision is ~20ms at best, `Date()` is sub-millisecond).
- **Storing all taps forever:** Use a rolling window. Memory is not the concern; accuracy is -- old taps from a different tempo section make the average wrong.
- **Blocking the row tap gesture:** If both row and badge have `.onTapGesture`, gesture precedence becomes ambiguous. Use `Button` for the badge instead, which naturally captures taps.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| BPM persistence | Custom UserDefaults/file storage | `BPMCacheService.cacheManual()` | Already built in Phase 18, handles SwiftData, manual confidence |
| Haptic feedback | Custom audio/vibration | `UIImpactFeedbackGenerator` / `UINotificationFeedbackGenerator` | System standard, respects user haptic settings |
| Sheet presentation | Custom overlay/transition | `.sheet()` + `.presentationDetents([.medium])` | Native SwiftUI, handles dismiss gesture, safe area |
| Badge refresh | Manual state propagation | Re-read from `BPMCacheService.getBPMInfo()` on save callback | Existing pattern from Phase 19 scan flow |

**Key insight:** Almost all infrastructure for this phase already exists. The only genuinely new code is the tap-tempo algorithm engine and the tap sheet view.

## Common Pitfalls

### Pitfall 1: Gesture Conflict Between Row and Badge
**What goes wrong:** Both the row and badge have tap gestures; SwiftUI resolves them unpredictably, causing badge taps to play the track instead of opening the tap sheet.
**Why it happens:** SwiftUI gesture precedence with nested `.onTapGesture` is not well-defined.
**How to avoid:** Use `Button` for the badge (buttons capture taps before parent gestures) or use `.highPriorityGesture` on the badge.
**Warning signs:** Tapping the badge plays the track or does nothing.

### Pitfall 2: Timer Firing After View Dismissed
**What goes wrong:** The 3-second inactivity timer fires after the sheet is dismissed, causing a crash or unexpected state mutation.
**Why it happens:** `Timer.scheduledTimer` retains the closure, and if the engine is not properly invalidated, it fires on a deallocated or dismissed context.
**How to avoid:** Invalidate the timer in `reset()` and call `reset()` when the sheet disappears (`.onDisappear`). Also use `[weak self]` in the timer closure.
**Warning signs:** Console errors about modifying state after view is dismissed.

### Pitfall 3: First Tap Shows 0 or Garbage BPM
**What goes wrong:** With only one tap, there are zero intervals, and dividing by zero or using an uninitialized value produces garbage.
**Why it happens:** Off-by-one between taps and intervals (N taps = N-1 intervals).
**How to avoid:** Show "--" for BPM until the second valid tap produces the first interval. Gate `currentBPM` on `intervals.count >= 1`.
**Warning signs:** BPM shows "0" or "inf" on first tap.

### Pitfall 4: TrackRow is Private -- Cannot Add Callback
**What goes wrong:** `TrackRow` is currently a `private struct` inside `PlaylistDetailView.swift`. Adding a badge tap callback requires it to accept a closure parameter.
**Why it happens:** The struct was built without foreseeing the need for a badge tap action.
**How to avoid:** Add an `onBadgeTap: (() -> Void)?` parameter to TrackRow. It remains private to the file, so the change is localized.
**Warning signs:** Compile errors when trying to reference TrackRow from outside the file.

### Pitfall 5: Auto-Play Race Condition
**What goes wrong:** The sheet opens before Spotify has started playing, and the "playback required" check falsely disables the tap zone.
**Why it happens:** `SpotifyPlayerService.play()` is async with a 500ms delay before fetching state.
**How to avoid:** Fire play on sheet appear, but don't gate the tap zone on playback state. The user decision says "playback is required" but practically, the user is looking at the track and knows what they're tapping along to. Simpler approach: just auto-play and let the user tap. If play fails, show an error state.
**Warning signs:** Tap zone appears disabled briefly on sheet open.

## Code Examples

### Tap BPM View Structure
```swift
struct TapBPMView: View {
    let track: SpotifyTrack
    let playlistURI: String
    let onSave: (Int) -> Void

    @State private var engine = TapBPMEngine()
    @State private var showTapFlash = false
    @State private var showShake = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Header: track info + live BPM
            headerSection

            // Progress dots
            progressDots

            // Tap zone
            tapZone

            // Bottom bar: Reset + Save
            bottomBar
        }
        .onAppear {
            SpotifyPlayerService.shared.play(
                uri: track.uri,
                contextURI: playlistURI
            )
        }
        .onDisappear {
            engine.reset()
        }
    }

    private var tapZone: some View {
        Rectangle()
            .fill(Color.surfaceOverlay)
            .overlay {
                VStack(spacing: Spacing.sm) {
                    Image(systemName: "hand.tap.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(Color.textSecondary)
                    Text("Tap along with the beat")
                        .font(.bodyText)
                        .foregroundStyle(Color.textSecondary)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                engine.tap()
                if engine.lastTapWasOutlier {
                    // Error haptic + shake
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.error)
                    withAnimation(.default) { showShake = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showShake = false
                    }
                } else {
                    // Success haptic + flash
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                    withAnimation(.easeOut(duration: 0.15)) { showTapFlash = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        showTapFlash = false
                    }
                }
            }
            .modifier(ShakeModifier(animating: showShake))
    }

    private func save() {
        guard let bpm = engine.currentBPM else { return }
        BPMCacheService.shared.cacheManual(
            trackID: track.id,
            name: track.name,
            artist: track.artistName,
            bpm: bpm
        )
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        onSave(bpm)
        dismiss()
    }
}
```

### Progress Dots
```swift
private var progressDots: some View {
    HStack(spacing: Spacing.xs) {
        ForEach(0..<8, id: \.self) { index in
            Circle()
                .fill(index < engine.tapCount - 1 ? Color.accent : Color.surfaceOverlay)
                .frame(width: 10, height: 10)
        }

        if engine.isStable {
            HStack(spacing: Spacing.xxs) {
                Image(systemName: "checkmark")
                Text("Stable")
            }
            .font(.captionText)
            .foregroundStyle(Color.stateSuccess)
        }
    }
    .padding(.vertical, Spacing.sm)
}
```

### Shake Modifier
```swift
struct ShakeModifier: ViewModifier {
    var animating: Bool

    func body(content: Content) -> some View {
        content
            .offset(x: animating ? -6 : 0)
            .animation(
                animating ?
                    .default.repeatCount(3, autoreverses: true).speed(6) :
                    .default,
                value: animating
            )
    }
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `.sheet(isPresented:)` | `.sheet(item:)` with `Identifiable` binding | iOS 16+ | Cleaner optional binding for sheets that need data |
| `@StateObject` | `@State` with `@Observable` | iOS 17 / Swift 5.9 | Project already uses this pattern |
| `UIImpactFeedbackGenerator()` + prepare | Direct instantiation + fire | iOS 17+ | System handles preparation internally |

## Open Questions

1. **Tap count display: "5/8" semantics**
   - What we know: User wants "5/8 taps" shown. With N taps there are N-1 intervals. The 8-dot progress maps to 8 intervals (9 taps).
   - What's unclear: Does "8 taps" mean 8 tap events (7 intervals) or 8 intervals (9 tap events)?
   - Recommendation: Treat it as 8 intervals needed for stability. Show tap count as `min(intervals.count, 8)` of 8. The user sees "0/8" through "8/8". First tap shows "0/8" since no interval yet. This matches the 8-dot progress naturally.

2. **Outlier threshold tuning**
   - What we know: 40% median deviation is a reasonable starting point for musical tempo.
   - What's unclear: Exact threshold that feels right for human tapping variance.
   - Recommendation: Start with 40%, adjust if testing shows too many false rejections. This is easily tunable in `TapBPMEngine`.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | XCTest (iOS 17+) |
| Config file | Xcode project default |
| Quick run command | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BeatStepTests/TapBPMEngineTests 2>&1 \| tail -20` |
| Full suite command | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 \| tail -40` |

### Phase Requirements to Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| TAP-01 | Tap zone records taps, calculates BPM, saves via cacheManual | unit | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BeatStepTests/TapBPMEngineTests` | Wave 0 |
| TAP-02 | Rolling 8-interval average, 3s inactivity reset | unit | Same as above | Wave 0 |
| TAP-03 | Outlier rejection, stability indicator after 8 intervals | unit | Same as above | Wave 0 |

### Sampling Rate
- **Per task commit:** `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BeatStepTests/TapBPMEngineTests`
- **Per wave merge:** Full suite
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] `BeatStepTests/TapBPMEngineTests.swift` -- covers TAP-01, TAP-02, TAP-03 (pure logic tests)
- Tests for TapBPMEngine are pure logic (no UI, no SwiftData) so no additional fixtures needed

## Sources

### Primary (HIGH confidence)
- Codebase inspection: `BPMCacheService.swift`, `PlaylistDetailView.swift`, `BPMConfidence.swift`, `BPMInfo.swift`, `DesignTokens.swift`
- Codebase inspection: existing test patterns in `BPMCacheWritePathTests.swift`, `BPMConfidenceModelTests.swift`

### Secondary (MEDIUM confidence)
- SwiftUI `.presentationDetents`, `.sheet(item:)` -- well-established iOS 16+/17+ APIs
- `UIImpactFeedbackGenerator`, `UINotificationFeedbackGenerator` -- standard UIKit haptics

### Tertiary (LOW confidence)
- Outlier threshold of 40% -- reasonable heuristic, may need tuning during testing

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- all platform frameworks already in use
- Architecture: HIGH -- follows established project patterns exactly
- Pitfalls: HIGH -- gesture conflicts and timer lifecycle are well-documented SwiftUI issues
- Algorithm: MEDIUM -- outlier threshold is a tunable heuristic, rolling average is mathematically sound

**Research date:** 2026-03-25
**Valid until:** 2026-04-25 (stable platform APIs, no churn expected)
