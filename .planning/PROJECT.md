# BeatStep

## What This Is

BeatStep is an iOS app that syncs your running music to your stride. It detects cadence in real-time via CoreMotion, then queues Spotify tracks whose BPM matches your running rhythm. Supports both free run mode (music adapts to your pace) and guided mode (you set a target BPM with warm-up/cool-down ramps). Smart song selection ranks matches by danceability. Every interaction has haptic feedback and spring animations, with shimmer loading states and instant song skipping. The app has a dark-only UI with a cohesive heartbeat red (#FF4545) design system and tab-based navigation.

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
- ✓ BPM confidence tracking per cached track (verified/approximate/manual source) — v1.4
- ✓ Existing BPM cache records backfilled with default confidence on migration — v1.4
- ✓ Confidence badges in playlist view (green checkmark/yellow hand/blue tilde capsules) — v1.4
- ✓ Tap BPM input via half-sheet with rolling 8-interval average and outlier rejection — v1.4
- ✓ Configurable zero-BPM fallback (skip/play regardless/prompt) in Settings — v1.4
- ✓ Sensor Lab debug screen behind hidden 5-tap Settings toggle — v1.4
- ✓ Live accelerometer data, cadence, step count, algorithm state in Sensor Lab — v1.4
- ✓ Real-time waveform chart with Swift Charts and configurable detection interval — v1.4
- ✓ Single run entry point via Run tab — no more duplicate run screens — v1.5
- ✓ Playlist selection in Library routes to Run tab with playlist pre-loaded — v1.5
- ✓ Run tab Start Run button works reliably with engine integration — v1.5
- ✓ Old RunView.swift deleted, single path enforced — v1.5
- ✓ Onboarding includes first-playlist BPM analysis step before completion — v1.5
- ✓ Quick start for returning users: last playlist, zone, tolerance pre-loaded on Run tab — v1.5

- ✓ Spotify API models updated for Feb 2026 endpoint changes — v1.6
- ✓ BSHaptics (7 methods) and BSAnimation (5 presets) design system tokens — v1.6
- ✓ Library search and filter (All / Analyzed / Unanalyzed) with coverage bars — v1.6
- ✓ Contextual scan actions replacing floating scan bar — v1.6
- ✓ Run menu redesign with cohesive custom components — v1.6
- ✓ Multi-zone selection with merged BPM range — v1.6
- ✓ Pre-built skip queue for instant song skipping — v1.6
- ✓ Settings screen organized into 5 grouped sections with SF Symbol icons and Run Defaults sub-page — v1.6
- ✓ Shimmer skeleton loading states replacing ProgressView spinners in library views — v1.6
- ✓ Micro-interaction pass (haptics, transitions, loading states) — v1.6

- ✓ Fix: analyzed state updates after scan (root cause for broken filter) — v1.7
- ✓ Fix: player docked above tab bar, not overlapping — v1.7
- ✓ Collapsible player strip (title/BPM/controls, swipe-down to thin handle) — v1.7
- ✓ Responsive cadence detection (<2s from real change to screen update) — v1.7
- ✓ Beat sync badge with SF Symbol icons and half/double-tempo normalization — v1.7

### Active

None — v1.7 milestone complete.

### Out of Scope

- Workout tracking (distance, pace, calories) — users have Strava, Apple Fitness, etc.
- Post-run analytics or stats screens — this is about the experience during the run
- Social features, leaderboards, achievements — not a fitness app
- Apple Music / local file support — Spotify only for v1
- Real-time tempo stretching of audio — queue matching songs instead
- Android support — iOS native only for v1
- Light mode support — v1.1 is intentional dark commitment; revisit only if feedback demands it
- Inline playlist picker in Run tab — users go to Library to select playlists; keeps Run tab simple

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
| Separate cacheFromAPI/cacheManual write paths | Prevents API overwrites of manual BPM, each sets correct confidence/source | ✓ Good — clean data integrity |
| Lazy backfill over migration for confidence | CachedBPM computed getter returns .verified for old records without confidenceRaw | ✓ Good — zero-migration approach |
| BPMInfo struct decoupled from SwiftData | Lightweight view data type avoids passing SwiftData models to views | ✓ Good — clean view layer |
| TapBPMEngine as pure-logic class | All rhythm analysis testable without UI — rolling average, outlier rejection, reset | ✓ Good — 11 unit tests, 100% logic coverage |
| Median-deviation outlier rejection (40% threshold) | Better than fixed-interval rejection for varying tempos | ✓ Good — catches erratic taps without false positives |
| ZeroBPMFallback via UserDefaults (not SwiftData) | Simple enum persistence, no model migration needed | ✓ Good — matches RunZone pattern |
| CMMotionManager in SensorLabService (separate from CadenceService) | CadenceService uses CMPedometer; raw accelerometer is a different sensor | ✓ Good — no interference with cadence detection |
| Hidden 5-tap toggle for Sensor Lab | Developer/power-user feature that shouldn't clutter normal Settings | ✓ Good — discoverable but not distracting |
| Swift Charts with drawingGroup() for waveform | Metal-backed rendering prevents frame drops with 100-sample rolling buffer | ✓ Good — smooth chart updates |
| stepCount from CadenceService (not SensorLabService) | CadenceService owns CMPedometer — authoritative source for step data | ✓ Good — fixed gap closure, single source of truth |
| Immediate fullScreenCover on Start Run tap | Spotify app bounce during playback handoff causes missed .onChange on cadence state | ✓ Good — reliable run start |
| Tab enum with selection binding | Programmatic tab switching from Library CTA to Run tab | ✓ Good — clean cross-tab navigation |
| SelectedTabKey EnvironmentKey | Avoids deep binding chains for tab switching; injected at NavigationStack level | ✓ Good — PlaylistDetailView reads cleanly |
| No skip button on onboarding playlist step | First-run experience requires at least one analyzed playlist | ✓ Good — ensures data ready for first run |
| Fetch 20 playlists for onboarding picker | Enough for selection, avoids pagination complexity in onboarding | ✓ Good — simple and sufficient |
| Multi-zone Set<Int> over single zone ID | Users select multiple zones for wider BPM range | ✓ Good — mergedBPMRange floor...ceiling works cleanly |
| Array-based 3-track skip buffer | Pre-computed buffer with removeFirst pop for instant skip | ✓ Good — zero-latency skipping, 1s cooldown prevents spam |
| Buffer invalidation on cadence commit | tempoMode didSet invalidates buffer — simpler than explicit call | ✓ Good — always matches current pace |
| BSHaptics/BSAnimation shared tokens | Single source of truth for haptics and animations across all views | ✓ Good — zero raw values in Views/ |
| Scoped .animation(value:) on run screen | Prevents number jank from rapid cadence updates | ✓ Good — numbers snap, chrome animates |
| ShimmerModifier with .linear repeatForever | Internal phase animation isolated from SwiftUI transition system | ✓ Good — no conflict with .transition(.opacity) |
| Label-based section headers in Settings | SF Symbols + foregroundStyle(Color.accent) pattern | ✓ Good — consistent, discoverable sections |

## Context

Shipped v1.6 with 6,845 LOC Swift across 32 phases (7 milestones). 104 files changed in v1.6 alone (+10,927 lines).
Tech stack: Swift/SwiftUI, CoreMotion (CMPedometer + CMMotionManager), HealthKit (optional), Spotify Web API (PKCE auth), GetSongBPM API via Cloudflare Worker proxy, SwiftData for BPM cache, Swift Charts for waveform visualization.

Key architecture additions in v1.6:
- `BSHaptics` / `BSAnimation` — design system tokens for haptics (7 types) and animations (5 spring presets)
- `ShimmerModifier` — gradient sweep animation for skeleton loading states
- `PlaylistCoverage` / `PlaylistFilter` — typed data models for library search and filtering
- `SkipQueueBuffer` — pre-computed 3-track buffer for instant song skipping
- `RunZone.selectedZoneIds` (Set<Int>) — multi-zone selection with merged BPM range
- 41 `.transition(.opacity)` instances across all conditional views for crossfade transitions

BPM data sourced from GetSongBPM (not Spotify Audio Features, deprecated Nov 2024). Danceability field used for smart selection ranking.

Known issues:
- Pre-existing test failure: SpotifyAPIServiceTests.testPlaylistTrackDecoding (XCTUnwrap on SpotifyTrack)
- "Select for Run" context menu in PlaylistListView doesn't set LastRunPlaylist (workaround: use PlaylistDetailView path)

## Current State

v1.7 complete. All 5 phases (33-37) shipped — analyzed state bug fixed, mini player docked above tab bar, collapsible player strip, responsive cadence tuned (2.5s window, dead zone filter, 8s debounce), beat sync badge with SF Symbol icons and half/double-tempo normalization.

---
*Last updated: 2026-03-27 after Phase 37 (Beat Sync Badge) completion*
