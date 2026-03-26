# Requirements: BeatStep

**Defined:** 2026-03-25
**Core Value:** When you run, your music should move with you — every footstrike landing on the beat.

## v1.6 Requirements

Requirements for v1.6 Little Big Things. Each maps to roadmap phases.

### Library

- [x] **LIB-01**: User can search playlists by name in real-time from Library view
- [x] **LIB-02**: User can filter playlists by status (All / Analyzed / Unanalyzed)
- [x] **LIB-03**: Playlist cards show scan quality — matched tracks vs total tracks with visual coverage indicator
- [x] **LIB-04**: User can scan/delete scan via swipe action or context menu on each playlist (floating bar removed)
- [x] **LIB-05**: Library correctly shows analyzed status after scan completes (bug fix)

### Run Tab

- [ ] **RUN-01**: Zone picker, tolerance selector, and playlist preview use cohesive custom components with haptic feedback
- [ ] **RUN-02**: User can select multiple zones — BPM range merges from lowest zone floor to highest zone ceiling
- [ ] **RUN-03**: Skipping a song is instant — 2-3 tracks pre-computed and ready in a local buffer

### Polish

- [x] **POL-01**: Design system includes haptic and animation tokens (BSHaptics, BSAnimation) referenced by all components
- [ ] **POL-02**: Every tap, selection, and state change has appropriate haptic feedback and spring animation
- [ ] **POL-03**: Loading states use skeleton shimmer instead of blank screens
- [ ] **POL-04**: Settings screen organized into grouped sections: Account, Run Defaults, Permissions, Debug, About

### Infrastructure

- [x] **INF-01**: Spotify API models verified against February 2026 changes (search limit, field renames)

## Future Requirements

### Multi-zone UX refinement

- **RUN-04**: Non-adjacent zone selection restricted or warned (e.g., Zone 1 + Zone 4 produces very wide BPM range)

### Queue visibility

- **RUN-05**: Upcoming queue (2-3 songs) visible on active run screen

## Out of Scope

| Feature | Reason |
|---------|--------|
| Spotify catalog search in library | Library filter is sufficient for v1.6; catalog search adds API complexity |
| Draggable/reorderable queue | Contradicts core BPM-matching value proposition |
| Zone labeling overhaul (HR-based) | Deferred — needs accurate measurement model first |
| Light mode | Intentional dark commitment from v1.1 |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| LIB-01 | Phase 28 | Complete |
| LIB-02 | Phase 28 | Complete |
| LIB-03 | Phase 28 | Complete |
| LIB-04 | Phase 28 | Complete |
| LIB-05 | Phase 27 | Complete |
| RUN-01 | Phase 29 | Pending |
| RUN-02 | Phase 29 | Pending |
| RUN-03 | Phase 30 | Pending |
| POL-01 | Phase 27 | Complete |
| POL-02 | Phase 32 | Pending |
| POL-03 | Phase 31 | Pending |
| POL-04 | Phase 31 | Pending |
| INF-01 | Phase 27 | Complete |

**Coverage:**
- v1.6 requirements: 13 total
- Mapped to phases: 13
- Unmapped: 0

---
*Requirements defined: 2026-03-25*
*Last updated: 2026-03-25 after roadmap creation*
