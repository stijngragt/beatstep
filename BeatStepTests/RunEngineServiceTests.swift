import XCTest
@testable import BeatStep

@MainActor
final class RunEngineServiceTests: XCTestCase {

    private var engine: RunEngineService!

    // Helper tracks
    private let track120 = SpotifyTrack(
        id: "t120", name: "Song 120", uri: "spotify:track:t120",
        durationMs: 200_000, artists: [Artist(name: "A")],
        album: Album(name: "Album", images: nil)
    )
    private let track170 = SpotifyTrack(
        id: "t170", name: "Song 170", uri: "spotify:track:t170",
        durationMs: 200_000, artists: [Artist(name: "A")],
        album: Album(name: "Album", images: nil)
    )
    private let track85 = SpotifyTrack(
        id: "t85", name: "Song 85", uri: "spotify:track:t85",
        durationMs: 200_000, artists: [Artist(name: "A")],
        album: Album(name: "Album", images: nil)
    )
    private let track340 = SpotifyTrack(
        id: "t340", name: "Song 340", uri: "spotify:track:t340",
        durationMs: 200_000, artists: [Artist(name: "A")],
        album: Album(name: "Album", images: nil)
    )
    private let track200 = SpotifyTrack(
        id: "t200", name: "Song 200", uri: "spotify:track:t200",
        durationMs: 200_000, artists: [Artist(name: "A")],
        album: Album(name: "Album", images: nil)
    )
    private let trackNoBPM = SpotifyTrack(
        id: "tNone", name: "No BPM", uri: "spotify:track:tNone",
        durationMs: 200_000, artists: [Artist(name: "A")],
        album: Album(name: "Album", images: nil)
    )

    override func setUp() async throws {
        try await super.setUp()
        engine = RunEngineService.shared
        engine.stopRun()
        engine.tolerance = .normal // reset to default
    }

    override func tearDown() async throws {
        engine.stopRun()
        engine = nil
        try await super.tearDown()
    }

    // MARK: - BPM Matching (Direct)

    func testMatchingTracksReturnsCorrectBPMRange() {
        // 170 SPM with Normal tolerance (+/-7) -> direct match range 163-177
        let bpmMap: [String: Int] = ["t170": 170, "t120": 120, "t200": 200]
        let tracks = [track170, track120, track200]

        engine.loadForTesting(tracks: tracks, bpmMap: bpmMap)
        engine.tolerance = .normal

        let matches = engine.findMatchingTracks(forSPM: 170)
        XCTAssertEqual(matches.count, 1)
        XCTAssertEqual(matches.first?.id, "t170")
    }

    // MARK: - Half/Double BPM Matching

    func testHalfDoubleMatching() {
        // 170 SPM: half = 85 (+/-7 = 78-92), double = 340 (+/-7 = 333-347)
        let bpmMap: [String: Int] = ["t85": 85, "t340": 340, "t200": 200]
        let tracks = [track85, track340, track200]

        engine.loadForTesting(tracks: tracks, bpmMap: bpmMap)
        engine.tolerance = .normal

        let matches = engine.findMatchingTracks(forSPM: 170)
        XCTAssertEqual(matches.count, 2)

        let matchIDs = Set(matches.map(\.id))
        XCTAssertTrue(matchIDs.contains("t85"))
        XCTAssertTrue(matchIDs.contains("t340"))
    }

    // MARK: - Songs Without BPM Excluded

    func testSongsWithoutCachedBPMAreExcluded() {
        let bpmMap: [String: Int] = ["t170": 170] // trackNoBPM not in map
        let tracks = [track170, trackNoBPM]

        engine.loadForTesting(tracks: tracks, bpmMap: bpmMap)
        engine.tolerance = .normal

        let matches = engine.findMatchingTracks(forSPM: 170)
        XCTAssertEqual(matches.count, 1)
        XCTAssertEqual(matches.first?.id, "t170")
    }

    // MARK: - Empty Playlist

    func testEmptyPlaylistReturnsEmptyMatches() {
        engine.loadForTesting(tracks: [], bpmMap: [:])
        let matches = engine.findMatchingTracks(forSPM: 170)
        XCTAssertTrue(matches.isEmpty)
    }

    // MARK: - Fallback to Closest BPM

