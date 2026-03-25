# Pitfalls Research

**Domain:** iOS running music app -- UI polish milestone (haptics, animations, search, gestures, queue, settings)
**Researched:** 2026-03-25
**Confidence:** HIGH (codebase-specific analysis + verified SwiftUI/Spotify patterns)

## Critical Pitfalls

### Pitfall 1: Haptic Fatigue -- Over-Hapticizing a Fitness App

**What goes wrong:**
Every button tap, toggle, and scroll snap gets a haptic. During a 45-minute run the phone vibrates hundreds of times. Users either disable haptics system-wide or perceive the app as cheap/annoying. Battery drain compounds -- the Taptic Engine draws measurable power on sustained use, and BeatStep already runs CoreMotion + Spotify polling + screen-on during exercise.

**Why it happens:**
Haptics are easy to add with iOS 17's `.sensoryFeedback` modifier. Developers sprinkle them everywhere during the "micro-interaction pass" because each one feels good in isolation. Nobody tests the cumulative experience over a full run session.

**How to avoid:**
Define a haptic budget before writing code. Three tiers:
- **Always haptic:** Run start, run stop (long-press confirm), zone transition, sync state change (in-sync/drifting/mismatch). These are ~5-10 events per run.
- **Light haptic:** Skip song, toggle tempo mode. Use `.selection` weight only.
- **Never haptic:** Scrolling, tab switching, navigation push/pop, loading states, pull-to-refresh, search typing.

Use `UIImpactFeedbackGenerator` prepared instances (not `.sensoryFeedback` inline) for the run screen -- prepare once at run start, fire during run, deallocate at run stop. This avoids repeated engine wake-up costs.

**Warning signs:**
- More than 8 distinct haptic call sites in a single view
- Haptics firing inside `onChange` or rapid-update closures
- No `.prepare()` call before time-critical haptics (causes 50-100ms latency on first fire)

**Phase to address:**
Micro-interaction pass phase. Define the haptic inventory as the first task before adding any `.sensoryFeedback` modifiers.

---

### Pitfall 2: Animation Jank on the Run Screen During Active Exercise

**What goes wrong:**
Animations that look smooth in Xcode previews stutter during an actual run. The run screen has real-time updates every 2 seconds (cadence, sync state, zone band, ramp progress) plus album art changes on song transitions. Adding transition animations to these elements causes frame drops because SwiftUI is already re-rendering the body on every `@Observable` state change from `RunEngineService.shared`.

**Why it happens:**
`ActiveRunView` reads `RunEngineService.shared` directly (per the v1.3 decision "Direct service reads over @State copies"). This means ANY property change on `RunEngineService` triggers a full view body evaluation. Adding `.animation(.spring())` to sync-state color shifts or zone band position creates animation work on top of the already-frequent re-renders. On ProMotion displays (120Hz) this compounds.

**How to avoid:**
- Use `drawingGroup()` on any animated sub-view in ActiveRunView (already proven with the Swift Charts waveform in SensorLabView).
- Scope animations with `animation(_:value:)` tied to specific values, never use bare `.animation(.default)` which animates ALL changes.
- For the sync background color shift (already exists via `SyncBackgroundModifier`), verify it uses `animation(_:value: syncQuality)` not a blanket animation.
- Song transition animations: use `.transition(.opacity)` with `.animation(.easeInOut(duration: 0.3), value: currentMatchedTrack?.id)` -- short duration, single property trigger.
- Never animate the cadence number or BPM number text itself -- number changes should snap, not interpolate.

**Warning signs:**
- Instruments Time Profiler showing >16ms frame times during run
- `.animation()` modifier without a `value:` parameter anywhere in the run view hierarchy
- Multiple nested `withAnimation` blocks in `onChange` closures

**Phase to address:**
Micro-interaction pass phase AND run menu redesign phase. Animation additions to `ActiveRunView` need profiling on a physical device during an actual run (not just previews).

---

### Pitfall 3: Spotify Queue API Cannot Pre-Buffer -- Building a Skip Queue on a Lie

**What goes wrong:**
The v1.6 feature "Pre-built skip queue for instant song skipping" implies pre-loading the next N tracks into Spotify's queue so skipping is instant. But the Spotify Web API `POST /me/player/queue` has critical limitations:
1. You cannot read back the queue reliably (GET returns max 20 items, with looping artifacts).
2. You cannot remove items from the queue once added.
3. Order of execution is not guaranteed when combined with other Player API endpoints.
4. Each `add-to-queue` call is a separate HTTP request counting toward rate limits.

