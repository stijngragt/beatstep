# Pitfalls Research

**Domain:** iOS running music app -- responsive cadence, beat sync validation, SwiftData observation fixes, collapsible player
**Researched:** 2026-03-26
**Confidence:** HIGH (codebase-specific analysis + verified CMPedometer/SwiftUI/SwiftData patterns)

## Critical Pitfalls

### Pitfall 1: Reducing CMPedometer Window Causes Cadence Jitter

**What goes wrong:**
The current `CadenceService` uses a 5-second rolling window (`windowDuration = 5.0`) for smoothing. Reducing this window for responsiveness (e.g., to 2s) causes cadence readings to oscillate wildly -- a runner at a steady 170 SPM might see readings jump between 155 and 185 every second. This jitter propagates to `RunEngineService.onCadenceChanged()`, triggering constant debounce resets, which means cadence commits never actually fire.

**Why it happens:**
CMPedometer's `startUpdates(from:)` callback fires at iOS-controlled intervals (roughly every 1-3 seconds, not configurable). With a 5-second window, you get 2-5 samples for averaging. Drop to 2 seconds and you might have only 1-2 samples -- not enough to smooth out the natural variance between individual steps. The pedometer also sometimes delivers step bursts (multiple steps in one callback) rather than evenly-spaced individual step events.

**How to avoid:**
Do NOT simply reduce `windowDuration`. Instead, use a dual-window approach:
1. Keep the 5-second window for the smoothed `currentSPM` that drives song selection (stability matters here).
2. Add a separate 2-second "trend detection" window that detects *direction* of change (speeding up / slowing down) faster.
3. Use the fast window to trigger early UI updates ("cadence changing...") while the slow window confirms the sustained change for song selection.

Alternatively, reduce the `sustainedChangeTask` debounce in `RunEngineService` from 17 seconds to ~8 seconds -- this is the *actual* responsiveness bottleneck. The 17-second debounce means even a perfectly detected cadence change takes 17 seconds before a new song is selected.

**Warning signs:**
- `currentSPM` value changes by more than 10 SPM between consecutive updates during steady running
- `sustainedChangeTask` gets cancelled and restarted repeatedly without ever completing
- Sensor Lab waveform shows jagged cadence line instead of smooth curve

**Phase to address:**
Responsive cadence detection phase -- this is the first and most critical change

---

### Pitfall 2: SwiftData Model Changes Not Propagating to View Layer (Analyzed State Bug)

**What goes wrong:**
After `LibraryScanService.scanPlaylist()` completes and calls `context.save()`, the `PlaylistListView` filter does not reflect the updated state. Playlists that were just scanned still appear under "Unanalyzed" filter. The root cause is that `PlaylistListView` uses `@State private var coverageData: [String: PlaylistCoverage]` -- a *local copy* that is not connected to SwiftData's observation system. When `LibraryScanService` updates `ScannedPlaylist` records via `BPMCacheService.shared.context`, the view's `coverageData` dictionary is stale.

**Why it happens:**
The current architecture has two disconnected data paths:
1. `LibraryScanService` writes to SwiftData `ScannedPlaylist` models via `context.save()`
2. `PlaylistListView` builds `coverageData` from a one-time fetch (likely in `.onAppear` or `.task`) and stores it in `@State`

SwiftData's `@Query` macro would auto-update, but `coverageData` is a manually-maintained `@State` dictionary. The `@Observable` macro on `LibraryScanService` tracks `scanningPlaylistID` and `scanProgress`, but NOT the underlying SwiftData model changes. SwiftUI's observation system only tracks property access on `@Observable` objects -- it does not automatically bridge to SwiftData model mutations happening on a shared `ModelContext`.

