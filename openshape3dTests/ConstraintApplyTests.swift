//
//  ConstraintApplyTests.swift
//  openshape3dTests
//
//  Applying constraints to a sketch selection (plan §C3): the view model
//  builds a SketchConstraint from the selected points/entities, re-solves the
//  sketch, and commits the constraint + moved geometry as ONE undoable step.
//  Also covers the adaptive enable/disable rules and point-role hit testing.
//

import XCTest
import SwiftData
import simd
@testable import openshape3d

@MainActor
final class ConstraintApplyTests: XCTestCase {

    /// MainActor view-model dealloc inside an XCTest invocation crashes the
    /// simulator runtime, so retain them for the process lifetime (mirrors
    /// SelectionUXTests.retainedViewModels).
    private static var retained: [EditorViewModel] = []

    private func makeViewModel() throws -> EditorViewModel {
        let schema = Schema([
            Project.self,
            PersistedBody.self,
            PersistedSketch.self,
            PersistedPlane.self,
            PersistedImage.self,
            PersistedSymbol.self,
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let context = ModelContext(container)
        let project = Project(name: "Constraint Apply Test")
        context.insert(project)
        let vm = EditorViewModel(project: project, modelContext: context)
        Self.retained.append(vm)
        return vm
    }

    /// Open a sketch containing `entities` and enter sketching mode.
    private func openSketch(
        _ vm: EditorViewModel, entities: [SketchEntity]
    ) -> Sketch {
        let sketch = Sketch(plane: .ground, entities: entities)
        vm.session.perform(AddSketchCommand(sketch: sketch))
        vm.mode = .sketching(sketch.id, tool: .line)
        return sketch
    }

    private func line(_ a: SIMD2<Double>, _ b: SIMD2<Double>) -> SketchEntity {
        .line(id: UUID(), a: a, b: b)
    }

    private func currentLine(_ vm: EditorViewModel, id: UUID) -> (a: SIMD2<Double>, b: SIMD2<Double>)? {
        for sketch in vm.session.document.sketches {
            for e in sketch.entities {
                if case let .line(eid, a, b) = e, eid == id { return (a, b) }
            }
        }
        return nil
    }

    func testTypedArcRotationUsesVisibleBoundsPivot() throws {
        let vm = try makeViewModel(), id = UUID()
        let arc = SketchEntity.arc(id: id, center: .zero, radius: 2,
                                  startAngle: -.pi / 2, endAngle: .pi / 2)
        let sketch = openSketch(vm, entities: [arc])
        vm.mode = .sketching(sketch.id, tool: nil)
        vm.selectedSketchEntityIDs = [id]
        vm.sketchTransformActive = true
        XCTAssertEqual(vm.sketchSelectionCentroid!.x, 1, accuracy: 1e-8)
        XCTAssertEqual(vm.sketchSelectionCentroid!.y, 0, accuracy: 1e-8)
        XCTAssertTrue(vm.commitSketchTransformControl(.rotation, text: "45 deg"))
        guard case let .arc(_, center, radius, start, end) = vm.activeSketch?.entities.first else { return XCTFail() }
        XCTAssertEqual(center.x, 1 - sqrt(0.5), accuracy: 1e-5)
        XCTAssertEqual(center.y, -sqrt(0.5), accuracy: 1e-5)
        XCTAssertEqual(radius, 2, accuracy: 1e-5)
        XCTAssertEqual(start, -.pi / 4, accuracy: 1e-5)
        XCTAssertEqual(SketchEntity.arcSweep(startAngle: start, endAngle: end), .pi, accuracy: 1e-5)
        vm.session.undo()
        XCTAssertEqual(vm.activeSketch?.entities, [arc])
    }

    func testRetainedTransformReeditUsesOriginalPivotAndSeparateUndo() throws {
        let vm = try makeViewModel(), id = UUID()
        let arc = SketchEntity.arc(id: id, center: .zero, radius: 2,
                                  startAngle: -.pi / 2, endAngle: .pi / 2)
        let sketch = openSketch(vm, entities: [arc])
        vm.mode = .sketching(sketch.id, tool: nil)
        vm.selectedSketchEntityIDs = [id]
        vm.sketchTransformActive = true
        XCTAssertTrue(vm.commitSketchTransformControl(.rotation, text: "45"))
        let first = vm.activeSketch!.entities
        XCTAssertEqual(vm.retainedSketchTransformValue(.rotation), 45)
        XCTAssertEqual(vm.sketchSelectionCentroid!.x, 1, accuracy: 1e-6)
        XCTAssertEqual(vm.sketchSelectionCentroid!.y, 0, accuracy: 1e-6)
        XCTAssertTrue(vm.commitSketchTransformControl(.rotation, text: "90"))
        guard case let .arc(_, center, radius, start, _) = vm.activeSketch?.entities.first else { return XCTFail() }
        XCTAssertEqual(center.x, 1, accuracy: 1e-5)
        XCTAssertEqual(center.y, -1, accuracy: 1e-5)
        XCTAssertEqual(radius, 2, accuracy: 1e-5)
        XCTAssertEqual(start, 0, accuracy: 1e-5)
        vm.session.undo()
        XCTAssertEqual(vm.activeSketch?.entities, first)
        vm.session.redo()
        XCTAssertTrue(vm.commitSketchTransformControl(.rotation, text: "0"))
        guard case let .arc(_, restored, _, _, _) = vm.activeSketch?.entities.first else { return XCTFail() }
        XCTAssertEqual(simd_length(restored), 0, accuracy: 1e-5)
        vm.sketchTransformActive = false
        XCTAssertNil(vm.retainedSketchTransformValue(.rotation))
    }

    func testRotatedSketchAxisMovementPreservesFrameAndAbsoluteReedit() throws {
        let vm = try makeViewModel(), id = UUID()
        let arc = SketchEntity.arc(id: id, center: .zero, radius: 2,
                                  startAngle: -.pi / 2, endAngle: .pi / 2)
        let sketch = openSketch(vm, entities: [arc])
        vm.mode = .sketching(sketch.id, tool: nil)
        vm.selectedSketchEntityIDs = [id]
        vm.sketchTransformActive = true
        XCTAssertTrue(vm.commitSketchTransformControl(.rotation, text: "45"))
        guard case let .arc(_, rotated, _, _, _) = vm.activeSketch?.entities.first else { return XCTFail() }
        XCTAssertTrue(vm.commitSketchTransformControl(.x, text: "2 mm"))
        guard case let .arc(_, moved, radius, _, _) = vm.activeSketch?.entities.first else { return XCTFail() }
        XCTAssertEqual(moved.x - rotated.x, sqrt(2), accuracy: 1e-5)
        XCTAssertEqual(moved.y - rotated.y, sqrt(2), accuracy: 1e-5)
        XCTAssertEqual(radius, 2, accuracy: 1e-5)
        XCTAssertEqual(vm.sketchTransformFrameAngle, .pi / 4, accuracy: 1e-8)
        XCTAssertEqual(vm.sketchSelectionCentroid!.x, 1 + sqrt(2), accuracy: 1e-5)
        XCTAssertTrue(vm.commitSketchTransformControl(.x, text: "4 mm"))
        guard case let .arc(_, edited, _, _, _) = vm.activeSketch?.entities.first else { return XCTFail() }
        XCTAssertEqual(edited.x - rotated.x, 2 * sqrt(2), accuracy: 1e-5)
        XCTAssertEqual(edited.y - rotated.y, 2 * sqrt(2), accuracy: 1e-5)
        vm.session.undo()
        guard case let .arc(_, undone, _, _, _) = vm.activeSketch?.entities.first else { return XCTFail() }
        XCTAssertEqual(simd_length(undone - moved), 0, accuracy: 1e-5)
    }

    func testSketchHistoryClosesExplicitTransformControls() throws {
        let vm = try makeViewModel(), id = UUID()
        let circle = SketchEntity.circle(id: id, center: .zero, radius: 2)
        let sketch = openSketch(vm, entities: [circle])
        vm.mode = .sketching(sketch.id, tool: nil)
        vm.selectedSketchEntityIDs = [id]
        vm.sketchTransformActive = true
        XCTAssertTrue(vm.commitSketchTransformControl(.x, text: "1 mm"))
        let moved = vm.activeSketch!.entities
        vm.undo()
        XCTAssertFalse(vm.sketchTransformActive)
        XCTAssertNil(vm.retainedSketchTransformValue(.x))
        XCTAssertEqual(vm.activeSketch?.entities, [circle])
        vm.redo()
        XCTAssertFalse(vm.sketchTransformActive)
        XCTAssertEqual(vm.activeSketch?.entities, moved)
    }

    func testCircleRotationRetainsFrameWithoutGeometryPerturbationOrHistoryFallthrough() throws {
        let vm = try makeViewModel(), id = UUID()
        let circle = SketchEntity.circle(id: id, center: SIMD2(2, 3), radius: 4)
        let sketch = openSketch(vm, entities: [circle])
        vm.mode = .sketching(sketch.id, tool: nil)
        vm.selectedSketchEntityIDs = [id]
        vm.sketchTransformActive = true
        XCTAssertTrue(vm.commitSketchTransformControl(.rotation, text: "45"))
        XCTAssertEqual(vm.activeSketch?.entities, [circle])
        XCTAssertEqual(vm.sketchTransformFrameAngle, .pi / 4, accuracy: 1e-8)
        XCTAssertEqual(vm.retainedSketchTransformValue(.rotation), 45)
        vm.undo()
        XCTAssertFalse(vm.sketchTransformActive)
        XCTAssertEqual(vm.activeSketch?.entities, [circle], "Undo the frame, not circle creation")
        vm.redo()
        XCTAssertEqual(vm.activeSketch?.entities, [circle])
        vm.sketchTransformActive = true
        XCTAssertTrue(vm.commitSketchTransformControl(.rotation, text: "45"))
        XCTAssertTrue(vm.commitSketchTransformControl(.x, text: "2 mm"))
        guard case let .circle(_, center, radius) = vm.activeSketch?.entities.first else { return XCTFail() }
        XCTAssertEqual(center.x, 2 + sqrt(2), accuracy: 1e-5)
        XCTAssertEqual(center.y, 3 + sqrt(2), accuracy: 1e-5)
        XCTAssertEqual(radius, 4, accuracy: 1e-5)
    }

    func testExactSketchAxisInputPreservesDiameterAndLocksAndHistory() throws {
        let vm = try makeViewModel(), id = UUID()
        let circle = SketchEntity.circle(id: id, center: SIMD2(2, 3), radius: 4)
        let sketch = openSketch(vm, entities: [circle])
        vm.mode = .sketching(sketch.id, tool: nil)
        vm.selectedSketchEntityIDs = [id]
        vm.sketchTransformActive = true
        XCTAssertTrue(vm.commitSketchTransformControl(.y, text: "2 cm"))
        guard case let .circle(_, center, radius) = vm.activeSketch?.entities.first else { return XCTFail() }
        XCTAssertEqual(center.x, 2, accuracy: 1e-5)
        XCTAssertEqual(center.y, 23, accuracy: 1e-5)
        XCTAssertEqual(radius, 4, accuracy: 1e-5)
        vm.session.undo()
        XCTAssertEqual(vm.activeSketch?.entities, [circle])
        vm.session.redo()
        let moved = vm.activeSketch!.entities
        vm.session.perform(AddSketchConstraintCommand(sketchID: sketch.id,
            constraint: .init(kind: .fixed, refs: [.init(entityID: id, role: .whole)])))
        XCTAssertTrue(vm.commitSketchTransformControl(.x, text: "5 mm"))
        XCTAssertEqual(vm.activeSketch?.entities, moved)
        XCTAssertFalse(vm.commitSketchTransformControl(.x, text: "5 deg"))
        XCTAssertFalse(vm.commitSketchTransformControl(.rotation, text: "5 cm"))
        XCTAssertEqual(vm.activeSketch?.entities, moved)
    }

    func testUnlockSelectedRectangleSidePreservesOtherLocksAndHistory() throws {
        let vm = try makeViewModel(), id = UUID()
        let sketch = openSketch(vm, entities: [.rect(id: id, min: .zero, max: SIMD2(10, 6))])
        let right = ConstraintRef(entityID: id, role: .whole, rectangleEdge: 1)
        let left = ConstraintRef(entityID: id, role: .whole, rectangleEdge: 3)
        let lock = SketchConstraint(kind: .fixed, refs: [right, left])
        vm.session.perform(AddSketchConstraintCommand(sketchID: sketch.id, constraint: lock))
        vm.selectedSketchEntityIDs = [id]
        vm.selectedAxisRectangleEdge = (id, 1)
        XCTAssertTrue(vm.canUnlockSketchSelection)
        vm.toggleSketchSelectionLock()
        XCTAssertFalse(vm.canUnlockSketchSelection)
        XCTAssertEqual(vm.activeSketch?.constraints.first?.refs, [left])
        vm.undo()
        XCTAssertEqual(vm.activeSketch?.constraints, [lock])
        vm.redo()
        XCTAssertEqual(vm.activeSketch?.constraints.first?.refs, [left])
        vm.selectedAxisRectangleEdge = (id, 3)
        XCTAssertTrue(vm.canUnlockSketchSelection)
        vm.toggleSketchSelectionLock()
        XCTAssertTrue(vm.activeSketch?.constraints.isEmpty == true)
        XCTAssertEqual(vm.activeSketch?.entities, sketch.entities, "Unlock must not relocate geometry")
    }

    // MARK: - Coincident welds a shared corner

    func testCoincidentOnTwoLinesWeldsCorner() throws {
        let vm = try makeViewModel()
        let l0 = line(SIMD2(0, 0), SIMD2(10, 0))
        let l1 = line(SIMD2(10.1, 0.1), SIMD2(20, 5))
        let sketch = openSketch(vm, entities: [l0, l1])
        vm.selectedSketchEntityIDs = [l0.id, l1.id]

        XCTAssertTrue(vm.canApplyConstraint(.coincident),
                      "Two lines sharing a near corner should enable Coincident")
        vm.applyConstraint(.coincident)

        // The constraint is recorded on the sketch.
        let solved = vm.session.document.sketches.first { $0.id == sketch.id }
        XCTAssertEqual(solved?.constraints.count, 1)
        XCTAssertEqual(solved?.constraints.first?.kind, .coincident)

        // Line 0's end and line 1's start now coincide.
        guard let a = currentLine(vm, id: l0.id), let b = currentLine(vm, id: l1.id) else {
            return XCTFail("Lines missing after solve")
        }
        XCTAssertLessThan(simd_distance(a.b, b.a), 1e-6,
                          "Coincident should weld the shared endpoints together")

        // Re-solving the committed sketch is stable (no further motion).
        let (again, _) = SketchSolverBridge.solve(solved!, movingEntity: nil, dragTarget: nil)
        for (before, after) in zip(solved!.entities, again) {
            XCTAssertEqual(before, after, "A satisfied sketch must not drift on re-solve")
        }
    }

    func testCoincidentIsOneUndoStep() throws {
        let vm = try makeViewModel()
        let l0 = line(SIMD2(0, 0), SIMD2(10, 0))
        let l1 = line(SIMD2(10.2, 0.2), SIMD2(20, 5))
        _ = openSketch(vm, entities: [l0, l1])
        vm.selectedSketchEntityIDs = [l0.id, l1.id]

        XCTAssertTrue(vm.session.undoStack.canUndo, "Adding the sketch is undoable")
        let sketchesBefore = vm.session.document.sketches.count
        vm.applyConstraint(.coincident)
        XCTAssertEqual(vm.session.document.sketches.count, sketchesBefore)

        vm.undo() // removes the constraint + geometry move in one step
        let afterUndo = vm.session.document.sketches.first
        XCTAssertEqual(afterUndo?.constraints.count, 0,
                       "One undo removes the whole constraint application")
        // Geometry restored to the pre-solve corner gap.
        guard let a = currentLine(vm, id: l0.id) else { return XCTFail("line gone") }
        XCTAssertEqual(a.b, SIMD2(10, 0), "Undo restores the original endpoint")
    }

    // MARK: - Horizontal levels a near-horizontal line

    func testHorizontalLevelsLine() throws {
        let vm = try makeViewModel()
        let l0 = line(SIMD2(0, 0), SIMD2(10, 0.5))
        _ = openSketch(vm, entities: [l0])
        vm.selectedSketchEntityIDs = [l0.id]

        XCTAssertTrue(vm.canApplyConstraint(.horizontal),
                      "A single selected line should enable Horizontal")
        vm.applyConstraint(.horizontal)

        guard let a = currentLine(vm, id: l0.id) else { return XCTFail("line gone") }
        XCTAssertLessThan(abs(a.a.y - a.b.y), 1e-6,
                          "Horizontal should level the line's endpoints")
    }

    func testLineHoverNamesSnapsBeforePlacementWithoutEditingGeometry() throws {
        let vm = try makeViewModel()
        let settings = AppSettings.shared
        let guidepoints = settings.snapToSketchGuidepoints
        let hints = settings.showSnapHints
        defer { settings.snapToSketchGuidepoints = guidepoints; settings.showSnapHints = hints }
        settings.snapToSketchGuidepoints = true
        settings.showSnapHints = true
        let original = Sketch(plane: .ground, entities: [line(SIMD2(0, 0), SIMD2(10, 0))])
        vm.session.perform(AddSketchCommand(sketch: original))
        vm.mode = .sketching(original.id, tool: .line)
        func ray(_ x: Double) -> Ray {
            let p = original.plane.toWorld(SIMD2(x, 0))
            let n = original.plane.normal
            return Ray(origin: SIMD3<Float>(Float(p.x+n.x*10), Float(p.y+n.y*10), Float(p.z+n.z*10)),
                       direction: SIMD3<Float>(Float(-n.x), Float(-n.y), Float(-n.z)))
        }
        XCTAssertTrue(vm.updateLinePreview(ray: ray(0)))
        XCTAssertEqual(vm.activeSnapLabel?.text, "Endpoint")
        XCTAssertNil(vm.pendingEntity)
        XCTAssertEqual(vm.activeSketch, original)
        XCTAssertTrue(vm.updateLinePreview(ray: ray(5)))
        XCTAssertEqual(vm.activeSnapLabel?.text, "Midpoint")
        XCTAssertTrue(vm.updateLinePreview(ray: nil))
        XCTAssertNil(vm.activeSnapLabel)
        settings.snapToSketchGuidepoints = false
        _ = vm.updateLinePreview(ray: ray(0))
        XCTAssertNil(vm.activeSnapLabel)
        vm.session.undo()
        XCTAssertNil(vm.activeSketch, "Hover must not add an undoable edit")
    }

    func testCopiedLinesRemainIndependentThroughHistoryAndReload() throws {
        let vm = try makeViewModel()
        let a = line(SIMD2(0, 0), SIMD2(10, 0))
        let b = line(SIMD2(10, 0), SIMD2(10, 5))
        let original = Sketch(plane: .ground, entities: [a, b])
        vm.session.perform(AddSketchCommand(sketch: original))
        vm.mode = .sketching(original.id, tool: nil)
        let copies = vm.duplicateSketchEntities([a, b], in: original.id)
        let copied = try XCTUnwrap(vm.activeSketch)
        let reopened = try JSONDecoder().decode(Sketch.self, from: JSONEncoder().encode(copied))
        let targets = SketchTransform.translate(entities: copies, by: SIMD2(0, 3))
        let moved = try XCTUnwrap(SketchSolverBridge.solveLineTransform(reopened, targets: targets))
        XCTAssertEqual(Array(moved.prefix(2)), original.entities, "Copy must not move sources")
        for index in copies.indices {
            guard case let .line(_, a, b) = moved[index + 2],
                  case let .line(_, c, d) = targets[index] else { return XCTFail("Expected line") }
            XCTAssertLessThan(simd_distance(a, c), 1e-4)
            XCTAssertLessThan(simd_distance(b, d), 1e-4)
        }
        XCTAssertEqual(copied.constraints.filter { $0.kind == .coincident }.count, 1)
        vm.session.undo()
        XCTAssertEqual(vm.activeSketch, original)
        vm.session.redo()
        XCTAssertEqual(vm.activeSketch, copied)
    }

    func testCopyDoesNotReconnectPreviouslyDisconnectedSources() throws {
        let vm = try makeViewModel()
        let a = line(SIMD2(0, 0), SIMD2(10, 0))
        let b = line(SIMD2(10, 0), SIMD2(10, 5))
        var original = Sketch(plane: .ground, entities: [a, b])
        original.disconnectedEndpoints = [.init(entityID: a.id, role: .endpointB)]
        vm.session.perform(AddSketchCommand(sketch: original))
        vm.mode = .sketching(original.id, tool: nil)
        _ = vm.duplicateSketchEntities([a, b], in: original.id)
        XCTAssertTrue(try XCTUnwrap(vm.activeSketch).constraints.isEmpty)
    }

    func testDisconnectPreservesDimensionsAndIndependentMovementThroughHistoryAndReload() throws {
        let vm = try makeViewModel()
        let edges = RectangleConstruction.threePoint(a: SIMD2(0, 0), b: SIMD2(10, 2),
            heightPoint: SIMD2(9, 7), ids: (0..<4).map { _ in UUID() })
        let original = Sketch(plane: .ground, entities: edges,
            constraints: RectangleConstruction.constraints(for: edges),
            dimensions: [.init(kind: .distance, refs: [.init(entityID: edges[0].id, role: .endpointA),
                .init(entityID: edges[0].id, role: .endpointB)], value: sqrt(104))])
        vm.session.perform(AddSketchCommand(sketch: original))
        vm.mode = .sketching(original.id, tool: nil)
        vm.selectedSketchEntityIDs = [edges[0].id]
        XCTAssertNotNil(vm.rectangleHandleGeometry)
        XCTAssertTrue(vm.canDisconnectSketchSelection)
        vm.disconnectSketchSelection()
        let detached = try XCTUnwrap(vm.activeSketch)
        XCTAssertEqual(detached.entities, original.entities)
        XCTAssertEqual(detached.dimensions, original.dimensions)
        XCTAssertEqual(detached.constraints.filter { $0.kind != .coincident },
                       original.constraints.filter { $0.kind != .coincident })
        XCTAssertEqual(detached.constraints.filter { $0.kind == .coincident }.count, 2)
        vm.selectedSketchEntityIDs = [edges[0].id]
        XCTAssertFalse(vm.canDisconnectSketchSelection)
        XCTAssertNil(vm.rectangleHandleGeometry)
        let reopened = try JSONDecoder().decode(Sketch.self, from: JSONEncoder().encode(detached))
        let targets = SketchTransform.translate(entities: [edges[0]], by: SIMD2(0, 3))
        let moved = try XCTUnwrap(SketchSolverBridge.solveLineTransform(reopened, targets: targets))
        for index in edges.indices {
            guard case let .line(_, a, b) = moved[index],
                  case let .line(_, c, d) = (index == 0 ? targets[0] : edges[index]) else {
                return XCTFail("Expected line")
            }
            XCTAssertLessThan(simd_distance(a, c), 1e-3)
            XCTAssertLessThan(simd_distance(b, d), 1e-3)
        }
        vm.session.undo()
        XCTAssertEqual(vm.activeSketch, original)
        XCTAssertNotNil(vm.rectangleHandleGeometry)
        vm.session.redo()
        XCTAssertEqual(vm.activeSketch, detached)
        XCTAssertNil(vm.rectangleHandleGeometry)
    }

    func testDisconnectProximityAndExplicitReconnectAndLegacyDecode() throws {
        let vm = try makeViewModel()
        let a = line(SIMD2(0, 0), SIMD2(10, 0))
        let b = line(SIMD2(10, 0), SIMD2(10, 5))
        let sketch = openSketch(vm, entities: [a, b])
        vm.mode = .sketching(sketch.id, tool: nil)
        vm.selectedSketchPoints = [.init(entityID: a.id, role: .endpointB)]
        XCTAssertTrue(vm.canDisconnectSketchSelection)
        vm.disconnectSketchSelection()
        var detached = try XCTUnwrap(vm.activeSketch)
        XCTAssertEqual(detached.disconnectedEndpoints, [.init(entityID: a.id, role: .endpointB)])
        XCTAssertEqual(SketchSolverBridge.solve(detached, movingEntity: nil, dragTarget: nil).dof, 8)
        detached.constraints.append(.init(kind: .coincident, refs: [
            .init(entityID: a.id, role: .endpointB), .init(entityID: b.id, role: .endpointA)]))
        XCTAssertEqual(SketchSolverBridge.solve(detached, movingEntity: nil, dragTarget: nil).dof, 6,
                       "Explicit reconnection must override the proximity exclusion")
        var json = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(sketch)) as? [String: Any])
        json.removeValue(forKey: "disconnectedEndpoints")
        let legacy = try JSONDecoder().decode(Sketch.self, from: JSONSerialization.data(withJSONObject: json))
        XCTAssertTrue(legacy.disconnectedEndpoints.isEmpty)
        XCTAssertEqual(SketchSolverBridge.solve(legacy, movingEntity: nil, dragTarget: nil).dof, 6)

        var document = DesignDocument()
        document.sketches = [detached]
        let deletion = RemoveSketchEntitiesCommand(ids: [a.id], sketch: detached)
        deletion.apply(to: &document)
        XCTAssertTrue(document.sketches[0].validateConstraintRefs())
        XCTAssertTrue(document.sketches[0].disconnectedEndpoints.isEmpty)
        deletion.revert(in: &document)
        XCTAssertEqual(document.sketches[0], detached)
        let fragment = line(SIMD2(5, 0), SIMD2(10, 0))
        let trim = TrimCommand(sketch: detached, index: 0, removed: a, fragments: [fragment])
        trim.apply(to: &document)
        XCTAssertEqual(document.sketches[0].disconnectedEndpoints,
                       [.init(entityID: fragment.id, role: .endpointB)])
        XCTAssertTrue(document.sketches[0].validateConstraintRefs())
        trim.revert(in: &document)
        XCTAssertEqual(document.sketches[0], detached)
    }

