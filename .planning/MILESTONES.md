# Milestones

## v1.1 Dark by Design (Shipped: 2026-03-24)

**Phases completed:** 4 phases, 7 plans
**Timeline:** 2026-03-23 → 2026-03-24 (2 days)
**Swift LOC:** 5,677
**Commits:** 21

**Delivered:** Dark-only visual identity with design system, tab navigation, and brand assets — every screen uses design tokens, no hardcoded colors remain.

**Key accomplishments:**
- Design token system: 10 color tokens (#FF4545 accent), 9 font tokens, 7 spacing values, 4 radii, 7 component sizes
- Global dark mode enforcement via Info.plist + window-level override (belt-and-suspenders)
- Tab navigation shell with Library/Run/Settings tabs, per-tab NavigationStack, global MiniPlayer
- All 8 view files migrated from hardcoded colors to design tokens
- Run tab landing screen with last-used playlist persistence via UserDefaults
- Track count bug fix: nil hides count for algorithmic playlists, 0 shows "0 tracks"
- App icon (ECG pulse mark, #FF4545 on near-black) and BEATSTEP wordmark on login

**Git range:** 9f70ca4 → 3924109

---

## v1.0 MVP (Shipped: 2026-03-23)

**Phases completed:** 5 phases, 11 plans
**Timeline:** 2026-03-19 → 2026-03-23 (5 days)
**Swift LOC:** 5,162

**Delivered:** A music-sync running app that detects your cadence in real-time and queues Spotify tracks whose BPM matches your stride.

**Key accomplishments:**
- Spotify OAuth + background playback with lock screen controls
- BPM data pipeline via GetSongBPM with Cloudflare Worker proxy (bypassing bot protection)
- Real-time cadence detection via CMPedometer with rolling average smoothing
- Core free run loop — cadence-to-BPM matching with half/double BPM support
- Guided run mode with warm-up/cool-down ramp state machine
- Smart song selection using danceability ranking from GetSongBPM

**Git range:** 81138cb → 6a9a248

---