    func testFallbackToClosestBPM() {
        // No songs match 170 SPM within tolerance, but 200 BPM is closest
        let bpmMap: [String: Int] = ["t200": 200, "t120": 120]
        let tracks = [track200, track120]

        engine.loadForTesting(tracks: tracks, bpmMap: bpmMap)
        engine.tolerance = .tight // +/-3 -> very narrow, no matches at 170

        let matches = engine.findMatchingTracks(forSPM: 170)
        XCTAssertTrue(matches.isEmpty, "No direct matches expected")

        let closest = engine.findClosestTrack(forSPM: 170)
        XCTAssertNotNil(closest)
        // 120 BPM is closer to 85 (half of 170) than 200 is to any target
        // targets: 170, 85, 340. dist(120, 85)=35, dist(200, 170)=30 -> 200 is closer
        XCTAssertEqual(closest?.id, "t200")
    }

    func testFallbackNeverReturnsNilIfPlaylistHasBPMData() {
        let bpmMap: [String: Int] = ["t120": 120]
        let tracks = [track120]

        engine.loadForTesting(tracks: tracks, bpmMap: bpmMap)
        engine.tolerance = .tight

        let closest = engine.findClosestTrack(forSPM: 170)
        XCTAssertNotNil(closest)
    }

    // MARK: - No-Repeat Pool

    func testSelectNextMatchMarksTrackAsPlayed() {
        let bpmMap: [String: Int] = ["t170": 170]
        let tracks = [track170]

        engine.loadForTesting(tracks: tracks, bpmMap: bpmMap)
        engine.tolerance = .normal

        let selected = engine.selectNextMatch(forSPM: 170)
        XCTAssertNotNil(selected)
        XCTAssertEqual(selected?.id, "t170")

        // Second selection: pool exhausted, should reset and return again
        let second = engine.selectNextMatch(forSPM: 170)
        XCTAssertNotNil(second)
    }

    func testAlreadyPlayedTracksAreExcludedUntilPoolResets() {
        let bpmMap: [String: Int] = ["t170": 170, "t85": 85]
        let tracks = [track170, track85]

        engine.loadForTesting(tracks: tracks, bpmMap: bpmMap)
        engine.tolerance = .normal

        // At 170 SPM, both match (170 direct, 85 half)
        let first = engine.selectNextMatch(forSPM: 170)
        XCTAssertNotNil(first)

        let second = engine.selectNextMatch(forSPM: 170)
        XCTAssertNotNil(second)
        XCTAssertNotEqual(first?.id, second?.id, "Second pick should be the other track")

        // Third: pool exhausted -> reset -> both available again
        let third = engine.selectNextMatch(forSPM: 170)
        XCTAssertNotNil(third)
    }

    // MARK: - Sustained Change Detection

    func testSPMChangeWithinToleranceDoesNotTriggerRematch() {
        engine.tolerance = .normal // +/-7
        engine.setSustainedSPMForTesting(170)

        // Change within tolerance (170 -> 175, delta 5 < range 7)
        let needsRematch = engine.evaluateCadenceChange(newSPM: 175)
        XCTAssertFalse(needsRematch, "Change within tolerance should not trigger rematch")
    }

    func testSPMChangeOutsideToleranceStartsDebounce() {
        engine.tolerance = .normal // +/-7
        engine.setSustainedSPMForTesting(170)

        // Change outside tolerance (170 -> 185, delta 15 > range 7)
        let needsRematch = engine.evaluateCadenceChange(newSPM: 185)
        XCTAssertTrue(needsRematch, "Change outside tolerance should start debounce")
    }

    // MARK: - Run Lifecycle

    func testStopRunResetsAllState() {
        let bpmMap: [String: Int] = ["t170": 170]
        let tracks = [track170]

        engine.loadForTesting(tracks: tracks, bpmMap: bpmMap)
        _ = engine.selectNextMatch(forSPM: 170)

        engine.stopRun()

        XCTAssertFalse(engine.isRunActive)
        XCTAssertNil(engine.currentMatchedTrack)
    }

    // MARK: - Guided Mode

