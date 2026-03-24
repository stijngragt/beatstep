# Pitfalls Research

**Domain:** Active run screen rebuild, integrated music player, cadence indicators, half-tempo matching, pause/idle state UX -- adding to existing SwiftUI iOS running music app
**Researched:** 2026-03-24
**Confidence:** HIGH

---

## Critical Pitfalls

### Pitfall 1: Half-Tempo Mode Breaks the Existing BPM Matching Logic Silently

**What goes wrong:**
The existing `findMatchingTracks(forSPM:)` already considers `spm/2` and `spm*2` as valid matches. Adding a "half-tempo mode" toggle that naively divides the target BPM by 2 creates a double-halving: the method already checks `spm/2`, so a half-tempo mode that passes `spm/2` into that method checks `(spm/2)/2` = quarter-tempo. The pool collapses to near-zero matches at normal running cadences (170 SPM / 4 = ~42 BPM -- no songs exist there).

**Why it happens:**
The half/double BPM support is already baked into `findMatchingTracks` at the matching layer. A feature toggle that changes the *input* BPM rather than the *matching behavior* conflicts with the existing logic. The developer sees "half-tempo" in the spec and instinctively halves the BPM before calling the matcher, not realizing the matcher already does this.

**How to avoid:**
Half-tempo mode must change which matches are *preferred*, not which matches are *considered*. The correct implementation: when half-tempo is on, the matcher should prefer tracks whose BPM equals `spm/2` (i.e., one footstrike per two beats) and deprioritize tracks at `spm*1` (which would feel frantic). The match *pool* stays the same -- the ranking changes. Concretely: add a `tempoMode: TempoMode` parameter to `selectNextMatch` that influences sort order, not the SPM input.

Alternative valid approach: keep `findMatchingTracks` unchanged, add a `preferredBPM` computed property that returns `spm/2` in half-tempo mode, and sort matches by proximity to `preferredBPM` rather than filtering to it. This preserves fallback behavior when no half-tempo matches exist.

**Warning signs:**
- "No matches found" at normal cadences (150-180 SPM) when half-tempo is enabled
- Song pool shrinks dramatically after toggling half-tempo mid-run
- `findMatchingTracks` returns tracks but `selectNextMatch` ignores them

**Phase to address:**
Half-tempo matching phase -- must be designed before any code changes to `RunEngineService`.

---

### Pitfall 2: CMPedometer Inactivity Detection Races With Genuine Pause State

**What goes wrong:**
The existing `CadenceService` has a 5-second inactivity timer that sets `state = .paused`. But CMPedometer does not deliver a "stopped" event -- it simply stops sending updates. The 5-second threshold is too aggressive: a runner waiting at a traffic light for 3 seconds, adjusting their phone, or running very slowly (low step frequency) triggers the paused state. The UI flickers between active and paused.

Additionally, when the run screen shows a deliberate "paused" UI with different visuals (dimmed cadence, "paused" label, music behavior changes), false pauses become highly visible and disruptive. The current v1.2 paused view is minimal; the v1.3 pause UX will have real consequences (music fading, visual state change) that make false triggers much worse.

**Why it happens:**
CMPedometer's update frequency depends on step rate. At low cadence (walking pace, ~100 SPM), updates can arrive every 1-2 seconds. At very low cadence or irregular stepping, gaps of 3-5 seconds between updates are normal. The inactivity timer cannot distinguish "stopped running" from "slow update delivery."

**How to avoid:**
- Increase the inactivity threshold to 8-10 seconds. Running rarely has gaps longer than 6 seconds; traffic lights and phone adjustments typically last 10+ seconds when genuine.
- Add a confirmation period: transition to `.paused` only after 8 seconds of no updates, but add a `.pausePending` intermediate state (internal only, not shown in UI) that starts at 5 seconds. If updates resume during the pending window, cancel the transition silently.
- Do NOT tie music behavior (fade/stop) to the initial pause detection. Add a secondary delay (e.g., 5 seconds after entering `.paused`) before music actions trigger. This gives the user time to resume without hearing their music fade and restart.

**Warning signs:**
- Cadence display flickers between active and paused during slow sections
- Music fades out and restarts during a continuous run
- Users at traffic lights see jarring visual transitions that resolve instantly when they start moving

**Phase to address:**
Pause/idle state phase -- inactivity thresholds must be tuned before the pause UX is built on top of them.

---

### Pitfall 3: Run Screen UI Updates Every 2 Seconds Cause Jarring Number Jumps

