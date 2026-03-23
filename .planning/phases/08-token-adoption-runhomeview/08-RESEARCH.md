# Phase 8: Token Adoption + RunHomeView - Research

**Researched:** 2026-03-23
**Domain:** SwiftUI design token migration, view state management
**Confidence:** HIGH

## Summary

Phase 8 has two distinct workstreams: (1) migrating all hardcoded colors, fonts, and spacing in existing views to the design tokens defined in `DesignTokens.swift`, and (2) building a useful Run tab landing screen that shows last-used playlist context (NAV-04).

The token migration is mechanical but extensive. A full audit reveals approximately 80 hardcoded color references across 11 view files. The most heavily affected files are `RunView.swift` (~30 references), `PlaylistDetailView.swift` (~20), and `PlaylistListView.swift` (~10). There are also hardcoded font values (`.font(.system(size:...))`) and spacing values (`.padding(.horizontal, 32)`) that should use token equivalents. The `LoginView.swift` has a local `spotifyGreen` constant that duplicates `Color.spotifyBrand` from the token file.

The RunHomeView (NAV-04) requires persisting a "last used playlist" reference via UserDefaults and displaying it on the Run tab. The current `RunTabView.swift` is a stub with a placeholder CTA. No persistence mechanism exists yet for last-used playlist data.

**Primary recommendation:** Split into two plans -- Plan 1 for full token migration across all views (DS-04), Plan 2 for RunTabView enhancement with last-used playlist (NAV-04). This allows the token migration to be verified independently with a grep-based success criteria before building new UI.

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| DS-04 | All existing views migrated from hardcoded colors to design tokens | Full audit of 80+ hardcoded references across 11 view files completed; mapping table provided below |
| NAV-04 | Run tab shows last-used playlist context when available, otherwise prompts to select a playlist | UserDefaults persistence pattern identified; RunTabView stub ready for enhancement |
</phase_requirements>

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| SwiftUI | iOS 17+ | All views | Already in use, project standard |
| Foundation (UserDefaults) | iOS 17+ | Last-used playlist persistence | Already used for RunMode/BPMTolerance persistence |

### Supporting
No new dependencies. All work uses existing `DesignTokens.swift` definitions and first-party Apple APIs per project decision.

## Architecture Patterns

### Token Mapping Reference

The following mapping table defines how every hardcoded color maps to a design token:

| Hardcoded | Token Replacement | Notes |
|-----------|------------------|-------|
| `.white` | `Color.textPrimary` | For text on dark backgrounds |
| `.white.opacity(0.5)` / `.white.opacity(0.6)` | `Color.textSecondary` | Secondary text (token is 0.55 opacity) |
| `.white.opacity(0.3)` / `.white.opacity(0.35)` | `Color.textTertiary` | Tertiary text (token is 0.35 opacity) |
| `.white.opacity(0.2)` | `Color.textTertiary` | Very faint text, closest token |
| `.white.opacity(0.4)` | `Color.textTertiary` | Dimmed text |
| `Color.black` | `Color.surfaceBase` | Background surfaces |
| `.black` (foreground) | Evaluate context: `Color.surfaceBase` or keep for contrast-on-accent | |
| `.secondary` | `Color.textSecondary` | SwiftUI semantic color to explicit token |
| `.primary` | `Color.textPrimary` | SwiftUI semantic color to explicit token |
| `.green` | `Color.stateSuccess` | Trend indicators, "speeding up" |
| `.green` (Start Run button fill) | `Color.stateSuccess` | Start action |
| `.orange` | `Color.stateWarning` | BPM badges, "slowing down" trend, coverage text |
| `.orange.opacity(0.15)` | `Color.stateWarning.opacity(0.15)` | BPM badge background |
| `.orange.opacity(0.8)` | `Color.stateWarning.opacity(0.8)` | Cool down button |
| `.red` / `.red.opacity(0.8)` | `Color.stateError` / `Color.stateError.opacity(0.8)` | Error text, stop button |
| `Color.red.opacity(0.08)` | `Color.stateError.opacity(0.08)` | Error background |
| `Color.gray.opacity(0.3)` | `Color.surfaceOverlay` | Placeholder artwork backgrounds |
| `Color.gray.opacity(0.15)` | `Color.surfaceElevated` | BPM badge background in MiniPlayer |
| `.gray` | `Color.textTertiary` | Placeholder icons |
| `spotifyGreen` (local) | `Color.spotifyBrand` | LoginView local constant elimination |
| `Color.white.opacity(0.25)` / `0.08` (PacePresetPicker) | `Color.surfaceOverlay` / `Color.surfaceElevated` | Picker pill backgrounds |

