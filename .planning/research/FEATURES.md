# Feature Research

**Domain:** Running music-sync / cadence-to-music iOS app
**Researched:** 2026-03-19
**Confidence:** MEDIUM-HIGH

## Feature Landscape

### Table Stakes (Users Expect These)

Features users assume exist in any cadence-music running app. Missing these means immediate uninstall.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Real-time cadence detection | Core promise of the entire category. Every competitor (Weav, RockMyRun, TrailMix) does this. Without it there is no product. | MEDIUM | Use CoreMotion accelerometer. Typical range 150-190 SPM for runners. Must work reliably on varied terrain and pocket positions. |
| BPM-matched song queuing | The fundamental value prop. Users open these apps specifically to hear music that matches their stride. | MEDIUM | Queue songs whose BPM matches detected cadence. Must handle half/double BPM matching (85 BPM song works at 170 cadence). |
| Free run mode (music adapts to you) | Weav calls this "Match My Stride", RockMyRun does this automatically. Users expect the app to follow their natural pace without manual input. | MEDIUM | Continuously detect cadence and queue/switch tracks accordingly. Primary mode for casual runners. |
| Fixed tempo / target BPM mode | Every competitor offers this. Runners training for cadence improvement need to set a target (e.g., 180 SPM) and have music enforce it. | LOW | User sets target BPM, app plays songs at that tempo. Simpler than free run since no real-time detection needed during playback. |
| Play/pause/skip controls | Basic music player controls. Users will rage-quit without ability to skip a song they dislike. | LOW | Standard transport controls. Must work from lock screen and notification center via MPNowPlayingInfoCenter. |
| Lock screen / background playback | Music apps that stop when the phone locks are broken. Every music app supports this. | LOW | AVAudioSession background mode. Non-negotiable for a running app. |
| Song library access (user's own music) | PaceDJ, TrailMix, and others let users play from their own library. Users want familiar music, not just curated content. | MEDIUM | For BeatStep: pull from user's Spotify playlists and saved tracks. Pre-analyze BPM for the library. |
| BPM tolerance / matching range | Users' cadence fluctuates. A tight-only match means constant jarring track switches. Every mature app allows configurable tolerance. | LOW | Default +/- 5 BPM range, user-adjustable. Wider tolerance = more song variety, narrower = tighter sync. |
| Smooth transitions between songs | Abrupt cuts between tracks destroy the running flow. RockMyRun uses DJ-style crossfades. | MEDIUM | Crossfade or gapless playback. At minimum, fade out/in. No hard silence gaps. |

### Differentiators (Competitive Advantage)

Features that would set BeatStep apart. Not expected, but create delight and retention.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Spotify catalog discovery when library has no match | Most competitors use their own music library or user's local files. BeatStep can tap Spotify's full catalog to find BPM-matched songs the user hasn't heard -- turning running into a discovery engine. | MEDIUM | Use Spotify search/recommendations API filtered by genre preferences. Major differentiator since Weav is limited to its own licensed catalog. |
| Intelligent cadence smoothing | Competitors often react too aggressively to momentary pace changes (stopping at a light, brief sprint). Smoothing the cadence signal over a window prevents jarring track switches. | MEDIUM | Rolling average over 10-15 seconds. Configurable sensitivity. Hysteresis to prevent oscillation between two BPM targets. |
| Half/double BPM awareness | A 85 BPM chill track feels perfectly on-beat at 170 cadence. Most competitors only do 1:1 matching, severely limiting the available song pool. | LOW | Map cadence to BPM at 1:1, 1:2, and 2:1 ratios. Dramatically expands matchable catalog. |
| Pre-run BPM analysis of Spotify library | Scan and cache BPM data for the user's entire Spotify library upfront, so song selection during a run is instant with no API latency. | HIGH | Critical given Spotify Audio Features API deprecation (see Pitfalls). Need alternative BPM source or on-device analysis. |
| Cadence visualization during run | Show current SPM with simple, glanceable UI. Runners checking form benefit from seeing their cadence trend. Apple Watch shows this natively but phone apps rarely make it prominent. | LOW | Large number display with trend indicator (arrow up/down/steady). Keep UI minimal for glanceability. |
| Genre/mood-aware matching | When multiple songs match the BPM, pick based on user's current genre preference or energy level. Morning easy run gets chill indie; tempo run gets aggressive EDM. | MEDIUM | Tag songs by genre/mood from Spotify metadata. Let user set mood per run or auto-detect from pace intensity. |
| Strava / HealthKit integration | Weav and RockMyRun both integrate with Strava and Health. Runners expect their runs to appear in their fitness ecosystem without manual entry. | MEDIUM | Export workout session (duration, cadence stats) to HealthKit. Optional Strava upload. Do NOT build a full tracker -- just share the session data. |
| Apple Watch companion | Strong user demand based on community discussions. Runners want to leave their phone behind. Basic controls + cadence display on wrist. | HIGH | WatchOS app with WatchConnectivity. Spotify does not have a playback SDK for watchOS, so this is limited to controls/display relay from phone. Defer to v2. |
| Warm-up / cool-down BPM ramp | Automatically start at a lower BPM and gradually increase to target pace, then ramp down at end of run. Supports proper warm-up without manual adjustment. | LOW | Timer-based BPM target curve. Simple linear ramp from start BPM to target BPM over configurable duration. |

### Anti-Features (Commonly Requested, Often Problematic)

Features that seem good but create problems for BeatStep specifically.

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| Real-time tempo stretching of audio | Weav Run does this -- music speeds up/slows down with your stride in real-time. Feels magical. | Enormous audio processing complexity. Requires licensing or building a time-stretch engine. Quality degrades at extreme tempo shifts. Weav spent years and significant funding on this tech. It is their entire moat. Trying to replicate it is a losing strategy. | Queue songs that already match the BPM. With half/double matching and Spotify's massive catalog, the pool is large enough. Focus on smart queuing, not audio manipulation. |
| Workout tracking (distance, pace, calories, maps) | Runners always want stats. Every fitness app has them. | BeatStep is a music experience layer, not a fitness tracker. Building tracking means competing with Strava, Nike Run Club, Apple Fitness -- apps with years of polish. It dilutes focus and adds massive scope. | Export session data (duration, avg cadence) to HealthKit/Strava. Let dedicated apps handle tracking. |
| Social features / leaderboards / achievements | Engagement mechanics that "increase retention." | Wrong product for social. The value is personal (my music, my stride). Social features add backend complexity, moderation burden, and distract from the core music experience. | None needed. The app is a tool, not a community. |
| Apple Music / local file support in v1 | Expand addressable market beyond Spotify users. | Doubles the integration surface. Apple Music has no BPM metadata API. Local files require on-device BPM analysis for every track. Each music source has different playback APIs, DRM constraints, and failure modes. | Spotify only for v1. Add Apple Music in v2 only if demand validates it. |
| AI-generated / procedural music | Generate infinite perfectly-BPM-matched music. Never run out of songs. | Users want to run to music they know and love, not generic AI beats. The emotional connection to familiar songs is half the value. AI music also adds significant technical complexity. | Use Spotify's catalog. 100M+ tracks is more than enough variety. |
| Offline mode for Spotify playback | Run without internet, especially in rural areas or airplanes. | Spotify SDK offline playback has strict DRM/caching limitations. Implementing reliable offline with BPM-matched queuing is extremely complex. Cache invalidation, storage management, Premium-only constraints. | Require internet connection for v1. Most urban runners have connectivity. Document as potential v2 feature if user demand exists. |
| Podcast / audiobook BPM overlay | Play podcasts with a beat overlay that matches cadence. | Audio mixing complexity. Podcasts have variable volume/tempo. Overlaying a beat sounds terrible in practice. Users either want music OR podcasts, not both. | Let users pause BeatStep and switch to their podcast app. |
| Custom audio engine | Building your own player to avoid Spotify app dependency. | Massive effort, probably violates Spotify TOS. | Use SPTAppRemote. Accept the Spotify app requirement. |

## Feature Dependencies

```
[Accelerometer cadence detection]
    |-- requires --> [CoreMotion integration]
    |-- enables --> [Free run mode]
    |-- enables --> [Fixed tempo mode]
    |-- enables --> [Cadence visualization]

[Spotify authentication (OAuth)]
    |-- requires --> [Spotify SDK integration]
    |-- enables --> [Song library access]
    |-- enables --> [Spotify catalog discovery]
    |-- enables --> [Playback controls]

[BPM data for songs]
    |-- requires --> [Spotify auth] + [BPM source (API or on-device analysis)]
    |-- enables --> [BPM-matched queuing]
    |-- enables --> [Half/double BPM matching]
    |-- enables --> [Pre-run library analysis]

[BPM-matched queuing]
    |-- requires --> [Cadence detection] + [BPM data for songs] + [Song library access]
    |-- enables --> [Free run mode]
    |-- enables --> [Fixed tempo mode]
    |-- enables --> [Genre/mood-aware matching]
    |-- enables --> [Warm-up/cool-down ramp]

[Smooth transitions]
    |-- requires --> [Playback controls]
    |-- enhances --> [BPM-matched queuing]

[Cadence smoothing]
    |-- enhances --> [Free run mode] (practically required for it to feel usable)
    |-- requires --> [Cadence detection]

[Strava/HealthKit integration]
    |-- requires --> [Cadence detection] (for session data)
    |-- independent of --> [Music playback] (export works regardless)

[Apple Watch companion]
    |-- requires --> [All core features working on phone first]
    |-- enhances --> [Cadence visualization]
```

### Dependency Notes

- **BPM-matched queuing requires both cadence detection AND BPM data:** These are the two halves of the core feature. Neither is useful alone. Both must work before any run mode functions.
- **BPM data source is a critical dependency with risk:** Spotify Audio Features API was deprecated Nov 2024. New apps cannot access it. BeatStep needs an alternative BPM source (Soundcharts API, on-device audio analysis via Essentia/aubio, or a pre-built BPM database like GetSongBPM). This is the single biggest technical risk.
- **Free run mode requires cadence smoothing to feel good:** Without smoothing, the raw accelerometer signal causes too-frequent track switches. Smoothing is technically a differentiator but practically required for free run to be usable.
- **Apple Watch requires all phone features first:** WatchOS is a separate platform with its own constraints. Spotify has no watch playback SDK. Defer completely until core phone experience is solid.

## MVP Definition

### Launch With (v1)

Minimum viable product -- validate that runners want BPM-matched Spotify queuing.

- [ ] Accelerometer cadence detection via CoreMotion -- the sensor foundation
- [ ] BPM data acquisition for songs -- must solve the Spotify API deprecation problem (likely Soundcharts API or on-device analysis)
- [ ] Spotify OAuth + playback via Spotify iOS SDK -- music source and player
- [ ] Song library access from user's Spotify playlists/saved tracks -- familiar music
- [ ] BPM-matched song queuing with half/double BPM support -- core value prop
- [ ] Free run mode (music adapts to your pace) -- primary use case
- [ ] Fixed tempo mode (set target BPM) -- secondary use case, simpler to implement
- [ ] BPM tolerance configuration -- prevents jarring over-sensitivity
- [ ] Cadence smoothing (rolling average) -- required for free run to feel smooth
- [ ] Basic playback controls (play/pause/skip) + lock screen integration -- non-negotiable UX
- [ ] Crossfade between tracks -- prevents jarring silence gaps

### Add After Validation (v1.x)

Features to add once core running experience is validated with real users.

- [ ] Spotify catalog discovery -- add when users report "not enough matching songs"
- [ ] Genre/mood-aware matching -- add when users complain about song selection quality
- [ ] Cadence visualization (SPM display during run) -- add when users request training feedback
- [ ] Warm-up / cool-down BPM ramp -- add when training-focused users request it
- [ ] HealthKit session export -- add when users want runs to appear in Apple Health
- [ ] Strava integration -- add when users specifically request it
- [ ] Pre-run library BPM analysis (background scan) -- add when song matching latency is a complaint

### Future Consideration (v2+)

Features to defer until product-market fit is established.

- [ ] Apple Watch companion app -- high complexity, requires proven phone experience first, Spotify watchOS limitations
- [ ] Apple Music support -- only if demand proves Spotify-only is limiting growth
- [ ] Guided run / coaching overlays -- only if BeatStep pivots toward training features
- [ ] Offline mode -- only if connectivity proves to be a real barrier for users

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| Cadence detection (CoreMotion) | HIGH | MEDIUM | P1 |
| BPM data acquisition | HIGH | HIGH | P1 |
| Spotify OAuth + playback | HIGH | MEDIUM | P1 |
| User's Spotify library access | HIGH | LOW | P1 |
| BPM-matched song queuing | HIGH | MEDIUM | P1 |
| Free run mode | HIGH | MEDIUM | P1 |
| Fixed tempo mode | HIGH | LOW | P1 |
| BPM tolerance config | MEDIUM | LOW | P1 |
| Cadence smoothing | HIGH | LOW | P1 |
| Playback controls + lock screen | HIGH | LOW | P1 |
| Crossfade transitions | MEDIUM | MEDIUM | P1 |
| Half/double BPM matching | HIGH | LOW | P1 |
| Spotify catalog discovery | MEDIUM | MEDIUM | P2 |
| Genre/mood matching | MEDIUM | MEDIUM | P2 |
| Cadence visualization | MEDIUM | LOW | P2 |
| Warm-up/cool-down ramp | LOW | LOW | P2 |
| HealthKit export | MEDIUM | LOW | P2 |
| Strava integration | MEDIUM | MEDIUM | P2 |
| Pre-run BPM library scan | MEDIUM | HIGH | P2 |
| Apple Watch companion | HIGH | HIGH | P3 |
| Apple Music support | MEDIUM | HIGH | P3 |

**Priority key:**
- P1: Must have for launch
- P2: Should have, add when possible
- P3: Nice to have, future consideration

## Competitor Feature Analysis

| Feature | Weav Run | RockMyRun | TrailMix | PaceDJ | BeatStep (Our Plan) |
|---------|----------|-----------|----------|--------|---------------------|
| Cadence detection | Yes (accelerometer) | Yes (accelerometer) | Yes (accelerometer) | Manual BPM entry | Yes (CoreMotion accelerometer) |
| Music adapts to stride | Real-time tempo stretch | Real-time tempo adjust | Real-time tempo stretch | No (plays matching songs) | Queue matching songs (no stretching) |
| Fixed tempo mode | Yes | Yes | Yes (lock BPM) | Yes (core feature) | Yes |
| Music source | Own licensed catalog (hundreds of songs) | Own curated DJ mixes | User's local library / Apple Music | User's local library | Spotify library + catalog (100M+ songs) |
| BPM range | 100-240 SPM | Not specified | Any song tempo | Any song in library | 120-200+ via matching + half/double |
| Guided workouts | Yes (instructor-led) | No | No | Interval templates | No (out of scope) |
| Workout tracking | Yes (GPS, distance, streaks) | Yes (distance, steps, calories, HR) | HealthKit export | No | No (HealthKit export only) |
| Strava integration | Yes | No | No | No | Planned for v1.x |
| Heart rate matching | No | Yes (with HR monitor) | No | No | No |
| Apple Watch | Yes | No | No | No | Planned for v2 |
| Pricing model | Subscription | Subscription | One-time purchase | Subscription ($1.99/mo) | TBD |
| Crossfade/transitions | Seamless (tempo stretch) | DJ-mixed (seamless) | Tempo-adjusted (seamless) | Basic | Crossfade between tracks |

### Competitive Positioning

BeatStep's unique angle: **Spotify as the music source.** Every competitor either uses their own limited catalog (Weav, RockMyRun) or relies on local files (TrailMix, PaceDJ). By integrating directly with Spotify, BeatStep gives users access to 100M+ songs they already know and love. The tradeoff is no real-time tempo stretching -- but smart queuing with half/double BPM matching and the sheer size of Spotify's catalog compensates.

**Key risk:** Spotify API restrictions (Audio Features deprecation Nov 2024) threaten the BPM data pipeline. New apps get 403 errors on the audio-features endpoint. This MUST be solved in the architecture phase. Alternatives: Soundcharts API, on-device analysis (Essentia/aubio), GetSongBPM database, or a hybrid approach.

**Market context:** Spotify itself tried a "Running" feature that detected cadence and played matching music -- they retired it in Feb 2018 citing low usage. However, the feature was buried and poorly promoted. Dedicated apps like Weav Run have since proven the market exists for runners who specifically seek this. BeatStep targets this validated niche with a better music source (the user's own Spotify library).

## Sources

- [Weav Run App Store and features](https://appmuse.com/app/weav-run-1-running-music/) - MEDIUM confidence
- [Weav Run adaptive music technology](https://medium.com/@weavmusic/whats-so-adaptive-about-our-music-bc9190772890) - MEDIUM confidence
- [Weav Run review - Well+Good](https://www.wellandgood.com/weav-run-app/) - MEDIUM confidence
- [RockMyRun official site and myBeat tech](https://www.rockmyrun.com/) - HIGH confidence
- [PaceDJ App Store listing](https://apps.apple.com/us/app/pacedj-bpm-running-music/id446225183) - HIGH confidence
- [TrailMix App Store listing](https://apps.apple.com/us/app/trailmix-step-to-the-beat/id647651691) - HIGH confidence
- [TrailMix features and tempo adjustment](https://www.trailmixapp.com/) - MEDIUM confidence
- [AudioStep BPM matching app](https://apps.apple.com/us/app/audiostep-improve-your-run-cadence-with-bpm-match/id652697216) - MEDIUM confidence
- [Spotify API deprecation announcement (Nov 2024)](https://developer.spotify.com/blog/2024-11-27-changes-to-the-web-api) - HIGH confidence
- [Spotify Audio Features 403 errors for new apps](https://community.spotify.com/t5/Spotify-for-Developers/Web-API-Get-Track-s-Audio-Features-403-error/td-p/6654507) - HIGH confidence
- [Spotify API alternatives - Soundcharts](https://soundcharts.com/en/audio-features-api) - MEDIUM confidence
- [Spotify Audio Analysis deprecation alternatives](https://medium.com/@musicae.io/spotify-audio-analysis-was-deprecated-heres-the-best-spotify-api-alternative-for-developers-585750724f48) - LOW confidence
- [Spotify Running feature retirement (2018)](https://community.spotify.com/t5/Content-Questions/Retirement-of-our-Running-Feature/td-p/4383603) - HIGH confidence
- [Apple Watch cadence tracking](https://store.cultofmac.com/blogs/learn-about-your-apple-watch/how-to-use-running-cadence-on-apple-watch) - MEDIUM confidence
- [Spotify API restrictions analysis 2026](https://voclr.it/news/why-spotify-has-restricted-its-api-access-what-changed-and-why-it-matters-in-2026/) - MEDIUM confidence
- [Spotify Running alternatives roundup](https://www.drmare.com/spotify-music/spotify-running-alternative.html) - LOW confidence
- PROJECT.md -- explicit out-of-scope items and constraints

---
*Feature research for: BeatStep -- Running music-sync / cadence-to-music iOS app*
*Researched: 2026-03-19*