**How to avoid:**
Three options (in order of preference):
1. **Replace `@State coverageData` with `@Query`**: Use SwiftData's `@Query` to fetch `ScannedPlaylist` records directly. This auto-updates when the underlying data changes.
2. **Reload coverage after scan completes**: Observe `LibraryScanService.scanningPlaylistID` (which IS `@Observable`) -- when it transitions from non-nil to nil (scan complete), re-fetch coverage data.
3. **Post a notification**: Have `LibraryScanService` post a `Notification` after scan completion, and have `PlaylistListView` listen and reload.

Option 1 is cleanest. Option 2 is pragmatic given the current architecture. Option 3 is a code smell but works.

**Warning signs:**
- Filter counts don't change after a scan completes
- Navigating away from Library tab and back "fixes" the filter (because `onAppear` re-fetches)
- `ScannedPlaylist` record in SwiftData has correct values but UI shows stale data

**Phase to address:**
Analyzed state bug fix phase -- this is a data flow architecture fix, not just a UI tweak

---

### Pitfall 3: safeAreaInset Stacking With TabView Creates Double Padding

**What goes wrong:**
The current `ContentView` applies `.safeAreaInset(edge: .bottom)` to the `TabView` to place `MiniPlayerView`. When converting to a collapsible player, if the collapsed height differs from the expanded height, the safe area inset does not animate smoothly. Worse, on iOS 17.4+ there's a known bug where `safeAreaInset` on `TabView` can cause the tab bar's safe area to stack incorrectly -- content gets pushed up by both the tab bar height AND the inset height, leaving a gap.

**Why it happens:**
`safeAreaInset` modifies the safe area for ALL child content within the `TabView`. The system tab bar already claims bottom safe area. Adding another `safeAreaInset` stacks on top. When the inset height changes (collapsed vs expanded player), SwiftUI recalculates layout for the entire tab content, which can cause visible jumps in scroll position and content offset. The height change also fights with the tab bar's own safe area management.

**How to avoid:**
Do NOT animate `safeAreaInset` height for collapse/expand. Instead:
1. Keep `safeAreaInset` at a FIXED height (the collapsed player height, e.g., 44pt).
2. Use an overlay or ZStack for the expanded state that extends upward from the fixed strip.
3. The expanded player should be a sheet, overlay, or separate layer -- NOT part of the safe area inset.

This way, content layout never changes when the player expands/collapses. Only the player view itself animates.

**Warning signs:**
- Content jumps or scroll position resets when player expands/collapses
- Gap between player and tab bar on certain iOS versions
- Tab bar items become unreachable (taps go to player instead)

**Phase to address:**
Collapsible player strip phase -- must be designed with fixed inset height from the start

---

### Pitfall 4: DragGesture on Collapsible Player Conflicts With Tab Content Scrolling

**What goes wrong:**
Adding a `DragGesture` to the player strip for swipe-down-to-collapse interferes with vertical scrolling in the tab content below (playlist lists, settings). Users try to scroll but accidentally trigger the player collapse gesture, or vice versa. The gesture system cannot distinguish between "user is swiping down on player strip" and "user is scrolling the list and their finger started near the player."

**Why it happens:**
SwiftUI's gesture system resolves conflicts based on gesture type and modifier (`.gesture`, `.simultaneousGesture`, `.highPriorityGesture`). A `DragGesture` on the player competes with the implicit `ScrollView` gesture. Using `.simultaneousGesture` lets both fire (causing visual chaos). Using `.gesture` blocks scrolling when starting from the player area. Using `.highPriorityGesture` takes over entirely.

**How to avoid:**
1. **Restrict drag target**: Apply the `DragGesture` only to the player's drag handle (a small visual indicator at the top), not the entire player view. Use a small `minimumDistance` (e.g., 10) so taps still work.
2. **Use tap-to-toggle instead of drag**: Simpler and no gesture conflicts. Tap the player strip to expand/collapse. This matches the Apple Music mini-player pattern.
3. **If drag is required**: Use `DragGesture(minimumDistance: 20)` to distinguish from taps, and gate the gesture recognition on vertical-only movement (`translation.height > abs(translation.width)`).

