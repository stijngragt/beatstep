---
phase: 7
slug: tab-navigation-shell
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-23
---

# Phase 7 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | XCTest (built-in) |
| **Config file** | BeatStepTests target in Xcode project |
| **Quick run command** | `xcodebuild build -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 \| tail -5` |
| **Full suite command** | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 \| tail -40` |
| **Estimated runtime** | ~30 seconds |

---

## Sampling Rate

- **After every task commit:** Run `xcodebuild build -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | tail -5`
- **After every plan wave:** Run `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | tail -40`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 07-01-01 | 01 | 1 | NAV-01 | build | `xcodebuild build ...` | N/A | ⬜ pending |
| 07-01-02 | 01 | 1 | NAV-02 | build | `xcodebuild build ...` | N/A | ⬜ pending |
| 07-01-03 | 01 | 1 | NAV-03 | manual | Visual verification | N/A | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements. No new test files needed — Phase 7 requirements are structural UI changes verified by compilation + manual testing. Existing test suite must remain green (no regressions).

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Three tabs render with correct icons and labels | NAV-01 | SwiftUI TabView rendering is visual-only | Launch simulator, verify tab bar shows Library/Run/Settings with correct SF Symbol icons and accent tint |
| Per-tab navigation state preserved | NAV-02 | Tab switching state preservation requires interactive testing | Navigate deep into Library tab, switch to Run, switch back, verify Library state preserved |
| MiniPlayer visible across all tabs | NAV-03 | safeAreaInset overlay positioning is visual | Play a track, switch between all three tabs, verify MiniPlayer visible and functional on each |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