**What goes wrong:**
The cadence monitor polls `CadenceService.shared.currentSPM` every 2 seconds (line 340 in `RunEngineService`). The rolling average window is 5 seconds. When the run screen displays a large center-stage cadence number, updates arrive in discrete jumps (e.g., 162 -> 168 -> 165) every 2 seconds. The number feels "choppy" rather than smooth, especially when paired with delta indicators ("+4 spm") and color shift animations.

**Why it happens:**
The current `CadenceDisplayView` renders whatever `currentSPM` is at render time. There is no interpolation. The 2-second poll interval in `RunEngineService` is fine for *song selection* (songs are 3-4 minutes long), but too coarse for a real-time visual display that users stare at during their run.

**How to avoid:**
Separate the display update cadence from the song-selection cadence:
- **Display layer:** Observe `CadenceService.currentSPM` directly via SwiftUI's `@Observable` reactivity (it already updates on every `processCadenceSample` call). The view re-renders when `currentSPM` changes -- no polling needed for the UI. Use `.animation(.easeInOut(duration: 0.3))` on the text to smooth numeric transitions.
- **Song selection layer:** Keep the 2-second poll + 17-second debounce in `RunEngineService` unchanged.
- For the delta indicator ("+4 spm"), compute delta against the *target* BPM (in guided mode) or the *matched song BPM* (in free mode), not against a previous reading. This gives a stable reference point.

**Warning signs:**
- Cadence number visibly "jumps" in the UI during steady running
- Delta indicator oscillates between positive and negative rapidly
- Users report the cadence display feels "laggy" or "jittery"

**Phase to address:**
Run screen rebuild phase -- the display architecture must be decided before building the cadence center-stage UI.

---

### Pitfall 4: Long-Press Gesture for Half-Tempo Toggle Conflicts With Scroll and Tap

**What goes wrong:**
If the half-tempo toggle is triggered by a long-press gesture on the run screen (common UX pattern for mid-run mode switches), the gesture blocks other touch interactions. In SwiftUI, `LongPressGesture` attached to a view inside a `ScrollView` or alongside `TapGesture` causes one of: (a) scrolling stops working, (b) taps require a double-tap to register, or (c) the long-press never fires because the scroll gesture wins.

**Why it happens:**
SwiftUI's gesture system has well-documented priority conflicts. A `LongPressGesture` applied with `.gesture()` works alongside scrolling, but `.simultaneousGesture()` breaks scrolling. The run screen likely won't have a scroll view, but the music player section with track info might, and any future additions (workout stats list) would conflict. More critically, the stop/cool-down buttons in `controlsSection` use `Button` which is a `TapGesture` -- combining long-press and tap on adjacent or overlapping areas creates ambiguity.

**How to avoid:**
- Do NOT use a long-press gesture for the half-tempo toggle. Use a visible, tappable toggle control instead -- a small "1:1 / 1:2" segmented control or a labeled toggle button. This is more discoverable (users cannot discover long-press without instruction) and avoids gesture conflicts entirely.
- If long-press is required by design, isolate it to a specific view (e.g., only the cadence number itself) and use `.gesture()` (not `.simultaneousGesture()`). Add an empty `.onTapGesture {}` before the long-press to prevent scroll blocking.
- For iOS 18+, `UIGestureRecognizerRepresentable` solves gesture conflicts, but the app supports iOS 17+ (per `ScrollViewReader` choice in v1.1).

**Warning signs:**
- Stop button requires double-tap to register after adding long-press
- Long-press gesture fires accidentally during normal run screen interaction
- Gesture conflict only appears on device, works fine in Simulator

**Phase to address:**
Half-tempo matching phase -- interaction design must be finalized before gesture implementation.

---

### Pitfall 5: Music Player State During Pause Creates Spotify API Rate Limit Risk

**What goes wrong:**
When the runner pauses (cadence drops to zero), the app decides to fade/pause Spotify playback. When they resume, the app resumes playback. Each pause/resume cycle is a Spotify Web API call (`/me/player/pause`, `/me/player/play`). At traffic lights, water stops, or shoe-tying breaks, this can fire 5-10 times in a 30-minute run. Combined with the existing song-end monitor polling (every 3 seconds) and cadence-triggered rematches, the app approaches Spotify's rate limit.

