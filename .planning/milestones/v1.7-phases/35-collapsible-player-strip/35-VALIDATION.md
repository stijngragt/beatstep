---
phase: 35
slug: collapsible-player-strip
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-26
---

# Phase 35 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | XCTest (Xcode built-in) |
| **Config file** | BeatStepTests/ directory |
| **Quick run command** | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BeatStepTests 2>&1 \| tail -20` |
| **Full suite command** | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 \| tail -40` |
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
| 35-01-01 | 01 | 1 | PLAY-02 | unit | `xcodebuild test -only-testing:BeatStepTests/CollapsiblePlayerTests` | ❌ W0 | ⬜ pending |
| 35-01-02 | 01 | 1 | PLAY-03 | unit | `xcodebuild test -only-testing:BeatStepTests/CollapsiblePlayerTests` | ❌ W0 | ⬜ pending |
| 35-01-03 | 01 | 1 | PLAY-04 | manual | N/A — visual + gesture | N/A | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `BeatStepTests/CollapsiblePlayerTests.swift` — stubs for expand progress calculation and threshold logic
- [ ] Existing test infrastructure covers XCTest — no framework install needed

*Existing infrastructure covers framework requirements.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Collapsed handle doesn't obstruct tab bar | PLAY-04 | Visual/interaction — requires simulator tap testing | 1. Collapse player 2. Tap each tab bar item 3. Verify tabs switch correctly |
| Interactive drag follows finger | PLAY-02 | Gesture feedback — requires visual confirmation | 1. Drag player down 2. Verify it follows finger 3. Release before threshold — verify snap back |
| Persistence across restart | PLAY-02 | App lifecycle — requires kill/relaunch | 1. Collapse player 2. Kill app 3. Relaunch 4. Verify player is still collapsed |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
