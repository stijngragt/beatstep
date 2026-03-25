---
phase: 20
slug: tap-bpm-input
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-25
---

# Phase 20 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | XCTest (iOS 17+) |
| **Config file** | Xcode project default |
| **Quick run command** | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BeatStepTests/TapBPMEngineTests 2>&1 \| tail -20` |
| **Full suite command** | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 \| tail -40` |
| **Estimated runtime** | ~30 seconds |

---

## Sampling Rate

- **After every task commit:** Run `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BeatStepTests/TapBPMEngineTests 2>&1 | tail -20`
- **After every plan wave:** Run `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | tail -40`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 20-01-01 | 01 | 0 | TAP-01, TAP-02, TAP-03 | unit | `xcodebuild test ... -only-testing:BeatStepTests/TapBPMEngineTests` | ❌ W0 | ⬜ pending |
| 20-01-02 | 01 | 1 | TAP-01 | unit | `xcodebuild test ... -only-testing:BeatStepTests/TapBPMEngineTests` | ❌ W0 | ⬜ pending |
| 20-02-01 | 02 | 1 | TAP-01 | manual | N/A — SwiftUI sheet presentation | N/A | ⬜ pending |
| 20-02-02 | 02 | 1 | TAP-02, TAP-03 | manual | N/A — haptics, animations | N/A | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `BeatStepTests/TapBPMEngineTests.swift` — stubs for TAP-01, TAP-02, TAP-03 (pure logic tests)
- Tests for TapBPMEngine are pure logic (no UI, no SwiftData) so no additional fixtures needed

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Half-sheet presentation from badge tap | TAP-01 | SwiftUI sheet presentation, gesture routing | Tap BPM badge on any track → verify half-sheet opens |
| Haptic feedback on tap/outlier/save | TAP-01 | Physical device haptics | Run on device, tap → feel light impact; tap outlier → feel error buzz; save → feel success |
| Auto-play track on sheet open | TAP-01 | Spotify playback integration | Open tap sheet → verify track starts playing |
| 8-dot progress indicator + stability label | TAP-02 | Visual UI verification | Tap 8 times → verify dots fill, "Stable" appears |
| Shake animation on outlier rejection | TAP-03 | Visual animation | Tap erratically → verify shake animation on tap zone |
| Badge refresh after save | TAP-01 | Integration with playlist view | Save tapped BPM → verify manual badge appears immediately |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
