# Requirements: BeatStep

**Defined:** 2026-03-26
**Core Value:** When you run, your music should move with you — every footstrike landing on the beat.

## v1.7 Requirements

Requirements for v1.7 Beat Perfect. Each maps to roadmap phases.

### Cadence

- [ ] **CAD-01**: User sees cadence update on screen within 2 seconds of a real pace change
- [ ] **CAD-02**: Song selection responds to sustained cadence changes within 12 seconds (reduced from 24s worst-case)
- [ ] **CAD-03**: Cadence display remains stable during steady-state running (no jitter from reduced window)

### Beat Sync

- [ ] **SYNC-01**: Run screen shows a beat sync confidence badge reflecting how closely SPM matches current track BPM
- [ ] **SYNC-02**: Badge updates reactively as cadence or track changes

### Bug Fixes

- [ ] **BUG-01**: Library view shows correct analyzed/unanalyzed state immediately after scan completes
- [ ] **BUG-02**: Analyzed/Unanalyzed filter correctly filters playlists based on actual scan state

### Player

- [ ] **PLAY-01**: Mini player docks above the tab bar without overlapping navigation
- [ ] **PLAY-02**: User can collapse the player to a thin drag handle via swipe-down or tap
- [ ] **PLAY-03**: User can expand the collapsed player via swipe-up or tap on handle
- [ ] **PLAY-04**: Collapsed player shows minimal indicator (handle) that doesn't obstruct tab navigation

## Future Requirements

### Beat Sync — Advanced

- **SYNC-03**: Beat-phase alignment validation (actual footstrike-on-beat timing via CMMotionManager)
- **SYNC-04**: Adaptive cadence window that tightens/loosens based on variance

## Out of Scope

| Feature | Reason |
|---------|--------|
| Beat-phase alignment (footstrike-on-beat timing) | Heavy R&D requiring CMMotionManager per-step timestamps; sync confidence score achieves the user-facing goal |
| Real-time audio tempo stretching | Queue-matching works well; stretching adds audio processing complexity |
| Cadence detection via raw accelerometer | CMPedometer is reliable and lower-risk; Sensor Lab already covers raw data for debugging |
| Haptic beat feedback (pulse on each beat) | Core Haptics latency makes precise beat sync unreliable; research recommends against |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| CAD-01 | — | Pending |
| CAD-02 | — | Pending |
| CAD-03 | — | Pending |
| SYNC-01 | — | Pending |
| SYNC-02 | — | Pending |
| BUG-01 | — | Pending |
| BUG-02 | — | Pending |
| PLAY-01 | — | Pending |
| PLAY-02 | — | Pending |
| PLAY-03 | — | Pending |
| PLAY-04 | — | Pending |

**Coverage:**
- v1.7 requirements: 11 total
- Mapped to phases: 0
- Unmapped: 11 ⚠️

---
*Requirements defined: 2026-03-26*
*Last updated: 2026-03-26 after initial definition*
