# Phase 10: Models, Settings & Library UX - Research

**Researched:** 2026-03-24
**Domain:** SwiftUI views, UserDefaults persistence, SwiftData queries, iOS List patterns
**Confidence:** HIGH

## Summary

Phase 10 introduces four discrete features: (1) a RunZone model with UserDefaults-persisted BPM values and Settings UI, (2) updated tolerance picker labels, (3) playlist analyzed-state indicators in Library rows, and (4) inline swipe-to-analyze on playlist rows. All four features operate on well-established SwiftUI patterns already used throughout BeatStep (Picker, Stepper, .swipeActions, @Observable services, UserDefaults persistence).

The codebase is well-structured for these changes. BPMTolerance already has the exact +-N values and UserDefaults pattern to copy. PacePreset provides a precedent for the zone model. PlaylistListView already has a coverageMap feeding into PlaylistRow. LibraryScanService.scanPlaylist already handles the full scan flow -- the inline analyze just needs to call it from a new entry point.

**Primary recommendation:** Build the RunZone model and tolerance label update first (pure model layer, easy to test), then layer on the Settings UI and Library UX changes.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- Playlist analyzed indicator: fraction text as secondary label "42/60 BPM", "Not analyzed" when zero, accent red for fraction, warning color for unanalyzed
- Inline analyze: trailing swipe action on ALL playlists, accent red button, spinner + "Analyzing 12/35" during scan
- Zone settings: inline in SettingsView list, tap-to-reveal Stepper, "Reset to Defaults" button, locked defaults Z1=155 Z2=165 Z3=174 Z4=178 Z5=185, UserDefaults persistence
- Tolerance picker: segments show only "+-3 BPM" / "+-7 BPM" / "+-12 BPM", drop named labels, stays in Run tab, "BPM Tolerance" caption above

### Claude's Discretion
- Zone model struct design (enum vs struct, Codable conformance)
- Stepper range validation (100-220 BPM)
- Exact spacing and typography for zone rows in Settings
- How to extract analyze logic from PlaylistDetailView into reusable service method

### Deferred Ideas (OUT OF SCOPE)
None
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| RUN-03 | User sees BPM tolerance as a segmented control displaying +-3, +-7, +-12 BPM | Update BPMTolerance.displayName to return "+-N BPM" format; TolerancePicker already uses .segmented style |
| RUN-04 | User can configure custom BPM values per zone in Settings (with sensible defaults) | New RunZone model with UserDefaults persistence following BPMTolerance pattern; SettingsView section with Stepper |
| LIB-01 | User can see analyzed/unanalyzed state on each playlist row in the Library tab | Extend coverageMap to include all playlists (not just those with tracksWithBPM > 0); update PlaylistRow display |
| LIB-02 | User can trigger playlist analysis inline from the Library list without navigating to the detail screen | Add .swipeActions to ForEach in PlaylistListView; extract scan logic into reusable service method |
</phase_requirements>

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| SwiftUI | iOS 17+ | All UI (List, Picker, Stepper, .swipeActions) | Already used throughout BeatStep |
| SwiftData | iOS 17+ | ScannedPlaylist persistence, BPM cache | Already used for BPM cache layer |
| Foundation/UserDefaults | iOS 17+ | Zone BPM and tolerance persistence | Already used for BPMTolerance, RunMode |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| @Observable macro | iOS 17+ | LibraryScanService reactive state | Already used for scan progress |

### Alternatives Considered
None -- all features use existing stack components.

**Installation:**
No new dependencies required.

## Architecture Patterns

### Recommended Project Structure
```
BeatStep/
  Models/
    RunZone.swift         # New: zone model + UserDefaults persistence
    BPMTolerance.swift    # Modified: displayName returns "+-N BPM"
    ScannedPlaylist.swift  # Unchanged
  Views/
    Settings/
      SettingsView.swift   # Modified: add "Running Zones" section
      ZoneSettingsRow.swift # New: zone row with tap-to-reveal Stepper
    Library/
      PlaylistListView.swift # Modified: swipe actions, extended coverageMap
    Run/
      TolerancePicker.swift  # Modified: caption label, updated text
  Services/
    LibraryScanService.swift # Modified: add scanPlaylistByID method
```

### Pattern 1: RunZone Model (Claude's Discretion - Recommendation)
**What:** Use a struct with static defaults and UserDefaults persistence, not an enum
**When to use:** When the user needs to customize values at runtime (enums have fixed associated values)
**Why struct over enum:** Zone BPM values are user-editable. An enum would require a parallel storage mechanism. A struct with `CaseIterable`-like static array keeps it clean.

