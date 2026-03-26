# Roadmap: BeatStep

## Milestones

- v1.0 MVP -- Phases 1-5 (shipped 2026-03-23)
- v1.1 Dark by Design -- Phases 6-9 (shipped 2026-03-24)
- v1.2 The Right Flow -- Phases 10-12 (shipped 2026-03-24)
- v1.3 In The Zone -- Phases 13-17 (shipped 2026-03-25)
- v1.4 Under The Hood -- Phases 18-23 (shipped 2026-03-25)
- v1.5 One Way In -- Phases 24-26 (shipped 2026-03-25)
- v1.6 Little Big Things -- Phases 27-32 (in progress)

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

<details>
<summary>v1.5 One Way In (Phases 24-26) -- SHIPPED 2026-03-25</summary>

- [x] Phase 24: Fix Run Tab Start (1/1 plan) -- completed 2026-03-25
- [x] Phase 25: Consolidate Run Entry (1/1 plan) -- completed 2026-03-25
- [x] Phase 26: Onboarding Analysis Step (1/1 plan) -- completed 2026-03-25

</details>

### v1.6 Little Big Things (In Progress)

**Milestone Goal:** Polish the UI, fix interaction pain points, and make every screen feel intentionally designed.

- [x] **Phase 27: Foundation + Fixes** - Design system tokens (haptics, animations), Spotify API audit, analysis status bug fix (completed 2026-03-25)
- [x] **Phase 28: Library Polish** - Search, filter, playlist card redesign, contextual scan actions (completed 2026-03-26)
- [x] **Phase 29: Run Menu Rebuild** - Cohesive custom components with haptics and multi-zone selection (completed 2026-03-26)
- [ ] **Phase 30: Skip Queue** - Pre-built local track buffer for instant song skipping
- [ ] **Phase 31: Settings + Skeleton States** - Settings screen structure and shimmer loading states
- [ ] **Phase 32: Micro-Interaction Pass** - Haptics, spring animations, and transitions on all interactions

## Phase Details

### Phase 27: Foundation + Fixes
**Goal**: Every component built in v1.6 references shared haptic and animation tokens, API models are verified, and library coverage data is accurate
**Depends on**: Nothing (first phase of v1.6)
**Requirements**: POL-01, INF-01, LIB-05
**Success Criteria** (what must be TRUE):
  1. BSHaptics and BSAnimation token files exist and define named constants for haptic types and animation presets
  2. Spotify API models decode correctly against February 2026 endpoint responses (search limit, field renames verified)
  3. After scanning a playlist, the Library view immediately reflects the updated analyzed status without requiring a manual refresh
**Plans**: 2 plans
Plans:
- [ ] 27-01-PLAN.md -- Spotify API model fixes for Feb 2026 compatibility
- [ ] 27-02-PLAN.md -- Design system tokens (BSHaptics, BSAnimation) and library reactivity fix

### Phase 28: Library Polish
**Goal**: Users can find, filter, and manage playlists efficiently with visual scan quality feedback and native iOS interaction patterns
**Depends on**: Phase 27 (bug fix ensures accurate coverage data; tokens used by new components)
**Requirements**: LIB-01, LIB-02, LIB-03, LIB-04
**Success Criteria** (what must be TRUE):
  1. User can type in a search field and playlists filter by name in real-time without UI stutter
  2. User can tap filter chips (All / Analyzed / Unanalyzed) and see only matching playlists
  3. Each playlist card displays a visual indicator showing how many tracks have BPM data vs total tracks
  4. User can swipe or long-press a playlist to scan or delete scan — no floating scan bar visible anywhere
**Plans**: 2 plans
Plans:
- [ ] 28-01-PLAN.md -- Data model upgrade (PlaylistCoverage, PlaylistFilter, deleteScan, coverArtMedium token)
- [ ] 28-02-PLAN.md -- Library UI overhaul (search, filter chips, coverage bar, context menu)

