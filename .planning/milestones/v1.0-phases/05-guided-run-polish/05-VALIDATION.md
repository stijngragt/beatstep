---
phase: 05
slug: guided-run-polish
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-23
---

# Phase 05 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | XCTest (Swift, built-in) |
| **Config file** | BeatStepTests/ target in Xcode project |
| **Quick run command** | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BeatStepTests` |
| **Full suite command** | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16'` |
| **Estimated runtime** | ~30 seconds |

---

## Sampling Rate

- **After every task commit:** Run quick test command
- **After every plan wave:** Run full suite command
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 05-01-01 | 01 | 1 | RUN-02 | unit | `xcodebuild test` | ❌ W0 | ⬜ pending |
| 05-01-02 | 01 | 1 | RUN-03 | unit | `xcodebuild test` | ❌ W0 | ⬜ pending |
| 05-02-01 | 02 | 2 | BPM-06 | unit | `xcodebuild test` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `BeatStepTests/GuidedRunEngineTests.swift` — stubs for RUN-02, RUN-03
- [ ] `BeatStepTests/SmartSelectionTests.swift` — stubs for BPM-06

*Existing XCTest infrastructure covers framework needs.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Warm-up/cool-down ramp feels smooth during actual run | RUN-03 | Subjective UX quality | Start guided run, observe BPM ramp over 2-3 minutes |
| Music matches target BPM perceptibly | RUN-02 | Requires listening | Set target 160 BPM, verify songs feel on-beat |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
