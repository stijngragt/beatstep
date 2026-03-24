# Phase 9: Bug Fix + Brand Assets - Research

**Researched:** 2026-03-24
**Domain:** iOS app icon generation, SwiftUI optional display patterns, SF Pro typography
**Confidence:** HIGH

## Summary

Phase 9 covers three independent requirements: fixing a track count bug (BUG-01), creating an app icon (BRAND-01), and establishing a wordmark (BRAND-02). All three are straightforward with well-understood patterns.

The bug fix is a simple model change: `trackCount` becomes `Int?` and views conditionally display the count. The app icon requires creating an Asset Catalog with a single 1024x1024 PNG (Xcode 14+ auto-generates all device sizes). The wordmark is a styling change to an existing Text view on LoginView.

**Primary recommendation:** Tackle as three independent tasks in a single plan; no new dependencies needed, all work uses first-party Apple APIs.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- Track count: Change `trackCount` from `Int` to `Int?` -- nil means unknown, 0 means genuinely empty
- When Spotify returns null for tracks/tracks.total, hide the count entirely -- don't show "0 tracks"
- When Spotify explicitly returns total=0, show "0 tracks" -- that's accurate
- Both PlaylistListView and PlaylistDetailView need the conditional display
- App icon: Abstract heartbeat pulse / ECG shape, #FF4545 mark on near-black background
- Ultra-minimal -- just the pulse mark and background, no glow/shadow/container
- Code-generated SVG/PDF -- programmatic vector path, no external design tool
- Pulse mark lives on the icon only -- not reused inside the app
- Wordmark: "BEATSTEP" in SF Pro Bold, all caps, white text, wide letter-spacing
- Wordmark appears on login screen only -- replaces existing "BeatStep" Text() in LoginView
- Icon and wordmark are independent treatments

### Claude's Discretion
- Exact pulse wave path geometry and proportions
- Exact letter-spacing value for the wordmark
- Icon background shade (within near-black range matching surfaceBase)
- How to generate and export icon at all required iOS sizes

### Deferred Ideas (OUT OF SCOPE)
None -- discussion stayed within phase scope
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| BUG-01 | Playlist view displays correct track count (handles zero/null from Spotify API gracefully) | Optional Int pattern on SpotifyPlaylist model + conditional view display |
| BRAND-01 | App icon designed with dark background and accent mark | Asset Catalog creation + programmatic 1024x1024 PNG generation |
| BRAND-02 | Wordmark established for in-app identity | SF Pro Bold + kerning modifier on LoginView |
</phase_requirements>

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| SwiftUI | iOS 17+ | View layer, kerning modifier | Already in use throughout app |
| UIKit (UIGraphicsImageRenderer) | iOS 17+ | Programmatic icon PNG generation | First-party, produces exact pixel output |
| Xcode Asset Catalog | Xcode 15+ | AppIcon.appiconset with single 1024pt | Auto-generates all device sizes from one image |

### Supporting
No new dependencies. All work uses first-party Apple APIs consistent with project decisions.

## Architecture Patterns

### BUG-01: Optional Track Count Pattern

**Current code** (SpotifyPlaylist.swift:23):
```swift
var trackCount: Int {
    tracks?.total ?? 0
}
```

**Fix:** Change to `Int?` so nil propagates from `tracks?.total`:
```swift
var trackCount: Int? {
    tracks?.total
}
```

**View pattern** -- conditional display in both PlaylistListView and PlaylistDetailView:
```swift
// When trackCount is nil (unknown), hide entirely
// When trackCount is 0, show "0 tracks" (genuinely empty)
if let count = playlist.trackCount {
    Text("\(count) tracks")
        .font(.captionText)
        .foregroundStyle(Color.textSecondary)
}
```

**TracksRef note:** `TracksRef.total` is currently `Int` (non-optional). The `tracks` property on `SpotifyPlaylist` is already `TracksRef?`, so when Spotify returns null for the tracks object, `tracks` is nil and `tracks?.total` returns nil. This correctly handles the algorithmic playlist case where Spotify omits the tracks object entirely. If Spotify returns `{"tracks": {"total": 0}}`, it decodes as `TracksRef(total: 0)` and `trackCount` becomes `0` -- shown as "0 tracks".

