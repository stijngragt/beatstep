---
phase: 05-guided-run-polish
verified: 2026-03-23T10:00:00Z
status: human_needed
score: 14/15 must-haves verified
re_verification: false
human_verification:
  - test: "Complete guided run flow on physical device"
    expected: "Mode picker switches between Free and Guided. Guided reveals pace presets. Starting guided run shows 'Warming up' label that progresses to 'At pace'. Cool Down button triggers 'Cooling down' phase. Mode and BPM persist between runs."
    why_human: "On-device ramp progression, BPM-matched song selection, and UI flow transitions cannot be verified programmatically without running the app against live Spotify playback"
---

# Phase 5: Guided Run Polish — Verification Report

**Phase Goal:** User can set a target pace and let the music guide their cadence, with smart song selection
**Verified:** 2026-03-23
**Status:** human_needed
**Re-verification:** No — initial verification

---

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Guided mode selects songs at fixed target BPM, not runner's cadence | VERIFIED | `effectiveBPM` dispatches `.guided` path returning `targetBPM`; `selectNextMatch(forSPM: engine.effectiveBPM)` used in queueNextMatch; test `testGuidedModeUsesTargetBPM` confirms |
| 2 | Warm-up ramp steps BPM from 140 toward target, one step per song | VERIFIED | `effectiveBPM` warm-up: `min(140 + rampSongsPlayed * 8, targetBPM)`; `handleRampTransition()` increments `rampSongsPlayed`; tests `testWarmUpRampProgression` and `testRampClampsToTarget` pass |
| 3 | Cool-down ramp steps BPM from target back toward 140 | VERIFIED | `effectiveBPM` cool-down: `max(targetBPM - rampSongsPlayed * 8, 140)`; test `testCoolDownRampProgression` and `testCoolDownClampsAtWarmUpBPM` cover both progression and clamping |
| 4 | Ramp never overshoots target BPM (clamped) | VERIFIED | Warm-up uses `min(..., targetBPM)`, cool-down uses `max(..., 140)`; dedicated test `testRampClampsToTarget` at boundary (140 + 5*8 = 180 → clamps to 175) |
| 5 | Smart selection ranks matches by danceability (high for active, low for ramp) | VERIFIED | `preferHighEnergy` computed property: free/.atPace = true, .warmUp/.coolDown = false; `selectNextMatch` sorts by `danceabilityMap[id] ?? 50`; tests `testSmartSelectionRanksByDanceability` and `testSmartSelectionLowDanceabilityForRamp` pass |
| 6 | When pool has fewer than 3 matches, discovery fires asynchronously | VERIFIED | `checkDiscoveryNeeded(matchCount:forBPM:)` fires `fireBackgroundDiscovery()` via background `Task`; `needsDiscovery` flag set; test `testDiscoveryFlagSetWhenPoolLow` confirms flag |
| 7 | Named pace presets map to correct BPM values | VERIFIED | `PacePreset.easyJog=150, steady=160, tempo=170, fast=180, sprint=190, custom=nil`; 8 tests in `PacePresetTests.swift` cover all values and display names |
| 8 | RunMode and target BPM persist to UserDefaults | VERIFIED | `RunMode.saved` reads/writes key `"selectedRunMode"`; `RunMode.savedTargetBPM` reads/writes key `"selectedTargetBPM"` with default 160; `ModePicker` calls `newValue.save()` on change; `PacePresetPicker` calls `RunMode.savedTargetBPM = bpm` on change |
| 9 | User can switch between Free and Guided mode before starting a run | VERIFIED | `ModePicker` segmented control bound to `$runMode` in `RunView.idleView`; `.onChange` saves to UserDefaults |
| 10 | Selecting Guided reveals target BPM configuration with pace presets | VERIFIED | `RunView` line 78-81: `if runMode == .guided { PacePresetPicker(...) }` |
| 11 | Custom preset opens a numeric picker for arbitrary BPM | VERIFIED | `PacePresetPicker` lines 24-41: `if selectedPreset == .custom { Stepper(value: $customBPM, in: 120...200) }` |
| 12 | During guided run, phase label shows 'Warming up' / 'At pace' / 'Cooling down' | VERIFIED | `RunView.activeView` lines 122-126: `if let phase = runEngine.rampPhase { Text(phase.displayLabel) }`; `RampPhase.displayLabel` returns correct strings |
| 13 | Cool Down button appears during guided active run | VERIFIED | `guidedRunControls`: `if runEngine.runMode == .guided && runEngine.rampPhase != .coolDown` shows Cool Down button |
| 14 | Tapping Cool Down triggers ramp-down to warm-up BPM | VERIFIED | Button calls `runEngine.startCoolDown()` which sets `rampPhase = .coolDown, rampSongsPlayed = 0`; effectiveBPM then decrements from targetBPM |
| 15 | Last-used mode and target BPM persist between runs | VERIFIED (automated) / NEEDS HUMAN (runtime) | `RunView` init reads `.saved` and `savedTargetBPM`; persistence logic correct in code; actual round-trip requires device test |