    // MARK: - Adaptive enable/disable rules

    /// Spec §3.2 lists Parallel as taking "2+ lines". Three selected lines must
    /// therefore enable it and end up mutually parallel — stored as a pairwise
    /// chain, which is equivalent because parallelism is transitive.
    func testParallelAcceptsMoreThanTwoLines() throws {
        let vm = try makeViewModel()
        let l0 = line(SIMD2(0, 0), SIMD2(10, 0))          // horizontal
        let l1 = line(SIMD2(0, 5), SIMD2(10, 6))          // slightly tilted
        let l2 = line(SIMD2(0, 12), SIMD2(9, 14))         // more tilted
        _ = openSketch(vm, entities: [l0, l1, l2])

        vm.selectedSketchEntityIDs = [l0.id, l1.id, l2.id]
        XCTAssertTrue(vm.canApplyConstraint(.parallel),
                      "Parallel must enable for 2+ lines (spec §3.2)")
        // Perpendicular is NOT transitive — three mutually perpendicular lines
        // are impossible in 2D, so it stays a strict pair.
        XCTAssertFalse(vm.canApplyConstraint(.perpendicular),
                       "Perpendicular stays a strict two-line relation")

        vm.applyConstraint(.parallel)

        guard let a = currentLine(vm, id: l0.id),
              let b = currentLine(vm, id: l1.id),
              let c = currentLine(vm, id: l2.id) else {
            return XCTFail("lines missing after solve")
        }
        func angle(_ l: (a: SIMD2<Double>, b: SIMD2<Double>)) -> Double {
            let d = l.b - l.a
            return atan2(d.y, d.x).truncatingRemainder(dividingBy: .pi)
        }
        XCTAssertEqual(angle(a), angle(b), accuracy: 1e-3, "line 0 ∥ line 1")
        XCTAssertEqual(angle(b), angle(c), accuracy: 1e-3, "line 1 ∥ line 2")
    }

