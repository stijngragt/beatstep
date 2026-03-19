# Pitfalls Research

**Domain:** iOS running cadence-to-music sync (BeatStep)
**Researched:** 2026-03-19
**Confidence:** HIGH

## Critical Pitfalls

### Pitfall 1: Spotify Audio Features API Is Deprecated -- No BPM Data for New Apps

**What goes wrong:**
The Spotify Web API `get-audio-features` endpoint (which provided tempo/BPM per track) was deprecated on November 27, 2024. New apps created after that date receive a 403 Forbidden response. This is the single biggest blocker for BeatStep -- without BPM data, you cannot match songs to cadence.

**Why it happens:**
Developers assume the Spotify API still provides BPM data because tutorials and documentation from pre-2024 reference it extensively. The deprecation is recent and many resources have not been updated.

**How to avoid:**
Do NOT rely on Spotify's audio features API for BPM data. Instead:
1. Use a third-party BPM database or API (e.g., MusicBrainz AcousticBrainz data, or services like GetSongBPM).
2. Run on-device BPM detection using Essentia.js (WebAssembly) or a native port of Essentia's rhythm extraction algorithms on audio previews.
3. Build a server-side BPM analysis pipeline that processes audio and caches results.
4. Allow users to manually tag/correct BPM values for their library tracks.
5. Investigate whether the Spotify iOS SDK provides any audio analysis data locally.

**Warning signs:**
- 403 errors when calling `/v1/audio-features`
- Planning documents that reference Spotify BPM data as a given

**Phase to address:**
Phase 1 (Foundation) -- this must be solved before any song-matching logic is built. BPM data source is an architectural prerequisite.

---

### Pitfall 2: Spotify Developer Platform Lockdown -- Premium Required, 5-User Limit

**What goes wrong:**
As of February 2026, Spotify requires the developer account to have Spotify Premium, limits Development Mode to 5 test users (down from 25), and restricts each developer to one Client ID. Getting "Extended Quota" approval now requires a legally registered business, 250,000 MAU, and presence in key Spotify markets. This makes it nearly impossible to launch a new consumer app through normal channels.

**Why it happens:**
Spotify is aggressively restricting API access due to AI/automation abuse. The barrier to entry has risen dramatically in 2025-2026, and most indie developers building Spotify-dependent apps are caught off guard.

**How to avoid:**
1. Apply for Extended Quota as early as possible -- before building features that depend on wide user access.
2. Design the app to be fully functional for 5 test users during development (this is actually fine for MVP).
3. Have a clear "Spotify approval strategy" in the roadmap -- what the app needs to demonstrate to get extended access.
4. Consider whether the app can function with a degraded experience for non-Premium Spotify users (it likely cannot -- Premium is required for on-demand playback control anyway).
5. Have a contingency plan if Extended Quota is denied.

**Warning signs:**
- No plan for the Spotify approval process in the roadmap
- Building features that require >5 users before getting extended access
- Assuming free Spotify accounts will work (they will not for on-demand playback)

**Phase to address:**
Phase 1 (Foundation) -- Spotify auth setup must account for these constraints from day one. Extended Quota application should happen during beta/pre-launch phase.

---

### Pitfall 3: Background Accelerometer Access Is Not Allowed on iOS

**What goes wrong:**
iOS does not permit direct accelerometer access (CMMotionManager) when the app is backgrounded or the screen is locked. The app gets suspended, and cadence detection stops. Runners routinely lock their phone and pocket it, so this breaks the core experience.

**Why it happens:**
Developers prototype with the app in foreground and assume it will keep working. iOS background execution is heavily restricted -- accelerometer access is not one of the blessed background modes.

**How to avoid:**
Use a combination of strategies:
1. **Audio background mode** -- Since BeatStep plays music, it qualifies for the `audio` background mode. This keeps the app process alive. However, you must be the audio source (or have an active AVAudioSession) for this to work. Since Spotify handles actual playback, you need to verify the Spotify SDK's audio session keeps your app alive.
2. **CMPedometer** -- Apple's pedometer API provides real-time cadence data (`currentCadence` in steps/second) and works with background delivery. This is the most reliable path for cadence detection without raw accelerometer access.
3. **Location background mode** -- As a fallback, location updates keep the app alive, but this is an abuse of the API and will likely be rejected by App Store review.
4. **CMSensorRecorder** -- Can record up to 12 hours of accelerometer data in background, but data is only available after the fact (not real-time). Not suitable for real-time song matching.

