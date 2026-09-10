import XCTest
import simd
@testable import openshape3d

final class RectangleConstructionTests: XCTestCase {
    func testRectangleCenterLockAllowsSymmetricSizingButRejectsTranslation() throws {
        let id = UUID(), lo = SIMD2<Double>(2, 3), hi = SIMD2<Double>(20, 15)
        var sketch = Sketch(plane: .ground, entities: [.rect(id: id, min: lo, max: hi)])
        sketch.rectangleSizingAnchors[id] = .minMin
        sketch.constraints = [.init(kind: .fixed, refs: [.init(entityID: id, role: .center)])]
        let dimension = sizeDimension(id, .horizontal, 9)
        sketch.dimensions = [dimension]
        let result = SketchSolverBridge.solveDimensionEdit(sketch, dimension: dimension)
        XCTAssertTrue(result.converged)
        XCTAssertLessThan(result.structuralResidual, 1e-5)
        guard case let .rect(_, a, b) = result.entities[0] else { return XCTFail() }
        XCTAssertLessThan(simd_distance((a + b) / 2, (lo + hi) / 2), 1e-5)
        XCTAssertEqual(b.x - a.x, 9, accuracy: 1e-5)
        XCTAssertEqual(b.y - a.y, 12, accuracy: 1e-5)
        sketch.entities = result.entities
        let blocked = try XCTUnwrap(SketchSolverBridge.solveAxisRectangleTranslation(
            sketch, id: id, delta: SIMD2(4, 2)))
        XCTAssertEqual(blocked, sketch.entities)
        let decoded = try JSONDecoder().decode(Sketch.self, from: JSONEncoder().encode(sketch))
        XCTAssertEqual(decoded.constraints, sketch.constraints)
    }

    func testRectangleCenterTranslationPreservesSizeAndSavedConnections() throws {
        let id = UUID(), lineID = UUID()
        let lo = SIMD2<Double>(2, 3), hi = SIMD2<Double>(12, 9), delta = SIMD2<Double>(4, -2)
        let rectangle = SketchEntity.rect(id: id, min: lo, max: hi)
        for driven in [false, true] {
            var sketch = Sketch(plane: .ground, entities: [rectangle])
            if driven { sketch.dimensions = [sizeDimension(id, .horizontal, 10), sizeDimension(id, .vertical, 6)] }
            let moved = try XCTUnwrap(SketchSolverBridge.solveAxisRectangleTranslation(sketch, id: id, delta: delta))
            guard case let .rect(_, a, b) = moved[0] else { return XCTFail() }
            XCTAssertLessThan(simd_distance(a, lo + delta), 1e-5)
            XCTAssertLessThan(simd_distance(b, hi + delta), 1e-5)
            sketch.constraints = [.init(kind: .fixed, refs: [.init(entityID: id, role: .endpointA)])]
            let pinned = try XCTUnwrap(SketchSolverBridge.solveAxisRectangleTranslation(sketch, id: id, delta: delta))
            XCTAssertEqual(pinned, sketch.entities, "Refused translation must not create numerical history noise")
            guard case let .rect(_, p, q) = pinned[0] else { return XCTFail() }
            XCTAssertLessThan(simd_distance(p, lo), 1e-5)
            XCTAssertLessThan(simd_distance(q, hi), 1e-5)
        }
        var connected = Sketch(plane: .ground, entities: [rectangle,
            .line(id: lineID, a: lo, b: SIMD2(-4, 3))])
        connected.constraints = [.init(kind: .coincident, refs: [
            .init(entityID: id, role: .endpointA), .init(entityID: lineID, role: .endpointA)])]
        let moved = try XCTUnwrap(SketchSolverBridge.solveAxisRectangleTranslation(connected, id: id, delta: delta))
        guard case let .rect(_, a, b) = moved[0], case let .line(_, start, _) = moved[1] else { return XCTFail() }
        XCTAssertLessThan(simd_distance(start, a), 1e-5)
        XCTAssertLessThan(simd_distance(b - a, hi - lo), 1e-5)
        XCTAssertEqual(connected.constraints.count, 1, "temporary size equations must not be persisted")
        XCTAssertTrue(connected.dimensions.isEmpty)
    }