If you pre-queue 5 tracks and the user's cadence changes, those 5 tracks are now wrong-BPM and there is no way to remove them. The user skips through 5 mismatched songs before reaching a fresh match.

**Why it happens:**
Developers assume "queue" means a controllable playlist-like buffer. Spotify's queue is append-only with no remove/reorder/clear API. The current `RunEngineService` correctly avoids this by using `play(uri:)` which plays a specific track immediately (overriding queue). Switching to queue-based playback loses this control.

**How to avoid:**
Do NOT use Spotify's queue API for the skip queue. Instead, build a **local pre-computation queue**:
- `RunEngineService` maintains an internal `nextTracks: [SpotifyTrack]` array (3-5 pre-selected matches for current BPM).
- On skip, call `play(uri:)` with the next track from the local array (same as current behavior, but the selection is pre-computed so there is zero selection delay).
- On cadence change, invalidate and recompute the local queue.
- The user perceives "instant skip" because selection work is done ahead of time, but Spotify playback is still controlled via direct `play(uri:)` calls.

This gives instant skip UX without the queue API's limitations.

**Warning signs:**
- Any code calling `POST /me/player/queue` in the skip flow
- No invalidation logic when cadence/BPM changes
- Skip flow making more than 1 API call (should be exactly 1 `play(uri:)`)

**Phase to address:**
Skip queue phase. The phase plan MUST specify "local pre-computation queue, NOT Spotify queue API" in its requirements.

---

### Pitfall 4: Search/Filter Recomputing on Every Keystroke Against Full Playlist State

**What goes wrong:**
Adding `.searchable` to `PlaylistListView` with a naive `filteredPlaylists` computed property causes the entire `List` to re-render on every character typed. With 50+ playlists each showing `AsyncImage` album art, this creates visible lag -- images flash/reload as the list rebuilds.

**Why it happens:**
`PlaylistListView` currently loads playlists into `@State private var playlists: [SpotifyPlaylist]` with pagination. A naive filter creates a new array on every keystroke, and SwiftUI's `List` identity changes cause cell recycling to reset `AsyncImage` loads. Combined with the coverage map lookup and scan state checks per row, this is expensive.

**How to avoid:**
- Debounce search text with a 300ms delay before filtering (use `.task(id: searchText)` with `Task.sleep`).
- Filter should produce stable IDs so `List(filteredPlaylists)` does not destroy/recreate cells. Use `ForEach(filteredPlaylists, id: \.id)` -- already the case since `SpotifyPlaylist` is `Identifiable`, but verify the filtered array maintains identity stability.
- For the filter segments (All / Analyzed / Unanalyzed), compute filter state from the existing `coverageMap` dictionary, not a re-fetch. The data is already loaded.
- Keep `AsyncImage` in a separate extracted view so its identity is tied to the playlist ID, not the list position.

**Warning signs:**
- `AsyncImage` URLs being re-fetched during typing (visible as flickering album art)
- Search text binding directly driving a computed property without debounce
- Filter segments triggering `loadPlaylists()` or `loadCoverageData()` instead of filtering in-memory

**Phase to address:**
Library search/filter phase. The filter segments (All/Analyzed/Unanalyzed) should be implemented first since they are a simple `coverageMap` lookup, then search is layered on top.

---

### Pitfall 5: Swipe Actions Conflicting with Navigation and Existing Gestures

**What goes wrong:**
`PlaylistListView` already has `.swipeActions` on each row (the "Analyze" swipe). Adding more swipe actions (contextual scan actions) or context menus creates gesture priority conflicts. In iOS 18, custom swipe implementations in `ScrollView` are broken due to `highPriorityGesture` conflicts. Additionally, adding a long-press context menu to rows that already have `NavigationLink` causes the navigation to fire before the context menu appears.

**Why it happens:**
SwiftUI's gesture system has a strict priority: `ScrollView` drag > `highPriorityGesture` > `gesture` > `simultaneousGesture`. Native `.swipeActions` on `List` work because they are built into the `List` implementation. But mixing native swipe actions with custom gesture recognizers or context menus creates unpredictable priority resolution. The existing `NavigationLink(value:)` wrapping each row means taps are already "claimed."