No change needed to `TracksRef` itself.

### BRAND-01: App Icon Generation

**Approach:** Create a Swift script (or inline UIGraphicsImageRenderer code in a test/helper) that draws the icon at 1024x1024 and exports as PNG.

**Asset Catalog structure:**
```
BeatStep/Resources/Assets.xcassets/
  Contents.json
  AppIcon.appiconset/
    Contents.json          # Single-size mode
    appicon-1024.png       # 1024x1024 PNG
```

**Contents.json for single-size AppIcon:**
```json
{
  "images": [
    {
      "filename": "appicon-1024.png",
      "idiom": "universal",
      "platform": "ios",
      "size": "1024x1024"
    }
  ],
  "info": {
    "author": "xcode",
    "version": 1
  }
}
```

**Icon drawing approach** -- UIGraphicsImageRenderer in a unit test or helper:
```swift
let size = CGSize(width: 1024, height: 1024)
let renderer = UIGraphicsImageRenderer(size: size)
let image = renderer.image { ctx in
    // Background: near-black (surfaceBase = 0.067 white)
    UIColor(white: 0.067, alpha: 1.0).setFill()
    ctx.fill(CGRect(origin: .zero, size: size))

    // ECG pulse path in #FF4545
    let pulse = UIBezierPath()
    // ... heartbeat/ECG wave geometry
    UIColor(red: 1.0, green: 0.271, blue: 0.271, alpha: 1.0).setStroke()
    pulse.lineWidth = ... // proportional to 1024
    pulse.stroke()
}

// Export
let pngData = image.pngData()!
try pngData.write(to: outputURL)
```

**Key constraints:**
- PNG format, fully opaque (no transparency), sRGB color space
- Do NOT round corners -- Apple applies the squircle mask automatically
- Single 1024x1024 image; Xcode auto-generates all smaller sizes (Xcode 14+)

**Xcode project integration:** The Assets.xcassets must be added to the project build target. Since no xcassets currently exists, need to:
1. Create the directory structure
2. Add the Assets.xcassets folder reference to the Xcode project (project.pbxproj)
3. Ensure `ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon` is already set (confirmed: it is)

### BRAND-02: Wordmark on LoginView

**Current LoginView branding** (LoginView.swift:14-19):
```swift
Image(systemName: "waveform.path.ecg")
    .font(.system(size: 60))
    .foregroundStyle(Color.spotifyBrand)

Text("BeatStep")
    .font(.displayHero)
```

**Replace with wordmark:**
```swift
Text("BEATSTEP")
    .font(.system(size: 52, weight: .bold))  // SF Pro Bold (not Rounded)
    .tracking(8)  // Wide letter-spacing -- Claude's discretion on exact value
    .foregroundStyle(Color.textPrimary)  // White
```

**Key details:**
- `.tracking()` is SwiftUI's kerning/letter-spacing modifier
- SF Pro Bold (not Rounded) -- the `design` parameter should be `.default`, not `.rounded`
- The existing `.displayHero` token uses `.rounded` design; wordmark should NOT use this token
- Consider adding a dedicated font token or just inline the font since it's a one-off brand treatment
- The waveform.path.ecg icon above the text should likely be removed or replaced per decision that pulse mark is icon-only

**Note on the ECG icon in LoginView:** The CONTEXT.md says "Pulse mark lives on the icon only -- not reused inside the app." The current LoginView has `waveform.path.ecg` as a decorative element. This should be removed from LoginView since the brand moment is now the wordmark alone. The icon carries the accent pulse; the login screen carries the wordmark.

### Recommended Project Structure Changes

```
BeatStep/
  Resources/
    Assets.xcassets/           # NEW: Asset Catalog
      Contents.json
      AppIcon.appiconset/
        Contents.json
        appicon-1024.png       # Generated 1024x1024 icon
  Models/
    SpotifyPlaylist.swift      # MODIFY: trackCount -> Int?
  Views/
    Onboarding/
      LoginView.swift          # MODIFY: wordmark replaces branding
    Library/
      PlaylistListView.swift   # MODIFY: conditional track count
      PlaylistDetailView.swift # MODIFY: conditional track count
```

