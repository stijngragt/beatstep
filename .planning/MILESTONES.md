# Milestones

## v1.5 One Way In (Shipped: 2026-03-25)

**Phases completed:** 3 phases, 3 plans
**Timeline:** 2026-03-25 (1 day)
**Swift LOC:** 9,482
**Commits:** 6 feature commits

**Delivered:** Unified run flow — Run tab is the single entry point for all runs, old duplicate screen deleted, Library routes to Run tab, and onboarding now includes first-playlist BPM analysis.

**Key accomplishments:**
- Run tab Start Run button works reliably with last-used playlist, zone, and tolerance pre-loaded
- Old RunView.swift deleted — single entry point via Run tab enforced
- Library "Run with this playlist" CTA navigates to Run tab via SelectedTabKey EnvironmentKey
- 4-page onboarding flow: Spotify → Health → Playlist Analysis → Zones
- Immediate fullScreenCover on Start Run tap (workaround for Spotify bounce causing missed .onChange)

**Git range:** e797d4f → f77815b

---

## v1.4 Under The Hood (Shipped: 2026-03-25)

**Phases completed:** 6 phases, 11 plans
**Timeline:** 2026-03-25 (1 day)

**Delivered:** BPM data quality layer — confidence tracking, tap-to-correct input, zero-BPM fallback, and developer Sensor Lab for debugging cadence detection.

**Key accomplishments:**
- BPM confidence model (verified/approximate/manual) with lazy backfill migration
- Confidence badges in playlist view (green/yellow/blue capsules)
- Tap BPM input with rolling 8-interval average and outlier rejection
- Zero-BPM fallback (skip/play regardless/prompt) in Settings
- Sensor Lab with live accelerometer data, waveform chart, and configurable detection interval
- Step count fix using CadenceService as single source of truth

---

## v1.3 In The Zone (Shipped: 2026-03-25)

**Phases completed:** 5 phases, 8 plans
**Timeline:** 2026-03-24 → 2026-03-25 (2 days)
**Swift LOC:** 7,725
**Commits:** 26 feature commits

**Delivered:** Full active run experience — a focused full-screen view composing cadence feedback, zone indicators, music player, and long-press stop, all driven by a reactive sync quality engine.

**Key accomplishments:**
- Reactive sync quality engine: SyncQuality/TempoMode models with cadenceDelta → syncQuality → color token chain
- Color-coded cadence display with signed delta indicator, zone band visualization, and ramp phase progress
- Subtle sync-state background color shift as subconscious feedback during runs
- Integrated run player with 80pt album art, track info, BPM display, and 56pt+ playback controls
- Full-screen ActiveRunView via fullScreenCover with three-zone composition and MiniPlayer hiding
- Long-press stop button with 2-second progress ring preventing accidental mid-run stops
- 1:1/1:2 tempo mode toggle with reactive chain and UserDefaults persistence

**Git range:** b6c9dd8 → ea48487

---

## v1.2 The Right Flow (Shipped: 2026-03-24)

**Phases completed:** 3 phases, 6 plans
**Timeline:** 2026-03-24 (1 day)
**Swift LOC:** 6,376
**Commits:** 10 feature commits

**Delivered:** Overhauled onboarding, playlist UX, and run setup — making the app feel intentional from first launch through starting a run.

**Key accomplishments:**
- Zone-based running (Z1-Z5 + Free) replacing effort labels, with configurable BPM per zone in Settings
- Library playlists show analyzed/unanalyzed state with inline swipe-to-analyze
- Value-framed 3-screen onboarding flow (Spotify, Health/Motion, Zones) gated at app root via AppState enum
- Settings permission recovery section for users who denied during onboarding
- Full-width pinned Run CTA and ±BPM tolerance segmented picker
- HealthKit framework integration (optional link) for future fitness features

**Git range:** 919c123 → 02f93a1

---

## v1.1 Dark by Design (Shipped: 2026-03-24)

**Phases completed:** 4 phases, 7 plans
**Timeline:** 2026-03-23 → 2026-03-24 (2 days)
**Swift LOC:** 5,677
**Commits:** 21

**Delivered:** Dark-only visual identity with design system, tab navigation, and brand assets — every screen uses design tokens, no hardcoded colors remain.

**Key accomplishments:**
- Design token system: 10 color tokens (#FF4545 accent), 9 font tokens, 7 spacing values, 4 radii, 7 component sizes
- Global dark mode enforcement via Info.plist + window-level override (belt-and-suspenders)
- Tab navigation shell with Library/Run/Settings tabs, per-tab NavigationStack, global MiniPlayer
- All 8 view files migrated from hardcoded colors to design tokens
- Run tab landing screen with last-used playlist persistence via UserDefaults
- Track count bug fix: nil hides count for algorithmic playlists, 0 shows "0 tracks"
- App icon (ECG pulse mark, #FF4545 on near-black) and BEATSTEP wordmark on login

**Git range:** 9f70ca4 → 3924109

---

## v1.0 MVP (Shipped: 2026-03-23)

**Phases completed:** 5 phases, 11 plans
**Timeline:** 2026-03-19 → 2026-03-23 (5 days)
**Swift LOC:** 5,162

**Delivered:** A music-sync running app that detects your cadence in real-time and queues Spotify tracks whose BPM matches your stride.

**Key accomplishments:**
- Spotify OAuth + background playback with lock screen controls
- BPM data pipeline via GetSongBPM with Cloudflare Worker proxy (bypassing bot protection)
- Real-time cadence detection via CMPedometer with rolling average smoothing
- Core free run loop — cadence-to-BPM matching with half/double BPM support
- Guided run mode with warm-up/cool-down ramp state machine
- Smart song selection using danceability ranking from GetSongBPM

**Git range:** 81138cb → 6a9a248

---

