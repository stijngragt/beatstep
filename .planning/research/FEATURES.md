# Feature Research

**Domain:** Active run screen, music player, cadence visualization, tempo matching, pause/idle UX for a BPM-syncing running music app
**Researched:** 2026-03-24
**Confidence:** MEDIUM-HIGH (competitor patterns well-documented, codebase thoroughly analyzed)

## Scope Note

This file covers NEW features for v1.3 "In The Zone" only. All v1.0-v1.2 features (cadence detection, BPM matching, Spotify playback, free/guided run, design system, tab nav, onboarding, zones, library analysis UX) are shipped and stable. Research below addresses: rebuilt active run screen, integrated music player, cadence sync indicators, half-tempo matching mode, and pause/idle state UX.

---

## Feature Landscape

### Table Stakes (Users Expect These)

Features users assume exist on an active run screen. Missing these = the run experience feels broken.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| **Large center-stage cadence number** | Every fitness app puts the primary metric big and center; runners glance mid-stride. NRC, Strava, Apple Fitness all use oversized primary metrics | LOW | Already have `CadenceDisplayView` with `.displaySPM` font. Needs promotion to hero element in rebuilt layout. Keep trend arrow |
| **Elapsed run time** | Universal across NRC, Strava, Apple Fitness, Peloton. Runners orient by duration even when not tracking distance | LOW | New addition. Simple `Date`-based timer, pause-aware (freeze when `CadenceService.state == .paused`). Display in status bar area, not hero size |
| **Now Playing: song + artist** | Users expect to know what's playing without switching apps. RockMyRun and TrailMix show this inline. MiniPlayer already does this but is disconnected from the run screen | LOW | `SpotifyPlayerService.currentTrack` provides `name` and `artistName`. Elevate into run screen layout alongside album art |
| **Play/pause + skip controls** | Every music player during exercise provides these. Must be thumb-reachable per one-handed navigation patterns | LOW | Already in `MiniPlayerView`. Move into run screen with larger touch targets (44pt minimum per Apple HIG, ideally 56pt+ for sweaty fingers) |
| **Current song BPM visible** | BeatStep's entire value prop is BPM matching. Hiding the song BPM during the run contradicts the core promise | LOW | `BPMCacheService.shared.getBPM(forTrackID:)` already computed in MiniPlayer. Surface prominently in the integrated player area |
| **Zone / mode indicator** | User selected a zone before starting; confirming which zone is active provides orientation. "Am I in guided or free mode?" should never be ambiguous | LOW | `runEngine.runMode` and zone data available. Display as persistent label in status bar area |
| **Stop run action (protected)** | Must be available but protected from accidental taps. Accidental stop mid-run is catastrophic UX | LOW | Current `stopRunButton` has no protection. Add long-press confirmation or swipe-to-stop. Long-press is simpler and works with gloves |
| **Pause-aware idle state** | Runner stops at traffic light. Screen must acknowledge the pause, not show stale data. Strava/NRC use auto-pause detection; BeatStep uses cadence timeout | MEDIUM | `CadenceService` already transitions to `.paused` after 5s inactivity. Current `pausedView` is a minimal placeholder ("Paused" + "Resume running to continue"). Needs deliberate, polished design |
| **Album art / visual anchor** | Music players universally show album art. Creates visual interest on an otherwise metric-heavy screen | LOW | Spotify API provides image URLs via `currentTrack`. Not currently displayed on run screen. Use `AsyncImage` with playlist/track artwork |

### Differentiators (Competitive Advantage)

