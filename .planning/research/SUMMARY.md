# Project Research Summary

**Project:** BeatStep v1.7 — Beat Perfect
**Domain:** iOS running music sync app — cadence responsiveness, beat-sync accuracy, collapsible player UX
**Researched:** 2026-03-26
**Confidence:** HIGH

## Executive Summary

BeatStep v1.7 is an algorithmic tuning and UI pattern milestone, not a dependency milestone. Every feature in scope — responsive cadence, beat-sync accuracy display, collapsible player, and the analyzed-state bug fix — is achievable by modifying existing service classes and adding two small new components. Zero new Swift packages, frameworks, or APIs are required. The app's existing stack (Swift 6 / SwiftUI / @Observable / CMPedometer / SwiftData / GetSongBPM API) covers all requirements, and the recommended approach is surgical: tune constants, split code paths, and add components that read from already-published observable properties.

The primary technical challenge is understanding the two distinct responsiveness pipelines that must be improved separately. The *display* path (CMPedometer → CadenceService → ActiveRunView) already updates in roughly 1-3 seconds; reducing `windowDuration` from 5s to 3s will tighten this to under 2s. The *song selection* path has a stacked worst-case latency of 24 seconds (5s window + 2s poll + 17s debounce); reducing those three values in concert (3s window, 1s poll, 8s debounce) drops worst-case to approximately 12s and typical to under 5s. These are different objectives and must both be scoped explicitly in the roadmap rather than treating "cadence responsiveness" as a single metric.

The highest-risk area is the analyzed-state bug fix, which has two distinct root causes: a background scan timing gap (PlaylistListView may not be mounted when scans run at app launch) and a data-path architecture issue (`@State coverageData` is a manual copy that does not auto-update from SwiftData writes). The fix requires adding a `scanCompletionCount` signal to LibraryScanService and always refreshing coverage data on that signal, not just on initial view appearance. The collapsible player carries moderate UX risk: `safeAreaInset` must be replaced with a VStack dock to avoid iOS 17.4+ stacking bugs, and gesture scope must be restricted to the drag handle to prevent conflicts with ScrollView.

## Key Findings

### Recommended Stack

The existing stack requires no changes. Swift 6 / SwiftUI + @Observable is the reactive spine; CMPedometer is the authoritative step source (CMMotionManager raw accelerometer cadence is a deep signal-processing problem unsuitable for v1.7); SwiftData persists BPM cache and scanned playlist coverage; and the GetSongBPM API via Cloudflare Worker provides pre-analyzed BPM — more reliable than real-time audio beat detection, which is architecturally unavailable because Spotify controls the audio stream.

**Core technologies:**
- **CMPedometer (CadenceService)**: Step cadence source — Apple's battle-tested algorithm; reduce rolling window 5s → 3s for display responsiveness; song-selection window can stay at 5s for stability
- **@Observable + Task.sleep polling (RunEngineService)**: Cadence monitor and song-selection pipeline — reduce poll 2s → 1s, reduce debounce 17s → 8s to improve song-selection latency
- **SwiftUI DragGesture + @State (CollapsiblePlayerView)**: Collapse/expand interaction — matches existing LongPressStopButton pattern (DragGesture.onEnded threshold), use @State Bool local to view
- **SwiftData + scanCompletionCount signal (LibraryScanService)**: Analyzed state fix — add explicit completion counter to trigger manual coverage refresh reliably
- **Existing RunEngineService properties (BeatSyncBadge)**: Beat accuracy display — reads `syncQuality`, `cadenceDelta`, and `currentTrackBPM` already published; no new computation required

**Version compatibility:** All changes compatible with iOS 17+ deployment target. No new minimums introduced.

### Expected Features

**Must have (table stakes — define "Beat Perfect"):**
- Sub-2s cadence display response — current 5s rolling window creates perceptible lag; competitors respond in 1-2s
- Player not overlapping tab bar — basic layout correctness; prerequisite for collapsible player work
- Analyzed state updates after scan — broken filter erodes user trust; Analyzed/Unanalyzed counts must update immediately after scan
- Collapsible player strip — two-state (expanded ~60pt / collapsed ~12pt) with swipe-down and tap gestures

**Should have (competitive differentiators — P2):**
- Beat accuracy confidence score — rolling sync score (SPM vs BPM delta over 30s) shown in ActiveRunView; no competitor surfaces this metric
- Adaptive window smoothing — variance-based window (2s when pace is changing rapidly, 4s when steady); no competitor implements this

