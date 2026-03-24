---
phase: 13
slug: engine-extensions-design-tokens
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-24
---

# Phase 13 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | XCTest (Xcode 16+) |
| **Config file** | BeatStepTests target in Xcode project |
| **Quick run command** | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BeatStepTests/RunEngineServiceTests -only-testing:BeatStepTests/SyncQualityTests -only-testing:BeatStepTests/DesignTokenTests` |
| **Full suite command** | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16'` |
| **Estimated runtime** | ~30 seconds |

---

## Sampling Rate

- **After every task commit:** Run quick run command (RunEngineServiceTests + SyncQualityTests + DesignTokenTests)
- **After every plan wave:** Run full suite
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 13-01-01 | 01 | 1 | PLR-04 | unit | `xcodebuild test ... -only-testing:BeatStepTests/RunEngineServiceTests` | Partially | ⬜ pending |
| 13-01-02 | 01 | 1 | CAD-01 | unit | `xcodebuild test ... -only-testing:BeatStepTests/SyncQualityTests` | ❌ W0 | ⬜ pending |
| 13-01-03 | 01 | 1 | CAD-02 | unit | `xcodebuild test ... -only-testing:BeatStepTests/RunEngineServiceTests` | Partially | ⬜ pending |
| 13-02-01 | 02 | 1 | CAD-01 | unit | `xcodebuild test ... -only-testing:BeatStepTests/DesignTokenTests` | Partially | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `BeatStepTests/SyncQualityTests.swift` — stubs for CAD-01 threshold logic
- [ ] New test cases in `BeatStepTests/RunEngineServiceTests.swift` — stubs for PLR-04 (tempoMode ranking), CAD-02 (cadenceDelta)
- [ ] New test cases in `BeatStepTests/DesignTokenTests.swift` — stubs for CAD-01 (sync color tokens exist)

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| tempoMode persists across app relaunch | PLR-04 | UserDefaults persistence needs real device/simulator | 1. Set tempoMode to .half 2. Kill app 3. Relaunch 4. Verify tempoMode is .half |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
