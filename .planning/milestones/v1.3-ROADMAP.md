# Roadmap: BeatStep

## Milestones

- v1.0 MVP -- Phases 1-5 (shipped 2026-03-23)
- v1.1 Dark by Design -- Phases 6-9 (shipped 2026-03-24)
- v1.2 The Right Flow -- Phases 10-12 (shipped 2026-03-24)
- **v1.3 In The Zone** -- Phases 13-17 (in progress)

## Phases

<details>
<summary>v1.0 MVP (Phases 1-5) -- SHIPPED 2026-03-23</summary>

- [x] Phase 1: Spotify Integration (2/2 plans) -- completed 2026-03-19
- [x] Phase 2: BPM Data Pipeline (3/3 plans) -- completed 2026-03-20
- [x] Phase 3: Cadence Detection (2/2 plans) -- completed 2026-03-20
- [x] Phase 4: Core Loop / Free Run (2/2 plans) -- completed 2026-03-20
- [x] Phase 5: Guided Run + Polish (2/2 plans) -- completed 2026-03-23

</details>

<details>
<summary>v1.1 Dark by Design (Phases 6-9) -- SHIPPED 2026-03-24</summary>

- [x] Phase 6: Design System Foundation (2/2 plans) -- completed 2026-03-23
- [x] Phase 7: Tab Navigation Shell (1/1 plan) -- completed 2026-03-23
- [x] Phase 8: Token Adoption + RunHomeView (2/2 plans) -- completed 2026-03-23
- [x] Phase 9: Bug Fix + Brand Assets (2/2 plans) -- completed 2026-03-24

</details>

<details>
<summary>v1.2 The Right Flow (Phases 10-12) -- SHIPPED 2026-03-24</summary>

- [x] Phase 10: Models, Settings & Library UX (2/2 plans) -- completed 2026-03-24
- [x] Phase 11: Run Experience (2/2 plans) -- completed 2026-03-24
- [x] Phase 12: Onboarding (2/2 plans) -- completed 2026-03-24

</details>

### v1.3 In The Zone

- [x] **Phase 13: Engine Extensions + Design Tokens** - Add syncQuality, cadenceDelta, tempoMode to RunEngineService and sync color tokens to DesignTokens (completed 2026-03-24)
- [x] **Phase 14: Cadence Display + Status Bar** - Build enhanced CadenceDisplayView and RunStatusBar as standalone previewable components (completed 2026-03-24)
- [x] **Phase 15: Run Player View** - Build integrated music player with album art, track info, BPM, and playback controls (completed 2026-03-24)
- [x] **Phase 16: Active Run Assembly** - Compose full-screen ActiveRunView via fullScreenCover with long-press stop and MiniPlayer hiding (completed 2026-03-24)
- [x] **Phase 17: Tempo Mode Toggle** - Add UI toggle for 1:1/1:2 tempo matching in the active run screen (gap closure) (completed 2026-03-25)

## Phase Details

### Phase 13: Engine Extensions + Design Tokens
**Goal**: RunEngineService exposes the computed state that all run screen views depend on -- sync quality, cadence delta, and tempo mode -- plus design tokens for sync-state colors
**Depends on**: Phase 12
**Requirements**: PLR-04, CAD-01, CAD-02
**Success Criteria** (what must be TRUE):
  1. RunEngineService publishes a syncQuality value (inSync, drifting, mismatched) that updates as cadence changes relative to current song BPM
  2. RunEngineService publishes a signed cadenceDelta (e.g., +4, -6) in guided mode and a sync quality label in free mode
  3. User can toggle between 1:1 and 1/2 tempo matching, and findMatchingTracks respects the mode as a ranking preference (not a BPM /2 transformation)
  4. DesignTokens includes sync-state color aliases (inSync, drifting, mismatched) usable by downstream views
**Plans**: 2 plans

Plans:
- [ ] 13-01-PLAN.md — Model types (TempoMode, SyncQuality), sync-state color tokens, threshold tests
- [ ] 13-02-PLAN.md — Wire models into RunEngineService, half-tempo ranking in findMatchingTracks

### Phase 14: Cadence Display + Status Bar
**Goal**: Runners see rich, glanceable cadence feedback and run status as standalone components that work in SwiftUI previews before the full screen is assembled
**Depends on**: Phase 13
**Requirements**: RUN-03, CAD-03, CAD-04, CAD-05
**Success Criteria** (what must be TRUE):
  1. User sees current zone name and a color-coded sync quality badge in a RunStatusBar component
  2. User sees a zone band visualization showing where current cadence sits within the target zone BPM range (guided mode only)
  3. User perceives a subtle background color shift reflecting sync state (in-sync to drifting to mismatched)
  4. User sees ramp phase progress (warm-up / at-pace / cool-down) during guided mode runs
