---
phase: 16-active-run-assembly
verified: 2026-03-24T22:45:00Z
status: human_needed
score: 9/9 must-haves verified
human_verification:
  - test: "Verify complete active run flow end-to-end in simulator or on device"
    expected: "fullScreenCover appears when cadence is detected, tab bar hidden, MiniPlayer hidden, swipe down does not dismiss, long-press stop fills progress ring over 2 seconds, releasing before 2 seconds resets ring, holding 2 seconds stops run and returns to RunView, MiniPlayer reappears after run ends"
    why_human: "Runtime behavior: fullScreenCover presentation timing, tab bar visibility, gesture tracking, live cadence data display, and dismissal flow cannot be verified by static analysis alone. The human checkpoint in Plan 02 was recorded as approved, but this is documented in a SUMMARY file rather than a committed test result."
---

# Phase 16: Active Run Assembly Verification Report

**Phase Goal:** The complete run experience works end-to-end — a focused full-screen view composes all components, prevents accidental dismissal, and hides the MiniPlayer
**Verified:** 2026-03-24T22:45:00Z
**Status:** human_needed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | LongPressStopButton progress reaches 1.0 at exactly 2 seconds | VERIFIED | `static func progress(elapsed: TimeInterval, duration: TimeInterval) -> CGFloat` with `min(max(...), 1.0)` clamp; test `testProgressAtFullDurationReturnsOne` covers elapsed==duration==2 |
| 2 | LongPressStopButton progress resets to 0 when released before 2 seconds | VERIFIED | `cancelPress()` calls `pressTimer?.invalidate()` and animates `currentProgress = 0`; DragGesture `.onEnded` wired to `cancelPress()` |
| 3 | ActiveRunView composes RunStatusBar, CadenceDisplayView, ZoneBandView, RampPhaseIndicator, RunPlayerView | VERIFIED | All five sub-components instantiated in `ActiveRunView.body` at lines 36, 51, 60, 43, 75 |
| 4 | ActiveRunView wires live RunEngineService data (syncQuality, cadenceDelta, isGuidedMode) not hardcoded values | VERIFIED | Line 54: `syncQuality: runEngine.syncQuality`; line 55: `cadenceDelta: runEngine.cadenceDelta`; line 56: `isGuidedMode: runEngine.runMode == .guided`; no hardcoded sync constants |
| 5 | ActiveRunView appears as fullScreenCover when cadence becomes active | VERIFIED | RunView.swift line 31: `.fullScreenCover(isPresented: $showActiveRun)`; line 35-39: `.onChange(of: cadenceService.state)` sets `showActiveRun = true` when `newValue == .active && oldValue != .active` |
| 6 | User cannot swipe to dismiss ActiveRunView | VERIFIED | RunView.swift line 33: `.interactiveDismissDisabled(true)` applied inside the fullScreenCover |
| 7 | MiniPlayer is hidden when active run is showing | VERIFIED | ContentView.swift line 67: `SpotifyPlayerService.shared.currentTrack != nil && !RunEngineService.shared.isRunActive` guards MiniPlayer |
| 8 | RunView onDisappear does not kill the run when fullScreenCover presents | VERIFIED | RunView.swift line 40-46: `.onDisappear` guarded with `if !runEngine.isRunActive` |
| 9 | Run stops cleanly when long-press completes and fullScreenCover dismisses | VERIFIED | ActiveRunView `stopRun()` at lines 110-115 calls `runEngine.stopRun()`, `cadenceService.stopDetecting()`, disables idle timer, then `dismiss()` |

