---
phase: 27
slug: foundation-fixes
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-25
---

# Phase 27 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | XCTest (bundled with Xcode) |
| **Config file** | BeatStepTests target in Xcode project |
| **Quick run command** | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BeatStepTests 2>&1 \| tail -20` |
| **Full suite command** | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 \| tail -40` |
| **Estimated runtime** | ~30 seconds |

---

## Sampling Rate

- **After every task commit:** Run `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BeatStepTests 2>&1 | tail -20`
- **After every plan wave:** Run `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | tail -40`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 27-01-01 | 01 | 1 | POL-01 | unit | `xcodebuild test ... -only-testing:BeatStepTests/DesignTokenTests` | Exists (extend) | pending |
| 27-01-02 | 01 | 1 | POL-01 | unit | `xcodebuild test ... -only-testing:BeatStepTests/DesignTokenTests` | Exists (extend) | pending |
| 27-02-01 | 02 | 1 | INF-01 | unit | `xcodebuild test ... -only-testing:BeatStepTests/SpotifyAPIServiceTests` | Exists (fix) | pending |
| 27-02-02 | 02 | 1 | INF-01 | unit | `xcodebuild test ... -only-testing:BeatStepTests/SpotifyAPIServiceTests` | Exists (extend) | pending |
| 27-02-03 | 02 | 1 | INF-01 | unit | `xcodebuild test ... -only-testing:BeatStepTests/SpotifyAPIServiceTests` | Exists (extend) | pending |
| 27-02-04 | 02 | 1 | INF-01 | unit | `xcodebuild test ... -only-testing:BeatStepTests/SpotifyAPIServiceTests` | Wave 0 | pending |
| 27-03-01 | 03 | 2 | LIB-05 | manual | Manual test — requires Spotify auth + real playlist scan | N/A | pending |

*Status: pending / green / red / flaky*

---

## Wave 0 Requirements

- [ ] Extend DesignTokenTests with BSHaptics token existence tests
- [ ] Extend DesignTokenTests with BSAnimation token existence tests
- [ ] Fix MockSpotifyResponses to use Feb 2026 JSON format (fix pre-existing failure)
- [ ] Add test for SpotifyUser decoding without `product` field

*Existing infrastructure covers framework needs — extend test files only.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Library view reflects analyzed status after scan | LIB-05 | Requires Spotify auth + real playlist scan in simulator | 1. Open Library tab 2. Swipe playlist > Scan 3. Wait for scan completion 4. Verify analyzed badge updates without manual refresh |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