**Defer to future milestones:**
- Accelerometer-supplemented trend detection — CMMotionManager peak detection pipeline, high complexity
- True phase-aligned beat haptics — requires sub-50ms timing; Spotify progress_ms has 200-500ms latency; would feel wrong
- Post-run sync analysis report
- Full-screen expandable player — third player state creates navigation complexity; ActiveRunView already serves this role during runs

**Anti-features confirmed:** Real-time audio beat detection is architecturally unavailable (Spotify controls playback). Raw accelerometer cadence replacement requires months of signal-processing R&D. Phase-aligned playback start is blocked by Spotify Web API network jitter (100-500ms round trip).

### Architecture Approach

v1.7 modifies six existing components and adds two new ones, with three components deliberately left unchanged (SpotifyPlayerService, BPMCacheService, data models). The build order is strictly dependency-driven: analyzed-state fix is independent and highest trust-impact so it goes first; player layout restructure (VStack dock replacing safeAreaInset) must precede the collapsible player component because the new component depends on the new layout; cadence tuning follows stable player UI so run testing is not confounded by UI bugs; and the BeatSyncBadge goes last as a read-only additive view that benefits from responsive cadence being in place.

**Major components:**
1. **LibraryScanService + PlaylistListView** — add `scanCompletionCount: Int`, always refresh coverage on that signal; fixes analyzed state bug
2. **ContentView** — replace `safeAreaInset` conditional with VStack dock; creates structural slot for CollapsiblePlayerView
3. **CollapsiblePlayerView** — two-state player (expanded/collapsed) with DragGesture.onEnded on handle only; replaces and deletes MiniPlayerView
4. **CadenceService + RunEngineService** — constant tuning (windowDuration 5→3, poll 2s→1s, debounce 17s→8s); split display path from song-selection path
5. **BeatSyncBadge + ActiveRunView** — reads existing `syncQuality` / `cadenceDelta` / `currentTrackBPM` from RunEngineService; purely additive view

### Critical Pitfalls

1. **Cadence jitter from over-reducing window** — Dropping `windowDuration` below 3s produces fewer than 2 samples per averaging window (CMPedometer fires at 1-3s intervals), causing >10 SPM jumps during steady running. Use 3s not 2s. Consider dual-window: 3s for display, 5s for song selection.

2. **17s debounce is the real song-selection bottleneck** — Reducing `windowDuration` alone has almost no effect on how quickly songs change. The 17-second `sustainedChangeTask` debounce in RunEngineService is the dominant latency. Must address all three latency sources (window, poll, debounce) as a system; must also distinguish "display responsiveness" from "song-selection responsiveness" in scope.

3. **safeAreaInset stacking bug on iOS 17.4+** — Animating `safeAreaInset` height for collapse/expand causes content jumps and known tab-bar stacking issues on iOS 17.4+. Resolution: replace entirely with VStack dock (player sits in its own vertical slot between tab content and tab bar).

4. **DragGesture conflicts with ScrollView** — Applying DragGesture to the entire player strip blocks list scrolling when a user's drag begins near the player. Apply DragGesture only to the drag handle element (the small capsule indicator); use tap gesture for expand.

5. **Beat sync false positives from BPM source mismatch** — GetSongBPM sometimes returns half-time or double-time values. The BeatSyncBadge must reuse the existing `SyncQuality.from(delta:tolerance:)` logic which already handles half/double octave matching — do not build a parallel validation system with tighter thresholds.

6. **Analyzed state gap: background scan path** — The existing `onChange(of: scanningPlaylistID)` fix misses the case where PlaylistListView is not yet mounted during background scan at app launch. `scanCompletionCount: Int` on LibraryScanService provides a reliable signal that works regardless of mounting state.

## Implications for Roadmap

All five phases are implementation phases. No phase requires external API research or new framework evaluation — all research is complete and implementation-ready.

### Phase 1: Analyzed State Fix

**Rationale:** Zero dependencies on other features; highest trust-impact per LOC changed. Smallest scope — two files, one new property. Independent fix that can go first in any ordering.
**Delivers:** Reliable Analyzed/Unanalyzed filter counts that update immediately after scan, including background scans on app launch without requiring navigation away and back.
**Addresses:** Table stakes — "analyzed state updates after scan"
**Avoids:** Pitfall 6 (background scan path gap) — `scanCompletionCount` signal fires regardless of PlaylistListView mounting state
**Files:** LibraryScanService.swift (add `scanCompletionCount`), PlaylistListView.swift (observe it, always-refresh coverage)

