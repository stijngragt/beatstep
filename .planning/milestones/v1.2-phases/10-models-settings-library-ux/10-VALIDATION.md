---
phase: 10
slug: models-settings-library-ux
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-24
---

# Phase 10 — Validation Strategy

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

- **After every task commit:** Run `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BeatStepTests`
- **After every plan wave:** Run `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16'`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 10-01-01 | 01 | 1 | RUN-03 | unit | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BeatStepTests/BPMToleranceTests` | ✅ update | ⬜ pending |
| 10-01-02 | 01 | 1 | RUN-04 | unit | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BeatStepTests/RunZoneTests` | ❌ W0 | ⬜ pending |
| 10-02-01 | 02 | 2 | LIB-01 | unit | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BeatStepTests/ScannedPlaylistTests` | ❌ W0 | ⬜ pending |
| 10-02-02 | 02 | 2 | LIB-02 | unit | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BeatStepTests/LibraryScanServiceTests` | ✅ add test | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `BeatStepTests/RunZoneTests.swift` — stubs for RUN-04 (defaults, persistence, reset, range validation)
- [ ] `BeatStepTests/BPMToleranceTests.swift` — update displayName assertions for RUN-03
- [ ] `BeatStepTests/LibraryScanServiceTests.swift` — add scanPlaylistByID test for LIB-02

*Existing infrastructure covers framework setup. Only test file additions needed.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Playlist row shows fraction text with correct color | LIB-01 | SwiftUI visual styling not testable via XCTest | Open Library tab, verify "42/60 BPM" in accent red, "Not analyzed" in warning color |
| Swipe-to-analyze shows spinner with progress | LIB-02 | Animation/UI state requires device interaction | Swipe playlist row left, tap Analyze, verify spinner shows "Analyzing 12/35" |
| Zone settings Stepper tap-to-reveal | RUN-04 | Interactive disclosure pattern | Open Settings, tap zone row, verify Stepper appears, adjust value |
| Tolerance picker shows +-N BPM segments | RUN-03 | Visual label verification | Open Run tab, verify segmented control shows "+-3 BPM", "+-7 BPM", "+-12 BPM" |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
