import XCTest
@testable import openshape3d

final class SketchLinearDimensionLayoutTests: XCTestCase {
    func testVerticalLeaderAndTextStayLeftDespiteProjectionNoiseAndReversal() throws {
        for drift in [-0.01, 0, 0.01] {
            let a = CGPoint(x: 350, y: 249)
            let b = CGPoint(x: 350 + drift, y: 450)
            for (start, end) in [(a, b), (b, a)] {
                let layout = try XCTUnwrap(SketchLinearDimensionLayout.make(start: start, end: end))
                XCTAssertEqual(layout.start.x, start.x - 60, accuracy: 0.001)
                XCTAssertEqual(layout.end.x, end.x - 60, accuracy: 0.001)
                XCTAssertLessThan(layout.anchor.x, min(layout.start.x, layout.end.x))
                XCTAssertEqual(layout.rotation, -.pi / 2, accuracy: 0.0001)
            }
        }
    }

    func testHorizontalLeaderStaysBelowAndTextAboveItInEitherStrokeDirection() throws {
        let a = CGPoint(x: 200, y: 350), b = CGPoint(x: 400, y: 350)
        for (start, end) in [(a, b), (b, a)] {
            let layout = try XCTUnwrap(SketchLinearDimensionLayout.make(start: start, end: end))
            XCTAssertEqual(layout.start.y, 410)
            XCTAssertEqual(layout.end.y, 410)
            XCTAssertEqual(layout.anchor, CGPoint(x: 300, y: 390))
            XCTAssertEqual(layout.rotation, 0)
        }
    }

    func testRotatedRectangleLeadersPointAwayFromInteriorInEitherDirection() throws {
        let a = CGPoint(x: 400, y: 450), b = CGPoint(x: 550, y: 490)
        for interior in [CGPoint(x: 450, y: 520), CGPoint(x: 480, y: 390)] {
            for (start, end) in [(a, b), (b, a)] {
                let layout = try XCTUnwrap(SketchLinearDimensionLayout.make(
                    start: start, end: end, leaderOffset: 100, awayFrom: interior))
                let mx = (a.x + b.x) / 2, my = (a.y + b.y) / 2
                let ox = layout.start.x - start.x, oy = layout.start.y - start.y
                XCTAssertEqual(hypot(ox, oy), 100, accuracy: 0.001)
                XCTAssertGreaterThan(ox * (mx - interior.x) + oy * (my - interior.y), 0)
                XCTAssertEqual(ox * (b.x - a.x) + oy * (b.y - a.y), 0, accuracy: 0.001)
            }
        }
    }

    func testDegenerateProjectionDoesNotCreateInvalidLeader() {
        XCTAssertNil(SketchLinearDimensionLayout.make(start: .zero, end: .zero))
    }
}
