---
phase: 6
slug: design-system-foundation
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-23
---

# Phase 6 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | XCTest (built-in, existing in project) |
| **Config file** | BeatStepTests target in Xcode project |
| **Quick run command** | `xcodebuild build -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 \| tail -5` |
| **Full suite command** | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 \| tail -40` |
| **Estimated runtime** | ~30 seconds (build check), ~60 seconds (full suite) |

---

## Sampling Rate

- **After every task commit:** Run `xcodebuild build -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | tail -5`
- **After every plan wave:** Run full test suite
- **Before `/gsd:verify-work`:** Full suite must be green + grep checks + user approval
- **Max feedback latency:** 60 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 06-01-01 | 01 | 1 | DARK-01 | build | Verify Info.plist contains UIUserInterfaceStyle = Dark | N/A (plist) | ⬜ pending |
| 06-01-02 | 01 | 1 | DARK-01 | manual-only | Test on light-mode device: alerts, sheets appear dark | N/A | ⬜ pending |
| 06-01-03 | 01 | 1 | DARK-02 | grep | `grep -r "preferredColorScheme" BeatStep/ \| grep -v AppEntry` returns empty | N/A | ⬜ pending |
| 06-02-01 | 02 | 1 | DS-01 | unit | `xcodebuild build -scheme BeatStep` succeeds | Wave 0 | ⬜ pending |
| 06-02-02 | 02 | 1 | DS-02 | unit | `xcodebuild build -scheme BeatStep` succeeds | Wave 0 | ⬜ pending |
| 06-02-03 | 02 | 1 | DS-03 | unit | `xcodebuild build -scheme BeatStep` succeeds | Wave 0 | ⬜ pending |
| 06-02-04 | 02 | 1 | DS-05 | manual-only | Present token summary for user review | N/A | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `BeatStepTests/DesignTokenTests.swift` — stubs for DS-01, DS-02, DS-03: verify token values compile, accent matches expected hex, background levels are distinct and ordered dark-to-light
- [ ] Verification script: grep for `preferredColorScheme` in source files returns zero hits outside acceptable locations

*Existing infrastructure covers XCTest framework — no new framework install needed.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| No white flashes on launch, alerts, sheets, or Spotify OAuth | DARK-01 | Requires physical/simulator observation with device in light mode | Set device to light mode → launch app → trigger alert → open sheet → test OAuth flow → verify all dark |
| User approval of token definitions | DS-05 | Human judgment required | Present token summary (colors, typography, spacing) → user reviews and approves |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 60s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
