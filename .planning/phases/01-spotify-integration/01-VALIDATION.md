---
phase: 1
slug: spotify-integration
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-19
---

# Phase 1 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | XCTest (built-in) + Swift Testing |
| **Config file** | None — Wave 0 must create test targets |
| **Quick run command** | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16'` |
| **Full suite command** | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16'` |
| **Estimated runtime** | ~15 seconds |

---

## Sampling Rate

- **After every task commit:** Run unit tests for affected module
- **After every plan wave:** Run full test suite
- **Before `/gsd:verify-work`:** Full suite must be green + manual verification checklist
- **Max feedback latency:** 15 seconds

---

## Per-Requirement Verification Map

| Req ID | Requirement | Test Type | Automated Command | File Exists | Status |
|--------|-------------|-----------|-------------------|-------------|--------|
| SPOT-01 | OAuth auth flow completes, tokens stored in Keychain | unit (token storage), manual (full auth requires Spotify app) | `xcodebuild test -only-testing BeatStepTests/SpotifyAuthServiceTests` | ❌ W0 | ⬜ pending |
| SPOT-02 | Play/pause/skip controls work | manual-only (requires Spotify app on physical device) | N/A — SPTAppRemote requires physical device with Spotify | ❌ W0 | ⬜ pending |
| SPOT-03 | Background playback + lock screen controls | manual-only (requires physical device) | N/A — background audio + lock screen cannot be automated in XCTest | ❌ W0 | ⬜ pending |
| SPOT-04 | Playlists fetched and displayed | unit (API parsing, pagination) | `xcodebuild test -only-testing BeatStepTests/SpotifyAPIServiceTests` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `BeatStepTests/` test target — must be created in Xcode project
- [ ] `BeatStepTests/SpotifyAuthServiceTests.swift` — token storage/retrieval, premium check parsing
- [ ] `BeatStepTests/SpotifyAPIServiceTests.swift` — playlist JSON decoding, pagination logic, error handling
- [ ] `BeatStepTests/Mocks/MockSpotifyResponses.swift` — JSON fixtures for API responses
- [ ] Manual test checklist for physical device verification of SPOT-02 and SPOT-03

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Full OAuth flow with Spotify app | SPOT-01 | Requires Spotify app installed on device for redirect | 1. Tap "Connect Spotify" 2. Spotify app opens 3. Authorize 4. Redirected back to BeatStep 5. Verify authenticated state |
| Play/pause/skip controls | SPOT-02 | SPTAppRemote requires physical device with Spotify | 1. Start playback from a playlist 2. Tap pause — music stops 3. Tap play — music resumes 4. Tap skip — next track plays |
| Background playback + lock screen | SPOT-03 | Background audio and lock screen controls cannot be automated | 1. Start playback 2. Lock phone — music continues 3. Use lock screen controls (play/pause/skip) 4. Open another app — music continues 5. Return to BeatStep — controls reflect current state |
| Playlist browsing and track display | SPOT-04 | Full visual verification of playlist UI | 1. Navigate to library 2. Playlists load with cover art 3. Tap playlist — tracks load with pagination 4. Tap track — playback starts |

---

## Validation Sign-Off

- [ ] All tasks have automated verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 15s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
