//
//  ConstraintLifecycleTests.swift
//  openshape3dTests
//
//  The constraint-lifecycle contract (docs/FREECAD_PLAYBOOK.md S1/S2, review
//  R2-2/R2-3): deleting geometry cascades to the constraints and dimensions
//  that referenced it (and undo restores both), trim re-anchors what it can
//  onto the surviving fragments and drops the rest, and a CONFLICTING
//  constraint system is reported by the solver instead of silently written
//  back as a best-fit compromise. Pure-value tests; no DocumentSession.
//

import XCTest
import simd
@testable import openshape3d

final class ConstraintLifecycleTests: XCTestCase {

    // MARK: - Delete cascades (R2-2)

    func testDeleteRemovesConstraintsAndDimensionsWithTheEntity() {
        let lineA = SketchEntity.line(id: UUID(), a: SIMD2(0, 0), b: SIMD2(10, 0))
        let lineB = SketchEntity.line(id: UUID(), a: SIMD2(10, 0), b: SIMD2(10, 8))
        var sketch = Sketch(plane: .ground, entities: [lineA, lineB])
        sketch.constraints = [SketchConstraint(kind: .coincident, refs: [
            ConstraintRef(entityID: lineA.id, role: .endpointB),
            ConstraintRef(entityID: lineB.id, role: .endpointA),
        ])]
        sketch.dimensions = [SketchDimension(kind: .distance, refs: [
            ConstraintRef(entityID: lineA.id, role: .whole),
        ], value: 10)]

        var document = DesignDocument()
        document.sketches = [sketch]
        let command = RemoveSketchEntitiesCommand(ids: [lineA.id], sketch: sketch)
        command.apply(to: &document)

        let after = document.sketches[0]
        XCTAssertEqual(after.entities.map(\.id), [lineB.id])
        XCTAssertTrue(after.constraints.isEmpty,
                      "the coincidence referenced the deleted line — it must go with it")
        XCTAssertTrue(after.dimensions.isEmpty,
                      "a dimension whose entity is gone drives nothing; leaving it "
                      + "displayed a value the solver silently ignored (R2-2)")
        XCTAssertTrue(after.validateConstraintRefs())

        command.revert(in: &document)
        let restored = document.sketches[0]
        XCTAssertEqual(restored.entities.count, 2)
        XCTAssertEqual(restored.constraints.count, 1, "undo restores the constraint too")
        XCTAssertEqual(restored.dimensions.count, 1)
        XCTAssertTrue(restored.validateConstraintRefs())
    }

    // MARK: - Trim re-anchors (R2-2)

    func testTrimReanchorsEndpointConstraintAndDropsWholeDimension() {
        let target = SketchEntity.line(id: UUID(), a: SIMD2(0, 0), b: SIMD2(10, 0))
        let anchor = SketchEntity.line(id: UUID(), a: SIMD2(0, 0), b: SIMD2(0, 5))
        var sketch = Sketch(plane: .ground, entities: [target, anchor])
        // A coincidence at the SURVIVING end (0,0)…
        let coincidence = SketchConstraint(kind: .coincident, refs: [
            ConstraintRef(entityID: target.id, role: .endpointA),
            ConstraintRef(entityID: anchor.id, role: .endpointA),
        ])
        // …and a length dimension on the whole line, which becomes ambiguous
        // once the line is two pieces.
        let length = SketchDimension(kind: .distance, refs: [
            ConstraintRef(entityID: target.id, role: .whole),
        ], value: 10)
        sketch.constraints = [coincidence]
        sketch.dimensions = [length]

        // The trimmed span is (3,0)–(7,0): two fragments survive.
        let fragmentA = SketchEntity.line(id: UUID(), a: SIMD2(0, 0), b: SIMD2(3, 0))
        let fragmentB = SketchEntity.line(id: UUID(), a: SIMD2(7, 0), b: SIMD2(10, 0))
        let command = TrimCommand(
            sketch: sketch, index: 0, removed: target,
            fragments: [fragmentA, fragmentB])

        var document = DesignDocument()
        document.sketches = [sketch]
        command.apply(to: &document)

        let after = document.sketches[0]
        XCTAssertTrue(after.validateConstraintRefs(),
                      "no ref may dangle after a trim")
        XCTAssertEqual(after.constraints.count, 1)
        XCTAssertEqual(after.constraints[0].refs[0].entityID, fragmentA.id,
                       "the (0,0) coincidence re-anchors to the fragment that owns (0,0)")
        XCTAssertTrue(after.dimensions.isEmpty,
                      "a whole-line length can't mean anything across two fragments — "
                      + "dropped visibly, not left dangling")

        command.revert(in: &document)
        let restored = document.sketches[0]
        XCTAssertEqual(restored.constraints[0].refs[0].entityID, target.id)
        XCTAssertEqual(restored.dimensions.count, 1, "undo restores the dropped dimension")
        XCTAssertTrue(restored.validateConstraintRefs())
    }

