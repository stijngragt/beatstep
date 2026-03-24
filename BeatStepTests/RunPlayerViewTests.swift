import XCTest
@testable import BeatStep

final class RunPlayerViewTests: XCTestCase {

    // MARK: - Helpers

    private func makeImage(url: String = "https://i.scdn.co/image/test", width: Int?, height: Int? = nil) -> SpotifyImage {
        SpotifyImage(url: url, width: width, height: height)
    }

    // MARK: - Album Art URL Selection

    func testAlbumArtURLPrefers300px() {
        let images = [
            makeImage(url: "https://cdn/640", width: 640),
            makeImage(url: "https://cdn/300", width: 300),
            makeImage(url: "https://cdn/64", width: 64),
        ]
        let result = RunPlayerView.selectAlbumArtURL(from: images)
        XCTAssertEqual(result?.absoluteString, "https://cdn/300")
    }

    func testAlbumArtURLNilWhenNoImages() {
        let result = RunPlayerView.selectAlbumArtURL(from: nil)
        XCTAssertNil(result)
    }

    func testAlbumArtURLFallsBackToFirst() {
        let images = [
            makeImage(url: "https://cdn/640", width: 640),
        ]
        let result = RunPlayerView.selectAlbumArtURL(from: images)
        XCTAssertEqual(result?.absoluteString, "https://cdn/640")
    }

    func testAlbumArtURLHandlesEmptyArray() {
        let result = RunPlayerView.selectAlbumArtURL(from: [])
        XCTAssertNil(result)
    }
}
