# Roadmap: BeatStep

## Milestones

- v1.0 MVP -- Phases 1-5 (shipped 2026-03-23)
- v1.1 Dark by Design -- Phases 6-9 (in progress)

## Phases

<details>
<summary>v1.0 MVP (Phases 1-5) -- SHIPPED 2026-03-23</summary>

- [x] Phase 1: Spotify Integration (2/2 plans) -- completed 2026-03-19
- [x] Phase 2: BPM Data Pipeline (3/3 plans) -- completed 2026-03-20
- [x] Phase 3: Cadence Detection (2/2 plans) -- completed 2026-03-20
- [x] Phase 4: Core Loop / Free Run (2/2 plans) -- completed 2026-03-20
- [x] Phase 5: Guided Run + Polish (2/2 plans) -- completed 2026-03-23

</details>

### v1.1 Dark by Design

**Milestone Goal:** Establish BeatStep's visual identity -- dark-only fitness aesthetic, design system with electric green accent, tab-based navigation, and brand mark.

- [x] **Phase 6: Design System Foundation** - Dark-mode commitment, color/type/spacing tokens, user approval gate (completed 2026-03-23)
- [x] **Phase 7: Tab Navigation Shell** - Bottom tab bar with Library/Run/Settings, MiniPlayer persistence, nav state (completed 2026-03-23)
- [x] **Phase 8: Token Adoption + RunHomeView** - Migrate all views to design tokens, build Run tab landing screen (completed 2026-03-23)
- [x] **Phase 9: Bug Fix + Brand Assets** - Fix track count display, app icon, wordmark (completed 2026-03-24)

## Phase Details

### Phase 6: Design System Foundation
**Goal**: Users see a consistent dark UI with a cohesive heartbeat red accent -- the visual language is defined and approved before any view migration begins
**Depends on**: Phase 5 (v1.0 complete)
**Requirements**: DARK-01, DARK-02, DS-01, DS-02, DS-03, DS-05
**Success Criteria** (what must be TRUE):
  1. App renders in dark mode on a device set to light mode -- no white flashes on launch, alerts, sheets, or Spotify OAuth
  2. No conditional light/dark styling code remains in the codebase (grep for preferredColorScheme returns zero hits outside AppEntry)
  3. Color, typography, and spacing token files exist and compile; tokens cover accent, 3 background levels, primary/secondary/tertiary text, state colors, heading/body/caption/numeric scales, and padding/radii/sizing
  4. User has reviewed and approved the token definitions (palette, type scale, spacing) before any view migration work begins
**Plans**: 2 plans

Plans:
- [x] 06-01-PLAN.md -- Design tokens + dark mode enforcement (DARK-01, DARK-02, DS-01, DS-02, DS-03)
- [ ] 06-02-PLAN.md -- Token approval gate (DS-05)

### Phase 7: Tab Navigation Shell
**Goal**: Users navigate BeatStep through a bottom tab bar with Library, Run, and Settings tabs -- the structural container for all screens
**Depends on**: Phase 6
**Requirements**: NAV-01, NAV-02, NAV-03
**Success Criteria** (what must be TRUE):
  1. Bottom tab bar shows three tabs (Library, Run, Settings) with appropriate SF Symbol icons and electric green tint
  2. User can navigate deep into a tab (e.g., Library > Playlist), switch to another tab, switch back, and find their navigation state preserved
  3. MiniPlayer is visible and functional across all three tabs without duplication or disappearing behind the tab bar
**Plans**: 1 plan

Plans:
- [x] 07-01-PLAN.md -- Tab navigation shell with TabView, per-tab NavigationStack, MiniPlayer safeAreaInset (NAV-01, NAV-02, NAV-03)

### Phase 8: Token Adoption + RunHomeView
**Goal**: Every screen uses design tokens (zero hardcoded colors) and the Run tab has a usable landing screen showing playlist context
**Depends on**: Phase 7
**Requirements**: DS-04, NAV-04
**Success Criteria** (what must be TRUE):
  1. Grep for hardcoded Color.green, Color.orange, Color.white, Color.gray returns zero hits outside the token definition files
  2. All existing views (PlaylistListView, RunView, MiniPlayerView, SettingsView, LoginView, CadenceDisplayView) use design tokens for all colors, fonts, and spacing
  3. Run tab shows the last-used playlist name and artwork when available; shows a prompt to select a playlist when no previous run exists
  4. LoginView uses a named SpotifyBrand token instead of a local spotifyGreen constant
**Plans**: 2 plans

Plans:
- [ ] 08-01-PLAN.md -- Migrate all views to design tokens (DS-04)
- [ ] 08-02-PLAN.md -- RunTabView last-used playlist context (NAV-04)

### Phase 9: Bug Fix + Brand Assets
**Goal**: Track count displays correctly and BeatStep has an app icon and wordmark establishing brand identity
**Depends on**: Phase 6 (tokens for icon color; independent of Phases 7-8 structurally)
**Requirements**: BUG-01, BRAND-01, BRAND-02
**Success Criteria** (what must be TRUE):
  1. Playlist view shows accurate track count for all playlist types; algorithmic playlists (Discover Weekly, Daily Mixes) display a dash or contextual label instead of "0 tracks"
  2. App icon appears on home screen with dark background and electric green accent mark
  3. Wordmark asset exists in the asset catalog and renders correctly at in-app display sizes
**Plans**: 2 plans

Plans:
- [ ] 09-01-PLAN.md -- Fix track count bug: trackCount becomes Int?, conditional display in views (BUG-01)
- [ ] 09-02-PLAN.md -- App icon (ECG pulse mark) and wordmark on login screen (BRAND-01, BRAND-02)

## Progress

**Execution Order:**
Phases execute in numeric order: 6 > 7 > 8 > 9
(Phase 9 can run in parallel with 7-8 -- its only dependency is Phase 6 tokens for color consistency.)

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 1. Spotify Integration | v1.0 | 2/2 | Complete | 2026-03-19 |
| 2. BPM Data Pipeline | v1.0 | 3/3 | Complete | 2026-03-20 |
| 3. Cadence Detection | v1.0 | 2/2 | Complete | 2026-03-20 |
| 4. Core Loop (Free Run) | v1.0 | 2/2 | Complete | 2026-03-20 |
| 5. Guided Run + Polish | v1.0 | 2/2 | Complete | 2026-03-23 |
| 6. Design System Foundation | 2/2 | Complete   | 2026-03-23 | - |
| 7. Tab Navigation Shell | v1.1 | 1/1 | Complete | 2026-03-23 |
| 8. Token Adoption + RunHomeView | 2/2 | Complete   | 2026-03-23 | - |
| 9. Bug Fix + Brand Assets | 2/2 | Complete   | 2026-03-24 | - |
