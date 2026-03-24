---
phase: 15
slug: run-player-view
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-24
---

# Phase 15 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | XCTest (project standard) |
| **Config file** | BeatStepTests target in Xcode project |
| **Quick run command** | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BeatStepTests/RunPlayerViewTests` |
| **Full suite command** | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16'` |
| **Estimated runtime** | ~30 seconds |

---

## Sampling Rate

- **After every task commit:** Run `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BeatStepTests/RunPlayerViewTests`
- **After every plan wave:** Run `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16'`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 15-01-01 | 01 | 1 | PLR-01 | unit | `xcodebuild test ... -only-testing:BeatStepTests/RunPlayerViewTests/testAlbumArtURLPrefers300px` | ❌ W0 | ⬜ pending |
| 15-01-02 | 01 | 1 | PLR-01 | unit | `xcodebuild test ... -only-testing:BeatStepTests/RunPlayerViewTests/testAlbumArtURLNilWhenNoImages` | ❌ W0 | ⬜ pending |
| 15-01-03 | 01 | 1 | PLR-02 | unit | `xcodebuild test ... -only-testing:BeatStepTests/RunPlayerViewTests/testTrackBPMLookup` | ❌ W0 | ⬜ pending |
| 15-01-04 | 01 | 1 | PLR-03 | unit | `xcodebuild test ... -only-testing:BeatStepTests/RunPlayerViewTests/testTouchTargetMinimumSize` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `BeatStepTests/RunPlayerViewTests.swift` — stubs for PLR-01 (image URL selection), PLR-02 (BPM display data), PLR-03 (touch target sizing)

*Existing infrastructure covers test framework and configuration.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Album art renders at 80pt visually | PLR-01 | Visual rendering requires simulator | Run app, play track, verify album art appears at correct size |
| Touch targets feel responsive while running | PLR-03 | Ergonomic UX during physical activity | Use simulator with touch, verify buttons respond reliably |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