**Warning signs:**
- Cadence detection works perfectly in development but fails when phone is locked
- Using CMMotionManager without a background execution strategy
- No testing with screen locked and app backgrounded

**Phase to address:**
Phase 1 (Foundation) -- Background execution strategy must be validated before building cadence detection. Use CMPedometer for cadence, not raw accelerometer, unless you can prove background accelerometer access works via audio session.

---

### Pitfall 4: Spotify SDK 30-Second Timeout Kills Idle Connections

**What goes wrong:**
The Spotify iOS SDK (SPTAppRemote) disconnects after approximately 30 seconds of paused playback. If the runner stops (e.g., at a traffic light, water break), the SDK connection drops. Resuming playback requires reconnecting to the Spotify app, which causes a noticeable delay and can fail silently.

**Why it happens:**
The Spotify app suspends its background connection to conserve resources when no audio is playing. The SDK is designed as a "remote control" for the Spotify app, not a persistent connection.

**How to avoid:**
1. Implement robust reconnection logic -- detect disconnection and automatically reconnect when the user resumes running.
2. Consider playing inaudible audio or a very low-volume ambient track to keep the connection alive during brief pauses (risky -- may violate Spotify TOS or drain battery).
3. Show clear UI state when disconnected and make reconnection one-tap.
4. Queue multiple tracks ahead so there is always a next track ready, reducing the need for just-in-time communication during brief connectivity gaps.
5. Test extensively with pause/resume scenarios during real runs.

**Warning signs:**
- "Works great in the lab" but breaks during actual runs with stops
- No reconnection handling in the Spotify integration layer
- Users reporting songs stopping and not resuming

**Phase to address:**
Phase 2 (Spotify Integration) -- Must be designed into the Spotify communication layer from the start, not bolted on later.

---

### Pitfall 5: Spotify BPM Data Is Frequently Wrong (Half/Double Tempo Problem)

**What goes wrong:**
Even if you obtain BPM data (from a third-party source or cached data), automated tempo detection commonly reports half or double the actual BPM. A 160 BPM song may be reported as 80 BPM or 320 BPM. For a running app, this means a fast song gets matched to a slow cadence (or vice versa), completely ruining the experience.

**Why it happens:**
Tempo detection algorithms struggle with ambiguity -- a 4/4 beat at 160 BPM can be interpreted as 80 BPM (half-time feel) or 320 BPM (double-time). This is a fundamental limitation of automated BPM analysis, not a bug in any specific API.

**How to avoid:**
1. **Clamp BPM to running range** -- Running cadence is 140-200 SPM. If a song's BPM falls outside this range, check if half or double BPM falls within it. A song at 85 BPM should be treated as 170 BPM for running purposes.
2. **BPM normalization layer** -- Build a module that normalizes all BPM values to the 130-200 range using halving/doubling.
3. **Confidence scoring** -- If your BPM source provides confidence values, weight high-confidence matches higher.
4. **User correction** -- Allow users to flag songs that feel "off beat" and manually adjust BPM.
5. **Pre-compute and cache** -- Analyze and normalize BPM for the user's entire library upfront rather than at queue time.

**Warning signs:**
- Songs that "feel wrong" during testing but have the "right" BPM number
- BPM values outside the 60-220 range for pop/rock/electronic music
- No normalization logic for half/double tempo

**Phase to address:**
Phase 2 (Song Matching) -- BPM normalization must be part of the matching algorithm, not an afterthought.

---

### Pitfall 6: Cadence Detection Latency Ruins Real-Time Sync

