# Phase 15: Run Player View - Research

**Researched:** 2026-03-24
**Domain:** SwiftUI component design, AsyncImage caching, Spotify album art, playback controls
**Confidence:** HIGH

## Summary

Phase 15 builds a standalone music player component for the active run screen. It displays album art (80pt), song name, artist name, current track BPM, and provides large play/pause and skip controls (56pt+ touch targets). All data sources already exist: `SpotifyPlayerService.shared` provides `currentTrack` (with album.images for art) and `isPaused` state, `BPMCacheService.shared` provides track BPM, and `RunEngineService.shared` provides `skipToNextMatch()` for BPM-aware skip.

The project already has a `MiniPlayerView` that shows track info + controls in the global tab bar. The run player view is a larger, run-optimized version with album art and bigger touch targets. The existing `AsyncImage` pattern (used in RunTabView, PlaylistDetailView, PlaylistListView) handles Spotify CDN image loading with built-in URLSession caching -- no custom image cache needed.

The `SpotifyTrack` model already includes `album: Album` which has `images: [SpotifyImage]?`. Spotify returns images in descending size order (640px, 300px, 64px). For 80pt display (@3x = 240px physical), the 300px image is the ideal choice.

**Primary recommendation:** Build RunPlayerView as a pure view taking explicit parameters (track, isPaused, bpm, onPlayPause, onSkip closures), following the same pattern as CadenceDisplayView and RunStatusBar from Phase 14. The parent view (Phase 16) wires it to the engine/player singletons.

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| PLR-01 | User sees album art (80pt) for the current track in the integrated run screen player | SpotifyTrack.album.images provides Spotify CDN URLs; AsyncImage with 300px image variant is ideal for 80pt display; existing project pattern in RunTabView/PlaylistDetailView |
| PLR-02 | User sees song name, artist name, and current track BPM in the player area | SpotifyTrack.name, .artistName computed property, BPMCacheService.shared.getBPM(forTrackID:) for BPM lookup |
| PLR-03 | User can play/pause and skip tracks with large touch targets (56pt+) during a run | SpotifyPlayerService.togglePlayPause() and RunEngineService.skipToNextMatch() already exist; MiniPlayerView shows the skip-routing pattern (engine skip during run, raw skip otherwise) |
</phase_requirements>

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| SwiftUI | iOS 17+ | View components, AsyncImage | Project standard |
| @Observable | Swift 5.9+ | Reactive data from SpotifyPlayerService/RunEngineService | Already used throughout project |

### Supporting
No additional libraries needed. AsyncImage handles image loading. URLSession's built-in HTTP cache handles Spotify CDN caching (Spotify returns Cache-Control headers).

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| AsyncImage | Kingfisher/SDWebImage | Overkill -- AsyncImage with URLSession cache is sufficient for single album art display; no thumbnail grid or prefetching needed |
| Closure-based actions | Direct singleton access | Closures make view pure and previewable; consistent with Phase 14 pattern |

## Architecture Patterns

### Recommended Project Structure
```
BeatStep/
  Views/
    Player/
      MiniPlayerView.swift       # existing -- global tab bar player
      RunPlayerView.swift        # NEW -- 80pt art + large controls for run screen
```

### Pattern 1: Pure View with Explicit Parameters
**What:** View takes all display data and action closures as init parameters
**When to use:** All standalone components (Phase 14 established this pattern)
**Example:**
```swift
struct RunPlayerView: View {
    let track: SpotifyTrack
    let isPaused: Bool
    let trackBPM: Int?
    let onPlayPause: () -> Void
    let onSkip: () -> Void

    var body: some View {
        // Layout: album art left, track info center, controls right
        // OR: album art top-center, info below, controls below that
    }
}
```

### Pattern 2: Spotify Album Art via AsyncImage
**What:** Load album art from Spotify CDN using AsyncImage with placeholder
**When to use:** Displaying track album art
**Example:**
```swift
// Spotify returns images sorted by size descending: [640, 300, 64]
// For 80pt display, pick the 300px variant (index 1, or last before 64px)
private var albumArtURL: URL? {
    // Prefer ~300px image for 80pt display
    let images = track.album.images ?? []
    let preferred = images.first(where: { ($0.width ?? 0) <= 300 && ($0.width ?? 0) >= 200 })
        ?? images.first
    return preferred.flatMap { URL(string: $0.url) }
}

AsyncImage(url: albumArtURL) { image in
    image.resizable().aspectRatio(contentMode: .fill)
} placeholder: {
    RoundedRectangle(cornerRadius: Radius.sm)
        .fill(Color.surfaceElevated)
}
.frame(width: 80, height: 80)
.clipShape(RoundedRectangle(cornerRadius: Radius.sm))
```

