# Roadmap: BeatStep

## Milestones

- v1.0 MVP -- Phases 1-5 (shipped 2026-03-23)
- v1.1 Dark by Design -- Phases 6-9 (shipped 2026-03-24)
- v1.2 The Right Flow -- Phases 10-12 (shipped 2026-03-24)
- v1.3 In The Zone -- Phases 13-17 (shipped 2026-03-25)
- v1.4 Under The Hood -- Phases 18-23 (shipped 2026-03-25)
- v1.5 One Way In -- Phases 24-26 (in progress)

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

<details>
<summary>v1.3 In The Zone (Phases 13-17) -- SHIPPED 2026-03-25</summary>

- [x] Phase 13: Engine Extensions + Design Tokens (2/2 plans) -- completed 2026-03-24
- [x] Phase 14: Cadence Display + Status Bar (2/2 plans) -- completed 2026-03-24
- [x] Phase 15: Run Player View (1/1 plan) -- completed 2026-03-24
- [x] Phase 16: Active Run Assembly (2/2 plans) -- completed 2026-03-24
- [x] Phase 17: Tempo Mode Toggle (1/1 plan) -- completed 2026-03-25

</details>

<details>
<summary>v1.4 Under The Hood (Phases 18-23) -- SHIPPED 2026-03-25</summary>

- [x] Phase 18: BPM Confidence Model (2/2 plans) -- completed 2026-03-25
- [x] Phase 19: Confidence Badges (2/2 plans) -- completed 2026-03-25
- [x] Phase 20: Tap BPM Input (2/2 plans) -- completed 2026-03-25
- [x] Phase 21: Zero-BPM Fallback (2/2 plans) -- completed 2026-03-25
- [x] Phase 22: Sensor Lab (2/2 plans) -- completed 2026-03-25
- [x] Phase 23: Sensor Lab Step Count Fix (1/1 plan) -- completed 2026-03-25

</details>

### v1.5 One Way In (In Progress)

**Milestone Goal:** Unify the run flow into a single path -- Run tab is the only way to start a run. Kill duplicate screens, fix the broken start button, and extend onboarding with first playlist analysis.

- [x] **Phase 24: Fix Run Tab Start** - Make the Run tab Start Run button work reliably with last-used settings pre-loaded (completed 2026-03-25)
- [x] **Phase 25: Consolidate Run Entry** - Kill the old run screen, route all run initiation through Run tab (completed 2026-03-25)
- [x] **Phase 26: Onboarding Analysis Step** - Add first-playlist analysis to onboarding flow before completion (completed 2026-03-25)

## Phase Details

### Phase 24: Fix Run Tab Start
**Goal**: Users can start a run from the Run tab with one tap -- the button works and their last settings are ready
**Depends on**: Phase 23
**Requirements**: FLOW-02, FLOW-05
**Success Criteria** (what must be TRUE):
  1. User taps Start Run on Run tab and a run begins with the selected playlist, zone, and tolerance
  2. Returning user sees their last-used playlist, zone, and tolerance pre-loaded when they open the Run tab
  3. User can change playlist, zone, or tolerance before starting without navigating away from Run tab
**Plans**: 1 plan
Plans:
- [ ] 24-01-PLAN.md -- Wire Run tab Start Run with playlist fetch, engine integration, and fullScreenCover

### Phase 25: Consolidate Run Entry
**Goal**: Run tab is the single entry point for all runs -- no duplicate screens, library routes to Run tab
**Depends on**: Phase 24
**Requirements**: FLOW-01, FLOW-03, FLOW-04
**Success Criteria** (what must be TRUE):
  1. Tapping "Run with this playlist" in PlaylistDetailView navigates to Run tab with that playlist pre-loaded
  2. The old playlist-initiated run screen (green button menu) no longer exists in the codebase
  3. There is no way to start a run from any screen other than the Run tab
  4. After navigating from Library to Run tab, user sees the selected playlist and can start immediately
**Plans**: 1 plan
Plans:
- [ ] 25-01-PLAN.md -- Add CTA button to PlaylistDetailView, delete RunView.swift, consolidate run entry

### Phase 26: Onboarding Analysis Step
**Goal**: New users have an analyzed playlist ready before they finish onboarding
**Depends on**: Phase 24
**Requirements**: ONBD-01
**Success Criteria** (what must be TRUE):
  1. After granting Spotify and Health permissions, user sees a step to pick and analyze their first playlist
  2. User completes onboarding with at least one analyzed playlist available for their first run
**Plans**: 1 plan
Plans:
- [ ] 26-01-PLAN.md -- Add playlist picker and BPM analysis step to onboarding flow

## Progress

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
| 17. Tempo Mode Toggle | v1.3 | 1/1 | Complete | 2026-03-25 |
| 18. BPM Confidence Model | v1.4 | 2/2 | Complete | 2026-03-25 |
| 19. Confidence Badges | v1.4 | 2/2 | Complete | 2026-03-25 |
| 20. Tap BPM Input | v1.4 | 2/2 | Complete | 2026-03-25 |
| 21. Zero-BPM Fallback | v1.4 | 2/2 | Complete | 2026-03-25 |
| 22. Sensor Lab | v1.4 | 2/2 | Complete | 2026-03-25 |
| 23. Sensor Lab Step Count Fix | v1.4 | 1/1 | Complete | 2026-03-25 |
| 24. Fix Run Tab Start | 1/1 | Complete    | 2026-03-25 | - |
| 25. Consolidate Run Entry | 1/1 | Complete    | 2026-03-25 | - |
| 26. Onboarding Analysis Step | 1/1 | Complete   | 2026-03-25 | - |
