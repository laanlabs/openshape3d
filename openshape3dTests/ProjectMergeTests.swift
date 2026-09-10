//
//  ProjectMergeTests.swift
//  openshape3dTests
//
//  Spec §6.5 Insert Project. The point of Insert Project (versus Insert File)
//  is that the inserted work arrives WITH its history and stays editable. So
//  the tests care about two things: the guest's steps show up individually and
//  still evaluate, and no identity from the guest can collide with the host's —
//  the failure mode there is silent and destructive.
//

import XCTest
import simd
@testable import openshape3d

final class ProjectMergeTests: XCTestCase {

    private final class RevisionSource {
        private var value: UInt64 = 0
        func next() -> UInt64 { value += 1; return value }
    }

    /// A one-step project: a box of `size`, built by a feature.
    private func boxProject(size: Double, name: String = "Box") -> DesignDocument {
        var document = DesignDocument()
        let feature = FeatureID(), body = BodyID()
        document.features.nodes.append(FeatureNode(
            id: feature, name: name,
            kind: .primitive(spec: .box(width: size, depth: size, height: size),
                             placement: .identity),
            outputBodyIDs: [body]))
        return document
    }

    /// A two-step project: a box with a cylinder cut out of it.
    private func drilledProject() -> DesignDocument {
        var document = DesignDocument()
        let box = FeatureID(), drill = FeatureID()
        let boxBody = BodyID(), drillBody = BodyID()
        document.features.nodes = [
            FeatureNode(id: box, name: "Box",
                        kind: .primitive(spec: .box(width: 10, depth: 10, height: 10),
                                         placement: .identity),
                        outputBodyIDs: [boxBody]),
            FeatureNode(id: drill, name: "Drill",
                        kind: .primitive(spec: .cylinder(radius: 2, height: 30),
                                         placement: .identity),
                        outputBodyIDs: [drillBody]),
            FeatureNode(id: FeatureID(), name: "Cut",
                        kind: .boolean(kind: .subtract,
                                       target: BodyRef(producer: box, bodyID: boxBody),
                                       tools: [BodyRef(producer: drill, bodyID: drillBody)]),
                        outputBodyIDs: []),
        ]
        return document
    }

    private func evaluate(_ document: DesignDocument) -> EvalResult {
        document.features.evaluate(
            sketches: document.sketches, planes: document.planes,
            naming: SignatureNaming(), nextRevision: RevisionSource().next)
    }

    // MARK: History arrives intact

    func testInsertedStepsAppearIndividuallyInHistory() {
        let host = boxProject(size: 10, name: "Host box")
        let merged = ProjectMergeKit.insert(drilledProject(), into: host).document

        XCTAssertEqual(merged.features.nodes.count, 4, "1 host step + 3 guest steps")
        XCTAssertEqual(merged.features.nodes.map(\.name),
                       ["Host box", "Box", "Drill", "Cut"],
                       "guest steps are appended, in order, individually")
    }

    func testInsertedHistoryStillEvaluates() throws {
        let insertion = ProjectMergeKit.insert(
            drilledProject(), into: boxProject(size: 4), translation: SIMD3(50, 0, 0))
        let result = evaluate(insertion.document)

        XCTAssertTrue(result.errors.isEmpty,
                      "every remapped ref resolved: \(result.errors)")
        // Host's 4-cube plus the guest's drilled 10-box.
        XCTAssertEqual(result.bodies.count, 2)
        let volumes = result.bodies
            .map { MeasureKit.bodyVolume($0.render, scale: 1) }.sorted()
        XCTAssertEqual(volumes[0], 64, accuracy: 1e-6, "the host box is untouched")
        XCTAssertLessThan(volumes[1], 1000, "the guest kept its drilled hole")
    }

    func testInsertedStepsRemainEditable() throws {
        let insertion = ProjectMergeKit.insert(drilledProject(), into: DesignDocument())
        var document = insertion.document

        // Edit the guest's first step — the thing a plain geometry merge loses.
        let target = try XCTUnwrap(insertion.featureIDs.first)
        let index = try XCTUnwrap(document.features.nodes.firstIndex { $0.id == target })
        document.features.nodes[index].kind = .primitive(
            spec: .box(width: 20, depth: 10, height: 10), placement: .identity)

        let body = try XCTUnwrap(evaluate(document).bodies.first)
        XCTAssertEqual(body.render.localAABB.max.x - body.render.localAABB.min.x,
                       20, accuracy: 1e-6,
                       "editing the inserted step rebuilt the inserted geometry")
    }

    // MARK: Identity is re-minted — the silent-corruption case