    func testGuidedModeUsesTargetBPM() {
        // Track at 170 BPM, runner at 120 SPM -- guided mode should match at 170 (target), not 120
        let track150 = SpotifyTrack(
            id: "t150", name: "Song 150", uri: "spotify:track:t150",
            durationMs: 200_000, artists: [Artist(name: "A")],
            album: Album(name: "Album", images: nil)
        )
        let bpmMap: [String: Int] = ["t170": 170, "t150": 150]
        let tracks = [track170, track150]

        engine.loadForTesting(tracks: tracks, bpmMap: bpmMap)
        engine.tolerance = .normal // +/-7
        engine.setRunModeForTesting(.guided, targetBPM: 170)
        engine.setRampPhaseForTesting(.atPace, songsPlayed: 0)
        engine.setSustainedSPMForTesting(120)

        // In guided mode at-pace with target 170, effectiveBPM should be 170
        let selected = engine.selectNextMatch(forSPM: engine.effectiveBPM)
        XCTAssertNotNil(selected)
        XCTAssertEqual(selected?.id, "t170", "Guided mode should select based on target BPM (170), not runner cadence (120)")
    }

    // MARK: - Warm-Up Ramp

    func testWarmUpRampProgression() {
        engine.setRunModeForTesting(.guided, targetBPM: 180)
        engine.setRampPhaseForTesting(.warmUp, songsPlayed: 0)

        // Start: 140 + 0*8 = 140
        XCTAssertEqual(engine.effectiveBPM, 140, "Warm-up starts at 140")

        engine.setRampPhaseForTesting(.warmUp, songsPlayed: 1)
        XCTAssertEqual(engine.effectiveBPM, 148, "After 1 song: 140 + 1*8 = 148")

        engine.setRampPhaseForTesting(.warmUp, songsPlayed: 2)
        XCTAssertEqual(engine.effectiveBPM, 156, "After 2 songs: 140 + 2*8 = 156")

        engine.setRampPhaseForTesting(.warmUp, songsPlayed: 3)
        XCTAssertEqual(engine.effectiveBPM, 164, "After 3 songs: 140 + 3*8 = 164")
    }

    // MARK: - Cool-Down Ramp

    func testCoolDownRampProgression() {
        engine.setRunModeForTesting(.guided, targetBPM: 180)
        engine.setRampPhaseForTesting(.coolDown, songsPlayed: 0)

        // Start: 180 - 0*8 = 180
        XCTAssertEqual(engine.effectiveBPM, 180, "Cool-down starts at target BPM")

        engine.setRampPhaseForTesting(.coolDown, songsPlayed: 1)
        XCTAssertEqual(engine.effectiveBPM, 172, "After 1 song: 180 - 1*8 = 172")

        engine.setRampPhaseForTesting(.coolDown, songsPlayed: 2)
        XCTAssertEqual(engine.effectiveBPM, 164, "After 2 songs: 180 - 2*8 = 164")
    }

    // MARK: - Ramp Clamping

    func testRampClampsToTarget() {
        engine.setRunModeForTesting(.guided, targetBPM: 175)
        engine.setRampPhaseForTesting(.warmUp, songsPlayed: 5)

        // 140 + 5*8 = 180, but should clamp to target 175
        XCTAssertEqual(engine.effectiveBPM, 175, "Warm-up should clamp at target BPM, not overshoot")
    }

    func testCoolDownClampsAtWarmUpBPM() {
        engine.setRunModeForTesting(.guided, targetBPM: 160)
        engine.setRampPhaseForTesting(.coolDown, songsPlayed: 5)

        // 160 - 5*8 = 120, but should clamp at 140
        XCTAssertEqual(engine.effectiveBPM, 140, "Cool-down should clamp at 140, not go below")
    }

    // MARK: - Smart Selection (Danceability)

    func testSmartSelectionRanksByDanceability() {
        let trackHigh = SpotifyTrack(
            id: "tHigh", name: "High Dance", uri: "spotify:track:tHigh",
            durationMs: 200_000, artists: [Artist(name: "A")],
            album: Album(name: "Album", images: nil)
        )
        let trackLow = SpotifyTrack(
            id: "tLow", name: "Low Dance", uri: "spotify:track:tLow",
            durationMs: 200_000, artists: [Artist(name: "A")],
            album: Album(name: "Album", images: nil)
        )
        let bpmMap: [String: Int] = ["tHigh": 170, "tLow": 170]
        let danceMap: [String: Int] = ["tHigh": 90, "tLow": 20]

        engine.loadForTesting(tracks: [trackHigh, trackLow], bpmMap: bpmMap)
        engine.setDanceabilityMapForTesting(danceMap)
        engine.tolerance = .normal

        // preferHighEnergy = true (free run or guided at-pace): should prefer tHigh
        engine.setRunModeForTesting(.free, targetBPM: 160)

        // Run multiple selections to verify bias
        var highCount = 0
        for _ in 0..<20 {
            engine.loadForTesting(tracks: [trackHigh, trackLow], bpmMap: bpmMap)
            engine.setDanceabilityMapForTesting(danceMap)
            if let selected = engine.selectNextMatch(forSPM: 170) {
                if selected.id == "tHigh" { highCount += 1 }
            }
        }
        XCTAssertGreaterThan(highCount, 10, "With preferHighEnergy=true, high danceability track should be selected more often")
    }

