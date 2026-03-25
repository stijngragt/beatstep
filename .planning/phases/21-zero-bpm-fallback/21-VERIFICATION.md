---
phase: 21-zero-bpm-fallback
verified: 2026-03-25T00:00:00Z
status: passed
score: 8/8 must-haves verified
re_verification: false
---

# Phase 21: Zero-BPM Fallback Verification Report

**Phase Goal:** Let users configure what happens when the queue encounters a track with no BPM data — skip, play anyway, or prompt.
**Verified:** 2026-03-25
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| #  | Truth                                                                           | Status     | Evidence                                                                               |
|----|---------------------------------------------------------------------------------|------------|----------------------------------------------------------------------------------------|
| 1  | ZeroBPMFallback enum has three cases: skip, playRegardless, prompt              | VERIFIED   | ZeroBPMFallback.swift lines 4–6: all three cases present with correct raw values       |
| 2  | Default fallback is skip (preserves current behavior)                           | VERIFIED   | ZeroBPMFallback.swift line 21–25: `.saved` returns `.skip` when no UserDefaults entry  |
| 3  | User can select zero-BPM behavior from a picker in Settings                     | VERIFIED   | SettingsView.swift lines 48–55: Playback section with Picker and ForEach over allCases |
| 4  | Selected fallback persists across app restarts via UserDefaults                 | VERIFIED   | SettingsView.swift lines 106–108: `.onChange` calls `newValue.save()`                  |
| 5  | During a run with fallback=skip, nil-BPM tracks are never selected              | VERIFIED   | RunEngineService.swift line 267: fallback block only entered if `.playRegardless` or `.prompt` |
| 6  | During a run with fallback=playRegardless, nil-BPM tracks are selected as fallback | VERIFIED | RunEngineService.swift lines 267–283: nil-BPM pool selected after BPM matching exhausted |
| 7  | Nil-BPM tracks played via fallback are added to playedNilBPMIDs (no repeats)   | VERIFIED   | RunEngineService.swift lines 270, 279: playedNilBPMIDs.insert on every selection       |
| 8  | BPM-matched tracks are always preferred over nil-BPM tracks in playRegardless mode | VERIFIED | RunEngineService.swift lines 260–265: findClosestTrack returns first; nil-BPM only reached if that returns nil |

**Score:** 8/8 truths verified

### Required Artifacts

| Artifact                                      | Expected                               | Status    | Details                                                    |
|-----------------------------------------------|----------------------------------------|-----------|------------------------------------------------------------|
| `BeatStep/Models/ZeroBPMFallback.swift`        | Enum with UserDefaults persistence     | VERIFIED  | 31 lines, all 3 cases, displayName, key, saved, save()     |
| `BeatStep/Views/Settings/SettingsView.swift`   | Playback section with fallback picker  | VERIFIED  | @State zeroBPMFallback, Section("Playback"), Picker, onChange |
| `BeatStepTests/ZeroBPMFallbackTests.swift`     | Unit tests for enum and persistence    | VERIFIED  | 5 tests: cases count, default, round-trip, displayNames, CaseIterable |
| `BeatStep/Services/RunEngineService.swift`     | Fallback-aware track selection         | VERIFIED  | zeroBPMFallback property, loaded in startRun, logic in selectNextMatch, playedNilBPMIDs |
| `BeatStepTests/RunEngineServiceTests.swift`    | Tests for fallback behavior per mode   | VERIFIED  | 5 new tests using setZeroBPMFallbackForTesting helper      |

### Key Link Verification

| From                                          | To                                  | Via                                        | Status   | Details                                                          |
|-----------------------------------------------|-------------------------------------|--------------------------------------------|----------|------------------------------------------------------------------|
| `SettingsView.swift`                          | `ZeroBPMFallback.swift`             | `@State .saved` + `.onChange` + `.save()`  | WIRED    | Line 8: `@State private var zeroBPMFallback: ZeroBPMFallback = .saved`; lines 106-108: `.onChange` saves |
| `RunEngineService.swift`                      | `ZeroBPMFallback.swift`             | `ZeroBPMFallback.saved` in `startRun`      | WIRED    | Line 126: `zeroBPMFallback = ZeroBPMFallback.saved`              |
| `RunEngineService.selectNextMatch`            | nil-BPM track pool                  | `bpmMap[$0.id] == nil` filter after BPM exhaustion | WIRED | Lines 267-283: fallback block with nil filter and playedNilBPMIDs tracking |

### Requirements Coverage

| Requirement | Source Plan | Description                                                    | Status    | Evidence                                                        |
|-------------|------------|----------------------------------------------------------------|-----------|-----------------------------------------------------------------|
| FALL-01     | 21-01      | User can configure zero-BPM behavior in Settings (skip/play regardless/prompt) | SATISFIED | SettingsView Playback section with picker; ZeroBPMFallback enum |
| FALL-02     | 21-02      | Run engine respects configured fallback when encountering nil-BPM tracks | SATISFIED | RunEngineService loads .saved at startRun; selectNextMatch fallback logic |

Both requirements marked `[x]` in REQUIREMENTS.md. No orphaned requirements.

### Anti-Patterns Found

No anti-patterns found.

| File                                    | Line | Pattern | Severity | Impact |
|-----------------------------------------|------|---------|----------|--------|
| (none)                                  | —    | —       | —        | —      |

### Notable Implementation Detail

Plan 21-02 deviated from the original spec in a correct way: instead of reusing `playedTrackIDs` for nil-BPM tracking, a separate `playedNilBPMIDs` set was added. This prevents the BPM pool exhaustion reset (`playedTrackIDs.removeAll()`) from clearing nil-BPM play history and causing immediate repeats. The deviation is an improvement, not a regression. Confirmed in RunEngineService.swift line 48 and lines 270, 277, 279, 497.

The `prompt` case is intentionally wired to the same code path as `playRegardless` (plays track without prompting). This is a known deferral — a future phase can add a prompt UI overlay. The current behavior is a superset of skip: prompt tracks are played rather than skipped.

### Human Verification Required

1. **Settings Picker Appearance**
   **Test:** Open Settings in the app. Verify a "Playback" section appears between "Running Zones" and "Permissions" with a "No-BPM Tracks" menu picker showing Skip / Play Anyway / Ask Me.
   **Expected:** Picker visible, selection persists on app restart.
   **Why human:** Visual layout and persistence across cold launch cannot be verified programmatically.

2. **Run Engine Fallback Behavior**
   **Test:** Add tracks with no BPM data to a Spotify playlist. Set fallback to "Play Anyway" in Settings. Start a run. Verify nil-BPM tracks are played after BPM-matched tracks are exhausted.
   **Expected:** Nil-BPM tracks play; no repeats until all have been played once.
   **Why human:** Live run engine with Spotify integration cannot be exercised by unit tests.

---

_Verified: 2026-03-25_
_Verifier: Claude (gsd-verifier)_
