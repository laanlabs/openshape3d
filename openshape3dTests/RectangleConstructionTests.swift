import XCTest
import simd
@testable import openshape3d

final class RectangleConstructionTests: XCTestCase {
    func testDimensionEdgesRecognizeReloadedReversedRectangleButRejectOtherSelections() throws {
        let ids = (0..<4).map { _ in UUID() }
        let edges = RectangleConstruction.threePoint(a: SIMD2(1, 2), b: SIMD2(5, 3),
                                                     heightPoint: SIMD2(4, 7), ids: ids)
        let loaded = try JSONDecoder().decode([SketchEntity].self, from: JSONEncoder().encode(edges))
        func reverse(_ edge: SketchEntity) -> SketchEntity {
            guard case let .line(id, a, b) = edge else { return edge }
            return .line(id: id, a: b, b: a)
        }
        let pair = try XCTUnwrap(RectangleConstruction.dimensionEdges(
            in: [loaded[0], reverse(loaded[2]), reverse(loaded[3]), loaded[1]]))
        XCTAssertEqual(pair, ids)
        XCTAssertNil(RectangleConstruction.dimensionEdges(in: Array(loaded.prefix(3))))
        let trapezoid: [SketchEntity] = [
            .line(id: ids[0], a: .zero, b: SIMD2(4, 0)),
            .line(id: ids[1], a: SIMD2(4, 0), b: SIMD2(3, 2)),
            .line(id: ids[2], a: SIMD2(3, 2), b: SIMD2(0, 2)),
            .line(id: ids[3], a: SIMD2(0, 2), b: .zero)]
        XCTAssertNil(RectangleConstruction.dimensionEdges(in: trapezoid))
    }

    func testThreePointHeightPreservesFarEdgeAndUndrivenLength() throws {
        for height in [-1.0, 1.0] {
            let ids = (0..<4).map { _ in UUID() }
            let edges = RectangleConstruction.threePoint(a: SIMD2(1, 2), b: SIMD2(5, 3),
                heightPoint: SIMD2(5, 3) + SIMD2(-1, 4) * height, ids: ids)
            let dimension = SketchDimension(kind: .distance, refs: [
                .init(entityID: ids[1], role: .endpointA),
                .init(entityID: ids[1], role: .endpointB)], value: 0.5)
            var sketch = Sketch(plane: .ground, entities: edges,
                constraints: RectangleConstruction.constraints(for: edges), dimensions: [dimension])
            let outcome = SketchSolverBridge.solveDimensionEdit(sketch, dimension: dimension,
                preservingLineID: ids[2])
            XCTAssertTrue(outcome.converged)
            XCTAssertLessThan(outcome.structuralResidual, 1e-5)
            XCTAssertEqual(outcome.entities[2], edges[2], "Far baseline must remain fixed")
            guard case let .line(_, a, b) = outcome.entities[0],
                  case let .line(_, c, d) = outcome.entities[1] else { return XCTFail() }
            XCTAssertEqual(simd_length(b - a), sqrt(17), accuracy: 1e-5)
            XCTAssertEqual(simd_length(d - c), 0.5, accuracy: 1e-5)
            XCTAssertEqual(simd_normalize(b - a).x, 4 / sqrt(17), accuracy: 1e-5)
            // Explicitly fixing the original baseline makes the far-edge
            // preference impossible. The existing lock wins, no fake lock saved.
            sketch.constraints.append(SketchConstraint(kind: .fixed,
                refs: [.init(entityID: ids[0], role: .whole)]))
            let fallback = SketchSolverBridge.solveDimensionEdit(sketch, dimension: dimension,
                preservingLineID: ids[2])
            XCTAssertTrue(fallback.converged)
            XCTAssertLessThan(fallback.structuralResidual, 1e-5)
            XCTAssertEqual(fallback.entities[0], edges[0])
            XCTAssertEqual(sketch.constraints.count, 8)
        }
    }

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
    private func sizeDimension(_ id: UUID, _ kind: DimensionKind, _ value: Double) -> SketchDimension {
        SketchDimension(kind: kind, refs: [.init(entityID: id, role: .endpointA),
            .init(entityID: id, role: .endpointB)], value: value)
    }