    func testGuestIdentitiesAreAllReminted() {
        let guest = drilledProject()
        let merged = ProjectMergeKit.insert(guest, into: DesignDocument()).document

        let guestFeatureIDs = Set(guest.features.nodes.map(\.id))
        let mergedFeatureIDs = Set(merged.features.nodes.map(\.id))
        XCTAssertTrue(guestFeatureIDs.isDisjoint(with: mergedFeatureIDs),
                      "no feature keeps its old id")

        let guestBodyIDs = Set(guest.features.nodes.flatMap(\.outputBodyIDs))
        let mergedBodyIDs = Set(merged.features.nodes.flatMap(\.outputBodyIDs))
        XCTAssertTrue(guestBodyIDs.isDisjoint(with: mergedBodyIDs))
    }

    /// The destructive case: host and guest share ids (both from one template).
    func testAnIdenticalCopyInsertedIntoItselfDoesNotCrossWire() throws {
        let host = drilledProject()
        let insertion = ProjectMergeKit.insert(host, into: host,
                                               translation: SIMD3(40, 0, 0))
        let result = evaluate(insertion.document)

        XCTAssertTrue(result.errors.isEmpty, "\(result.errors)")
        XCTAssertEqual(result.bodies.count, 2,
                       "two independent drilled boxes, not one self-referencing mess")
        let volumes = result.bodies.map { MeasureKit.bodyVolume($0.render, scale: 1) }
        // Tessellation of the translated copy differs in the last few digits,
        // so this is a same-shape check, not a bit-identical one.
        XCTAssertEqual(volumes[0], volumes[1], accuracy: 1e-3,
                       "the copy is the same solid as the original")
    }

    func testHostHistoryIsUntouched() {
        let host = boxProject(size: 10, name: "Host box")
        let merged = ProjectMergeKit.insert(drilledProject(), into: host).document
        XCTAssertEqual(merged.features.nodes[0].id, host.features.nodes[0].id,
                       "the host's own step keeps its identity")
        XCTAssertEqual(merged.features.nodes[0].outputBodyIDs,
                       host.features.nodes[0].outputBodyIDs)
        XCTAssertEqual(merged.features.nodes[0].name, host.features.nodes[0].name)
    }

    // MARK: Placement

    func testTranslationOffsetsTheInsertedGeometry() throws {
        let insertion = ProjectMergeKit.insert(
            boxProject(size: 6), into: DesignDocument(), translation: SIMD3(100, 0, 0))
        let body = try XCTUnwrap(evaluate(insertion.document).bodies.first)
        XCTAssertEqual(body.render.localAABB.min.x, 100 - 3, accuracy: 1e-5,
                       "the insert landed 100 away, ready to be moved again")
    }

    func testSketchesAndPlanesComeAcrossWithNewIdentities() {
        var guest = DesignDocument()
        let sketch = Sketch(plane: .ground, entities: [
            .circle(id: UUID(), center: SIMD2(0, 0), radius: 5),
        ])
        guest.sketches = [sketch]
        guest.planes = [ConstructionPlane(plane: .offsetGround(y: 12), size: 100)]

        let merged = ProjectMergeKit.insert(
            guest, into: DesignDocument(), translation: SIMD3(0, 3, 0)).document

        XCTAssertEqual(merged.sketches.count, 1)
        XCTAssertNotEqual(merged.sketches[0].id, sketch.id, "the sketch is re-identified")
        XCTAssertNotEqual(merged.sketches[0].entities[0].id, sketch.entities[0].id)
        XCTAssertEqual(merged.sketches[0].plane.origin.y, 3, accuracy: 1e-9,
                       "the sketch plane moved with the insert")
        XCTAssertEqual(merged.planes[0].plane.origin.y, 15, accuracy: 1e-9)
    }

    func testSketchConstraintsFollowTheirRemappedEntities() {
        let line = UUID()
        var guest = DesignDocument()
        guest.sketches = [Sketch(
            plane: .ground,
            entities: [.line(id: line, a: SIMD2(0, 0), b: SIMD2(10, 0))],
            constraints: [SketchConstraint(
                kind: .horizontal, refs: [ConstraintRef(entityID: line, role: .whole)])])]

        let merged = ProjectMergeKit.insert(guest, into: DesignDocument()).document
        let newLine = merged.sketches[0].entities[0].id
        XCTAssertEqual(merged.sketches[0].constraints[0].refs[0].entityID, newLine,
                       "a constraint pointing at the OLD id would be dead on arrival")
    }