### Font Mapping Reference

| Hardcoded | Token Replacement |
|-----------|------------------|
| `.system(size: 76, weight: .bold, design: .monospaced)` | `Font.displayHero` (52pt rounded) -- evaluate if 76pt needs a new token or is intentional override |
| `.system(size: 28, weight: .semibold)` | `Font.heading` (22pt bold) -- close match |
| `.system(size: 32, weight: .semibold)` | `Font.heading` -- paused state |
| `.system(size: 48, weight: .bold, design: .monospaced)` | `Font.displayHero` scaled down -- or keep as intentional override |
| `.system(size: 42, weight: .bold, design: .rounded)` | `Font.displayHero` -- LoginView app name |
| `.system(size: 60)` (icon) | Keep as-is -- icon sizing, not text token |
| `.system(size: 14, weight: .bold, design: .monospaced)` | `Font.captionBold` -- MiniPlayer BPM |
| `.system(size: 8, weight: .medium)` | `Font.labelText` (11pt) -- closest match, or keep small |
| `.font(.body)` | `.font(.bodyText)` |
| `.font(.subheadline)` | `.font(.captionText)` or `.font(.bodyText)` depending on context |
| `.font(.caption)` | `.font(.captionText)` |
| `.font(.caption2)` | `.font(.labelText)` |
| `.font(.callout)` | `.font(.bodyText)` |
| `.font(.title2)` | `.font(.heading)` |
| `.font(.title3)` | `.font(.subheading)` |
| `.font(.headline)` | `.font(.bodyBold)` |

### Spacing Mapping Reference

| Hardcoded | Token Replacement |
|-----------|------------------|
| `.padding(.horizontal, 32)` | `.padding(.horizontal, Spacing.xl)` |
| `.padding(.horizontal, 40)` | `.padding(.horizontal, Spacing.xl)` (closest) or `Spacing.xxl` minus adjust |
| `.padding(.horizontal, 24)` | `.padding(.horizontal, Spacing.lg)` |
| `.padding(.horizontal, 16)` | `.padding(.horizontal, Spacing.md)` |
| `.padding(.vertical, 16)` | `.padding(.vertical, Spacing.md)` |
| `.padding(.vertical, 14)` | `.padding(.vertical, Spacing.md)` (closest) |
| `.padding(.vertical, 12)` | `.padding(.vertical, Spacing.md)` |
| `.padding(.vertical, 10)` | `.padding(.vertical, Spacing.sm)` |
| `.padding()`  / `.padding()` | Keep as-is (SwiftUI default) or use `Spacing.md` |
| `spacing: 12` | `Spacing.md` (closest at 16) or keep 12 |
| `spacing: 16` | `Spacing.md` |
| `spacing: 24` | `Spacing.lg` |
| `spacing: 32` | `Spacing.xl` |
| `spacing: 20` | `Spacing.lg` (closest) |
| `cornerRadius: 6` | `Radius.sm` |
| `cornerRadius: 8` | `Radius.sm` (closest) or `Radius.md` |
| `cornerRadius: 12` | `Radius.md` |
| `cornerRadius: 28` | `Radius.pill` |
| `.frame(width: 44, height: 44)` | `ComponentSize.coverArtSmall` |
| `.frame(width: 200, height: 200)` | `ComponentSize.coverArtLarge` |
| `.frame(width: 52, height: 44)` | Keep or define new component token |

### Pattern: Last-Used Playlist Persistence (NAV-04)