```swift
struct RunZone: Identifiable, Equatable {
    let id: Int          // 1-5
    let name: String     // "Recovery", "Endurance", etc.
    var bpm: Int         // User-editable

    static let defaults: [RunZone] = [
        RunZone(id: 1, name: "Recovery", bpm: 155),
        RunZone(id: 2, name: "Endurance", bpm: 165),
        RunZone(id: 3, name: "Tempo", bpm: 174),
        RunZone(id: 4, name: "Threshold", bpm: 178),
        RunZone(id: 5, name: "Max", bpm: 185),
    ]

    // UserDefaults persistence
    private static let key = "runZoneBPMs"

    static var saved: [RunZone] {
        guard let dict = UserDefaults.standard.dictionary(forKey: key) as? [String: Int] else {
            return defaults
        }
        return defaults.map { zone in
            var z = zone
            z.bpm = dict["\(zone.id)"] ?? zone.bpm
            return z
        }
    }

    static func saveAll(_ zones: [RunZone]) {
        let dict = Dictionary(uniqueKeysWithValues: zones.map { ("\($0.id)", $0.bpm) })
        UserDefaults.standard.set(dict, forKey: key)
    }

    static func resetToDefaults() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}
```

**Why this pattern:** Matches the existing BPMTolerance UserDefaults pattern. Only BPM values are stored (not names/IDs -- those are compiled-in). The struct is trivially testable without mocking.

### Pattern 2: Inline Swipe-to-Analyze
**What:** .swipeActions trailing modifier on playlist ForEach rows
**When to use:** iOS-native pattern for contextual actions on list rows

```swift
ForEach(playlists) { playlist in
    NavigationLink(value: playlist) {
        PlaylistRow(playlist: playlist, coverageText: coverageMap[playlist.id])
    }
    .swipeActions(edge: .trailing) {
        Button {
            Task { await analyzePlaylist(playlist) }
        } label: {
            Label("Analyze", systemImage: "waveform.badge.magnifyingglass")
        }
        .tint(Color.accent)
    }
}
```

### Pattern 3: Extract Analyze Logic into LibraryScanService
**What:** Move the "fetch tracks then scan" flow from PlaylistDetailView into LibraryScanService so both detail and list views can trigger it
**When to use:** When the same operation is needed from two entry points

```swift
// In LibraryScanService:
func scanPlaylistByID(_ playlistID: String, name: String) async {
    // 1. Fetch all tracks via SpotifyAPIService
    // 2. Build SpotifyPlaylist wrapper
    // 3. Call existing scanPlaylist(_:tracks:)
    // (Logic currently duplicated in scanEnabledPlaylists -- extract and reuse)
}
```

The existing `scanEnabledPlaylists()` method already contains this "fetch tracks by ID then scan" pattern (lines 90-117 of LibraryScanService.swift). Extract it into a reusable method.

### Pattern 4: Coverage Map Extension for "Not analyzed"
**What:** Change loadCoverageData to include ALL playlists, showing "Not analyzed" for playlists with no ScannedPlaylist record

```swift
private func loadCoverageData() {
    let context = BPMCacheService.shared.context
    let descriptor = FetchDescriptor<ScannedPlaylist>()
    guard let scannedPlaylists = try? context.fetch(descriptor) else { return }

    let scannedMap = Dictionary(uniqueKeysWithValues: scannedPlaylists.map { ($0.spotifyPlaylistID, $0) })

    for playlist in playlists {
        if let sp = scannedMap[playlist.id] {
            coverageMap[playlist.id] = "\(sp.tracksWithBPM)/\(sp.totalTracks) BPM"
        } else {
            coverageMap[playlist.id] = nil  // nil = "Not analyzed" state
        }
    }
}
```

Then in PlaylistRow, differentiate between nil (not analyzed) and a value (fraction).

### Anti-Patterns to Avoid
- **Don't store zone names in UserDefaults:** Only BPM values are user-editable. Names are compiled-in constants.
- **Don't create a new SwiftData model for zones:** UserDefaults is the correct persistence layer for simple key-value settings. SwiftData is overkill.
- **Don't duplicate scan logic:** Extract from PlaylistDetailView, don't copy-paste the fetch+scan flow.
- **Don't block the main thread during swipe-analyze:** The scan is async and should update the coverageMap reactively via scanProgress observation.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| List swipe actions | Custom gesture recognizer + overlay | `.swipeActions(edge:)` modifier | iOS-native, handles animation/dismissal/accessibility |
| Segmented control | Custom HStack toggle buttons | `Picker(.segmented)` | Already used in TolerancePicker, consistent iOS look |
| Stepper with range | Custom +/- buttons | SwiftUI `Stepper(value:in:)` | Already used in PacePresetPicker for custom BPM |
| Settings list sections | Custom VStack layout | SwiftUI `List` + `Section` | SettingsView already uses this pattern |

## Common Pitfalls