**What goes wrong:**
Cadence detection inherently has latency -- you need multiple steps to calculate a reliable BPM. If the algorithm needs 10-15 seconds of data, the runner has already been at a new pace for 15 seconds before the app reacts. Frequent cadence changes (speed intervals, hills) result in the music always being "behind" the runner.

**Why it happens:**
There is a fundamental trade-off between accuracy and latency in cadence detection. Longer sampling windows give more accurate BPM but react slower. Short windows are noisy and produce jittery BPM estimates.

**How to avoid:**
1. **Sliding window with weighted recent bias** -- Use a 5-10 second window but weight recent steps more heavily. Do not use a simple average over 30 seconds.
2. **CMPedometer's currentCadence** -- Apple's built-in cadence updates every few seconds and has already solved the smoothing problem. Use this as the primary signal rather than building custom step detection.
3. **Hysteresis / dead zone** -- Do not switch songs for small cadence changes (e.g., 170 to 173 SPM). Only react when cadence changes by more than the configured tolerance (e.g., 8-10 SPM sustained for 10+ seconds).
4. **Predictive queuing** -- Queue the next song based on cadence trend, not just current value. If cadence is rising, queue a slightly faster song.
5. **Do not switch mid-song constantly** -- Let songs play through. Queue the next appropriate song rather than cutting the current one short.

**Warning signs:**
- Songs changing every 30 seconds during testing
- Music feels like it is "chasing" your pace rather than matching it
- Users feel disrupted rather than supported by the sync

**Phase to address:**
Phase 2 (Cadence Detection) -- The cadence smoothing algorithm and song-switch threshold logic are tightly coupled and must be designed together.

---

### Pitfall 7: Battery Drain Makes the App Unusable for Long Runs

**What goes wrong:**
Running apps that combine continuous sensor polling (accelerometer/pedometer), active network connections (Spotify API), and audio session management drain battery rapidly. A 10-15% battery drop per hour is typical for poorly optimized apps. For a 2-hour long run, that is 20-30% battery -- unacceptable when the runner also needs GPS from their fitness app.

**Why it happens:**
Multiple always-on systems compound: high-frequency sensor polling (50-100Hz accelerometer), persistent Spotify SDK connection, frequent Web API calls for track metadata, and active audio session management. Each is modest alone but devastating in combination.

**How to avoid:**
1. **Use CMPedometer instead of raw accelerometer** -- CMPedometer uses the co-processor (M-series chip) which is dramatically more power-efficient than polling CMMotionManager.
2. **Batch API calls** -- Pre-fetch BPM data for the user's library at launch, not per-song. Cache aggressively.
3. **Reduce cadence polling frequency** -- You do not need 100Hz accelerometer data. CMPedometer updates every few seconds, which is sufficient.
4. **Profile battery usage during development** -- Use Xcode's Energy Impact gauge. Test with a full 60-minute simulated run.
5. **Minimize network calls during the run** -- Pre-build a queue of candidate songs before the run starts. Only make API calls when the queue runs low.

**Warning signs:**
- No battery profiling in the test plan
- Using CMMotionManager at high frequency for step detection
- Making Spotify API calls on every cadence change
- Users complaining about battery in TestFlight feedback

**Phase to address:**
Phase 3 (Polish/Optimization) -- But architectural decisions in Phase 1-2 determine battery baseline. Using CMPedometer vs. raw accelerometer is a Phase 1 decision.

---

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Hardcoded BPM tolerance (e.g., +/-5) | Fast to implement | Cannot adapt to user preference or genre; some genres need wider tolerance | MVP only -- must be configurable by Phase 2 |
| Polling Spotify player state on a timer | Simple to implement | Battery drain, race conditions, missed state changes | Never -- use SPTAppRemote delegate callbacks instead |
| Storing BPM data only in memory | No persistence layer needed | Library re-analysis on every launch, slow startup | MVP only -- must cache to disk by Phase 2 |
| Skipping song mid-playback on cadence change | Immediately responsive | Terrible UX, songs feel interrupted | Never -- always let current song finish or use crossfade |
| Using Spotify Web API for playback control instead of iOS SDK | Works in simulator | Higher latency, requires network, breaks offline scenarios | Never for playback control -- use iOS SDK |