Features that set BeatStep apart. These make the "music syncs to your stride" promise tangible and visible.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| **Sync state indicator (in-sync / drifting / mismatched)** | No competitor visualizes how well the music BPM matches cadence in real-time. TrailMix stretches tempo silently; RockMyRun adjusts BPM invisibly; Weav Run makes tempo changes audible but doesn't quantify the gap. BeatStep queues matching songs, so showing sync state IS the feedback loop that closes the experience | MEDIUM | Compare `currentSPM` against current song BPM (from `BPMCacheService`). Three states: **synced** (within tolerance), **drifting** (within 2x tolerance), **mismatched** (beyond). Color-code using existing tokens: `stateSuccess` / `stateWarning` / `stateError`. Must account for half-tempo mode in comparison |
| **Delta indicator ("+4 SPM" / "-6 SPM")** | Quantifies the gap between cadence and song BPM. Runners can self-correct pace. Garmin shows HR zone delta; same principle applied to cadence. No running music app does this | LOW | Simple arithmetic: `currentSPM - effectiveSongBPM` (where effective accounts for half/double tempo). Display as signed number near cadence. Only meaningful during `.active` state; hide during `.paused` |
| **Half-tempo toggle (1:1 vs 1/2)** | BeatStep already matches at half/double BPM internally (`findMatchingTracks` checks `spm/2` and `spm*2`), but users have zero visibility or control. A 90 BPM song at 180 SPM feels perfectly synced but the numbers "90 vs 180" look broken. Making this explicit and toggleable mid-run gives runners agency and eliminates confusion | MEDIUM | UI toggle that sets which BPM multiples are considered primary. When in half-tempo mode, the sync/delta display compares `currentSPM` against `songBPM * 2` rather than `songBPM`. Must persist during the run but reset between runs. Display: show effective comparison ("90 BPM x2") so user understands the math |
| **Zone band visualization** | Shows cadence within context of the target zone range. A horizontal bar or arc showing where current SPM sits relative to zone min/max. More informative than a bare number -- provides spatial awareness of "how far off am I?" | MEDIUM | Zones have a BPM target; band = target +/- tolerance. Visual: simple gauge bar with current position marker. Fills green when in range, amber when approaching edge. Only shown in guided mode (free mode has no target) |
| **Cadence-responsive color shift** | The screen subtly shifts color temperature based on sync state. Green-tinted accent when locked in, warm shift when drifting. Creates a visceral "in the zone" feeling without requiring focus. Subconscious feedback | LOW | Tint background or accent elements via `.opacity` modifiers on existing color tokens. Subtle -- not a full screen color change. Derive from sync state computation (same data as sync indicator) |
| **Ramp phase progress** | In guided mode, show progression through warm-up / at-pace / cool-down with visual indicator. Users know where they are in the guided experience without counting songs | LOW | `runEngine.rampPhase` and `rampSongsPlayed` exist. Display as segmented bar with three sections or phase dots with active highlight |

### Anti-Features (Commonly Requested, Often Problematic)

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| **Real-time tempo stretching** | Weav Run and TrailMix do this. Seems like the "perfect" sync | Degrades audio quality noticeably. Requires audio processing pipeline (AVAudioEngine + time-pitch node). Increases battery drain. Licensing complexity. BeatStep's queuing model is a deliberate design choice (PROJECT.md key decision) | Show sync state clearly so users understand the relationship. The queue model preserves original audio quality -- that IS the differentiator |
| **Distance / pace / calories overlay** | "Every running app shows this" | BeatStep is explicitly not a fitness tracker (PROJECT.md: "No workout tracking -- focused product"). Adding these metrics dilutes focus and competes with Strava/Apple Fitness which do it better with GPS/HR | Keep the run screen about music + cadence only. The absence of fitness metrics IS the brand statement. Users run Strava simultaneously |
| **Heart rate display** | Peloton and Apple Fitness show HR prominently | Requires HealthKit continuous HR reading, watch pairing, creates another metric competing for screen real estate on a music-focused screen | Defer entirely. If added later, belongs in a secondary swipe-screen, not the primary run view |
| **Auto-pause with timer freeze** | Standard in NRC/Strava -- timer pauses when you stop | BeatStep doesn't track workout duration for fitness purposes. Music continuing during brief stops (intersection wait) is actually desirable. A frozen timer implies workout tracking that BeatStep explicitly doesn't do | Show "Paused" state visually when cadence drops. Music behavior during pause is a separate concern (keep playing vs pause). Don't freeze a workout timer |
| **Metronome / audio click** | Running metronome apps (RunCadence, My Cadence) use audio clicks to guide cadence | Conflicts with music playback. Annoying layered over headphones. The matched-BPM music IS the metronome -- that's the whole product | The music beat IS the pacing guide. Sync state indicator provides visual confirmation that the beat matches your stride |
| **Song queue preview / upcoming tracks** | "What's playing next?" -- standard in music apps | BeatStep doesn't know what's next until the current song ends and cadence is re-evaluated. Showing a queue implies a fixed playlist, contradicting the adaptive model | Show nothing, or show "Next: matched to your cadence." The adaptive-unknown-next is a feature, not a bug |
| **Complex gesture controls** | Swipe patterns, multi-finger gestures for different actions | Sweaty fingers, bouncing phone in armband, gloves in winter. Complex gestures fail during physical activity. Auto-pause research confirms: fewer controls = better during exercise | Large tap targets only. Play/pause, skip, stop. Three actions maximum for primary controls |

---

## Feature Dependencies

