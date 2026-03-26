---
phase: 30
slug: skip-queue
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-26
---

# Phase 30 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | XCTest (built-in) |
| **Config file** | BeatStepTests target in Xcode project |
| **Quick run command** | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BeatStepTests/RunEngineServiceTests` |
| **Full suite command** | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16'` |
| **Estimated runtime** | ~30 seconds |

---

## Sampling Rate

- **After every task commit:** Run `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BeatStepTests/RunEngineServiceTests`
- **After every plan wave:** Run `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16'`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 30-01-01 | 01 | 1 | RUN-03a | unit | `...RunEngineServiceTests/testBufferFillsOnStart` | ❌ W0 | ⬜ pending |
| 30-01-02 | 01 | 1 | RUN-03b | unit | `...RunEngineServiceTests/testSkipPopsFromBuffer` | ❌ W0 | ⬜ pending |
| 30-01-03 | 01 | 1 | RUN-03c | unit | `...RunEngineServiceTests/testBufferRefillsAfterPop` | ❌ W0 | ⬜ pending |
| 30-01-04 | 01 | 1 | RUN-03d | unit | `...RunEngineServiceTests/testSkipCooldown` | ❌ W0 | ⬜ pending |
| 30-01-05 | 01 | 1 | RUN-03e | unit | `...RunEngineServiceTests/testBufferInvalidatedOnCadenceChange` | ❌ W0 | ⬜ pending |
| 30-01-06 | 01 | 1 | RUN-03f | unit | `...RunEngineServiceTests/testBufferInvalidatedOnTempoToggle` | ❌ W0 | ⬜ pending |
| 30-01-07 | 01 | 1 | RUN-03g | unit | `...RunEngineServiceTests/testRapidSkipBlocksWhenEmpty` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `BeatStepTests/RunEngineServiceTests.swift` — 7 new buffer-related test cases (see map above)
- [ ] Testing helpers: `fillBufferForTesting()`, `getBufferForTesting()`, `setLastSkipTimeForTesting()`

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Skip feels instant (~100ms) | RUN-03 | Perceptual latency requires real device + Spotify playback | Start run, play song, tap skip, confirm next song starts without visible spinner or pause |
| Rapid multi-skip works reliably | RUN-03 | End-to-end with real Spotify API needed | During run, tap skip 3x rapidly (1s intervals), confirm each skip transitions cleanly |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
