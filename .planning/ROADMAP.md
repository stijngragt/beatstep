# Roadmap: BeatStep

## Milestones

- v1.0 MVP -- Phases 1-5 (shipped 2026-03-23)
- v1.1 Dark by Design -- Phases 6-9 (shipped 2026-03-24)
- v1.2 The Right Flow -- Phases 10-12 (shipped 2026-03-24)
- v1.3 In The Zone -- Phases 13-17 (shipped 2026-03-25)
- v1.4 Under The Hood -- Phases 18-23 (shipped 2026-03-25)
- v1.5 One Way In -- Phases 24-26 (shipped 2026-03-25)
- v1.6 Little Big Things -- Phases 27-32 (shipped 2026-03-26)
- v1.7 Beat Perfect -- Phases 33-37 (in progress)

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

<details>
<summary>v1.6 Little Big Things (Phases 27-32) -- SHIPPED 2026-03-26</summary>

- [x] Phase 27: Foundation + Fixes (2/2 plans) -- completed 2026-03-25
- [x] Phase 28: Library Polish (2/2 plans) -- completed 2026-03-26
- [x] Phase 29: Run Menu Rebuild (2/2 plans) -- completed 2026-03-26
- [x] Phase 30: Skip Queue (3/3 plans) -- completed 2026-03-26
- [x] Phase 31: Settings + Skeleton States (3/3 plans) -- completed 2026-03-26
- [x] Phase 32: Micro-Interaction Pass (3/3 plans) -- completed 2026-03-26

</details>

### v1.7 Beat Perfect (In Progress)

**Milestone Goal:** Make the core loop trustworthy -- responsive cadence, accurate beat sync, reliable library state, and a player that stays out of the way.

- [x] **Phase 33: Analyzed State Fix** - Library filters reflect actual scan state immediately (completed 2026-03-26)
- [x] **Phase 34: Player Dock Fix** - Mini player docks above tab bar without overlap (completed 2026-03-26)
- [x] **Phase 35: Collapsible Player Strip** - Two-state player with swipe collapse/expand (completed 2026-03-27)
- [ ] **Phase 36: Responsive Cadence** - Sub-2s display updates and faster song selection
- [ ] **Phase 37: Beat Sync Badge** - Real-time sync confidence visible during runs

## Phase Details

### Phase 33: Analyzed State Fix
**Goal**: Library view accurately reflects playlist scan state so users can trust the Analyzed/Unanalyzed filter
**Depends on**: Nothing (independent bug fix)
**Requirements**: BUG-01, BUG-02
**Success Criteria** (what must be TRUE):
  1. After scanning a playlist, the Library view shows the updated analyzed/unanalyzed state without navigating away and back
  2. The Analyzed filter shows only playlists that have been scanned, and the Unanalyzed filter shows only playlists that have not
  3. Background scans triggered at app launch update the filter counts when the user reaches the Library tab
**Plans**: 1 plan
Plans:
- [x] 33-01-PLAN.md — Fix upsert + reactive state propagation

### Phase 34: Player Dock Fix
**Goal**: Mini player sits in the correct vertical position -- above tab bar, no overlap, no double-padding
**Depends on**: Phase 33
**Requirements**: PLAY-01
**Success Criteria** (what must be TRUE):
  1. Mini player is visually docked directly above the tab bar with no gap and no overlap on any screen size
  2. Tab bar items remain fully tappable with the player visible
  3. Scrollable content in Library and Settings does not get clipped behind the player
**Plans**: 1 plan
Plans:
- [ ] 34-01-PLAN.md — Fix player dock layout and verify positioning
**UI hint**: yes

### Phase 35: Collapsible Player Strip
**Goal**: Users can minimize the player to a thin handle when they want more screen space, and restore it with a gesture
**Depends on**: Phase 34
**Requirements**: PLAY-02, PLAY-03, PLAY-04
**Success Criteria** (what must be TRUE):
  1. User can swipe down on the player to collapse it to a thin drag handle
  2. User can swipe up or tap the handle to expand the player back to full strip with title, BPM, and controls
  3. Collapsed handle does not obstruct tab bar taps or list scrolling
  4. Collapse/expand state persists across app restarts
**Plans**: 1 plan
Plans:
- [x] 35-01-PLAN.md — Collapsible player with interactive drag, cross-fade, and state persistence
**UI hint**: yes

### Phase 36: Responsive Cadence
**Goal**: Cadence display and song selection respond fast enough that runners feel the app is tracking them in real time
**Depends on**: Phase 34
**Requirements**: CAD-01, CAD-02, CAD-03
**Success Criteria** (what must be TRUE):
  1. When the runner changes pace, the cadence number on the run screen updates within 2 seconds
  2. After a sustained pace change, a new BPM-matched song begins playing within 12 seconds (down from 24s)
  3. During steady-state running at a constant pace, the cadence display does not jitter by more than 5 SPM between consecutive readings
**Plans**: 1 plan
Plans:
- [ ] 36-01-PLAN.md — [To be planned]

### Phase 37: Beat Sync Badge
**Goal**: Runners can see at a glance how well their current stride matches the playing track's beat
**Depends on**: Phase 36
**Requirements**: SYNC-01, SYNC-02
**Success Criteria** (what must be TRUE):
  1. The active run screen displays a beat sync confidence badge showing the match quality between SPM and track BPM
  2. The badge updates in real time as the runner's cadence changes or a new track starts playing
  3. The badge correctly handles half-tempo and double-tempo track matches without showing false mismatches
**Plans**: 1 plan
Plans:
- [ ] 37-01-PLAN.md — [To be planned]
**UI hint**: yes

## Progress

**Execution Order:**
Phases execute in numeric order: 33 -> 34 -> 35 -> 36 -> 37

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
| 27. Foundation + Fixes | v1.6 | 2/2 | Complete | 2026-03-25 |
| 28. Library Polish | v1.6 | 2/2 | Complete | 2026-03-26 |
| 29. Run Menu Rebuild | v1.6 | 2/2 | Complete | 2026-03-26 |
| 30. Skip Queue | v1.6 | 3/3 | Complete | 2026-03-26 |
| 31. Settings + Skeleton States | v1.6 | 3/3 | Complete | 2026-03-26 |
| 32. Micro-Interaction Pass | v1.6 | 3/3 | Complete | 2026-03-26 |
| 33. Analyzed State Fix | v1.7 | 1/1 | Complete    | 2026-03-26 |
| 34. Player Dock Fix | v1.7 | 0/1 | Complete    | 2026-03-26 |
| 35. Collapsible Player Strip | v1.7 | 1/1 | Complete   | 2026-03-27 |
| 36. Responsive Cadence | v1.7 | 0/0 | Not started | - |
| 37. Beat Sync Badge | v1.7 | 0/0 | Not started | - |