### Pattern 3: Large Touch Targets for Running
**What:** Minimum 56pt touch targets for play/pause and skip buttons
**When to use:** Any control meant to be tapped while running (sweaty fingers, bouncing phone)
**Example:**
```swift
Button(action: onPlayPause) {
    Image(systemName: isPaused ? "play.fill" : "pause.fill")
        .font(.system(size: 28))
        .frame(width: 56, height: 56)
        .background(Circle().fill(Color.surfaceOverlay))
}

Button(action: onSkip) {
    Image(systemName: "forward.fill")
        .font(.system(size: 22))
        .frame(width: 56, height: 56)
        .background(Circle().fill(Color.surfaceOverlay))
}
```

### Anti-Patterns to Avoid
- **Reading singletons inside the view body:** Makes previews impossible and testing hard. Pass data as parameters.
- **Custom image caching:** AsyncImage + URLSession HTTP cache is sufficient. Spotify CDN returns proper Cache-Control headers.
- **Small touch targets:** Requirements explicitly say 56pt+. MiniPlayerView's current .title3 icons are too small for running -- this view needs bigger targets.
- **Blocking on BPM lookup:** BPMCacheService.getBPM is synchronous (SwiftData local read). No async needed.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Image caching | Custom URLCache or disk cache | AsyncImage (built-in URLSession cache) | Spotify CDN returns Cache-Control headers; single image doesn't need prefetching |
| Image size selection | Complex resolution logic | Simple filter on SpotifyImage.width | Spotify consistently returns 3 sizes (640, 300, 64) |
| Play/pause state management | Custom state tracking | SpotifyPlayerService.isPaused | Already @Observable, already polling |
| Skip-during-run routing | Custom skip logic | Existing MiniPlayerView pattern | Check RunEngineService.isRunActive to decide engine skip vs raw skip |

## Common Pitfalls

### Pitfall 1: Album Images Array Being nil or Empty
**What goes wrong:** SpotifyTrack.album.images is optional and could be nil for some tracks
**Why it happens:** Some Spotify tracks (local files, some singles) lack album art
**How to avoid:** Always provide a placeholder. The existing project pattern uses `RoundedRectangle.fill(Color.surfaceElevated)` as placeholder.
**Warning signs:** Blank space where art should be

### Pitfall 2: Picking Wrong Image Size
**What goes wrong:** Loading 640px image for 80pt display wastes bandwidth; loading 64px looks blurry
**Why it happens:** Spotify returns images in descending order by default
**How to avoid:** Filter for the ~300px variant. At @3x (240px physical), 300px is perfect. Fallback to first available.
**Warning signs:** Slow image loads on cellular, pixelated art

### Pitfall 3: Touch Target Size Not Meeting 56pt Minimum
**What goes wrong:** Buttons too small to hit while running
**Why it happens:** Icon size != touch target size. A 28pt icon needs a 56pt+ frame
**How to avoid:** Always set explicit `.frame(width: 56, height: 56)` or larger on button labels, independent of icon size
**Warning signs:** Frequent mis-taps during testing

### Pitfall 4: BPM Showing Stale Value After Track Change
**What goes wrong:** BPM display shows previous track's BPM momentarily
**Why it happens:** Track changes via polling (3s interval) but BPM lookup is sync
**How to avoid:** Use `.onChange(of: track.id)` to refresh BPM, same pattern as MiniPlayerView
**Warning signs:** BPM flicker on track change

### Pitfall 5: Skip Not Using BPM-Aware Matching During Run
**What goes wrong:** Skip plays random next track instead of BPM-matched track
**Why it happens:** Calling SpotifyPlayerService.skipNext() instead of RunEngineService.skipToNextMatch()
**How to avoid:** Follow MiniPlayerView pattern: check `RunEngineService.shared.isRunActive` to route skip
**Warning signs:** Skipped track BPM doesn't match cadence

## Code Examples

### RunPlayerView Structure (recommended layout)
```swift
// Source: project patterns from MiniPlayerView + Phase 14 views
struct RunPlayerView: View {
    let track: SpotifyTrack
    let isPaused: Bool
    let trackBPM: Int?
    let onPlayPause: () -> Void
    let onSkip: () -> Void

    var body: some View {
        HStack(spacing: Spacing.md) {
            // Album art (80pt)
            albumArt

            // Track info (song, artist, BPM)
            trackInfo

            Spacer()

            // Controls (play/pause, skip)
            controls
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(Color.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: Radius.md))
    }
}
```

