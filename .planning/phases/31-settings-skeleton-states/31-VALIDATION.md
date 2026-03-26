---
phase: 31
slug: settings-skeleton-states
status: draft
nyquist_compliant: true
wave_0_complete: true
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

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | Status |
|---------|------|------|-------------|-----------|-------------------|--------|
| 31-01-01 | 01 | 1 | POL-04 | structural | `grep -c "struct RunDefaultsView" BeatStep/Views/Settings/RunDefaultsView.swift` | pending |
| 31-01-02 | 01 | 1 | POL-04 | structural | `grep -c "listStyle(.insetGrouped)" BeatStep/Views/Settings/SettingsView.swift && grep -c "CFBundleShortVersionString" BeatStep/Views/Settings/SettingsView.swift` | pending |
| 31-02-01 | 02 | 1 | POL-03 | structural | `test -f BeatStep/DesignSystem/ShimmerModifier.swift && test -f BeatStep/Views/Library/PlaylistListSkeleton.swift && test -f BeatStep/Views/Library/PlaylistDetailSkeleton.swift` | pending |
| 31-02-02 | 02 | 1 | POL-03 | structural | `grep -c "PlaylistListSkeleton" BeatStep/Views/Library/PlaylistListView.swift && grep -c "PlaylistDetailSkeleton" BeatStep/Views/Library/PlaylistDetailView.swift` | pending |

*Status: pending / green / red / flaky*

**Verification approach:** This phase is primarily visual (settings layout restructuring + shimmer skeleton animations). Grep-based structural checks verify that the correct types, modifiers, and wiring are present in each file. Unit test stubs would add overhead without meaningful coverage for layout and animation code. The build verification (`xcodebuild build`) confirms compilation correctness, and manual verification confirms visual quality.

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

- [x] All tasks have `<automated>` verify commands (grep-based structural checks)
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] No Wave 0 stubs needed (structural grep verification is inline)
- [x] No watch-mode flags
- [x] Feedback latency < 30s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved — grep-based structural verification accepted for visual phase
