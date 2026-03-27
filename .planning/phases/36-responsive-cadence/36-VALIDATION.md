---
phase: 36
slug: responsive-cadence
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-27
---

# Phase 36 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | XCTest (Xcode) |
| **Config file** | BeatStep.xcodeproj |
| **Quick run command** | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BeatStepTests/CadenceServiceTests -quiet` |
| **Full suite command** | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' -quiet` |
| **Estimated runtime** | ~30 seconds |

---

## Sampling Rate

- **After every task commit:** Run quick CadenceService tests
- **After every plan wave:** Run full suite
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 36-01-01 | 01 | 1 | CAD-01, CAD-03 | unit | CadenceServiceTests | ✅ | ⬜ pending |
| 36-01-02 | 01 | 1 | CAD-02 | unit | RunEngineServiceTests | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Cadence display updates within 2s of pace change | CAD-01 | Requires real pedometer data or device testing | Run in Simulator, observe display latency |
| Song switches within 12s of sustained pace change | CAD-02 | Requires running app with active Spotify session | Start run, change pace, time until new song |
| Display doesn't jitter during steady pace | CAD-03 | Jitter perception requires visual observation | Run at constant pace, watch for number fluctuations |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
