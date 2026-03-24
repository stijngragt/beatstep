# Requirements: BeatStep

**Defined:** 2026-03-24
**Core Value:** When you run, your music should move with you — every footstrike landing on the beat.

## v1.2 Requirements

Requirements for v1.2 "The Right Flow". Each maps to roadmap phases.

### Onboarding

- [ ] **ONBD-01**: User sees a value-framed Spotify permission screen before the system OAuth dialog on first launch
- [ ] **ONBD-02**: User sees a value-framed Apple Health permission screen before the system HealthKit dialog on first launch
- [ ] **ONBD-03**: User sees a brief skippable "how zones work" screen during onboarding
- [ ] **ONBD-04**: User can re-trigger permission setup from Settings when permissions were denied or revoked

### Library

- [x] **LIB-01**: User can see analyzed/unanalyzed state on each playlist row in the Library tab
- [x] **LIB-02**: User can trigger playlist analysis inline from the Library list without navigating to the detail screen

### Run Setup

- [ ] **RUN-01**: User selects a running zone (Zone 1–5 or Free) instead of effort labels (Easy Jog/Steady/Fast Sprint)
- [ ] **RUN-02**: User sees a full-width Run CTA at the bottom of the Run tab
- [ ] **RUN-03**: User sees BPM tolerance as a segmented control displaying ±3, ±7, ±12 BPM
- [ ] **RUN-04**: User can configure custom BPM values per zone in Settings (with sensible defaults)

## Future Requirements

### Fitness Integration

- **FIT-01**: App reads real-time heart rate from HealthKit during a run
- **FIT-02**: App auto-detects running zone from heart rate and adjusts BPM target dynamically

### Personalization

- **PERS-01**: User receives playlist recommendations based on running history
- **PERS-02**: User can set preferred genres for BPM discovery

## Out of Scope

| Feature | Reason |
|---------|--------|
| Auto-analyze all playlists on first launch | Rate limits on GetSongBPM; terrible first-launch experience for large libraries |
| Onboarding quiz (goals, fitness level, genres) | Every extra screen reduces completion rate; BeatStep's value is immediate |
| Blocking permission gate | App Store guideline 5.1.1; don't require unnecessary info before providing value |
| Zone-based heart rate monitoring | Substantial new system touching RunEngine + HealthKit; deferred to future |
| Per-song analyze status in playlist | Noise; users care about playlist readiness, not individual track state |
| Light mode | Intentional dark commitment from v1.1 |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| ONBD-01 | Phase 12 | Pending |
| ONBD-02 | Phase 12 | Pending |
| ONBD-03 | Phase 12 | Pending |
| ONBD-04 | Phase 12 | Pending |
| LIB-01 | Phase 10 | Complete |
| LIB-02 | Phase 10 | Complete |
| RUN-01 | Phase 11 | Pending |
| RUN-02 | Phase 11 | Pending |
| RUN-03 | Phase 10 | Pending |
| RUN-04 | Phase 10 | Pending |

**Coverage:**
- v1.2 requirements: 10 total
- Mapped to phases: 10
- Unmapped: 0

---
*Requirements defined: 2026-03-24*
*Last updated: 2026-03-24 after roadmap creation*
