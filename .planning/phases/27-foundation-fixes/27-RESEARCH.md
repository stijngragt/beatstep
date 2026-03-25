# Phase 27: Foundation + Fixes - Research

**Researched:** 2026-03-25
**Domain:** iOS Design System Tokens (Haptics/Animation), Spotify API Migration, SwiftUI Reactivity Bug Fix
**Confidence:** HIGH

## Summary

Phase 27 has three distinct work areas: (1) creating haptic and animation token files for the design system, (2) verifying/fixing Spotify API models against February 2026 breaking changes, and (3) fixing a library view reactivity bug where scan completion does not immediately update the analyzed status display.

The Spotify API changes are the most impactful area. The February 2026 Dev Mode migration renamed playlist response fields (`tracks` -> `items`, `track` -> `item`), reduced search limits (max 50 -> 10), removed the `product` field from user profiles, and changed playlist content visibility rules. The existing codebase has PARTIALLY migrated (endpoint URLs updated, `PlaylistTrackItem` uses `item` key) but has inconsistencies: mock test data still uses `"track"` key (causing the pre-existing test failure), `SpotifyPlaylist.tracks` field name is stale, `addTracksToPlaylist` endpoint still uses `/tracks`, and `SpotifyUser.product` is no longer returned.

The haptic and animation tokens are a straightforward design system extension. The library bug (LIB-05) is a SwiftUI state management issue where `loadCoverageData()` is called inside the swipe action closure but the view does not observe `LibraryScanService` state changes reactively.

**Primary recommendation:** Fix the Spotify model inconsistencies first (they affect tests and runtime correctness), then add design tokens, then fix the library reactivity bug.

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| POL-01 | Design system includes haptic and animation tokens (BSHaptics, BSAnimation) referenced by all components | Existing DesignTokens.swift pattern; add two new files following same enum-based static constant pattern |
| INF-01 | Spotify API models verified against February 2026 changes (search limit, field renames) | Full migration guide analyzed; 6 specific model/endpoint changes identified |
| LIB-05 | Library correctly shows analyzed status after scan completes (bug fix) | Root cause identified: `loadCoverageData()` is imperative, not reactive; scan completion does not trigger re-read |
</phase_requirements>

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| SwiftUI | iOS 17+ | UI framework | Project standard, already in use |
| UIKit (UIImpactFeedbackGenerator) | iOS 17+ | Haptic feedback | Only API for haptics on iOS |
| SwiftUI Animation | iOS 17+ | Spring/easing animations | Native animation system |
| Foundation (JSONDecoder) | iOS 17+ | Spotify model decoding | Already used for all API models |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| XCTest | iOS 17+ | Unit tests | Verifying model decoding, token existence |
| SwiftData | iOS 17+ | ScannedPlaylist persistence | Already used for BPM cache and scan records |

### Alternatives Considered
None -- all work uses existing project dependencies.

## Architecture Patterns

### Recommended Project Structure
```
BeatStep/DesignSystem/
    DesignTokens.swift          # existing: colors, fonts, spacing, radius, component sizes
    BSHaptics.swift             # NEW: haptic feedback token definitions
    BSAnimation.swift           # NEW: animation preset token definitions
BeatStep/Models/
    SpotifyTrack.swift          # MODIFY: PlaylistTrackItem backward compat
    SpotifyPlaylist.swift       # MODIFY: tracks -> items field rename
    SpotifyUser.swift           # MODIFY: product field now optional/removed
BeatStep/Services/
    SpotifyAPIService.swift     # MODIFY: search limit, addTracks endpoint
BeatStep/Views/Library/
    PlaylistListView.swift      # MODIFY: reactive scan status updates
BeatStepTests/
    Mocks/MockSpotifyResponses.swift  # MODIFY: update mock JSON to match Feb 2026 format
    SpotifyAPIServiceTests.swift      # MODIFY: fix pre-existing test failure
```

### Pattern 1: Design Token Enum (Existing Pattern)
**What:** Static constants grouped in enums (no instances)
**When to use:** All design system tokens
**Example:**
```swift
// Follow existing pattern from DesignTokens.swift
enum BSHaptics {
    static func light() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    static func medium() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
    static func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }
    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
    // etc.
}

enum BSAnimation {
    static let springSnappy = Animation.spring(response: 0.3, dampingFraction: 0.7)
    static let springGentle = Animation.spring(response: 0.5, dampingFraction: 0.8)
    static let easeDefault = Animation.easeInOut(duration: 0.25)
    // etc.
}
```