### Anti-Patterns to Avoid
- **Providing multiple icon sizes manually:** Use single-size 1024x1024 and let Xcode handle the rest
- **Using .kerning() instead of .tracking():** SwiftUI's `.tracking()` applies uniform letter-spacing (what designers mean by "tracking"); `.kerning()` adjusts pairs differently
- **Defaulting unknown track count to a number:** nil means unknown -- hide it, don't fake it

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Icon size variants | Manual resizing to 29pt, 40pt, 60pt, etc. | Xcode single-size AppIcon | Xcode 14+ auto-generates all sizes from 1024x1024 |
| Letter-spacing | Custom attributed string | SwiftUI `.tracking()` modifier | Built-in, declarative, correct behavior |
| Icon corner rounding | CGPath with rounded corners | Nothing -- Apple applies mask | System squircle mask is required; custom rounding looks wrong |

## Common Pitfalls

### Pitfall 1: TracksRef.total vs tracks being nil
**What goes wrong:** Confusing "Spotify didn't return a tracks object" with "Spotify returned tracks.total = 0"
**Why it happens:** `TracksRef?` being nil (no tracks key) vs `TracksRef(total: 0)` (empty playlist) are different
**How to avoid:** Only change `trackCount` computed property to return `Int?` -- let Swift's optional chaining handle it naturally
**Warning signs:** Tests that don't distinguish nil tracks from zero-count tracks

### Pitfall 2: Asset Catalog not in build target
**What goes wrong:** Icon doesn't appear on device even though file exists
**Why it happens:** Creating the directory but not adding it to the Xcode project's build phases
**How to avoid:** Verify Assets.xcassets appears in project.pbxproj under PBXResourcesBuildPhase
**Warning signs:** App builds but shows default blank icon

### Pitfall 3: Icon with transparency
**What goes wrong:** App Store rejection or visual artifacts
**Why it happens:** Using clear background or alpha channel in the icon PNG
**How to avoid:** Fill entire 1024x1024 canvas with opaque background color first
**Warning signs:** Icon appears differently in simulator vs device

### Pitfall 4: Wrong font design for wordmark
**What goes wrong:** Wordmark uses SF Pro Rounded instead of SF Pro
**Why it happens:** Copy-pasting from existing `.displayHero` token which uses `.rounded` design
**How to avoid:** Explicitly use `.default` design or omit the design parameter entirely
**Warning signs:** Rounded letterforms on "BEATSTEP" text

## Code Examples

### Conditional Track Count Display
```swift
// In PlaylistListView and PlaylistDetailView
if let count = playlist.trackCount {
    Text("\(count) tracks")
        .font(.captionText)
        .foregroundStyle(Color.textSecondary)
}
```

### Wordmark Text
```swift
Text("BEATSTEP")
    .font(.system(size: 52, weight: .bold))
    .tracking(8)
    .foregroundStyle(Color.textPrimary)
```

