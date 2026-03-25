---
phase: 20-tap-bpm-input
verified: 2026-03-25T12:47:00Z
status: human_needed
score: 11/11 automated must-haves verified
human_verification:
  - test: "Badge tap opens half-sheet, row tap still plays track"
    expected: "Tapping BPM badge opens TapBPMView sheet; tapping rest of row plays track without opening sheet"
    why_human: "Gesture separation between Button-wrapped badge and parent onTapGesture requires physical interaction to verify no conflict"
  - test: "Tap zone feedback: valid tap flash + light haptic"
    expected: "Zone briefly dims to 40% opacity; light impact haptic fires on each valid tap"
    why_human: "UIImpactFeedbackGenerator and opacity animation are runtime behaviors, not statically verifiable"
  - test: "Outlier tap: shake animation + error haptic"
    expected: "Zone shakes left/right three times; notification error haptic fires; dot does NOT fill; BPM does not change"
    why_human: "UINotificationFeedbackGenerator and ShakeModifier animation runtime behavior requires physical device"
  - test: "8-dot progress and Stable indicator"
    expected: "One dot fills per valid interval (0-8 progression); Stable checkmark label appears after 8 intervals (9 taps)"
    why_human: "Visual progression requires live interaction to verify completedIntervals mapping is correct"
  - test: "Save flow: persists BPM, refreshes badge"
    expected: "Save button enabled after 4 taps; tap Save fires success haptic, sheet dismisses, playlist row badge updates to manual confidence (hand icon)"
    why_human: "Badge refresh and sheet dismissal are runtime UI transitions"
  - test: "Track auto-plays when sheet opens"
    expected: "Spotify begins playing the tapped track when TapBPMView appears"
    why_human: "SpotifyPlayerService.shared.play() call requires live Spotify connection to observe"
  - test: "3-second inactivity auto-reset"
    expected: "After 3 seconds with no taps, BPM clears to '--', tap count resets to 0, dots empty"
    why_human: "Timer.scheduledTimer fires in real time; cannot be verified statically"
---

# Phase 20: Tap BPM Input Verification Report

**Phase Goal:** Users can manually set BPM for any track by tapping along with the music
**Verified:** 2026-03-25T12:47:00Z
**Status:** human_needed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Tapping at steady tempo produces correct BPM within +/-1 | VERIFIED | 14/14 unit tests pass; `testSecondTapProduces120BPM`, `testSteady120BPMNineTapsProducesStable` confirm exact BPM calculation via `60.0 / avgInterval` |
| 2 | Rolling window uses last 8 intervals, discarding older data | VERIFIED | `intervals.removeFirst()` when `count > maxIntervals` (8); `testRollingWindowUsesLast8Intervals` passes |
| 3 | 3 seconds of inactivity resets all tap state | VERIFIED | `Timer.scheduledTimer(withTimeInterval: 3.0)` calls `reset()` on MainActor; verified by test 9 which calls reset() directly (timer behavior implicit) |
| 4 | Erratic taps (>40% median deviation) are rejected without affecting BPM | VERIFIED | `isOutlier()` checks median deviation; `testOutlierTapIsRejected` passes; `lastTapWasOutlier` set, tapCount and BPM unchanged |
| 5 | canSave is true after 4+ taps (3+ intervals) | VERIFIED | `canSave: intervals.count >= 3`; `testCanSaveFalseAtThreeTaps` and `testCanSaveTrueAtFourTaps` both pass |
| 6 | isStable is true after 9 taps (8 intervals) | VERIFIED | `isStable = intervals.count >= maxIntervals`; `testSteady120BPMNineTapsProducesStable` confirms isStable=true at 9 taps |
| 7 | First tap produces no BPM (no interval yet) | VERIFIED | Guard on `tapTimestamps.last` returns early on first tap; `testFirstTapSetsInitialState` confirms currentBPM=nil |
| 8 | User can tap BPM badge on any track to open tap BPM sheet | VERIFIED | `tapBPMTrack` @State in PlaylistDetailView; `.sheet(item: $tapBPMTrack)` presents TapBPMView; TrackRow badge wrapped in Button with `onBadgeTap: { tapBPMTrack = track }` |
| 9 | Row tap and badge tap are independent gestures | VERIFIED | Badge Button with `.buttonStyle(.plain)` captures tap before parent `.onTapGesture`; gesture separation pattern confirmed in code |
| 10 | Save persists BPM via cacheManual and refreshes badge | VERIFIED | `save()` calls `BPMCacheService.shared.cacheManual(trackID:name:artist:bpm:)`; `onSave` closure calls `getBPMInfo` and updates `bpmCache[track.id]` |
| 11 | Track auto-plays via Spotify when sheet opens | VERIFIED | `onAppear` calls `SpotifyPlayerService.shared.play(uri: track.uri, contextURI: playlistURI)` — wiring confirmed statically |