### Pattern 2: Backward-Compatible Codable Migration
**What:** Support both old and new JSON field names during transition
**When to use:** Spotify API model migration where old cached data or test mocks may use old keys
**Example:**
```swift
struct PlaylistTrackItem: Codable {
    let item: SpotifyTrack?

    var track: SpotifyTrack? { item }

    // Support both "item" (Feb 2026+) and "track" (legacy)
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let item = try container.decodeIfPresent(SpotifyTrack.self, forKey: .item) {
            self.item = item
        } else if let track = try container.decodeIfPresent(SpotifyTrack.self, forKey: .track) {
            self.item = track
        } else {
            self.item = nil
        }
    }

    enum CodingKeys: String, CodingKey {
        case item
        case track // legacy fallback
    }
}
```

### Pattern 3: Observable Service Observation for Reactivity
**What:** Use SwiftUI's `@Observable` macro observation to reactively update views
**When to use:** When a service state change should immediately reflect in the view
**Example:**
```swift
// LibraryScanService is already @Observable
// The bug: PlaylistListView does not observe scanningPlaylistID changes
// to trigger loadCoverageData() when scan completes

// Fix: observe the scanService and react to scan completion
.onChange(of: scanService.scanningPlaylistID) { oldValue, newValue in
    if oldValue != nil && newValue == nil {
        // Scan just completed
        loadCoverageData()
    }
}
```

### Anti-Patterns to Avoid
- **Hardcoded haptic calls scattered in views:** Always use BSHaptics tokens so haptic patterns can be tuned centrally
- **Hardcoded animation values in views:** Always use BSAnimation presets for consistency
- **Breaking backward compat in Codable models:** Use `decodeIfPresent` with fallback keys, not hard renames that break existing data
- **Imperative data refresh without reactive observation:** The LIB-05 bug exists because `loadCoverageData()` is only called in specific code paths, not reactively when the underlying data changes

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Haptic feedback | Custom haptic wrappers per view | `BSHaptics` centralized enum | Consistency, easy tuning, single import |
| Animation presets | Inline `.spring(response:dampingFraction:)` values | `BSAnimation` named presets | Consistency, semantic naming |
| JSON field migration | Manual string replacement in mocks | Backward-compatible `init(from:)` decoder | Handles both old and new API responses gracefully |

## Common Pitfalls

### Pitfall 1: Spotify Dev Mode Playlist Content Restriction
**What goes wrong:** Playlists the user follows (but does not own) no longer return track items in Dev Mode. The `items` field will be absent or empty.
**Why it happens:** February 2026 Dev Mode restricts playlist content to owned/collaborated playlists only.
**How to avoid:** Make `SpotifyPlaylist.items` (formerly `tracks`) optional. Handle nil gracefully in all views that display track counts or scan coverage.
**Warning signs:** Track count shows 0 for followed playlists; scan fails silently for non-owned playlists.

### Pitfall 2: Search Limit Reduced to 10
**What goes wrong:** `searchTrack(limit: 1)` is fine, but any future search with limit > 10 will fail or be capped.
**Why it happens:** Dev Mode search limit max reduced from 50 to 10.
**How to avoid:** Ensure search limit parameter never exceeds 10. Current usage (`limit: 1`) is safe.
**Warning signs:** Search returning fewer results than expected.