    func testFreshLineDimensionStartPreferenceAndSavedEndLockFallback() throws {
        for direction in [SIMD2<Double>(40, 0), SIMD2(-40, 0), SIMD2(0, 40), SIMD2(0, -40)] {
            for lockEnd in [false, true] {
                let id = UUID(), start = SIMD2<Double>(7, 9), end = SIMD2<Double>(7, 9) + direction
                var sketch = Sketch(plane: .ground, entities: [.line(id: id, a: start, b: end)])
                sketch.constraints = [.init(kind: direction.y == 0 ? .horizontal : .vertical,
                    refs: [.init(entityID: id, role: .whole)])]
                if lockEnd { sketch.constraints.append(.init(kind: .fixed, refs: [.init(entityID: id, role: .endpointB)])) }
                let originalConstraints = sketch.constraints
                let dimension = SketchDimension(kind: .distance,
                    refs: [.init(entityID: id, role: .endpointA), .init(entityID: id, role: .endpointB)], value: 20)
                sketch.dimensions = [dimension]
                let outcome = SketchSolverBridge.solveDimensionEdit(sketch, dimension: dimension,
                    preservingPoint: .init(entityID: id, role: .endpointA))
                XCTAssertTrue(outcome.converged)
                XCTAssertLessThan(outcome.structuralResidual, 1e-5)
                guard case let .line(resultID, a, b) = outcome.entities[0] else { return XCTFail() }
                XCTAssertEqual(resultID, id)
                XCTAssertLessThan(simd_distance(lockEnd ? b : a, lockEnd ? end : start), 1e-5)
                XCTAssertEqual(simd_distance(a, b), 20, accuracy: 1e-5)
                XCTAssertLessThan(simd_distance(b - a, direction / 2), 1e-5)
                XCTAssertEqual(sketch.constraints, originalConstraints, "Preference must not persist a Lock")
            }
        }
    }

    func testAxisSideLocksPersistAndAllowOnlyOppositeEdgeResize() throws {
        let id = UUID(), rectangle = SketchEntity.rect(id: id, min: SIMD2(2, 3), max: SIMD2(12, 9))
        let legacy = Data("{\"entityID\":\"\(id.uuidString)\",\"role\":\"whole\"}".utf8)
        XCTAssertNil(try JSONDecoder().decode(ConstraintRef.self, from: legacy).rectangleEdge)
        for edge in 0..<4 {
            var sketch = Sketch(plane: .ground, entities: [rectangle])
            sketch.constraints = [.init(kind: .fixed, refs: [.init(entityID: id, role: .whole, rectangleEdge: edge)])]
            sketch = try JSONDecoder().decode(Sketch.self, from: JSONEncoder().encode(sketch))
            XCTAssertEqual(sketch.constraints[0].refs[0].rectangleEdge, edge)
            let states = SketchSolverBridge.pointStates(sketch)
            let pinnedRole: PointRole = edge == 0 || edge == 3 ? .endpointA : .endpointB
            let freeRole: PointRole = pinnedRole == .endpointA ? .endpointB : .endpointA
            XCTAssertEqual(states[SketchPointKey(entityID: id, role: pinnedRole)], .locked)
            XCTAssertEqual(states[SketchPointKey(entityID: id, role: freeRole)], .free)
            let original = try XCTUnwrap(RectangleConstruction.axisEdge(rectangle, index: edge))
            XCTAssertEqual(SketchSolverBridge.solveAxisRectangleEdge(sketch, id: id, edge: edge, delta: 2), sketch.entities)
            let opposite = (edge + 2) % 4
            let resized = try XCTUnwrap(SketchSolverBridge.solveAxisRectangleEdge(sketch, id: id, edge: opposite, delta: 2))
            let locked = try XCTUnwrap(RectangleConstruction.axisEdge(resized[0], index: edge))
            let moving = try XCTUnwrap(RectangleConstruction.axisEdge(resized[0], index: opposite))
            let before = try XCTUnwrap(RectangleConstruction.axisEdge(rectangle, index: opposite))
            XCTAssertLessThan(simd_distance(locked.a, original.a), 1e-5)
            XCTAssertLessThan(simd_distance(locked.b, original.b), 1e-5)
            XCTAssertLessThan(simd_distance(moving.a, before.a + before.normal * 2), 1e-5)
            XCTAssertLessThan(simd_distance(moving.b, before.b + before.normal * 2), 1e-5)
            sketch.dimensions = [sizeDimension(id, edge % 2 == 0 ? .vertical : .horizontal, edge % 2 == 0 ? 6 : 10)]
            let driven = try XCTUnwrap(SketchSolverBridge.solveAxisRectangleEdge(sketch, id: id, edge: opposite, delta: 2))
            guard case let .rect(_, a, b) = driven[0] else { return XCTFail() }
            XCTAssertLessThan(simd_distance(a, SIMD2(2, 3)), 1e-5)
            XCTAssertLessThan(simd_distance(b, SIMD2(12, 9)), 1e-5)
        }
    }

