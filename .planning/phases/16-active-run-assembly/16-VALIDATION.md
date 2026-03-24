---
phase: 16
slug: active-run-assembly
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-24
---

# Phase 16 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | XCTest (Xcode 16) |
| **Config file** | BeatStepTests target in Xcode project |
| **Quick run command** | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BeatStepTests -quiet` |
| **Full suite command** | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' -quiet` |
| **Estimated runtime** | ~30 seconds |

---

## Sampling Rate

- **After every task commit:** Run quick run command for changed test files
- **After every plan wave:** Run full suite command
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 16-01-01 | 01 | 1 | RUN-01 | unit | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BeatStepTests/ActiveRunViewTests -quiet` | ❌ W0 | ⬜ pending |
| 16-01-02 | 01 | 1 | RUN-02 | unit | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BeatStepTests/LongPressStopTests -quiet` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `BeatStepTests/ActiveRunViewTests.swift` — stubs for RUN-01 (wiring verification: syncQuality, cadenceDelta, isGuidedMode from engine)
- [ ] `BeatStepTests/LongPressStopTests.swift` — stubs for RUN-02 (progress calculation: 0s=0%, 1s=50%, 2s=100%)

*Existing infrastructure covers test framework — only test files needed.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| fullScreenCover prevents swipe dismiss | RUN-01 | Gesture interaction requires simulator/device | Present ActiveRunView, attempt swipe-down — should not dismiss |
| Tab bar hidden during run | RUN-01 | Visual verification | Start run, verify tab bar not visible |
| MiniPlayer hides during active run | RUN-01 | Visual verification | Start run with track playing, verify MiniPlayer not visible |
| Long-press visual progress ring | RUN-02 | Animation verification | Press and hold stop button, verify ring fills over 2 seconds |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
