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
