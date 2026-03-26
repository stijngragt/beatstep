# Feature Research

**Domain:** Running music sync -- cadence responsiveness, beat accuracy, collapsible player UX
**Researched:** 2026-03-26
**Confidence:** MEDIUM-HIGH

## Feature Landscape

### Table Stakes (Users Expect These)

Features that v1.7 must deliver. Without these, the "Beat Perfect" milestone name is misleading.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Sub-2s cadence response | Current 5s rolling window creates perceptible lag. Competitors (TrailMix, RockMyRun) respond within 1-2 seconds. Users changing pace expect music to follow quickly. | MEDIUM | CadenceService uses 5s `windowDuration` with CMPedometer. Reducing window to 2-3s is low-risk. Supplementing with CMMotionManager accelerometer (100Hz) for sub-second peaks is possible but overkill -- CMPedometer delivers ~1 update/sec already. The bottleneck is the averaging window, not the sensor. |
| Player not overlapping tab bar | Currently `.safeAreaInset(edge: .bottom)` on the TabView should push content up, but the reported bug means the player covers the tab bar in certain states. Basic layout correctness. | LOW | Likely a conditional rendering or z-ordering issue in ContentView where MiniPlayerView renders inside `.safeAreaInset` but something pushes it over the tab bar. Debug by inspecting the view hierarchy. Straightforward fix once root cause is identified. |
| Analyzed state updates after scan | Broken filter (analyzed/unanalyzed) shows stale results after scanning a playlist. Users cannot trust what they see. | LOW | Root cause is likely that `PlaylistListView` does not re-query coverage data after `LibraryScanService` completes a scan. SwiftData observation may not be triggering a view refresh. Fix with explicit notification or by ensuring the `@Query` or coverage map is invalidated on scan completion. |

### Differentiators (Competitive Advantage)

Features that make BeatStep meaningfully better than TrailMix, RockMyRun, and Weav Run.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Collapsible player strip (expand/collapse) | No running-music app has a collapsible mini-player. Spotify and Apple Music do, but running apps show a static bar. Lets the runner minimize visual noise outside of runs while keeping controls accessible. | MEDIUM | Two states: expanded (current MiniPlayerView with BPM pill, title, controls at 64pt) and collapsed (thin strip ~24-28pt with drag handle, truncated title, play/pause only). Swipe-down to collapse, tap to expand. Use `matchedGeometryEffect` for smooth morphing of the play/pause button between positions. The `safeAreaInset` height changes dynamically with state -- SwiftUI handles this natively. Persist preference in `@AppStorage`. |
| Beat accuracy confidence score | No running music app surfaces how well the music BPM actually tracks the runner's cadence over time. BeatStep already has sync badges (in-sync/drifting/mismatched) but they are instantaneous snapshots. A rolling "sync score" that builds confidence over sustained matching is more meaningful. | MEDIUM | Compute score based on how closely SPM has tracked BPM over the last 30-60 seconds. Simple formula: `score = max(0, 100 - avgDelta * 5)` where `avgDelta` is the average absolute difference between SPM and track BPM over the window. Display as a percentage or ring fill in ActiveRunView. No accelerometer work needed -- this uses existing CadenceService.currentSPM and track BPM. |
| Adaptive window cadence smoothing | Instead of a fixed window, use a shorter window (2s) when cadence is changing rapidly and a longer window (4s) when steady. Gives fast response to real pace changes while filtering noise during steady running. | MEDIUM | Detect cadence variance: compute standard deviation of last 5 cadence samples. High stddev (>8 SPM) = use 2s window, low stddev = use 4s window. This is the approach used by research-grade running analysis. No competitor does this -- they all use fixed averaging. |

