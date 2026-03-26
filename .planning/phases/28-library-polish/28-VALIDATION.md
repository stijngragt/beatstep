---
phase: 28
slug: library-polish
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-26
---

# Phase 28 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | XCTest (iOS 17+) |
| **Config file** | BeatStepTests target in Xcode project |
| **Quick run command** | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BeatStepTests/LibraryScanServiceTests -quiet` |
| **Full suite command** | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' -quiet` |
| **Estimated runtime** | ~30 seconds |

---

## Sampling Rate

- **After every task commit:** Run quick run targeting modified test files
- **After every plan wave:** Run full suite command
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 28-01-01 | 01 | 0 | LIB-01 | unit | Test `filteredPlaylists` with search text | No -- Wave 0 | ⬜ pending |
| 28-01-02 | 01 | 0 | LIB-02 | unit | Test `filteredPlaylists` with filter enum | No -- Wave 0 | ⬜ pending |
| 28-01-03 | 01 | 0 | LIB-03 | unit | Test `PlaylistCoverage` struct | No -- Wave 0 | ⬜ pending |
| 28-01-04 | 01 | 0 | LIB-04 | unit | Test `deleteScan` in LibraryScanServiceTests | No -- Wave 0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `BeatStepTests/PlaylistFilterTests.swift` — stubs for LIB-01 + LIB-02 (filtering logic)
- [ ] `BeatStepTests/PlaylistCoverageTests.swift` — stubs for LIB-03 (coverage model, color thresholds)
- [ ] Add `testDeleteScan` to existing `BeatStepTests/LibraryScanServiceTests.swift` — covers LIB-04

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Search field filters without UI stutter | LIB-01 | Performance perception requires visual check | Type rapidly in search; verify no frame drops |
| Swipe/long-press gesture discoverability | LIB-04 | Gesture UX requires human evaluation | Swipe left on playlist; verify scan/delete actions appear |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
