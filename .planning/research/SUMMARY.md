# Project Research Summary

**Project:** BeatStep v1.3 — In The Zone
**Domain:** Native iOS running music app — active run experience rebuild
**Researched:** 2026-03-24
**Confidence:** HIGH

## Executive Summary

BeatStep v1.3 rebuilds the active run screen into a focused, glanceable experience with three visual zones: a status bar (zone, elapsed time, sync state), a hero cadence display (big SPM number, delta indicator, sync color), and an integrated music player (album art, song/artist, controls, BPM, half-tempo toggle). This replaces the current monolithic RunView (269 lines handling 5 states) and the disconnected MiniPlayer strip.

Zero new external dependencies are needed. Every capability — numeric text animation, phase-driven effects, haptic feedback, async image loading, long-press gestures, periodic time updates — is available in SwiftUI's iOS 17 built-in APIs. The RunEngineService needs three new observable properties (syncQuality, tempoMode, runStartTime) but its core matching logic stays intact. CadenceService and SpotifyPlayerService are unchanged.

The highest-risk feature is half-tempo matching: the existing `findMatchingTracks` already checks `spm/2` and `spm*2`. A naive implementation that divides the input BPM by 2 causes double-halving (spm/4 = ~42 BPM — no songs exist there). Half-tempo must be implemented as a ranking preference, not a BPM transformation. The second risk is false pause triggers: the current 5-second inactivity threshold is too aggressive for v1.3's deliberate pause UX (music behavior, visual state changes), and should increase to 8-10 seconds.

## Key Findings

### Recommended Stack

All first-party Apple APIs on iOS 17+. No new dependencies.

**Core technologies:**
- `.contentTransition(.numericText())` — per-digit cadence counter animation with direction awareness
- `.phaseAnimator` — pulse/breathe effects for sync state and pause state (already in use in RunView)
- `.sensoryFeedback()` — haptic confirmation on long-press completion, half-tempo toggle, zone transitions
- `AsyncImage` + thin `NSCache` wrapper — album art from Spotify CDN (300px for 80pt display)
- `TimelineView` / `Text(date, style: .timer)` — elapsed run time without Combine
- `.onLongPressGesture(minimumDuration:onPressingChanged:)` — protected stop action with progress ring

### Expected Features

**Must have (table stakes):**
- Large center-stage cadence number — every fitness app puts primary metric big and center
- Elapsed run time — universal across NRC, Strava, Apple Fitness
- Now Playing: song + artist + album art — users expect to know what's playing
- Play/pause + skip controls — thumb-reachable, 44pt+ touch targets
- Song BPM visible — BeatStep's entire value prop; hiding it contradicts the promise
- Zone/mode indicator — confirm which zone is active
- Protected stop action — long-press prevents accidental mid-run stop
- Pause-aware idle state — deliberate design when cadence drops

**Should have (competitive differentiators):**
- Sync state indicator (in-sync/drifting/mismatched) — no competitor visualizes cadence-to-music sync. This is genuinely novel
- Delta indicator ("+4 SPM") — quantifies the gap; runners can self-correct pace
- Half-tempo toggle (1:1 vs 1/2) — makes the 180 SPM / 90 BPM relationship explicit and controllable
- Zone band visualization — spatial awareness of where cadence sits within target range
- Cadence-responsive color shift — subconscious sync feedback

**Defer (v2+):**
- Haptic feedback on sync state changes
- Live Activities / Dynamic Island
- Apple Watch companion
- Customizable run screen layout

### Architecture Approach

Split RunView (currently 269 lines, 5 states) into: idle/detecting stays in RunView, active/paused moves to a new ActiveRunView presented via `fullScreenCover`. This prevents accidental dismissal (interactiveDismissDisabled), hides the tab bar automatically, and separates pre-run setup from the running experience. Pause state is an overlay on ActiveRunView, not a navigation transition — music keeps playing, run state preserved.

**New components:**
1. `ActiveRunView` — full-screen run experience container, presented via fullScreenCover
2. `RunStatusBar` — zone label, sync quality badge, elapsed time
3. `RunPlayerView` — album art, song/artist, BPM badge, controls, half-tempo toggle
4. `PauseOverlayView` — translucent overlay when cadence pauses

**Modified components:**
5. `RunEngineService` — add TempoMode, syncQuality, cadenceDelta, runStartTime
6. `CadenceDisplayView` — add delta label, sync color, zone band
7. `RunView` — simplify to idle/detecting only
8. `MiniPlayerView` — hide when ActiveRunView is showing (one-line change)
9. `DesignTokens` — add sync color aliases, delta font, component sizes

### Critical Pitfalls

1. **Half-tempo double-halving** — `findMatchingTracks` already checks spm/2. Adding another /2 creates spm/4 (~42 BPM). Implement as ranking preference, not BPM transformation.

2. **False pause triggers** — 5-second inactivity threshold is too aggressive for v1.3's deliberate pause UX. Increase to 8-10 seconds; add internal `.pausePending` intermediate state.

3. **Free mode delta is meaningless** — Delta assumes a fixed reference (guided mode target). In free mode, show sync quality (in-sync/adapting) not corrective delta (+4 SPM). Never show corrective arrows in free mode.

4. **Accidental run dismissal** — Current `onDisappear { stopRun() }` + NavigationLink allows swipe-to-dismiss. Use `fullScreenCover(interactiveDismissDisabled: true)` with explicit long-press stop only.