### Anti-Features (Commonly Requested, Often Problematic)

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| Raw accelerometer cadence replacing CMPedometer | "CMPedometer is too slow, use raw accelerometer at 100Hz" | CMMotionManager gives raw data but requires building a step-detection algorithm (peak detection, low-pass filtering, stride classification). This is a deep signal-processing problem. False positives cause worse UX than slight lag. CMPedometer is Apple's battle-tested algorithm -- it exists precisely because raw accelerometer step detection is hard. | Keep CMPedometer as authoritative cadence source. Reduce the rolling window for faster response. Optionally supplement with accelerometer for trend-change detection only (detect that pace is changing before CMPedometer reports the new value). |
| Real-time audio beat detection | "Detect beats from the actual audio stream for true phase alignment" | BeatStep does not have access to the raw audio stream -- Spotify Web API controls playback remotely. Even if audio were available, on-device beat detection introduces its own 100-500ms latency, and running outdoors with wind/noise degrades microphone input. | Use pre-analyzed BPM from GetSongBPM API (already working). BPM is known before the song plays -- more reliable than real-time detection. |
| Full-screen expandable player (Apple Music style) | "Tap mini-player to see full album art, progress bar, lyrics" | BeatStep already has an 80pt album art player in ActiveRunView. A third player state (mini -> expanded -> full) creates navigation complexity. Outside of runs, the player's job is minimal -- show what's playing and provide play/skip. During runs, ActiveRunView IS the full player. | Two states only: expanded strip (current MiniPlayerView) and collapsed handle. No third state. |
| Phase-aligned beat synchronization | Research shows footfalls 20-50ms before beats increases motivation (Buhmann et al., 2018). "Adjust playback timing to align beats with footstrikes." | Requires sub-millisecond audio timing control that Spotify Web API does not provide. Cannot adjust playback start position with ms precision. Even `play(uri:position_ms:)` has network round-trip jitter of 100-500ms. | Surface sync quality as information (existing badges). Runners naturally phase-synchronize when BPM matches within +/-2 SPM -- the research confirms this happens automatically without technical intervention. |
| Persistent always-visible player during runs | "Keep the mini-player visible during ActiveRunView too" | ActiveRunView is already a full-screen player with all controls. Showing the mini-player AND the run view creates redundant controls, wastes screen real estate, and confuses which controls to use. | MiniPlayerView is already correctly hidden via `!RunEngineService.shared.isRunActive` check. Keep this behavior. |

## Feature Dependencies

```
[Cadence responsiveness (<2s)]
    |
    +--enables--> [Accurate sync quality display in ActiveRunView]
    |                 |
    |                 +--enables--> [Beat accuracy confidence score]
    |
    +--enables--> [Faster song re-matching on pace change]

[Player nav bar fix]
    |
    +--unblocks--> [Collapsible player strip]
                       |
                       +--requires--> [Dynamic safeAreaInset height]

[Analyzed state fix]
    (independent -- no downstream dependencies in v1.7)
```

### Dependency Notes

- **Cadence responsiveness before beat accuracy score:** The confidence score depends on a responsive cadence signal. If cadence lags 5 seconds behind reality, any accuracy metric computed from it will be meaningless -- it would measure lag, not sync quality.
- **Nav bar fix before collapsible player:** The overlap bug must be fixed first because the collapsible player modifies the same `safeAreaInset` layout system. Building collapse behavior on a broken foundation will compound bugs and make debugging harder.
- **Analyzed state fix is independent:** Can be done in any order. It is a data-layer fix with no UI coupling to the other v1.7 features.

## v1.7 Scope Definition

### Must Ship (P1)

- [ ] Cadence responsiveness: reduce rolling window from 5s to 2-3s adaptive -- single most impactful change for the "Beat Perfect" promise
- [ ] Nav bar overlap fix -- bug fix, prerequisite for player work
- [ ] Analyzed state fix -- bug fix, restores filter functionality users depend on
- [ ] Collapsible player strip -- expanded and collapsed states with swipe gesture

### Should Ship (P2)

- [ ] Beat accuracy confidence score -- rolling "sync score" displayed in ActiveRunView, computed from SPM-vs-BPM delta over time
- [ ] Adaptive window smoothing -- variance-based window duration (2s when changing, 4s when steady)

### Defer (Future Milestones)

