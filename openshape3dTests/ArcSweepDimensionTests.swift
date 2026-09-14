import XCTest
import simd
@testable import openshape3d

final class ArcSweepDimensionTests: XCTestCase {
    func testSweepEditPreservesStartingRayRadiusCenterAndOtherGeometry() throws {
        for start in [Double.pi, -Double.pi / 3] {
            for degrees in [90.0, 180.0, 270.0] {
                let arc = SketchEntity.arc(id: UUID(), center: SIMD2(7, 4), radius: 2,
                                          startAngle: start, endAngle: start + .pi)
                let line = SketchEntity.line(id: UUID(), a: SIMD2(1, 4), b: SIMD2(10, 4))
                var sketch = Sketch(plane: .ground, entities: [arc, line])
                sketch.dimensions = [SketchDimension(kind: .angle,
                    refs: [.init(entityID: arc.id, role: .whole)], value: degrees * .pi / 180)]
                let result = SketchSolverBridge.solveOutcome(sketch, movingEntity: nil, dragTarget: nil)
                XCTAssertLessThan(result.structuralResidual, 1e-6)
                guard case let .arc(_, center, radius, sa, ea) = result.entities[0] else {
                    return XCTFail("Expected arc")
                }
                XCTAssertEqual(center, SIMD2(7, 4)); XCTAssertEqual(radius, 2, accuracy: 1e-8)
                XCTAssertEqual(sa, start)
                XCTAssertEqual(SketchEntity.arcSweep(startAngle: sa, endAngle: ea),
                               degrees * .pi / 180, accuracy: 1e-6)
                XCTAssertEqual(result.entities[1], line)
                sketch.entities = result.entities
                let decoded = try JSONDecoder().decode(Sketch.self, from: JSONEncoder().encode(sketch))
                let reopened = SketchSolverBridge.solve(decoded, movingEntity: nil, dragTarget: nil).0
                XCTAssertEqual(reopened, result.entities)
            }
        }
    }

    func testFullTurnBecomesClosedCircleAndRetargetsOnlyItsDimensions() throws {
        let arc = SketchEntity.arc(id: UUID(), center: SIMD2(7, 4), radius: 2,
                                  startAngle: .pi, endAngle: 3 * .pi)
        let refs = [ConstraintRef(entityID: arc.id, role: .whole)]
        let angle = SketchDimension(kind: .angle, refs: refs, value: .pi)
        let radius = SketchDimension(kind: .radius, refs: refs, value: 2, formula: "base/2")
        let other = SketchDimension(kind: .angle, refs: [.init(entityID: UUID(), role: .whole)], value: 1)
        let conversion = try XCTUnwrap(ArcDimensionConversion.fullCircle(
            from: arc, dimensions: [angle, radius, other]))
        XCTAssertEqual(conversion.circle, .circle(id: arc.id, center: SIMD2(7, 4), radius: 2))
        XCTAssertEqual(conversion.removedAngleIDs, [angle.id])
        let diameter = try XCTUnwrap(conversion.updatedRadiusDimensions.first)
        XCTAssertEqual(diameter.id, radius.id); XCTAssertEqual(diameter.kind, .diameter)
        XCTAssertEqual(diameter.value, 4); XCTAssertEqual(diameter.formula, "(base/2)*2")
        let sketch = Sketch(plane: .ground, entities: [conversion.circle])
        XCTAssertEqual(ProfileDetector.detectProfiles(in: sketch).count, 1)
        let decoded = try JSONDecoder().decode(Sketch.self, from: JSONEncoder().encode(sketch))
        XCTAssertEqual(decoded.entities, sketch.entities)
    }

    func testLockedArcRejectsIncompatibleSweep() {
        let arc = SketchEntity.arc(id: UUID(), center: .zero, radius: 2,
                                  startAngle: .pi, endAngle: 0)
        var sketch = Sketch(plane: .ground, entities: [arc])
        let refs = [ConstraintRef(entityID: arc.id, role: .whole)]
        sketch.constraints = [SketchConstraint(kind: .fixed, refs: refs)]
        sketch.dimensions = [SketchDimension(kind: .angle, refs: refs, value: .pi / 2)]
        let result = SketchSolverBridge.solveOutcome(sketch, movingEntity: nil, dragTarget: nil)
        XCTAssertGreaterThan(result.structuralResidual, 0.1)
        XCTAssertEqual(result.entities, [arc])
    }

    func testUntouchedWrappedArcDoesNotCreateRepresentationOnlyEdit() {
        let arc = SketchEntity.arc(id: UUID(), center: .zero, radius: 2,
                                  startAngle: .pi, endAngle: 0)
        let sketch = Sketch(plane: .ground, entities: [arc])
        let result = SketchSolverBridge.solve(sketch, movingEntity: nil, dragTarget: nil)
        XCTAssertEqual(result.0, [arc])
    }
}