Spotify Web API rate limits are not publicly documented per-endpoint, but the general guidance is ~180 requests per minute. The current polling alone (1 request / 3 seconds = 20/min) is safe, but adding pause/resume/fade calls on top of queueing calls on top of playback state fetches can spike to 40-60 requests in burst scenarios.

**Why it happens:**
Each feature (cadence monitoring, song-end detection, pause/resume, music fade) independently makes API calls. No central rate limiter or request coalescing exists.

**How to avoid:**
- Add a minimum interval between pause/resume API calls (e.g., 10 seconds). If the pause state changes within the interval, only send the final state. This prevents rapid pause-resume-pause cycles from hitting the API.
- When the runner pauses, do NOT pause Spotify immediately. Let the current song continue playing. Many runners appreciate that music keeps playing at traffic lights -- it maintains energy. Only pause if the idle state persists for 30+ seconds (indicating a deliberate stop, not a brief pause).
- Consider making music-during-pause a user preference: "Keep playing" (default) vs "Pause music when stopped." This sidesteps the technical issue and respects user preference.

**Warning signs:**
- HTTP 429 responses from Spotify API during runs
- Music cuts out and resumes with audible gaps at traffic lights
- `SpotifyPlayerService` console logs showing rapid-fire API calls

**Phase to address:**
Pause/idle state phase -- music behavior during pause must be designed before implementing the pause UX.

---

### Pitfall 6: Album Art Loading Blocks the Main Thread or Causes Memory Pressure

**What goes wrong:**
The integrated music player needs album art. Loading album art from Spotify's image URLs for every song change (potentially every 3-4 minutes during a run) without caching or background loading causes: (a) main thread hitches when `AsyncImage` reloads, (b) memory growth if previous images are not released, (c) visible placeholder flash between songs.

**Why it happens:**
SwiftUI's `AsyncImage` reloads from scratch when its URL changes. There is no built-in disk or memory cache across `AsyncImage` instances. During a 60-minute run with 15-20 song changes, this is 15-20 network requests for images that could be pre-cached.

**How to avoid:**
- Use `AsyncImage` with a shared `URLCache` by configuring a custom `URLSession` with a larger cache. Or use a lightweight image caching approach: store the last 5 album art images in an in-memory `NSCache<NSString, UIImage>`.
- Pre-fetch the next song's album art when it is selected by `selectNextMatch`, before it starts playing. The match selection happens before `playTrack()` -- use that window to kick off the image download.
- Set a fixed size for the album art view (e.g., 120x120pt) and request the appropriate Spotify image size (Spotify provides 64px, 300px, and 640px variants). Do not load the 640px image for a 120pt display.

**Warning signs:**
- Visible white/gray flash when songs change
- Memory usage grows steadily during long runs
- Album art sometimes fails to load (network timeout during run)

**Phase to address:**
Music player phase -- image loading strategy must be in place before building the album art UI.

---

### Pitfall 7: Cadence Delta Indicator Shows Meaningless Values in Free Mode

**What goes wrong:**
The spec calls for a delta indicator showing "+4 spm" with color coding for sync state. In guided mode this is clear: delta = currentSPM - targetBPM. But in free mode, there is no target -- the music adapts to the runner. Showing a delta against the matched song's BPM creates a confusing feedback loop: the runner sees "-5 spm," tries to speed up, triggers a new song match at the higher cadence, then sees "+3 spm" against the new song, and so on. The indicator oscillates meaninglessly.

**Why it happens:**
The delta concept assumes a fixed reference point. Guided mode has one (target BPM). Free mode does not -- the "target" moves with the runner's cadence.

**How to avoid:**
- In free mode, show the delta between `currentSPM` and the `currentMatchedTrack`'s BPM as a *sync quality* indicator, not a corrective indicator. Use wording like "in sync" / "adapting..." rather than "+4 spm." The color coding shows whether the current song is well-matched, not whether the runner should change pace.
- Alternative: in free mode, suppress the numeric delta entirely and show only the sync state (green = matched, yellow = adapting, red = far off). The numeric delta is only meaningful in guided mode where the runner has a BPM goal.
- Never show a corrective arrow (up/down) in free mode -- the runner should not feel pressured to match the song. The song matches the runner.

**Warning signs:**
- Delta indicator in free mode constantly shows non-zero values
- Users report feeling "judged" by the sync indicator during a free run
- Delta sign flips after every song change

**Phase to address:**
Cadence indicators phase -- the delta display must be mode-aware from the start.

---

### Pitfall 8: Run Screen Navigation/Dismissal Stops the Run Without Confirmation

