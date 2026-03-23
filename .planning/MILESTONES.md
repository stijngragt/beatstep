# Milestones

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

