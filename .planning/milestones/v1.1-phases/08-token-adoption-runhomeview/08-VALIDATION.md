---
phase: 8
slug: token-adoption-runhomeview
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-23
---

# Phase 8 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | XCTest (Xcode built-in) |
| **Config file** | BeatStepTests/ directory |
| **Quick run command** | `grep -rn 'Color\.black\|Color\.green\|Color\.orange\|Color\.red\|Color\.gray\|\.green\b\|\.orange\b\|\.red\b\|\.gray\b' --include='*.swift' BeatStep/Views/ \| grep -v '//' ; test $? -eq 1` |
| **Full suite command** | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 \| tail -20` |
| **Estimated runtime** | ~30 seconds (grep instant, full suite ~30s) |

---

## Sampling Rate

- **After every task commit:** Run grep verification for DS-04 (instant)
- **After every plan wave:** Run full test suite
- **Before `/gsd:verify-work`:** Full suite must be green + all grep checks pass
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 08-01-XX | 01 | 1 | DS-04 | smoke (grep) | `grep -rn 'Color\.black\|Color\.green\|Color\.orange\|Color\.red\|Color\.gray' --include='*.swift' BeatStep/Views/ \| grep -v '//'; test $? -eq 1` | N/A (shell) | ⬜ pending |
| 08-01-XX | 01 | 1 | DS-04 | smoke (grep) | `grep -rn '\.secondary\|\.primary' --include='*.swift' BeatStep/Views/ \| grep -v '//'; test $? -eq 1` | N/A (shell) | ⬜ pending |
| 08-01-XX | 01 | 1 | DS-04 | smoke (grep) | `grep -rn 'spotifyGreen' --include='*.swift' BeatStep/; test $? -eq 1` | N/A (shell) | ⬜ pending |
| 08-02-XX | 02 | 2 | NAV-04 | unit | `xcodebuild test -only-testing:BeatStepTests/LastRunPlaylistTests` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `BeatStepTests/LastRunPlaylistTests.swift` — stubs for NAV-04 persistence round-trip
- [ ] If `displaySPM` token added, update `DesignTokenTests.swift` to cover it

*Existing grep-based infrastructure covers DS-04 requirements.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| RunTabView shows playlist name + artwork when last-used exists | NAV-04 | Visual layout verification | 1. Run app, select playlist, start run, stop. 2. Navigate to Run tab. 3. Verify playlist name and artwork visible. |
| RunTabView shows prompt when no previous run | NAV-04 | Visual layout verification | 1. Clear UserDefaults. 2. Launch app, navigate to Run tab. 3. Verify "select a playlist" prompt shown. |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
