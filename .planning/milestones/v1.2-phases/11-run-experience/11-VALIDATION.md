---
phase: 11
slug: run-experience
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-24
---

# Phase 11 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | XCTest (built-in) |
| **Config file** | Xcode project test target (BeatStepTests) |
| **Quick run command** | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BeatStepTests 2>&1 \| tail -20` |
| **Full suite command** | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 \| tail -40` |
| **Estimated runtime** | ~30 seconds |

---

## Sampling Rate

- **After every task commit:** Run `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BeatStepTests/RunZoneTests -only-testing:BeatStepTests/ZoneSelectionTests 2>&1 | tail -20`
- **After every plan wave:** Run full suite command
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 11-01-01 | 01 | 1 | RUN-01 | unit | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BeatStepTests/ZoneSelectionTests` | ❌ W0 | ⬜ pending |
| 11-01-02 | 01 | 1 | RUN-01 | unit | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BeatStepTests/RunZoneTests` | ✅ | ⬜ pending |
| 11-01-03 | 01 | 1 | RUN-02 | unit | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BeatStepTests/LastRunPlaylistTests` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `BeatStepTests/ZoneSelectionTests.swift` — stubs for selectedZoneId persistence, zone-to-runMode mapping, Free mode selection (RUN-01)
- [ ] Verify PacePresetTests.swift can be safely deleted after PacePreset enum removal

*Existing RunZoneTests and LastRunPlaylistTests cover partial requirements.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Zone capsule visual layout (horizontal scroll, selected state styling) | RUN-01 | SwiftUI visual rendering | Run app → Run tab → verify capsules show Z1-Z5 + Free, selected = surfaceOverlay fill |
| Full-width CTA pinned to bottom | RUN-02 | SwiftUI layout positioning | Run app → Run tab → verify red Start Run button pinned at bottom, doesn't scroll |
| Tolerance picker show/hide animation | RUN-01 | Visual transition | Select Free → tolerance hidden; select Z1 → tolerance appears with animation |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