    func testAdaptiveEnablement() throws {
        let vm = try makeViewModel()
        let l0 = line(SIMD2(0, 0), SIMD2(10, 0))
        let l1 = line(SIMD2(0, 5), SIMD2(10, 6))
        let c0 = SketchEntity.circle(id: UUID(), center: SIMD2(0, 0), radius: 2)
        let c1 = SketchEntity.circle(id: UUID(), center: SIMD2(8, 0), radius: 3)
        _ = openSketch(vm, entities: [l0, l1, c0, c1])

        // Two lines: parallel/perpendicular/equalLength enabled; concentric not.
        vm.selectedSketchEntityIDs = [l0.id, l1.id]
        XCTAssertTrue(vm.canApplyConstraint(.parallel))
        XCTAssertTrue(vm.canApplyConstraint(.perpendicular))
        XCTAssertTrue(vm.canApplyConstraint(.equalLength))
        XCTAssertFalse(vm.canApplyConstraint(.concentric))
        XCTAssertFalse(vm.canApplyConstraint(.tangent))

        // Two circles: concentric/equalRadius enabled; parallel not.
        vm.selectedSketchEntityIDs = [c0.id, c1.id]
        XCTAssertTrue(vm.canApplyConstraint(.concentric))
        XCTAssertTrue(vm.canApplyConstraint(.equalRadius))
        XCTAssertFalse(vm.canApplyConstraint(.parallel))

        // Line + circle: tangent enabled.
        vm.selectedSketchEntityIDs = [l0.id, c0.id]
        XCTAssertTrue(vm.canApplyConstraint(.tangent))
        XCTAssertFalse(vm.canApplyConstraint(.parallel))

        // A point + a line: midpoint enabled, symmetric not (needs 2 points).
        vm.selectedSketchEntityIDs = [l1.id]
        vm.selectedSketchPoints = [.init(entityID: l0.id, role: .endpointA)]
        XCTAssertTrue(vm.canApplyConstraint(.midpoint))
        XCTAssertFalse(vm.canApplyConstraint(.symmetric))

        // Two points: coincident + horizontal/vertical enabled.
        vm.selectedSketchEntityIDs = []
        vm.selectedSketchPoints = [
            .init(entityID: l0.id, role: .endpointA),
            .init(entityID: l1.id, role: .endpointB),
        ]
        XCTAssertTrue(vm.canApplyConstraint(.coincident))
        XCTAssertTrue(vm.canApplyConstraint(.horizontal))
        XCTAssertTrue(vm.canApplyConstraint(.vertical))
    }

    // MARK: - Point-role hit testing

    func testNearestPointReturnsRole() {
        let id = UUID()
        let entities: [SketchEntity] = [.line(id: id, a: SIMD2(0, 0), b: SIMD2(10, 0))]
        let hitA = SketchHitTester.nearestPoint(to: SIMD2(0.1, 0.1), in: entities, tolerance: 0.5)
        XCTAssertEqual(hitA?.role, .endpointA)
        XCTAssertEqual(hitA?.entityID, id)
        let hitB = SketchHitTester.nearestPoint(to: SIMD2(9.9, 0.05), in: entities, tolerance: 0.5)
        XCTAssertEqual(hitB?.role, .endpointB)
        // The middle of the line is not a model point.
        XCTAssertNil(SketchHitTester.nearestPoint(to: SIMD2(5, 0), in: entities, tolerance: 0.5))
    }
}
