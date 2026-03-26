# Phase 30: Skip Queue - Research

**Researched:** 2026-03-26
**Domain:** Swift Concurrency / Local Playback Buffer / RunEngineService
**Confidence:** HIGH

## Summary

Phase 30 adds a 3-track pre-computed buffer to `RunEngineService` so that skipping a song pops from local memory (~0ms compute) rather than computing a match on-demand (~variable ms). The existing `selectNextMatch(forSPM:)` is fully reusable -- it already handles BPM matching, danceability ranking, no-repeat pool, zero-BPM fallback, and discovery triggers. The buffer is a straightforward array/queue that wraps this existing function.

The primary complexity is concurrency: buffer refill is async (background), buffer pop is sync (main actor), and cadence/tempo-mode changes must invalidate and rebuild the buffer atomically. The existing `@ObservationIgnored` + guard-flag patterns in RunEngineService provide the template.

**Primary recommendation:** Implement buffer as a private `[SpotifyTrack]` array with `@ObservationIgnored`, fill it 3-deep via `selectNextMatch(forSPM:)` calls, pop from index 0 on skip/song-end, and refill asynchronously after each pop. Guard concurrent refills with an `isRefillingBuffer` flag matching the existing `isQueueingNext` pattern.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** 3-track pre-computed buffer -- enough runway for rapid skipping
- **D-02:** Refill immediately after each skip/pop -- async refill to maintain 3 tracks at all times
- **D-03:** Buffer serves ALL transitions -- both manual skip and natural song-end use the buffer (replaces current on-demand computation in `queueNextMatch()`)
- **D-04:** 1-second cooldown between skips -- prevents accidental double-taps while allowing fast skipping
- **D-05:** Current 5-second rate limit in `queueNextMatch()` is removed/replaced by the new 1-second cooldown
- **D-06:** When buffer is empty (all 3 skipped, refill in progress), skip button blocks until refill completes -- no fallback to on-demand computation
- **D-07:** When sustained cadence change commits (after 17s debounce), invalidate buffer and rebuild with 3 new tracks at new cadence
- **D-08:** When user toggles tempo mode (1:1 <-> 1:2) mid-run, invalidate buffer and rebuild -- tempo mode changes effective BPM range

### Claude's Discretion
- Internal buffer data structure (array, queue, etc.)
- Whether `selectNextMatch(forSPM:)` is called 3x upfront or refactored for batch selection
- How buffer interacts with the existing `playedTrackIDs` no-repeat pool
- Refill timing details (sync vs async, which thread)

### Deferred Ideas (OUT OF SCOPE)
- **Queue visibility on active run screen** (RUN-05) -- Future requirement. Buffer is internal-only for now, but can be made observable later.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| RUN-03 | Skipping a song is instant -- 2-3 tracks pre-computed and ready in a local buffer | Buffer architecture, pop-from-array pattern, 1s cooldown, buffer invalidation on cadence/tempo changes |
</phase_requirements>

## Architecture Patterns

### Recommended Approach: Array-Based Ring Buffer

**What:** A private `[SpotifyTrack]` array (not a custom queue type) serving as FIFO buffer. Pop from index 0 (`removeFirst()`), append refills at end. Simple, debuggable, matches existing code style.

**Why array over Deque/custom queue:** The buffer is only 3 elements. `removeFirst()` on a 3-element array is O(1) in practice (compiler optimizes small arrays). No need for `Collections.Deque` -- it adds a dependency for zero measurable benefit at this scale.

**Structure after implementation:**
```
RunEngineService
  [existing state]
  + trackBuffer: [SpotifyTrack]         // @ObservationIgnored, max 3
  + bufferRefillTask: Task<Void, Never>? // @ObservationIgnored
  + isRefillingBuffer: Bool              // @ObservationIgnored guard flag
  + lastSkipTime: Date?                  // @ObservationIgnored, 1s cooldown
```

### Pattern 1: Pop + Play + Refill

**What:** Every transition (skip or song-end) pops from buffer, plays immediately, then triggers async refill.
**When to use:** Both `skipToNextMatch()` and `queueNextMatch()` converge on this pattern.

```swift
// Pseudocode -- Claude's discretion on exact implementation
private func popAndPlay() async {
    guard !trackBuffer.isEmpty else {
        // D-06: block until refill completes
        await awaitBufferRefill()
        guard !trackBuffer.isEmpty else { return }
    }

    let next = trackBuffer.removeFirst()
    await playTrack(next)
    handleRampTransition()
    triggerBufferRefill()
}
```

### Pattern 2: Buffer Invalidation