```
[Rebuilt Run Screen Layout]
    |-- contains --> [All table stakes features]
    |-- contains --> [All differentiator features]
    |-- requires --> [Status bar area: zone + time + sync state]
    |-- requires --> [Hero area: cadence number + delta + trend]
    |-- requires --> [Player area: art + song + controls + BPM]
    |-- requires --> [Controls area: stop (protected)]

[Sync State Indicator]
    |-- requires --> [Song BPM visible on run screen]
    |-- requires --> [Cadence display active]
    |-- feeds into --> [Cadence-responsive color shift]
    |-- must account for --> [Half-tempo toggle mode]

[Delta Indicator "+4 SPM"]
    |-- requires --> [Song BPM visible on run screen]
    |-- requires --> [Cadence display active]
    |-- enhances --> [Sync State Indicator]
    |-- must account for --> [Half-tempo toggle mode]

[Half-Tempo Toggle]
    |-- requires --> [Song BPM visible on run screen]
    |-- modifies --> [RunEngineService.findMatchingTracks multiplier logic]
    |-- modifies --> [Sync state + delta calculations]
    |-- must ship with --> [Sync State Indicator] (otherwise numbers confuse users)

[Zone Band Visualization]
    |-- requires --> [Zone / mode indicator in status bar]
    |-- only shown in --> [Guided mode runs]

[Cadence-Responsive Color Shift]
    |-- requires --> [Sync State Indicator computed state]

[Ramp Phase Progress]
    |-- reads from --> [RunEngineService.rampPhase + rampSongsPlayed]
    |-- only shown in --> [Guided mode runs]

[Pause/Idle State UX]
    |-- requires --> [CadenceService.state == .paused] (already implemented)
    |-- affects --> [All display areas: dim hero, ghost last SPM, hide delta]
    |-- independent of --> [Other differentiator features]

[Elapsed Time Display]
    |-- pauses when --> [CadenceService.state == .paused]
    |-- independent of --> [Music player features]
```

### Dependency Notes

- **Half-tempo toggle MUST ship with sync state indicator.** Without sync visualization, toggling between 1:1 and 1/2 is meaningless to the user. The toggle changes which BPM comparison is shown -- if nothing is shown, there's nothing to toggle.
- **Sync state and delta both depend on song BPM.** Song BPM must be surfaced on the run screen before either indicator makes sense. Build the player area (with BPM display) first.
- **Pause state is independent.** `CadenceService` already handles the `.paused` transition at 5s inactivity. The UX work is purely view-layer: dimming, ghosting last SPM, hiding active-only elements.
- **Zone band and ramp progress are guided-mode-only.** These features are irrelevant in free mode. The layout must conditionally show/hide them based on `runEngine.runMode`.
- **Color shift is a visual layer on top of sync state.** Same underlying computation, different output. Build sync state logic once, consume it in both the indicator and the color shift.

---

## MVP Definition

### Launch With (v1.3 Core)

The rebuilt run screen must ship with all of these to feel complete:

- [ ] **Rebuilt run screen layout** -- three zones: status bar (zone, time, sync), hero area (cadence, delta, trend), player area (art, song, controls, BPM)
- [ ] **Sync state indicator** -- color-coded in-sync/drifting/mismatched based on cadence vs song BPM (accounting for half-tempo)
- [ ] **Delta indicator** -- "+4 SPM" / "-6 SPM" near cadence number, accounting for effective BPM comparison
- [ ] **Song BPM on run screen** -- visible in the integrated player area, not just the global MiniPlayer
- [ ] **Half-tempo toggle** -- 1:1 / 1/2 switch, visible mid-run, affects matching behavior and display math
- [ ] **Pause/idle state** -- deliberate visual: dimmed elements, "Paused" overlay, last-known SPM ghosted, delta hidden
- [ ] **Elapsed time** -- pause-aware timer in status bar
- [ ] **Album art** -- visual anchor in player area
- [ ] **Protected stop action** -- long-press to stop (prevents accidental mid-run stop)

### Add After Validation (v1.3.x)

- [ ] **Zone band visualization** -- gauge bar showing cadence position within zone range. Add if users report confusion about whether they're "in zone"
- [ ] **Cadence-responsive color shift** -- subtle background tinting based on sync state. Add if static sync indicator feels insufficient
- [ ] **Ramp phase progress** -- visual warm-up/pace/cool-down progression. Add if guided mode users want more phase awareness

### Future Consideration (v2+)

