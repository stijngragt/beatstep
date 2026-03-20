# Roadmap: BeatStep

## Overview

BeatStep delivers a music-sync running experience in five phases. We start by establishing Spotify connectivity (the dependency everything else sits on), then build the BPM data pipeline (the biggest technical risk due to Spotify Audio Features deprecation), followed by cadence detection (lower risk, CMPedometer-based), then wire the core loop together (cadence-to-BPM matching with song queuing), and finally add guided run mode and selection polish. Each phase delivers a verifiable, standalone capability.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [x] **Phase 1: Spotify Integration** - Authenticate, play music, access library, and survive background transitions
- [x] **Phase 2: BPM Data Pipeline** - Source BPM data externally, cache it, and scan user libraries (completed 2026-03-20)
- [x] **Phase 3: Cadence Detection** - Detect running cadence in real-time via CoreMotion with smoothing (completed 2026-03-20)
- [x] **Phase 4: Core Loop (Free Run)** - Match cadence to BPM, queue songs, and deliver the core experience (completed 2026-03-20)
- [ ] **Phase 5: Guided Run + Polish** - Target-pace mode, warm-up/cool-down ramps, and smart song selection

## Phase Details

### Phase 1: Spotify Integration
**Goal**: User can authenticate with Spotify and control music playback from BeatStep, including in background
**Depends on**: Nothing (first phase)
**Requirements**: SPOT-01, SPOT-02, SPOT-03, SPOT-04
**Success Criteria** (what must be TRUE):
  1. User can sign in with their Spotify account and stay authenticated across app launches
  2. User can play, pause, and skip tracks from within BeatStep
  3. Playback continues when the app is backgrounded or the phone is locked, with lock screen controls working
  4. User can browse their Spotify playlists and saved tracks within the app
**Plans**: 2 plans

Plans:
- [x] 01-01-PLAN.md -- Project scaffold, models, auth service, audio session infrastructure
- [x] 01-02-PLAN.md -- Playback service, API service, all views, wiring, manual verification

### Phase 2: BPM Data Pipeline
**Goal**: App has reliable BPM data for the user's music library and can discover new tracks by BPM
**Depends on**: Phase 1
**Requirements**: BPM-01, BPM-05, SPOT-05
**Success Criteria** (what must be TRUE):
  1. App retrieves BPM data for tracks via external API (GetSongBPM or equivalent), not Spotify Audio Features
  2. BPM data is cached locally so repeated lookups are instant
  3. User's Spotify library is pre-scanned with BPM coverage visible (e.g., "142 of 200 tracks have BPM data")
  4. App can search Spotify catalog for songs at a specific BPM when user's library lacks matches
**Plans**: 3 plans

Plans:
- [x] 02-01-PLAN.md -- SwiftData models, GetSongBPM API client, BPM cache service, container setup
- [x] 02-02-PLAN.md -- Library scan service, discovery service, SpotifyAPI extensions, all UI wiring, verification
- [x] 02-03-PLAN.md -- Gap closure: Cloudflare Worker proxy for GetSongBPM, rewire scan to use GetSongBPM instead of Spotify audio-features

### Phase 3: Cadence Detection
**Goal**: App accurately detects the runner's cadence in real-time and displays it
**Depends on**: Nothing (can run in parallel with Phase 2, but sequenced for focus)
**Requirements**: CAD-01, CAD-02, CAD-03
**Success Criteria** (what must be TRUE):
  1. App detects running cadence via CMPedometer and updates in real-time during a run
  2. Cadence readings are smoothed with a rolling average so brief pace changes do not cause erratic values
  3. Current cadence (SPM) is displayed on-screen during a run with a trend indicator (speeding up / steady / slowing down)
**Plans**: 2 plans

Plans:
- [x] 03-01-PLAN.md -- CadenceService singleton, RunSession model, smoothing/trend logic, CoreMotion config, unit tests
- [x] 03-02-PLAN.md -- RunView dark UI, CadenceDisplayView, navigation wiring from PlaylistDetailView, human verification

### Phase 4: Core Loop (Free Run)
**Goal**: Runner's music automatically matches their stride -- the core value proposition works end to end
**Depends on**: Phase 1, Phase 2, Phase 3
**Requirements**: BPM-02, BPM-03, BPM-04, RUN-01
**Success Criteria** (what must be TRUE):
  1. In free run mode, the app queues the next song based on the runner's current cadence
  2. Half and double BPM matching works (e.g., a 85 BPM song plays at 170 SPM cadence)
  3. User can adjust BPM tolerance before or during a run (tight match vs. loose match)
  4. Song transitions feel natural -- cadence changes do not trigger immediate jarring switches
**Plans**: 2 plans

Plans:
- [x] 04-01-PLAN.md -- RunEngineService orchestrator + BPMTolerance model with TDD (matching, half/double, sustained change, pool management)
- [x] 04-02-PLAN.md -- UI wiring: tolerance picker on RunView, Start/Stop engine controls, MiniPlayerView skip override, device verification

### Phase 5: Guided Run + Polish
**Goal**: User can set a target pace and let the music guide their cadence, with smart song selection
**Depends on**: Phase 4
**Requirements**: RUN-02, RUN-03, BPM-06
**Success Criteria** (what must be TRUE):
  1. User can set a target BPM before starting a run, and the app plays music at that tempo
  2. Warm-up/cool-down ramp works: BPM gradually increases from warm-up pace to target, then decreases at cool-down
  3. When multiple songs match the target BPM, selection considers genre or mood preferences rather than random picks
**Plans**: TBD

Plans:
- [ ] 05-01: TBD
- [ ] 05-02: TBD

## Progress

**Execution Order:**
Phases execute in numeric order: 1 -> 2 -> 3 -> 4 -> 5

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Spotify Integration | 2/2 | Complete | 2026-03-19 |
| 2. BPM Data Pipeline | 3/3 | Complete   | 2026-03-20 |
| 3. Cadence Detection | 2/2 | Complete    | 2026-03-20 |
| 4. Core Loop (Free Run) | 2/2 | Complete | 2026-03-20 |
| 5. Guided Run + Polish | 0/2 | Not started | - |
