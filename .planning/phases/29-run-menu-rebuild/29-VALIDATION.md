---
phase: 29
slug: run-menu-rebuild
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-26
---

# Phase 29 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | XCTest (built-in) |
| **Config file** | BeatStepTests target in Xcode project |
| **Quick run command** | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BeatStepTests/ZoneSelectionTests` |
| **Full suite command** | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16'` |
| **Estimated runtime** | ~30 seconds |

---

## Sampling Rate

- **After every task commit:** Run `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BeatStepTests/ZoneSelectionTests`
- **After every plan wave:** Run `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16'`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 29-01-01 | 01 | 1 | RUN-02 | unit | `xcodebuild test ... -only-testing:BeatStepTests/ZoneSelectionTests` | ✅ (needs new cases) | ⬜ pending |
| 29-01-02 | 01 | 1 | RUN-02 | unit | `xcodebuild test ... -only-testing:BeatStepTests/RunZoneTests` | ✅ (needs new cases) | ⬜ pending |
| 29-02-01 | 02 | 1 | RUN-01 | manual-only | Visual inspection | N/A | ⬜ pending |
| 29-02-02 | 02 | 1 | RUN-01 | manual-only | Haptic inspection on device | N/A | ⬜ pending |
| 29-03-01 | 03 | 2 | RUN-02 | unit | `xcodebuild test ... -only-testing:BeatStepTests/RunEngineServiceTests` | ✅ (needs new cases) | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] New test cases in `ZoneSelectionTests.swift` for multi-zone persistence (Set<Int> round-trip, empty set = free mode, migration from single Int?)
- [ ] New test cases in `RunZoneTests.swift` for `mergedBPMRange(for:)` computation
- [ ] New test cases in `RunEngineServiceTests.swift` for midpoint BPM with multi-zone

*Existing infrastructure covers framework needs — only new test cases required.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Zone picker is custom component (not stock Picker) | RUN-01 | Visual appearance | Open Run tab, verify zone capsules render as custom styled buttons |
| Tolerance selector is custom capsule | RUN-01 | Visual appearance | Verify tolerance shows 3 capsules, not segmented Picker |
| Haptic on zone/tolerance selection | RUN-01 | Requires physical device | Tap zone capsules and tolerance options on device, confirm haptic feedback |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