### Phase 2: Player Dock Fix (Layout Restructure)

**Rationale:** Hard prerequisite for Phase 3. CollapsiblePlayerView requires the VStack dock slot to exist. Building the collapsible player on the broken safeAreaInset layout will compound bugs and require rework.
**Delivers:** Correct player placement — player sits above tab bar without overlap, no double-padding, no gap. VStack slot ready for CollapsiblePlayerView.
**Addresses:** Table stakes — "player not overlapping tab bar"
**Avoids:** Pitfall 3 (safeAreaInset stacking) — VStack dock eliminates the animated-inset-height approach entirely
**Files:** ContentView.swift (replace safeAreaInset with VStack + placeholder slot)

### Phase 3: Collapsible Player Strip

**Rationale:** Depends on Phase 2 layout. CollapsiblePlayerView takes the VStack slot introduced in Phase 2 and replaces MiniPlayerView entirely.
**Delivers:** Expanded/collapsed two-state player with swipe-down to collapse, tap to expand. MiniPlayerView deleted after verification. `@AppStorage` persists collapse preference across restarts.
**Addresses:** Table stakes — "collapsible player strip"
**Avoids:** Pitfall 4 (gesture/scroll conflict) — DragGesture scoped to handle only; Pitfall 3 (height animation) — collapsed height is fixed, no safeAreaInset animation
**Files:** Views/Player/CollapsiblePlayerView.swift (new), Views/Player/CollapsedPlayerBar.swift (new), MiniPlayerView.swift (deleted), ContentView.swift (wire up new component)

### Phase 4: Responsive Cadence Detection

**Rationale:** Player UI must be finalized before cadence-testing during real runs. Cadence tuning touches RunEngineService timing — the core loop — and needs clean test conditions without confounding UI bugs from an unsettled player layout.
**Delivers:** Sub-2s cadence display updates (3s window). Song selection latency drops from 24s worst-case to ~12s (1s poll, 8s debounce). Display path separated from song-selection path so UI shows current cadence even while debounce is still running.
**Addresses:** Table stakes — "sub-2s cadence response"; both display AND selection responsiveness
**Avoids:** Pitfall 1 (jitter from over-reducing window) — 3s not 2s; Pitfall 2 (debounce bottleneck) — addresses window, poll, and debounce as a system; Pitfall 6 (display vs selection distinction) — explicitly separates the two paths
**Files:** CadenceService.swift (windowDuration 5→3, expose display-path), RunEngineService.swift (poll 2s→1s, debounce 17s→8s, split display update)

### Phase 5: Beat Sync Accuracy Badge

**Rationale:** Purely additive read-only view component. No upstream dependencies on the bug fixes, but the badge is most meaningful when cadence is already responsive (Phase 4 complete). Testing it with 5-second-lagging cadence gives misleading impressions of the feature's value.
**Delivers:** BeatSyncBadge in ActiveRunView Zone 2 showing rolling sync quality and confidence. Reads existing `syncQuality`, `cadenceDelta`, `currentTrackBPM` from RunEngineService — zero service changes.
**Addresses:** Differentiator — beat accuracy confidence score (P2 in FEATURES.md)
**Avoids:** Pitfall 5 (BPM octave mismatch) — reuses existing SyncQuality logic which already handles half/double-tempo tracks
**Files:** Views/Run/BeatSyncBadge.swift (new), ActiveRunView.swift (add badge to Zone 2)

### Phase Ordering Rationale

- **Phases 1-2 fix the foundation** before new features are built. Bug fixes first builds user trust and provides clean test conditions.
- **Phase 2 before 3** is a hard architectural dependency: CollapsiblePlayerView requires the VStack dock slot in ContentView.
- **Phase 1 is fully independent** and could be parallelized with Phase 2 if two developers are available. Sequentially it goes first for immediate trust impact.
- **Phase 4 before 5** is a logical dependency: responsive cadence gives the BeatSyncBadge meaningful, current data to display. With 5s-lagging cadence the badge would be misleading.
- **Phase 5 is always last** — purely additive, zero risk, highest dependency on all prior work being stable.

### Research Flags

No phases require `/gsd:research-phase` — all research is complete and implementation-ready based on direct codebase analysis.