**Warning signs:**
- Users can't scroll playlists when finger starts near player area
- Player randomly collapses during normal scrolling
- Player gesture and list scroll fight visibly (both try to respond)

**Phase to address:**
Collapsible player strip phase -- gesture design must be decided before implementation

---

### Pitfall 5: Beat-to-Step Validation Gives False Positives Due to BPM Source Mismatch

**What goes wrong:**
When validating 1:1 beat-to-step accuracy with "known-BPM tracks," the BPM value from GetSongBPM may not match the actual audio tempo. GetSongBPM crowdsources data and sometimes reports the "felt" tempo (half or double the actual), or a slightly wrong value (e.g., 128 when the track is actually 127.5). If validation compares cadence against this approximate BPM, the sync quality indicator shows "in sync" when the runner is actually slightly off-beat, or "mismatched" when they're actually on tempo.

**Why it happens:**
BPM data has three sources of error:
1. **Half/double ambiguity**: A 140 BPM track might be listed as 70 BPM (half-time feel) in GetSongBPM
2. **Rounding errors**: Real BPMs are floating-point (127.5), but the app stores integers
3. **Wrong data**: GetSongBPM occasionally has incorrect entries

The current `BPMConfidence` model tracks `verified`/`approximate`/`manual` but doesn't account for half/double ambiguity within a confidence level. A track marked `.verified` by the API could still be at the wrong octave.

**How to avoid:**
1. **Accept both octaves in validation**: When checking sync, treat cadence-vs-BPM AND cadence-vs-(BPM*2) AND cadence-vs-(BPM/2) as valid matches. The existing `findMatchingTracks` already does this for selection -- validation must use the same logic.
2. **Use tolerance bands, not exact match**: Sync quality should use the same `BPMTolerance` ranges already in the app, not tighter thresholds.
3. **Don't build a separate validation system**: The existing `SyncQuality.from(delta:tolerance:)` IS the validation. "Beat-to-step validation" should mean verifying that `SyncQuality` is accurate during real runs, not building a new measurement system.

**Warning signs:**
- Sync indicator shows "mismatched" when user is clearly running on beat
- Validation test suite passes with synthetic data but fails with real GetSongBPM values
- Half-tempo tracks always show as "drifting"

**Phase to address:**
Beat-to-step accuracy validation phase -- must reuse existing sync logic, not create parallel system

---

### Pitfall 6: 17-Second Debounce Is the Real Responsiveness Bottleneck, Not the Detection Window

**What goes wrong:**
Developers focus on reducing `CadenceService.windowDuration` from 5s to 2s for responsiveness, but miss that `RunEngineService.onCadenceChanged()` has a 17-second debounce (`Task.sleep(for: .seconds(17))`). Even with instant cadence detection, song selection won't change for 17 seconds after a pace change. The cadence monitor also only polls every 2 seconds (`Task.sleep(for: .seconds(2))` in `startCadenceMonitor`). Total worst-case latency: 2s poll + 17s debounce = 19 seconds from real change to new song.

**Why it happens:**
The 17-second debounce was designed to prevent song-switching churn during momentary pace fluctuations (stopping at a traffic light, brief sprint). It's a reasonable conservative value. But combined with the 2-second polling interval and 5-second averaging window, the system is optimized entirely for stability at the expense of responsiveness.

**How to avoid:**
Address ALL three latency sources as a system, not individually:
1. **Reduce poll interval** in `startCadenceMonitor` from 2s to 1s (cheap, low risk)
2. **Reduce debounce** from 17s to 8-10s (moderate risk -- test with real running to verify no churn)
3. **Keep detection window at 5s** or use dual-window approach (see Pitfall 1)
4. **Add immediate UI feedback**: Update the cadence display immediately (current `latestCadence` assignment already does this), so the user sees responsiveness even before song selection changes.