**What:** Store the last playlist used for a run in UserDefaults so RunTabView can display it on next launch.
**When to use:** When user starts a run from PlaylistDetailView.

```swift
// Pattern follows existing RunMode/BPMTolerance persistence style
enum LastRunPlaylist {
    private static let nameKey = "beatstep_last_run_playlist_name"
    private static let idKey = "beatstep_last_run_playlist_id"
    private static let imageURLKey = "beatstep_last_run_playlist_image"

    static var name: String? {
        get { UserDefaults.standard.string(forKey: nameKey) }
        set { UserDefaults.standard.set(newValue, forKey: nameKey) }
    }

    static var id: String? {
        get { UserDefaults.standard.string(forKey: idKey) }
        set { UserDefaults.standard.set(newValue, forKey: idKey) }
    }

    static var imageURL: String? {
        get { UserDefaults.standard.string(forKey: imageURLKey) }
        set { UserDefaults.standard.set(newValue, forKey: imageURLKey) }
    }
}
```

**Save point:** In `RunView` when a run starts (the `Task { await runEngine.startRun(...) }` call).
**Read point:** In `RunTabView` on appear.

### Anti-Patterns to Avoid
- **Mapping .secondary to textTertiary:** SwiftUI `.secondary` is closer to `textSecondary` (55% opacity), not tertiary (35%). Check each usage contextually.
- **Over-tokenizing icon sizes:** SF Symbol font sizes for icons are layout, not typography. Keep `.font(.system(size: 48))` for icons unless a component size token fits.
- **Breaking opacity semantics:** `.white.opacity(0.2)` in pausedView is intentionally very faint for "ghost" text. Using `textTertiary` (0.35) may be too visible. Evaluate visually.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Color consistency | Individual color definitions per view | `DesignTokens.swift` extensions | Single source of truth, already defined |
| Playlist persistence | Codable model + file storage | UserDefaults with string keys | Matches existing project pattern (RunMode, BPMTolerance), only 3 values needed |
| Token validation | Manual visual inspection | Grep-based verification script | Success criteria requires zero hardcoded colors outside token files |

## Common Pitfalls

### Pitfall 1: Missing .foregroundStyle(.secondary) replacements
**What goes wrong:** SwiftUI `.secondary` looks fine in dark mode but is not a design token. Easy to miss because it "works."
**Why it happens:** `.secondary` is semantic and adapts to dark mode, so it does not visually break.
**How to avoid:** Grep for `.secondary` and `.primary` in addition to explicit color names.
**Warning signs:** Grep returns hits for `.secondary` or `.primary` in view files.

### Pitfall 2: CadenceDisplayView SPM font size
**What goes wrong:** The 76pt monospaced SPM display is a deliberate design choice for the run screen. Replacing with `displayHero` (52pt rounded) would break the visual hierarchy.
**Why it happens:** Mechanical token replacement without considering intent.
**How to avoid:** Keep the CadenceDisplayView SPM size as an explicit override, or add a `displaySPM` token to `DesignTokens.swift`.
**Warning signs:** SPM number looks too small after migration.

### Pitfall 3: LoginView spotifyGreen not fully replaced
**What goes wrong:** The local `spotifyGreen` constant is replaced in the property declaration but references in the body are missed.
**Why it happens:** Three separate references to `spotifyGreen` in LoginView.
**How to avoid:** Delete the local constant entirely and replace all 3 uses with `Color.spotifyBrand`.

### Pitfall 4: RunTabView NavigationStack context
**What goes wrong:** RunTabView is wrapped in a NavigationStack in ContentView. Adding a NavigationLink to a playlist detail from RunTabView could conflict.
**Why it happens:** Phase 7 decision: "RunTabView shows idle CTA only -- active RunView stays in Library tab's NavigationStack."
**How to avoid:** RunTabView should display playlist info read-only. The "Start Run" action should either switch to Library tab or navigate within its own stack. Keep it simple -- display only.

## Code Examples

