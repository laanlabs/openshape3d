//
//  GizmoPivotTests.swift
//  openshape3dTests
//
//  Where the move gizmo sits and what a rotation spins about: the centre of
//  the selection's world bounding box (Jason, iPad, 2026-09-14 — it used to
//  be each body's local origin, so a box turned about its base).
//

import XCTest
import SwiftData
import simd
@testable import openshape3d

@MainActor
final class GizmoPivotTests: XCTestCase {
    nonisolated(unsafe) private static var retainedViewModels: [EditorViewModel] = []

    private func makeViewModel() throws -> EditorViewModel {
        let schema = Schema([
            Project.self, PersistedBody.self, PersistedSketch.self,
            PersistedPlane.self, PersistedImage.self, PersistedSymbol.self,
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let context = ModelContext(container)
        let project = Project(name: "Gizmo Pivot Test")
        context.insert(project)
        let viewModel = EditorViewModel(project: project, modelContext: context)
        Self.retainedViewModels.append(viewModel)
        return viewModel
    }

    /// A 2 mm box whose mesh spans x,z −1…1 and y 0…2 in its own frame.
    @discardableResult
    private func addBox(to viewModel: EditorViewModel, at translation: SIMD3<Double>) -> Body {
        var transform = Transform3D.identity
        transform.translation = translation
        var document = viewModel.session.document
        let body = Body(
            name: "Block",
            transform: transform,
            euclidMesh: .primitive(.box(width: 2, depth: 2, height: 2)),
            revision: document.nextRevision()
        )
        viewModel.session.perform(AddBodyCommand(body: body))
        return body
    }

    func testGizmoSitsAtTheCentreOfTheSelectedBodysBoundingBox() throws {
        let vm = try makeViewModel()
        let box = addBox(to: vm, at: SIMD3(3, 0, 0))
        vm.selection = [box.id]
        vm.mode = .selected(box.id)
        let origin = try XCTUnwrap(vm.gizmoOrigin)
        XCTAssertEqual(origin.x, 3, accuracy: 1e-5)
        XCTAssertEqual(origin.y, 1, accuracy: 1e-5, "the box spans y 0…2: its centre is 1 up, not its base")
        XCTAssertEqual(origin.z, 0, accuracy: 1e-5)
    }

    /// A typed 90° about X: the box's frame origin (its base centre) swings
    /// about the box centre (3,1,0) — from 1 below it to 1 behind it.
    func testTypedRotationSpinsTheBodyAboutItsCentre() throws {
        let vm = try makeViewModel()
        let box = addBox(to: vm, at: SIMD3(3, 0, 0))
        vm.selection = [box.id]
        vm.mode = .selected(box.id)
        vm.beginAngleEntry(.xRing)
        vm.commitAngleRotate(degrees: 90)
        let after = try XCTUnwrap(vm.session.document.body(with: box.id))
        XCTAssertEqual(after.transform.translation.x, 3, accuracy: 1e-6)
        XCTAssertEqual(after.transform.translation.y, 1, accuracy: 1e-6)
        XCTAssertEqual(after.transform.translation.z, -1, accuracy: 1e-6)
        // And the gizmo is still at the (unchanged) centre of the solid.
        let origin = try XCTUnwrap(vm.gizmoOrigin)
        XCTAssertEqual(origin.x, 3, accuracy: 1e-4)
        XCTAssertEqual(origin.y, 1, accuracy: 1e-4)
        XCTAssertEqual(origin.z, 0, accuracy: 1e-4)
    }

    /// Recenter puts a dropped gizmo back at the selection's centre.
    func testRecenterReturnsADroppedGizmoToTheCentre() throws {
        let vm = try makeViewModel()
        let box = addBox(to: vm, at: SIMD3(3, 0, 0))
        vm.selection = [box.id]
        vm.mode = .selected(box.id)
        vm.toggleGizmoReposition()
        vm.setGizmoPivot(world: SIMD3(4, 2, 1))
        XCTAssertTrue(vm.gizmoPivotIsOffset)
        XCTAssertEqual(try XCTUnwrap(vm.gizmoOrigin).x, 4, accuracy: 1e-5)
        vm.recenterGizmoPivot()
        XCTAssertFalse(vm.gizmoPivotIsOffset)
        let origin = try XCTUnwrap(vm.gizmoOrigin)
        XCTAssertEqual(origin.x, 3, accuracy: 1e-5)
        XCTAssertEqual(origin.y, 1, accuracy: 1e-5)
        XCTAssertEqual(origin.z, 0, accuracy: 1e-5)
        XCTAssertTrue(vm.gizmoRepositionArmed, "recentring keeps the mode on until Done")
    }

    /// A dropped pivot is the rotation centre instead (unchanged behaviour).
    func testADroppedPivotIsTheRotationCentre() throws {
        let vm = try makeViewModel()
        let box = addBox(to: vm, at: SIMD3(3, 0, 0))
        vm.selection = [box.id]
        vm.mode = .selected(box.id)
        vm.toggleGizmoReposition()
        vm.setGizmoPivot(world: SIMD3(3, 0, 0))   // the base centre, as before
        vm.beginAngleEntry(.xRing)
        vm.commitAngleRotate(degrees: 90)
        let after = try XCTUnwrap(vm.session.document.body(with: box.id))
        XCTAssertEqual(after.transform.translation.x, 3, accuracy: 1e-6)
        XCTAssertEqual(after.transform.translation.y, 0, accuracy: 1e-6)
        XCTAssertEqual(after.transform.translation.z, 0, accuracy: 1e-6)
    }
}