## Integration Gotchas

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| Spotify iOS SDK | Assuming the SDK handles playback directly (it is a remote control for the Spotify app) | Design around the remote-control model: Spotify app must be installed, Premium required, connection can drop |
| Spotify Web API | Calling audio-features endpoint for BPM data | This endpoint is deprecated for new apps (403). Use alternative BPM source |
| Spotify OAuth | Not handling token refresh during long runs | Tokens expire; implement silent refresh. A 2-hour run will outlast most token lifetimes |
| CMPedometer | Assuming cadence data is always available | `currentCadence` can be nil (e.g., user standing still). Handle nil gracefully |
| CMPedometer | Reading cadence in steps/second and treating it as steps/minute | Multiply by 60 to convert steps/second to SPM |
| Spotify Add-to-Queue API | Assuming queue order is guaranteed | The API docs state "order of execution is not guaranteed when used with other Player API endpoints" |
| AVAudioSession | Not configuring audio session category | Must set `.playback` category to maintain background execution |

## Performance Traps

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| Fetching BPM data per-song at queue time | Noticeable delay before songs play; gaps between tracks | Pre-fetch and cache BPM for entire library at app launch or first sync | Immediately -- any network latency creates gaps |
| Re-analyzing entire Spotify library on every app launch | 30+ second loading screen, high data usage | Persist BPM cache to disk (Core Data or UserDefaults for small libraries) | Libraries with 500+ saved songs |
| Raw accelerometer at 100Hz for cadence detection | Battery drain, thermal throttling on long runs | Use CMPedometer or reduce to 10-20Hz with low-pass filter | Runs longer than 30 minutes |
| Synchronous Spotify API calls on main thread | UI freezes, dropped frames, app feels janky | All network calls on background queues with async/await | Immediately -- even one blocking call is noticeable |

## Security Mistakes

| Mistake | Risk | Prevention |
|---------|------|------------|
| Storing Spotify OAuth tokens in UserDefaults (unencrypted) | Token theft if device is compromised | Use Keychain Services for all token storage |
| Shipping Client Secret in the app binary | Secret can be extracted via reverse engineering | Use PKCE auth flow (no client secret needed for mobile) or proxy through a backend |
| Not validating Spotify callback URLs | OAuth redirect attacks | Register exact callback URL schemes; validate state parameter |

## UX Pitfalls

| Pitfall | User Impact | Better Approach |
|---------|-------------|-----------------|
| Switching songs too frequently when cadence fluctuates | Music feels chaotic; runners hate constant interruptions | Use hysteresis: only switch when cadence changes by 8+ SPM for 10+ seconds |
| No visual feedback of detected cadence | Runner does not know if the app is working; loses trust | Show real-time cadence number prominently, even in minimal lock-screen UI |
| Requiring complex setup before a run | Runners want to start quickly; too many screens = abandonment | One-tap "Start Run" after initial Spotify auth. Pre-configure defaults |
| Abrupt song transitions (hard cut) | Jarring audio experience; feels broken | Use Spotify's crossfade setting or queue songs with matching energy levels |
| No fallback when no BPM match exists | Silence or error when library has no matching song | Fall back to closest available BPM, or play a random song rather than nothing |
| Guided mode feeling too rigid | Runner feels controlled rather than supported | Allow BPM drift in guided mode; the music guides, not dictates |

## "Looks Done But Isn't" Checklist

- [ ] **Cadence detection:** Works in foreground but verify it works with screen locked, phone in pocket, and another app (Strava) in foreground
- [ ] **Spotify playback:** Works in development but verify with only 5 Development Mode users and Spotify Premium requirement
- [ ] **Song queuing:** Works for one song but verify queue behavior when rapidly changing cadence (does not double-queue or skip songs)
- [ ] **BPM matching:** Works for electronic music but verify with genres that have complex rhythms (jazz, classical, hip-hop with variable tempo)
- [ ] **OAuth flow:** Works on fresh login but verify token refresh after 1+ hours of continuous use during a long run
- [ ] **Background execution:** Works for 5 minutes but verify after 30+ minutes of background execution (iOS may still kill the process)
- [ ] **Battery impact:** Acceptable for 20-minute test but measure actual drain over 60-90 minute simulated run alongside other running apps

