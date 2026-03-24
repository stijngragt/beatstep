# Roadmap: BeatStep

## Milestones

- v1.0 MVP -- Phases 1-5 (shipped 2026-03-23)
- v1.1 Dark by Design -- Phases 6-9 (shipped 2026-03-24)
- **v1.2 The Right Flow** -- Phases 10-12 (in progress)

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

### v1.2 The Right Flow

- [ ] **Phase 10: Models, Settings & Library UX** - Zone model, BPM tolerance picker, zone settings, and playlist analyzed state with inline analyze
- [ ] **Phase 11: Run Experience** - Zone picker replaces effort labels, full-width Run CTA
- [ ] **Phase 12: Onboarding** - Value-framed first-launch permission flow with re-trigger from Settings

## Phase Details

### Phase 10: Models, Settings & Library UX
**Goal**: Users can see playlist readiness at a glance, trigger analysis without leaving the list, configure zone BPM values, and use a clearer tolerance picker
**Depends on**: Nothing (first phase of v1.2)
**Requirements**: RUN-03, RUN-04, LIB-01, LIB-02
**Success Criteria** (what must be TRUE):
  1. User sees a clear analyzed/unanalyzed indicator on every playlist row in the Library tab (e.g., "42/60 tracks" or "Not analyzed")
  2. User can tap an inline analyze button on an unanalyzed playlist row without navigating into the detail screen
  3. User sees BPM tolerance as a segmented control showing concrete deltas (+-3, +-7, +-12 BPM) instead of named labels
  4. User can open Settings and adjust BPM values for each zone (Z1 through Z5), with sensible defaults pre-filled
**Plans**: 2 plans

Plans:
- [ ] 10-01-PLAN.md — RunZone model, zone settings UI, tolerance picker labels
- [ ] 10-02-PLAN.md — Playlist analyzed state indicators, inline swipe-to-analyze

### Phase 11: Run Experience
**Goal**: Users select a running zone that speaks their language and see a prominent action to start their run
**Depends on**: Phase 10 (RunZone model and zone BPM settings must exist)
**Requirements**: RUN-01, RUN-02
**Success Criteria** (what must be TRUE):
  1. User sees Zone 1 through Zone 5 and Free as run mode options, replacing the old effort labels (Easy Jog, Steady, Fast Sprint)
  2. Selecting a zone uses the user-configured BPM (or default) as the target BPM for the run
  3. User sees a full-width Start Run button at the bottom of the Run tab that is visually prominent and always accessible
**Plans**: TBD

Plans:
- [ ] 11-01: TBD

### Phase 12: Onboarding
**Goal**: First-launch users understand why BeatStep needs permissions and grant them confidently; users who denied can recover
**Depends on**: Phase 11 (all features behind the onboarding gate should be built and working first)
**Requirements**: ONBD-01, ONBD-02, ONBD-03, ONBD-04
**Success Criteria** (what must be TRUE):
  1. On first launch, user sees a value-framed Spotify screen explaining why music access is needed before the system OAuth dialog appears
  2. On first launch, user sees a value-framed Apple Health screen explaining why motion data is needed before the system HealthKit dialog appears
  3. On first launch, user sees a brief skippable screen explaining how running zones work
  4. User who denied permissions on first launch can navigate to Settings and find a "Revisit Permissions" action that guides them to restore access
  5. The Library tab does not fire a background playlist scan until onboarding is complete
**Plans**: TBD

Plans:
- [ ] 12-01: TBD
- [ ] 12-02: TBD

## Progress

**Execution Order:**
Phases execute in numeric order: 10 -> 11 -> 12

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
| 10. Models, Settings & Library UX | v1.2 | 0/2 | Not started | - |
| 11. Run Experience | v1.2 | 0/? | Not started | - |
| 12. Onboarding | v1.2 | 0/? | Not started | - |
