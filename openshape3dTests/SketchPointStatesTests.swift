//
//  SketchPointStatesTests.swift
//  openshape3dTests
//
//  Coverage for SketchSolverBridge.pointStates (A2): per-point determinacy at
//  (entityID, role) granularity used by the on-canvas DOF markers. Verifies the
//  three states — .free (under-defined), .constrained (fully determined) and
//  .locked (pinned by a .fixed / Lock constraint) — plus that welded coincident
//  points report identical states.
//

import XCTest
import simd
@testable import openshape3d

final class SketchPointStatesTests: XCTestCase {

    func testAxisRectangleCornersUseTheirOwnCoordinateDeterminacy() throws {
        let id = UUID()
        var sketch = Sketch(plane: .ground, entities: [
            .rect(id: id, min: SIMD2(2, 3), max: SIMD2(12, 9))])
        XCTAssertEqual(SketchSolverBridge.pointStateAnalysis(sketch).rectangleCorners[id],
                       [.free, .free, .free, .free])
        sketch.constraints = [.init(kind: .fixed, refs: [.init(entityID: id, role: .whole, rectangleEdge: 3)])]
        XCTAssertEqual(SketchSolverBridge.pointStateAnalysis(sketch).rectangleCorners[id],
                       [.locked, .free, .free, .locked], "Left-side Lock pins both left corners only")
        sketch.constraints = [.init(kind: .fixed, refs: [.init(entityID: id, role: .endpointA)])]
        sketch.dimensions = [.init(kind: .horizontal, refs: [
            .init(entityID: id, role: .endpointA), .init(entityID: id, role: .endpointB)], value: 10)]
        XCTAssertEqual(SketchSolverBridge.pointStateAnalysis(sketch).rectangleCorners[id],
                       [.locked, .constrained, .free, .free], "Width determines the lower-right but not upper corners")
        sketch.constraints = [.init(kind: .fixed, refs: [.init(entityID: id, role: .whole)])]
        XCTAssertEqual(SketchSolverBridge.pointStateAnalysis(sketch).rectangleCorners[id],
                       [.locked, .locked, .locked, .locked])
    }

    private func key(_ id: UUID, _ role: PointRole) -> SketchPointKey {
        SketchPointKey(entityID: id, role: role)
    }

    // MARK: - 1. Free line: both endpoints .free

    func testFreeLineBothEndpointsAreFree() {
        let l = UUID()
        let sketch = Sketch(plane: .ground,
                            entities: [.line(id: l, a: SIMD2(0, 0), b: SIMD2(10, 0))])

        let states = SketchSolverBridge.pointStates(sketch)
        XCTAssertEqual(states[key(l, .endpointA)], .free)
        XCTAssertEqual(states[key(l, .endpointB)], .free)
    }

    // MARK: - 2. Both endpoints .fixed => .locked

    func testLineWithFixedEndpointsIsLocked() {
        let l = UUID()
        var sketch = Sketch(plane: .ground,
                            entities: [.line(id: l, a: SIMD2(0, 0), b: SIMD2(10, 0))])
        sketch.constraints = [
            SketchConstraint(kind: .fixed, refs: [ConstraintRef(entityID: l, role: .endpointA)]),
            SketchConstraint(kind: .fixed, refs: [ConstraintRef(entityID: l, role: .endpointB)]),
        ]

        let states = SketchSolverBridge.pointStates(sketch)
        XCTAssertEqual(states[key(l, .endpointA)], .locked)
        XCTAssertEqual(states[key(l, .endpointB)], .locked)
    }

    // MARK: - 3. Horizontal + coincident + dimensioned => fully determined

    /// Two lines joined at a coincident endpoint, fully constrained: the anchor
    /// corner is .locked, every determined point (including the welded shared
    /// joint) is .constrained, and the two coincident endpoints agree.
    func testHorizontalCoincidentDimensionedLineIsConstrained() {
        let l0 = UUID(), l1 = UUID()
        let entities: [SketchEntity] = [
            .line(id: l0, a: SIMD2(0, 0), b: SIMD2(10, 0)),  // horizontal base
            .line(id: l1, a: SIMD2(10, 0), b: SIMD2(10, 5)), // vertical riser
        ]
        var sketch = Sketch(plane: .ground, entities: entities)
        sketch.constraints = [
            SketchConstraint(kind: .fixed, refs: [ConstraintRef(entityID: l0, role: .endpointA)]),
            SketchConstraint(kind: .horizontal, refs: [ConstraintRef(entityID: l0, role: .whole)]),
            SketchConstraint(kind: .vertical, refs: [ConstraintRef(entityID: l1, role: .whole)]),
            SketchConstraint(kind: .coincident,
                             refs: [ConstraintRef(entityID: l0, role: .endpointB),
                                    ConstraintRef(entityID: l1, role: .endpointA)]),
        ]
        sketch.dimensions = [
            SketchDimension(kind: .distance,
                            refs: [ConstraintRef(entityID: l0, role: .endpointA),
                                   ConstraintRef(entityID: l0, role: .endpointB)],
                            value: 10),
            SketchDimension(kind: .distance,
                            refs: [ConstraintRef(entityID: l1, role: .endpointA),
                                   ConstraintRef(entityID: l1, role: .endpointB)],
                            value: 5),
        ]

        // Fully defined (0 DOF).
        let (_, dof) = SketchSolverBridge.solve(sketch, movingEntity: nil, dragTarget: nil)
        XCTAssertEqual(dof, 0, "fixed + horizontal + vertical + coincident + two lengths is fully defined")

        let states = SketchSolverBridge.pointStates(sketch)
        XCTAssertEqual(states[key(l0, .endpointA)], .locked, "the pinned corner is locked")
        XCTAssertEqual(states[key(l0, .endpointB)], .constrained)
        XCTAssertEqual(states[key(l1, .endpointA)], .constrained)
        XCTAssertEqual(states[key(l1, .endpointB)], .constrained)
        // Welded coincident points must report the SAME state.
        XCTAssertEqual(states[key(l0, .endpointB)], states[key(l1, .endpointA)])
        // Nothing is left free.
        XCTAssertFalse(states.values.contains(.free))
    }