### Pitfall 3: SpotifyUser.product Field Removed
**What goes wrong:** `user.isPremium` always returns false because `product` field is no longer in the API response.
**Why it happens:** `product` field removed from `GET /me` in Dev Mode.
**How to avoid:** Make `product` decoding fail gracefully (it's already optional). Document that premium detection is unreliable in Dev Mode. Consider removing premium check entirely since Spotify requires Premium for Dev Mode as of Feb 2026.
**Warning signs:** Settings screen showing "Free" for all users.

### Pitfall 4: addTracksToPlaylist Endpoint Still Uses /tracks
**What goes wrong:** Adding tracks to playlists fails with 404 or unexpected behavior.
**Why it happens:** Endpoint renamed from `/playlists/{id}/tracks` to `/playlists/{id}/items`.
**How to avoid:** Update the endpoint URL in `SpotifyAPIService.addTracksToPlaylist`.
**Warning signs:** Playlist creation/modification fails silently.

### Pitfall 5: Library Scan Status Not Updating Reactively
**What goes wrong:** After scanning a playlist, the library view still shows "Not analyzed" until pull-to-refresh.
**Why it happens:** `loadCoverageData()` is called in the swipe action completion, but `LibraryScanService.scanPlaylistByID` is async and runs in a `Task` -- the `loadCoverageData()` call may execute before the scan completes, or the view may not re-render because the state change path is imperative.
**How to avoid:** Use `.onChange(of: scanService.scanningPlaylistID)` to detect scan completion and reload coverage data reactively.
**Warning signs:** User must pull-to-refresh to see updated status after scan.

### Pitfall 6: Mock Test Data Inconsistency
**What goes wrong:** `testPlaylistTrackDecoding` fails with XCTUnwrap on nil SpotifyTrack.
**Why it happens:** Mock JSON uses `"track"` key but `PlaylistTrackItem` CodingKeys maps to `"item"`. The model was updated for Feb 2026 but the mock was not.
**How to avoid:** Update mock JSON to use `"item"` key, OR implement backward-compatible decoder (recommended -- handles both formats).
**Warning signs:** Pre-existing test failure documented in STATE.md.

## Code Examples

### BSHaptics Token File
```swift
// BeatStep/DesignSystem/BSHaptics.swift
import UIKit

enum BSHaptics {
    // Tap feedback
    static func light() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func medium() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    static func heavy() {
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
    }

    // Selection changes (picker, toggle, segment)
    static func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }

    // Outcomes
    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func warning() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }

    static func error() {
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }
}
```

### BSAnimation Token File
```swift
// BeatStep/DesignSystem/BSAnimation.swift
import SwiftUI

enum BSAnimation {
    // Interactive responses (taps, toggles)
    static let snappy = Animation.spring(response: 0.3, dampingFraction: 0.7)

    // Content transitions (cards appearing, layout changes)
    static let smooth = Animation.spring(response: 0.45, dampingFraction: 0.85)

    // Gentle movements (background shifts, opacity fades)
    static let gentle = Animation.easeInOut(duration: 0.3)

    // Quick micro-interactions (badge appear, checkmark)
    static let quick = Animation.easeOut(duration: 0.15)

    // Page transitions
    static let page = Animation.spring(response: 0.5, dampingFraction: 0.9)
}
```

### Backward-Compatible PlaylistTrackItem Decoder
```swift
struct PlaylistTrackItem: Codable {
    let item: SpotifyTrack?

    var track: SpotifyTrack? { item }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        // Try "item" first (Feb 2026+), fall back to "track" (legacy)
        if let item = try container.decodeIfPresent(SpotifyTrack.self, forKey: .item) {
            self.item = item
        } else if let track = try container.decodeIfPresent(SpotifyTrack.self, forKey: .track) {
            self.item = track
        } else {
            self.item = nil
        }
    }

    enum CodingKeys: String, CodingKey {
        case item
        case track
    }
}
```

### Reactive Library Status Update
```swift
// In PlaylistListView body, add:
.onChange(of: scanService.scanningPlaylistID) { oldValue, newValue in
    if oldValue != nil && newValue == nil {
        loadCoverageData()
    }
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `tracks` field in playlist JSON | `items` field | Feb 2026 | Model decode failure if not updated |
| `track` field in playlist item JSON | `item` field | Feb 2026 | Track decode returns nil |
| Search limit max 50 | Search limit max 10 | Feb 2026 | Must paginate for >10 results |
| `product` field in user profile | Removed | Feb 2026 | `isPremium` check broken |
| `/playlists/{id}/tracks` endpoint | `/playlists/{id}/items` endpoint | Feb 2026 | Add/remove tracks fails |
| `popularity` field on tracks | Removed | Feb 2026 | No impact (not used) |

**Deprecated/outdated:**
- `SpotifyUser.product`: Removed in Dev Mode. Since Dev Mode now requires Premium, all Dev Mode users are implicitly Premium.
- `Audio Features` endpoint: Already deprecated Nov 2024 (app uses GetSongBPM instead -- no impact).

## Open Questions

1. **Is the app in Dev Mode or Extended Quota?**
   - What we know: No evidence of extended quota application in the codebase. App appears pre-launch.
   - What's unclear: If the app has been granted extended quota, none of the Feb 2026 restrictions apply.
   - Recommendation: Assume Dev Mode (safer). The model fixes are backward-compatible regardless.

2. **Should premium check be removed entirely?**
   - What we know: Dev Mode requires Premium since Feb 2026. The `product` field is no longer returned.
   - What's unclear: Whether the app should still attempt premium detection or assume all users are Premium.
   - Recommendation: Make `SpotifyUser.product` decode gracefully (already optional). Add a comment noting Dev Mode implies Premium. Keep `isPremium` defaulting to true when `product` is nil.

3. **Non-owned playlist behavior change**
   - What we know: Dev Mode no longer returns playlist contents for non-owned playlists.
   - What's unclear: How many user playlists are "followed" vs "owned" in typical usage.
   - Recommendation: Handle nil items gracefully. This may affect scan behavior for followed playlists.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | XCTest (bundled with Xcode) |
| Config file | BeatStepTests target in Xcode project |
| Quick run command | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BeatStepTests 2>&1 \| tail -20` |
| Full suite command | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 \| tail -40` |

### Phase Requirements -> Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| POL-01 | BSHaptics enum defines named haptic constants | unit | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BeatStepTests/DesignTokenTests` | Exists (extend) |
| POL-01 | BSAnimation enum defines named animation presets | unit | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BeatStepTests/DesignTokenTests` | Exists (extend) |
| INF-01 | PlaylistTrackItem decodes both "item" and "track" keys | unit | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BeatStepTests/SpotifyAPIServiceTests` | Exists (fix) |
| INF-01 | SpotifyPlaylist decodes with items field (no tracks) | unit | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BeatStepTests/SpotifyAPIServiceTests` | Exists (extend) |
| INF-01 | SpotifyUser decodes without product field | unit | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BeatStepTests/SpotifyAPIServiceTests` | Exists (extend) |
| INF-01 | Search limit capped at 10 | unit | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BeatStepTests/SpotifyAPIServiceTests` | Wave 0 |
| LIB-05 | Library view reflects analyzed status after scan | manual-only | Manual test -- requires Spotify auth + real playlist scan | N/A |

### Sampling Rate
- **Per task commit:** Run affected test file only
- **Per wave merge:** Full test suite
- **Phase gate:** Full suite green before verify

### Wave 0 Gaps
- [ ] Add tests for BSHaptics token existence (extend DesignTokenTests)
- [ ] Add tests for BSAnimation token existence (extend DesignTokenTests)
- [ ] Fix MockSpotifyResponses to use Feb 2026 JSON format (fix pre-existing failure)
- [ ] Add test for SpotifyUser decoding without `product` field

## Sources

### Primary (HIGH confidence)
- [Spotify Feb 2026 Migration Guide](https://developer.spotify.com/documentation/web-api/tutorials/february-2026-migration-guide) - Full Dev Mode migration details
- [Spotify Feb 2026 Changelog](https://developer.spotify.com/documentation/web-api/references/changes/february-2026) - Field-level changes
- [Spotify March 2026 Changelog](https://developer.spotify.com/documentation/web-api/references/changes/march-2026) - external_ids revert
- Existing codebase: DesignTokens.swift, SpotifyAPIService.swift, SpotifyTrack.swift, PlaylistListView.swift, LibraryScanService.swift

### Secondary (MEDIUM confidence)
- [rspotify GitHub issue #550](https://github.com/ramsayleung/rspotify/issues/550) - Community migration discussion confirming field renames

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - All dependencies already in use, no new libraries needed
- Architecture: HIGH - Following existing patterns (enum tokens, Codable models, @Observable)
- Pitfalls: HIGH - Verified against official Spotify migration guide, pre-existing test failure confirms the track->item issue

**Research date:** 2026-03-25
**Valid until:** 2026-04-25 (stable -- Spotify changes are documented, design tokens are straightforward)