**What:** Cadence commit or tempo-mode toggle clears buffer and rebuilds from scratch.
**When to use:** `onCadenceChanged` sustained commit (line 429) and `tempoMode` setter.

```swift
private func invalidateBuffer() {
    bufferRefillTask?.cancel()
    trackBuffer.removeAll()
    triggerBufferRefill()
}
```

### Pattern 3: Buffer Fill at Run Start

**What:** After playing the first track in `startRun()`, immediately fill the buffer with 3 tracks.
**Why:** Ensures the buffer is ready before the user's first skip.

### Pattern 4: Skip Cooldown

**What:** 1-second cooldown replaces the existing 5-second rate limit. Applied only to manual skips (not song-end transitions).
**Implementation:** Check `lastSkipTime` in `skipToNextMatch()`, return early if < 1s elapsed.

### Anti-Patterns to Avoid
- **Calling Spotify API during skip:** The `play(uri:)` call is fire-and-forget (no `await` needed on the engine side). The 500ms sleep in `SpotifyPlayerService.play()` happens in its own Task -- it does NOT block the caller.
- **Registering tracks in `playedTrackIDs` at play time:** Register when selected into buffer (during `selectNextMatch`), not when popped. This prevents the same track appearing twice in the buffer.
- **Making buffer `@Observable`:** Buffer is internal engine state. Following `@ObservationIgnored` pattern per CONTEXT.md.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| FIFO queue | Custom generic queue class | Plain `[SpotifyTrack]` with `removeFirst()` | 3-element array, no abstraction needed |
| Thread safety | Manual locks/semaphores | Swift Task + guard flag (`isRefillingBuffer`) | Matches existing `isQueueingNext` pattern exactly |
| Rate limiting | Timer-based debounce | Simple `Date` comparison (`lastSkipTime`) | Matches existing `lastPlayTime` pattern exactly |

## Common Pitfalls

### Pitfall 1: Buffer Contains Stale Tracks After Cadence Change
**What goes wrong:** Buffer was filled at 170 BPM, cadence changes to 150 BPM, user skips and gets a 170-BPM track.
**Why it happens:** Buffer not invalidated on cadence commit.
**How to avoid:** D-07 -- invalidate buffer in the sustained change commit block (line 429-431 of current code). Also invalidate on tempo mode toggle (D-08).
**Warning signs:** Skipped track BPM doesn't match current cadence after a sustained change.

### Pitfall 2: Duplicate Tracks in Buffer
**What goes wrong:** Same track appears twice in the 3-track buffer.
**Why it happens:** `selectNextMatch` adds to `playedTrackIDs`, but if buffer is invalidated and refilled, the old buffer tracks were already in `playedTrackIDs` and the pool may reset.
**How to avoid:** On invalidation, do NOT remove buffer track IDs from `playedTrackIDs`. The no-repeat pool handles its own reset when exhausted.
**Warning signs:** Hearing the same song twice in quick succession.

### Pitfall 3: Race Between Refill and Invalidation
**What goes wrong:** Refill task completes after invalidation, adding stale tracks back.
**Why it happens:** Async refill runs concurrently with invalidation.
**How to avoid:** Cancel `bufferRefillTask` BEFORE clearing buffer in `invalidateBuffer()`. Use `Task.isCancelled` checks in the refill loop.
**Warning signs:** Buffer contains tracks that don't match current BPM after tempo change.

### Pitfall 4: Song-End Monitor Conflicts With Buffer
**What goes wrong:** Song-end monitor detects track change (from our own skip) and queues another transition.
**Why it happens:** Current song-end monitor compares `currentTrack?.id` with `lastTrackID` -- a skip changes the track, triggering another `queueNextMatch`.
**How to avoid:** The `isQueueingNext` guard already prevents this. But verify: when skip pops + plays, and song-end monitor fires, the guard flag or buffer empty state must prevent double-pop.
**Warning signs:** Two songs consumed from buffer for one skip.

### Pitfall 5: Buffer Empty on Rapid Triple-Skip
**What goes wrong:** User skips 3 times quickly, buffer empty, 4th skip does nothing.
**Why it happens:** D-06 says block until refill -- but if refill takes time, the UX feels broken.
**How to avoid:** This is by design (D-06). The 1-second cooldown (D-04) means 3 skips take at least 3 seconds, which should be enough time for at least 1 refill cycle (selectNextMatch is pure in-memory, nearly instant).
**Warning signs:** Skip button unresponsive after 3 rapid skips.

## Code Examples