**Score:** 11/11 automated truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `BeatStep/Services/TapBPMEngine.swift` | Pure-logic tap tempo engine | VERIFIED | 107 lines, `@Observable final class TapBPMEngine`, all 5 published properties, `tap()`, `tap(at:)`, `reset()` present |
| `BeatStepTests/TapBPMEngineTests.swift` | Unit tests for all TapBPMEngine behaviors | VERIFIED | 212 lines, 14 test methods covering all 10 specified behaviors + 2 edge cases; 14/14 pass |
| `BeatStep/Views/Library/TapBPMView.swift` | Tap BPM half-sheet UI | VERIFIED | 189 lines, `struct TapBPMView`, header/progress dots/tap zone/bottom bar/ShakeModifier all present |
| `BeatStep/Views/Library/PlaylistDetailView.swift` | Badge tap gesture + sheet presentation + bpmCache refresh | VERIFIED | `tapBPMTrack: SpotifyTrack?` state present; `.sheet(item: $tapBPMTrack)` present; `onBadgeTap` callback wired at TrackRow call site |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `TapBPMEngine.tap()` | `currentBPM` | rolling average of intervals | VERIFIED | `Int(round(60.0 / avgInterval))` at line 73 of TapBPMEngine.swift |
| `TapBPMEngine.tap()` | `lastTapWasOutlier` | median deviation check | VERIFIED | `isOutlier()` called at line 53; sets `lastTapWasOutlier = true` on rejection |
| TrackRow badge | TapBPMView sheet | Button sets tapBPMTrack state | VERIFIED | `onBadgeTap: { tapBPMTrack = track }` at ForEach call site; `.sheet(item: $tapBPMTrack)` presents TapBPMView |
| `TapBPMView.save()` | `BPMCacheService.cacheManual()` | direct call on save | VERIFIED | `BPMCacheService.shared.cacheManual(trackID:name:artist:bpm:)` in `save()` function |
| `TapBPMView onSave` callback | bpmCache dict | getBPMInfo refresh in closure | VERIFIED | `onSave: { _ in bpmCache[track.id] = BPMCacheService.shared.getBPMInfo(forTrackID: track.id) }` |
| `TapBPMView.onAppear` | SpotifyPlayerService.play() | auto-play track on sheet open | VERIFIED | `SpotifyPlayerService.shared.play(uri: track.uri, contextURI: playlistURI)` in `.onAppear` |

### Requirements Coverage

| Requirement | Source Plans | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| TAP-01 | 20-01-PLAN, 20-02-PLAN | User can tap along with a song to set its BPM via a large tap area | SATISFIED | TapBPMView tap zone with `.onTapGesture { engine.tap() }` and `.contentShape(Rectangle())`; save persists via cacheManual |
| TAP-02 | 20-01-PLAN, 20-02-PLAN | Tap BPM uses rolling 8-interval average with 3-second inactivity reset | SATISFIED | Rolling window via `removeFirst()` when `count > 8`; 3s Timer resets state; 14 tests confirm |
| TAP-03 | 20-01-PLAN, 20-02-PLAN | Erratic taps filtered via outlier rejection with stabilization indicator | SATISFIED | Outlier rejection via `isOutlier()` (40% median deviation + boundary guards); ShakeModifier error feedback; `isStable` flag + "Stable" UI label after 8 intervals |