### Verified: Token usage in RunTabView (already correct)
```swift
// RunTabView.swift already uses tokens correctly:
Color.surfaceBase.ignoresSafeArea()  // correct
Color.textOnAccent                   // correct
Color.accent                         // correct
Color.textSecondary                  // correct
Spacing.xl, Spacing.md, Spacing.sm  // correct
Font.captionText                     // correct
```

### Example: LoginView migration
```swift
// BEFORE:
private let spotifyGreen = Color(red: 0.114, green: 0.725, blue: 0.329)
// ...
.foregroundStyle(spotifyGreen)
.background(spotifyGreen)

// AFTER (delete spotifyGreen property entirely):
.foregroundStyle(Color.spotifyBrand)
.background(Color.spotifyBrand)
```

### Example: RunView background migration
```swift
// BEFORE:
Color.black.ignoresSafeArea()

// AFTER:
Color.surfaceBase.ignoresSafeArea()
```

### Example: BPM badge token migration
```swift
// BEFORE:
.foregroundStyle(.orange)
.background(Capsule().fill(.orange.opacity(0.15)))

// AFTER:
.foregroundStyle(Color.stateWarning)
.background(Capsule().fill(Color.stateWarning.opacity(0.15)))
```

### Example: RunTabView with last-used playlist (NAV-04)
```swift
struct RunTabView: View {
    @State private var lastPlaylistName: String?
    @State private var lastPlaylistImageURL: String?

    var body: some View {
        ZStack {
            Color.surfaceBase.ignoresSafeArea()

            if let name = lastPlaylistName {
                // Show last-used playlist context
                VStack(spacing: Spacing.md) {
                    if let imageURL = lastPlaylistImageURL,
                       let url = URL(string: imageURL) {
                        AsyncImage(url: url) { image in
                            image.resizable().aspectRatio(contentMode: .fill)
                        } placeholder: {
                            RoundedRectangle(cornerRadius: Radius.md)
                                .fill(Color.surfaceOverlay)
                        }
                        .frame(width: ComponentSize.coverArtLarge,
                               height: ComponentSize.coverArtLarge)
                        .clipShape(RoundedRectangle(cornerRadius: Radius.md))
                    }

                    Text(name)
                        .font(.heading)
                        .foregroundStyle(Color.textPrimary)

                    Button { /* start run */ } label: {
                        Text("Start Run")
                            .font(.subheading)
                            .foregroundStyle(Color.textOnAccent)
                            .padding(.horizontal, Spacing.xl)
                            .padding(.vertical, Spacing.md)
                            .background(Capsule().fill(Color.accent))
                    }
                }
            } else {
                // No previous run -- prompt
                VStack(spacing: Spacing.sm) {
                    Text("Select a playlist from Library to start")
                        .font(.captionText)
                        .foregroundStyle(Color.textSecondary)
                }
            }
        }
        .navigationTitle("Run")
        .onAppear {
            lastPlaylistName = LastRunPlaylist.name
            lastPlaylistImageURL = LastRunPlaylist.imageURL
        }
    }
}
```

## Affected Files Inventory

Complete list of files requiring token migration (DS-04):

| File | Hardcoded Colors | Hardcoded Fonts | Hardcoded Spacing | Severity |
|------|-----------------|-----------------|-------------------|----------|
| `RunView.swift` | ~30 | ~8 | ~10 | HIGH |
| `PlaylistDetailView.swift` | ~20 | ~6 | ~5 | HIGH |
| `PlaylistListView.swift` | ~10 | ~4 | ~3 | MEDIUM |
| `LoginView.swift` | ~5 + spotifyGreen | ~3 | ~3 | MEDIUM |
| `MiniPlayerView.swift` | ~8 | ~3 | ~2 | MEDIUM |
| `CadenceDisplayView.swift` | ~5 | ~2 | ~1 | LOW |
| `PacePresetPicker.swift` | ~8 | ~2 | ~2 | MEDIUM |
| `SettingsView.swift` | ~2 | 0 | 0 | LOW |
| `ModePicker.swift` | 0 | 0 | 0 | NONE |
| `TolerancePicker.swift` | 0 | 0 | 0 | NONE |
| `ContentView.swift` | 0 | 0 | 0 | NONE (already uses tokens) |