### Phase 29: Run Menu Rebuild
**Goal**: The Run tab feels cohesive and intentional with custom-designed components, haptic feedback on every selection, and multi-zone BPM range support
**Depends on**: Phase 27 (haptic and animation tokens)
**Requirements**: RUN-01, RUN-02
**Success Criteria** (what must be TRUE):
  1. Zone picker, tolerance selector, and playlist preview are visually cohesive custom components (not stock SwiftUI pickers)
  2. Selecting a zone or changing tolerance triggers appropriate haptic feedback
  3. User can select multiple zones and the displayed BPM range merges from lowest floor to highest ceiling
  4. Starting a run with multiple zones selected uses the merged BPM range for song matching
**Plans**: 2 plans
Plans:
- [x] 29-01-PLAN.md -- Multi-zone selection model (Set<Int> persistence, mergedBPMRange, migration, tests)
- [x] 29-02-PLAN.md -- UI rebuild (multi-select zone picker, custom tolerance capsules, haptics, engine wiring)

### Phase 30: Skip Queue
**Goal**: Skipping a song during a run feels instant with no perceptible delay
**Depends on**: Phase 29 (run tab must be in final form before modifying engine)
**Requirements**: RUN-03
**Success Criteria** (what must be TRUE):
  1. Tapping skip plays the next song within ~100ms (no spinner, no pause)
  2. Skipping multiple times in quick succession works reliably without playback errors
  3. The skip buffer refills automatically in the background after each skip
**Plans**: TBD

### Phase 31: Settings + Skeleton States
**Goal**: Settings screen is organized and discoverable, and loading states across the app feel polished instead of empty
**Depends on**: Phase 27 (animation tokens for shimmer)
**Requirements**: POL-04, POL-03
**Success Criteria** (what must be TRUE):
  1. Settings screen shows grouped sections: Account, Run Defaults, Permissions, Debug, About
  2. Each section is visually distinct with clear headers and the user can find any setting within 2 taps
  3. Library playlist list shows shimmer skeleton placeholders while loading instead of a blank screen
  4. Any view that loads async data shows a skeleton state before content appears
**Plans**: TBD

### Phase 32: Micro-Interaction Pass
**Goal**: Every tap, selection, and state change in the app has appropriate haptic feedback and fluid spring animations
**Depends on**: Phases 28, 29, 30, 31 (all views must be in final form)
**Requirements**: POL-02
**Success Criteria** (what must be TRUE):
  1. All interactive elements (buttons, selectors, toggles) provide haptic feedback using BSHaptics tokens
  2. View transitions and selection changes use spring animations from BSAnimation tokens
  3. Conditional view appearances (showing/hiding elements) use explicit transitions instead of abrupt appear/disappear
  4. Run screen animations are scoped to specific value changes — no jank from rapid cadence updates
**Plans**: TBD

## Progress

**Execution Order:**
Phases execute in numeric order: 27 -> 28 -> 29 -> 30 -> 31 -> 32
Note: Phases 28 and 29 depend only on 27 (not each other). Phase 31 depends only on 27.

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
| 24. Fix Run Tab Start | v1.5 | 1/1 | Complete | 2026-03-25 |
| 25. Consolidate Run Entry | v1.5 | 1/1 | Complete | 2026-03-25 |
| 26. Onboarding Analysis Step | v1.5 | 1/1 | Complete | 2026-03-25 |
| 27. Foundation + Fixes | 2/2 | Complete    | 2026-03-25 | - |
| 28. Library Polish | 2/2 | Complete    | 2026-03-26 | - |
| 29. Run Menu Rebuild | v1.6 | 2/2 | Complete   | 2026-03-26 |
| 30. Skip Queue | v1.6 | 0/? | Not started | - |
| 31. Settings + Skeleton States | v1.6 | 0/? | Not started | - |
| 32. Micro-Interaction Pass | v1.6 | 0/? | Not started | - |
