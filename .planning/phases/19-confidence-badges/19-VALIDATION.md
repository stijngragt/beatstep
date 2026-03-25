---
phase: 19
slug: confidence-badges
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-25
---

# Phase 19 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | XCTest (iOS 17+) |
| **Config file** | BeatStepTests target in Xcode project |
| **Quick run command** | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BeatStepTests/BPMConfidenceBadgeTests 2>&1 \| tail -20` |
| **Full suite command** | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 \| tail -40` |
| **Estimated runtime** | ~15 seconds |

---

## Sampling Rate

- **After every task commit:** Run quick command (BPMConfidenceBadgeTests)
- **After every plan wave:** Run full suite command
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 15 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 19-01-01 | 01 | 1 | CONF-03 | unit | `xcodebuild test -only-testing:BeatStepTests/BPMConfidenceBadgeTests/testVerifiedIconName` | ❌ W0 | ⬜ pending |
| 19-01-02 | 01 | 1 | CONF-03 | unit | `xcodebuild test -only-testing:BeatStepTests/BPMConfidenceBadgeTests/testManualIconName` | ❌ W0 | ⬜ pending |
| 19-01-03 | 01 | 1 | CONF-03 | unit | `xcodebuild test -only-testing:BeatStepTests/BPMConfidenceBadgeTests/testApproximateIconName` | ❌ W0 | ⬜ pending |
| 19-01-04 | 01 | 1 | CONF-03 | unit | `xcodebuild test -only-testing:BeatStepTests/BPMConfidenceBadgeTests/testVerifiedColor` | ❌ W0 | ⬜ pending |
| 19-01-05 | 01 | 1 | CONF-03 | unit | `xcodebuild test -only-testing:BeatStepTests/BPMConfidenceBadgeTests/testManualColor` | ❌ W0 | ⬜ pending |
| 19-01-06 | 01 | 1 | CONF-03 | unit | `xcodebuild test -only-testing:BeatStepTests/BPMConfidenceBadgeTests/testApproximateColor` | ❌ W0 | ⬜ pending |
| 19-01-07 | 01 | 1 | CONF-03 | unit | `xcodebuild test -only-testing:BeatStepTests/BPMConfidenceBadgeTests/testGetBPMInfoReturnsConfidence` | ❌ W0 | ⬜ pending |
| 19-01-08 | 01 | 1 | CONF-03 | unit | `xcodebuild test -only-testing:BeatStepTests/BPMConfidenceBadgeTests/testGetBPMInfoEmptyForUnknown` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `BeatStepTests/BPMConfidenceBadgeTests.swift` — stubs for CONF-03 (icon/color mapping + service method)
- [ ] `BeatStep/Models/BPMInfo.swift` — new value struct (production code needed before tests compile)

*Existing infrastructure (XCTest, SwiftData test helpers) covers framework needs.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Visual badge rendering | CONF-03 | SwiftUI view appearance cannot be unit tested | Run app, open playlist detail, verify checkmark/hand/tilde icons render correctly with correct colors |
| No-BPM muted capsule | CONF-03 | Visual styling verification | Run app, confirm tracks without BPM show gray capsule with "-- BPM" |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 15s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