    func testTrimDropsConstraintOnTheTrimmedAwaySpan() {
        let target = SketchEntity.line(id: UUID(), a: SIMD2(0, 0), b: SIMD2(10, 0))
        var sketch = Sketch(plane: .ground, entities: [target])
        // Constrained at (10,0) — an end that does NOT survive this trim.
        sketch.constraints = [SketchConstraint(kind: .fixed, refs: [
            ConstraintRef(entityID: target.id, role: .endpointB),
        ])]
        let fragment = SketchEntity.line(id: UUID(), a: SIMD2(0, 0), b: SIMD2(4, 0))
        let command = TrimCommand(sketch: sketch, index: 0, removed: target,
                                  fragments: [fragment])
        var document = DesignDocument()
        document.sketches = [sketch]
        command.apply(to: &document)
        XCTAssertTrue(document.sketches[0].constraints.isEmpty,
                      "the constrained point was trimmed away")
        XCTAssertTrue(document.sketches[0].validateConstraintRefs())
    }

    // MARK: - Trim re-anchors, curved fragments

    /// Trimming a circle leaves one arc on the same supporting circle: the
    /// tangency (a `.whole` ref) and the center-anchored concentric both
    /// re-anchor to it instead of dropping.
    func testTrimKeepsTangencyWhenACircleBecomesAnArc() {
        let circle = SketchEntity.circle(id: UUID(), center: SIMD2(0, 0), radius: 5)
        let line = SketchEntity.line(id: UUID(), a: SIMD2(-10, 5), b: SIMD2(10, 5))
        var sketch = Sketch(plane: .ground, entities: [circle, line])
        sketch.constraints = [
            SketchConstraint(kind: .tangent, refs: [
                ConstraintRef(entityID: line.id, role: .whole),
                ConstraintRef(entityID: circle.id, role: .whole),
            ]),
        ]
        // The trimmer turns a circle into ONE arc (the complement of the
        // deleted span).
        let arc = SketchEntity.arc(id: UUID(), center: SIMD2(0, 0), radius: 5,
                                   startAngle: 0.5, endAngle: 6.0)
        let command = TrimCommand(sketch: sketch, index: 0, removed: circle,
                                  fragments: [arc])
        var document = DesignDocument()
        document.sketches = [sketch]
        command.apply(to: &document)
        let after = document.sketches[0]
        XCTAssertEqual(after.constraints.count, 1, "tangency survives the trim")
        XCTAssertEqual(after.constraints[0].refs[1].entityID, arc.id)
        XCTAssertTrue(after.validateConstraintRefs())
    }

