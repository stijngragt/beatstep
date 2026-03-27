---
phase: 37
slug: beat-sync-badge
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-27
---

# Phase 37 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | XCTest (built-in) |
| **Config file** | BeatStepTests target in Xcode project |
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
| 37-01-01 | 01 | 1 | SYNC-01 | unit | `xcodebuild test -only-testing:BeatStepTests/SyncQualityTests` | ❌ W0 | ⬜ pending |
| 37-01-02 | 01 | 1 | SYNC-02 | unit | `xcodebuild test -only-testing:BeatStepTests/SyncQualityTests` | ❌ W0 | ⬜ pending |
| 37-01-03 | 01 | 1 | SYNC-01 | visual | Manual — inspect SyncBadge in simulator | N/A | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `BeatStepTests/SyncQualityTests.swift` — stubs for SYNC-01, SYNC-02 tempo normalization
- Existing test infrastructure covers framework setup

*If none: "Existing infrastructure covers all phase requirements."*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Badge shows icon + text in capsule | SYNC-01 | Visual layout | Run app, start run with music, verify badge shows SF Symbol icon left of text label |
| Badge updates in real time | SYNC-01 | Requires live cadence | Start run, change pace, verify badge transitions between states |
| Half/double-tempo shows correct match | SYNC-02 | Requires specific track BPM | Play 170 BPM track while running at ~85 SPM, verify badge shows "In Sync" not "Mismatched" |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
