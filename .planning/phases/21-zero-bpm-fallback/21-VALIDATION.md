---
phase: 21
slug: zero-bpm-fallback
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-25
---

# Phase 21 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | XCTest (Xcode built-in) |
| **Config file** | BeatStepTests target in Xcode project |
| **Quick run command** | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BeatStepTests/RunEngineServiceTests -quiet` |
| **Full suite command** | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' -quiet` |
| **Estimated runtime** | ~30 seconds |

---

## Sampling Rate

- **After every task commit:** Run `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BeatStepTests/RunEngineServiceTests -quiet`
- **After every plan wave:** Run `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' -quiet`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 21-01-01 | 01 | 1 | FALL-01 | unit | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BeatStepTests/ZeroBPMFallbackTests -quiet` | ❌ W0 | ⬜ pending |
| 21-01-02 | 01 | 1 | FALL-01 | manual | Manual verification (UI) | N/A | ⬜ pending |
| 21-02-01 | 02 | 1 | FALL-02 | unit | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BeatStepTests/RunEngineServiceTests -quiet` | ❌ W0 | ⬜ pending |
| 21-02-02 | 02 | 1 | FALL-02 | unit | Same as above | ❌ W0 | ⬜ pending |
| 21-02-03 | 02 | 1 | FALL-02 | unit | Same as above | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `BeatStepTests/ZeroBPMFallbackTests.swift` — stubs for FALL-01 enum + persistence
- [ ] New tests in `BeatStepTests/RunEngineServiceTests.swift` — stubs for FALL-02 engine behavior per fallback mode

*Existing RunEngineServiceTests infrastructure covers test helpers and mock setup.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Settings view shows fallback picker with 3 options | FALL-01 | SwiftUI view layout verification | Open Settings > verify "Playback" section with "No-BPM Tracks" picker showing Skip/Play Anyway/Ask Me |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