**What goes wrong:**
The current `RunView.onDisappear` calls `runEngine.stopRun()` and `cadenceService.stopDetecting()`. If the run screen is rebuilt as a fullScreenCover or sheet, swiping to dismiss accidentally ends the run. If it is pushed onto a NavigationStack, a back-swipe ends the run. There is no confirmation dialog, no way to recover.

**Why it happens:**
The `.onDisappear` pattern is correct for the current implementation where leaving the run screen means ending the run. But the v1.3 run screen will be the primary experience -- users may accidentally trigger dismissal via swipe gestures, especially while running with sweaty hands or the phone in an arm band.

**How to avoid:**
- Present the run screen as a `.fullScreenCover` with `interactiveDismissDisabled(true)` while a run is active. This prevents accidental swipe-dismiss entirely.
- Replace `onDisappear { stopRun() }` with an explicit "Stop Run" button that requires a long-press or confirmation alert. The run should only stop via deliberate user action, not navigation events.
- If using a NavigationStack, override the back button and disable the interactive pop gesture during active runs using `UINavigationController.interactivePopGestureRecognizer?.isEnabled = false` via a `UIViewControllerRepresentable`.

**Warning signs:**
- Users report accidentally ending runs
- Run stops when the phone auto-locks and the user unlocks back to a different screen
- `.onDisappear` fires during sheet/cover transitions that are not actual dismissals

**Phase to address:**
Run screen rebuild phase -- presentation and dismissal strategy must be decided first.

---

### Pitfall 9: Background/Lock Screen State Breaks the Cadence-to-Music Pipeline

**What goes wrong:**
The app sets `isIdleTimerDisabled = true` to prevent auto-lock, but users may still manually lock their phone or switch to another app. When the app moves to background: (a) CMPedometer continues delivering updates (it has background capability), (b) SpotifyPlayerService's polling task may be suspended by iOS, (c) the song-end monitor stops detecting song changes, (d) the cadence monitor's `Task.sleep` may not wake on time. The result: cadence is tracked but no song re-matching happens. The same song loops or Spotify's auto-queue takes over.

**Why it happens:**
CMPedometer has background delivery capability, but URLSession tasks and Task.sleep in Swift concurrency are subject to iOS background execution limits. The app does not have the `audio` background mode (Spotify handles its own audio), so it gets only ~30 seconds of background execution before being suspended.

**How to avoid:**
- Accept that song re-matching will not work in background. Document this as expected behavior: "Keep BeatStep visible for best results."
- When returning to foreground (`scenePhase == .active`), immediately fetch current playback state and cadence, then re-evaluate match quality. If the current song no longer matches, queue a new match. This "catch up on foreground" pattern is more reliable than fighting background limits.
- For the song-end monitor specifically: instead of polling every 3 seconds, calculate the expected end time from `currentTrack.durationMs` and the playback start time. Set a single delayed task for that time. This survives short background periods better than continuous polling.

**Warning signs:**
- Song never changes after phone is locked for 2+ minutes
- Cadence updates continue but no new songs are queued
- On foreground return, a burst of queued song changes fires at once

**Phase to address:**
Run screen rebuild phase -- foreground/background lifecycle must be handled before building features that depend on continuous monitoring.

---

## Technical Debt Patterns

Shortcuts that seem reasonable but create long-term problems.

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Putting half-tempo logic inside `effectiveBPM` as a `/2` | Single-line change | Conflicts with existing half/double matching in `findMatchingTracks`; double-halving bug | Never -- half-tempo must be a ranking preference, not a BPM transformation |
| Using `Timer.scheduledTimer` for inactivity in CadenceService (current approach) | Works, simple | Timer fires on main thread RunLoop; if main thread is blocked by heavy SwiftUI layout, timer delivery delays cause false pauses | Replace with `Task.sleep`-based async timer during the pause state rework |
| Loading album art with bare `AsyncImage` without caching | Zero additional code | Memory growth, placeholder flash on every song change, redundant network requests | Acceptable for initial scaffolding only; must add caching before testing with real runs |
| Observing `SpotifyPlayerService.currentTrack` for song-end detection via polling | Already implemented, works | 3-second poll interval means up to 3 seconds of wrong-song display after song ends; battery cost of continuous polling | Keep for now but add duration-based end prediction as enhancement |

---

## Integration Gotchas

