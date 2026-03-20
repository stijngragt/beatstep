---
phase: 3
slug: cadence-detection
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-20
---

# Phase 3 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | XCTest (built-in, iOS 17+) |
| **Config file** | project.yml BeatStepTests target |
| **Quick run command** | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BeatStepTests/CadenceServiceTests` |
| **Full suite command** | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16'` |
| **Estimated runtime** | ~30 seconds |

---

## Sampling Rate

- **After every task commit:** Run `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BeatStepTests/CadenceServiceTests`
- **After every plan wave:** Run `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16'`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 03-01-01 | 01 | 1 | CAD-01 | unit (mocked pedometer) | `xcodebuild test ... -only-testing:BeatStepTests/CadenceServiceTests` | ❌ W0 | ⬜ pending |
| 03-01-02 | 01 | 1 | CAD-02 | unit (pure logic) | `xcodebuild test ... -only-testing:BeatStepTests/CadenceServiceTests/testSmoothing` | ❌ W0 | ⬜ pending |
| 03-01-03 | 01 | 1 | CAD-03 | manual (UI) | Manual: launch app, start run, verify display | N/A | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `BeatStepTests/CadenceServiceTests.swift` — stubs for CAD-01, CAD-02 (smoothing logic, state transitions, trend detection)
- [ ] `BeatStepTests/Mocks/MockCMPedometer.swift` — mock pedometer data for unit testing without device motion

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| RunView displays SPM with trend arrows and states | CAD-03 | SwiftUI view rendering requires visual inspection on device/simulator | 1. Launch app, 2. Navigate to run screen, 3. Start run, 4. Verify SPM number displays, 5. Verify trend arrows update, 6. Verify "Detecting..." settling state, 7. Verify "Paused" state when stopped |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
