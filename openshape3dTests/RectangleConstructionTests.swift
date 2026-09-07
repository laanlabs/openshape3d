import XCTest
import simd
@testable import openshape3d

final class RectangleConstructionTests: XCTestCase {
    func testCenterRectangleReflectsCornerInEveryQuadrant() throws {
        let center = SIMD2<Double>(4, -2)
        for dx in [-3.0, 3.0] {
            for dy in [-5.0, 5.0] {
                guard case let .rect(_, lo, hi)? = RectangleConstruction.axisAligned(
                    from: center, to: center + SIMD2(dx, dy), centered: true) else {
                    return XCTFail("Expected a rectangle")
                }
                XCTAssertEqual((lo + hi) / 2, center)
                XCTAssertEqual(hi - lo, SIMD2(6, 10))
            }
        }
    }

    func testZoomedSmallProfileInteriorRemainsExtrudableNotAnOutlinePick() {
        let sketch = Sketch(plane: .ground, entities: [
            .rect(id: UUID(), min: .zero, max: SIMD2(0.2, 0.2))])
        let ray = Ray(origin: SIMD3(0.1, 1, -0.1), direction: SIMD3(0, -1, 0))
        let tolerance = SketchHitTester.screenPickTolerance(worldUnitsPerPoint: 0.001)
        XCTAssertNil(SketchHitTester.nearestEntity(along: ray, in: [sketch], tolerance: tolerance))
    }

    func testShortLineMiddleSelectsEntityNotEndpointAcrossZoomLevels() {
        for scale in [0.001, 0.01, 0.1] {
            let id = UUID()
            let line = SketchEntity.line(id: id, a: .zero, b: SIMD2(200 * scale, 0))
            let middle = SIMD2(100 * scale, 2 * scale)
            XCTAssertNil(SketchHitTester.nearestPoint(to: middle, in: [line],
                tolerance: SketchHitTester.screenControlPointTolerance(worldUnitsPerPoint: scale)))
            XCTAssertEqual(SketchHitTester.nearestEntity(to: middle, in: [line],
                tolerance: SketchHitTester.screenPickTolerance(worldUnitsPerPoint: scale))?.entity.id, id)
        }
    }

    func testDiagonalUsesOppositeCornersAndRejectsFlatShapes() {
        let id = UUID()
        XCTAssertEqual(RectangleConstruction.axisAligned(from: SIMD2(6, 1), to: SIMD2(2, 8),
            centered: false, id: id), .rect(id: id, min: SIMD2(2, 1), max: SIMD2(6, 8)))
        XCTAssertNil(RectangleConstruction.axisAligned(from: .zero, to: SIMD2(0, 4), centered: true))
    }

    private func rotated(height: Double = 3) -> [SketchEntity] {
        RectangleConstruction.threePoint(a: .zero, b: SIMD2(6, 8),
            heightPoint: SIMD2(6, 8) + SIMD2(-0.8, 0.6) * height + SIMD2(0.6, 0.8) * 7,
            ids: (0..<4).map { _ in UUID() })
    }

    private func endpoints(_ e: SketchEntity) -> (SIMD2<Double>, SIMD2<Double>) {
        guard case let .line(_, a, b) = e else { fatalError("Expected line") }
        return (a, b)
    }

    func testThreePointProjectsHeightPerpendicularlyOnEitherSide() {
        for height in [-3.0, 3.0] {
            let edges = rotated(height: height)
            XCTAssertEqual(edges.count, 4)
            let (a, b) = endpoints(edges[0]), (c, d) = endpoints(edges[1])
            XCTAssertEqual(b, c)
            XCTAssertEqual(simd_length(b - a), 10, accuracy: 1e-9)
            XCTAssertEqual(simd_length(d - c), 3, accuracy: 1e-9)
            XCTAssertEqual(simd_dot(b - a, d - c), 0, accuracy: 1e-9)
            for i in 0..<4 { XCTAssertEqual(endpoints(edges[i]).1, endpoints(edges[(i+1)%4]).0) }
            let sketch = Sketch(plane: .ground, entities: edges)
            XCTAssertEqual(ProfileDetector.profiles(at: (a + d) / 2, in: sketch).count, 1)
        }
    }

    func testDegenerateBaselineAndHeightProduceNoGeometry() {
        let ids = (0..<4).map { _ in UUID() }
        XCTAssertTrue(RectangleConstruction.threePoint(a: .zero, b: .zero,
            heightPoint: SIMD2(1, 2), ids: ids).isEmpty)
        XCTAssertTrue(RectangleConstruction.threePoint(a: .zero, b: SIMD2(6, 8),
            heightPoint: SIMD2(12, 16), ids: ids).isEmpty)
    }

    func testRotatedRectangleRemainsClosedAndRectangularAfterDimensionSolve() throws {
        let edges = rotated()
        var sketch = Sketch(plane: .ground, entities: edges,
                            constraints: RectangleConstruction.constraints(for: edges))
        sketch.dimensions = [SketchDimension(kind: .distance, refs: [
            .init(entityID: edges[0].id, role: .endpointA),
            .init(entityID: edges[0].id, role: .endpointB)], value: 12)]
        let (solved, _) = SketchSolverBridge.solve(sketch, movingEntity: nil, dragTarget: nil)
        XCTAssertEqual(solved.count, 4)
        let (a, b) = endpoints(solved[0]), (c, d) = endpoints(solved[1])
        XCTAssertEqual(simd_length(b-a), 12, accuracy: 1e-5)
        XCTAssertEqual(simd_dot(b-a, d-c), 0, accuracy: 1e-5)
        for i in 0..<4 {
            XCTAssertLessThan(simd_length(endpoints(solved[i]).1 - endpoints(solved[(i+1)%4]).0), 1e-5)
        }
        sketch.entities = solved
        XCTAssertLessThan(SketchSolverBridge.residualNorm(sketch), 1e-5)
        let restored = try JSONDecoder().decode(Sketch.self, from: JSONEncoder().encode(sketch))
        XCTAssertEqual(restored.entities, sketch.entities)
        XCTAssertEqual(restored.constraints, sketch.constraints)
        XCTAssertEqual(ProfileDetector.profiles(at: (a+d)/2, in: restored).count, 1)
    }
}
