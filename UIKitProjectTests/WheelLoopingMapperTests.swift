import XCTest
@testable import UIKitProject

final class WheelLoopingMapperTests: XCTestCase {
    private let mapper = WheelLoopingMapper(itemsPerCycle: 24, cycleCount: 9)

    func testVirtualIndexStartsInMiddleCycle() {
        XCTAssertEqual(mapper.totalItemCount, 216)
        XCTAssertEqual(mapper.virtualIndex(forBaseIndex: 5), 101)
    }

    func testRecenteringPreservesFractionalProgressNearStart() throws {
        let progress = try XCTUnwrap(mapper.recenteredProgressIfNeeded(29.25))

        XCTAssertEqual(progress, 101.25, accuracy: 0.001)
    }

    func testRecenteringPreservesFractionalProgressNearEnd() throws {
        let progress = try XCTUnwrap(mapper.recenteredProgressIfNeeded(175.75))

        XCTAssertEqual(progress, 103.75, accuracy: 0.001)
    }

    func testProgressInMiddleCyclesDoesNotRecenter() {
        XCTAssertNil(mapper.recenteredProgressIfNeeded(110.5))
    }
}