Common mistakes when connecting to external services or system APIs.

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| Spotify `/me/player/play` during pause resume | Calling play without checking if a device is active -- returns 404 "No active device" after phone was locked | Fetch `/me/player` first; if no active device, re-activate with `device_id` parameter or show "Open Spotify" prompt |
| Spotify album art URLs | Using the first image in the `album.images` array (640px) for a small player view | Sort `album.images` by size; pick the one closest to 2x display size (e.g., 300px for a 120pt view) |
| CMPedometer `currentCadence` | Assuming `currentCadence` is always non-nil during active walking/running | `currentCadence` can return nil even during activity -- the fallback step-delta calculation in `CadenceService` is essential; do not remove it |
| `isIdleTimerDisabled` | Setting it in `RunView.onAppear` and clearing in `onDisappear` -- but if the app crashes or is force-quit, the timer stays disabled system-wide until the app is relaunched | Set to `false` in `scenePhase == .background` as a safety net, not just in `onDisappear` |

---

## Performance Traps

Patterns that work at small scale but fail as usage grows.

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| Continuous SwiftUI animation on cadence number (`.animation(.easeInOut)` on every SPM change) | High CPU usage when cadence updates every 0.5-1 second; battery drain during 60-minute run | Use `withAnimation` only when the value actually changes meaningfully (delta > 1 SPM); skip animation for identical values | Immediately during real runs -- Instruments shows continuous Core Animation commits |
| Re-rendering entire run screen on every `currentSPM` change | Cadence changes trigger re-evaluation of all subviews including music player, controls, status bar | Extract cadence display, music player, and controls into separate `@Observable`-tracking subviews so only the cadence section re-renders when SPM changes | At normal cadence update frequency (~1/sec) with complex run screen layout |
| Fetching Spotify playback state every 3 seconds for the full run duration | ~1,200 API calls per 60-minute run; battery drain from network radio | Reduce poll frequency to 5 seconds during active playback; pause polling when app is in background; use duration-based prediction for song-end instead of polling | Accumulates over long runs; rate limit risk in guided mode with frequent rematches |

---

## UX Pitfalls

Common user experience mistakes for these specific features.

