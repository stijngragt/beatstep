# Roadmap: BeatStep

## Milestones

- v1.0 MVP -- Phases 1-5 (shipped 2026-03-23)
- v1.1 Dark by Design -- Phases 6-9 (shipped 2026-03-24)
- v1.2 The Right Flow -- Phases 10-12 (shipped 2026-03-24)
- v1.3 In The Zone -- Phases 13-17 (shipped 2026-03-25)
- **v1.4 Under The Hood** -- Phases 18-22 (in progress)

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

### v1.4 Under The Hood (In Progress)

**Milestone Goal:** Make the BPM matching algorithm observable, testable, and trustworthy -- debug tooling, manual BPM input, confidence indicators, and defined fallback behavior.

- [x] **Phase 18: BPM Confidence Model** - Extend data model with confidence/source tracking and separated write paths (completed 2026-03-25)
- [x] **Phase 19: Confidence Badges** - Show BPM confidence visually per track in playlist view (completed 2026-03-25)
- [ ] **Phase 20: Tap BPM Input** - Manual BPM entry via tap-along interface for unanalyzed tracks
- [ ] **Phase 21: Zero-BPM Fallback** - Configurable behavior when tracks lack BPM data
- [ ] **Phase 22: Sensor Lab** - Debug screen exposing raw cadence detection internals

## Phase Details

### Phase 18: BPM Confidence Model
**Goal**: Every cached BPM value carries its origin and confidence level, enabling downstream features to distinguish API-verified from manual from unknown
**Depends on**: Nothing (foundation for v1.4)
**Requirements**: CONF-01, CONF-02
**Success Criteria** (what must be TRUE):
  1. Every newly cached BPM record stores its source (API / manual) and confidence level (verified / approximate / manual)
  2. Existing BPM cache records from v1.3 survive the upgrade intact with a default confidence value assigned
  3. API-sourced and manual BPM writes use separate code paths that cannot silently overwrite each other
**Plans**: 2 plans

Plans:
- [ ] 18-01-PLAN.md -- Model + enums + write path split (BPMConfidence, BPMSource, CachedBPM extension, cacheFromAPI/cacheManual)
- [ ] 18-02-PLAN.md -- Test updates + confidence tracking tests (update cache() callers, 7 new test methods)

### Phase 19: Confidence Badges
**Goal**: Users can see at a glance which tracks have reliable BPM data and which need attention
**Depends on**: Phase 18
**Requirements**: CONF-03
**Success Criteria** (what must be TRUE):
  1. Each track in playlist detail view displays an icon badge indicating its BPM confidence (checkmark for verified, tilde for approximate, hand for manual)
  2. Tracks with no BPM data are visually distinguishable from tracks with any level of confidence
**Plans**: 2 plans

Plans:
- [x] 19-01-PLAN.md -- Data contracts: BPMInfo struct, BPMConfidence display properties, getBPMInfo service method, stateApproximate color token, unit tests
- [ ] 19-02-PLAN.md -- View integration: update PlaylistDetailView + TrackRow to render confidence badges with visual checkpoint

### Phase 20: Tap BPM Input
**Goal**: Users can manually set BPM for any track by tapping along with the music
**Depends on**: Phase 19
**Requirements**: TAP-01, TAP-02, TAP-03
**Success Criteria** (what must be TRUE):
  1. User can open a tap-along interface from any track in playlist view and tap to set its BPM
  2. BPM calculation stabilizes after 8 taps using a rolling average, with a visual stability indicator
  3. Erratic taps (outliers) are rejected without corrupting the calculated BPM
  4. After saving a tapped BPM, the track immediately shows a manual confidence badge in the playlist
**Plans**: 2 plans

Plans:
- [ ] 20-01-PLAN.md -- TDD: TapBPMEngine pure-logic class (rolling average, outlier rejection, inactivity reset)
- [ ] 20-02-PLAN.md -- TapBPMView half-sheet UI + TrackRow badge tap wiring + visual checkpoint

### Phase 21: Zero-BPM Fallback
**Goal**: Users control what happens when the run engine encounters tracks without BPM data
**Depends on**: Phase 18
**Requirements**: FALL-01, FALL-02
**Success Criteria** (what must be TRUE):
  1. User can choose zero-BPM behavior in Settings: skip, play regardless, or prompt
  2. During an active run, tracks without BPM are handled according to the user's configured fallback
  3. The default behavior (skip) matches current behavior so existing users see no change without action
**Plans**: TBD

Plans:
- [ ] 21-01: TBD

### Phase 22: Sensor Lab
**Goal**: Developers and power users can inspect raw cadence detection data to build trust in the algorithm
**Depends on**: Nothing (independent of Phases 18-21)
**Requirements**: SLAB-01, SLAB-02, SLAB-03, SLAB-04
**Success Criteria** (what must be TRUE):
  1. A hidden debug toggle in Settings reveals the Sensor Lab screen
  2. Sensor Lab displays live raw accelerometer data, cadence value, step count, and algorithm state
  3. Detection interval is adjustable from 0.5s to 5s within Sensor Lab for rapid desk testing
  4. A real-time waveform chart visualizes accelerometer output
  5. Closing Sensor Lab stops the accelerometer (no background battery drain)
**Plans**: TBD

Plans:
- [ ] 22-01: TBD

## Progress

**Execution Order:**
Phases execute in numeric order: 18 -> 19 -> 20 -> 21 -> 22
Note: Phase 21 and 22 depend only on Phase 18, not on each other.

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
| 19. Confidence Badges | 2/2 | Complete    | 2026-03-25 | - |
| 20. Tap BPM Input | v1.4 | 0/2 | Not started | - |
| 21. Zero-BPM Fallback | v1.4 | 0/? | Not started | - |
| 22. Sensor Lab | v1.4 | 0/? | Not started | - |