- [ ] Accelerometer-supplemented trend detection -- use CMMotionManager to detect pace-change onset before CMPedometer reports it
- [ ] True beat-phase alignment via per-step timestamps -- requires CMMotionManager peak detection pipeline
- [ ] Post-run sync analysis report -- show how well-synced the run was over time

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| Cadence responsiveness (<2s) | HIGH | LOW | P1 |
| Nav bar overlap fix | HIGH | LOW | P1 |
| Analyzed state fix | MEDIUM | LOW | P1 |
| Collapsible player strip | MEDIUM | MEDIUM | P1 |
| Beat accuracy confidence score | MEDIUM | MEDIUM | P2 |
| Adaptive window smoothing | MEDIUM | MEDIUM | P2 |
| Accelerometer trend detection | HIGH | HIGH | Future |

**Priority key:**
- P1: Must ship in v1.7 -- these define "Beat Perfect"
- P2: Should ship if time allows -- enhances the core loop
- Future: Needs dedicated R&D milestone

## Competitor Feature Analysis

| Feature | TrailMix | RockMyRun | Weav Run | BeatStep (v1.7 target) |
|---------|----------|-----------|----------|------------------------|
| Cadence detection speed | ~1-2s (on-device beat detection of audio) | ~2-3s ("Body-Driven Music") | Real-time (audio tempo-stretching) | Target: <2s (adaptive rolling window on CMPedometer) |
| Beat-step sync metric | None visible | None visible | None (stretches audio to match) | Sync quality badge + confidence score (differentiator) |
| Collapsible player | No (static bar) | No (static bar) | No (integrated view) | Yes -- expanded/collapsed with swipe (differentiator) |
| BPM source | On-device audio analysis | Pre-analyzed catalog | Pre-analyzed + real-time stretch | GetSongBPM API (pre-analyzed, via Cloudflare Worker) |
| Song matching approach | Queue BPM-matched songs | Adaptive playlist ordering | Real-time tempo stretching | Queue + half/double BPM + danceability ranking |
| Cadence sensor | Device motion sensors | Device motion sensors | Device motion sensors | CMPedometer (Apple's pedometer, battle-tested) |

**Key insight:** Weav Run is the only competitor doing real-time tempo stretching, but they require specially prepared music from their own catalog -- users cannot use their own Spotify library. TrailMix and RockMyRun use queue-based matching like BeatStep. BeatStep's competitive edge in v1.7 is: (1) transparency -- showing a quantified sync score, (2) responsiveness -- adaptive window cadence, and (3) UX -- collapsible player. None of these exist in any competitor.

## Implementation Notes

### Cadence Responsiveness

Current `CadenceService` bottleneck is the fixed 5-second `windowDuration` on line 23. CMPedometer delivers `currentCadence` roughly every 1 second during active movement. With a 5s window, it takes 5 updates before the rolling average fully reflects a pace change.

**Recommended approach (two-step):**

1. **Immediate win:** Reduce `windowDuration` from 5.0 to 3.0. This halves response time with minimal noise increase. Low risk, high impact.

2. **Adaptive window (P2):** Track variance of recent cadence samples. If stddev of last 5 samples > 8 SPM (indicating the runner is changing pace), temporarily use a 2s window. When stddev drops below 5 SPM (steady pace), expand to 4s. This gives sub-2s response to real changes while smoothing noise at steady state.

The step delta fallback in `handlePedometerData` (lines 126-139) already provides cadence when `currentCadence` is nil. This is good -- it covers devices or conditions where CMPedometer does not report cadence directly.

### Collapsible Player Strip

Current MiniPlayerView is 64pt (`DesignTokens.miniPlayerHeight`). The collapsible design:

- **Expanded state (default):** Current layout -- BPM pill, track info (title + artist), play/pause, skip. Height: 64pt.
- **Collapsed state:** Thin strip with subtle drag handle (3pt x 36pt rounded rect), truncated song title, and a small play/pause button. Height: ~28pt.
- **Gesture:** Swipe down on expanded state to collapse. Tap anywhere on collapsed state to expand. Do NOT use DragGesture for this -- it conflicts with scroll gestures. Use a simple `onTapGesture` for expand and a swipe-down detection (threshold ~40pt vertical translation).
- **Animation:** `matchedGeometryEffect` on the play/pause button so it morphs position between expanded and collapsed layouts. Use `BSAnimation.smooth` (existing spring preset) for the height transition.
- **Layout:** Keep `.safeAreaInset(edge: .bottom)` -- just change the content height based on `@State private var isCollapsed: Bool`. SwiftUI automatically re-layouts surrounding content.
- **Persistence:** `@AppStorage("playerCollapsed") var isCollapsed = false` so the preference survives app restarts.

### Beat Accuracy Confidence Score (P2)

Score formula without accelerometer work:

```
recentDeltas: rolling buffer of |currentSPM - trackBPM| values, sampled every 2 seconds, last 30 seconds (15 samples)
avgDelta = mean(recentDeltas)
syncScore = max(0, 100 - avgDelta * 5)
```

This means: perfect match (0 delta) = 100, 5 SPM off = 75, 10 SPM off = 50, 20+ SPM off = 0.

Display in ActiveRunView as a small ring or arc next to the existing sync quality badge. The badge gives qualitative state (in-sync/drifting/mismatched), the score gives quantitative confidence.

### Player Nav Bar Fix

The MiniPlayerView is mounted via `.safeAreaInset(edge: .bottom)` on the TabView (ContentView.swift line 90). This should push tab content up, not cover the tab bar. Possible root causes:

1. The `.safeAreaInset` is applied to the TabView rather than inside individual tab NavigationStacks. On some iOS versions, this can cause the inset to push into the tab bar area rather than above it.
2. The conditional `if SpotifyPlayerService.shared.currentTrack != nil` may cause layout recalculation issues where the space is reserved but the view clips over the tab bar.

Fix approach: move the MiniPlayerView into an overlay or VStack inside each tab's NavigationStack, or use `.toolbar(.visible, for: .tabBar)` to ensure the tab bar is always visible when the player is shown. Test on multiple iOS versions.

## Sources

- [CMPedometer Documentation](https://developer.apple.com/documentation/coremotion/cmpedometer) -- update frequency, cadence API
- [CMPedometerData.currentCadence](https://developer.apple.com/documentation/coremotion/cmpedometerdata/currentcadence) -- steps/second measurement
- [Core Motion Overview](https://developer.apple.com/documentation/coremotion/) -- CMMotionManager 100Hz alternative for raw accelerometer
- [WWDC 2015: What's New in Core Motion](https://developer.apple.com/videos/play/wwdc2015/705/) -- cadence introduction, CMPedometer design rationale
- [Buhmann et al. "Optimizing beat synchronized running to music" (PLOS ONE, 2018)](https://journals.plos.org/plosone/article?id=10.1371/journal.pone.0208702) -- negative mean asynchrony, phase alignment effects on motivation and cadence
- [Van Dyck et al. "Enhancing Running Performance by Coupling Cadence with the Right Beats" (PLOS ONE, 2013)](https://journals.plos.org/plosone/article?id=10.1371/journal.pone.0070758) -- auditory-motor synchronization in running
- [iOS 26.1 Apple Music MiniPlayer swipe gesture](https://www.macobserver.com/news/ios-26-1-beta-adds-swipe-gesture-to-apple-music-miniplayer/) -- Apple's latest mini-player UX direction
- [MinimizableView SwiftUI library](https://github.com/DominikButz/MinimizableView) -- reference implementation for mini-player collapse/expand pattern
- [SwiftUI safeAreaInset](https://www.hackingwithswift.com/quick-start/swiftui/how-to-inset-the-safe-area-with-custom-content) -- dynamic bottom inset for player bars
- [matchedGeometryEffect](https://designcode.io/swiftui-handbook-matched-geometry-effect/) -- smooth element morphing between view states
- [TrailMix](https://apps.apple.com/us/app/trailmix-step-to-the-beat/id647651691) -- competitor: on-device beat detection, ~1-2s response
- [RockMyRun](https://www.rockmyrun.com/) -- competitor: Body-Driven Music adaptive tempo
- [Runo](https://www.runoapp.com/) -- competitor: metronome-based cadence guidance

---
*Feature research for: BeatStep v1.7 Beat Perfect*
*Researched: 2026-03-26*
