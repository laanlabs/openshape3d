import XCTest
@testable import openshape3d

final class SketchRadialDragTests: XCTestCase {
    func testFreeRadiusRetainsCenterSweepAndCrossingLineWithoutSavingIntent() throws {
        let arcID = UUID(), lineID = UUID()
        let arc = SketchEntity.arc(id: arcID, center: SIMD2(2, 3), radius: 4,
                                  startAngle: -.pi / 2, endAngle: .pi / 2)
        let line = SketchEntity.line(id: lineID, a: SIMD2(2, -5), b: SIMD2(2, 11))
        let sketch = Sketch(plane: .ground, entities: [arc, line])
        let result = try XCTUnwrap(SketchRadialDrag.solve(sketch, entityID: arcID, radius: 6))
        guard case let .arc(_, center, radius, start, end) = result[0] else { return XCTFail() }
        XCTAssertEqual(center.x, 2, accuracy: 1e-6)
        XCTAssertEqual(center.y, 3, accuracy: 1e-6)
        XCTAssertEqual(radius, 6, accuracy: 1e-5)
        XCTAssertEqual(start, -.pi / 2, accuracy: 1e-6)
        XCTAssertEqual(end, .pi / 2, accuracy: 1e-6)
        XCTAssertEqual(result[1], line)
        XCTAssertTrue(sketch.dimensions.isEmpty)
        XCTAssertTrue(sketch.constraints.isEmpty)
    }

    func testCircleRadialIntentPreservesCenterAndRespectsDiameter() throws {
        let id = UUID()
        let circle = SketchEntity.circle(id: id, center: SIMD2(2, 3), radius: 4)
        var sketch = Sketch(plane: .ground, entities: [circle])
        let result = try XCTUnwrap(SketchRadialDrag.solve(sketch, entityID: id, radius: 6))
        guard case let .circle(_, center, radius) = result[0] else { return XCTFail() }
        XCTAssertEqual(center.x, 2, accuracy: 1e-6)
        XCTAssertEqual(center.y, 3, accuracy: 1e-6)
        XCTAssertEqual(radius, 6, accuracy: 1e-5)
        XCTAssertTrue(sketch.dimensions.isEmpty)
        sketch.dimensions = [SketchDimension(kind: .diameter,
            refs: [.init(entityID: id, role: .whole)], value: 8)]
        XCTAssertNil(SketchRadialDrag.solve(sketch, entityID: id, radius: 6))
        sketch.dimensions = []
        sketch.constraints = [SketchConstraint(kind: .fixed, refs: [.init(entityID: id, role: .whole)])]
        XCTAssertNil(SketchRadialDrag.solve(sketch, entityID: id, radius: 6))
    }

    func testDrivingRadiusAndLockRefuseConflictingDrag() {
        let id = UUID()
        let arc = SketchEntity.arc(id: id, center: .zero, radius: 4, startAngle: 0, endAngle: .pi)
        var sketch = Sketch(plane: .ground, entities: [arc])
        sketch.dimensions = [SketchDimension(kind: .radius, refs: [.init(entityID: id, role: .whole)], value: 4)]
        XCTAssertNil(SketchRadialDrag.solve(sketch, entityID: id, radius: 6))
        sketch.dimensions = []
        sketch.constraints = [SketchConstraint(kind: .fixed, refs: [.init(entityID: id, role: .whole)])]
        XCTAssertNil(SketchRadialDrag.solve(sketch, entityID: id, radius: 6))
        XCTAssertNil(SketchRadialDrag.solve(sketch, entityID: id, radius: .nan))
    }
}