Standard patterns — can proceed directly to planning:
- **Phase 1 (Analyzed State Fix):** Root cause confirmed by architecture research. Two-part fix (scanCompletionCount + always-refresh) is straightforward.
- **Phase 2 (Player Dock Fix):** VStack dock is the standard Spotify/Apple Music pattern. ARCHITECTURE.md has the exact code pattern.
- **Phase 3 (Collapsible Player):** STACK.md has a complete implementation sketch. DragGesture.onEnded with threshold is an existing project pattern.
- **Phase 4 (Cadence Tuning):** All target constants identified. Split of display vs song-selection path is explicitly specified. No new logic required.
- **Phase 5 (Beat Sync Badge):** All data already published by RunEngineService. Badge is a read-only view. No new computation path required.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Zero new dependencies confirmed. All tuning targets identified from direct code analysis. CMPedometer callback frequency confirmed from Apple docs. |
| Features | MEDIUM-HIGH | P1 features are clear and research-confirmed. P2 adaptive window has less codebase prior art but algorithm is standard signal-processing. |
| Architecture | HIGH | Based on direct codebase inspection of all 7 affected files. Build order validated against real dependency graph. VStack dock approach confirmed against Apple safeAreaInset docs. |
| Pitfalls | HIGH | All 6 pitfalls backed by Apple Developer Forum threads, official docs, or direct code path analysis with file/line identification. |

**Overall confidence:** HIGH

### Gaps to Address

- **windowDuration sweet spot — 2.5s vs 3.0s:** STACK.md recommends 2.5s, ARCHITECTURE.md recommends 3.0s. Validate empirically during a real run at 170+ SPM using Sensor Lab. Start with 3.0s, reduce to 2.5s only if the waveform shows acceptable stability with no >10 SPM jumps between consecutive readings.

- **Debounce tuning — 6s vs 8s:** STACK.md recommends 6s, ARCHITECTURE.md recommends 8s for the sustained-change debounce. Start with 8s and reduce only if real-run testing reveals users perceive lag after pace changes. Extract to a named constant (`RunEngineService.sustainedChangeDebounceDuration`) rather than leaving as a hardcoded literal, to enable easy tuning.

- **Analyzed state timing race confirmation:** The two-part fix (scanCompletionCount + always-refresh-coverage) addresses both identified gaps, but the exact reproduction sequence of the timing race between `context.save()` and `scanningPlaylistID = nil` notification should be confirmed during Phase 1 implementation. If only the always-refresh approach is needed, the scanCompletionCount addition is still the right signal regardless.

- **CollapsiblePlayerView vs MiniPlayerView reuse strategy:** ARCHITECTURE.md recommends deleting MiniPlayerView after CollapsiblePlayerView is verified. STACK.md suggests keeping MiniPlayerView unchanged as an internal component wrapped by CollapsiblePlayerView. The wrapper approach reduces risk; the replacement approach eliminates dead code. Decide during Phase 3 implementation based on how much internal MiniPlayerView content is directly reusable.

## Sources

### Primary (HIGH confidence)
- Apple Developer Documentation: CMPedometer startUpdates callback frequency, safeAreaInset behavior, SwiftData context.save() / @Observable semantics
- Direct codebase analysis: CadenceService.swift, RunEngineService.swift, ContentView.swift, MiniPlayerView.swift, PlaylistListView.swift, LibraryScanService.swift, ActiveRunView.swift, ScannedPlaylist.swift — all latency values, constant names, and code paths confirmed from source
- PROJECT.md key decisions — DragGesture.onEnded pattern, @Observable polling pattern, BSAnimation.smooth

### Secondary (MEDIUM confidence)
- Apple Developer Forums: safeAreaInset + TabView stacking bug (iOS 17.4+), SwiftData model not propagating to view layer, DragGesture conflicts with ScrollView
- Hacking with Swift: @Observable not always updating child views, SwiftData child views not updating on insertions
- Buhmann et al. "Optimizing beat synchronized running to music" (PLOS ONE, 2018) — phase alignment and auditory-motor synchronization research
- Van Dyck et al. "Enhancing Running Performance by Coupling Cadence with the Right Beats" (PLOS ONE, 2013)

### Tertiary (MEDIUM-LOW confidence)
- Competitor analysis (TrailMix, RockMyRun, Weav Run) — cadence response time estimates and feature gap assessment; based on App Store observation and published documentation, not internal testing
- iOS 26.1 Apple Music swipe gesture direction — directional confirmation for mini-player UX pattern

---
*Research completed: 2026-03-26*
*Ready for roadmap: yes*
