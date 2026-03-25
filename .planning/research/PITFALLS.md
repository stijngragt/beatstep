# Pitfalls Research

**Domain:** Debug tooling, manual BPM input, confidence tracking, and zero-BPM fallback for iOS running music app
**Researched:** 2026-03-25
**Confidence:** HIGH (based on direct codebase analysis of CadenceService, BPMCacheService, RunEngineService, CachedBPM model)

---

## Critical Pitfalls

### Pitfall 1: SwiftData Schema Migration Breaking Existing BPM Cache

**What goes wrong:**
Adding a `bpmSource` or `bpmConfidence` field to `CachedBPM` triggers a SwiftData schema migration. If the new field is non-optional without a default value, the migration fails and the app crashes on launch for every existing user. Their entire BPM cache (built up across playlist scans) is destroyed.

**Why it happens:**
The current `CachedBPM` model has 7 fields (`spotifyTrackID`, `trackName`, `artistName`, `bpm`, `lookupAttempted`, `lastUpdated`, `danceability`). SwiftData's automatic lightweight migration only handles additive optional fields or fields with default values. Adding `var bpmSource: BPMConfidence` as a non-optional enum triggers a destructive migration. This works fine on clean simulator installs during development -- the bug only surfaces when upgrading from v1.3 with existing data.

**How to avoid:**
- Add new fields as optionals: `var bpmSource: String?` (raw string, not enum)
- Provide computed properties for type safety: `var resolvedSource: BPMSource { BPMSource(rawValue: bpmSource ?? "") ?? .api }`
- Treat nil as "api" (the default for all existing records -- they were all populated by GetSongBPM)
- Test migration: install v1.3 build, scan a playlist, then install v1.4 build and verify cache survives

**Warning signs:**
- `NSInternalInconsistencyException` on launch after update
- SwiftData console logs showing "failed to migrate" or "model version mismatch"
- Works on simulator (clean install) but crashes on device (existing data)

**Phase to address:**
BPM Confidence phase -- schema change must be the very first thing built, before any UI references the new fields.

---

### Pitfall 2: Debug Detection Interval Leaking Into Production Runs

**What goes wrong:**
The Sensor Lab allows configuring detection interval from 5s down to 0.5s for desk testing. If this setting persists in shared UserDefaults, a user who tested in debug mode unknowingly starts real runs with 0.5s intervals. This floods `CadenceService.cadenceWindow` with 10x more samples than designed, making the rolling average sluggish (the window prunes by time, not count, so 50 samples in 5 seconds all stay). Battery drains rapidly.

**Why it happens:**
The current `CadenceService` uses hardcoded `windowDuration: TimeInterval = 5.0` and relies on CMPedometer's native update frequency (~1Hz). A configurable interval means either restarting CMPedometer on a timer or switching to raw `CMMotionManager` accelerometer. Either approach creates a setting that must be completely isolated from the production code path.

**How to avoid:**
- CadenceService keeps its existing `startDetecting()` method untouched for production
- Create a separate `SensorLabService` that wraps `CMMotionManager` for raw accelerometer data and has its own configurable cadence detection -- completely independent of CadenceService
- The debug interval setting lives in `SensorLabService` only, never read by `CadenceService`
- SensorLabService stops all updates in `onDisappear` and when `scenePhase` leaves `.active`

**Warning signs:**
- Battery drain reports from testers who visited Sensor Lab
- Rolling average window contains 50+ samples instead of the expected 5-10
- Cadence reading responds slowly to pace changes (window overwhelmed with stale samples)

**Phase to address:**
Sensor Lab phase -- isolation architecture must be designed from day one.

---

### Pitfall 3: Tap BPM Silently Overwriting API-Sourced BPM

**What goes wrong:**
A user taps a BPM for a song that already has a GetSongBPM-verified value (e.g., API returned 128 BPM). The tap result (126 BPM) silently overwrites the verified value via `BPMCacheService.cache()`, which does a simple upsert. Now the song matches differently during runs, and there is no way to revert to the original API value.

**Why it happens:**
The current `cache(trackID:name:artist:bpm:)` method overwrites `bpm` regardless of origin. Without a `bpmSource` field, there is no distinction between "API-verified 128" and "user-tapped 126". The developer assumes manual input should always win, but users frequently tap to off-beats, half-time, or double-time.

