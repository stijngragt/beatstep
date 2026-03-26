# Phase 31: Settings + Skeleton States - Research

**Researched:** 2026-03-26
**Domain:** SwiftUI skeleton loading states, Settings screen architecture
**Confidence:** HIGH

## Summary

This phase has two distinct workstreams: (1) restructuring the existing SettingsView into grouped sections with SF Symbol icons, and (2) implementing shimmer skeleton loading states for PlaylistListView and PlaylistDetailView. Both are well-established iOS patterns with no external dependencies.

The skeleton shimmer effect uses a SwiftUI `LinearGradient` animated across placeholder shapes via `GeometryReader` and a repeating animation. The Settings restructuring uses the standard `.insetGrouped` List style with `Section` headers already present in the codebase. The existing design token system (DesignTokens.swift, BSAnimation.swift) provides all styling and animation primitives needed.

**Primary recommendation:** Build a reusable `ShimmerModifier` ViewModifier and per-view skeleton components. Restructure SettingsView in-place using existing Section/NavigationLink patterns.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Gradient sweep shimmer -- classic iOS pattern with a light gradient sweeping left-to-right across grey placeholder shapes
- **D-02:** Content-matched skeleton shapes -- each skeleton mirrors the real row's structure (square for art, lines for title/subtitle, bar for coverage) to reduce layout shift
- **D-03:** Neutral grey color palette -- shape fill ~#2A2A2A on dark background, shimmer peak ~#3A3A3A. No accent color tinting
- **D-04:** Fill visible area with skeleton rows (~6-8 rows for playlists) -- no empty space below placeholders
- **D-05:** Fade crossfade transition from skeleton to content using BSAnimation.smooth
- **D-06:** Grouped inset List style -- standard iOS rounded section cards with clear section headers
- **D-07:** SF Symbol icons next to each section header -- all icons use heartbeat red (#FF4545), monochrome
- **D-08:** Running Zones moves to a sub-page via NavigationLink with chevron -- keeps Settings compact
- **D-09:** PlaylistListView gets skeleton loading state (replaces ProgressView spinner)
- **D-10:** PlaylistDetailView gets skeleton loading state (replaces ProgressView spinner)
- **D-11:** RunTabView and Onboarding views keep their current ProgressView spinners -- lower priority
- Settings sections in order: Account, Run Defaults, Permissions, Debug, About
- "Disconnect Spotify" stays in Account section or gets its own (Claude's discretion)
- Version display must be dynamic (read from bundle), not hardcoded "v1.4"

### Claude's Discretion
- Exact SF Symbol names for each section
- Shimmer animation timing and gradient width
- Skeleton row spacing and corner radii
- Section header typography (existing design tokens)
- Whether "Disconnect Spotify" stays in Account or gets its own section
- Zone editing sub-page layout and navigation title

### Deferred Ideas (OUT OF SCOPE)
None
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| POL-04 | Settings screen organized with grouped sections, SF Symbol icons, discoverable structure | Settings restructuring with .insetGrouped List, Section headers with icons, NavigationLink for sub-pages |
| POL-03 | Loading states use skeleton placeholders instead of spinners | ShimmerModifier + content-matched skeleton views for PlaylistListView and PlaylistDetailView |
</phase_requirements>

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| SwiftUI | iOS 17+ | All UI components | Project standard, already used throughout |
| Foundation (Bundle) | iOS 17+ | Dynamic version string from Info.plist | Standard iOS API for bundle version |

### Supporting
No additional libraries needed. Skeleton shimmer is built entirely with SwiftUI primitives (LinearGradient, GeometryReader, withAnimation). No third-party skeleton library required.

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Custom shimmer | SkeletonUI (SPM package) | Adds dependency for ~50 lines of custom code; not worth it |
| LinearGradient shimmer | Lottie animation | Overkill; gradient sweep is simpler and more performant |

## Architecture Patterns

### Recommended Project Structure
```
BeatStep/
├── DesignSystem/
│   └── ShimmerModifier.swift      # Reusable shimmer ViewModifier
├── Views/
│   ├── Library/
│   │   ├── PlaylistListView.swift  # Modified: skeleton state replaces ProgressView
│   │   ├── PlaylistListSkeleton.swift  # NEW: content-matched skeleton rows
│   │   ├── PlaylistDetailView.swift    # Modified: skeleton state replaces ProgressView
│   │   └── PlaylistDetailSkeleton.swift # NEW: content-matched skeleton rows
│   └── Settings/
│       ├── SettingsView.swift      # Modified: restructured sections + icons
│       ├── RunDefaultsView.swift   # NEW: sub-page for zones + no-BPM tracks
│       ├── ZoneSettingsRow.swift   # Unchanged, reused in sub-page
│       └── SensorLabView.swift    # Unchanged
```

### Pattern 1: ShimmerModifier (Reusable ViewModifier)
**What:** A ViewModifier that overlays an animated gradient sweep on any shape
**When to use:** Apply to any placeholder shape that needs shimmer
**Example:**
```swift
struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = -1

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    LinearGradient(
                        colors: [.clear, Color(white: 0.23), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geometry.size.width * 0.4)
                    .offset(x: geometry.size.width * phase)
                }
                .clipped()
            )
            .onAppear {
                withAnimation(
                    .linear(duration: 1.2)
                    .repeatForever(autoreverses: false)
                ) {
                    phase = 1.4
                }
            }
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}
```

### Pattern 2: Content-Matched Skeleton View
**What:** A skeleton component that mirrors the real content layout with placeholder shapes
**When to use:** Each view with async loading gets its own skeleton that matches its row structure
**Example:**
```swift
struct PlaylistRowSkeleton: View {
    var body: some View {
        HStack(spacing: Spacing.md) {
            // Cover art placeholder
            RoundedRectangle(cornerRadius: Radius.sm)
                .fill(Color(white: 0.165))  // #2A2A2A
                .frame(width: ComponentSize.coverArtMedium,
                       height: ComponentSize.coverArtMedium)

            VStack(alignment: .leading, spacing: Spacing.xs) {
                // Title line
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color(white: 0.165))
                    .frame(width: 140, height: 14)
                // Subtitle line
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color(white: 0.165))
                    .frame(width: 80, height: 11)
                // Coverage bar
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color(white: 0.165))
                    .frame(height: 4)
            }
        }
        .frame(height: 70)  // Match PlaylistRow height
        .shimmer()
    }
}
```

### Pattern 3: Skeleton-to-Content Crossfade
**What:** Use BSAnimation.smooth transition when swapping skeleton for real content
**When to use:** At the loading state branch in each view
**Example:**
```swift
Group {
    if isLoading && playlists.isEmpty {
        PlaylistListSkeleton()
    } else {
        playlistList
    }
}
.animation(BSAnimation.smooth, value: isLoading)
```

### Pattern 4: Settings Section with SF Symbol Header
**What:** Grouped inset List sections with icon-decorated headers
**When to use:** SettingsView restructuring
**Example:**
```swift
Section {
    // section content
} header: {
    Label("Account", systemImage: "person.circle")
        .foregroundStyle(Color.accent)
        .font(.captionBold)
}
```

### Pattern 5: Dynamic Version from Bundle
**What:** Read CFBundleShortVersionString at runtime
**When to use:** Replace hardcoded "v1.4" in About section
**Example:**
```swift
let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
Text("BeatStep v\(version) (\(build))")
```

### Anti-Patterns to Avoid
- **Animating skeleton rows individually:** All rows should share one animation phase via the ShimmerModifier; individual timers cause visual chaos
- **Using .redacted(reason: .placeholder):** SwiftUI's built-in redaction doesn't support gradient shimmer and looks generic; custom shapes are better for content-matching (D-02)
- **Hardcoding skeleton row count:** Use a fixed count (6-8 per D-04) but derive from available height if possible; simpler to hardcode 7

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Settings grouped layout | Custom card views | `.listStyle(.insetGrouped)` | Native iOS pattern, handles dark mode, dynamic type, accessibility |
| Navigation to sub-page | Custom push/pop logic | `NavigationLink` with chevron | Already used for SensorLabView; consistent behavior |
| Version string | Hardcoded constant | `Bundle.main.infoDictionary` | Auto-updates with build; no manual maintenance |
| Gradient animation | CADisplayLink or Timer | SwiftUI `.animation(.linear.repeatForever)` | Declarative, no manual cleanup |

## Common Pitfalls

### Pitfall 1: Shimmer Animation Not Starting
**What goes wrong:** The gradient offset animation doesn't trigger because `onAppear` fires before the view is visible
**Why it happens:** SwiftUI may call `onAppear` before layout is complete; `@State` initial value may not trigger animation
**How to avoid:** Set initial phase to a negative value (-1.0) and animate to a value past 1.0 (e.g., 1.4) so the gradient sweeps fully across
**Warning signs:** Static grey shapes with no movement

### Pitfall 2: Skeleton Layout Shift
**What goes wrong:** Content "jumps" when real data replaces skeleton because dimensions don't match
**Why it happens:** Skeleton shapes don't match real row dimensions
**How to avoid:** Use exact same frame sizes from PlaylistRow (height: 70, coverArtMedium: 56) and TrackRow layout; this is why D-02 mandates content-matched shapes
**Warning signs:** Visible flicker or repositioning when data loads

### Pitfall 3: List Style Mismatch After Settings Restructure
**What goes wrong:** Settings sections look different from the rest of the app
**Why it happens:** Switching to `.insetGrouped` changes padding and background behavior
**How to avoid:** The rest of the app uses `.plain` list style; Settings using `.insetGrouped` is intentional and correct for a settings screen. Ensure background color matches `Color.surfaceBase`
**Warning signs:** White/light background bleeding through on section cards

### Pitfall 4: Disconnect Button Placement
**What goes wrong:** Destructive "Disconnect Spotify" action is too easy to accidentally tap
**Why it happens:** Placing it inline with other Account rows
**How to avoid:** Keep it at the bottom of the Account section with `.destructive` role; confirmation alert is recommended but not required by CONTEXT.md
**Warning signs:** User feedback about accidental disconnects

### Pitfall 5: Version Hardcoding Regression
**What goes wrong:** Future developers hardcode version again
**Why it happens:** Current code has `"BeatStep v1.4"` hardcoded
**How to avoid:** Use Bundle.main lookup and add a code comment explaining why
**Warning signs:** Version string doesn't match Xcode project version

## Code Examples

### SF Symbol Recommendations for Settings Sections
```swift
// Account
Label("Account", systemImage: "person.circle")

// Run Defaults
Label("Run Defaults", systemImage: "figure.run")

// Permissions
Label("Permissions", systemImage: "lock.shield")

// Debug (only when sensorLabEnabled)
Label("Debug", systemImage: "wrench.and.screwdriver")

// About
Label("About", systemImage: "info.circle")
```

### Current Loading State Replacement Points

PlaylistListView line 69-71:
```swift
// REPLACE THIS:
if isLoading && playlists.isEmpty {
    ProgressView("Loading playlists...")
        .frame(maxWidth: .infinity, maxHeight: .infinity)
}
// WITH skeleton view
```

PlaylistDetailView line 22-24:
```swift
// REPLACE THIS:
if isLoading && tracks.isEmpty {
    ProgressView("Loading tracks...")
        .frame(maxWidth: .infinity, maxHeight: .infinity)
}
// WITH skeleton view
```

### Settings Section Restructure Map
Current SettingsView has these sections (in order): Account, Running Zones, Playback, Permissions, Disconnect (standalone), Sensor Lab (conditional), Version footer.

Target structure:
1. **Account** -- Name, Plan, Disconnect Spotify (destructive, bottom of section)
2. **Run Defaults** -- NavigationLink to RunDefaultsView (contains zones + no-BPM picker)
3. **Permissions** -- Motion Access, Apple Health, Open Settings button
4. **Debug** -- Sensor Lab NavigationLink (when `sensorLabEnabled`)
5. **About** -- Dynamic version, hidden 5-tap debug toggle

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `.redacted(reason: .placeholder)` | Custom skeleton shapes + shimmer | iOS 15+ | Better visual fidelity, matches app branding |
| Timer-based shimmer | `withAnimation(.repeatForever)` | SwiftUI from iOS 14 | Cleaner lifecycle, no Timer cleanup needed |
| `.listStyle(.grouped)` | `.listStyle(.insetGrouped)` | iOS 14+ | Rounded section cards, more modern look |

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | XCTest (built-in) |
| Config file | BeatStepTests target in Xcode project |
| Quick run command | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BeatStepTests` |
| Full suite command | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16'` |

### Phase Requirements to Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| POL-04 | Settings sections structured correctly (5 groups) | manual | Visual inspection in Simulator | N/A |
| POL-04 | Dynamic version reads from Bundle | unit | `xcodebuild test ... -only-testing:BeatStepTests/SettingsTests` | Wave 0 |
| POL-03 | ShimmerModifier produces animation | unit | `xcodebuild test ... -only-testing:BeatStepTests/SkeletonTests` | Wave 0 |
| POL-03 | Skeleton row count fills visible area | manual | Visual inspection in Simulator | N/A |

### Wave 0 Gaps
- [ ] `BeatStepTests/SettingsTests.swift` -- covers dynamic version string, section structure logic
- [ ] `BeatStepTests/SkeletonTests.swift` -- covers shimmer modifier existence, skeleton row dimensions match real rows

Note: Most validation for this phase is visual (correct layout, shimmer animation, section grouping). Unit tests can verify data logic (version string, skeleton dimensions) but the visual polish is manual-only.

## Open Questions

1. **POL-03 and POL-04 formal definitions**
   - What we know: These requirement IDs are referenced in ROADMAP.md but not formally defined in REQUIREMENTS.md
   - What's unclear: Exact formal requirement text
   - Recommendation: Infer from roadmap success criteria; POL-03 = skeleton loading states, POL-04 = organized settings screen. Add to REQUIREMENTS.md during planning.

## Sources

### Primary (HIGH confidence)
- Project source code: SettingsView.swift, PlaylistListView.swift, PlaylistDetailView.swift, DesignTokens.swift, BSAnimation.swift
- CONTEXT.md decisions: D-01 through D-11 define all implementation constraints

### Secondary (MEDIUM confidence)
- SwiftUI LinearGradient and animation APIs: standard iOS framework, well-documented by Apple
- `.insetGrouped` List style: standard iOS pattern since iOS 14

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - pure SwiftUI, no external dependencies, all patterns visible in existing codebase
- Architecture: HIGH - existing codebase patterns (Section, NavigationLink, design tokens) directly apply
- Pitfalls: HIGH - common SwiftUI animation issues, well-documented

**Research date:** 2026-03-26
**Valid until:** 2026-04-26 (stable SwiftUI patterns, no fast-moving dependencies)
