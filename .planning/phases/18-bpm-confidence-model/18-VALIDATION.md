---
phase: 18
slug: bpm-confidence-model
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-25
---

# Phase 18 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | XCTest (built-in) |
| **Config file** | Xcode project (BeatStepTests target) |
| **Quick run command** | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BeatStepTests/BPMCacheServiceTests 2>&1 \| tail -20` |
| **Full suite command** | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 \| tail -40` |
| **Estimated runtime** | ~30 seconds (quick), ~120 seconds (full) |

---

## Sampling Rate

- **After every task commit:** Run quick command (BPMCacheServiceTests only)
- **After every plan wave:** Run full suite command
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 18-01-01 | 01 | 0 | CONF-01 | unit | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BeatStepTests/BPMCacheServiceTests` | ❌ W0 | ⬜ pending |
| 18-01-02 | 01 | 1 | CONF-01 | unit | Same as above | ❌ W0 | ⬜ pending |
| 18-01-03 | 01 | 1 | CONF-01 | unit | Same as above | ❌ W0 | ⬜ pending |
| 18-01-04 | 01 | 1 | CONF-01 | unit | Same as above | ❌ W0 | ⬜ pending |
| 18-01-05 | 01 | 1 | CONF-02 | unit | Same as above | ❌ W0 | ⬜ pending |
| 18-01-06 | 01 | 1 | CONF-02 | unit | Same as above | ❌ W0 | ⬜ pending |
| 18-01-07 | 01 | 1 | CONF-02 | unit | Same as above | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] New test methods in `BPMCacheServiceTests.swift` for confidence/source tracking (7 new tests)
- [ ] Update existing `BPMCacheServiceTests` calls from `cache()` to `cacheFromAPI()`
- [ ] Update existing `BPMViewWiringTests` calls from `cache()` to `cacheFromAPI()`
- [ ] Update existing `LibraryScanServiceTests` calls from `cache()` to `cacheFromAPI()`

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| v1.3 data survives upgrade | CONF-02 | Requires actual device with existing data | 1. Install v1.3 build, scan library 2. Install v1.4 build over top 3. Verify BPM values still display correctly |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
