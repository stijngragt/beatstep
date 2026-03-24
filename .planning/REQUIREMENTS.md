# Requirements: BeatStep

**Defined:** 2026-03-24
**Core Value:** When you run, your music should move with you -- every footstrike landing on the beat.

## v1.3 Requirements

Requirements for v1.3 "In The Zone" milestone. Each maps to roadmap phases.

### Run Screen

- [ ] **RUN-01**: User sees a full-screen active run view (three-zone layout: status bar, hero cadence, player area) presented via fullScreenCover when cadence is detected
- [ ] **RUN-02**: User can stop a run only via long-press (2-second hold with visual progress ring), preventing accidental mid-run stops
- [ ] **RUN-03**: User sees current zone name and sync quality badge in the status bar during a run

### Cadence Indicators

- [x] **CAD-01**: User sees a color-coded sync state indicator showing whether cadence is in-sync, drifting, or mismatched with the current song BPM
- [ ] **CAD-02**: User sees a signed delta indicator ("+4 SPM" / "-6 SPM") near the cadence number in guided mode, and sync quality text in free mode
- [ ] **CAD-03**: User sees a zone band visualization showing where current cadence sits within the target zone range (guided mode only)
- [ ] **CAD-04**: User perceives a subtle background color shift based on sync state (in-sync vs drifting) as subconscious feedback
- [ ] **CAD-05**: User sees ramp phase progress (warm-up / at-pace / cool-down) during guided mode runs

### Music Player

- [ ] **PLR-01**: User sees album art (80pt) for the current track in the integrated run screen player
- [ ] **PLR-02**: User sees song name, artist name, and current track BPM in the player area
- [ ] **PLR-03**: User can play/pause and skip tracks with large touch targets (56pt+) during a run
- [ ] **PLR-04**: User can toggle between 1:1 and 1/2 tempo matching mid-run, which changes how songs are matched to cadence and updates the sync/delta display accordingly

## v2 Requirements

Deferred to future release. Tracked but not in current roadmap.

### Pause & Lifecycle

- **PAUSE-01**: Deliberate pause/idle state UX with dimmed metrics, ghosted last SPM, music continues playing
- **TIME-01**: Elapsed run time display in status bar

### Platform Extensions

- **HAP-01**: Haptic feedback on sync state changes (vibrate when entering/leaving sync)
- **LIVE-01**: Live Activities / Dynamic Island showing cadence + sync state
- **WATCH-01**: Apple Watch companion with cadence + sync on wrist

## Out of Scope

Explicitly excluded. Documented to prevent scope creep.

| Feature | Reason |
|---------|--------|
| Elapsed run timer | No workout-tracking feel -- BeatStep is about music sync, not fitness metrics |
| Auto-pause music on cadence drop | Music continues during stops; pausing feels broken at traffic lights |
| Distance / pace / calories | Users have Strava, Apple Fitness -- BeatStep is the music-sync layer |
| Heart rate display | Requires HealthKit continuous reading, competes for screen real estate |
| Metronome / audio click | The music beat IS the pacing guide -- that's the whole product |
| Song queue preview | Adaptive model doesn't know next track until current ends |
| Real-time tempo stretching | Queue matching preserves audio quality -- deliberate design choice |
| Complex gesture controls | Sweaty fingers, bouncing phone, gloves -- large tap targets only |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| RUN-01 | Phase 16 | Pending |
| RUN-02 | Phase 16 | Pending |
| RUN-03 | Phase 14 | Pending |
| CAD-01 | Phase 13 | Complete |
| CAD-02 | Phase 13 | Pending |
| CAD-03 | Phase 14 | Pending |
| CAD-04 | Phase 14 | Pending |
| CAD-05 | Phase 14 | Pending |
| PLR-01 | Phase 15 | Pending |
| PLR-02 | Phase 15 | Pending |
| PLR-03 | Phase 15 | Pending |
| PLR-04 | Phase 13 | Pending |

**Coverage:**
- v1.3 requirements: 12 total
- Mapped to phases: 12
- Unmapped: 0

---
*Requirements defined: 2026-03-24*
*Last updated: 2026-03-24 after roadmap creation*