    func testDiagonalSizingPreservesFirstCornerInAllQuadrantsAfterReload() throws {
        for dx in [-20.0, 20.0] {
            for dy in [-12.0, 12.0] {
                let first = SIMD2<Double>(7, -3), id = UUID()
                let entity = try XCTUnwrap(RectangleConstruction.axisAligned(
                    from: first, to: first + SIMD2(dx, dy), centered: false, id: id))
                guard case let .rect(_, lo, _) = entity else { return XCTFail() }
                var sketch = Sketch(plane: .ground, entities: [entity],
                    rectangleSizingAnchors: [id: .diagonal(first: first, min: lo)])
                sketch = try JSONDecoder().decode(Sketch.self, from: JSONEncoder().encode(sketch))
                for (kind, value) in [(DimensionKind.horizontal, 8.0), (.vertical, 5.0), (.horizontal, 30.0)] {
                    let dim = sizeDimension(id, kind, value)
                    sketch.dimensions.removeAll { $0.kind == kind }
                    sketch.dimensions.append(dim)
                    let outcome = SketchSolverBridge.solveDimensionEdit(sketch, dimension: dim)
                    XCTAssertTrue(outcome.converged)
                    XCTAssertLessThan(outcome.structuralResidual, 1e-5)
                    sketch.entities = outcome.entities
                    guard case let .rect(_, mn, mx) = outcome.entities[0] else { return XCTFail() }
                    XCTAssertEqual(dx > 0 ? mn.x : mx.x, first.x, accuracy: 1e-6)
                    XCTAssertEqual(dy > 0 ? mn.y : mx.y, first.y, accuracy: 1e-6)
                    XCTAssertEqual(kind == .horizontal ? mx.x-mn.x : mx.y-mn.y, value, accuracy: 1e-5)
                }
            }
        }
    }

    func testCenterAndLegacySizingKeepExistingCenterBehavior() throws {
        for anchors in [false, true] {
            let id = UUID()
            var sketch = Sketch(plane: .ground,
                entities: [.rect(id: id, min: SIMD2(2, 4), max: SIMD2(22, 16))],
                rectangleSizingAnchors: anchors ? [id: .center] : [:])
            let dim = sizeDimension(id, .horizontal, 8)
            sketch.dimensions = [dim]
            let result = SketchSolverBridge.solveDimensionEdit(sketch, dimension: dim)
            guard case let .rect(_, lo, hi) = result.entities[0] else { return XCTFail() }
            XCTAssertEqual((lo.x+hi.x)/2, 12, accuracy: 1e-5)
            XCTAssertEqual((lo.y+hi.y)/2, 10, accuracy: 1e-5)
            XCTAssertEqual(hi.x-lo.x, 8, accuracy: 1e-5)
        }
        var json = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(
            Sketch(plane: .ground))) as? [String: Any])
        json.removeValue(forKey: "rectangleSizingAnchors")
        let legacy = try JSONDecoder().decode(Sketch.self, from: JSONSerialization.data(withJSONObject: json))
        XCTAssertTrue(legacy.rectangleSizingAnchors.isEmpty)
    }

    func testAnchorInsertionUndoRedoAndTranslatedSizing() throws {
        let id = UUID(), sketch = Sketch(plane: .ground)
        let entity = SketchEntity.rect(id: id, min: SIMD2(50, 60), max: SIMD2(70, 72))
        let command = AddSketchEntityCommand(sketchID: sketch.id, entity: entity,
                                            rectangleSizingAnchor: .maxMin)
        var document = DesignDocument()
        document.sketches = [sketch]
        command.apply(to: &document)
        XCTAssertEqual(document.sketches[0].rectangleSizingAnchors[id], .maxMin)
        command.revert(in: &document)
        XCTAssertTrue(document.sketches[0].rectangleSizingAnchors.isEmpty)
        XCTAssertTrue(document.sketches[0].entities.isEmpty)
        command.apply(to: &document)
        var moved = document.sketches[0]
        moved.entities = [.rect(id: id, min: SIMD2(150, 160), max: SIMD2(170, 172))]
        let dim = sizeDimension(id, .horizontal, 5)
        moved.dimensions = [dim]
        let result = SketchSolverBridge.solveDimensionEdit(moved, dimension: dim)
        guard case let .rect(_, lo, hi) = result.entities[0] else { return XCTFail() }
        XCTAssertEqual(hi.x, 170, accuracy: 1e-6)
        XCTAssertEqual(lo.x, 165, accuracy: 1e-5)
        XCTAssertEqual(lo.y, 160, accuracy: 1e-6)
        XCTAssertEqual(SketchSolverBridge.solve(moved, movingEntity: nil, dragTarget: nil).entities.count, 1)
    }

    func testExplicitLockWinsOverCreationAnchorWithoutBreakingDimension() {
        let id = UUID()
        let dim = sizeDimension(id, .horizontal, 8)
        let sketch = Sketch(plane: .ground,
            entities: [.rect(id: id, min: .zero, max: SIMD2(20, 12))],
            constraints: [SketchConstraint(kind: .fixed, refs: [.init(entityID: id, role: .endpointB)])],
            dimensions: [dim], rectangleSizingAnchors: [id: .minMin])
        let result = SketchSolverBridge.solveDimensionEdit(sketch, dimension: dim)
        XCTAssertLessThan(result.structuralResidual, 1e-5)
        guard case let .rect(_, lo, hi) = result.entities[0] else { return XCTFail() }
        XCTAssertEqual(hi, SIMD2(20, 12))
        XCTAssertEqual(lo.x, 12, accuracy: 1e-5)
    }

}