**Score:** 9/9 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `BeatStep/Views/Run/LongPressStopButton.swift` | Long-press stop button with 2-second progress ring | VERIFIED | 89 lines; static `progress()` function; Timer-based 1/60 interval; DragGesture; 56x56pt frame; progress ring with `.stateError` color; `.surfaceOverlay` background; `stop.fill` icon |
| `BeatStep/Views/Run/ActiveRunView.swift` | Full-screen composition of all run sub-components | VERIFIED | 131 lines; three-zone VStack; all 5 sub-components composed; live service data; `stopRun()` cleanup; no navigation bar |
| `BeatStepTests/LongPressStopTests.swift` | Progress calculation tests | VERIFIED | 32 lines; 5 tests covering elapsed=0, elapsed=1, elapsed=2, elapsed=3 (clamp), elapsed=-1 (clamp) |
| `BeatStepTests/ActiveRunViewTests.swift` | Wiring verification tests | VERIFIED | 38 lines; 2 build-verification tests for nil zone (free mode) and zone-id (guided mode) instantiation |
| `BeatStep/Views/Run/RunView.swift` | fullScreenCover trigger for ActiveRunView | VERIFIED | `fullScreenCover` at line 31; `onChange` trigger at line 35; `showActiveRun` @State at line 12; `onDisappear` guard at line 40 |
| `BeatStep/App/ContentView.swift` | MiniPlayer hiding during active run | VERIFIED | Line 67: `!RunEngineService.shared.isRunActive` condition added to MiniPlayer safeAreaInset |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `RunView.swift` | `ActiveRunView.swift` | `.fullScreenCover` presentation | WIRED | Pattern `\.fullScreenCover.*ActiveRunView` confirmed at lines 31-34; `ActiveRunView(playlist: playlist, tracks: tracks, selectedZoneId: selectedZoneId)` |
| `ContentView.swift` | `RunEngineService.shared.isRunActive` | MiniPlayer visibility condition | WIRED | Pattern `!RunEngineService\.shared\.isRunActive` confirmed at line 67 |
| `ActiveRunView.swift` | `RunEngineService.shared` | direct property access | WIRED | `runEngine.syncQuality`, `runEngine.cadenceDelta`, `runEngine.runMode`, `runEngine.rampPhase`, `runEngine.effectiveBPM`, `runEngine.tolerance`, `runEngine.adjustedCadence`, `runEngine.currentMatchedTrack`, `runEngine.currentTrackBPM` all accessed |
| `ActiveRunView.swift` | `CadenceService.shared` | direct property access | WIRED | `cadenceService.currentSPM`, `cadenceService.trend` both accessed at lines 52-53 |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|-------------|--------|---------|
| RUN-01 | 16-01, 16-02 | User sees a full-screen active run view (three-zone layout: status bar, hero cadence, player area) presented via fullScreenCover when cadence is detected | SATISFIED | ActiveRunView three-zone VStack confirmed; fullScreenCover wired in RunView; onChange trigger on cadence .active state |
| RUN-02 | 16-01, 16-02 | User can stop a run only via long-press (2-second hold with visual progress ring), preventing accidental mid-run stops | SATISFIED | LongPressStopButton is the sole explicit stop path in ActiveRunView; `interactiveDismissDisabled(true)` prevents swipe dismiss; note — RunView's own `stopRunButton` exists but is inaccessible while fullScreenCover is presented |

**Orphaned requirements check:** RUN-03 is mapped to Phase 14, not Phase 16 — no orphan.

### Commit Verification

All three task commits verified in git history:
- `25e06e0` — feat(16-01): add LongPressStopButton
- `1482a4c` — feat(16-01): add ActiveRunView
- `efffac6` — feat(16-02): wire fullScreenCover and guard lifecycle

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `RunView.swift` | 141-143 | `CadenceDisplayView` in `activeView` uses hardcoded `syncQuality: .inSync`, `cadenceDelta: 0`, `isGuidedMode: false` | Warning | This code is a pre-existing placeholder in the RunView `activeView` branch. It is never visible to the user during an active run because `fullScreenCover` immediately covers RunView when cadence transitions to `.active`. The plan explicitly acknowledges this one-frame transition is acceptable. Not a blocker. |

### Human Verification Required

#### 1. End-to-end active run flow

**Test:** Open BeatStep in simulator or on device. Select a playlist, tap Start Run, allow cadence to be detected (walk/run to trigger the `.active` state).

**Expected:**
1. ActiveRunView appears as a full-screen modal (fullScreenCover) once cadence is active
2. Tab bar is NOT visible during the active run
3. MiniPlayer is NOT visible during the active run
4. Swiping down on the view does NOT dismiss it
5. Live SPM and sync coloring change as cadence changes (not always "In Sync")
6. In guided mode: zone band, ramp phase indicator, and Cool Down button are visible
7. Press and hold the stop button — progress ring fills over approximately 2 seconds
8. Release before 2 seconds — ring resets smoothly with easeOut animation
9. Hold for full 2 seconds — run stops and returns to RunView
10. MiniPlayer reappears after run ends (if a track was playing)

**Why human:** Runtime behavior including fullScreenCover presentation timing, tab bar and MiniPlayer visibility, gesture tracking, live sync coloring, and dismissal flow cannot be verified by static analysis. The Plan 02 SUMMARY records a human checkpoint as "approved" but this approval is documented only in the summary file.

### Gaps Summary

No gaps found. All 9 observable truths pass all three verification levels (exists, substantive, wired). All required artifacts are present, non-stub, and connected. Both requirement IDs are satisfied. All three task commits are confirmed in git history. The sole human verification item is an end-to-end runtime flow check — the automated evidence is complete.

---

_Verified: 2026-03-24T22:45:00Z_
_Verifier: Claude (gsd-verifier)_