### ECG Pulse Path (conceptual -- exact geometry is Claude's discretion)
```swift
// Heartbeat pulse: flat line -> sharp spike -> dip -> return to baseline
// Classic ECG QRS complex shape, simplified
let pulse = UIBezierPath()
let y = size.height * 0.5  // Vertical center
let strokeWidth: CGFloat = size.width * 0.035  // ~36pt at 1024

// Left flat segment
pulse.move(to: CGPoint(x: size.width * 0.15, y: y))
pulse.addLine(to: CGPoint(x: size.width * 0.35, y: y))

// P-wave small bump (optional, simpler without)
// QRS spike up
pulse.addLine(to: CGPoint(x: size.width * 0.42, y: y - size.height * 0.30))
// QRS spike down
pulse.addLine(to: CGPoint(x: size.width * 0.48, y: y + size.height * 0.12))
// Return to baseline
pulse.addLine(to: CGPoint(x: size.width * 0.55, y: y))

// Right flat segment
pulse.addLine(to: CGPoint(x: size.width * 0.85, y: y))
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Multiple icon PNGs per size | Single 1024x1024, Xcode auto-generates | Xcode 14 (2022) | Only need one PNG file |
| AppIcon in Contents.json with per-device entries | `"idiom": "universal"` single entry | Xcode 14 (2022) | Simpler Contents.json |
| Dark/tinted icon variants | Automatic from single icon (iOS 18+) | WWDC 2024 | Optional, deferred per REQUIREMENTS.md |

## Open Questions

1. **ECG pulse exact geometry**
   - What we know: Heartbeat/ECG shape, #FF4545 stroke on near-black, ultra-minimal
   - What's unclear: Exact proportions, stroke width, whether to include full PQRST or simplified QRS only
   - Recommendation: Claude's discretion -- start with simplified QRS complex (spike up, dip down, return), iterate visually

2. **Wordmark tracking value**
   - What we know: Wide letter-spacing for premium/athletic feel
   - What's unclear: Exact point value
   - Recommendation: Start with `.tracking(8)` -- comparable to Peloton/Nike athletic branding. Adjust by eye. Range 6-12 is typical for this style.

3. **LoginView ECG icon removal**
   - What we know: "Pulse mark lives on icon only -- not reused inside the app"
   - What's unclear: Whether the existing `waveform.path.ecg` SF Symbol should be fully removed or replaced with something else
   - Recommendation: Remove it -- the wordmark becomes the sole branding element. The subtitle "Your music, your stride" remains.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | XCTest (built-in) |
| Config file | BeatStep.xcodeproj (test target: BeatStepTests) |
| Quick run command | `xcodebuild test -project BeatStep.xcodeproj -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BeatStepTests 2>&1 \| tail -20` |
| Full suite command | `xcodebuild test -project BeatStep.xcodeproj -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 \| tail -40` |

### Phase Requirements -> Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| BUG-01 | trackCount returns nil when tracks is nil, 0 when total is 0 | unit | `xcodebuild test -project BeatStep.xcodeproj -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BeatStepTests/TrackCountTests` | No -- Wave 0 |
| BRAND-01 | App icon PNG exists at 1024x1024, is opaque | unit | `xcodebuild test -project BeatStep.xcodeproj -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BeatStepTests/AppIconTests` | No -- Wave 0 |
| BRAND-02 | Wordmark renders (manual visual check) | manual-only | N/A -- visual verification | N/A |

### Sampling Rate
- **Per task commit:** Quick run command targeting changed test files
- **Per wave merge:** Full suite command
- **Phase gate:** Full suite green before verification

### Wave 0 Gaps
- [ ] `BeatStepTests/TrackCountTests.swift` -- covers BUG-01: test SpotifyPlaylist.trackCount returns nil when tracks is nil, returns 0 when TracksRef(total: 0)
- [ ] `BeatStepTests/AppIconTests.swift` -- covers BRAND-01: test icon PNG file exists in asset catalog at expected path (optional, may be overkill for a static asset)

## Sources

### Primary (HIGH confidence)
- Project source code: SpotifyPlaylist.swift, LoginView.swift, DesignTokens.swift, PlaylistListView.swift, PlaylistDetailView.swift -- direct inspection
- Apple Developer Documentation: UIGraphicsImageRenderer -- standard API for image generation
- Xcode Asset Catalog: Single-size AppIcon since Xcode 14

### Secondary (MEDIUM confidence)
- [Use Your Loaf: Xcode 14 Single Size App Icon](https://useyourloaf.com/blog/xcode-14-single-size-app-icon/) -- confirms single 1024x1024 approach
- [App Radar: iOS App Icon Guidelines](https://appradar.com/academy/ios-app-icon) -- confirms PNG, opaque, sRGB requirements

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- all first-party Apple APIs, verified in existing codebase
- Architecture: HIGH -- patterns are simple (optional property, conditional view, asset catalog)
- Pitfalls: HIGH -- well-known iOS development patterns, verified against project code

**Research date:** 2026-03-24
**Valid until:** 2026-04-24 (stable domain, no fast-moving dependencies)