### Pitfall 1: Swipe action during active scan
**What goes wrong:** User swipes to analyze a playlist that is already being scanned, triggering a duplicate scan
**Why it happens:** No guard against concurrent scans on the same playlist
**How to avoid:** Track which playlist ID is currently scanning in LibraryScanService. Disable swipe action or show "already scanning" state when that playlist is active.
**Warning signs:** Duplicate API calls to GetSongBPM, scan progress jumping between playlists

### Pitfall 2: CoverageMap not updating after swipe-analyze
**What goes wrong:** User swipes to analyze, scan completes, but the row still shows old state
**Why it happens:** coverageMap is a @State dictionary -- it won't automatically update when SwiftData changes
**How to avoid:** After scan completes, explicitly reload coverage for that playlist ID. Or observe LibraryScanService.scanProgress to know when to reload.
**Warning signs:** Row shows stale "Not analyzed" after successful scan

### Pitfall 3: Stepper revealing/hiding causes List animation glitch
**What goes wrong:** Tapping a zone row to reveal the Stepper causes jarring layout shift
**Why it happens:** List row height change without animation
**How to avoid:** Use `withAnimation(.easeInOut(duration: 0.2))` when toggling the expanded state. Use `DisclosureGroup` or a simple Bool toggle with conditional content.
**Warning signs:** Content jumping, overlapping rows

### Pitfall 4: BPMTolerance displayName change breaks existing tests
**What goes wrong:** PacePresetTests or BPMToleranceTests expect "Tight"/"Normal"/"Loose" display names
**Why it happens:** Tests assert on displayName values
**How to avoid:** Update BPMToleranceTests to expect new "+-N BPM" format. Check if displayName is used elsewhere (RunEngineService, etc.).
**Warning signs:** Test failures after label change

### Pitfall 5: Scan progress UI in PlaylistRow conflicts with global scan banner
**What goes wrong:** Both the scan progress banner (top of list) and the individual row show scan status simultaneously
**Why it happens:** scanProgress is a single global property, not per-playlist
**How to avoid:** For inline swipe-analyze, show progress on the specific row only (not the banner). The banner pattern is for background/multi-playlist scans. Either add per-playlist progress tracking or repurpose scanProgress with playlist ID context.
**Warning signs:** Confusing double progress indicators

## Code Examples

### Tolerance Picker Label Update
```swift
// In BPMTolerance.swift -- change displayName:
var displayName: String {
    "\u{00B1}\(range) BPM"  // "+-3 BPM", "+-7 BPM", "+-12 BPM"
}

// In TolerancePicker.swift -- add caption, simplify text:
VStack(spacing: Spacing.xxs) {
    Text("BPM Tolerance")
        .font(.captionText)
        .foregroundStyle(Color.textSecondary)

    Picker("Tolerance", selection: $tolerance) {
        ForEach(BPMTolerance.allCases, id: \.self) { level in
            Text(level.displayName).tag(level)
        }
    }
    .pickerStyle(.segmented)
    .onChange(of: tolerance) { _, newValue in
        newValue.save()
    }
}
```

### Zone Settings Row in SettingsView
```swift
// In SettingsView.swift -- between Account and Disconnect sections:
Section("Running Zones") {
    ForEach($zones) { $zone in
        ZoneRow(zone: $zone)
    }

    Button("Reset to Defaults") {
        zones = RunZone.defaults
        RunZone.resetToDefaults()
    }
    .foregroundStyle(Color.accent)
}

// ZoneRow component:
struct ZoneRow: View {
    @Binding var zone: RunZone
    @State private var isExpanded = false

    var body: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation { isExpanded.toggle() }
            } label: {
                HStack {
                    Text("Z\(zone.id) \(zone.name)")
                        .font(.bodyText)
                        .foregroundStyle(Color.textPrimary)
                    Spacer()
                    Text("\(zone.bpm) BPM")
                        .font(.bodyText)
                        .foregroundStyle(Color.textSecondary)
                }
            }

            if isExpanded {
                Stepper(value: $zone.bpm, in: 100...220) {
                    Text("\(zone.bpm) BPM")
                        .font(.subheading)
                        .monospacedDigit()
                }
                .padding(.top, Spacing.sm)
                .onChange(of: zone.bpm) { _, _ in
                    RunZone.saveAll(zones)  // persist on each change
                }
            }
        }
    }
}
```

### PlaylistRow with Coverage States
```swift
// In PlaylistRow -- update coverage display:
HStack(spacing: Spacing.xs) {
    if let count = playlist.trackCount {
        Text("\(count) tracks")
            .font(.captionText)
            .foregroundStyle(Color.textSecondary)
    }

    if let coverageText {
        Text("\u{00B7}")
            .font(.captionText)
            .foregroundStyle(Color.textSecondary)
        Text(coverageText)
            .font(.captionText)
            .foregroundStyle(Color.accent)  // red for fraction
    } else {
        Text("\u{00B7}")
            .font(.captionText)
            .foregroundStyle(Color.textSecondary)
        Text("Not analyzed")
            .font(.captionText)
            .foregroundStyle(Color.stateWarning)  // warning for unanalyzed
    }
}
```

