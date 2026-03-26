---
phase: 32
slug: micro-interaction-pass
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-26
---

# Phase 32 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Xcode Previews (visual inspection) + code-grep compliance checks |
| **Config file** | n/a — Previews are inline |
| **Quick run command** | `grep -r "UIImpactFeedbackGenerator\|UISelectionFeedbackGenerator\|UINotificationFeedbackGenerator" BeatStep/Views/` (should return empty) |
| **Full suite command** | Quick run + `grep -r "\.spring(response:\|\.easeInOut(duration:\|\.easeOut(duration:" BeatStep/Views/` (should return empty) + manual interaction test |
| **Estimated runtime** | ~10 seconds (grep) + manual testing |

---

## Sampling Rate

- **After every task commit:** Run quick grep command
- **After every plan wave:** Run full suite command
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 10 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 32-01-01 | 01 | 1 | POL-02 | code-grep | `grep -r "UIImpactFeedbackGenerator\|UISelectionFeedbackGenerator\|UINotificationFeedbackGenerator" BeatStep/Views/` returns empty | n/a | ⬜ pending |
| 32-01-02 | 01 | 1 | POL-02 | code-grep | `grep -r "\.spring(response:\|\.easeInOut(duration:\|\.easeOut(duration:" BeatStep/Views/` returns empty | n/a | ⬜ pending |
| 32-02-01 | 02 | 2 | POL-02 | code-grep | `grep -c "BSHaptics\." BeatStep/Views/*.swift BeatStep/Views/**/*.swift` shows usage in all interactive views | n/a | ⬜ pending |
| 32-03-01 | 03 | 3 | POL-02 | code-grep | `grep -c "\.transition(.opacity)" BeatStep/Views/*.swift BeatStep/Views/**/*.swift` shows transitions on all conditional views | n/a | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements. No test framework installation needed — verification is code-grep for token compliance + manual interaction.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| All buttons provide haptic feedback | POL-02 | Haptic output requires physical device | Tap every button in app, verify haptic response |
| View transitions use spring animations | POL-02 | Animation quality is visual | Navigate between screens, observe animation smoothness |
| Conditional views crossfade | POL-02 | Transition smoothness is visual | Trigger state changes (loading→loaded, etc.), verify crossfade |
| Run screen numbers snap instantly | POL-02 | Animation scoping is visual during active run | Start run with varying cadence, verify numbers don't spring/bounce |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 10s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