5. **Background/foreground pipeline break** — CMPedometer delivers in background but song-end polling gets suspended. Add "catch up on foreground" pattern: fetch current playback + cadence on `scenePhase == .active`, re-evaluate match.

## Implications for Roadmap

### Phase 1: RunEngine Extensions + Design Tokens

**Rationale:** All new views depend on syncQuality, cadenceDelta, tempoMode, and runStartTime. Building views without this data means placeholder logic that gets rewritten.
**Delivers:** TempoMode enum, syncQuality computed property, cadenceDelta, runStartTime tracking, modified findMatchingTracks for explicit tempo mode, new design token aliases (sync colors, delta font, component sizes).
**Addresses:** Half-tempo matching engine logic, sync state computation
**Avoids:** Pitfall 1 (half-tempo double-halving) by designing the matching change first

### Phase 2: CadenceDisplayView + RunStatusBar

**Rationale:** Center-stage cadence and status bar are self-contained components that read from Phase 1's new engine properties. Can be previewed independently before the full run screen exists.
**Delivers:** Enhanced CadenceDisplayView (big SPM, delta label, sync color, zone band), RunStatusBar (zone label, match quality, elapsed time via Text(date, style: .timer)).
**Addresses:** Cadence indicators, elapsed time display
**Avoids:** Pitfall 3 (free mode delta) by making delta display mode-aware from the start, Pitfall 7 (choppy updates) by observing CadenceService directly

### Phase 3: RunPlayerView

**Rationale:** Independent component, no dependency on ActiveRunView layout. Reads from SpotifyPlayerService (already complete) and RunEngineService (Phase 1 additions). Can be previewed standalone.
**Delivers:** Album art (AsyncImage + NSCache), song/artist display, BPM badge, play/pause/skip controls, half-tempo toggle UI.
**Addresses:** Integrated music player, half-tempo toggle UX
**Avoids:** Pitfall 6 (album art memory) by building caching from the start

### Phase 4: ActiveRunView Assembly + Pause State

**Rationale:** Pure composition — all building blocks exist from Phases 1-3. Wire up the full-screen experience, add pause overlay, handle dismissal and lifecycle.
**Delivers:** ActiveRunView (fullScreenCover, composition of all sub-views), PauseOverlayView (dimmed metrics, music continues), long-press-to-end with progress ring, MiniPlayer hide-when-active, idle timer management, foreground catch-up logic.
**Addresses:** Run screen rebuild, pause/idle state, protected stop action
**Avoids:** Pitfall 4 (accidental dismissal) via interactiveDismissDisabled, Pitfall 2 (false pauses) by tuning inactivity threshold, Pitfall 9 (background break) with foreground catch-up

### Phase Ordering Rationale

- **Engine before views:** syncQuality, cadenceDelta, tempoMode must exist before any view can consume them
- **Components before container:** CadenceDisplayView, RunStatusBar, RunPlayerView are built and previewed independently, then composed into ActiveRunView
- **Pause last (with assembly):** Pause overlay is a thin layer on top of the complete run screen; it needs all other elements to exist so it knows what to dim
- **4 phases, not 5:** Assembly and pause state are tightly coupled (pause affects all display areas) — combining them avoids a too-thin final phase

### Research Flags

Phases with standard patterns (skip research-phase):
- **Phase 1:** Engine extensions are well-defined computed properties; matching change is a sort preference tweak
- **Phase 2:** SwiftUI built-in APIs (contentTransition, TimelineView); patterns documented in STACK.md
- **Phase 3:** AsyncImage + NSCache is standard; player controls mirror existing MiniPlayerView

Phases that may benefit from brief research:
- **Phase 4:** Background/foreground lifecycle handling — verify song-end prediction approach works with Spotify Web API's playback state response

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | All first-party Apple APIs at iOS 17 target; zero new dependencies; verified against Apple docs |
| Features | HIGH | Feature list derived from competitor analysis + codebase capabilities; novel sync indicator has no precedent but is straightforward computation |
| Architecture | HIGH | Based on full codebase read of all 29 Swift source files; integration points verified |
| Pitfalls | HIGH | 9 specific pitfalls with prevention strategies; derived from codebase inspection + Apple docs |

**Overall confidence:** HIGH

### Gaps to Address

- **Music behavior during pause:** Research recommends keeping music playing (runner at traffic light). Confirm this as the default behavior during Phase 4.
- **Half-tempo default:** 1:1 is the intuitive default, but if most songs in typical playlists are ~90 BPM, 1/2 might be better. Test with real song pools during implementation.
- **Inactivity threshold tuning:** Research suggests 8-10 seconds. Exact value needs physical device testing during Phase 4 — Simulator cannot replicate real CMPedometer timing.

## Sources

### Primary (HIGH confidence)
- Apple Developer Documentation: contentTransition(.numericText()), phaseAnimator, sensoryFeedback, AsyncImage, LongPressGesture, TimelineView
- Full codebase read: all Swift source files under /BeatStep/ (29 files)
- RunEngineService.swift: findMatchingTracks logic, effectiveBPM, cadence monitor polling

### Secondary (MEDIUM confidence)
- Competitor analysis: Nike Run Club, Strava, TrailMix, RockMyRun, Weav Run — App Store listings and public documentation
- Running literature: spontaneous entrainment of cadence to music tempo (PMC), half/double tempo matching patterns

### Tertiary (LOW confidence)
- Spotify Web API rate limits: community-reported ~180 req/min, not officially documented per-endpoint

---
*Research completed: 2026-03-24*
*Ready for roadmap: yes*
