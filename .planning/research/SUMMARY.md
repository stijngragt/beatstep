# Research Summary: BeatStep

**Domain:** Native iOS running music-sync app (cadence-to-BPM matching via Spotify)
**Researched:** 2026-03-19
**Overall confidence:** MEDIUM

## Executive Summary

BeatStep's core loop is technically feasible but has one critical risk: Spotify deprecated its Audio Features API (which provided BPM/tempo data per track) for all new apps as of November 2024. This means the original assumption that BPM data comes from Spotify is invalid. The app needs an alternative BPM sourcing strategy from day one, using GetSongBPM API and AcousticBrainz as primary sources with aggressive local caching.

The rest of the stack is straightforward. Swift 6 with SwiftUI targeting iOS 17+ provides modern concurrency (async/await, actors, @Observable) that maps cleanly to the app's architecture: concurrent sensor data streams, network requests, and playback control. CoreMotion's CMPedometer provides `currentCadence` directly, avoiding the need for custom DSP-based step detection. Spotify's iOS SDK (v5.0.1) handles playback control and authentication via SPTAppRemote, and the Web API still supports track search, user library access, and playlist retrieval.

The architecture naturally splits into three service domains: motion (CoreMotion), music (Spotify SDK + Web API), and BPM data (external APIs + local cache). A domain layer (BPMMatcher, CadenceSmoothing, RunSession) orchestrates these services. Protocol-based abstractions are essential -- not just for testing, but because the BPM data source landscape is actively shifting and needs to be swappable.

Key UX challenges are not technical but algorithmic: smoothing cadence to avoid jarring song switches, handling half/double BPM matching without producing mood-mismatched tracks, and gracefully degrading when BPM data is unavailable for certain tracks. These are solvable but need deliberate design.

## Key Findings

**Stack:** Swift 6 / SwiftUI (iOS 17+), CoreMotion (CMPedometer), Spotify iOS SDK v5.0.1, GetSongBPM API for BPM data, SwiftData for caching.

**Architecture:** MVVM with @Observable, protocol-based service layer, AsyncStream for sensor data, actor-isolated BPM cache.

**Critical pitfall:** Spotify Audio Features API is deprecated for new apps. BPM data must come from external sources (GetSongBPM, AcousticBrainz). This affects every phase of the product.

## Implications for Roadmap

Based on research, suggested phase structure:

1. **Foundation + Spotify Integration** - Establish auth, playback control, and confirm SPTAppRemote connectivity works reliably
   - Addresses: Spotify auth, basic playback, connection management
   - Avoids: Building on unstable foundation; auth issues cascade everywhere

2. **BPM Data Pipeline** - Build the layered BPM sourcing, caching, and playlist scanning
   - Addresses: BPM data fetching, caching, coverage analysis
   - Avoids: The Audio Features deprecation trap; validates BPM coverage before building matching

3. **Cadence Detection** - Implement CMPedometer integration with smoothing
   - Addresses: Real-time cadence, rolling average, background operation
   - Avoids: Over-engineering with raw accelerometer before proving CMPedometer suffices

4. **Core Loop: Free Run Mode** - Connect cadence to BPM matching to song queuing
   - Addresses: The core value proposition -- feet landing on the beat
   - Avoids: Building the hardest part first without validated sub-components

5. **Polish + Guided Run** - Target cadence mode, tolerance settings, UX refinements
   - Addresses: Guided run, pre-run scanning, cadence lock feedback
   - Avoids: Premature polish before core loop is validated

**Phase ordering rationale:**
- Spotify auth must come first because every feature depends on it
- BPM data pipeline before cadence detection because BPM coverage is the biggest unknown risk -- validate it early
- Cadence detection is technically lower risk (CMPedometer is well-documented) so it comes after BPM
- Core loop combines the previous three phases; must be last of the core phases
- Polish and guided run build on validated core loop

**Research flags for phases:**
- Phase 2 (BPM Pipeline): NEEDS deeper research on GetSongBPM API rate limits, coverage, and reliability. Also investigate Soundcharts API as paid fallback.
- Phase 1 (Spotify): Needs hands-on testing of SPTAppRemote connection lifecycle, especially background reconnection.
- Phase 3 (Cadence): LOW risk, CMPedometer is well-documented. May need research only if latency proves insufficient.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Swift/SwiftUI, CoreMotion, Spotify iOS SDK are all well-established. Versions verified. |
| Features | HIGH | Feature set is clearly defined in PROJECT.md. Table stakes vs differentiators well-understood. |
| Architecture | MEDIUM | Patterns are standard, but the BPM sourcing layer introduces uncertainty. Real-world testing needed for cadence smoothing thresholds. |
| Pitfalls | HIGH | Spotify API deprecation confirmed from official blog. Background execution constraints documented by Apple. |
| BPM Data Strategy | LOW | GetSongBPM API coverage and rate limits unverified. AcousticBrainz data is from 2022. Need hands-on testing to confirm viability. |

## Gaps to Address

- **GetSongBPM API reliability:** Need to test actual coverage for common Spotify tracks. Rate limits are undocumented. Is the free tier sufficient?
- **BPM matching for Spotify track IDs:** GetSongBPM and AcousticBrainz use different identifiers than Spotify. How do you map Spotify track IDs to these databases? Likely via ISRC codes or artist+title search.
- **CMPedometer update frequency:** Documentation says "every few seconds." Need real-device testing to determine if this is fast enough for responsive beat matching. If not, raw accelerometer with vDSP peak detection is the fallback.
- **SPTAppRemote background reconnection:** How reliably does the connection survive background/foreground transitions during a 30-60 minute run?
- **Spotify app requirement UX:** What percentage of target users have Spotify installed? How to handle the onboarding for users who need to install it?
- **Soundcharts API as paid BPM fallback:** If GetSongBPM coverage is insufficient, Soundcharts claims 70M+ tracks. Pricing and feasibility unknown.

---
*Research summary for: BeatStep*
*Researched: 2026-03-19*