    /// An arc split into TWO arcs of the same supporting circle keeps its
    /// radius dimension: center + radius are identical on both fragments, so
    /// the whole-entity statement stays unambiguous (unlike a split line).
    func testTrimReanchorsARadiusDimensionAcrossTwoArcFragments() {
        let arc = SketchEntity.arc(id: UUID(), center: SIMD2(0, 0), radius: 5,
                                   startAngle: 0, endAngle: 3)
        var sketch = Sketch(plane: .ground, entities: [arc])
        sketch.dimensions = [
            SketchDimension(kind: .radius,
                            refs: [ConstraintRef(entityID: arc.id, role: .whole)],
                            value: 5),
        ]
        let fragmentA = SketchEntity.arc(id: UUID(), center: SIMD2(0, 0), radius: 5,
                                         startAngle: 0, endAngle: 1)
        let fragmentB = SketchEntity.arc(id: UUID(), center: SIMD2(0, 0), radius: 5,
                                         startAngle: 2, endAngle: 3)
        let command = TrimCommand(sketch: sketch, index: 0, removed: arc,
                                  fragments: [fragmentA, fragmentB])
        var document = DesignDocument()
        document.sketches = [sketch]
        command.apply(to: &document)
        let after = document.sketches[0]
        XCTAssertEqual(after.dimensions.count, 1, "the radius still means the same thing")
        XCTAssertEqual(after.dimensions[0].refs[0].entityID, fragmentA.id)
        XCTAssertTrue(after.validateConstraintRefs())

        command.revert(in: &document)
        XCTAssertEqual(document.sketches[0].dimensions[0].refs[0].entityID, arc.id)
    }

    /// Mixed fragments (line + arc) stay ambiguous for a `.whole` ref — the
    /// same-circle transfer never fires across different supporting curves.
    func testTrimDropsAWholeRefAcrossMixedFragments() {
        let arc = SketchEntity.arc(id: UUID(), center: SIMD2(0, 0), radius: 5,
                                   startAngle: 0, endAngle: 3)
        var sketch = Sketch(plane: .ground, entities: [arc])
        sketch.dimensions = [
            SketchDimension(kind: .radius,
                            refs: [ConstraintRef(entityID: arc.id, role: .whole)],
                            value: 5),
        ]
        let fragmentA = SketchEntity.arc(id: UUID(), center: SIMD2(0, 0), radius: 5,
                                         startAngle: 0, endAngle: 1)
        let stray = SketchEntity.line(id: UUID(), a: SIMD2(0, 0), b: SIMD2(1, 0))
        let command = TrimCommand(sketch: sketch, index: 0, removed: arc,
                                  fragments: [fragmentA, stray])
        var document = DesignDocument()
        document.sketches = [sketch]
        command.apply(to: &document)
        XCTAssertTrue(document.sketches[0].dimensions.isEmpty)
        XCTAssertTrue(document.sketches[0].validateConstraintRefs())
    }

    /// A rect corner constraint re-anchors onto the exploded line fragment
    /// that owns the corner (sketchPoint now knows rect endpoints).
    func testTrimReanchorsARectCornerOntoItsExplodedLine() {
        let rect = SketchEntity.rect(id: UUID(), min: SIMD2(0, 0), max: SIMD2(10, 5))
        var sketch = Sketch(plane: .ground, entities: [rect])
        sketch.constraints = [
            SketchConstraint(kind: .fixed,
                             refs: [ConstraintRef(entityID: rect.id, role: .endpointA)]),
        ]
        // Exploding a rect trim: line fragments along the boundary; the one
        // that owns the min corner starts there.
        let bottom = SketchEntity.line(id: UUID(), a: SIMD2(0, 0), b: SIMD2(4, 0))
        let left = SketchEntity.line(id: UUID(), a: SIMD2(0, 5), b: SIMD2(0, 0))
        let command = TrimCommand(sketch: sketch, index: 0, removed: rect,
                                  fragments: [bottom, left])
        var document = DesignDocument()
        document.sketches = [sketch]
        command.apply(to: &document)
        let after = document.sketches[0]
        XCTAssertEqual(after.constraints.count, 1, "the corner lock survives")
        XCTAssertEqual(after.constraints[0].refs[0].entityID, bottom.id)
        XCTAssertTrue(after.validateConstraintRefs())
    }

