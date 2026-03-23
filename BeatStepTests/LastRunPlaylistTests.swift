import XCTest
@testable import BeatStep

final class LastRunPlaylistTests: XCTestCase {
    private let testName = "Test Playlist"
    private let testID = "spotify:playlist:abc123"
    private let testImageURL = "https://i.scdn.co/image/test"

    override func tearDown() {
        // Clean up test values from UserDefaults
        LastRunPlaylist.name = nil
        LastRunPlaylist.id = nil
        LastRunPlaylist.imageURL = nil
        super.tearDown()
    }

    func testNamePersistsViaUserDefaults() {
        LastRunPlaylist.name = testName
        XCTAssertEqual(LastRunPlaylist.name, testName)
    }

    func testIDPersistsViaUserDefaults() {
        LastRunPlaylist.id = testID
        XCTAssertEqual(LastRunPlaylist.id, testID)
    }

    func testImageURLPersistsViaUserDefaults() {
        LastRunPlaylist.imageURL = testImageURL
        XCTAssertEqual(LastRunPlaylist.imageURL, testImageURL)
    }

    func testAllPropertiesReturnNilWhenNothingStored() {
        // tearDown clears values, so after clearing they should be nil
        LastRunPlaylist.name = nil
        LastRunPlaylist.id = nil
        LastRunPlaylist.imageURL = nil
        XCTAssertNil(LastRunPlaylist.name)
        XCTAssertNil(LastRunPlaylist.id)
        XCTAssertNil(LastRunPlaylist.imageURL)
    }
}
