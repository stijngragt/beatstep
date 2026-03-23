# Phase 7: Tab Navigation Shell - Research

**Researched:** 2026-03-23
**Domain:** SwiftUI TabView, NavigationStack, tab bar customization, MiniPlayer positioning
**Confidence:** HIGH

## Summary

Phase 7 restructures the app from a single-NavigationStack layout to a TabView with three tabs (Library, Run, Settings), each maintaining independent navigation state. The existing ContentView uses a ZStack with NavigationStack + MiniPlayerView overlay -- this becomes a TabView where each tab wraps its own NavigationStack. The MiniPlayer moves from per-view overlay to a persistent safeAreaInset on the TabView container.

All required APIs (TabView, NavigationStack, UITabBarAppearance, safeAreaInset) are stable in iOS 17.0, which is the project's deployment target. No new dependencies are needed -- this is purely first-party SwiftUI and UIKit appearance APIs.

**Primary recommendation:** Use SwiftUI TabView with NavigationStack inside each tab (never wrap TabView in NavigationStack). Apply UITabBarAppearance in an init() block for blur/material styling. Position MiniPlayer via safeAreaInset(edge: .bottom) on the ZStack wrapping the TabView.

<user_constraints>

## User Constraints (from CONTEXT.md)

### Locked Decisions
- Library tab icon: `music.note.list`, Run: `waveform.path.ecg`, Settings: `gearshape`
- Selected state: `.fill` variant, unselected: outline
- Selected tint: accent color (#FF4545 / Color.accent)
- Unselected tint: textTertiary (white at 35% opacity / Color.textTertiary)
- Labels shown below icons ("Library", "Run", "Settings")
- Translucent blur background (.ultraThinMaterial)
- No separator line between content and tab bar
- Run tab default: centered "Start Run" CTA button (accent-filled pill/rounded)
- Run tab active: embed existing RunView directly
- No playlist context on Run tab (deferred to Phase 8 NAV-04)

### Claude's Discretion
- MiniPlayer positioning relative to tab bar (safeAreaInset approach)
- NavigationStack per tab implementation details
- Start Run button exact sizing and padding
- Tab bar height and safe area handling
- How to restructure ContentView from single NavigationStack to TabView

### Deferred Ideas (OUT OF SCOPE)
None -- discussion stayed within phase scope

</user_constraints>

<phase_requirements>

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| NAV-01 | Bottom tab bar with three tabs: Library, Run, Settings | TabView with .tabItem modifier, UITabBarAppearance for styling |
| NAV-02 | Each tab maintains its own navigation state (NavigationStack per tab) | NavigationStack inside each Tab child view, not wrapping TabView |
| NAV-03 | MiniPlayer persists across all tabs via safeAreaInset | safeAreaInset(edge: .bottom) on outer ZStack wrapping TabView |

</phase_requirements>

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| SwiftUI TabView | iOS 17+ | Tab-based navigation container | First-party, stable, matches project's zero-dependency constraint |
| SwiftUI NavigationStack | iOS 16+ | Per-tab navigation with back stack | Required for independent nav state per tab |
| UITabBarAppearance | iOS 15+ | Tab bar visual customization | Only way to set blur material + tint on native tab bar |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| UIBlurEffect (via UITabBarAppearance) | iOS 15+ | Background blur for tab bar | Setting .ultraThinMaterial equivalent on UIKit tab bar |
| safeAreaInset | iOS 15+ | Reserve space for MiniPlayer | Ensures scrollable content doesn't hide behind MiniPlayer |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Native TabView | Custom tab bar | Fragile across iOS versions, out of scope per REQUIREMENTS.md |
| UITabBarAppearance | SwiftUI .toolbarBackground | Less control over blur material type, no separator removal |
| tabViewBottomAccessory | safeAreaInset | tabViewBottomAccessory requires iOS 26, project targets iOS 17 |

**Installation:** No new dependencies. All APIs are first-party.

## Architecture Patterns

### Recommended Project Structure
```
BeatStep/
├── App/
│   ├── BeatStepApp.swift          # Unchanged
│   └── ContentView.swift          # Major restructure: TabView container
├── Views/
│   ├── Library/
│   │   └── PlaylistListView.swift # Unchanged (Library tab root)
│   ├── Run/
│   │   ├── RunView.swift          # Unchanged (embedded in Run tab when active)
│   │   └── RunTabView.swift       # NEW: Run tab root with Start Run CTA / RunView toggle
│   ├── Settings/
│   │   └── SettingsView.swift     # Unchanged (Settings tab root)
│   └── Player/
│       └── MiniPlayerView.swift   # Unchanged (repositioned via safeAreaInset)
```

### Pattern 1: NavigationStack Inside TabView (Not Outside)
**What:** Each tab contains its own NavigationStack. TabView is the outermost navigation container.
**When to use:** Always. This is the only correct architecture for independent tab navigation.
**Example:**
```swift
// CORRECT: NavigationStack inside each tab
TabView {
    NavigationStack {
        PlaylistListView()
    }
    .tabItem {
        Label("Library", systemImage: "music.note.list")
    }

    NavigationStack {
        RunTabView()
    }
    .tabItem {
        Label("Run", systemImage: "waveform.path.ecg")
    }

    NavigationStack {
        SettingsView()
    }
    .tabItem {
        Label("Settings", systemImage: "gearshape")
    }
}

// WRONG: NavigationStack wrapping TabView -- breaks per-tab state
NavigationStack {
    TabView { ... }
}
```

### Pattern 2: Tab Bar Appearance via UITabBarAppearance
**What:** Configure tab bar blur, tint, and separator via UIKit appearance API in SwiftUI.
**When to use:** For translucent blur background, custom tint colors, separator removal.
**Example:**
```swift
// In ContentView init() or .onAppear
init() {
    let appearance = UITabBarAppearance()
    appearance.configureWithDefaultBackground()
    // Apply blur effect matching .ultraThinMaterial
    appearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterial)
    // Remove separator line
    appearance.shadowColor = .clear
    // Apply to both states
    UITabBar.appearance().standardAppearance = appearance
    UITabBar.appearance().scrollEdgeAppearance = appearance
    // Tint colors
    UITabBar.appearance().tintColor = UIColor(Color.accent)
    UITabBar.appearance().unselectedItemTintColor = UIColor(Color.textTertiary)
}
```

### Pattern 3: MiniPlayer via safeAreaInset on Outer Container
**What:** Position MiniPlayer above the tab bar using safeAreaInset on a ZStack wrapping TabView.
**When to use:** For persistent overlay that must be visible across all tabs without duplication.
**Example:**
```swift
ZStack(alignment: .bottom) {
    TabView {
        // tabs...
    }
    .safeAreaInset(edge: .bottom) {
        if SpotifyPlayerService.shared.currentTrack != nil {
            MiniPlayerView()
        }
    }
}
```
**Key insight:** safeAreaInset on the TabView itself pushes content up, ensuring scrollable lists don't hide behind the MiniPlayer. The MiniPlayer renders above the tab bar because safeAreaInset stacks on top of the tab bar's safe area.

### Pattern 4: Run Tab with Conditional Content
**What:** A new RunTabView shows either a "Start Run" CTA or the active RunView.
**When to use:** The Run tab needs two states -- idle (prompt to start) and active (running).
**Example:**
```swift
struct RunTabView: View {
    private var runEngine: RunEngineService { .shared }

    var body: some View {
        if runEngine.isRunActive {
            RunView(playlist: runEngine.currentPlaylist!,
                    tracks: runEngine.currentTracks!)
        } else {
            // Centered Start Run CTA
            VStack {
                Spacer()
                Button { /* navigate or start */ } label: {
                    Text("Start Run")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(Color.textOnAccent)
                        .frame(width: 200, height: ComponentSize.buttonHeight)
                        .background(Capsule().fill(Color.accent))
                }
                Spacer()
            }
        }
    }
}
```

### Anti-Patterns to Avoid
- **NavigationStack wrapping TabView:** Breaks per-tab navigation state preservation. User switches tabs and loses their position.
- **Embedding MiniPlayer inside each tab:** Creates duplication, inconsistent state, and visual glitches during tab transitions.
- **Using .tint() modifier on TabView:** Only controls selected color. Does not control unselected color -- need UITabBar.appearance().unselectedItemTintColor for that.
- **Removing MiniPlayer from RunView but not from other places:** RunView currently embeds its own MiniPlayerView (line 34 of RunView.swift). When MiniPlayer moves to the global container, it must be removed from RunView to avoid double rendering.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Tab bar UI | Custom HStack tab bar | Native TabView + UITabBarAppearance | REQUIREMENTS.md explicitly marks custom tab bar as out of scope; native handles accessibility, animation, safe area |
| Tab bar blur | Custom .background(.ultraThinMaterial) on HStack | UITabBarAppearance.backgroundEffect | Native respects system behaviors, scroll edge, and landscape modes |
| Per-tab navigation | Custom navigation state management | NavigationStack per tab | Automatic back stack, swipe-back gesture, title management |
| Safe area handling | Manual frame calculations for MiniPlayer offset | safeAreaInset(edge: .bottom) | Automatically adjusts for all content including scrollable views |

**Key insight:** The entire tab navigation shell uses zero custom components. Native TabView + UITabBarAppearance + safeAreaInset covers every requirement.

## Common Pitfalls

### Pitfall 1: NavigationStack Outside TabView
**What goes wrong:** Navigation state is shared across all tabs. Pushing a detail view in Library and switching to Run, then back to Library -- the detail view is gone.
**Why it happens:** A single NavigationStack manages one path. TabView children share it.
**How to avoid:** Always place NavigationStack INSIDE each tab child.
**Warning signs:** Tab switching resets navigation depth to root.

### Pitfall 2: scrollEdgeAppearance Not Set
**What goes wrong:** Tab bar becomes fully transparent when scrollable content doesn't reach the bottom (e.g., short lists). Visual inconsistency.
**Why it happens:** iOS 15+ uses separate appearances for "at scroll edge" vs "scrolled". If scrollEdgeAppearance is nil, iOS uses the default transparent look.
**How to avoid:** Always set both `standardAppearance` and `scrollEdgeAppearance` to the same UITabBarAppearance instance.
**Warning signs:** Tab bar looks correct on long lists but transparent on short lists.

### Pitfall 3: MiniPlayer Rendered Twice
**What goes wrong:** MiniPlayer appears both in the global safeAreaInset AND inside RunView.
**Why it happens:** RunView.swift line 34 currently embeds `MiniPlayerView()` directly inside the view.
**How to avoid:** Remove `MiniPlayerView()` from RunView when it moves to the global container. The global safeAreaInset handles it for all tabs.
**Warning signs:** Two MiniPlayers stacked on screen when RunView is active.

### Pitfall 4: Tab Bar Tint Not Applied to Unselected State
**What goes wrong:** Unselected tab icons remain system gray instead of white at 35% opacity.
**Why it happens:** SwiftUI's `.tint()` modifier only affects the selected state. The unselected state requires UIKit's `UITabBar.appearance().unselectedItemTintColor`.
**How to avoid:** Set both `tintColor` and `unselectedItemTintColor` on UITabBar.appearance().
**Warning signs:** Unselected icons are wrong color.

### Pitfall 5: Settings Toolbar Gear Icon Still Shows
**What goes wrong:** After adding Settings as its own tab, the gear icon still appears in the Library toolbar.
**Why it happens:** ContentView still has the `.toolbar { ToolbarItem }` with the Settings NavigationLink.
**How to avoid:** Remove the toolbar item from PlaylistListView/ContentView when Settings becomes a tab.
**Warning signs:** Duplicate navigation paths to Settings.

### Pitfall 6: .fill Variant Icon Names Wrong
**What goes wrong:** Selected tab icons show outline instead of fill, or crash with missing SF Symbol.
**Why it happens:** Not all SF Symbols follow the `name.fill` naming convention. Need to verify each icon name.
**How to avoid:** Verified names: `music.note.list` (no fill variant available -- stays the same), `waveform.path.ecg` (no fill variant), `gearshape` / `gearshape.fill` (fill exists). For icons without fill variants, use the same icon for both states -- the tint color differentiates.
**Warning signs:** Missing icon (shows empty space) or warning in console.

## Code Examples

### Complete ContentView Restructure
```swift
// Source: Verified pattern from Apple developer docs + project context
struct ContentView: View {
    @Environment(SpotifyAuthService.self) private var authService

    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterial)
        appearance.shadowColor = .clear  // Remove separator
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
        UITabBar.appearance().tintColor = UIColor(Color.accent)
        UITabBar.appearance().unselectedItemTintColor = UIColor(Color.textTertiary)
    }

    var body: some View {
        Group {
            if authService.isAuthenticated {
                authenticatedView
            } else {
                LoginView()
            }
        }
        .onAppear {
            AudioSessionService.shared.setupAudioSession()
            SpotifyAuthService.shared.checkExistingAuth()
        }
    }

    private var authenticatedView: some View {
        TabView {
            NavigationStack {
                PlaylistListView()
            }
            .tabItem {
                Label("Library", systemImage: "music.note.list")
            }

            NavigationStack {
                RunTabView()
            }
            .tabItem {
                Label("Run", systemImage: "waveform.path.ecg")
            }

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape")
            }
        }
        .safeAreaInset(edge: .bottom) {
            if SpotifyPlayerService.shared.currentTrack != nil {
                MiniPlayerView()
            }
        }
        .task {
            await LibraryScanService.shared.scanEnabledPlaylists()
        }
    }
}
```

### RunTabView (New File)
```swift
struct RunTabView: View {
    private var runEngine: RunEngineService { .shared }

    var body: some View {
        Group {
            if runEngine.isRunActive {
                // Embed existing RunView -- reuse what's built
                RunView(playlist: runEngine.currentPlaylist!,
                        tracks: runEngine.currentTracks!)
            } else {
                startRunPrompt
            }
        }
        .navigationTitle("Run")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var startRunPrompt: some View {
        VStack {
            Spacer()
            Button {
                // Start run flow -- specifics TBD by planner
            } label: {
                Text("Start Run")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Color.textOnAccent)
                    .padding(.horizontal, Spacing.xl)
                    .padding(.vertical, Spacing.md)
                    .background(Capsule().fill(Color.accent))
            }
            Spacer()
        }
    }
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| NavigationView | NavigationStack | iOS 16 (2022) | Project already uses NavigationStack -- no migration needed |
| TabView { Tab(...) } syntax | TabView { view.tabItem {} } | iOS 18 introduced Tab type | Use .tabItem{} syntax for iOS 17 compatibility |
| tabViewBottomAccessory | safeAreaInset | iOS 26 (2025) | Not available at iOS 17 target; use safeAreaInset instead |

**Deprecated/outdated:**
- `NavigationView`: Replaced by NavigationStack in iOS 16. Project already uses NavigationStack.
- `.tabViewStyle(.automatic)`: Default, no need to specify.

## Open Questions

1. **RunView currently requires playlist and tracks parameters**
   - What we know: RunView takes `let playlist: SpotifyPlaylist` and `let tracks: [SpotifyTrack]` -- it cannot be instantiated without them
   - What's unclear: How RunTabView accesses these when transitioning from idle to active state
   - Recommendation: RunEngineService likely needs `currentPlaylist` and `currentTracks` properties (check if they exist). If not, the Run tab "Start Run" button may need to navigate to Library first to select a playlist. Planner should determine this flow.

2. **SF Symbol fill variants for Library and Run icons**
   - What we know: `music.note.list` and `waveform.path.ecg` do not have `.fill` variants in SF Symbols
   - What's unclear: Whether the user's intent for ".fill variant" applies only to icons that have one (gearshape)
   - Recommendation: Use the same icon for both states for Library and Run; tint color alone differentiates selected/unselected. Only gearshape gets the fill/outline toggle.

3. **MiniPlayer removal from RunView**
   - What we know: RunView embeds MiniPlayerView() directly (line 34). Global safeAreaInset will add it everywhere.
   - What's unclear: Whether RunView's embedded MiniPlayer serves any special purpose vs the global one
   - Recommendation: Remove it from RunView. The global MiniPlayer is identical.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | XCTest (built-in) |
| Config file | BeatStepTests target in Xcode project |
| Quick run command | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BeatStepTests 2>&1 \| tail -20` |
| Full suite command | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 \| tail -40` |

### Phase Requirements to Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| NAV-01 | Three tabs render with correct icons and labels | manual-only | Visual verification in simulator | N/A |
| NAV-02 | Per-tab navigation state preserved across tab switches | manual-only | Navigate deep, switch tabs, verify state | N/A |
| NAV-03 | MiniPlayer visible across all tabs | manual-only | Play track, switch between all tabs | N/A |

**Manual-only justification:** All three requirements are UI navigation behaviors. SwiftUI TabView rendering, tab switching state preservation, and safeAreaInset overlay positioning cannot be meaningfully tested via XCTest unit tests. They require simulator/device visual verification. The project's existing test suite is service-layer focused (BPMCacheService, SpotifyAuth, RunEngine, etc.) -- no UI tests exist.

### Sampling Rate
- **Per task commit:** Build succeeds: `xcodebuild build -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | tail -5`
- **Per wave merge:** Full test suite green + manual tab navigation walkthrough
- **Phase gate:** Full suite green + all three tabs navigable with MiniPlayer visible

### Wave 0 Gaps
None -- no new test files needed. Phase 7 requirements are structural UI changes verified by compilation + manual testing. Existing test suite must remain green (no regressions).

## Sources

### Primary (HIGH confidence)
- Project source code: ContentView.swift, RunView.swift, MiniPlayerView.swift, DesignTokens.swift, BeatStepApp.swift -- direct inspection
- Project config: IPHONEOS_DEPLOYMENT_TARGET = 17.0 from project.pbxproj
- [Apple TabView Documentation](https://developer.apple.com/documentation/swiftui/tabview) -- TabView API reference
- [Apple tabViewBottomAccessory](https://developer.apple.com/documentation/swiftui/view/tabviewbottomaccessory(isenabled:content:)) -- confirmed iOS 26+ only

### Secondary (MEDIUM confidence)
- [Hacking with Swift - TabView](https://www.hackingwithswift.com/books/ios-swiftui/creating-tabs-with-tabview-and-tabitem) -- NavigationStack-inside-TabView pattern
- [Big Mountain Studio - TabView Customization 2024](https://www.bigmountainstudio.com/community/public/posts/86559-how-to-customize-the-tabview-in-swiftui-in-2024) -- UITabBarAppearance configuration
- [Swift with Majid - Safe Area](https://swiftwithmajid.com/2021/11/03/managing-safe-area-in-swiftui/) -- safeAreaInset usage
- [CreateWithSwift - safeAreaInset](https://www.createwithswift.com/placing-ui-components-within-the-safe-area-inset/) -- MiniPlayer positioning pattern
- [Better Programming - TabView Behaviour](https://betterprogramming.pub/swiftui-navigation-stack-and-ideal-tab-view-behaviour-e514cc41a029) -- per-tab NavigationStack state preservation

### Tertiary (LOW confidence)
- SF Symbol fill variant availability for `music.note.list` and `waveform.path.ecg` -- based on training knowledge, should be verified in SF Symbols app

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- all APIs are first-party iOS 17+, verified via Apple docs
- Architecture: HIGH -- NavigationStack-in-TabView pattern is well-documented and widely used
- Pitfalls: HIGH -- identified from direct source code inspection (RunView MiniPlayer duplication, toolbar gear icon)
- Tab bar styling: HIGH -- UITabBarAppearance is the standard approach, verified across multiple sources
- SF Symbol names: MEDIUM -- fill variants need verification in SF Symbols app on device

**Research date:** 2026-03-23
**Valid until:** 2026-04-23 (stable APIs, no expected changes)