    func testSmartSelectionLowDanceabilityForRamp() {
        let trackHigh = SpotifyTrack(
            id: "tHigh", name: "High Dance", uri: "spotify:track:tHigh",
            durationMs: 200_000, artists: [Artist(name: "A")],
            album: Album(name: "Album", images: nil)
        )
        let trackLow = SpotifyTrack(
            id: "tLow", name: "Low Dance", uri: "spotify:track:tLow",
            durationMs: 200_000, artists: [Artist(name: "A")],
            album: Album(name: "Album", images: nil)
        )
        let bpmMap: [String: Int] = ["tHigh": 170, "tLow": 170]
        let danceMap: [String: Int] = ["tHigh": 90, "tLow": 20]

        engine.loadForTesting(tracks: [trackHigh, trackLow], bpmMap: bpmMap)
        engine.setDanceabilityMapForTesting(danceMap)
        engine.tolerance = .normal
        engine.setRunModeForTesting(.guided, targetBPM: 170)
        engine.setRampPhaseForTesting(.warmUp, songsPlayed: 0)

        // preferHighEnergy = false (warm-up phase): should prefer tLow
        var lowCount = 0
        for _ in 0..<20 {
            engine.loadForTesting(tracks: [trackHigh, trackLow], bpmMap: bpmMap)
            engine.setDanceabilityMapForTesting(danceMap)
            engine.setRunModeForTesting(.guided, targetBPM: 170)
            engine.setRampPhaseForTesting(.warmUp, songsPlayed: 0)
            if let selected = engine.selectNextMatch(forSPM: 170) {
                if selected.id == "tLow" { lowCount += 1 }
            }
        }
        XCTAssertGreaterThan(lowCount, 10, "With preferHighEnergy=false (warm-up), low danceability track should be selected more often")
    }

    func testMissingDanceabilityFallback() {
        let trackWithDance = SpotifyTrack(
            id: "tWith", name: "Has Dance", uri: "spotify:track:tWith",
            durationMs: 200_000, artists: [Artist(name: "A")],
            album: Album(name: "Album", images: nil)
        )
        let trackNoDance = SpotifyTrack(
            id: "tNo", name: "No Dance", uri: "spotify:track:tNo",
            durationMs: 200_000, artists: [Artist(name: "A")],
            album: Album(name: "Album", images: nil)
        )
        let bpmMap: [String: Int] = ["tWith": 170, "tNo": 170]
        // Only tWith has danceability data, tNo is missing (should default to 50)
        let danceMap: [String: Int] = ["tWith": 50]

        engine.loadForTesting(tracks: [trackWithDance, trackNoDance], bpmMap: bpmMap)
        engine.setDanceabilityMapForTesting(danceMap)
        engine.tolerance = .normal

        // Both should be selectable -- missing danceability defaults to 50 (same as tWith)
        let selected = engine.selectNextMatch(forSPM: 170)
        XCTAssertNotNil(selected, "Should still select a track even when danceability data is missing")
    }

    // MARK: - Discovery Flag

    func testDiscoveryFlagSetWhenPoolLow() {
        // Only 2 tracks match -- less than 3 threshold
        let bpmMap: [String: Int] = ["t170": 170, "t85": 85]
        let tracks = [track170, track85]

        engine.loadForTesting(tracks: tracks, bpmMap: bpmMap)
        engine.tolerance = .normal

        _ = engine.selectNextMatch(forSPM: 170)

        // After selection with < 3 matches, needsDiscovery should be true
        XCTAssertTrue(engine.needsDiscovery, "Discovery flag should be set when pool has fewer than 3 matches")
    }
}