No orphaned requirements — TAP-01, TAP-02, TAP-03 all declared in both plans and all three are satisfied.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `PlaylistDetailView.swift` | 121 | `placeholder:` (AsyncImage placeholder closure) | Info | Not a code stub — SwiftUI AsyncImage loading state. No impact. |

No blocker or warning anti-patterns found.

### Human Verification Required

#### 1. Badge tap vs row tap gesture separation

**Test:** Open app, navigate to any playlist. Tap the BPM badge/capsule on a track row. Then tap the row text area on a different track.
**Expected:** Badge tap opens TapBPMView half-sheet; row tap plays that track without opening sheet.
**Why human:** Button-wrapped badge depends on SwiftUI gesture hit-testing priority at runtime; static code analysis confirms the pattern is correct but cannot verify there are no layout/hitbox conflicts.

#### 2. Valid tap visual and haptic feedback

**Test:** Open tap sheet, tap the zone at a steady ~120 BPM pace.
**Expected:** Zone flashes (dims to ~40% opacity, 0.15s ease-out then 0.1s ease-in recovery); light impact haptic fires on each accepted tap; BPM converges toward 120; dots fill one at a time.
**Why human:** UIImpactFeedbackGenerator and opacity animation are runtime behaviors requiring physical interaction.

#### 3. Outlier tap rejection feedback

**Test:** After 4 steady taps, tap very quickly (within ~0.1s) or very slowly (>2s gap).
**Expected:** Zone shakes left/right three times; error haptic fires; dot count does not increment; BPM does not change.
**Why human:** ShakeModifier animation and UINotificationFeedbackGenerator require live device interaction to verify.

#### 4. 8-dot progress and Stable label

**Test:** Tap steadily until 9 taps delivered.
**Expected:** Dots fill one per valid interval (0 to 8 progression shown); after 9th valid tap (8 intervals), "Stable" label with checkmark appears in green.
**Why human:** Visual rendering of `completedIntervals = min(max(0, tapCount - 1), 8)` mapping requires runtime verification.

#### 5. Save flow end-to-end

**Test:** Tap 4+ times, then tap Save.
**Expected:** Save button enables at 4th tap; tapping Save fires success haptic, sheet dismisses, playlist row badge updates from "-- BPM" or previous badge to the new manual BPM with hand icon.
**Why human:** Sheet dismissal transition and badge re-render require live UI observation.

#### 6. Track auto-play on sheet open

**Test:** Tap any BPM badge when Spotify is connected.
**Expected:** Spotify begins playing that track as the sheet opens.
**Why human:** SpotifyPlayerService.shared.play() requires live Spotify SDK connection.

#### 7. 3-second inactivity auto-reset

**Test:** Open tap sheet, tap 3-4 times, then wait without tapping.
**Expected:** After 3 seconds of silence, BPM resets to "--", tap count returns to 0, all dots empty.
**Why human:** Timer.scheduledTimer fires in real time; cannot be triggered in unit tests without live runtime.

### Gaps Summary

No automated gaps found. All 11 observable truths verified. All 4 artifacts exist and are substantive. All 6 key links confirmed wired. All 3 requirements (TAP-01, TAP-02, TAP-03) satisfied. 14/14 unit tests pass.

Seven items flagged for human verification — all are runtime behaviors (haptics, animations, live Spotify integration, timer) that cannot be verified statically. The code patterns are correct; human testing confirms the runtime experience works as intended.

---

_Verified: 2026-03-25T12:47:00Z_
_Verifier: Claude (gsd-verifier)_
