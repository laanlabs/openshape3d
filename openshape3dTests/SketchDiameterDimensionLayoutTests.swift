import XCTest
@testable import openshape3d

final class SketchDiameterDimensionLayoutTests: XCTestCase {
    func testRoomyDiameterKeepsOriginalLeaderAndCenterClearance() throws {
        let bounds = CGRect(x: 96, y: 140, width: 744, height: 1000)
        for clearance: CGFloat in [20, 60] {
            let layout = try XCTUnwrap(SketchDiameterDimensionLayout.make(
                start: CGPoint(x: 400, y: 500), end: CGPoint(x: 600, y: 500),
                anchor: CGPoint(x: 550, y: 500), clearance: clearance,
                available: bounds, textWidth: 80))
            XCTAssertEqual(layout.start, CGPoint(x: 400, y: 500))
            XCTAssertEqual(layout.tail, CGPoint(x: 600, y: 500))
            XCTAssertEqual(layout.anchor, CGPoint(x: 550, y: 500 - clearance))
        }
    }

    func testManualAnchorRotatesLeaderWithoutChangingDiameter() throws {
        for point in [CGPoint(x: 250, y: 300), CGPoint(x: 650, y: 650)] {
            let layout = try XCTUnwrap(SketchDiameterDimensionLayout.make(
                start: CGPoint(x: 400, y: 500), end: CGPoint(x: 600, y: 500),
                anchor: CGPoint(x: 550, y: 500), clearance: 20,
                available: CGRect(x: 96, y: 140, width: 744, height: 1000),
                textWidth: 80, manualAnchor: point))
            XCTAssertEqual(hypot(layout.end.x - layout.start.x, layout.end.y - layout.start.y), 200, accuracy: 0.001)
            XCTAssertEqual((layout.start.x + layout.end.x) / 2, 500, accuracy: 0.001)
            XCTAssertEqual((layout.start.y + layout.end.y) / 2, 500, accuracy: 0.001)
            XCTAssertGreaterThan(hypot(layout.tail.x - 500, layout.tail.y - 500), 100)
            XCTAssertGreaterThanOrEqual(layout.targetSize.width, 44)
            XCTAssertGreaterThanOrEqual(layout.targetSize.height, 44)
        }
    }

    func testObliqueProjectionRetainsRealProjectedRimPoints() throws {
        let start = CGPoint(x: 780, y: 500), end = CGPoint(x: 900, y: 520)
        let layout = try XCTUnwrap(SketchDiameterDimensionLayout.make(
            start: start, end: end, anchor: CGPoint(x: 870, y: 515), clearance: 20,
            available: CGRect(x: 96, y: 140, width: 744, height: 1000),
            textWidth: 100, allowVertical: false))
        XCTAssertEqual(layout.start, start)
        XCTAssertEqual(layout.end, end)
        XCTAssertEqual(layout.tail, end)
    }

    func testSideChromeKeepsFullRotatedTargetInsideAndDiameterThroughCenter() throws {
        let bounds = CGRect(x: 96, y: 140, width: 744, height: 1000)
        for x: CGFloat in [105, 820] {
            for y: CGFloat in [240, 950] {
                let layout = try XCTUnwrap(SketchDiameterDimensionLayout.make(
                    start: CGPoint(x: x - 60, y: y), end: CGPoint(x: x + 60, y: y),
                    anchor: CGPoint(x: x + 30, y: y), clearance: 20,
                    available: bounds, textWidth: 100))
                XCTAssertEqual(layout.rotation, .pi / 2)
                XCTAssertTrue(bounds.contains(CGRect(x: layout.anchor.x - 22,
                    y: layout.anchor.y - 50, width: 44, height: 100)))
                XCTAssertEqual((layout.start.y + layout.end.y) / 2, y)
                XCTAssertEqual(abs(layout.start.y - layout.end.y), 120)
                XCTAssertEqual(layout.start.x, x)
                XCTAssertEqual(layout.end.x, x)
                XCTAssertGreaterThan(abs(layout.tail.y - y), 60)
            }
        }
    }
}
