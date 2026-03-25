# Project Research Summary

**Project:** BeatStep v1.6 — Little Big Things
**Domain:** iOS running music app — UI polish, custom components, micro-interactions
**Researched:** 2026-03-25
**Confidence:** HIGH

## Executive Summary

BeatStep v1.6 is a pure UI polish milestone with zero new external dependencies. The existing stack (Swift 6 / SwiftUI + `@Observable`, iOS 17.0 target, Spotify Web API, SwiftData) already contains every API needed: `.sensoryFeedback()` for haptics, `.searchable()` for search, `.redacted()` + custom shimmer for skeletons, spring presets for animations, and `matchedGeometryEffect` for selection indicators. The work is extracting components, adding polish modifiers, and restructuring views — not adding packages.

The recommended approach is to build in 9 sequential phases with a strict dependency order: foundation work (design system tokens, API audit, bug fix) before feature work (library polish, run tab rebuild), and micro-interaction polish strictly last. The most important structural decision is keeping multi-zone selection as a view-layer concept that resolves to `targetBPM + tolerance` before reaching `RunEngineService`, preserving the engine's clean API contract. Similarly, the skip queue must be a local `[SpotifyTrack]` buffer using `play(uri:)` — never Spotify's append-only queue API.

The top risks are: (1) using Spotify's queue API for the skip buffer (no remove endpoint — stale songs cannot be cleared), (2) animation jank on the run screen from unscoped `.animation()` modifiers over frequently-updating `@Observable` state, and (3) haptic fatigue from over-hapticizing a fitness app where the Taptic Engine runs for 45+ minutes. All three are preventable with explicit inventory and scoping rules defined before writing code.

## Key Findings

### Recommended Stack

v1.6 requires no new dependencies. All capabilities come from SwiftUI APIs available on iOS 17.0 — the app's current deployment target. The existing `DesignTokens.swift` token system extends cleanly to animation and component size tokens via new sibling files (`BSHaptics.swift`, `BSAnimation.swift`) rather than adding to the existing file.

**Core technologies:**
- `.sensoryFeedback()` (iOS 17+): Haptic feedback on zone selection, tolerance change, run lifecycle — declarative, trigger-based, replaces `UIImpactFeedbackGenerator` for new v1.6 haptics. Exception: keep `UIImpactFeedbackGenerator` in `TapBPMView` where imperative firing is required.
- `.searchable()` + computed filter (iOS 15+): Client-side playlist search and filter — no Spotify API calls, library already loaded via paginated fetch.
- `.redacted(reason: .placeholder)` + `ShimmerModifier`: Loading skeleton states — ~20 lines of custom `ViewModifier` with `LinearGradient`, no library needed.
- `matchedGeometryEffect` + `@Namespace`: Sliding selection indicator in zone picker — smooth capsule highlight without frame calculations.
- Named spring presets (`.bouncy`, `.snappy`) (iOS 17+): Physical-feel transitions for selection and insertion.
- Local `[SpotifyTrack]` buffer: Pre-built skip queue using `play(uri:)` — zero Spotify queue API involvement.

### Expected Features

**Must have (table stakes):**
- Library search — users with 50+ playlists cannot navigate without it; `.searchable()` is 15 lines
- Library filter (All / Analyzed / Unanalyzed) — needed to find playlists to scan; computed from existing `coverageMap`
- Skeleton loading states — shimmer placeholders show layout shape, far better UX than spinners for list items
- Analysis status bug fix — stale `coverageMap` after background scans; single `.onChange` observer on `scanService.scanningPlaylistID`
- Settings screen structure — current flat list mixes account, zones, playback, debug; groups into Account / Run Defaults / Permissions / About

**Should have (differentiators):**
- Contextual scan actions replacing floating bar — swipe + context menu + toolbar, native iOS patterns instead of content-covering overlay
- Custom zone picker with haptics — `.sensoryFeedback(.selection)` makes zone switching feel physical
- Playlist card redesign with scan quality visualization — `ScanQualityBadge` with color-coded coverage ratio (green/yellow/red)
- Pre-built skip queue — reduce skip latency from ~500ms to ~100ms via local pre-computation
- Run menu redesign with custom components — reusable `BeatStepSegmentedControl` from zone picker pattern
- Micro-interaction pass — spring animations, transitions, haptics audit across all modified views

**Defer (v2+):**
- Multi-zone selection — highest complexity (HIGH), low relative value (P3); changes `ZonePickerView` API contract and `RunEngineService` BPM range logic; defer unless time permits after all P1/P2 features are complete
- Spotify catalog search — scope creep; library filter is sufficient for v1.6
- Draggable/reorderable queue — contradicts core BPM-matching value proposition

