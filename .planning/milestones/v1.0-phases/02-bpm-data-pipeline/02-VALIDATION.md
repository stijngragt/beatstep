---
phase: 2
slug: bpm-data-pipeline
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-20
---

# Phase 2 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | XCTest (built-in, iOS 17) |
| **Config file** | BeatStepTests target in project.yml |
| **Quick run command** | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:BeatStepTests` |
| **Full suite command** | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 17 Pro'` |
| **Estimated runtime** | ~30 seconds |

---

## Sampling Rate

- **After every task commit:** Run `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:BeatStepTests`
- **After every plan wave:** Run `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 17 Pro'`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 02-01-01 | 01 | 0 | BPM-01 | unit | `xcodebuild test -only-testing:BeatStepTests/ModelDecodingTests` | ❌ W0 | ⬜ pending |
| 02-01-02 | 01 | 0 | BPM-01 | unit | `xcodebuild test -only-testing:BeatStepTests/GetSongBPMServiceTests` | ❌ W0 | ⬜ pending |
| 02-01-03 | 01 | 0 | BPM-05 | unit | `xcodebuild test -only-testing:BeatStepTests/BPMCacheServiceTests` | ❌ W0 | ⬜ pending |
| 02-02-01 | 02 | 2 | BPM-05 | unit | `xcodebuild test -only-testing:BeatStepTests/LibraryScanServiceTests` | ❌ W0 | ⬜ pending |
| 02-02-02 | 02 | 2 | SPOT-05 | unit | `xcodebuild test -only-testing:BeatStepTests/BPMViewWiringTests` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `BeatStepTests/ModelDecodingTests.swift` — stubs for BPM-01 (Codable response decoding, coverageText)
- [ ] `BeatStepTests/GetSongBPMServiceTests.swift` — stubs for BPM-01, SPOT-05 (API response decoding, mock responses)
- [ ] `BeatStepTests/BPMCacheServiceTests.swift` — stubs for BPM-05 (SwiftData CRUD with in-memory container)
- [ ] `BeatStepTests/LibraryScanServiceTests.swift` — stubs for BPM-05 (delta scan logic)
- [ ] `BeatStepTests/BPMViewWiringTests.swift` — stubs for BPM-05 (cache-to-view data flow)
- [ ] `BeatStepTests/Mocks/MockGetSongBPMResponses.swift` — mock JSON responses for GetSongBPM API
- [ ] SwiftData test setup: in-memory `ModelContainer` configuration for unit tests

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| BPM coverage stat display (e.g., "142 of 200") | BPM-05 | UI rendering in SwiftUI preview | Run app, navigate to library, verify coverage label matches scanned count |
| Spotify catalog search results display | SPOT-05 | End-to-end requires live Spotify token | Search for BPM, verify tracks appear with correct metadata |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
