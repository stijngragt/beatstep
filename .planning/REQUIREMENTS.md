# Requirements: BeatStep

**Defined:** 2026-03-19
**Core Value:** When you run, your music should move with you -- every footstrike landing on the beat.

## v1 Requirements

Requirements for initial release. Each maps to roadmap phases.

### Cadence Detection

- [ ] **CAD-01**: App detects running cadence in real-time via CMPedometer
- [ ] **CAD-02**: Cadence is smoothed with a rolling average to prevent jarring song switches
- [ ] **CAD-03**: Current cadence (SPM) is displayed during a run with trend indicator

### Spotify Integration

- [x] **SPOT-01**: User can authenticate with Spotify via OAuth
- [ ] **SPOT-02**: User can control playback (play/pause/skip) from the app
- [x] **SPOT-03**: Playback continues in background with lock screen controls
- [ ] **SPOT-04**: App can access user's Spotify playlists and saved tracks
- [ ] **SPOT-05**: App can discover new songs from Spotify catalog at matching BPM

### BPM Matching

- [ ] **BPM-01**: App acquires BPM data for songs via external API (not Spotify Audio Features)
- [ ] **BPM-02**: App queues songs whose BPM matches the runner's current cadence
- [ ] **BPM-03**: Half/double BPM matching expands the matchable song pool (e.g., 85 BPM song at 170 cadence)
- [ ] **BPM-04**: User can configure BPM tolerance (how tight the match needs to be)
- [ ] **BPM-05**: App pre-scans and caches BPM data for user's Spotify library
- [ ] **BPM-06**: When multiple songs match BPM, selection considers genre/mood preferences

### Run Modes

- [ ] **RUN-01**: Free run mode -- music adapts to the runner's natural pace
- [ ] **RUN-02**: Guided run mode -- user sets target BPM, app plays music at that tempo
- [ ] **RUN-03**: Warm-up/cool-down ramp -- BPM gradually increases from warm-up to target pace, then decreases

## v2 Requirements

Deferred to future release. Tracked but not in current roadmap.

### Transitions

- **TRANS-01**: Crossfade between tracks (no silence gaps)

### Integrations

- **INT-01**: Export run session data (duration, avg cadence) to HealthKit
- **INT-02**: Optional Strava upload of session data

### Platform

- **PLAT-01**: Apple Watch companion app with basic controls and cadence display
- **PLAT-02**: Apple Music support as alternative music source
- **PLAT-03**: Offline mode for runs without connectivity

## Out of Scope

Explicitly excluded. Documented to prevent scope creep.

| Feature | Reason |
|---------|--------|
| Workout tracking (distance, pace, calories, maps) | BeatStep is a music experience layer, not a fitness tracker. Users have Strava/Apple Fitness. |
| Social features / leaderboards / achievements | Wrong product for social. The value is personal (my music, my stride). |
| Real-time tempo stretching | Enormous complexity, Weav Run's moat. Smart queuing with Spotify's catalog is sufficient. |
| AI-generated / procedural music | Users want to run to music they know and love, not generic beats. |
| Podcast / audiobook BPM overlay | Audio mixing complexity, sounds terrible in practice. |
| Custom audio engine | Massive effort, likely violates Spotify TOS. Use SPTAppRemote. |
| Android support | iOS native only for v1. |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| CAD-01 | Phase 3 | Pending |
| CAD-02 | Phase 3 | Pending |
| CAD-03 | Phase 3 | Pending |
| SPOT-01 | Phase 1 | Complete |
| SPOT-02 | Phase 1 | Pending |
| SPOT-03 | Phase 1 | Complete |
| SPOT-04 | Phase 1 | Pending |
| SPOT-05 | Phase 2 | Pending |
| BPM-01 | Phase 2 | Pending |
| BPM-02 | Phase 4 | Pending |
| BPM-03 | Phase 4 | Pending |
| BPM-04 | Phase 4 | Pending |
| BPM-05 | Phase 2 | Pending |
| BPM-06 | Phase 5 | Pending |
| RUN-01 | Phase 4 | Pending |
| RUN-02 | Phase 5 | Pending |
| RUN-03 | Phase 5 | Pending |

**Coverage:**
- v1 requirements: 17 total
- Mapped to phases: 17
- Unmapped: 0

---
*Requirements defined: 2026-03-19*
*Last updated: 2026-03-19 after roadmap creation*