The target of "<2s from real change to screen update" from the milestone is achievable for the *display* without touching the debounce. The *song selection* response time is a separate, longer pipeline.

**Warning signs:**
- Cadence display updates quickly but song doesn't change for 15+ seconds
- User perception of "laggy" persists even after detection window is reduced
- Only measuring detection latency, not end-to-end selection latency

**Phase to address:**
Responsive cadence detection phase -- must scope "responsiveness" to mean display AND selection separately

---

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| `@State coverageData` dict instead of `@Query` | Avoids SwiftData coupling in view | Stale data, manual invalidation needed | Never -- this is the analyzed state bug |
| Singleton services with `static let shared` | Simple access everywhere | Untestable without ForTesting methods, tight coupling | Acceptable for v1 but add protocol abstraction if a second consumer appears |
| 17s hardcoded debounce | Prevents churn | Not tunable per user, single value for all running styles | Extract to a configurable constant immediately |
| `coverageData` built from separate fetch, not derived from `ScannedPlaylist` | Decouples view from SwiftData | Two sources of truth for same data | Never -- derive from single source |

## Integration Gotchas

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| CMPedometer cadence vs step-derived cadence | Using `data.currentCadence` (system estimate) and step-delta fallback interchangeably -- they have different latencies | Track which source provided each sample; system cadence is smoother but slower, step-delta is faster but noisier |
| SwiftData `context.save()` from service → view update | Assuming `context.save()` triggers SwiftUI view updates automatically | Only `@Query` in views auto-updates; `@State`-backed data must be manually refreshed |
| `safeAreaInset` + `TabView` on iOS 17.4+ | Assuming safe area math is stable across iOS versions | Test on both iOS 17 and iOS 18; the stacking behavior differs between minor versions |
| Spotify Web API playback state | Trusting `SpotifyPlayerService.currentTrack` is always up-to-date for beat sync validation | Spotify playback state has 1-3 second lag; don't use it for precise beat timing |

## Performance Traps

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| Polling cadence every 1s with `Task.sleep` in a `while` loop | Battery drain on long runs (1h+), main thread pressure | Use CMPedometer's built-in callback (already in CadenceService); only poll in RunEngineService for sustained-change detection | Runs longer than 30 minutes |
| Re-rendering entire `PlaylistListView` on every cadence update | List scrolls jankily during active run with mini-player visible | Ensure `MiniPlayerView` doesn't force parent re-render; use `@Observable` property isolation | Playlists with 50+ items |
| `matchedGeometryEffect` on player collapse with complex subviews | Frame drops during expand/collapse animation | Use `.drawingGroup()` on player content (already done for charts) or simplify animated content | Players with album art + multiple text labels |

## UX Pitfalls

| Pitfall | User Impact | Better Approach |
|---------|-------------|-----------------|
| Collapsible player covers last list item | User can't tap bottom playlist item; it's behind the player | Ensure `safeAreaInset` reserves space for collapsed player at all times |
| Cadence display updates faster than song selection | User sees 180 SPM but music is still at 160 BPM, feels broken | Show a "matching..." indicator when cadence change is detected but debounce hasn't committed |
| Expand/collapse gesture too sensitive | Accidental player expansion during normal tapping | Require deliberate gesture (tap handle, not swipe anywhere) or add 200ms delay before recognizing expand gesture |
| Analyzed filter shows wrong count after scan | User scans a playlist, filter still says "0 Analyzed" | Immediate UI refresh after scan completes, even before navigating away |

## "Looks Done But Isn't" Checklist

- [ ] **Responsive cadence:** Display updates fast but song selection still takes 17+ seconds -- verify end-to-end latency, not just display latency
- [ ] **Beat sync validation:** Works with test data but half/double BPM tracks always show mismatched -- test with real GetSongBPM data across genres
- [ ] **Analyzed state fix:** Filter updates on initial scan but not on re-scan of same playlist -- verify delta scan path also refreshes UI
- [ ] **Player safe area:** Player looks correct on one device but cuts off on SE/Mini (smaller screens) -- test on 4" and 6.7" screens
- [ ] **Collapsible player:** Animation smooth in isolation but janky when run is active (cadence updates triggering re-renders) -- test with `RunEngineService.isRunActive = true`
- [ ] **Cadence responsiveness:** Works at walking pace but jittery at running pace (170+ SPM) -- test at actual running cadences, not walking

