# Phase 33: Analyzed State Fix - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-03-26
**Phase:** 33-analyzed-state-fix
**Areas discussed:** State propagation, Record creation gap, Background scan timing

---

## State Propagation

| Option | Description | Selected |
|--------|-------------|----------|
| Keep manual reload (Recommended) | Fix trigger reliability but keep @State dictionary pattern. Simplest change, consistent with existing patterns. | ✓ |
| Switch to @Query | Replace @State coverageData with SwiftData @Query on ScannedPlaylist. Auto-updates but requires view restructuring. | |
| You decide | Claude picks simplest approach | |

**User's choice:** Keep manual reload (Recommended)
**Notes:** Consistent with existing codebase patterns. Fix the triggers, not the architecture.

---

## Record Creation Gap

| Option | Description | Selected |
|--------|-------------|----------|
| Upsert in updateScannedPlaylist (Recommended) | Change to create-or-update. Single method, no new API surface. | ✓ |
| Separate create + update methods | Add explicit createScannedPlaylist at scan start. Clearer intent but more call sites. | |

**User's choice:** Upsert in updateScannedPlaylist (Recommended)
**Notes:** Root cause: updateScannedPlaylist at LibraryScanService.swift:150 only updates existing records. First-time scans never create a ScannedPlaylist record.

---

## Background Scan Timing

| Option | Description | Selected |
|--------|-------------|----------|
| Add scanCompletionCount (Recommended) | Int counter on LibraryScanService, incremented on each scan completion. View observes via onChange. | ✓ |
| Always reload on appear | Call loadCoverageData in onAppear. Simpler but more SwiftData reads. | |
| You decide | Claude picks most reliable pattern | |

**User's choice:** Add scanCompletionCount (Recommended)
**Notes:** Handles case where scanEnabledPlaylists() completes before PlaylistListView mounts.

---

## Claude's Discretion

- Whether to keep existing `.onChange(of: scanningPlaylistID)` alongside new `scanCompletionCount`
- Exact placement of `scanCompletionCount` increment
- Whether `.task` loadCoverageData should also check scanCompletionCount

## Deferred Ideas

None — discussion stayed within phase scope.