**How to avoid:**
- Stick to native `.swipeActions` and `.contextMenu` modifiers on `List` rows -- do NOT implement custom swipe gesture recognizers.
- Multiple swipe actions on the same edge are supported natively (e.g., Analyze + Delete on trailing edge). Use this instead of custom implementations.
- For context menus: use `.contextMenu` modifier which coexists with `NavigationLink` and `.swipeActions` without conflict (SwiftUI handles the long-press disambiguation).
- Order matters: apply `.swipeActions` before `.contextMenu` on the row.
- Do NOT use `DragGesture` or `LongPressGesture` on rows inside `List` -- these will fight with scroll and swipe.

**Warning signs:**
- Custom `DragGesture` or `UIGestureRecognizerRepresentable` inside List rows
- Swipe actions that sometimes fail to trigger (gesture stolen by scroll)
- Navigation fires when user intended long-press context menu

**Phase to address:**
Contextual scan actions phase. Design the action inventory (what goes in swipe vs context menu) before implementation. Swipe = primary action (Analyze). Context menu = secondary actions (copy link, remove, etc.).

---

### Pitfall 6: Settings Screen Over-Engineering with Premature Abstraction

**What goes wrong:**
The current `SettingsView` is 137 lines with inline sections. The v1.6 goal is "Settings screen structure (account, defaults, debug, about)." Developers restructure this into a generic `SettingsSection` model, a `SettingsRow` component with multiple configuration options, and a data-driven settings architecture. This adds 300+ lines of abstraction for a screen with 6 sections and ~15 rows that rarely changes.

**Why it happens:**
Settings screens look like they should be data-driven because each row follows a pattern. But BeatStep's settings have heterogeneous row types: static text, `Picker`, `Button`, `NavigationLink`, zone editor with binding, permission status with computed color. A generic model cannot cleanly express this variety without becoming as complex as the view code it replaces.

**How to avoid:**
Keep `SettingsView` as a plain `List` with explicit sections. The restructuring should be:
1. Extract long sections into separate views (`AccountSection`, `ZonesSection`, `PlaybackSection`, `PermissionsSection`, `DebugSection`, `AboutSection`).
2. Each section is a simple `Section { ... }` returning concrete views -- no generics, no model layer.
3. Add the missing sections (About with version/credits, Debug with Sensor Lab toggle relocated).
4. Total refactor should be <200 lines across all files.

**Warning signs:**
- A `SettingsItem` enum or struct being created
- Generic `SettingsRow<Content: View>` wrapper
- More than 3 new files for the settings restructure
- Settings data flowing through a ViewModel/ObservableObject when `@AppStorage` and direct reads suffice

**Phase to address:**
Settings screen phase. Keep the phase scope to "restructure into extracted sections + add About section" -- explicitly NOT "build a settings framework."

---

### Pitfall 7: Design Token Drift -- New Components Bypassing the Token System

**What goes wrong:**
v1.6 introduces custom components (playlist cards, run menu rebuild, zone picker redesign). Each new component hardcodes colors, fonts, spacing, and radii instead of using `DesignTokens.swift`. After the milestone, some components use `Color.accent` while others use `Color(red: 1.0, green: 0.271, blue: 0.271)`. Typography uses `.system(size: 16)` instead of `.bodyText`. The design system fractures.

**Why it happens:**
Developers copy-paste from Apple sample code or Stack Overflow answers that use raw values. The existing token system is not enforced by the compiler -- it requires discipline. New developers (or AI assistants) do not know the token vocabulary exists.

**How to avoid:**
Every phase plan for v1.6 must include a verification step: "grep for hardcoded colors/fonts/spacing in new files." Specifically:
- No `Color(red:` or `Color(white:` in view files (only in `DesignTokens.swift`).
- No `.system(size:` in view files for text fonts (SF Symbol sizing is exempted per key decision).
- No raw `CGFloat` padding/spacing values -- use `Spacing.sm`, `Spacing.md`, etc.
- No raw corner radius values -- use `Radius.sm`, `Radius.md`, etc.

Add a comment header to `DesignTokens.swift`: "All visual constants live here. Views use token names, never raw values."

**Warning signs:**
- New `.swift` files in Views/ containing `Color(red:` or `Color(white:`
- Inconsistent spacing between new and old components
- "It looks slightly different" feedback on new components

**Phase to address:**
EVERY phase in v1.6. This is a cross-cutting concern. Each phase verification should include a token compliance check.

---

