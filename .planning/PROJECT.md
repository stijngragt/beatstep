# BeatStep

## What This Is

BeatStep is a focused iOS app that syncs your running music to your stride. It uses the phone's accelerometer to detect your cadence in real-time, then queues Spotify tracks whose BPM matches your running rhythm — so your feet land on the beat. It's a music experience layer for runners, not a workout tracker.

## Core Value

When you run, your music should move with you — every footstrike landing on the beat.

## Requirements

### Validated

(None yet — ship to validate)

### Active

- [ ] Accelerometer-based cadence detection during a run
- [ ] Real-time BPM calculation from detected steps
- [ ] Spotify integration for playback and track metadata (BPM via audio features API)
- [ ] BPM-matched song queuing — queue next track based on current cadence
- [ ] Free run mode — app reacts to your natural pace and matches music to it
- [ ] Guided run mode — user sets a target cadence/BPM, app plays music to guide that pace
- [ ] Song pool from user's Spotify library (playlists, saved tracks)
- [ ] Song discovery from Spotify catalog when user's library has no BPM match
- [ ] Configurable BPM tolerance (how tight the cadence-to-song match needs to be)

### Out of Scope

- Workout tracking (distance, pace, calories) — users have Strava, Apple Fitness, etc.
- Post-run analytics or stats screens — this is about the experience during the run
- Social features, leaderboards, achievements — not a fitness app
- Apple Music / local file support — Spotify only for v1
- Real-time tempo stretching of audio — queue matching songs instead
- Android support — iOS native only for v1

## Context

- The runner's phone accelerometer produces strong, distinct impact signals on each footstrike, making cadence detection reliable
- Spotify's Web API exposes audio features per track including tempo (BPM), which enables server-side or pre-cached BPM lookup
- Typical running cadence ranges from ~150 BPM (easy jog) to ~190+ BPM (fast sprint)
- Songs at half or double the running BPM can also feel "on beat" (e.g., 85 BPM song at 170 cadence)
- The app sits alongside existing fitness apps — it doesn't replace them, it complements them

## Constraints

- **Platform**: iOS only (Swift/SwiftUI) — leverages CoreMotion for accelerometer access
- **Music source**: Spotify only — requires Spotify Premium for playback control via SDK
- **Privacy**: Accelerometer data stays on-device, no tracking or analytics collected
- **Spotify API**: Rate limits and OAuth flow constraints; BPM data availability per track

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| iOS native over cross-platform | Best accelerometer access via CoreMotion, best Spotify SDK support | — Pending |
| Song queuing over tempo stretching | Simpler, preserves original audio quality, avoids audio processing complexity | — Pending |
| Spotify only for v1 | Richest API for BPM data and playback control, largest user base | — Pending |
| No workout tracking | Focused product — be the best music-sync layer, not another fitness app | — Pending |

---
*Last updated: 2026-03-19 after initialization*