### Architecture Approach

The architecture remains unchanged at the service layer. All v1.6 changes are view-layer reshuffling with two new design system files and 8 new component/model files. Key principle: multi-zone selection resolves to `targetBPM + tolerance` at the `RunTabView` layer before reaching `RunEngineService` — the engine never needs to understand zones. New `@Observable` properties on `RunEngineService` (skip queue) must use `@ObservationIgnored` to prevent `ActiveRunView` re-renders on every cadence poll.

**Major components:**
1. `DesignSystem/BSHaptics.swift` + `BSAnimation.swift` — token files for haptic types and animation constants; all later features reference these
2. `Views/Library/` (LibraryFilterBar, ScanQualityBadge) + modified PlaylistListView/PlaylistRow — search, filter, skeleton, contextual scan, card redesign
3. `Views/Run/RunPlaylistCard.swift` + modified RunTabView/ZonePickerView — run menu rebuild, multi-zone (if in scope)
4. Modified `RunEngineService` — `@ObservationIgnored private var skipBuffer: [SpotifyTrack]` for pre-built queue
5. Modified `SettingsView` — extracted section structs, dynamic version string from `Bundle.main.infoDictionary`

### Critical Pitfalls

1. **Spotify queue API for skip buffer** — `POST /me/player/queue` is append-only with no remove/clear endpoint. Pre-queued wrong-BPM songs cannot be removed when cadence changes. Use local `[SpotifyTrack]` buffer with `play(uri:)` exclusively; recovery cost is HIGH if built wrong.

2. **Animation jank on ActiveRunView** — `ActiveRunView` reads `RunEngineService.shared` directly; any property change triggers full body evaluation. Bare `.animation(.default)` without `value:` parameter animates all state changes including rapid cadence updates. Always scope with `animation(_:value:)` on specific triggers; use `drawingGroup()` on animated subviews; never animate cadence/BPM number text.

3. **Haptic fatigue during runs** — `.sensoryFeedback` is trivially easy to add, making it tempting to sprinkle everywhere. 45-minute runs with frequent haptics drain battery and annoy users. Define a haptic inventory (tiered budget) before writing any haptic code; restrict run-screen haptics to ~5-10 events per session.

4. **Search causing AsyncImage reload flicker** — naive computed `filteredPlaylists` rebuilds on every keystroke, destroying cell identity and causing 50+ album art images to re-fetch. Debounce with `Task.sleep(300ms)` and use `ForEach(id: \.id)` identity-stable rows.

5. **Spotify February 2026 API changes** — search `limit` max reduced from 50 to 10; playlist response field `tracks` renamed to `items`; `product` field removed from user profile. Audit all API endpoints before building new features; verify `BPMDiscoveryService` search limit and `SpotifyPlaylist` decoding.

## Implications for Roadmap

Based on combined research, the features naturally fall into 9 build phases with strict dependency ordering.