### Current Skip Flow (to be replaced)
```swift
// Current: compute + play on every skip (ActiveRunView line 83)
onSkip: { Task { await runEngine.skipToNextMatch() } }

// Current skipToNextMatch -> queueNextMatch -> selectNextMatch -> playTrack
// Each skip recomputes. Buffer eliminates this.
```

### Key Integration Points

**1. `skipToNextMatch()` (line 180-183)** -- Changes from compute+play to pop-from-buffer+play. Add 1s cooldown check.

**2. `queueNextMatch()` (line 454-482)** -- Changes from compute+play to pop-from-buffer+play. Remove 5s rate limit. Keep `handleRampTransition()`.

**3. `startRun()` (line 107-152)** -- After playing first track, fill buffer with 3 tracks.

**4. `stopRun()` (line 154-178)** -- Clear buffer, cancel refill task.

**5. `onCadenceChanged()` sustained commit (line 425-431)** -- Add buffer invalidation after `sustainedSPM = newSPM`.

**6. `tempoMode` setter** -- Currently just a stored property. Either add a `didSet` or change the toggle in ActiveRunView to also call `invalidateBuffer()`.

**7. `ActiveRunView` skip button (line 83)** -- May remain as-is (`Task { await runEngine.skipToNextMatch() }`). The async call now just pops from buffer (near-instant) instead of computing.

### playTrack Timing Note
```swift
// SpotifyPlayerService.play(uri:) spawns its own Task internally (line 32-46)
// It does NOT block the caller. The 500ms sleep is internal.
// So popAndPlay() effectively completes instantly from the engine's perspective.
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| On-demand `selectNextMatch` per skip | 3-track pre-computed buffer | Phase 30 | Skip latency: ~variable ms -> ~0ms (array pop) |
| 5-second rate limit | 1-second cooldown (skip only) | Phase 30 | Users can skip faster, feels responsive |
| `queueNextMatch` computes per song-end | Song-end pops from buffer too | Phase 30 | Consistent transition path for all playback changes |

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | XCTest (built-in) |
| Config file | BeatStepTests target in Xcode project |
| Quick run command | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BeatStepTests/RunEngineServiceTests` |
| Full suite command | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16'` |

### Phase Requirements -> Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| RUN-03a | Buffer fills with 3 tracks at run start | unit | `...RunEngineServiceTests/testBufferFillsOnStart` | Wave 0 |
| RUN-03b | Skip pops from buffer (not recompute) | unit | `...RunEngineServiceTests/testSkipPopsFromBuffer` | Wave 0 |
| RUN-03c | Buffer refills after pop | unit | `...RunEngineServiceTests/testBufferRefillsAfterPop` | Wave 0 |
| RUN-03d | 1-second skip cooldown enforced | unit | `...RunEngineServiceTests/testSkipCooldown` | Wave 0 |
| RUN-03e | Buffer invalidated on cadence commit | unit | `...RunEngineServiceTests/testBufferInvalidatedOnCadenceChange` | Wave 0 |
| RUN-03f | Buffer invalidated on tempo mode toggle | unit | `...RunEngineServiceTests/testBufferInvalidatedOnTempoToggle` | Wave 0 |
| RUN-03g | Rapid triple-skip empties buffer, 4th blocks | unit | `...RunEngineServiceTests/testRapidSkipBlocksWhenEmpty` | Wave 0 |

### Sampling Rate
- **Per task commit:** Quick run on RunEngineServiceTests only
- **Per wave merge:** Full suite
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] New buffer-related tests in `BeatStepTests/RunEngineServiceTests.swift` -- 7 test cases listed above
- [ ] Testing helpers needed: `fillBufferForTesting()`, `getBufferForTesting()`, `setLastSkipTimeForTesting()`

## Sources

### Primary (HIGH confidence)
- `BeatStep/Services/RunEngineService.swift` -- full source read, all 529 lines
- `BeatStep/Services/SpotifyPlayerService.swift` -- full source read, play() fire-and-forget pattern confirmed
- `BeatStep/Views/Run/ActiveRunView.swift` -- skip button integration at line 83
- `BeatStep/Views/Player/RunPlayerView.swift` -- onSkip callback pattern
- `BeatStepTests/RunEngineServiceTests.swift` -- existing test patterns, testing helpers

### Secondary (MEDIUM confidence)
- None needed -- this is purely internal refactoring of existing code patterns

### Tertiary (LOW confidence)
- None

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- no new dependencies, pure Swift
- Architecture: HIGH -- buffer pattern is straightforward, existing code patterns provide template
- Pitfalls: HIGH -- identified from direct code analysis of race conditions and state management

**Research date:** 2026-03-26
**Valid until:** No expiry -- internal architecture, no external dependencies