    func testTrimmedProfileDropsOnlyAffectedReferencesAndUndoRestoresEverything() {
        let bottom = SketchEntity.line(id: UUID(), a: SIMD2(0, 0), b: SIMD2(10, 0))
        let right = SketchEntity.line(id: UUID(), a: SIMD2(10, 0), b: SIMD2(10, 6))
        let top = SketchEntity.line(id: UUID(), a: SIMD2(10, 6), b: SIMD2(0, 6))
        let left = SketchEntity.line(id: UUID(), a: SIMD2(0, 6), b: SIMD2(0, 0))
        let cutter = SketchEntity.line(id: UUID(), a: SIMD2(4, -2), b: SIMD2(4, 2))
        let fixedTopRight = SketchConstraint(kind: .fixed, refs: [
            ConstraintRef(entityID: top.id, role: .endpointA),
        ])
        let affectedBottomLength = SketchDimension(kind: .distance, refs: [
            ConstraintRef(entityID: bottom.id, role: .endpointA),
            ConstraintRef(entityID: bottom.id, role: .endpointB),
        ], value: 10)
        let survivingTopLength = SketchDimension(kind: .distance, refs: [
            ConstraintRef(entityID: top.id, role: .endpointA),
            ConstraintRef(entityID: top.id, role: .endpointB),
        ], value: 10)
        let sketch = Sketch(
            plane: .ground,
            entities: [bottom, right, top, left, cutter],
            constructionEntityIDs: [cutter.id],
            constraints: [fixedTopRight],
            dimensions: [affectedBottomLength, survivingTopLength]
        )
        XCTAssertEqual(ProfileDetector.detectProfiles(in: sketch).count, 1)

        let fragment = SketchEntity.line(id: UUID(), a: SIMD2(0, 0), b: SIMD2(4, 0))
        let command = TrimCommand(sketch: sketch, index: 0, removed: bottom,
                                  fragments: [fragment])
        var document = DesignDocument()
        document.sketches = [sketch]
        command.apply(to: &document)

        let open = document.sketches[0]
        XCTAssertTrue(ProfileDetector.detectProfiles(in: open).isEmpty,
                      "removing the far boundary opens the downstream profile")
        XCTAssertEqual(open.constraints, [fixedTopRight])
        XCTAssertEqual(open.dimensions, [survivingTopLength])
        XCTAssertEqual(open.constructionEntityIDs, [cutter.id])
        XCTAssertTrue(open.validateConstraintRefs())

        command.revert(in: &document)
        XCTAssertEqual(document.sketches[0], sketch)
        XCTAssertEqual(ProfileDetector.detectProfiles(in: document.sketches[0]).count, 1)
        XCTAssertTrue(document.sketches[0].validateConstraintRefs())
    }

    // MARK: - Solver conflict reporting (R2-3, docs/FREECAD_PLAYBOOK.md S1)

    func testConflictingDimensionsReportStructuralResidual() {
        let line = SketchEntity.line(id: UUID(), a: SIMD2(0, 0), b: SIMD2(10, 0))
        var sketch = Sketch(plane: .ground, entities: [line])
        // Two driving lengths that cannot both hold: 10 and 20.
        func length(_ value: Double) -> SketchDimension {
            SketchDimension(kind: .distance, refs: [
                ConstraintRef(entityID: line.id, role: .endpointA),
                ConstraintRef(entityID: line.id, role: .endpointB),
            ], value: value)
        }
        sketch.dimensions = [length(10), length(20)]
        let outcome = SketchSolverBridge.solveOutcome(
            sketch, movingEntity: nil, dragTarget: nil)
        XCTAssertGreaterThan(outcome.structuralResidual, 1e-3,
                             "a 10-and-20 length pair is a CONFLICT and must say so — "
                             + "the drag path holds the baseline on this signal")
    }

    func testSatisfiableSystemReportsNoConflict() {
        let line = SketchEntity.line(id: UUID(), a: SIMD2(0, 0), b: SIMD2(9, 0))
        var sketch = Sketch(plane: .ground, entities: [line])
        sketch.dimensions = [
            SketchDimension(kind: .distance, refs: [
                ConstraintRef(entityID: line.id, role: .endpointA),
                ConstraintRef(entityID: line.id, role: .endpointB),
            ], value: 10),
        ]
        let outcome = SketchSolverBridge.solveOutcome(
            sketch, movingEntity: nil, dragTarget: nil)
        XCTAssertLessThanOrEqual(outcome.structuralResidual, 1e-3,
                                 "one satisfiable dimension solves clean")
        XCTAssertTrue(outcome.converged)
    }
}