| Pitfall | User Impact | Better Approach |
|---------|-------------|-----------------|
| Showing "0 SPM" when cadence data hasn't arrived yet on run start | User thinks detection is broken; first 2-3 seconds show zero | Show "Detecting..." state (already exists) until first valid SPM reading; transition to numeric display only after `CadenceService.state == .active` |
| Numeric cadence as the only sync feedback | Runner must do mental math ("Am I close to 160?") while running | Add a visual zone band (arc, bar, or ring) showing position within the target range; the number is secondary to the visual |
| Half-tempo toggle with no explanation | Users don't understand what 1:2 means or when to use it | Brief tooltip or subtitle: "One stride per two beats -- relaxed feel" on first toggle; persist the last-used setting per zone |
| Abrupt music stop when runner pauses | Jarring silence; runner at traffic light loses motivation | Fade music volume over 3-5 seconds if stopping; or better: keep playing and let the runner decide |
| Run screen shows too much information at once | Runner glancing at phone while running can't parse cadence + song + delta + zone + BPM + time simultaneously | Prioritize: cadence number is huge and center-stage, everything else is secondary. Music player at bottom, status bar at top -- both with small text. Runner should get cadence info in a <1 second glance |
| Color-coded sync state uses red for "off-beat" | Red = error/danger in the design system (`stateError`); being slightly off cadence is not an error | Use the accent color (#FF4545) for in-sync, dim/neutral for out-of-sync; avoid red/green which implies right/wrong |

---

## "Looks Done But Isn't" Checklist

Things that appear complete but are missing critical pieces.

- [ ] **Half-tempo matching:** Verify toggling half-tempo mid-run does not clear the current song or cause an immediate rematch -- the current song should finish, and the next match should respect the new mode
- [ ] **Pause state:** Verify that entering pause state does not reset `sustainedSPM` to 0 -- when the runner resumes, matching should continue from the last known cadence, not re-detect from scratch
- [ ] **Album art:** Verify the music player does not show a blank/placeholder state when transitioning between songs -- pre-fetch the next song's art
- [ ] **Lock screen:** Verify that locking the phone during a run and unlocking 5 minutes later results in a correct UI state (current song displayed, cadence showing, no stale data)
- [ ] **Cadence delta:** Verify the delta indicator in guided mode uses the zone's target BPM, not the matched song's BPM, as the reference point -- these can differ by up to the tolerance range
- [ ] **Run screen dismissal:** Verify the run screen cannot be dismissed by swipe gesture while a run is active -- test on device with sweaty-finger simulation
- [ ] **Background transition:** Verify that `isIdleTimerDisabled` is reset to `false` if the app goes to background (scenePhase change), not just on RunView disappear
- [ ] **Inactivity timer:** Verify the 5-second (or adjusted) inactivity threshold works on a physical device during actual running -- Simulator cannot replicate real CMPedometer timing

---

## Recovery Strategies

When pitfalls occur despite prevention, how to recover.

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| Half-tempo double-halving bug deployed | LOW | Fix is in `selectNextMatch` sort logic -- no data migration, no schema change; hotfix release |
| False pause triggers disrupt runs | LOW | Increase threshold constant from 5 to 10 seconds; single-line change in `CadenceService` |
| Album art memory growth during long runs | LOW | Add `NSCache` with 5-item limit; wrap `AsyncImage` in caching layer; no API changes |
| Run ends on accidental screen dismiss | MEDIUM | Switch to `fullScreenCover(interactiveDismissDisabled: true)`; requires view hierarchy restructure if run screen was pushed via NavigationLink |
| Spotify rate limit hit during run | MEDIUM | Add request coalescing and minimum interval between API calls in `SpotifyPlayerService`; requires changes to pause/resume and polling logic |
| Background song matching stops working | LOW | Add "catch up on foreground" logic in `scenePhase` observer; no fundamental architecture change needed |

---

## Pitfall-to-Phase Mapping

How roadmap phases should address these pitfalls.

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| Half-tempo double-halving | Half-tempo matching | Unit test: enable half-tempo at 170 SPM -- matched songs should be ~85 BPM, not ~42 BPM |
| False pause from CMPedometer gaps | Pause/idle state | Physical device test: run slowly (walking pace) -- no false pause triggers |
| Choppy cadence display updates | Run screen rebuild | Visual test: cadence transitions smoothly during steady running |
| Long-press gesture conflicts | Half-tempo matching (if using gesture) | All run screen controls respond correctly alongside the toggle |
| Spotify API rate limits during pause/resume | Pause/idle state | 60-minute test run: total Spotify API calls < 1500 |
| Album art loading issues | Music player | Song change during run: no visible placeholder flash |
| Free mode delta indicator confusion | Cadence indicators | Free mode shows sync quality, not corrective delta |
| Accidental run dismissal | Run screen rebuild | Swipe gesture on run screen during active run: run continues |
| Background/foreground pipeline break | Run screen rebuild | Lock phone for 3 min during run, unlock: correct song and cadence shown within 2 seconds |

---

## Sources

- Apple Developer Documentation: [CMPedometer](https://developer.apple.com/documentation/coremotion/cmpedometer)
- Apple Developer Documentation: [CMPedometerData.currentCadence](https://developer.apple.com/documentation/coremotion/cmpedometerdata/currentcadence)
- Apple Developer Forums: [CMPedometer updates in the background](https://developer.apple.com/forums/thread/30339)
- Apple Developer Forums: [SwiftUI Gestures prevent scrolling with iOS 18](https://developer.apple.com/forums/thread/760035)
- Apple Developer Documentation: [Understanding and improving SwiftUI performance](https://developer.apple.com/documentation/Xcode/understanding-and-improving-swiftui-performance)
- WWDC23: [Demystify SwiftUI performance](https://developer.apple.com/videos/play/wwdc2023/10160/)
- Daniel Saidi: [Using complex gestures in a SwiftUI ScrollView](https://danielsaidi.com/blog/2022/11/16/using-complex-gestures-in-a-scroll-view)
- Spotify Developer: [Web API](https://developer.spotify.com/documentation/web-api)
- Spotify Community: [Web API Playback issues](https://community.spotify.com/t5/Spotify-for-Developers/Spotify-Web-API-Playback/td-p/5231490)
- Runo: [Running Music BPM Guide](https://www.runoapp.com/blog/running-music-bpm-guide) -- half/double tempo matching patterns
- Codebase inspection: `RunEngineService.swift`, `CadenceService.swift`, `SpotifyPlayerService.swift`, `RunView.swift`, `CadenceDisplayView.swift`

---
*Pitfalls research for: BeatStep v1.3 -- active run screen, music player, cadence indicators, half-tempo matching, pause/idle state*
*Researched: 2026-03-24*
