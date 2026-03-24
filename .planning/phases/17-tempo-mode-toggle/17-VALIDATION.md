---
phase: 17
slug: tempo-mode-toggle
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-24
---

# Phase 17 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | XCTest (built-in) |
| **Config file** | BeatStep.xcodeproj |
| **Quick run command** | `xcodebuild test -project BeatStep.xcodeproj -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BeatStepTests/TempoModeToggleTests 2>&1 \| tail -20` |
| **Full suite command** | `xcodebuild test -project BeatStep.xcodeproj -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 \| tail -30` |
| **Estimated runtime** | ~15 seconds |

---

## Sampling Rate

- **After every task commit:** Run quick test command
- **After every plan wave:** Run full suite command
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 15 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 17-01-01 | 01 | 1 | PLR-04 | unit | `xcodebuild test ...TempoModeToggleTests` | ❌ W0 | ⬜ pending |
| 17-01-02 | 01 | 1 | PLR-04 | human | Manual toggle verification | N/A | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

*Existing infrastructure covers all phase requirements. RunEngineServiceTests already covers tempoMode engine behavior. Only a view-level toggle test file is needed, created as part of Task 1.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Toggle button visible and toggles mode | PLR-04 | Runtime UI state, gesture interaction | Tap toggle in simulator, verify label changes between 1:1 and 1:2 |
| Sync display updates after toggle | PLR-04 | Live cadence + track BPM interaction | Toggle mode during active run, verify delta/sync recalculates |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 15s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
