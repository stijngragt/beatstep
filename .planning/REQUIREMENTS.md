# Requirements: BeatStep

**Defined:** 2026-03-25
**Core Value:** When you run, your music should move with you -- every footstrike landing on the beat.

## v1.4 Requirements

Requirements for v1.4 "Under The Hood". Each maps to roadmap phases.

### BPM Confidence

- [x] **CONF-01**: BPM source tracked per cached track (verified / approximate / manual)
- [x] **CONF-02**: Existing cached BPM records backfilled with default confidence on migration
- [x] **CONF-03**: Playlist view shows confidence badge per track (icon-based: checkmark / tilde / hand)

### Tap BPM

- [x] **TAP-01**: User can tap along with a song to set its BPM via a large tap area
- [x] **TAP-02**: Tap BPM uses rolling 8-interval average with 3-second inactivity reset
- [x] **TAP-03**: Erratic taps filtered via outlier rejection with stabilization indicator

### Zero-BPM Fallback

- [x] **FALL-01**: User can configure zero-BPM behavior in Settings (skip / play regardless / prompt)
- [x] **FALL-02**: Run engine respects configured fallback when encountering nil-BPM tracks

### Sensor Lab

- [x] **SLAB-01**: Debug screen accessible via hidden settings toggle
- [ ] **SLAB-02**: Sensor Lab displays raw accelerometer output, cadence, step count, algorithm state
- [x] **SLAB-03**: Detection interval configurable from 0.5s to 5s in Sensor Lab
- [x] **SLAB-04**: Real-time accelerometer waveform chart in Sensor Lab

## Future Requirements

### Tap BPM Enhancements

- **TAP-04**: Half/double tempo detection with user correction suggestion

### Zero-BPM Enhancements

- **FALL-03**: Circuit breaker to rate-limit skip behavior on sparse playlists

## Out of Scope

| Feature | Reason |
|---------|--------|
| Mid-run tap BPM | Disruptive to running flow -- BPM should be set in library before the run |
| Microphone-based BPM detection | Fragile, heavy, unreliable in outdoor environments |
| Text field BPM input | No confidence signal -- tapping gives rhythm-verified data |
| Sensor data export | Scope creep into analytics -- debug screen is for live testing only |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| CONF-01 | Phase 18 | Complete |
| CONF-02 | Phase 18 | Complete |
| CONF-03 | Phase 19 | Complete |
| TAP-01 | Phase 20 | Complete |
| TAP-02 | Phase 20 | Complete |
| TAP-03 | Phase 20 | Complete |
| FALL-01 | Phase 21 | Complete |
| FALL-02 | Phase 21 | Complete |
| SLAB-01 | Phase 22 | Complete |
| SLAB-02 | Phase 23 | Pending |
| SLAB-03 | Phase 22 | Complete |
| SLAB-04 | Phase 22 | Complete |

**Coverage:**
- v1.4 requirements: 12 total
- Mapped to phases: 12
- Unmapped: 0

---
*Requirements defined: 2026-03-25*
*Last updated: 2026-03-25 after roadmap creation*
