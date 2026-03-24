---
phase: 14
slug: cadence-display-status-bar
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-24
---

# Phase 14 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | XCTest (Xcode 16+) |
| **Config file** | BeatStepTests target in Xcode project |
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
| 14-01-01 | 01 | 1 | RUN-03 | unit | `xcodebuild test -only-testing:BeatStepTests/CadenceDisplayTests` | ❌ W0 | ⬜ pending |
| 14-01-02 | 01 | 1 | CAD-03 | unit | `xcodebuild test -only-testing:BeatStepTests/CadenceDisplayTests` | ❌ W0 | ⬜ pending |
| 14-01-03 | 01 | 1 | CAD-04 | unit | `xcodebuild test -only-testing:BeatStepTests/CadenceDisplayTests` | ❌ W0 | ⬜ pending |
| 14-01-04 | 01 | 1 | CAD-05 | unit | `xcodebuild test -only-testing:BeatStepTests/CadenceDisplayTests` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `BeatStepTests/CadenceDisplayTests.swift` — stubs for RUN-03, CAD-03, CAD-04, CAD-05 (view logic: position calc, progress calc, color mapping, delta formatting)
- [ ] SyncQuality.color extension test coverage

*Existing infrastructure covers framework setup. Wave 0 adds test stubs for new component logic.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Zone band visual appearance | CAD-03 | Visual rendering not testable in XCTest | Use SwiftUI previews to verify band renders with indicator at correct position |
| Background color shift subtlety | CAD-04 | Opacity perception is subjective | Preview with all 3 SyncQuality states, verify tint is barely perceptible |
| Ramp phase progress bar animation | CAD-05 | Animation smoothness not testable | Preview with varying effectiveBPM values, verify smooth transitions |
| Sync badge color-coded appearance | RUN-03 | Visual color verification | Preview RunStatusBar with each SyncQuality, verify badge colors match design tokens |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
