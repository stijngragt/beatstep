---
status: complete
phase: 29-run-menu-rebuild
source: [29-01-SUMMARY.md, 29-02-SUMMARY.md]
started: 2026-03-26T09:00:00Z
updated: 2026-03-26T09:05:00Z
---

## Current Test

[testing complete]

## Tests

### 1. Zone capsules toggle independently
expected: On the Run tab, tap a zone capsule (e.g. Z1 Recovery). It highlights and you feel a light haptic tap. Tap another zone (e.g. Z3 Tempo) — both are now highlighted. Tap Z1 again — it deselects (unhighlights), Z3 stays selected. Each tap gives a haptic tick.
result: pass

### 2. Free capsule clears all zones
expected: Select one or more zones, then tap the Free capsule. All zones deselect, Free highlights. You feel a haptic tap on the Free tap.
result: pass

### 3. Tolerance picker is custom capsules (not stock picker)
expected: The BPM Tolerance selector shows three capsule-shaped buttons (+-3, +-7, +-12) in a row — not a segmented control or dropdown. Tapping each gives a haptic tick and highlights the selected one.
result: pass

### 4. Merged BPM range label
expected: Select zones 1 and 3 (Recovery + Tempo). A label appears showing "155-174 BPM" (the floor of zone 1 to the ceiling of zone 3). Select only zone 2 — label shows "165-165 BPM". Deselect all zones — label disappears.
result: pass

### 5. Zone selection persists across app restart
expected: Select zones 1 and 3, then kill and reopen the app. The Run tab shows zones 1 and 3 still selected.
result: pass

### 6. Starting a run with zones uses guided mode
expected: With zones selected, tap Start Run. The active run view starts in guided mode using the midpoint BPM of your selected zones.
result: pass

### 7. Starting a run with no zones uses free mode
expected: Tap Free to deselect all zones, then tap Start Run. The active run view starts in free mode (music adapts to your pace, no target BPM).
result: pass

## Summary

total: 7
passed: 7
issues: 0
pending: 0
skipped: 0
blocked: 0

## Gaps

[none]