    func testAxisEdgeResizeAndDrivenTranslationRespectSavedLock() throws {
        let id = UUID(), lo = SIMD2<Double>(2, 3), hi = SIMD2<Double>(12, 9)
        let rectangle = SketchEntity.rect(id: id, min: lo, max: hi)
        for edge in 0..<4 {
            let geometry = try XCTUnwrap(RectangleConstruction.axisEdge(rectangle, index: edge))
            XCTAssertEqual(RectangleConstruction.nearestAxisEdge(rectangle, to: (geometry.a + geometry.b) / 2), edge)
            for driven in [false, true] {
                var sketch = Sketch(plane: .ground, entities: [rectangle])
                if driven {
                    sketch.dimensions = [sizeDimension(id, edge % 2 == 0 ? .vertical : .horizontal,
                                                      edge % 2 == 0 ? 6 : 10)]
                }
                let result = try XCTUnwrap(SketchSolverBridge.solveAxisRectangleEdge(sketch, id: id, edge: edge, delta: 2))
                guard case let .rect(_, a, b) = result[0] else { return XCTFail() }
                let shift = geometry.normal * 2
                let expectedLo = driven || edge == 0 || edge == 3 ? lo + shift : lo
                let expectedHi = driven || edge == 1 || edge == 2 ? hi + shift : hi
                XCTAssertLessThan(simd_distance(a, expectedLo), 1e-5)
                XCTAssertLessThan(simd_distance(b, expectedHi), 1e-5)
                sketch.constraints = [.init(kind: .fixed, refs: [.init(entityID: id, role: .whole)])]
                XCTAssertEqual(SketchSolverBridge.solveAxisRectangleEdge(sketch, id: id, edge: edge, delta: 2), sketch.entities)
            }
        }
    }

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

    func testReselectedThreePointBaselinePreservesLeftSide() throws {
        let ids = (0..<4).map { _ in UUID() }
        let edges = RectangleConstruction.threePoint(a: SIMD2(1, 2), b: SIMD2(5, 3),
            heightPoint: SIMD2(4, 7), ids: ids)
        let loaded = try JSONDecoder().decode([SketchEntity].self, from: JSONEncoder().encode(edges))
        XCTAssertEqual(RectangleConstruction.dimensionEdges(containing: ids[0], in: loaded), ids)
        let branch = SketchEntity.line(id: UUID(), a: SIMD2(1, 2), b: SIMD2(-4, 2))
        XCTAssertNil(RectangleConstruction.dimensionEdges(containing: ids[0], in: loaded + [branch]))
        let dimension = SketchDimension(kind: .distance, refs: [
            .init(entityID: ids[0], role: .endpointA), .init(entityID: ids[0], role: .endpointB)], value: 2)
        let sketch = Sketch(plane: .ground, entities: loaded,
            constraints: RectangleConstruction.constraints(for: loaded), dimensions: [dimension])
        let outcome = SketchSolverBridge.solveDimensionEdit(sketch, dimension: dimension,
            preservingLineID: ids[3])
        XCTAssertTrue(outcome.converged)
        XCTAssertLessThan(outcome.structuralResidual, 1e-5)
        XCTAssertEqual(outcome.entities[3], loaded[3])
        guard case let .line(_, a, b) = outcome.entities[0] else { return XCTFail() }
        XCTAssertEqual(simd_length(b - a), 2, accuracy: 1e-5)
        XCTAssertEqual(simd_normalize(b - a).x, 4 / sqrt(17), accuracy: 1e-5)
    }