## Recovery Strategies

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| Cadence jitter from small window | LOW | Revert `windowDuration` to 5.0, add dual-window instead |
| SwiftData state not propagating | MEDIUM | Replace `@State coverageData` with `@Query`; requires refactoring PlaylistListView data flow |
| safeAreaInset stacking bug | LOW | Pin inset to fixed height, use overlay for expanded state |
| Gesture conflicts | LOW | Switch from DragGesture to tap-to-toggle; zero gesture conflict |
| False sync validation | LOW | Use existing `SyncQuality.from()` instead of new system |
| 17s debounce missed | LOW | Reduce constant to 8-10s, extract to configurable value |

## Pitfall-to-Phase Mapping

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| Cadence jitter (P1) | Responsive cadence detection | Sensor Lab shows smooth curve at 170+ SPM; no >10 SPM jumps between consecutive readings |
| SwiftData propagation (P2) | Analyzed state bug fix | Scan playlist, immediately check filter count without navigating away |
| safeAreaInset stacking (P3) | Player nav bar fix + Collapsible player | No gap between player and tab bar on iOS 17 and 18; content doesn't jump on expand/collapse |
| Gesture conflicts (P4) | Collapsible player strip | Can scroll playlist while player is visible; player only responds to deliberate gesture |
| False sync validation (P5) | Beat-to-step accuracy validation | Test with 5 tracks of known BPM across 70-180 range including half-tempo tracks |
| Debounce bottleneck (P6) | Responsive cadence detection | End-to-end time from pace change to new song < 12 seconds |

## Sources

- [CMPedometer Apple Documentation](https://developer.apple.com/documentation/coremotion/cmpedometer)
- [startUpdates(from:withHandler:) Apple Documentation](https://developer.apple.com/documentation/coremotion/cmpedometer/1613950-startupdates)
- [Mastering Safe Area in SwiftUI](https://fatbobman.com/en/posts/safearea/)
- [Navigation Bar and Tab Bar broken - Apple Developer Forums](https://developer.apple.com/forums/thread/735837)
- [SwiftData Model class not triggering view update - Apple Developer Forums](https://developer.apple.com/forums/thread/736764)
- [@Observable not always updating child view - Hacking with Swift](https://www.hackingwithswift.com/forums/swiftui/atobservable-not-always-updating-child-view/27784)
- [SwiftData child views not updating on insertions - Hacking with Swift](https://www.hackingwithswift.com/forums/swiftui/swiftdata-child-views-not-updating-on-insertions-but-updating-fine-on-deletions/25407)
- [SwiftData autosave bugs - Apple Developer Forums](https://developer.apple.com/forums/thread/735562)
- [DragGesture in SwiftUI ScrollView - Apple Developer Forums](https://developer.apple.com/forums/thread/655465)
- [Preventing Scroll Hijacking by DragGestureRecognizer](https://darjeelingsteve.com/articles/Preventing-Scroll-Hijacking-by-DragGestureRecognizer-Inside-ScrollView.html)
- [SwiftUI Gestures prevent scrolling - Apple Developer Forums](https://developer.apple.com/forums/thread/760035)
- BeatStep codebase analysis: `CadenceService.swift`, `RunEngineService.swift`, `LibraryScanService.swift`, `ContentView.swift`, `MiniPlayerView.swift`, `PlaylistListView.swift`, `ScannedPlaylist.swift`

---
*Pitfalls research for: BeatStep v1.7 Beat Perfect*
*Researched: 2026-03-26*