**How to avoid:**
- Add `bpmSource: String?` to CachedBPM before building the tap BPM feature
- Create separate write paths: `cacheFromAPI(trackID:bpm:)` sets source to `"api"`, `cacheManualBPM(trackID:bpm:)` sets source to `"manual"`
- If a track already has API BPM, show the existing value in the tap UI and require explicit "Override" confirmation
- Store the API BPM alongside manual BPM: add `manualBPM: Int?` field so the original is never lost
- Provide "Reset to original" that clears `manualBPM` and reverts to API value

**Warning signs:**
- Playlist BPM counts change after a user uses tap BPM
- Songs that previously matched well now match poorly
- No audit trail for which BPMs are human-entered vs API-sourced

**Phase to address:**
Tap BPM phase -- source tracking must exist BEFORE any manual BPM write path is added. This means the BPM Confidence schema change must come first.

---

### Pitfall 4: Zero-BPM "Skip" Fallback Creating Rapid-Fire Spotify API Calls

**What goes wrong:**
When fallback is set to "skip" and the playlist has many unscanned tracks (common for new users), `selectNextMatch(forSPM:)` finds no BPM match, falls through to `findClosestTrack(forSPM:)` (which also only considers tracks in `bpmMap`), and returns nil. The engine tries the next track, also nil, creating a rapid-fire cycle. Each failed match attempt that does find something calls `playTrack()` -> `SpotifyPlayerService.shared.play()`, risking Spotify's 429 rate limit.

**Why it happens:**
The current matching logic in `selectNextMatch` already handles empty pools (resets `playedTrackIDs`, falls back to `findClosestTrack`). But all fallbacks require tracks to be in `bpmMap`. If 80% of tracks have no BPM, the usable pool is tiny. When those few tracks exhaust and the pool resets, the same 3 songs repeat. Adding an explicit "skip nil-BPM tracks" behavior does not change the existing flow -- but it codifies a behavior that currently just silently ignores nil-BPM tracks.

**How to avoid:**
- At run start, count BPM coverage: `let coverage = bpmMap.count / playlistTracks.count`. If below 50%, warn the user and suggest scanning first
- Circuit breaker: after 3 consecutive no-match cycles (selectNextMatch returns nil), auto-switch to "play regardless" mode and surface a toast
- "Play regardless" should pick a random unplayed track from the nil-BPM pool -- this is better than silence
- Rate-limit playTrack calls: the existing `lastPlayTime` + 5-second guard is good, but extend it to cover the skip cycle too

**Warning signs:**
- Spotify 429 errors in quick succession during a run
- `playTrack()` called multiple times within the 5-second guard window
- User sees no album art / rapid track flickering in the player

**Phase to address:**
Zero-BPM Fallback phase -- circuit breaker must be designed alongside the fallback configuration, not bolted on after.

---

### Pitfall 5: Confidence Badge Becoming Stale After Playlist Re-scan

**What goes wrong:**
A track is marked as `manual` source (user tapped BPM). Later, `LibraryScanService` re-scans the playlist and GetSongBPM now has a value. The scan calls `BPMCacheService.cache()` which overwrites BPM but has no awareness of `bpmSource`. Result: the track has an API-sourced BPM value but the source field still says "manual". The UI shows the wrong confidence badge.

**Why it happens:**
`LibraryScanService` and the tap BPM feature both write through the same `cache()` method. Neither updates the source field because it does not exist yet, and when it is added, the scan path must be updated to set it.

**How to avoid:**
- Define clear precedence: API BPM always upgrades confidence (API is more reliable than human tapping)
- The scan path must call `cacheFromAPI()` which sets `bpmSource = "api"`, overriding any previous manual source
- The tap path calls `cacheManualBPM()` which sets `bpmSource = "manual"` only when there is no existing API value (or when the user explicitly overrides)
- Confidence badges derive directly from the `bpmSource` field on `CachedBPM`, not a separate state

**Warning signs:**
- Badges showing "manual" for tracks that now have GetSongBPM data
- User confusion about which BPMs they set vs which came from the API

**Phase to address:**
BPM Confidence phase -- write-path separation must be established before LibraryScanService is modified.