### Pitfall 8: RunEngineService Singleton Mutation During Queue Changes

**What goes wrong:**
The skip queue feature adds new state to `RunEngineService` (pre-computed next tracks array, queue invalidation logic). Since `RunEngineService` is `@Observable` and `ActiveRunView` reads it directly, adding new `var` properties triggers view re-renders. Adding a `var nextTracks: [SpotifyTrack]` that updates every 2 seconds (when cadence changes) causes `ActiveRunView` to re-render every 2 seconds even though it does not display the queue.

**Why it happens:**
`@Observable` tracks access at the property level. If `ActiveRunView`'s body never reads `nextTracks`, it will not re-render when `nextTracks` changes. But if ANY view in the hierarchy reads it (e.g., a future "up next" indicator), that view and its parent chain re-render. The singleton pattern means every view sharing `RunEngineService.shared` is in the same observation graph.

**How to avoid:**
- Mark queue-internal state with `@ObservationIgnored` (same pattern used for `playlistTracks`, `bpmMap`, `playedTrackIDs`).
- Only expose a minimal observable surface: `var nextTrackPreview: SpotifyTrack?` (single next track for potential "up next" UI display).
- Keep queue computation in `@ObservationIgnored` properties and `private` methods.
- If an "up next" view is added later, make it read only `nextTrackPreview`, not the full queue array.

**Warning signs:**
- New `var` (non-`@ObservationIgnored`) properties on `RunEngineService` that change frequently
- `ActiveRunView` body being called on every cadence poll (check with `Self._printChanges()`)
- Queue array exposed as a public observable property

**Phase to address:**
Skip queue phase. The implementation MUST use `@ObservationIgnored` for internal queue state, following the existing pattern in `RunEngineService`.

---

### Pitfall 9: Spotify February 2026 API Changes Breaking Existing Functionality

**What goes wrong:**
Spotify's February 2026 Web API changelog introduced breaking changes that may affect BeatStep during v1.6 development:
1. Search endpoint `limit` parameter maximum decreased from 50 to 10 (default from 20 to 5).
2. Playlist response field `tracks` renamed to `items` throughout the object hierarchy.
3. Several batch endpoints removed (Get Several Tracks, Get Several Albums).
4. User profile fields removed: `country`, `email`, `followers`, `product`.

If `BPMDiscoveryService` uses search with `limit > 10`, it silently returns fewer results. If `SpotifyPlaylist` decoding relies on a `tracks` field, it breaks entirely.

**Why it happens:**
Spotify made these changes in February 2026. The app was built against the pre-February API. If the app is already running on the new API without issues, the decoding models are correct. But any new code written referencing old documentation or examples will use deprecated field names.

**How to avoid:**
- Audit `SpotifyAPIService.swift` search calls: verify `limit` parameter is <= 10.
- Audit `SpotifyPlaylist` model: verify the field used for tracks/items matches the current API response.
- Check `SpotifyUser` model: if it reads `product` field (used for Premium check), verify it still works. The `user.isPremium` check in SettingsView depends on this.
- When writing new API integration code for v1.6, reference the current (post-February 2026) API docs, not cached examples.

**Warning signs:**
- Search returning fewer results than expected
- Playlist decoding failures (`DecodingError.keyNotFound`)
- User Premium status check returning incorrect values

**Phase to address:**
First phase of v1.6. Run a quick API audit before building new features. If the app is currently working, the models may already be correct -- but verify explicitly.

---

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Inline haptic `.sensoryFeedback` in run views | Quick to add | Engine wake-up latency, no prepare/release lifecycle | Only for non-time-critical interactions (settings, library). Run screen must use prepared generators |
| `.animation(.default)` without value parameter | Animates "everything" easily | Animates state changes you did not intend, causes jank on rapid updates | Never in ActiveRunView. Acceptable in static views like Settings |
| Computing filtered playlists in view body | No debounce code needed | Keystroke lag with 50+ playlists + AsyncImage | Only if playlist count is guaranteed <20 |
| Storing skip queue in UserDefaults | Persists across app restarts | Queue is ephemeral -- stale data causes wrong-BPM playback on next run | Never. Queue should be in-memory only, cleared on run stop |
| One-file SettingsView with all sections | Single file to edit | 200+ line file, merge conflicts when multiple features touch settings | Acceptable during v1.5, should be split in v1.6 settings phase |

