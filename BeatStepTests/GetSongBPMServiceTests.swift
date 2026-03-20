import XCTest
@testable import BeatStep

final class GetSongBPMServiceTests: XCTestCase {

    private let decoder = JSONDecoder()
    private var service: GetSongBPMService!

    override func setUp() {
        super.setUp()
        service = GetSongBPMService()
    }

    // MARK: - Response Decoding

    func testSearchResponseDecoding() throws {
        let response = try decoder.decode(GetSongBPMSearchResponse.self, from: MockGetSongBPMResponses.searchSuccess)
        XCTAssertEqual(response.search.count, 2)
        XCTAssertEqual(response.search[0].id, "abc123")
        XCTAssertEqual(response.search[0].title, "Run Boy Run")
    }

    func testSongResponseWithTempo() throws {
        let response = try decoder.decode(GetSongBPMSongResponse.self, from: MockGetSongBPMResponses.songSuccess)
        XCTAssertEqual(response.song.tempo, "172")
        XCTAssertNotNil(Int(response.song.tempo!))
    }

    func testSongResponseWithoutTempo() throws {
        let response = try decoder.decode(GetSongBPMSongResponse.self, from: MockGetSongBPMResponses.songNoTempo)
        // Empty string tempo should not parse to Int
        let bpm = response.song.tempo.flatMap { $0.isEmpty ? nil : Int($0) }
        XCTAssertNil(bpm)
    }

    func testTempoResponseDecoding() throws {
        let response = try decoder.decode(GetSongBPMTempoResponse.self, from: MockGetSongBPMResponses.tempoSuccess)
        XCTAssertEqual(response.tempo.count, 3)
    }

    // MARK: - Title Sanitization

    func testSanitizeRemastered() {
        XCTAssertEqual(service.sanitizeTitle("Stronger - Remastered 2024"), "Stronger")
        XCTAssertEqual(service.sanitizeTitle("Stronger - Remastered"), "Stronger")
    }

    func testSanitizeFeaturing() {
        XCTAssertEqual(service.sanitizeTitle("Stronger (feat. Kanye West)"), "Stronger")
        XCTAssertEqual(service.sanitizeTitle("Stronger [feat. Kanye West]"), "Stronger")
    }

    func testSanitizeLive() {
        XCTAssertEqual(service.sanitizeTitle("Stronger - Live"), "Stronger")
        XCTAssertEqual(service.sanitizeTitle("Stronger - Live Version"), "Stronger")
    }

    func testSanitizeDeluxe() {
        XCTAssertEqual(service.sanitizeTitle("Stronger [Deluxe]"), "Stronger")
        XCTAssertEqual(service.sanitizeTitle("Stronger [Deluxe Edition]"), "Stronger")
    }

    func testSanitizeCleanTitle() {
        XCTAssertEqual(service.sanitizeTitle("Run Boy Run"), "Run Boy Run")
    }

    func testSanitizeMultipleSuffixes() {
        XCTAssertEqual(service.sanitizeTitle("Song (feat. Artist) - Remastered 2024"), "Song")
    }
}
