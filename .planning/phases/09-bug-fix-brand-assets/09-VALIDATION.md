---
phase: 9
slug: bug-fix-brand-assets
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-24
---

# Phase 9 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | XCTest (built-in) |
| **Config file** | BeatStep.xcodeproj (test target: BeatStepTests) |
| **Quick run command** | `xcodebuild test -project BeatStep.xcodeproj -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BeatStepTests 2>&1 \| tail -20` |
| **Full suite command** | `xcodebuild test -project BeatStep.xcodeproj -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 \| tail -40` |
| **Estimated runtime** | ~30 seconds |

---

## Sampling Rate

- **After every task commit:** Run quick run command targeting changed test files
- **After every plan wave:** Run full suite command
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 09-01-01 | 01 | 1 | BUG-01 | unit | `xcodebuild test ... -only-testing:BeatStepTests/TrackCountTests` | ❌ W0 | ⬜ pending |
| 09-02-01 | 02 | 1 | BRAND-01 | unit | `xcodebuild test ... -only-testing:BeatStepTests/AppIconTests` | ❌ W0 | ⬜ pending |
| 09-02-02 | 02 | 1 | BRAND-02 | manual-only | N/A — visual verification | N/A | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `BeatStepTests/TrackCountTests.swift` — stubs for BUG-01: test SpotifyPlaylist.trackCount returns nil when tracks is nil, returns 0 when TracksRef(total: 0)
- [ ] `BeatStepTests/AppIconTests.swift` — stubs for BRAND-01: test icon PNG exists in asset catalog

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Wordmark renders correctly on login screen | BRAND-02 | Visual styling verification — SF Pro Bold, all caps, wide tracking, white on dark | Launch app → verify login screen shows "BEATSTEP" wordmark |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