    func testBaselineAnchorPreservesLowerSideAcrossSlopesDirectionsAndReload() throws {
        for slope in [-1.0, 1.0] {
            for reversed in [false, true] {
                for height in [-1.0, 1.0] {
                    let ids = (0..<4).map { _ in UUID() }
                    let left = SIMD2<Double>(1, 2), right = SIMD2<Double>(5, 2 + slope)
                    let a = reversed ? right : left, b = reversed ? left : right
                    let delta = b - a
                    let edges = RectangleConstruction.threePoint(a: a, b: b,
                        heightPoint: b + SIMD2(-delta.y, delta.x) * height, ids: ids)
                    let loaded = try JSONDecoder().decode([SketchEntity].self,
                        from: JSONEncoder().encode(edges))
                    let expected = (slope > 0) == reversed ? ids[1] : ids[3]
                    for editedID in [ids[0], ids[2]] {
                        let anchor = try XCTUnwrap(RectangleConstruction.baselineAnchor(
                            containing: editedID, in: loaded))
                        XCTAssertEqual(anchor, expected)
                        let dim = sizeDimension(editedID, .distance, 2)
                        let sketch = Sketch(plane: .ground, entities: loaded,
                            constraints: RectangleConstruction.constraints(for: loaded), dimensions: [dim])
                        let result = SketchSolverBridge.solveDimensionEdit(sketch,
                            dimension: dim, preservingLineID: anchor)
                        XCTAssertTrue(result.converged)
                        XCTAssertLessThan(result.structuralResidual, 1e-5)
                        XCTAssertEqual(result.entities.first { $0.id == anchor },
                                       loaded.first { $0.id == anchor })
                        let base = endpoints(result.entities[0])
                        XCTAssertEqual(simd_length(base.1 - base.0), 2, accuracy: 1e-5)
                        XCTAssertEqual(simd_normalize(base.1 - base.0).x,
                                       simd_normalize(delta).x, accuracy: 1e-5)
                    }
                }
            }
        }
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

    func testShortLineInteriorRemainsSelectableWithoutStealingExactPoints() throws {
        for scale in [0.001, 0.01, 0.1] {
            let ids = (0..<4).map { _ in UUID() }
            let edges = RectangleConstruction.threePoint(a: .zero,
                b: SIMD2(160 * scale, 0), heightPoint: SIMD2(160 * scale, 40 * scale), ids: ids)
            let middle = SIMD2(160 * scale, 20 * scale)
            let tolerance = SketchHitTester.screenControlPointTolerance(worldUnitsPerPoint: scale)
            XCTAssertNil(SketchHitTester.nearestPoint(to: middle, in: edges,
                tolerance: tolerance, preservingLineInterior: true))
            XCTAssertEqual(SketchHitTester.nearestEntity(to: middle, in: edges,
                tolerance: tolerance)?.entity.id, ids[1])
            XCTAssertNotNil(SketchHitTester.nearestPoint(to: SIMD2(160 * scale, 2 * scale),
                in: edges, tolerance: tolerance, preservingLineInterior: true))
            let pointEntity = SketchEntity.circle(id: UUID(), center: middle, radius: scale)
            XCTAssertEqual(SketchHitTester.nearestPoint(to: middle, in: edges + [pointEntity],
                tolerance: tolerance, preservingLineInterior: true)?.entityID, pointEntity.id)
        }
    }

    func testLineGizmoTransformKeepsRectangleClosedAndSavedLocksFixed() throws {
        let ids = (0..<4).map { _ in UUID() }
        let edges = RectangleConstruction.threePoint(a: SIMD2(1, 2), b: SIMD2(5, 3),
            heightPoint: SIMD2(4, 7), ids: ids)
        var sketch = Sketch(plane: .ground, entities: edges,
            constraints: RectangleConstruction.constraints(for: edges))
        let moved = SketchTransform.translate(entities: [edges[0]], by: SIMD2(0.5, -2))
        let solved = try XCTUnwrap(SketchSolverBridge.solveLineTransform(sketch, targets: moved))
        XCTAssertNotEqual(solved, edges)
        for index in 0..<4 {
            XCTAssertLessThan(simd_distance(endpoints(solved[index]).1,
                endpoints(solved[(index + 1) % 4]).0), 1e-5)
        }
        var resultSketch = sketch
        resultSketch.entities = solved
        XCTAssertLessThan(SketchSolverBridge.residualNorm(resultSketch), 1e-5)
        let center = (endpoints(solved[0]).0 + endpoints(solved[2]).0) / 2
        XCTAssertEqual(ProfileDetector.profiles(at: center, in: resultSketch).count, 1)
        sketch.constraints.append(SketchConstraint(kind: .fixed,
            refs: [.init(entityID: ids[0], role: .whole)]))
        let locked = try XCTUnwrap(SketchSolverBridge.solveLineTransform(sketch, targets: moved))
        XCTAssertEqual(locked[0], edges[0], "Transform must not relocate the saved lock baseline")
    }

    func testLineGizmoRotationPreservesHorizontalConstraintAndHistorySnapshot() throws {
        let id = UUID(), line = SketchEntity.line(id: id, a: .zero, b: SIMD2(4, 0))
        let sketch = Sketch(plane: .ground, entities: [line], constraints: [
            SketchConstraint(kind: .horizontal, refs: [.init(entityID: id, role: .whole)])])
        let targets = SketchTransform.rotate(entities: [line], about: SIMD2(2, 0), angle: .pi / 6)
        let solved = try XCTUnwrap(SketchSolverBridge.solveLineTransform(sketch, targets: targets))
        let pair = endpoints(solved[0])
        XCTAssertEqual(pair.0.y, pair.1.y, accuracy: 1e-5)
        var document = DesignDocument()
        document.sketches = [sketch]
        let command = UpdateSketchEntitiesCommand(sketchID: sketch.id, before: [line], after: solved)
        command.apply(to: &document)
        command.revert(in: &document)
        XCTAssertEqual(document.sketches[0].entities, [line])
        XCTAssertEqual(document.sketches[0].constraints, sketch.constraints)
    }

    func testRectangleNormalTransformHoldsOppositeEdgeAndDrivingSizes() throws {
        let ids = (0..<4).map { _ in UUID() }
        let edges = RectangleConstruction.threePoint(a: .zero, b: SIMD2(4, 1),
            heightPoint: SIMD2(3, 5), ids: ids)
        let delta = simd_normalize(SIMD2<Double>(1, -4)) * 0.5
        let targets = SketchTransform.translate(entities: [edges[0]], by: delta)
        var sketch = Sketch(plane: .ground, entities: edges,
            constraints: RectangleConstruction.constraints(for: edges))
        let solved = try XCTUnwrap(SketchSolverBridge.solveLineTransform(sketch,
            targets: targets, preservingLineID: ids[2]))
        XCTAssertEqual(solved[2], edges[2])
        XCTAssertLessThan(simd_distance(endpoints(solved[0]).0, delta), 1e-5)
        sketch.dimensions = [sizeDimension(ids[1], .distance, sqrt(17))]
        let blocked = try XCTUnwrap(SketchSolverBridge.solveLineTransform(sketch,
            targets: targets, preservingLineID: ids[2]))
        XCTAssertLessThan(simd_distance(endpoints(blocked[0]).0, .zero), 1e-5)
        XCTAssertEqual(blocked[2], edges[2])
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

    func testDiagonalSizingPreservesLowerLeftInAllQuadrantsAfterReload() throws {
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
                    XCTAssertEqual(mn.x, lo.x, accuracy: 1e-6)
                    XCTAssertEqual(mn.y, lo.y, accuracy: 1e-6)
                    XCTAssertEqual(kind == .horizontal ? mx.x-mn.x : mx.y-mn.y, value, accuracy: 1e-5)
                }
            }
        }
    }

    func testCenterAndLegacySizingKeepExistingCenterBehavior() throws {
        for anchor in [nil, .center, .centerMinMin, .centerMinMax, .centerMaxMin,
                       .centerMaxMax] as [RectangleSizingAnchor?] {
            let id = UUID()
            var sketch = Sketch(plane: .ground,
                entities: [.rect(id: id, min: SIMD2(2, 4), max: SIMD2(22, 16))],
                rectangleSizingAnchors: anchor.map { [id: $0] } ?? [:])
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
        XCTAssertEqual(hi.x, 155, accuracy: 1e-5)
        XCTAssertEqual(lo.x, 150, accuracy: 1e-6)
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