- [ ] **Haptic feedback on sync state changes** -- vibrate when entering/leaving sync. iOS haptics are cheap but need user preference toggle
- [ ] **Lock screen / Dynamic Island** -- Live Activities showing cadence + sync state without unlocking
- [ ] **Apple Watch companion** -- cadence + sync on wrist, controls on watch
- [ ] **Customizable run screen layout** -- let users choose which metrics are shown (like Cadence app's customizable screens)

---

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| Rebuilt run screen layout | HIGH | MEDIUM | P1 |
| Sync state indicator | HIGH | LOW | P1 |
| Delta indicator | MEDIUM | LOW | P1 |
| Song BPM on run screen | HIGH | LOW | P1 |
| Half-tempo toggle | HIGH | MEDIUM | P1 |
| Pause/idle state UX | HIGH | LOW | P1 |
| Album art in player | MEDIUM | LOW | P1 |
| Elapsed time display | MEDIUM | LOW | P1 |
| Protected stop action | MEDIUM | LOW | P1 |
| Zone band visualization | MEDIUM | MEDIUM | P2 |
| Cadence-responsive color shift | LOW | LOW | P2 |
| Ramp phase progress | LOW | LOW | P2 |

**Priority key:**
- P1: Must have for v1.3 launch
- P2: Should have, add in v1.3.x if time permits
- P3: Nice to have, future consideration

---

## Run Screen Layout Recommendation

Based on competitor analysis and the existing codebase, the rebuilt run screen should use a three-zone vertical layout optimized for mid-run glanceability:

```
+----------------------------------+
| STATUS BAR                       |
| [Zone 3] [12:34] [IN SYNC]      |
+----------------------------------+
|                                  |
|           HERO AREA              |
|            172                   |
|         +4 SPM  ->              |
|            SPM                   |
|                                  |
+----------------------------------+
| PLAYER AREA                      |
| [art] Song Name        [BPM]    |
|       Artist Name               |
|    [<<]  [||]  [>>]             |
+----------------------------------+
| [====== STOP (long press) =====] |
+----------------------------------+
```

**Rationale:**
- **Status bar at top:** Secondary info that orients but doesn't demand attention. Zone label, elapsed time, sync state pill.
- **Hero cadence center stage:** The number runners glance at mid-stride. Largest element. Delta indicator and trend arrow are satellites to this number.
- **Player area at bottom-center:** Album art provides visual weight. Song info + BPM visible. Controls in thumb zone for one-handed operation.
- **Stop action at very bottom:** Protected by long-press. Full-width for findability but requires intentional action.

---

## Half-Tempo Matching: Design Details

The 180 SPM / 90 BPM equivalence is well-documented in running literature. Research confirms:

- A runner at 180 SPM matches perfectly to a 180 BPM song (1:1 -- one step per beat)
- The same runner also matches to a 90 BPM song (1/2 -- two steps per beat, each foot lands on alternating beats)
- `RunEngineService.findMatchingTracks` already checks `spm`, `spm/2`, and `spm*2`

**The problem:** When BeatStep plays a 90 BPM song for a 180 SPM runner, the display shows "90 BPM" next to "180 SPM". Without context, this looks like a mismatch -- the delta shows "-90 SPM" which is alarming.

**The solution:**
1. **Toggle control:** Small segmented toggle or icon button: "1:1" vs "1/2". Defaults to 1:1.
2. **When 1/2 is active:**
   - Song BPM display shows effective BPM: "90 BPM (x2)" or "= 180"
   - Delta computes against `songBPM * 2` instead of `songBPM`
   - Sync state evaluates against the doubled value
   - `findMatchingTracks` prioritizes half-tempo matches (or exclusively matches them)
3. **When 1:1 is active:**
   - Standard behavior: compare SPM directly to song BPM
   - Half/double matches still work in the engine but aren't prioritized
4. **Mid-run switching:** Toggle is accessible during the run. State persists for the duration of the run, resets on next run start.

---

## Pause/Idle State: Design Details

Current behavior: `CadenceService` transitions to `.paused` after 5 seconds of no steps. The `pausedView` shows "Paused" + "Resume running to continue" + last known SPM dimmed.

**Enhanced pause state should:**

| Element | Active State | Paused State |
|---------|-------------|--------------|
| Cadence number | Full brightness, updating | Ghosted (30% opacity), frozen at last value |
| Trend arrow | Visible, colored | Hidden |
| Delta indicator | Visible, signed number | Hidden |
| Sync state | Color-coded pill | Neutral/grey |
| Elapsed time | Counting | Frozen (or shows "Paused" badge) |
| Music player | Playing | Keep playing (deliberate: music at traffic light is fine) |
| Stop button | Available | Available |
| Overall screen | Normal | Subtle dim overlay or reduced brightness on metrics |

**Key design decision: Music continues during pause.** Unlike fitness apps that pause the workout timer, BeatStep's pause means "you stopped running" not "you want silence." The music keeps the energy up at traffic lights. When cadence resumes, the screen un-dims and metrics update live again.

**Transition behavior:**
- Active -> Paused: 5 second inactivity timeout (already implemented in `CadenceService`)
- Paused -> Active: First step detected re-triggers `.active` state (already implemented)
- The transition should animate: fade-to-dim over 0.5s, un-dim over 0.3s

---

## Competitor Feature Analysis

| Feature | Nike Run Club | Strava | TrailMix | RockMyRun | Weav Run | BeatStep v1.3 |
|---------|--------------|--------|----------|-----------|----------|---------------|
| Primary metric | Pace (large) | Pace + distance | Cadence | BPM target | Pace | **Cadence (hero)** |
| Music integration | Separate app | None | Built-in tempo stretch | Built-in tempo adjust | Built-in tempo stretch | **Built-in queue match** |
| BPM sync method | N/A | N/A | Tempo stretching | Body-Driven Music (accelerometer) | Tempo stretching (100-240 BPM range) | **Song queuing (preserves audio)** |
| Sync feedback to user | None | None | None visible | BPM number only | Speed change audible | **Visual sync state + delta number** |
| Half/double BPM | N/A | N/A | Manual tempo lock | N/A | Automatic (invisible) | **Explicit toggle with math shown** |
| Pause detection | Auto-pause (GPS speed) | Auto-pause (GPS, configurable threshold) | Unknown | Unknown | Unknown | **Cadence-based (5s no-step timeout)** |
| Pause behavior | Timer freezes | Timer freezes, configurable | Unknown | Unknown | Unknown | **Music continues, metrics dim** |
| Run metrics shown | Distance, pace, HR, time | Distance, pace, elevation, HR, cadence | Steps, cadence | Steps, distance, HR, calories | Cadence, distance | **Cadence, time, zone, sync state only** |
| Album art during run | N/A (separate player) | N/A | Yes | Yes (mix art) | Yes | **Yes** |

**Key competitive insight:** No competitor in the running-music space visualizes the cadence-to-music sync relationship. TrailMix and RockMyRun adjust tempo silently. Weav Run makes tempo changes audible but doesn't quantify the gap. BeatStep's sync state indicator + delta display is genuinely novel. This is the primary differentiator for v1.3.

---

## Sources

- [RockMyRun - Body-Driven Music technology](https://www.rockmyrun.com/)
- [TrailMix: Step to the Beat - App Store](https://apps.apple.com/us/app/trailmix-step-to-the-beat/id647651691)
- [Weav Run - Music matching pace - Women's Running](https://www.womensrunning.com/culture/weav-run-music-pace/)
- [Nike Run Club app features](https://www.nike.com/nrc-app)
- [Nike Run Club review - Tom's Guide](https://www.tomsguide.com/reviews/nike-run-club-review)
- [Strava Auto-Pause documentation](https://support.strava.com/hc/en-us/articles/216919277-Auto-Pause)
- [Garmin Auto-Pause best practices](https://forums.garmin.com/developer/connect-iq/f/discussion/7232/best-practices-to-implement-auto-pause-in-an-app)
- [Running Music BPM Guide - half/double tempo](https://www.runoapp.com/blog/running-music-bpm-guide)
- [Spontaneous Entrainment of Running Cadence to Music Tempo - PMC](https://pmc.ncbi.nlm.nih.gov/articles/PMC4526248/)
- [Fitness App UI Design principles - Stormotion](https://stormotion.io/blog/fitness-app-ux/)
- [Running Apps UX Research - Medium](https://fernandocomet.medium.com/running-apps-ux-research-7e07e41f556c)
- [Cadence app - customizable run screens](https://getcadence.app/features/)
- [SportTracks - Pros and cons of pausing workouts](https://sporttracks.mobi/blog/the-pros-and-cons-of-pausing-workouts)
- Codebase analysis: `RunView.swift`, `CadenceDisplayView.swift`, `MiniPlayerView.swift`, `CadenceService.swift`, `RunEngineService.swift`

---
*Feature research for: BeatStep v1.3 "In The Zone" -- active run screen, music player, cadence visualization, tempo matching, pause states*
*Researched: 2026-03-24*