---

### Pitfall 6: Sensor Lab Raw Accelerometer Draining Battery When Not Visible

**What goes wrong:**
The Sensor Lab uses `CMMotionManager` for raw accelerometer data (waveforms, g-force visualization). If the user navigates to another tab without the Sensor Lab explicitly stopping, the accelerometer keeps running. Unlike CMPedometer (system-managed, power-efficient), `CMMotionManager` accelerometer updates run at 50-100Hz and drain battery rapidly.

**Why it happens:**
CMPedometer is designed for background/continuous use. CMMotionManager is NOT -- it runs the accelerometer hardware continuously at the requested frequency. Developers treat them the same because both are CoreMotion APIs.

**How to avoid:**
- Create a `SensorLabService` that is NOT a singleton -- instantiate it within the Sensor Lab view
- Stop `CMMotionManager` updates in `onDisappear` of the Sensor Lab view
- Add `scenePhase` observer that stops all accelerometer updates when app backgrounds
- Assert in tests: after Sensor Lab dismiss, `CMMotionManager.isAccelerometerActive == false`

**Warning signs:**
- Battery drain after visiting Sensor Lab but navigating to a different tab
- `isAccelerometerActive` returns true when no debug screen is visible
- Thermal throttling on older devices

**Phase to address:**
Sensor Lab phase -- lifecycle management must be the first thing built, before any visualization.

---

### Pitfall 7: Tap BPM Accuracy Problems From Beat Subdivision Ambiguity

**What goes wrong:**
Users tap to the wrong beat subdivision. Running music often has strong off-beats. Users tap eighth notes (2x BPM) or half-notes (0.5x BPM). A 128 BPM track gets recorded as 64 or 256 BPM. Both are "correct" from a musical perspective but wrong for cadence matching.

**Why it happens:**
Tap BPM is inherently ambiguous. Without audio playback during tapping, users guess the tempo from memory. Even with audio, uptempo EDM and hip-hop have beat subdivisions that confuse non-musicians.

**How to avoid:**
- Show real-time BPM as user taps (updating after each tap), so they can self-correct
- Require minimum 8 taps (fewer = wildly inaccurate due to timing variance)
- Auto-detect doubling/halving: if tapped BPM is within 5% of 2x or 0.5x of a "running range" (130-200 SPM), suggest the normalized value
- Show a pulsing visual at the tapped rate so user can verify "does this feel right?"
- Add quick 2x / 0.5x adjustment buttons after tapping completes
- Play the track during tapping if Spotify playback is available

**Warning signs:**
- Manual BPMs clustering at exactly 2x or 0.5x of expected values
- Songs with manual BPM of 60-80 that are clearly uptempo pop/EDM

**Phase to address:**
Tap BPM phase -- validation and correction affordances must ship with the initial tap UI, not as a follow-up.

---

### Pitfall 8: Confidence Indicator Colors Clashing With Existing Sync State Colors

**What goes wrong:**
BPM confidence badges (verified/approximate/manual) use a traffic-light color scheme (green/yellow/orange). The existing `SyncQuality` enum already uses color-coded states (`stateInSync`, `stateDrifting`, `stateMismatched`) via DesignTokens. Both systems present colored badges on the same screens or in the same mental model, confusing users about what the color means.

**Why it happens:**
The existing v1.3 design system has sync state colors baked into `DesignTokens.swift`. Adding another set of status colors for a different concept (BPM data confidence vs run sync quality) creates visual ambiguity. Both could appear in playlist view (confidence badge) and run view (sync state).

**How to avoid:**
- Confidence badges should NOT use colors from the sync state palette
- Use icons instead of colors for confidence: checkmark (verified), tilde/wave (approximate), hand/tap icon (manual)
- If color is needed, use the neutral palette (gray tones) for confidence -- reserve colored indicators exclusively for run-time sync state
- The two systems should never appear in the same view simultaneously

**Warning signs:**
- Users asking "what does the green dot mean?" (could be sync quality OR confidence)
- Design review reveals both color systems on same screen

**Phase to address:**
BPM Confidence phase -- visual design must be decided before building any badges.