## Integration Gotchas

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| Spotify Player API + queue feature | Using `POST /me/player/queue` for skip queue (append-only, no remove) | Local pre-computation queue with `PUT /me/player/play` for playback control |
| Spotify API Feb 2026 changes | Search `limit` parameter still set to 20+ (max is now 10) | Update `BPMDiscoveryService` search calls to use `limit: 10`. Paginate if more results needed |
| Spotify API Feb 2026 changes | Reading `playlist.tracks` field (renamed to `items`) | Verify `SpotifyPlaylist` model uses correct field name. Check `PaginatedResponse` decoding |
| CoreMotion + haptics during run | Haptic engine interfering with accelerometer readings | No evidence of interference, but test on device. Haptic motor and accelerometer are separate hardware |
| SwiftData + search filtering | Fetching `ScannedPlaylist` on every filter change | Cache `coverageMap` in memory (already done), filter against it. No SwiftData queries during search |

## Performance Traps

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| `AsyncImage` reload on list filter | Album art flickers during search/filter | Extract `AsyncImage` into identity-stable subview, debounce filter | >30 playlists with search active |
| Unbounded `.sensoryFeedback` in cadence-updated views | Battery drain, haptic motor overheating | Haptics only on discrete user actions, never on observed-state changes | Any run >10 minutes |
| `.shadow()` or `.blur()` on scrolling list rows | Frame drops during scroll, especially with album art | Use `drawingGroup()` or remove blur/shadow from scrollable content | >20 visible rows |
| Song transition animation + cadence poll both triggering re-render | Dropped frames during song change | Scope animations to `value:` parameter, use `@ObservationIgnored` for non-UI state | Every song transition during active run |
| Pre-computing queue on every cadence update (every 2s) | Unnecessary CPU work during exercise | Only recompute queue when `sustainedSPM` changes (after 17s debounce), not on every `latestCadence` update | Continuous during run |

## UX Pitfalls

| Pitfall | User Impact | Better Approach |
|---------|-------------|-----------------|
| Haptic on every search keystroke | Annoying vibration while typing playlist name | No haptics on text input -- ever |
| Context menu on playlist row with no visual affordance | Users never discover secondary actions exist | Add subtle "..." icon on row trailing edge, or mention in onboarding |
| Search bar always visible (takes space) | Reduces visible playlist count on small screens | Use `.searchable` which auto-hides in navigation bar, revealed by pull-down |
| Skip queue showing "Up Next" with track that changes when cadence changes | Confusing -- "up next" keeps changing before playing | Either hide queue preview, or only show it when cadence is stable (no pending rematch) |
| Settings restructure moving zone configuration deeper | Users who configured zones in v1.2-v1.5 cannot find them | Keep zones at top level (not nested under a "Running" sub-page) |
| Animated transitions on every screen push/pop | Feels overdone, slows navigation | Only animate meaningful state changes (run start, sync state). Navigation should be instant/default |

## "Looks Done But Isn't" Checklist

- [ ] **Haptics:** Tested during a 10+ minute run on physical device -- not just in previews
- [ ] **Haptics:** `.prepare()` called before time-critical feedback (run screen events)
- [ ] **Search:** Debounce verified -- type rapidly and confirm no lag or image flicker
- [ ] **Search:** Filter segments (All/Analyzed/Unanalyzed) work without network calls
- [ ] **Search:** Empty state shown when filter/search yields zero results
- [ ] **Swipe actions:** Work after scrolling (not stolen by scroll gesture)
- [ ] **Swipe actions:** Coexist with context menu without gesture conflicts
- [ ] **Skip queue:** Local queue invalidates when cadence changes (not playing stale matches)
- [ ] **Skip queue:** Skip during song transition does not double-fire (rate limit guard)
- [ ] **Skip queue:** Uses `play(uri:)` not `POST /me/player/queue`
- [ ] **Animations:** No bare `.animation(.default)` without `value:` in run views
- [ ] **Animations:** Tested on physical device during run -- no frame drops
- [ ] **Settings:** Zone configuration still at top level, not buried
- [ ] **Settings:** Version string updated from "v1.4" to "v1.6"
- [ ] **Design tokens:** Zero hardcoded `Color(red:` in new view files
- [ ] **Design tokens:** All spacing uses `Spacing.*`, all radii use `Radius.*`
- [ ] **Feb 2026 API:** Search limit parameter <= 10 in BPMDiscoveryService
- [ ] **Feb 2026 API:** Playlist response field name verified (`items` not `tracks`)

