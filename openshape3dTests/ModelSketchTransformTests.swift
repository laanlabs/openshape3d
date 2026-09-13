//
//  ModelSketchTransformTests.swift
//  openshape3dTests
//
//  QA-24: sketch entities selected in model mode move and rotate through the
//  Move/Rotate gizmo, as Shapr3D's do. Observed natively 2026-09-13: a
//  distance typed on an arrow moved a whole selected sketch along it, the
//  sketch kept its identity and selection, and Undo restored it.
//

import XCTest
import SwiftData
import simd
@testable import openshape3d

@MainActor
final class ModelSketchTransformTests: XCTestCase {
    private static var retained: [EditorViewModel] = []

    private func makeViewModel() throws -> EditorViewModel {
        let schema = Schema([Project.self, PersistedBody.self, PersistedSketch.self,
                             PersistedPlane.self, PersistedImage.self, PersistedSymbol.self])
        let container = try ModelContainer(for: schema,
            configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)])
        let context = ModelContext(container)
        let project = Project(name: "Model sketch transform")
        context.insert(project)
        let vm = EditorViewModel(project: project, modelContext: context)
        Self.retained.append(vm)
        return vm
    }

    /// A 4×3 rectangle of four lines on the ground plane, selected the way a
    /// user does it: its Items row, then Exit — the selection survives.
    private func seedSelectedSquare(_ vm: EditorViewModel) -> Sketch {
        let corners: [SIMD2<Double>] = [[0, 0], [4, 0], [4, 3], [0, 3]]
        let lines = (0..<4).map { i in
            SketchEntity.line(id: UUID(), a: corners[i], b: corners[(i + 1) % 4])
        }
        let sketch = Sketch(name: "P24", plane: .ground, entities: lines)
        vm.session.perform(AddSketchCommand(sketch: sketch))
        vm.selectItemSketch(sketch.id)
        vm.finishSketch()
        return sketch
    }

    private func sketch(_ vm: EditorViewModel, _ id: SketchID) throws -> Sketch {
        try XCTUnwrap(vm.session.document.sketches.first { $0.id == id })
    }

    func testWholeSketchShowsTheGizmoAndATypedDistanceMovesItsFrame() throws {
        let vm = try makeViewModel()
        let seeded = seedSelectedSquare(vm)
        XCTAssertEqual(vm.mode, .idle)
        XCTAssertEqual(vm.selectedSketchEntityIDs.count, 4, "Items selection survives Exit")
        let origin = try XCTUnwrap(vm.gizmoOrigin, "the gizmo attaches to the selection")
        XCTAssertEqual(origin.x, 2, accuracy: 1e-5)
        XCTAssertEqual(origin.y, 0, accuracy: 1e-5)
        XCTAssertEqual(origin.z, -1.5, accuracy: 1e-5, "ground sketch y runs along world -z")

        vm.beginAxisDistanceEntry(.yAxis)
        vm.commitAxisMove(distance: 5)
        let moved = try sketch(vm, seeded.id)
        XCTAssertEqual(moved.plane.origin, SIMD3(0, 5, 0))
        XCTAssertEqual(moved.plane.xAxis, SketchPlane.ground.xAxis)
        XCTAssertEqual(moved.entities, seeded.entities, "local geometry is untouched")
        XCTAssertEqual(vm.selectedSketchEntityIDs.count, 4, "the selection stays, as native's did")
        XCTAssertEqual(vm.mode, .idle)
        XCTAssertNil(vm.axisEntryPart)

        vm.undo()
        XCTAssertEqual(try sketch(vm, seeded.id).plane, .ground, "one undo step lands home")
        vm.redo()
        XCTAssertEqual(try sketch(vm, seeded.id).plane.origin, SIMD3(0, 5, 0))
    }

    func testSubsetMovesInsideItsPlaneAndOnlyTheSelectedLinesChange() throws {
        let vm = try makeViewModel()
        let seeded = seedSelectedSquare(vm)
        let bottom = seeded.entities[0]
        vm.selectedSketchEntityIDs = [bottom.id]
        let origin = try XCTUnwrap(vm.gizmoOrigin)
        XCTAssertEqual(origin.x, 2, accuracy: 1e-5)
        XCTAssertEqual(origin.z, 0, accuracy: 1e-5)

        vm.beginAxisDistanceEntry(.xAxis)
        vm.commitAxisMove(distance: 2)
        let moved = try sketch(vm, seeded.id)
        XCTAssertEqual(moved.plane, .ground, "an in-plane move leaves the frame alone")
        guard case let .line(_, a, b) = try XCTUnwrap(moved.entities.first { $0.id == bottom.id }) else {
            return XCTFail("line expected")
        }
        XCTAssertEqual(a.x, 2, accuracy: 1e-6); XCTAssertEqual(a.y, 0, accuracy: 1e-6)
        XCTAssertEqual(b.x, 6, accuracy: 1e-6); XCTAssertEqual(b.y, 0, accuracy: 1e-6)
        // The solver keeps the square connected: the neighbours' shared
        // endpoints follow, the far side stays put.
        guard case let .line(_, rightA, rightB) = moved.entities[1],
              case let .line(_, leftA, leftB) = moved.entities[3] else { return XCTFail("lines expected") }
        XCTAssertEqual(rightA.x, 6, accuracy: 1e-6); XCTAssertEqual(rightB, SIMD2(4, 3))
        XCTAssertEqual(leftB.x, 2, accuracy: 1e-6); XCTAssertEqual(leftA, SIMD2(0, 3))
        XCTAssertEqual(moved.entities[2], seeded.entities[2], "the top line is untouched")
        vm.undo()
        XCTAssertEqual(try sketch(vm, seeded.id).entities, seeded.entities)
    }

    func testSubsetCannotLeaveItsPlane() throws {
        let vm = try makeViewModel()
        let seeded = seedSelectedSquare(vm)
        vm.selectedSketchEntityIDs = [seeded.entities[0].id]
        let steps = vm.session.undoStack.undoCommands.count
        vm.beginAxisDistanceEntry(.yAxis)
        vm.commitAxisMove(distance: 5)
        XCTAssertEqual(try sketch(vm, seeded.id), seeded, "nothing moved")
        XCTAssertEqual(vm.notice, "Select the whole sketch to move it off its plane")
        XCTAssertEqual(vm.session.undoStack.undoCommands.count, steps,
                       "a refused move is not a history step")
    }

    func testTypedRotationAboutTheNormalTurnsTheSubsetAboutTheGizmo() throws {
        let vm = try makeViewModel()
        let seeded = seedSelectedSquare(vm)
        let bottom = seeded.entities[0]
        vm.selectedSketchEntityIDs = [bottom.id]
        vm.beginAngleEntry(.yRing)          // world +Y is the ground plane's normal
        vm.commitAngleRotate(degrees: 90)
        let moved = try sketch(vm, seeded.id)
        XCTAssertEqual(moved.plane, .ground)
        guard case let .line(_, a, b) = try XCTUnwrap(moved.entities.first { $0.id == bottom.id }) else {
            return XCTFail("line expected")
        }
        // A quarter turn about the gizmo at (2, 0): (0,0) → (2,−2), (4,0) → (2,2).
        XCTAssertEqual(a.x, 2, accuracy: 1e-9); XCTAssertEqual(a.y, -2, accuracy: 1e-9)
        XCTAssertEqual(b.x, 2, accuracy: 1e-9); XCTAssertEqual(b.y, 2, accuracy: 1e-9)
        vm.undo()
        XCTAssertEqual(try sketch(vm, seeded.id).entities, seeded.entities)
    }

    func testDragMoveCommitsOneStepAndTiltingRotationTurnsTheWholeFrame() throws {
        let vm = try makeViewModel()
        let seeded = seedSelectedSquare(vm)
        let steps = vm.session.undoStack.undoCommands.count
        vm.beginMove()
        vm.updateMove(delta: SIMD3<Float>(0, 1, 0))
        vm.updateMove(delta: SIMD3<Float>(0, 3, 0))
        XCTAssertEqual(try sketch(vm, seeded.id).plane.origin.y, 3, accuracy: 1e-6, "live preview")
        XCTAssertEqual(vm.session.undoStack.undoCommands.count, steps,
                       "the preview is not yet a history step")
        vm.endMove()
        XCTAssertEqual(try sketch(vm, seeded.id).plane.origin, SIMD3(0, 3, 0))
        XCTAssertEqual(vm.session.undoStack.undoCommands.count, steps + 1, "one step for the drag")
        XCTAssertEqual(vm.session.undoStack.undoTitle, "Move")

        // Tilting the whole sketch a quarter turn about world X stands it up.
        vm.beginAngleEntry(.xRing)
        vm.commitAngleRotate(degrees: 90)
        let tilted = try sketch(vm, seeded.id)
        XCTAssertEqual(tilted.entities, seeded.entities)
        XCTAssertEqual(simd_length(tilted.plane.normal - SIMD3(0, 0, 1)), 0, accuracy: 1e-9,
                       "the ground normal (+Y) turns onto +Z")
        vm.undo()
        XCTAssertEqual(try sketch(vm, seeded.id).plane.origin, SIMD3(0, 3, 0))
        vm.undo()
        XCTAssertEqual(try sketch(vm, seeded.id).plane, .ground)
    }

    func testGizmoStaysHiddenWhileSketchingAndClearsWithTheSelection() throws {
        let vm = try makeViewModel()
        let seeded = seedSelectedSquare(vm)
        XCTAssertNotNil(vm.gizmoOrigin)
        vm.selectItemSketch(seeded.id)
        XCTAssertTrue(vm.mode.isSketching)
        XCTAssertNil(vm.gizmoOrigin, "sketch mode has its own Move/Rotate pills")
        vm.finishSketch()
        vm.selectedSketchEntityIDs.removeAll()
        XCTAssertNil(vm.gizmoOrigin)
    }
}