**Plans**: 2 plans

Plans:
- [ ] 14-01-PLAN.md — RunStatusBar + SyncBadge, SyncBackgroundModifier, SyncQuality.color extension
- [ ] 14-02-PLAN.md — ZoneBandView, RampPhaseIndicator, enhanced CadenceDisplayView with sync color + delta

### Phase 15: Run Player View
**Goal**: Runners see what song is playing with full context and can control playback with large touch targets, all in a standalone previewable component
**Depends on**: Phase 13
**Requirements**: PLR-01, PLR-02, PLR-03
**Success Criteria** (what must be TRUE):
  1. User sees 80pt album art for the currently playing track, loaded from Spotify CDN with caching
  2. User sees song name, artist name, and current track BPM displayed in the player area
  3. User can play/pause and skip tracks using large touch targets (56pt+) that are easy to hit while running
**Plans**: 1 plan

Plans:
- [ ] 15-01-PLAN.md — RunPlayerView with album art, track info, BPM, and 56pt+ playback controls

### Phase 16: Active Run Assembly
**Goal**: The complete run experience works end-to-end -- a focused full-screen view composes all components, prevents accidental dismissal, and hides the MiniPlayer
**Depends on**: Phase 14, Phase 15
**Requirements**: RUN-01, RUN-02
**Success Criteria** (what must be TRUE):
  1. User sees a full-screen active run view (status bar, hero cadence, player) presented via fullScreenCover when a run starts, with no swipe-to-dismiss possible
  2. User can stop a run only via long-press (2-second hold with visual progress ring) -- no other dismiss path exists
  3. MiniPlayer hides automatically when ActiveRunView is showing and reappears when the run ends
  4. Tab bar is not visible during the active run screen
**Plans**: 2 plans

Plans:
- [ ] 16-01-PLAN.md — ActiveRunView + LongPressStopButton with TDD progress tests
- [ ] 16-02-PLAN.md — Wire fullScreenCover into RunView, hide MiniPlayer, end-to-end verification

### Phase 17: Tempo Mode Toggle
**Goal**: User can toggle between 1:1 and 1/2 tempo matching mid-run via a visible control in the active run screen
**Depends on**: Phase 16
**Requirements**: PLR-04
**Gap Closure**: Closes PLR-04 gap from v1.3 audit — engine backend exists, UI toggle missing
**Success Criteria** (what must be TRUE):
  1. A visible toggle button exists in RunPlayerView or ActiveRunView that switches tempoMode between .oneToOne and .half
  2. The toggle reads current tempoMode from RunEngineService and displays the active mode (1:1 or 1:2)
  3. Tapping the toggle mutates runEngine.tempoMode, which immediately affects cadenceDelta and sync display
**Plans**: 1 plan

Plans:
- [ ] 17-01-PLAN.md — Tempo mode toggle button in ActiveRunView + test + human verification

## Progress

**Execution Order:**
Phases execute in numeric order: 13 -> 14 -> 15 -> 16 -> 17
Note: Phases 14 and 15 both depend only on Phase 13, so they could execute in parallel.

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 1. Spotify Integration | v1.0 | 2/2 | Complete | 2026-03-19 |
| 2. BPM Data Pipeline | v1.0 | 3/3 | Complete | 2026-03-20 |
| 3. Cadence Detection | v1.0 | 2/2 | Complete | 2026-03-20 |
| 4. Core Loop (Free Run) | v1.0 | 2/2 | Complete | 2026-03-20 |
| 5. Guided Run + Polish | v1.0 | 2/2 | Complete | 2026-03-23 |
| 6. Design System Foundation | v1.1 | 2/2 | Complete | 2026-03-23 |
| 7. Tab Navigation Shell | v1.1 | 1/1 | Complete | 2026-03-23 |
| 8. Token Adoption + RunHomeView | v1.1 | 2/2 | Complete | 2026-03-23 |
| 9. Bug Fix + Brand Assets | v1.1 | 2/2 | Complete | 2026-03-24 |
| 10. Models, Settings & Library UX | v1.2 | 2/2 | Complete | 2026-03-24 |
| 11. Run Experience | v1.2 | 2/2 | Complete | 2026-03-24 |
| 12. Onboarding | v1.2 | 2/2 | Complete | 2026-03-24 |
| 13. Engine Extensions + Design Tokens | v1.3 | 2/2 | Complete | 2026-03-24 |
| 14. Cadence Display + Status Bar | v1.3 | 2/2 | Complete | 2026-03-24 |
| 15. Run Player View | v1.3 | 1/1 | Complete | 2026-03-24 |
| 16. Active Run Assembly | v1.3 | 2/2 | Complete | 2026-03-24 |
| 17. Tempo Mode Toggle | 1/1 | Complete    | 2026-03-25 | - |