## Recovery Strategies

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| Built on deprecated Spotify audio features API | HIGH | Must find and integrate alternative BPM source; refactor data layer |
| Raw accelerometer instead of CMPedometer | MEDIUM | Replace CMMotionManager calls with CMPedometer; logic layer mostly unchanged |
| No reconnection logic for Spotify SDK | MEDIUM | Add connection state machine and auto-reconnect; test all edge cases |
| Hardcoded BPM tolerance | LOW | Extract to user-configurable setting; add UI control |
| No BPM normalization (half/double) | MEDIUM | Add normalization layer between BPM source and matching algorithm |
| Battery drain from high-frequency polling | MEDIUM | Switch to CMPedometer; batch API calls; requires profiling to verify fix |
| Spotify Extended Quota denied | HIGH | Limited to 5 users permanently; may need to pivot business model or platform |

## Pitfall-to-Phase Mapping

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| Spotify audio features API deprecated | Phase 1 (Foundation) | BPM data source identified and validated for 100+ songs |
| Spotify developer platform lockdown | Phase 1 (Foundation) | Dev Mode set up with Premium account; extended quota strategy documented |
| Background accelerometer access blocked | Phase 1 (Foundation) | Cadence detection tested with screen locked for 30+ minutes |
| Spotify SDK 30-second timeout | Phase 2 (Spotify Integration) | Pause/resume tested with 60-second pauses; auto-reconnect verified |
| BPM half/double tempo problem | Phase 2 (Song Matching) | BPM normalization tested across 50+ songs in different genres |
| Cadence detection latency | Phase 2 (Cadence + Matching) | Song transitions tested during interval runs with pace changes |
| Battery drain | Phase 3 (Optimization) | Battery impact measured over 60-minute run; under 8% drain target |
| OAuth token refresh during long runs | Phase 2 (Spotify Integration) | Token refresh tested during 2-hour continuous session |

## Sources

- [Spotify Web API Changes (Nov 2024)](https://developer.spotify.com/blog/2024-11-27-changes-to-the-web-api) -- Audio features deprecation announcement
- [Spotify Developer Access Update (Feb 2026)](https://developer.spotify.com/blog/2026-02-06-update-on-developer-access-and-platform-security) -- Premium requirement, 5-user limit
- [Spotify Extended Quota Criteria (Apr 2025)](https://developer.spotify.com/blog/2025-04-15-updating-the-criteria-for-web-api-extended-access) -- 250K MAU requirement
- [TechCrunch: Spotify API Changes](https://techcrunch.com/2026/02/06/spotify-changes-developer-mode-api-to-require-premium-accounts-limits-test-users/)
- [Spotify iOS SDK GitHub](https://github.com/spotify/ios-sdk) -- SDK capabilities and limitations
- [Apple CoreMotion Documentation](https://developer.apple.com/documentation/coremotion/) -- CMPedometer, background access
- [Apple Developer Forums: Background Sensor Data](https://developer.apple.com/forums/thread/115056) -- CMSensorRecorder, HKWorkoutSession
- [Spotify Web API Issue #1565](https://github.com/spotify/web-api/issues/1565) -- Tempo accuracy problems
- [Spotify Community: SDK Connection Timeout](https://community.spotify.com/t5/Spotify-for-Developers/iOS-amp-Android-Remote-SDK-loses-connection-after-paused-for-30s/td-p/7077461) -- 30-second timeout behavior
- [Apple Energy Efficiency Guide](https://developer.apple.com/library/archive/documentation/Performance/Conceptual/EnergyGuide-iOS/MotionBestPractices.html) -- Motion best practices
- [Essentia BPM Detection](https://essentia.upf.edu/tutorial_rhythm_beatdetection.html) -- Alternative BPM analysis

---
*Pitfalls research for: iOS running cadence-to-music sync (BeatStep)*
*Researched: 2026-03-19*
