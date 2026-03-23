# BeatStep

## What This Is

BeatStep is an iOS app that syncs your running music to your stride. It detects cadence in real-time via CoreMotion, then queues Spotify tracks whose BPM matches your running rhythm. Supports both free run mode (music adapts to your pace) and guided mode (you set a target BPM with warm-up/cool-down ramps). Smart song selection ranks matches by danceability.

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

### Active

(None — define with next milestone)

### Out of Scope

- Workout tracking (distance, pace, calories) — users have Strava, Apple Fitness, etc.
- Post-run analytics or stats screens — this is about the experience during the run
- Social features, leaderboards, achievements — not a fitness app
- Apple Music / local file support — Spotify only for v1
- Real-time tempo stretching of audio — queue matching songs instead
- Android support — iOS native only for v1

## Context

Shipped v1.0 with 5,162 LOC Swift.
Tech stack: Swift/SwiftUI, CoreMotion (CMPedometer), Spotify Web API (PKCE auth), GetSongBPM API via Cloudflare Worker proxy, SwiftData for BPM cache.

Key architecture:
- `RunEngineService` — orchestrator: cadence monitor, song-end monitor, BPM matching, ramp state machine
- `BPMCacheService` — SwiftData-backed local BPM + danceability cache
- `GetSongBPMService` → Cloudflare Worker → GetSongBPM API (bypasses bot protection)
- `BPMDiscoveryService` — on-demand Spotify catalog search when pool runs low
- `CadenceService` — CMPedometer wrapper with rolling average smoothing

BPM data sourced from GetSongBPM (not Spotify Audio Features, deprecated Nov 2024). Danceability field used for smart selection ranking.

## Constraints

- **Platform**: iOS only (Swift/SwiftUI) — leverages CoreMotion for accelerometer access
- **Music source**: Spotify only — requires Spotify Premium for playback control via Web API
- **Privacy**: Accelerometer data stays on-device, no tracking or analytics collected
- **BPM data**: GetSongBPM via Cloudflare Worker proxy — rate limits and coverage gaps for niche tracks
- **Spotify API**: PKCE OAuth flow; rate limits on catalog search and playback control

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

---
*Last updated: 2026-03-23 after v1.0 milestone*