### Phase 1: Design System Foundation
**Rationale:** `BSHaptics`, `BSAnimation`, and `ShimmerModifier` are referenced by every later feature. Must exist before components are built.
**Delivers:** `BSHaptics.swift`, `BSAnimation.swift`, `ShimmerModifier.swift`; design token comment header in `DesignTokens.swift`
**Addresses:** Design token drift (PITFALLS #7) — establishes the vocabulary before any new components are written
**Avoids:** Hardcoded `Color(red:`, raw spacing values in all subsequent phases

### Phase 2: API Audit + Bug Fix
**Rationale:** Spotify Feb 2026 changes may break existing functionality silently. Analysis status bug corrupts coverage data that all library features depend on. Both must be verified/fixed before building on top of them.
**Delivers:** Verified API models (`SpotifyPlaylist`, `BPMDiscoveryService` search limit), `.onChange` observer fix in `PlaylistListView`
**Addresses:** Analysis Status Bug Fix (FEATURES P1), Spotify Feb 2026 pitfall (PITFALLS #9)
**Avoids:** Building library features on stale or broken coverage data

### Phase 3: Coverage Data Model
**Rationale:** `CoverageInfo` struct and `LibraryFilter` enum are shared by both library search/filter and playlist card redesign. Shared model extracted once, referenced by both parallel features.
**Delivers:** `Models/CoverageInfo.swift`, `Models/LibraryFilter.swift`; `loadCoverageData()` updated to emit `CoverageInfo` instead of raw strings
**Uses:** SwiftData `ScannedPlaylist` (existing), `coverageMap` logic (existing)
**Implements:** Foundation for both Phase 4a and 4b

### Phase 4a: Library Search and Filter
**Rationale:** Independent of playlist card work; shares Phase 3 data model. Can be executed in parallel with 4b.
**Delivers:** `.searchable()` on `PlaylistListView`, `LibraryFilterBar` component, `filteredPlaylists` computed property with 300ms debounce
**Uses:** SwiftUI `.searchable()` (iOS 15+), `LibraryFilter` enum from Phase 3
**Avoids:** Search keystroke lag pitfall (PITFALLS #4) — debounce required

### Phase 4b: Playlist Card Redesign
**Rationale:** Independent of search; shares Phase 3 data model. Can be executed in parallel with 4a.
**Delivers:** `ScanQualityBadge` component, redesigned `PlaylistRow` with visual coverage indicator (green/yellow/red), `PlaylistRow` extracted from private to internal struct for reuse
**Uses:** `CoverageInfo` struct from Phase 3, `BSAnimation` tokens from Phase 1
**Implements:** `Views/Library/ScanQualityBadge.swift`

### Phase 5: Contextual Scan Actions
**Rationale:** Depends on redesigned `PlaylistRow` from Phase 4b being in its final form. Removes global scan banner, adds per-row inline scan state.
**Delivers:** Removed global `scanProgress` banner, inline scan button on rows, `.contextMenu` with Analyze + View Details, toolbar actions on `PlaylistDetailView`
**Uses:** Existing `.swipeActions` (already in place), `.contextMenu` modifier
**Avoids:** Swipe gesture conflicts pitfall (PITFALLS #5) — use only native `.swipeActions` + `.contextMenu`, no custom gesture recognizers

### Phase 6: Run Menu Redesign
**Rationale:** Independent of all library phases. `ZonePickerView` capsule pattern becomes the reusable `BeatStepSegmentedControl`. Multi-zone selection (if in scope) depends on this component.
**Delivers:** `RunPlaylistCard` extracted from `RunTabView`, `BeatStepSegmentedControl` reusable component, haptics on zone selection (`.sensoryFeedback`), `ToleranceSelector` extracted as standalone component
**Uses:** `BSHaptics.swift` from Phase 1, `matchedGeometryEffect` for selection indicator
**Implements:** Multi-zone foundation (Set-based ZonePickerView binding) — full multi-zone deferred to v2 unless time permits after phases 1-8 complete

### Phase 7: Settings Screen Structure
**Rationale:** Fully independent; can be moved earlier but placed here to not delay higher-value library and run tab work. Low risk, quick win.
**Delivers:** Restructured `SettingsView` with extracted section structs (Account, Run Defaults, Permissions, Debug, About), dynamic version string from `Bundle.main.infoDictionary`
**Avoids:** Settings over-engineering pitfall (PITFALLS #6) — explicit section views only, no `SettingsItem` model layer, total restructure under 200 LOC

### Phase 8: Pre-Built Skip Queue
**Rationale:** Highest-risk feature (Spotify API behavior), kept last among feature phases so it does not block or destabilize other work. `RunEngineService` changes are isolated.
**Delivers:** `@ObservationIgnored private var skipBuffer: [SpotifyTrack]` in `RunEngineService`, `replenishBuffer()` on track start, instant skip from buffer with background refill
**Avoids:** Spotify queue API misuse (PITFALLS #3, critical) — zero calls to `POST /me/player/queue`, exclusively `play(uri:)`; `@ObservationIgnored` prevents `ActiveRunView` re-render churn (PITFALLS #8)

### Phase 9: Micro-Interaction Pass
**Rationale:** Strictly last — all views must be in final form before adding animations and haptics. Sprinkling polish on components that get restructured later wastes work.
**Delivers:** `BSAnimation` tokens applied to all modified views, `BSHaptics` calls at all defined interaction points (haptic inventory enforced), `.transition()` on all conditional view appearances, verified no bare `.animation(.default)` in run view hierarchy
**Avoids:** Haptic fatigue (PITFALLS #1) and run screen animation jank (PITFALLS #2) — haptic budget defined as first task of phase, all run-view animations scoped with `value:` parameter, device-tested during actual run

### Phase Ordering Rationale

- Design system first because every component references it; token drift is a cross-cutting concern that compounds across phases
- API audit and bug fix second because library features are built on `coverageMap` data — correctness must come before visualization
- Shared data model before parallel library features to avoid duplicating the extraction work
- Library features (4a + 4b) can run in parallel since they share only the data model, not views
- Contextual scan actions after PlaylistRow is finalized to avoid rebuilding twice
- Run tab work is independent of library; can start after Phase 1 with no library dependency
- Skip queue last among feature phases — isolated, high risk, does not block anything
- Micro-interactions strictly last — polish applied once, to final views

### Research Flags

Phases likely needing deeper investigation during planning:
- **Phase 8 (Skip Queue):** Spotify `play(uri:)` behavior when called rapidly (skip during transition) needs verification on physical device. Rate limit guard (`isQueueingNext` flag) must be verified against actual Spotify API timing.
- **Phase 6 (Run Menu Redesign):** Multi-zone BPM range resolution (midpoint + expanded tolerance) should be user-tested if brought into scope. The UX of multi-select capsules (tap to add/remove) vs single-select requires design validation before build.

Phases with well-documented patterns (standard implementation, can skip research-phase):
- **Phase 1 (Design System):** Token file organization is established in codebase; additive-only
- **Phase 2 (API Audit):** Single verification task against live API, not new development
- **Phase 4a (Search + Filter):** `.searchable()` is stable iOS 15+, debounce pattern is standard async/await
- **Phase 7 (Settings):** View restructuring with no service changes; zero unknowns

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Zero new dependencies; all APIs are iOS 17 built-ins, verified against deployment target |
| Features | HIGH | Patterns verified against SwiftUI docs and existing codebase; prioritization informed by competitor analysis |
| Architecture | HIGH | Based on full codebase read of all 65 Swift files; all integration points verified against source |
| Pitfalls | HIGH | Codebase-specific analysis + Spotify API documentation + verified SwiftUI behavior patterns |

**Overall confidence:** HIGH

### Gaps to Address

- **Spotify `play(uri:)` + queued-track interaction:** When `play(uri:)` fires, does it reliably override any Spotify-internally-queued track? Documented behavior says yes, but verify on physical device before finalizing Phase 8 scope.
- **Multi-zone UX:** The Set-based ZonePickerView UX (tap to add/tap to remove) has not been user-tested. Feature is already classified P3/defer-to-v2, but if included it needs design validation before implementation.
- **`isQueueingNext` guard during rapid skips:** Current guard prevents double-fire. Verify it covers the gap between `play()` call and Spotify playback state update (typically 300-500ms).

## Sources

### Primary (HIGH confidence)
- Codebase inspection: all 65 Swift files in `/Users/stijngragt/Projects/beatstep/BeatStep/` — integration points, existing patterns
- `.planning/PROJECT.md` — v1.6 requirements and architectural decisions
- [SensoryFeedback modifier — Apple Docs](https://developer.apple.com/documentation/swiftui/view/sensoryfeedback(_:trigger:)) — API reference
- [searchable modifier — Apple Docs](https://developer.apple.com/documentation/swiftui/view/searchable(text:placement:prompt:)) — API reference
- [Spotify Add to Queue API](https://developer.spotify.com/documentation/web-api/reference/add-to-queue) — endpoint limitations confirmed
- [Spotify February 2026 Changelog](https://developer.spotify.com/documentation/web-api/references/changes/february-2026) — breaking changes confirmed
- [WWDC23: Demystify SwiftUI Performance](https://developer.apple.com/videos/play/wwdc2023/10160/) — observation tracking, animation scoping

### Secondary (MEDIUM confidence)
- [SwiftUI Redacted Magic — Medium](https://medium.com/@naqeeb-ahmed/swiftui-redacted-magic-achieve-shimmer-skeleton-loading-effect-with-just-one-line-of-code-5b203b540dad) — shimmer pattern validated against avanderlee.com
- [Mastering SwiftUI Animations iOS 17+](https://medium.com/@sanjaychavare1/mastering-swiftui-animations-in-ios-17-smooth-transitions-matchedgeometryeffect-beyond-03b89be3f463) — spring presets and matchedGeometryEffect
- [Spotify Queue endpoint issues — GitHub #921](https://github.com/spotify/web-api/issues/921) — community-reported queue API limitations (corroborates official docs)
- [SwiftUI Searchable bugs — Medium](https://medium.com/@snowham/exploring-swiftui-learnings-and-bugs-with-searchable-c5110995c80e) — lifecycle edge cases

### Tertiary (LOW confidence)
- [SwiftUI Scroll Performance: The 120FPS Challenge](https://blog.jacobstechtavern.com/p/swiftui-scroll-performance-the-120fps) — `drawingGroup()` usage; needs device profiling to confirm applies to BeatStep's specific view hierarchy

---
*Research completed: 2026-03-25*
*Ready for roadmap: yes*
