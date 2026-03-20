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
}