    func testInsertedDimensionRetainsScalarExpressionAndRemapsReferences() {
        let line = UUID()
        var guest = DesignDocument()
        guest.sketches = [Sketch(plane: .ground,
            entities: [.line(id: line, a: .zero, b: SIMD2(15, 0))],
            dimensions: [SketchDimension(kind: .distance,
                refs: [ConstraintRef(entityID: line, role: .endpointA),
                       ConstraintRef(entityID: line, role: .endpointB)],
                value: 15, displayExpression: "(10+5) mm")])]
        let inserted = ProjectMergeKit.insert(guest, into: DesignDocument()).document.sketches[0]
        XCTAssertEqual(inserted.dimensions[0].displayExpression, "(10+5) mm")
        XCTAssertNil(inserted.dimensions[0].formula)
        XCTAssertNotEqual(inserted.entities[0].id, line)
        XCTAssertTrue(inserted.dimensions[0].refs.allSatisfy { $0.entityID == inserted.entities[0].id })
    }

    func testInsertedDisconnectedEndpointDoesNotReweld() throws {
        let a = UUID(), b = UUID()
        var guest = DesignDocument()
        guest.sketches = [Sketch(plane: .ground, entities: [
            .line(id: a, a: SIMD2(0, 0), b: SIMD2(10, 0)),
            .line(id: b, a: SIMD2(10, 0), b: SIMD2(10, 5))],
            disconnectedEndpoints: [.init(entityID: a, role: .endpointB)])]
        let inserted = ProjectMergeKit.insert(guest, into: DesignDocument()).document.sketches[0]
        XCTAssertEqual(inserted.disconnectedEndpoints,
                       [.init(entityID: inserted.entities[0].id, role: .endpointB)])
        XCTAssertTrue(inserted.validateConstraintRefs())
        XCTAssertEqual(SketchSolverBridge.solve(inserted, movingEntity: nil, dragTarget: nil).dof, 8)
    }

    func testInsertedRectangleSideLockKeepsItsScope() throws {
        let id = UUID()
        var guest = DesignDocument()
        guest.sketches = [Sketch(plane: .ground,
            entities: [.rect(id: id, min: SIMD2(0, 0), max: SIMD2(10, 6))],
            constraints: [.init(kind: .fixed, refs: [.init(entityID: id, role: .whole, rectangleEdge: 1)])])]
        let inserted = ProjectMergeKit.insert(guest, into: DesignDocument()).document.sketches[0]
        let newID = inserted.entities[0].id
        XCTAssertNotEqual(newID, id)
        XCTAssertEqual(inserted.constraints[0].refs[0].entityID, newID)
        XCTAssertEqual(inserted.constraints[0].refs[0].rectangleEdge, 1)
        let moved = try XCTUnwrap(SketchSolverBridge.solveAxisRectangleEdge(inserted, id: newID, edge: 3, delta: 2))
        guard case let .rect(_, lo, hi) = moved[0] else { return XCTFail() }
        XCTAssertEqual(lo.x, -2, accuracy: 1e-5)
        XCTAssertEqual(hi.x, 10, accuracy: 1e-5)
        XCTAssertEqual(lo.y, 0, accuracy: 1e-5)
        XCTAssertEqual(hi.y, 6, accuracy: 1e-5)
    }

    // MARK: Variables

    func testGuestVariablesAreBroughtAcross() {
        var guest = DesignDocument()
        guest.variables = [Variable(name: "motorBore", expression: "8", value: 8)]
        let merged = ProjectMergeKit.insert(guest, into: DesignDocument()).document
        XCTAssertEqual(merged.variables.map(\.name), ["motorBore"])
    }

    func testAClashingVariableNameIsReportedRatherThanOverwritten() {
        var host = DesignDocument()
        host.variables = [Variable(name: "width", expression: "10", value: 10)]
        var guest = DesignDocument()
        guest.variables = [Variable(name: "width", expression: "99", value: 99),
                           Variable(name: "depth", expression: "5", value: 5)]

        let merged = ProjectMergeKit.insert(guest, into: host).document
        XCTAssertEqual(merged.variables.count, 2)
        XCTAssertEqual(merged.variables.first { $0.name == "width" }?.value, 10,
                       "the host's variable wins — its formulas depend on it")
        XCTAssertEqual(ProjectMergeKit.droppedVariableNames(inserting: guest, into: host),
                       ["width"], "and the clash is reported, not swallowed")
    }

    // MARK: Rollback

    func testRollbackMarkerExtendsSoInsertedStepsStayActive() {
        var host = boxProject(size: 10)
        host.features.rollbackIndex = 1
        let merged = ProjectMergeKit.insert(drilledProject(), into: host).document
        XCTAssertEqual(merged.features.rollbackIndex, 4,
                       "an unextended marker would leave the insert rolled back")
    }

    func testInsertingAnEmptyProjectChangesNothing() {
        let host = boxProject(size: 10)
        let merged = ProjectMergeKit.insert(DesignDocument(), into: host).document
        XCTAssertEqual(merged.features.nodes.count, host.features.nodes.count)
        XCTAssertEqual(merged.sketches.count, host.sketches.count)
    }
}