---

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Store `bpmSource` as raw String in SwiftData | Avoids enum migration issues | Typo-prone, no compile-time safety | Always -- use computed property with enum for type safety |
| Single `cache()` method for both API and manual writes | Less code | Cannot distinguish write sources, causes silent overwrites | Never -- separate write paths from day one |
| Debug interval in shared UserDefaults | Quick to implement | Leaks into production behavior, hard to audit | Never -- use separate UserDefaults suite or in-memory-only |
| CMMotionManager as global singleton | Convenient access from any view | Lifecycle leak, battery drain when not visible | Never -- use view-scoped instance tied to Sensor Lab |
| Tap BPM without minimum tap count | Faster UX | Inaccurate BPM from 2-3 taps (timing variance is huge) | Never -- require 8+ taps for reasonable accuracy |
| Batch-fetching confidence for playlist view via individual SwiftData queries | Works with current code structure | O(n) fetches for n tracks, sluggish on large playlists | Only for playlists under 50 tracks; batch fetch above that |

---

## Integration Gotchas

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| CMMotionManager + CMPedometer simultaneously | Running both for Sensor Lab during an active run causes resource contention on older iPhones | Never run both: Sensor Lab is a debug tool, not for mid-run use. Disable "Start Run" when Sensor Lab is active, or stop Sensor Lab when a run starts |
| SwiftData schema change on CachedBPM | Adding non-optional field without default to existing @Model | Always add as optional; test upgrade from v1.3 build with populated cache |
| GetSongBPM re-scan + manual BPM coexistence | Scan overwrites manual values because both use `cache()` | Separate write paths: `cacheFromAPI()` vs `cacheManualBPM()` with clear precedence |
| Spotify rate limits during skip fallback | Rapid `play()` calls when cycling through zero-BPM tracks | Circuit breaker: max 3 consecutive no-match attempts, then fall back to "play regardless" |
| CMMotionManager startAccelerometerUpdates | Forgetting to call `stopAccelerometerUpdates()` on view dismiss | Tie lifecycle to view: stop in `onDisappear` AND `scenePhase != .active` |

---

## Performance Traps

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| Raw accelerometer at 100Hz in Sensor Lab | UI thread overwhelmed, dropped frames, battery drain | Downsample to 10-20Hz for display; buffer raw data on background queue | Immediately on iPhone 12 and below |
| Individual SwiftData fetch per track for confidence badge | Playlist with 500 tracks = 500 queries on scroll | Batch fetch all CachedBPM for playlist track IDs in one query, build dictionary | Playlists over ~100 tracks |
| Tap BPM timer using `Date()` on main thread | Timer drift when main thread is busy (layout, animation) | Use `CADisplayLink` or `mach_absolute_time()` for tap interval measurement | At high BPM (>160): 10ms drift = 2-3 BPM error |
| Recomputing confidence enum for every cell in LazyVStack | Redundant computation on every scroll frame | Compute confidence once per playlist load, store in view model dictionary | Playlists over ~200 tracks |

---

## UX Pitfalls

| Pitfall | User Impact | Better Approach |
|---------|-------------|-----------------|
| Confidence badges without explanation | Users see "verified"/"approximate"/"manual" with no context | Info button or first-time tooltip explaining the three levels |
| Tap BPM without audio playback | User must remember song tempo from memory -- unreliable | Play the track (or Spotify preview) during tapping |
| Zero-BPM fallback buried in Settings | User hits the problem during a run, cannot fix mid-run | Show fallback choice inline on first encounter, with "remember my choice" option |
| Sensor Lab showing raw numbers only | "Accel X: 0.0023" means nothing to non-developers | Show interpreted values: "Detecting: Walking", "Confidence: High", "Steps: smooth rhythm" |
| Confidence colors clashing with sync state colors | Both use red/yellow/green -- which system does the color represent? | Confidence uses icons (checkmark/tilde/hand), sync state keeps its existing color system |
| No undo for tap BPM | User accidentally saves wrong BPM, no way to revert | Show "Reset to original" option when track has API BPM available |

---

## "Looks Done But Isn't" Checklist

