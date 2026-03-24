---
phase: 12
slug: onboarding
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-24
---

# Phase 12 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | XCTest (built-in) |
| **Config file** | BeatStepTests target in project.yml |
| **Quick run command** | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BeatStepTests/OnboardingTests 2>&1 \| tail -20` |
| **Full suite command** | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 \| tail -50` |
| **Estimated runtime** | ~30 seconds |

---

## Sampling Rate

- **After every task commit:** Run `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BeatStepTests/OnboardingTests 2>&1 | tail -20`
- **After every plan wave:** Run `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | tail -50`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 12-01-01 | 01 | 1 | ONBD-01 | unit | `xcodebuild test ... -only-testing:BeatStepTests/OnboardingTests` | ❌ W0 | ⬜ pending |
| 12-01-02 | 01 | 1 | ONBD-02 | unit | `xcodebuild test ... -only-testing:BeatStepTests/OnboardingTests` | ❌ W0 | ⬜ pending |
| 12-01-03 | 01 | 1 | ONBD-03 | unit | `xcodebuild test ... -only-testing:BeatStepTests/OnboardingTests` | ❌ W0 | ⬜ pending |
| 12-01-04 | 01 | 1 | ONBD-04 | unit | `xcodebuild test ... -only-testing:BeatStepTests/OnboardingTests` | ❌ W0 | ⬜ pending |
| 12-01-05 | 01 | 1 | GATE | unit | `xcodebuild test ... -only-testing:BeatStepTests/OnboardingTests` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `BeatStepTests/OnboardingTests.swift` — stubs for ONBD-01 through ONBD-04 + gate behavior
- [ ] Test for AppState enum routing logic (onboarding -> login -> authenticated precedence)
- [ ] Test that hasCompletedOnboarding flag prevents authenticated view from rendering

*Note: Permission dialog tests are manual-only on device; automated tests cover the routing logic and flag management*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Spotify OAuth dialog appears after pre-prompt | ONBD-01 | System dialog not testable in XCTest | Launch app fresh → verify value screen → tap continue → verify OAuth sheet |
| HealthKit permission dialog appears after pre-prompt | ONBD-02 | System dialog not testable in XCTest | Launch app fresh → verify value screen → tap continue → verify HK dialog |
| iOS Settings opens from "Revisit Permissions" | ONBD-04 | URL scheme requires device | Deny permissions → Settings → Revisit → verify iOS Settings opens |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
