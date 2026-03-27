import XCTest
@testable import BeatStep

final class CollapsiblePlayerTests: XCTestCase {

    private let expandedHeight: CGFloat = 64  // ComponentSize.miniPlayerHeight
    private let collapsedHeight: CGFloat = 20 // ComponentSize.miniPlayerCollapsedHeight
    private let threshold: CGFloat = 40

    // MARK: - expandProgress

    func testExpandProgressFullyExpanded() {
        let progress = CollapsiblePlayerView.computeExpandProgress(
            currentHeight: expandedHeight,
            collapsedHeight: collapsedHeight,
            expandedHeight: expandedHeight
        )
        XCTAssertEqual(progress, 1.0, accuracy: 0.001)
    }

    func testExpandProgressFullyCollapsed() {
        let progress = CollapsiblePlayerView.computeExpandProgress(
            currentHeight: collapsedHeight,
            collapsedHeight: collapsedHeight,
            expandedHeight: expandedHeight
        )
        XCTAssertEqual(progress, 0.0, accuracy: 0.001)
    }

    func testExpandProgressMidpoint() {
        let midHeight = (expandedHeight + collapsedHeight) / 2  // 42
        let progress = CollapsiblePlayerView.computeExpandProgress(
            currentHeight: midHeight,
            collapsedHeight: collapsedHeight,
            expandedHeight: expandedHeight
        )
        XCTAssertEqual(progress, 0.5, accuracy: 0.001)
    }

    func testExpandProgressEqualHeightsReturnsZero() {
        let progress = CollapsiblePlayerView.computeExpandProgress(
            currentHeight: 50,
            collapsedHeight: 50,
            expandedHeight: 50
        )
        XCTAssertEqual(progress, 0.0)
    }

    // MARK: - shouldToggle

    func testShouldToggleAboveThreshold() {
        XCTAssertTrue(CollapsiblePlayerView.shouldToggle(dragDistance: 41, threshold: threshold))
    }

    func testShouldToggleBelowThreshold() {
        XCTAssertFalse(CollapsiblePlayerView.shouldToggle(dragDistance: 39, threshold: threshold))
    }

    func testShouldToggleExactThresholdReturnsFalse() {
        XCTAssertFalse(CollapsiblePlayerView.shouldToggle(dragDistance: 40, threshold: threshold))
    }

    func testShouldToggleNegativeDistance() {
        XCTAssertTrue(CollapsiblePlayerView.shouldToggle(dragDistance: -41, threshold: threshold))
    }

    // MARK: - computeCurrentHeight

    func testCurrentHeightExpandedNoDrag() {
        let height = CollapsiblePlayerView.computeCurrentHeight(
            baseHeight: expandedHeight,
            dragOffset: 0,
            isCollapsed: false,
            collapsedHeight: collapsedHeight,
            expandedHeight: expandedHeight
        )
        XCTAssertEqual(height, expandedHeight)
    }

    func testCurrentHeightClampedToCollapsed() {
        let height = CollapsiblePlayerView.computeCurrentHeight(
            baseHeight: expandedHeight,
            dragOffset: -100,
            isCollapsed: false,
            collapsedHeight: collapsedHeight,
            expandedHeight: expandedHeight
        )
        XCTAssertEqual(height, collapsedHeight)
    }

    func testCurrentHeightClampedToExpanded() {
        let height = CollapsiblePlayerView.computeCurrentHeight(
            baseHeight: collapsedHeight,
            dragOffset: -100,
            isCollapsed: true,
            collapsedHeight: collapsedHeight,
            expandedHeight: expandedHeight
        )
        XCTAssertEqual(height, expandedHeight)
    }
}