**Score:** 14/15 automated verifications pass. 1 item (truth 15 and overall device flow) needs human verification.

---

## Required Artifacts

### Plan 01 Artifacts

| Artifact | Status | Details |
|----------|--------|---------|
| `BeatStep/Models/RunMode.swift` | VERIFIED | Contains `enum RunMode`, `static var saved`, `func save()`, `static var savedTargetBPM` |
| `BeatStep/Models/RampPhase.swift` | VERIFIED | Contains `enum RampPhase` with `warmUp/atPace/coolDown` and `displayLabel` |
| `BeatStep/Models/PacePreset.swift` | VERIFIED | Contains `enum PacePreset` with all 6 cases, correct BPM values, display names |
| `BeatStep/Services/RunEngineService.swift` | VERIFIED | Contains `effectiveBPM`, ramp state machine, smart selection, `startCoolDown()`, discovery integration |
| `BeatStep/Models/GetSongBPMResponse.swift` | VERIFIED | `GetSongBPMSong` has `let danceability: Int?` at line 37 |
| `BeatStep/Models/CachedBPM.swift` | VERIFIED | Has `var danceability: Int?` with nil default in init |
| `BeatStep/Services/BPMCacheService.swift` | VERIFIED | Has `getDanceability(forTrackID:)` and `cacheDanceability(trackID:danceability:)` methods |
| `BeatStepTests/RunEngineServiceTests.swift` | VERIFIED | 20 test methods (well above 50-line minimum); 9 new guided/ramp/smart-selection tests present |
| `BeatStepTests/PacePresetTests.swift` | VERIFIED | 8 test methods covering all preset BPM values, display names, custom nil, and count |

### Plan 02 Artifacts

| Artifact | Status | Details |
|----------|--------|---------|
| `BeatStep/Views/Run/ModePicker.swift` | VERIFIED | Contains `ModePicker` struct, segmented picker, `onChange` calls `save()` |
| `BeatStep/Views/Run/PacePresetPicker.swift` | VERIFIED | Contains `PacePresetPicker`, horizontal scroll capsule buttons, custom stepper 120-200, persists on change |
| `BeatStep/Views/Run/RunView.swift` | VERIFIED | Contains `ModePicker`, `PacePresetPicker`, phase label, Cool Down button, guided controls |

---

## Key Link Verification

### Plan 01 Key Links

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `RunEngineService.swift` | `RunMode.swift` | `runMode` property drives `effectiveBPM` | WIRED | `runMode` referenced 9 times; drives effectiveBPM dispatch switch at line 54 |
| `RunEngineService.swift` | `BPMDiscoveryService.swift` | on-demand discovery when pool < 3 | WIRED | `BPMDiscoveryService.shared.discoverTracks(atBPM: bpm)` called at line 268 via background Task |
| `RunEngineService.swift` | `danceabilityMap` | smart selection ranking | WIRED | `danceabilityMap[trackA.id] ?? 50` used in sort at lines 227-228; populated from BPMCacheService at line 89 |

