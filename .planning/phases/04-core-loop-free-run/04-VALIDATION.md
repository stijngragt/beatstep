---
phase: 4
slug: core-loop-free-run
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-20
---

# Phase 4 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | XCTest (Xcode 16+) |
| **Config file** | BeatStepTests target in project.yml |
| **Quick run command** | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BeatStepTests` |
| **Full suite command** | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16'` |
| **Estimated runtime** | ~30 seconds |

---

## Sampling Rate

- **After every task commit:** Run `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BeatStepTests`
- **After every plan wave:** Run `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16'`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 04-01-01 | 01 | 0 | BPM-02, BPM-03, RUN-01 | unit | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BeatStepTests/RunEngineServiceTests` | No - W0 | pending |
| 04-01-02 | 01 | 0 | BPM-04 | unit | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BeatStepTests/BPMToleranceTests` | No - W0 | pending |
| 04-XX-XX | TBD | TBD | BPM-02 | unit | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BeatStepTests/RunEngineServiceTests/testMatchingTracksReturnsCorrectBPMRange` | No - W0 | pending |
| 04-XX-XX | TBD | TBD | BPM-03 | unit | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BeatStepTests/RunEngineServiceTests/testHalfDoubleMatching` | No - W0 | pending |
| 04-XX-XX | TBD | TBD | BPM-04 | unit | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BeatStepTests/BPMToleranceTests` | No - W0 | pending |
| 04-XX-XX | TBD | TBD | RUN-01 | unit | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BeatStepTests/RunEngineServiceTests/testSustainedChangeDetection` | No - W0 | pending |
| 04-XX-XX | TBD | TBD | BPM-02 | unit | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BeatStepTests/RunEngineServiceTests/testFallbackToClosestBPM` | No - W0 | pending |
| 04-XX-XX | TBD | TBD | BPM-02 | unit | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BeatStepTests/RunEngineServiceTests/testNoRepeatPoolExhaustion` | No - W0 | pending |

*Status: pending / green / red / flaky*

---

## Wave 0 Requirements

- [ ] `BeatStepTests/RunEngineServiceTests.swift` -- stubs for BPM-02, BPM-03, RUN-01 (matching logic, sustained change, pool management)
- [ ] `BeatStepTests/BPMToleranceTests.swift` -- stubs for BPM-04 (enum values, persistence)
- No new framework installs needed -- XCTest already configured

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Song transitions feel natural during cadence changes | RUN-01 | Subjective UX quality | Start a run, change pace gradually, verify no jarring immediate switches |
| Auto-play on run start plays matching song | BPM-02 | Requires real Spotify session + device motion | Start run with playlist selected, verify first song BPM matches cadence |
| Skip button queues next BPM-matched song | BPM-02 | Requires real Spotify session | During run, tap skip, verify next song is BPM-matched |
| Tolerance persists between runs | BPM-04 | Requires app restart + UserDefaults | Set tolerance to Tight, kill app, relaunch, verify Tight is still selected |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