- [ ] **Schema migration:** Tested upgrade from v1.3 build with existing BPM cache -- not just clean install
- [ ] **Sensor Lab cleanup:** Accelerometer stops when navigating away (onDisappear + scenePhase)
- [ ] **Sensor Lab isolation:** Debug detection interval does NOT affect production CadenceService.startDetecting()
- [ ] **Tap BPM validation:** Minimum 8 taps enforced, 2x/0.5x auto-detection, not just raw average
- [ ] **Tap BPM vs API conflict:** Manual BPM cannot silently overwrite API-sourced BPM without confirmation
- [ ] **Confidence derivation:** Badge reads from `bpmSource` field on CachedBPM, not a separate or stale cache
- [ ] **Skip fallback circuit breaker:** Tested with playlist 90% unscanned on "skip" mode -- no rapid Spotify calls
- [ ] **Fallback communication:** User understands why a song played despite no BPM (toast or indicator)
- [ ] **Battery test:** 10-minute Sensor Lab session does not drain more than 5% above baseline
- [ ] **Confidence in RunEngine:** `selectNextMatch` and `findMatchingTracks` correctly handle manual vs API BPM
- [ ] **Re-scan updates confidence:** After LibraryScanService re-scan, tracks with new API data show "verified" badge (not stale "manual")
- [ ] **Sensor Lab + active run:** Cannot have both running simultaneously -- one disables/warns about the other

---

## Recovery Strategies

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| Schema migration crash | MEDIUM | Hotfix with correct optional field. Users re-launch, cache survives. If destructive migration shipped, cache rebuilds on next scan (data loss but not fatal) |
| Debug interval leaked to production | LOW | Reset debug settings on app launch outside Sensor Lab. One-line fix |
| Manual BPM overwrote API values | HIGH | No way to know which tracks were overwritten without audit log. Must re-scan all affected playlists. Prevention is the only real strategy |
| Infinite skip loop / rate limit | MEDIUM | Add circuit breaker, ship update. Users can switch fallback to "play regardless" in the meantime |
| Accelerometer battery drain | LOW | Stop accelerometer on next session. Add lifecycle guard in hotfix |
| Stale confidence badges | LOW | Force-refresh confidence from bpmSource field on next playlist view load |
| Confidence/sync color confusion | LOW | Replace color badges with icon badges. No data change needed |

---

## Pitfall-to-Phase Mapping

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| Schema migration breaking cache | BPM Confidence (FIRST phase) | Install v1.3 build with data, upgrade to v1.4, verify cache intact |
| Debug interval leaking to production | Sensor Lab | Use Sensor Lab with 0.5s interval, start production run, verify 5s window unchanged |
| Tap BPM overwriting API values | Tap BPM (AFTER confidence/source tracking) | Tap BPM on track with API value, verify API value preserved unless explicitly overridden |
| Zero-BPM skip loop | Zero-BPM Fallback | Start run with 90% unscanned playlist on "skip", verify circuit breaker fires after 3 attempts |
| Stale confidence after re-scan | BPM Confidence | Tap BPM on track, re-scan playlist via LibraryScanService, verify badge updates to "verified" |
| Sensor Lab battery drain | Sensor Lab | Leave Sensor Lab, verify CMMotionManager.isAccelerometerActive == false |
| Tap BPM accuracy | Tap BPM | Tap half-time on 128 BPM track, verify 2x suggestion appears |
| Confidence/sync color clash | BPM Confidence | Visual review: no overlapping color semantics between confidence and sync state |

---

## Sources

- Direct codebase analysis: `CadenceService.swift` (rolling window, inactivity timer), `BPMCacheService.swift` (upsert pattern, no source field), `RunEngineService.swift` (selectNextMatch, findClosestTrack, bpmMap filtering), `CachedBPM.swift` (current schema)
- Apple CoreMotion documentation: CMPedometer is background-safe and power-efficient; CMMotionManager accelerometer is not
- SwiftData migration behavior: lightweight migration requires optional fields or fields with default values
- Spotify Web API: 429 rate limit responses on rapid sequential play() calls
- Domain knowledge: tap BPM half/double detection is a well-known problem in music production tools (Ableton, Logic Pro tap tempo all handle this)

---
*Pitfalls research for: BeatStep v1.4 -- debug tooling, tap BPM, confidence indicators, zero-BPM fallback*
*Researched: 2026-03-25*