### Plan 02 Key Links

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `RunView.swift` | `RunEngineService.swift` | reads `rampPhase` for label | WIRED | `runEngine.rampPhase` read at lines 122, 221 |
| `RunView.swift` | `RunMode.swift` | mode state drives UI visibility | WIRED | `RunMode` used at lines 11, 13, 16, 78, 198, 199, 200 |
| `RunView.swift` | `RunEngineService.swift` | Cool Down button calls `startCoolDown()` | WIRED | `runEngine.startCoolDown()` at line 225 |

---

## Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|-------------|--------|----------|
| RUN-02 | 05-01, 05-02 | Guided run mode — user sets target BPM, app plays music at that tempo | SATISFIED | `effectiveBPM` in guided mode returns ramp target; `RunView` wires mode picker and preset picker; engine ignores cadence for song selection in guided mode |
| RUN-03 | 05-01, 05-02 | Warm-up/cool-down ramp — BPM gradually increases then decreases | SATISFIED | `handleRampTransition()` implements state machine (warmUp → atPace → coolDown → stopRun); 8 BPM steps per song; clamping verified by tests |
| BPM-06 | 05-01 | When multiple songs match BPM, selection considers genre/mood preferences | SATISFIED | Danceability-ranked smart selection replaces `randomElement()`; `danceabilityMap` populated from `BPMCacheService.getDanceability()`; `GetSongBPMSong` parses `danceability: Int?` from API |

No orphaned requirements detected. All three phase 5 requirements are claimed in plans and have implementation evidence.

---

## Anti-Patterns Found

None detected. Scanned all 7 key files for TODO/FIXME/placeholder comments, empty implementations, and return null patterns — clean.

---

## Human Verification Required

### 1. Complete Guided Run Flow on Device

**Test:** Build and run BeatStep on a physical device. Navigate to a playlist with scanned BPM data and tap "Run with this Playlist". In idle state: verify Free/Guided segmented control is visible. Select Guided and confirm pace preset picker appears with all 5 named presets plus Custom. Select Custom and confirm a stepper appears. Start a guided run with Steady (160 BPM). Verify "Warming up" label appears on run screen. After several songs, verify label transitions to "At pace". Tap Cool Down and verify "Cooling down" appears and Stop Run replaces Cool Down. Close and reopen run screen and confirm Guided mode and previous target BPM are still selected.

**Expected:** Mode picker visible. Guided selection reveals preset picker. Warm-up label progresses through phases. Songs feel matched to the ramping BPM (not runner's cadence). Cool Down button triggers ramp-down. Mode and BPM survive app navigation.

**Why human:** Actual BPM-matched song selection during live Spotify playback, the subjective feel of ramp progression over multiple songs, and real UserDefaults persistence across app sessions cannot be verified without running the app. The device-verification checkpoint in 05-02-PLAN Task 2 was marked approved in SUMMARY, but this verification cannot confirm that independently.

---

## Gaps Summary

No blocking gaps found. All automated verifications pass across both plans:

- All model files exist with correct implementations and complete APIs
- `RunEngineService` implements the full guided mode state machine including effectiveBPM dispatch, ramp transitions, danceability-ranked smart selection, and non-blocking discovery
- All UI components exist and are wired correctly: ModePicker and PacePresetPicker in RunView idle state, phase labels in active state, Cool Down button in guided active state
- All three requirements (RUN-02, RUN-03, BPM-06) have clear implementation evidence and test coverage
- 28 total test methods across RunEngineServiceTests (20) and PacePresetTests (8), all testing real behavior

The single human verification item is the device flow test, which the SUMMARY indicates was approved during execution. This verification cannot confirm that independently — it requires a human to confirm on device.

---

_Verified: 2026-03-23_
_Verifier: Claude (gsd-verifier)_
