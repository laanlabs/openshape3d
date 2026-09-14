//
//  GizmoTypedCopyTests.swift
//  openshape3dTests
//
//  The Copy badge applies to a TYPED gizmo move as it does to a drag
//  (iPad, 2026-09-14): with Copy on, a distance typed on an arrow moves a
//  duplicate and leaves the original where it was.
//

import XCTest
import SwiftData
import simd
@testable import openshape3d

@MainActor
final class GizmoTypedCopyTests: XCTestCase {
    nonisolated(unsafe) private static var retainedViewModels: [EditorViewModel] = []

    private func makeViewModel() throws -> EditorViewModel {
        let schema = Schema([
            Project.self, PersistedBody.self, PersistedSketch.self,
            PersistedPlane.self, PersistedImage.self, PersistedSymbol.self,
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let context = ModelContext(container)
        let project = Project(name: "Typed Copy Test")
        context.insert(project)
        let viewModel = EditorViewModel(project: project, modelContext: context)
        Self.retainedViewModels.append(viewModel)
        return viewModel
    }

    @discardableResult
    private func addBox(to viewModel: EditorViewModel, name: String) -> Body {
        var document = viewModel.session.document // nextRevision is mutating
        let body = Body(
            name: name,
            transform: .identity,
            euclidMesh: .primitive(.box(width: 2, depth: 2, height: 2)),
            revision: document.nextRevision()
        )
        viewModel.session.perform(AddBodyCommand(body: body))
        return body
    }

    func testTypedDistanceWithCopyOnMovesADuplicateAndLeavesTheOriginal() throws {
        let vm = try makeViewModel()
        let box = addBox(to: vm, name: "Block")
        vm.selection = [box.id]
        vm.mode = .selected(box.id)
        vm.copyOnDrag = true
        let undoBefore = vm.session.undoStack.undoCommands.count

        vm.beginAxisDistanceEntry(.xAxis)
        XCTAssertEqual(vm.axisEntryPart, .xAxis)
        vm.commitAxisMove(distance: 5)

        let bodies = vm.session.document.bodies
        XCTAssertEqual(bodies.count, 2, "Copy on: the typed move adds a duplicate")
        let original = try XCTUnwrap(bodies.first { $0.id == box.id })
        XCTAssertEqual(original.transform.translation, .zero, "the original stays put")
        let copy = try XCTUnwrap(bodies.first { $0.id != box.id })
        XCTAssertEqual(copy.transform.translation.x, 5, accuracy: 1e-9)
        XCTAssertEqual(copy.transform.translation.y, 0, accuracy: 1e-9)
        XCTAssertEqual(vm.selection, [copy.id], "the copy is what is selected afterwards")
        XCTAssertFalse(vm.copyOnDrag, "the badge resets after one use, as after a drag")
        XCTAssertNil(vm.axisEntryPart)
        // Same history shape as a dragged copy: the Copy step, then the Move.
        XCTAssertEqual(vm.session.undoStack.undoCommands.count - undoBefore, 2)
    }

    func testTypedDistanceWithCopyOffMovesTheOriginal() throws {
        let vm = try makeViewModel()
        let box = addBox(to: vm, name: "Block")
        vm.selection = [box.id]
        vm.mode = .selected(box.id)
        vm.beginAxisDistanceEntry(.yAxis)
        vm.commitAxisMove(distance: 3)
        XCTAssertEqual(vm.session.document.bodies.count, 1)
        XCTAssertEqual(vm.session.document.bodies[0].transform.translation.y, 3, accuracy: 1e-9)
    }

    func testTypedAngleWithCopyOnRotatesADuplicate() throws {
        let vm = try makeViewModel()
        let box = addBox(to: vm, name: "Block")
        vm.selection = [box.id]
        vm.mode = .selected(box.id)
        vm.copyOnDrag = true
        vm.beginAngleEntry(.yRing)
        vm.commitAngleRotate(degrees: 90)
        XCTAssertEqual(vm.session.document.bodies.count, 2, "Copy on: the typed rotation turns a duplicate")
        XCTAssertFalse(vm.copyOnDrag)
    }
}