    // MARK: - 4. Fully-defined rectangle: no free points

    /// Four lines welded into a rectangle, anchored + dimensioned. The fixed
    /// corner is .locked; every other corner is .constrained; none are .free.
    func testFullyDefinedRectangleHasNoFreePoints() {
        let l0 = UUID(), l1 = UUID(), l2 = UUID(), l3 = UUID()
        let entities: [SketchEntity] = [
            .line(id: l0, a: SIMD2(0, 0), b: SIMD2(10, 0)),  // bottom
            .line(id: l1, a: SIMD2(10, 0), b: SIMD2(10, 5)), // right
            .line(id: l2, a: SIMD2(10, 5), b: SIMD2(0, 5)),  // top
            .line(id: l3, a: SIMD2(0, 5), b: SIMD2(0, 0)),   // left
        ]
        var sketch = Sketch(plane: .ground, entities: entities)
        sketch.constraints = [
            SketchConstraint(kind: .horizontal, refs: [ConstraintRef(entityID: l0, role: .whole)]),
            SketchConstraint(kind: .horizontal, refs: [ConstraintRef(entityID: l2, role: .whole)]),
            SketchConstraint(kind: .vertical, refs: [ConstraintRef(entityID: l1, role: .whole)]),
            SketchConstraint(kind: .vertical, refs: [ConstraintRef(entityID: l3, role: .whole)]),
            SketchConstraint(kind: .fixed, refs: [ConstraintRef(entityID: l0, role: .endpointA)]),
        ]
        sketch.dimensions = [
            SketchDimension(kind: .distance,
                            refs: [ConstraintRef(entityID: l0, role: .endpointA),
                                   ConstraintRef(entityID: l0, role: .endpointB)],
                            value: 10),
            SketchDimension(kind: .distance,
                            refs: [ConstraintRef(entityID: l3, role: .endpointA),
                                   ConstraintRef(entityID: l3, role: .endpointB)],
                            value: 5),
        ]

        let (_, dof) = SketchSolverBridge.solve(sketch, movingEntity: nil, dragTarget: nil)
        XCTAssertEqual(dof, 0, "a fully constrained rectangle should have zero DOF")

        let states = SketchSolverBridge.pointStates(sketch)

        // No point is left free.
        XCTAssertFalse(states.values.contains(.free), "a fully defined rect has no free points")

        // The anchored corner (l0.endpointA, welded to l3.endpointB) is locked.
        XCTAssertEqual(states[key(l0, .endpointA)], .locked)
        XCTAssertEqual(states[key(l3, .endpointB)], .locked, "welded to the locked corner")

        // The remaining corners are fully constrained.
        XCTAssertEqual(states[key(l0, .endpointB)], .constrained)
        XCTAssertEqual(states[key(l1, .endpointA)], .constrained)
        XCTAssertEqual(states[key(l1, .endpointB)], .constrained)
        XCTAssertEqual(states[key(l2, .endpointA)], .constrained)
        XCTAssertEqual(states[key(l2, .endpointB)], .constrained)
        XCTAssertEqual(states[key(l3, .endpointA)], .constrained)

        // Welded coincident endpoints agree pairwise.
        XCTAssertEqual(states[key(l0, .endpointB)], states[key(l1, .endpointA)])
        XCTAssertEqual(states[key(l1, .endpointB)], states[key(l2, .endpointA)])
        XCTAssertEqual(states[key(l2, .endpointB)], states[key(l3, .endpointA)])
        XCTAssertEqual(states[key(l3, .endpointB)], states[key(l0, .endpointA)])
    }

    // MARK: - 5. Position-locked circle centre with a free radius is .locked

    /// A circle centre welded onto a fixed line endpoint cannot move even though
    /// its radius is undimensioned (free). The `.locked` classification keys on
    /// the point's POSITION variables only — the radius scalar must not dilute
    /// it into a misleading `.free` (blue "movable") marker.
    func testCircleCenterWeldedToFixedPointIsLockedDespiteFreeRadius() {
        let lineID = UUID(), circleID = UUID()
        var sketch = Sketch(plane: .ground, entities: [
            .line(id: lineID, a: SIMD2(0, 0), b: SIMD2(10, 0)),
            .circle(id: circleID, center: SIMD2(0, 0), radius: 3),  // centre on line start
        ])
        sketch.constraints = [
            // Pin the line's start point...
            SketchConstraint(kind: .fixed, refs: [ConstraintRef(entityID: lineID, role: .endpointA)]),
            // ...and weld the circle centre onto it.
            SketchConstraint(kind: .coincident,
                             refs: [ConstraintRef(entityID: circleID, role: .center),
                                    ConstraintRef(entityID: lineID, role: .endpointA)]),
        ]

        let states = SketchSolverBridge.pointStates(sketch)
        XCTAssertEqual(states[key(circleID, .center)], .locked,
                       "a centre welded onto a fixed point is locked even with a free radius")
        // The shared line endpoint reports the same immobility.
        XCTAssertEqual(states[key(lineID, .endpointA)], .locked)
    }
}