## Recovery Strategies

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| Over-hapticized app | LOW | Grep for `.sensoryFeedback` and `UIImpactFeedbackGenerator`, remove non-essential ones. 1-2 hour fix |
| Animation jank in run view | MEDIUM | Add `value:` parameter to all `.animation()` calls, add `drawingGroup()` to animated subviews. Requires device testing |
| Built skip queue on Spotify queue API | HIGH | Must rewrite to local pre-computation approach. Queue API items cannot be removed -- users stuck with wrong-BPM songs until queue drains |
| Search causes AsyncImage flicker | LOW | Extract playlist row album art into separate identity-stable view, add debounce. 1-2 hour fix |
| Gesture conflicts on swipe + context menu | MEDIUM | Remove custom gesture recognizers, switch to native `.swipeActions` + `.contextMenu`. May require row layout restructure |
| Settings over-engineered | MEDIUM | Delete abstraction layer, return to explicit section views. Wasted time but reversible |
| Design token drift | LOW-MEDIUM | Grep + replace hardcoded values. Easy per-file but tedious if spread across many files |
| RunEngineService observable bloat | MEDIUM | Add `@ObservationIgnored` to internal properties. Requires understanding observation tracking |
| Feb 2026 API breakage | MEDIUM | Update model field names, adjust search limits. Requires testing each endpoint |

## Pitfall-to-Phase Mapping

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| Haptic fatigue | Micro-interaction pass | Haptic inventory defined before implementation; run-test on device |
| Run screen animation jank | Micro-interaction pass + Run menu redesign | Instruments Time Profiler on device during 5-min run shows <16ms frames |
| Spotify queue API misuse | Skip queue | Implementation uses `play(uri:)`, zero calls to queue endpoint |
| Search keystroke lag | Library search/filter | Type rapidly in 50+ playlist library -- no flicker, no lag |
| Swipe gesture conflicts | Contextual scan actions | Swipe + context menu + navigation all work on same row |
| Settings over-engineering | Settings screen | Restructure is <200 LOC across all new files, no generic model layer |
| Design token drift | ALL phases | `grep -r "Color(red:" BeatStep/Views/` returns zero matches in new files |
| RunEngineService mutation | Skip queue | New queue state uses `@ObservationIgnored`; `Self._printChanges()` shows no spurious re-renders |
| Feb 2026 API changes | First phase (API audit) | All endpoints tested against live API, search limit <= 10 |

## Sources

- [Spotify Web API Rate Limits](https://developer.spotify.com/documentation/web-api/concepts/rate-limits) -- rolling 30-second window, 429 responses
- [Spotify Web API February 2026 Changelog](https://developer.spotify.com/documentation/web-api/references/changes/february-2026) -- search limit reduced to 10, playlist field renames
- [Spotify Queue API Limitations (GitHub Issue #921)](https://github.com/spotify/web-api/issues/921) -- no remove from queue, append-only, 20-item read limit
- [Sensory Feedback and Haptics in SwiftUI](https://bleepingswift.com/blog/sensory-feedback-haptics-swiftui) -- best practices, battery considerations
- [SwiftUI Sensory Feedback (Use Your Loaf)](https://useyourloaf.com/blog/swiftui-sensory-feedback/) -- iOS 17+ modifier usage
- [WWDC23: Demystify SwiftUI Performance](https://developer.apple.com/videos/play/wwdc2023/10160/) -- observation tracking, animation scoping
- [SwiftUI Scroll Performance: The 120FPS Challenge](https://blog.jacobstechtavern.com/p/swiftui-scroll-performance-the-120fps) -- drawingGroup, lazy containers
- [SwiftUI Gesture Conflicts in ScrollView (Apple Forums)](https://developer.apple.com/forums/thread/760035) -- iOS 18 highPriorityGesture breaking custom swipe
- [SwiftUI Searchable Bugs and Learnings](https://medium.com/@snowham/exploring-swiftui-learnings-and-bugs-with-searchable-c5110995c80e) -- memory and lifecycle issues
- BeatStep codebase: `RunEngineService.swift`, `SpotifyPlayerService.swift`, `PlaylistListView.swift`, `SettingsView.swift`, `DesignTokens.swift`

---
*Pitfalls research for: BeatStep v1.6 Little Big Things*
*Researched: 2026-03-25*
