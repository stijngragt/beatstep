# BeatStep

## What This Is

BeatStep is an iOS app that syncs your running music to your stride. It detects cadence in real-time via CoreMotion, then queues Spotify tracks whose BPM matches your running rhythm. Supports both free run mode (music adapts to your pace) and guided mode (you set a target BPM with warm-up/cool-down ramps). Smart song selection ranks matches by danceability. The app has a dark-only UI with a cohesive heartbeat red (#FF4545) design system and tab-based navigation.

## Core Value

When you run, your music should move with you — every footstrike landing on the beat.

## Requirements

### Validated

- ✓ Cadence detection via CMPedometer with rolling average smoothing — v1.0
- ✓ Real-time BPM calculation from detected steps — v1.0
- ✓ Spotify OAuth + background playback with lock screen controls — v1.0
- ✓ BPM-matched song queuing with half/double BPM support — v1.0
- ✓ Free run mode (music adapts to runner's natural pace) — v1.0
- ✓ Guided run mode (target BPM with warm-up/cool-down ramp) — v1.0
- ✓ Song pool from user's Spotify library (playlists, saved tracks) — v1.0
- ✓ Song discovery from Spotify catalog when library lacks matches — v1.0
- ✓ Configurable BPM tolerance — v1.0
- ✓ Smart song selection using danceability ranking — v1.0
- ✓ Dark-mode-only UI with light-mode logic stripped — v1.1
- ✓ Design system: color (#FF4545 heartbeat red accent), typography, spacing/component tokens — v1.1
- ✓ Bottom tab navigation: Library, Run, Settings with per-tab NavigationStack — v1.1
- ✓ All views migrated to design tokens (zero hardcoded colors) — v1.1
- ✓ Run tab shows last-used playlist context — v1.1
- ✓ Fix track count displaying zero for algorithmic playlists — v1.1
- ✓ App icon (ECG pulse mark) and BEATSTEP wordmark — v1.1
- ✓ Onboarding flow with value-framed Spotify + Apple Health permission screens — v1.2
- ✓ Re-triggerable onboarding from Settings for missed permissions — v1.2
- ✓ Library playlists show analyzed/unanalyzed state — v1.2
- ✓ Analyze button inline with playlist (swipe-to-analyze) — v1.2
- ✓ Zone-based running: Zone 1–5 + Free replacing effort labels — v1.2
- ✓ Zone BPM defaults with user-configurable overrides in Settings — v1.2
- ✓ Full-width Run CTA at bottom of Run tab — v1.2
- ✓ BPM tolerance as segmented control showing ±BPM deltas (±3, ±7, ±12) — v1.2
- ✓ Full-screen active run view with three-zone layout via fullScreenCover — v1.3
- ✓ Long-press stop with 2-second progress ring preventing accidental stops — v1.3
- ✓ Zone name and sync quality badge in status bar — v1.3
- ✓ Color-coded sync state indicator (in-sync/drifting/mismatched) — v1.3
- ✓ Signed cadence delta indicator (+N/-N SPM) — v1.3
- ✓ Zone band visualization showing cadence position within target range — v1.3
- ✓ Subtle background color shift based on sync state — v1.3
- ✓ Ramp phase progress indicator (warm-up/at-pace/cool-down) — v1.3
- ✓ 80pt album art in run screen player — v1.3
- ✓ Song name, artist, BPM display in player area — v1.3
- ✓ Play/pause and skip with 56pt+ touch targets — v1.3
- ✓ Toggle 1:1/1:2 tempo matching mid-run with persistence — v1.3

### Active

(None — next milestone requirements TBD)

### Out of Scope

- Workout tracking (distance, pace, calories) — users have Strava, Apple Fitness, etc.
- Post-run analytics or stats screens — this is about the experience during the run
- Social features, leaderboards, achievements — not a fitness app
- Apple Music / local file support — Spotify only for v1
- Real-time tempo stretching of audio — queue matching songs instead
- Android support — iOS native only for v1
- Light mode support — v1.1 is intentional dark commitment; revisit only if feedback demands it

## Context

Shipped v1.3 with 7,725 LOC Swift across 17 phases (5 MVP + 4 design + 3 flow + 5 run experience).
Tech stack: Swift/SwiftUI, CoreMotion (CMPedometer), HealthKit (optional), Spotify Web API (PKCE auth), GetSongBPM API via Cloudflare Worker proxy, SwiftData for BPM cache.

Key architecture:
- `AppState` — enum with `resolve()` gating onboarding → login → authenticated
- `OnboardingFlow` — 3-screen forward-only ScrollView (Spotify, Health/Motion, Zones)
- `RunEngineService` — orchestrator: cadence monitor, song-end monitor, BPM matching, ramp state machine, syncQuality/cadenceDelta/tempoMode reactive chain
- `RunZone` — struct with UserDefaults persistence, Z1-Z5 defaults + user-configurable BPM
- `ZonePickerView` — horizontal capsule picker replacing PacePresetPicker + ModePicker
- `BPMCacheService` — SwiftData-backed local BPM + danceability cache
- `GetSongBPMService` → Cloudflare Worker → GetSongBPM API (bypasses bot protection)
- `BPMDiscoveryService` — on-demand Spotify catalog search when pool runs low
- `CadenceService` — CMPedometer wrapper with rolling average smoothing
- `LibraryScanService` — playlist BPM scanning with per-playlist progress tracking
- `DesignTokens.swift` — centralized Color, Font, Spacing, Radius, ComponentSize tokens + sync-state color aliases
- `ContentView` — AppState-gated TabView with Library/Run/Settings tabs, global MiniPlayer safeAreaInset (hidden during active run)
- `ActiveRunView` — full-screen three-zone composition (status bar, hero cadence, player) via fullScreenCover
- `LongPressStopButton` — 2-second timer-based progress ring with DragGesture cancel
- `RunPlayerView` — 80pt album art, track info, BPM, 56pt+ playback controls
- `SyncQuality` — enum with threshold computation from cadence delta and tolerance
- `TempoMode` — 1:1/1:2 enum with UserDefaults persistence

BPM data sourced from GetSongBPM (not Spotify Audio Features, deprecated Nov 2024). Danceability field used for smart selection ranking.

Known tech debt: RunView.activeView has hardcoded syncQuality during ~0.3s fullScreenCover animation (cosmetic).

## Constraints

- **Platform**: iOS only (Swift/SwiftUI) — leverages CoreMotion for accelerometer access
- **Music source**: Spotify only — requires Spotify Premium for playback control via Web API
- **Privacy**: Accelerometer data stays on-device, no tracking or analytics collected
- **BPM data**: GetSongBPM via Cloudflare Worker proxy — rate limits and coverage gaps for niche tracks
- **Spotify API**: PKCE OAuth flow; rate limits on catalog search and playback control
- **Visual identity**: Dark-only UI with #FF4545 heartbeat red accent — no light mode

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| iOS native over cross-platform | Best accelerometer access via CoreMotion, best Spotify SDK support | ✓ Good — CMPedometer reliable, SwiftUI productive |
| Song queuing over tempo stretching | Simpler, preserves original audio quality, avoids audio processing complexity | ✓ Good — queue matching works well |
| Spotify only for v1 | Richest API for BPM data and playback control, largest user base | ✓ Good — Web API sufficient |
| No workout tracking | Focused product — be the best music-sync layer, not another fitness app | ✓ Good — kept scope tight |
| GetSongBPM over Spotify Audio Features | Spotify deprecated audio-features for new apps Nov 2024 | ✓ Good — working via Cloudflare proxy |
| PKCE auth replacing implicit grant | Spotify Feb 2026 requirement, more secure | ✓ Good — no app secret on device |
| Web API player replacing SPTAppRemote | Broader compatibility, simpler integration | ✓ Good — works reliably |
| Cloudflare Worker proxy for GetSongBPM | iOS URLSession blocked by bot protection | ✓ Good — resolved BPM data access |
| Danceability for smart selection | Only viable audio attribute from GetSongBPM (energy/genre not available) | ✓ Good — fallback to 50 when missing |
| 8 BPM step per song for ramp | Balance between gradual ramp and reaching target in reasonable songs | — Pending user feedback |
| #FF4545 heartbeat red over electric green | Better heartbeat association, differentiates from Spotify green | ✓ Good — cohesive brand identity |
| Dark-mode-only commitment | Fitness aesthetic, simpler code, stronger brand | ✓ Good — no light/dark conditional code |
| Belt-and-suspenders dark mode | Info.plist + window override for complete coverage | ✓ Good — covers all edge cases |
| TabView with per-tab NavigationStack | Independent nav state per tab, MiniPlayer via safeAreaInset | ✓ Good — clean tab separation |
| SF Symbol sizing not tokenized | Icon sizing is layout, not typography — .font(.system(size:)) is idiomatic | ✓ Good — avoids over-abstraction |
| Test-as-generator for app icon | Core Graphics in unit test produces reproducible PNG | ✓ Good — no external tool dependency |
| SF Pro Bold (not .rounded) for wordmark | One-off brand treatment, .displayHero uses .rounded design | ✓ Good — clear brand distinction |
| Zones as thin UI wrapper over existing RunEngine | RunEngineService already supports runMode + targetBPM — zones just map to these | ✓ Good — zero RunEngine changes needed |
| RunZone struct with UserDefaults dict | Only BPM values persisted, names compiled-in — simple, no migration needed | ✓ Good — straightforward persistence |
| AppState enum with static resolve() | Testable routing logic outside SwiftUI, onboarding gate before auth | ✓ Good — prevents tab bar flash and premature scan |
| ScrollViewReader over ScrollPosition | iOS 17 compat — ScrollPosition requires iOS 18+ | ✓ Good — forward-only pattern still works |
| HealthKit read-only permission check via AppStorage flag | HKAuthorizationStatus always returns .notDetermined for read types | ✓ Good — avoids misleading "Denied" display |
| Onboarding last (after features built) | Gate built after features behind it work — safer sequencing | ✓ Good — all gated features verified before gate added |
| Timer-based progress over GestureState | DragGesture.onEnded gives reliable cancel; GestureState resets too eagerly | ✓ Good — progress ring cancel works cleanly |
| Static progress functions for testability | Same pattern as ZoneBandView.position() and RampPhaseIndicator.progress() | ✓ Good — 5 TDD tests for LongPressStopButton |
| Direct service reads over @State copies | ActiveRunView reads RunEngineService directly via @Observable — no stale state | ✓ Good — all sync data always current |
| Tempo toggle always visible | Not gated by guided mode or track presence — user can set preference before first match | ✓ Good — reduces confusion |
| fullScreenCover over NavigationLink | Prevents swipe-back dismiss, hides tab bar automatically, supports interactiveDismissDisabled | ✓ Good — run screen feels focused |
| MiniPlayer hidden via isRunActive check | ContentView gates MiniPlayer on !RunEngineService.shared.isRunActive | ✓ Good — no visual clutter during run |

## Current State

v1.3 shipped. 17 phases complete across 4 milestones. All 12 v1.3 requirements satisfied. Ready for next milestone.

---
*Last updated: 2026-03-25 after v1.3 milestone*
