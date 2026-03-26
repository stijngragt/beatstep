# Phase 33: Analyzed State Fix - Context

**Gathered:** 2026-03-26
**Status:** Ready for planning

<domain>
## Phase Boundary

Fix the data flow so library view accurately reflects playlist scan state immediately after scan completion. The Analyzed/Unanalyzed filter must correctly reflect actual scan state. No new UI, no new features — fix the existing broken pipeline.

</domain>

<decisions>
## Implementation Decisions

### State propagation pattern
- **D-01:** Keep the existing `@State coverageData` manual reload pattern in PlaylistListView. Do not switch to `@Query`. Fix the trigger reliability instead.
- **D-02:** The existing `.onChange(of: scanService.scanningPlaylistID)` trigger stays but is supplemented by a new `scanCompletionCount` observer.

### Record creation gap (root cause)
- **D-03:** Change `updateScannedPlaylist` in LibraryScanService to upsert (create-or-update). Currently it only updates existing ScannedPlaylist records — first-time scans never create a record, which is the root cause of the bug. Single method, no new API surface.

### Background scan timing
- **D-04:** Add a `scanCompletionCount: Int` published property on LibraryScanService, incremented on each scan completion. PlaylistListView observes it via `.onChange` to reload coverage data. This handles the case where `scanEnabledPlaylists()` completes before the view mounts.

### Claude's Discretion
- Whether to keep the existing `.onChange(of: scanningPlaylistID)` alongside the new `scanCompletionCount`, or replace it entirely
- Exact placement of the `scanCompletionCount` increment (end of `scanPlaylist` vs end of `scanPlaylistByID`)
- Whether `loadCoverageData()` in `.task` should also check `scanCompletionCount` or rely solely on `.onChange`

</decisions>

<canonical_refs>
## Canonical References

No external specs — requirements fully captured in decisions above.

### Research
- `.planning/research/PITFALLS.md` — Identified dual root cause: missing ScannedPlaylist creation + stale @State coverage data
- `.planning/research/ARCHITECTURE.md` — Recommended scanCompletionCount pattern and confirmed fix scope

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `PlaylistCoverage` struct (PlaylistListView.swift:6-24): Data type for coverage display — stays as-is
- `PlaylistFilter` enum (PlaylistListView.swift:26-30): Filter logic — stays as-is, works once data is correct
- `FilterChipRow` (PlaylistListView.swift:283-312): UI component — no changes needed

### Established Patterns
- `@Observable` + `.onChange` for service-to-view communication (used by scanningPlaylistID already)
- `BPMCacheService.shared.context` for SwiftData access outside views
- `FetchDescriptor<ScannedPlaylist>` for querying scan state
- Upsert pattern not yet established — `updateScannedPlaylist` is update-only (the bug)

### Integration Points
- `LibraryScanService.swift:150-159` — `updateScannedPlaylist` needs upsert logic (create if not exists)
- `LibraryScanService.swift:16-19` — Add `scanCompletionCount` published property
- `PlaylistListView.swift:204-209` — Add `.onChange(of: scanService.scanCompletionCount)` trigger
- `PlaylistListView.swift:83-88` — `.task` already calls `loadCoverageData()` — verify timing with new trigger

</code_context>

<specifics>
## Specific Ideas

No specific requirements — the fix is well-scoped by the root cause analysis.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 33-analyzed-state-fix*
*Context gathered: 2026-03-26*
