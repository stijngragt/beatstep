---
phase: 22
slug: sensor-lab
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-25
---

# Phase 22 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | XCTest (project standard) |
| **Config file** | BeatStepTests target in Xcode project |
| **Quick run command** | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BeatStepTests/SensorLabServiceTests` |
| **Full suite command** | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16'` |
| **Estimated runtime** | ~30 seconds |

---

## Sampling Rate

- **After every task commit:** Run `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BeatStepTests/SensorLabServiceTests`
- **After every plan wave:** Run `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16'`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 22-01-01 | 01 | 1 | SLAB-01 | unit | `xcodebuild test ... -only-testing:BeatStepTests/SensorLabServiceTests/testTogglePersistence` | ❌ W0 | ⬜ pending |
| 22-01-02 | 01 | 1 | SLAB-02 | unit | `xcodebuild test ... -only-testing:BeatStepTests/SensorLabServiceTests/testServiceProperties` | ❌ W0 | ⬜ pending |
| 22-01-03 | 01 | 1 | SLAB-03 | unit | `xcodebuild test ... -only-testing:BeatStepTests/SensorLabServiceTests/testIntervalUpdate` | ❌ W0 | ⬜ pending |
| 22-01-04 | 01 | 1 | SLAB-04 | unit | `xcodebuild test ... -only-testing:BeatStepTests/SensorLabServiceTests/testBufferCap` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `BeatStepTests/SensorLabServiceTests.swift` — stubs for SLAB-01 through SLAB-04 service logic
- [ ] Note: Accelerometer hardware tests are manual-only (simulator has no accelerometer). Unit tests cover buffer logic, interval management, and state transitions using mock data.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Live accelerometer data displays correctly | SLAB-02 | Simulator has no accelerometer hardware | Run on physical device, verify X/Y/Z values update in real-time |
| Waveform chart renders smoothly | SLAB-04 | Visual rendering quality cannot be unit tested | Run on device, verify chart scrolls smoothly without frame drops |
| Accelerometer stops on Sensor Lab close | SC-5 | Background state requires device verification | Open Sensor Lab, close it, verify no battery drain indicator |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
