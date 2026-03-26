---
phase: 31
slug: settings-skeleton-states
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-26
---

# Phase 31 — Validation Strategy

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

- **After every task commit:** Run quick run command
- **After every plan wave:** Run full suite command
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 31-01-01 | 01 | 1 | POL-04 | unit | `xcodebuild test ... -only-testing:BeatStepTests/SettingsTests` | ❌ W0 | ⬜ pending |
| 31-01-02 | 01 | 1 | POL-04 | manual | Visual inspection in Simulator | N/A | ⬜ pending |
| 31-02-01 | 02 | 1 | POL-03 | unit | `xcodebuild test ... -only-testing:BeatStepTests/SkeletonTests` | ❌ W0 | ⬜ pending |
| 31-02-02 | 02 | 1 | POL-03 | manual | Visual inspection in Simulator | N/A | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `BeatStepTests/SettingsTests.swift` — covers dynamic version string, section structure logic
- [ ] `BeatStepTests/SkeletonTests.swift` — covers shimmer modifier existence, skeleton row dimensions match real rows

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Settings sections visually grouped with SF Symbol icons | POL-04 | Visual layout, not unit-testable | Open Settings tab, verify 5 sections with heartbeat red SF Symbol icons |
| Shimmer gradient sweep animation plays during loading | POL-03 | Animation timing, visual effect | Launch app, observe playlist list loading skeleton |
| Skeleton row count fills visible area | POL-03 | Device-dependent visual behavior | Launch on multiple simulator sizes, verify no blank space below skeletons |
| Fade crossfade transition from skeleton to content | POL-03 | Animation transition quality | Watch skeleton-to-content transition, verify smooth fade |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