Files NOT requiring changes: `RunTabView.swift` (already tokenized), `ContentView.swift` (already tokenized), `ModePicker.swift` (no styling), `TolerancePicker.swift` (no styling).

## Open Questions

1. **CadenceDisplayView 76pt SPM font**
   - What we know: Current size is 76pt monospaced bold. `displayHero` token is 52pt rounded.
   - What is unclear: Whether to add a new `displaySPM` token or keep as explicit override.
   - Recommendation: Add `displaySPM = Font.system(size: 76, weight: .bold, design: .monospaced)` to DesignTokens.swift. This is a legitimate design token, not a one-off.

2. **Spacing values that don't exactly match tokens**
   - What we know: Some values like 12, 14, 20 fall between token steps (sm=8, md=16, lg=24).
   - What is unclear: Whether to round to nearest token or keep exact values.
   - Recommendation: Round to nearest token. The visual difference between 12px and 16px is minimal. Consistency matters more than pixel-perfection.

3. **RunTabView "Start Run" action**
   - What we know: Phase 7 decided RunView stays in Library tab's NavigationStack.
   - What is unclear: What happens when user taps "Start Run" from RunTabView with a last-used playlist.
   - Recommendation: For now, make "Start Run" button non-functional (placeholder) or switch to Library tab. The full run-from-Run-tab flow is beyond NAV-04 scope.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | XCTest (Xcode built-in) |
| Config file | BeatStepTests/ directory |
| Quick run command | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BeatStepTests/DesignTokenTests 2>&1 \| tail -5` |
| Full suite command | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 \| tail -20` |

### Phase Requirements to Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| DS-04 | Zero hardcoded colors outside token files | smoke (grep) | `grep -rn 'Color\.black\|Color\.green\|Color\.orange\|Color\.red\|Color\.gray\|\.green\b\|\.orange\b\|\.red\b\|\.gray\b' --include='*.swift' BeatStep/Views/ \| grep -v '//'; test $? -eq 1` | N/A (shell) |
| DS-04 | Zero .secondary/.primary in views | smoke (grep) | `grep -rn '\.secondary\|\.primary' --include='*.swift' BeatStep/Views/ \| grep -v '//'; test $? -eq 1` | N/A (shell) |
| DS-04 | No local spotifyGreen constant | smoke (grep) | `grep -rn 'spotifyGreen' --include='*.swift' BeatStep/; test $? -eq 1` | N/A (shell) |
| NAV-04 | Last-used playlist persists | unit | `xcodebuild test -only-testing:BeatStepTests/LastRunPlaylistTests` | No -- Wave 0 |
| NAV-04 | RunTabView shows playlist or prompt | manual-only | Visual inspection in simulator | N/A |

### Sampling Rate
- **Per task commit:** Grep verification for DS-04 (instant)
- **Per wave merge:** Full test suite
- **Phase gate:** Full suite green + all grep checks pass

### Wave 0 Gaps
- [ ] If `displaySPM` token added, update `DesignTokenTests.swift` to cover it
- [ ] Optional: `LastRunPlaylistTests.swift` for UserDefaults persistence round-trip

## Sources

### Primary (HIGH confidence)
- Direct code audit of all 11 view files in `BeatStep/Views/`
- `DesignTokens.swift` -- complete token inventory
- `DesignTokenTests.swift` -- existing test coverage
- `STATE.md` -- Phase 7 decisions affecting this phase

### Secondary (MEDIUM confidence)
- Token-to-hardcoded mapping table derived from manual audit (mappings may need visual verification)

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - no new dependencies, all first-party Apple APIs
- Architecture: HIGH - patterns follow existing project conventions (UserDefaults, token extensions)
- Pitfalls: HIGH - derived from direct code audit, every hardcoded reference catalogued

**Research date:** 2026-03-23
**Valid until:** 2026-04-23 (stable -- no external dependency changes expected)