Note: The current code only populates coverageMap for playlists where `tracksWithBPM > 0`. The "Not analyzed" state maps to a nil coverage entry. The PlaylistRow needs to distinguish "no entry in coverageMap" (not analyzed) from "has entry" (show fraction). Consider using an enum or optional wrapper instead of String to make this explicit.

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Effort labels (Easy Jog, Steady, etc.) | Zone-based (Z1-Z5) with custom BPM | v1.2 Phase 10 | Zone model replaces PacePreset for target BPM selection (Phase 11 swaps the UI picker) |
| Named tolerance (Tight/Normal/Loose) | Delta tolerance (+-3/+-7/+-12 BPM) | v1.2 Phase 10 | Label-only change, values unchanged |
| Analyze from detail screen toolbar | Analyze from list via swipe | v1.2 Phase 10 | Reduces navigation friction |

**Note on zone defaults:** STATE.md mentions divergent BPM defaults between research files. CONTEXT.md locks the values: Z1=155, Z2=165, Z3=174, Z4=178, Z5=185. These differ from PacePreset values (150, 160, 170, 180, 190) -- this is intentional per the context session.

## Open Questions

1. **Zone names (Z1-Z5)**
   - What we know: CONTEXT.md says "Z1 Recovery", "Z2 Endurance" but doesn't name all 5
   - What's unclear: Names for Z3, Z4, Z5 (common running zone names would be Tempo, Threshold, Max/VO2Max)
   - Recommendation: Use standard running zone nomenclature -- Recovery, Endurance, Tempo, Threshold, Max. Claude has discretion here.

2. **Per-playlist scan progress vs global scanProgress**
   - What we know: CONTEXT.md says "replace fraction text with spinner + Analyzing 12/35" on the specific row
   - What's unclear: Whether to extend ScanProgress with playlist ID or use a separate per-row state
   - Recommendation: Add `scanningPlaylistID: String?` to LibraryScanService so the row can check if it's the one being scanned. Reuse existing `scanProgress` for the count.

3. **SettingsView state management for zones**
   - What we know: SettingsView currently has no @State -- it reads directly from services
   - What's unclear: How to manage the zones array for Stepper binding
   - Recommendation: Add `@State private var zones: [RunZone] = RunZone.saved` to SettingsView. Save on each Stepper change.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | XCTest (built-in) |
| Config file | BeatStepTests target in Xcode project |
| Quick run command | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BeatStepTests` |
| Full suite command | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16'` |

### Phase Requirements -> Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| RUN-03 | BPMTolerance.displayName returns "+-N BPM" format | unit | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BeatStepTests/BPMToleranceTests` | Exists -- update assertions |
| RUN-04 | RunZone defaults, persistence, reset | unit | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BeatStepTests/RunZoneTests` | New -- Wave 0 |
| LIB-01 | Coverage text shows fraction or "Not analyzed" | unit | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BeatStepTests/ScannedPlaylistTests` | New -- Wave 0 |
| LIB-02 | Inline analyze triggers scan service | unit | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BeatStepTests/LibraryScanServiceTests` | Exists -- add scanPlaylistByID test |

### Sampling Rate
- **Per task commit:** `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BeatStepTests`
- **Per wave merge:** Full suite
- **Phase gate:** Full suite green before /gsd:verify-work

### Wave 0 Gaps
- [ ] `BeatStepTests/RunZoneTests.swift` -- covers RUN-04 (defaults, persistence, reset, range validation)
- [ ] Update `BeatStepTests/BPMToleranceTests.swift` -- update displayName assertions for RUN-03
- [ ] Add scanPlaylistByID test to `BeatStepTests/LibraryScanServiceTests.swift` -- covers LIB-02

## Sources

### Primary (HIGH confidence)
- Direct codebase analysis: BPMTolerance.swift, PacePreset.swift, SettingsView.swift, PlaylistListView.swift, PlaylistDetailView.swift, LibraryScanService.swift, TolerancePicker.swift, RunView.swift, DesignTokens.swift
- Phase 10 CONTEXT.md -- locked decisions from user discussion session

### Secondary (MEDIUM confidence)
- SwiftUI .swipeActions API -- well-established iOS 15+ API, verified by existing SwiftUI usage in project
- UserDefaults dictionary persistence -- standard Foundation pattern

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- all features use existing project stack, no new dependencies
- Architecture: HIGH -- patterns directly follow existing codebase conventions (BPMTolerance, PacePreset, coverageMap)
- Pitfalls: HIGH -- identified from direct code analysis of current implementation gaps

**Research date:** 2026-03-24
**Valid until:** 2026-04-24 (stable domain, no external dependency changes expected)