### Album Art with Correct Size Selection
```swift
// Source: SpotifyImage model in SpotifyUser.swift + existing AsyncImage patterns
private var albumArtURL: URL? {
    let images = track.album.images ?? []
    // Prefer mid-size (~300px) for 80pt display
    let preferred = images.first(where: { ($0.width ?? 0) >= 200 && ($0.width ?? 0) <= 400 })
        ?? images.first
    return preferred.flatMap { URL(string: $0.url) }
}

private var albumArt: some View {
    AsyncImage(url: albumArtURL) { image in
        image.resizable().aspectRatio(contentMode: .fill)
    } placeholder: {
        RoundedRectangle(cornerRadius: Radius.sm)
            .fill(Color.surfaceOverlay)
            .overlay {
                Image(systemName: "music.note")
                    .foregroundStyle(Color.textTertiary)
            }
    }
    .frame(width: 80, height: 80)
    .clipShape(RoundedRectangle(cornerRadius: Radius.sm))
}
```

### BPM Display with Track Change Handling
```swift
// Source: MiniPlayerView.swift BPM pattern
// Note: In pure-parameter pattern, BPM is passed in, not looked up internally.
// The parent wires: trackBPM = BPMCacheService.shared.getBPM(forTrackID: track.id)

VStack(alignment: .leading, spacing: Spacing.xxs) {
    Text(track.name)
        .font(.bodyBold)
        .foregroundStyle(Color.textPrimary)
        .lineLimit(1)

    Text(track.artistName)
        .font(.captionText)
        .foregroundStyle(Color.textSecondary)
        .lineLimit(1)

    if let bpm = trackBPM {
        Text("\(bpm) BPM")
            .font(.captionBold)
            .foregroundStyle(Color.stateWarning)
    }
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| URLSession.shared.data(for:) + UIImage manual caching | AsyncImage | iOS 15+ | Built-in loading states, automatic caching |
| SPTAppRemote for playback control | Spotify Web API | v1.0 project decision | SpotifyPlayerService already uses Web API |
| Spotify Audio Features for BPM | GetSongBPM via Cloudflare Worker | Nov 2024 deprecation | BPMCacheService already handles this |

## Open Questions

1. **Layout orientation (horizontal vs vertical)**
   - What we know: MiniPlayerView uses horizontal (HStack). Run screen has more vertical space.
   - What's unclear: Whether horizontal or vertical arrangement works better for the run context
   - Recommendation: Start with horizontal (art left, info center, controls right) -- matches MiniPlayerView mental model and is compact. Can be adjusted in Phase 16 assembly.

2. **Whether to show "no track" state or hide entirely**
   - What we know: MiniPlayerView hides when no track. Run player might need a placeholder.
   - What's unclear: What happens when the run is active but no track matched yet
   - Recommendation: Build the view to require a track (non-optional). The parent view handles the nil case (show placeholder or nothing). Keeps component simple.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | XCTest (project standard) |
| Config file | BeatStepTests target in Xcode project |
| Quick run command | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BeatStepTests/RunPlayerViewTests` |
| Full suite command | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16'` |

### Phase Requirements -> Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| PLR-01 | Album art URL selection picks ~300px variant | unit | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BeatStepTests/RunPlayerViewTests/testAlbumArtURLPrefers300px` | No -- Wave 0 |
| PLR-01 | Album art URL returns nil gracefully when images empty | unit | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BeatStepTests/RunPlayerViewTests/testAlbumArtURLNilWhenNoImages` | No -- Wave 0 |
| PLR-02 | Track BPM displayed from BPMCacheService lookup | unit | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BeatStepTests/RunPlayerViewTests/testTrackBPMLookup` | No -- Wave 0 |
| PLR-03 | Touch target frames are 56pt+ | unit | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BeatStepTests/RunPlayerViewTests/testTouchTargetMinimumSize` | No -- Wave 0 |

### Sampling Rate
- **Per task commit:** `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BeatStepTests/RunPlayerViewTests`
- **Per wave merge:** `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16'`
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] `BeatStepTests/RunPlayerViewTests.swift` -- covers PLR-01 (image URL selection), PLR-02 (BPM display data), PLR-03 (touch target sizing via static helpers)

## Sources

### Primary (HIGH confidence)
- Project source code: SpotifyPlayerService.swift, MiniPlayerView.swift, SpotifyTrack.swift, RunEngineService.swift -- existing patterns for player state, track model, album images, skip routing
- Project source code: DesignTokens.swift -- all color, font, spacing, radius, component size tokens
- Project source code: CadenceDisplayView.swift, RunStatusBar.swift -- Phase 14 pure-parameter component pattern
- Project source code: RunTabView.swift, PlaylistDetailView.swift, PlaylistListView.swift -- existing AsyncImage patterns

### Secondary (MEDIUM confidence)
- Spotify Web API documentation -- album images consistently return 3 sizes (640, 300, 64px) with Cache-Control headers

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - no new dependencies, all patterns already established in project
- Architecture: HIGH - follows exact same pure-view pattern as Phase 14, data sources all exist
- Pitfalls: HIGH - based on direct code inspection of existing player and track models

**Research date:** 2026-03-24
**Valid until:** 2026-04-24 (stable -- no external dependencies or API changes expected)
