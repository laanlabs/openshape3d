//
//  SelectionTests.swift
//  openshape3dTests
//
//  Selection system core (plan §B13, spec §8.1–8.3): area-select window vs
//  crossing membership with a mock projection, additive multi-select
//  toggling, the shared-centroid gizmo origin, and Select Through's
//  pickAllBodies ordering.
//

import XCTest
import SwiftData
import simd
import Euclid
@testable import openshape3d

@MainActor
final class SelectionTests: XCTestCase {

    // MARK: - AreaSelect (pure logic, mock projection)

    /// Screen space = world (x, y); points with z < 0 are "behind the
    /// camera" and don't project.
    private let mockProject: (SIMD3<Float>) -> SIMD2<Double>? = { world in
        guard world.z >= 0 else { return nil }
        return SIMD2(Double(world.x), Double(world.y))
    }

    private func candidate(
        _ item: AreaSelectCandidate.Item,
        points: [SIMD3<Float>],
        hidden: Bool = false
    ) -> AreaSelectCandidate {
        AreaSelectCandidate(item: item, points: points, isHidden: hidden)
    }

    func testModeFollowsDragDirection() {
        XCTAssertEqual(
            AreaSelect.mode(dragStart: SIMD2(0, 0), dragEnd: SIMD2(10, 5)), .window
        )
        XCTAssertEqual(
            AreaSelect.mode(dragStart: SIMD2(10, 0), dragEnd: SIMD2(0, 5)), .crossing
        )
    }

    func testWindowSelectsOnlyFullyInsideItems() {
        let inside = BodyID()
        let straddling = BodyID()
        let outside = BodyID()
        let candidates = [
            candidate(.body(inside), points: [SIMD3(1, 1, 0), SIMD3(2, 2, 0)]),
            candidate(.body(straddling), points: [SIMD3(1, 1, 0), SIMD3(20, 1, 0)]),
            candidate(.body(outside), points: [SIMD3(30, 30, 0)]),
        ]
        // Left→right drag = window.
        let items = AreaSelect.select(
            candidates: candidates,
            dragStart: SIMD2(0, 0), dragEnd: SIMD2(10, 10),
            filter: .bodiesOnly,
            project: mockProject
        )
        XCTAssertEqual(items, [.body(inside)])
    }

    func testCrossingSelectsAnyVertexInside() {
        let inside = BodyID()
        let straddling = BodyID()
        let outside = BodyID()
        let candidates = [
            candidate(.body(inside), points: [SIMD3(1, 1, 0), SIMD3(2, 2, 0)]),
            candidate(.body(straddling), points: [SIMD3(1, 1, 0), SIMD3(20, 1, 0)]),
            candidate(.body(outside), points: [SIMD3(30, 30, 0)]),
        ]
        // Right→left drag = crossing.
        let items = AreaSelect.select(
            candidates: candidates,
            dragStart: SIMD2(10, 0), dragEnd: SIMD2(0, 10),
            filter: .bodiesOnly,
            project: mockProject
        )
        XCTAssertEqual(Set(items), [.body(inside), .body(straddling)])
    }

    func testHiddenItemsAndFilteredKindsAreSkipped() {
        let hiddenBody = BodyID()
        let entity = UUID()
        let candidates = [
            candidate(.body(hiddenBody), points: [SIMD3(1, 1, 0)], hidden: true),
            candidate(.sketchEntity(entity), points: [SIMD3(2, 2, 0)]),
        ]
        let bodiesOnly = AreaSelect.select(
            candidates: candidates,
            dragStart: SIMD2(0, 0), dragEnd: SIMD2(10, 10),
            filter: .bodiesOnly,
            project: mockProject
        )
        XCTAssertTrue(bodiesOnly.isEmpty)

        let withSketches = AreaSelect.select(
            candidates: candidates,
            dragStart: SIMD2(0, 0), dragEnd: SIMD2(10, 10),
            filter: .bodiesAndSketchEntities,
            project: mockProject
        )
        XCTAssertEqual(withSketches, [.sketchEntity(entity)])
    }

    func testUnprojectablePointsBreakWindowButNotCrossing() {
        // One vertex is behind the camera (z < 0 → projection nil).
        let id = BodyID()
        let candidates = [
            candidate(.body(id), points: [SIMD3(1, 1, 0), SIMD3(2, 2, -1)]),
        ]
        let window = AreaSelect.select(
            candidates: candidates,
            dragStart: SIMD2(0, 0), dragEnd: SIMD2(10, 10),
            filter: .bodiesOnly,
            project: mockProject
        )
        XCTAssertTrue(window.isEmpty)

        let crossing = AreaSelect.select(
            candidates: candidates,
            dragStart: SIMD2(10, 0), dragEnd: SIMD2(0, 10),
            filter: .bodiesOnly,
            project: mockProject
        )
        XCTAssertEqual(crossing, [.body(id)])
    }

    // MARK: - Additive selection toggling (EditorViewModel routing)

    /// The current simulator's Swift runtime crashes (malloc double-free in
    /// `swift_task_deinitOnExecutorImpl`) when a MainActor-isolated class
    /// deallocates inside an XCTest invocation, so every view model built
    /// here is retained for the process lifetime — the leak is deliberate.
    private static var retainedViewModels: [EditorViewModel] = []

    private func makeViewModel() throws -> EditorViewModel {
        // Full app schema (matches openshape3dApp) so the test container
        // doesn't fight the host app's registered entities.
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
        let project = Project(name: "Selection Test")
        context.insert(project)
        let viewModel = EditorViewModel(project: project, modelContext: context)
        Self.retainedViewModels.append(viewModel)
        return viewModel
    }

    @discardableResult
    private func addBox(
        to viewModel: EditorViewModel, name: String, at translation: SIMD3<Double>
    ) -> Body {
        var transform = Transform3D.identity
        transform.translation = translation
        var document = viewModel.session.document // nextRevision is mutating
        let body = Body(
            name: name,
            transform: transform,
            euclidMesh: .primitive(.box(width: 2, depth: 2, height: 2)),
            revision: document.nextRevision()
        )
        viewModel.session.perform(AddBodyCommand(body: body))
        return body
    }

    /// Shapr3D (observed 2026-09-13 on a probe cylinder): a click on a body
    /// EDGE selects the edge — "1 edge", length and radius readouts — and
    /// offers Chamfer/Fillet. Here that is the blend pick armed with the edge
    /// already chosen; a tap on the face interior still selects the face.
    func testTapNearABodyEdgeArmsFilletOnThatEdge() throws {
        let vm = try makeViewModel()
        let box = addBox(to: vm, name: "Block", at: .zero)   // x,z in −1…1, y in 0…2
        // 0.03 inside the top face's +x edge: within the 8 pt edge target.
        vm.handle(.tap(ray: Ray(origin: SIMD3(0.97, 10, 0.3), direction: SIMD3(0, -1, 0))))
        XCTAssertEqual(vm.mode, .pickingBlendEdges(.fillet))
        XCTAssertEqual(vm.blendSelectedEdges.count, 1, "the edge under the finger, not the whole face")
        XCTAssertEqual(vm.blendBodyID, box.id)
        let rows = vm.selectionMeasurements
        XCTAssertEqual(rows.first { $0.label == "Edges" }?.value, "1")
        XCTAssertEqual(rows.first { $0.label == "Length" }?.value, "2.00 mm")

        // Well inside the face: the face, as before.
        vm.cancelBlend()
        XCTAssertEqual(vm.mode, .selected(box.id), "leaving the blend keeps the body selected")
        vm.handle(.tap(ray: Ray(origin: SIMD3(0.5, 10, 0.3), direction: SIMD3(0, -1, 0))))
        XCTAssertEqual(vm.mode, .faceSelected(box.id))
    }

    /// A tap on the middle of a cylinder wall is the wall (the radial
    /// diameter edit), never a rim edge — CylinderGrowShotUITests caught the
    /// edge target firing on a 2 mm-tall wall.
    func testTapOnACylinderWallMidHeightArmsTheRadialEditNotAFillet() throws {
        let vm = try makeViewModel()
        let spec = PrimitiveSpec.cylinder(radius: 1.5, height: 2)
        var document = vm.session.document
        let drum = Body(name: "Drum", transform: .identity, primitive: spec,
                        euclidMesh: .primitive(spec), revision: document.nextRevision())
        vm.session.perform(AddBodyCommand(body: drum))
        // Sideways into the wall at mid-height (the wall spans y 0…2).
        vm.handle(.tap(ray: Ray(origin: SIMD3(10, 1, 0), direction: SIMD3(-1, 0, 0))))
        XCTAssertEqual(vm.mode, .faceSelected(drum.id), "\(vm.mode)")
        XCTAssertNotNil(vm.toolContext?.cylinderFace)
        XCTAssertNil(vm.blendBodyID)
    }

    /// Shapr3D's Select Through on a curved wall lists the wall faces, the
    /// body and the sketch profile behind (observed 2026-09-13). The clone
    /// used to keep only the body for a curved hit; choosing the wall now
    /// lands where a direct tap lands — a plain cylinder's radial edit.
    func testSelectThroughOffersACurvedWallAndChoosingItArmsTheRadialEdit() throws {
        let vm = try makeViewModel()
        let spec = PrimitiveSpec.cylinder(radius: 2, height: 4)
        var document = vm.session.document
        let cylinder = Body(name: "Drum", transform: .identity, primitive: spec,
                            euclidMesh: .primitive(spec), revision: document.nextRevision())
        vm.session.perform(AddBodyCommand(body: cylinder))
        // Sideways through the wall at mid-height.
        vm.presentSelectThrough(ray: Ray(origin: SIMD3(10, 2, 0), direction: SIMD3(-1, 0, 0)))
        let candidates = try XCTUnwrap(vm.selectThroughCandidates)
        let faces = candidates.filter { if case .face = $0.target { return true }; return false }
        XCTAssertFalse(faces.isEmpty, "the curved wall is a choice, not just the body")
        XCTAssertTrue(faces.allSatisfy { $0.name == "Face — Drum" })
        XCTAssertTrue(candidates.contains { if case .body(let id) = $0.target { return id == cylinder.id }; return false })
        vm.chooseSelectThrough(try XCTUnwrap(faces.first))
        XCTAssertEqual(vm.selection, [cylinder.id])
        XCTAssertEqual(vm.mode, .faceSelected(cylinder.id))
        XCTAssertNotNil(vm.toolContext?.cylinderFace, "a plain cylinder's wall arms the radial push/pull")
        XCTAssertEqual(vm.session.document.bodies.count, 1, "choosing never edits geometry")
    }

    func testAdditiveToggleAddsAndRemovesBodies() throws {
        let viewModel = try makeViewModel()
        let a = addBox(to: viewModel, name: "A", at: .zero)
        let b = addBox(to: viewModel, name: "B", at: SIMD3(10, 0, 0))

        viewModel.toggleSelection(of: a.id)
        XCTAssertEqual(viewModel.selection, [a.id])
        XCTAssertEqual(viewModel.mode, .selected(a.id))

        viewModel.toggleSelection(of: b.id)
        XCTAssertEqual(viewModel.selection, [a.id, b.id])
        if case .selected = viewModel.mode {} else {
            XCTFail("Multi-selection should stay in .selected, got \(viewModel.mode)")
        }

        viewModel.toggleSelection(of: a.id)
        XCTAssertEqual(viewModel.selection, [b.id])
        XCTAssertEqual(viewModel.mode, .selected(b.id))

        viewModel.toggleSelection(of: b.id)
        XCTAssertTrue(viewModel.selection.isEmpty)
        XCTAssertEqual(viewModel.mode, .idle)
    }

    func testAdditiveViewportTapsToggleAndEmptyTapKeepsSelection() throws {
        let viewModel = try makeViewModel()
        let a = addBox(to: viewModel, name: "A", at: .zero)
        let b = addBox(to: viewModel, name: "B", at: SIMD3(10, 0, 0))
        viewModel.selectionAdditive = true

        let down = SIMD3<Float>(0, -1, 0)
        viewModel.handle(.tap(ray: Ray(origin: SIMD3(0, 10, 0), direction: down)))
        XCTAssertEqual(viewModel.selection, [a.id])

        viewModel.handle(.tap(ray: Ray(origin: SIMD3(10, 10, 0), direction: down)))
        XCTAssertEqual(viewModel.selection, [a.id, b.id])

        // Additive tap on empty space keeps the selection (Shift-click).
        viewModel.handle(.tap(ray: Ray(origin: SIMD3(50, 10, 50), direction: down)))
        XCTAssertEqual(viewModel.selection, [a.id, b.id])

        // Tapping a selected body again removes it.
        viewModel.handle(.tap(ray: Ray(origin: SIMD3(0, 10, 0), direction: down)))
        XCTAssertEqual(viewModel.selection, [b.id])
    }

    func testGizmoOriginIsSharedCentroidForMultiSelection() throws {
        let viewModel = try makeViewModel()
        let a = addBox(to: viewModel, name: "A", at: .zero)
        let b = addBox(to: viewModel, name: "B", at: SIMD3(4, 2, 0))

        viewModel.toggleSelection(of: a.id)
        viewModel.toggleSelection(of: b.id)
        let origin = try XCTUnwrap(viewModel.gizmoOrigin)
        XCTAssertEqual(origin.x, 2, accuracy: 1e-5)
        XCTAssertEqual(origin.y, 1, accuracy: 1e-5)
        XCTAssertEqual(origin.z, 0, accuracy: 1e-5)
    }

    func testPerformAreaSelectWindowAndCrossingOnDocumentBodies() throws {
        let viewModel = try makeViewModel()
        let a = addBox(to: viewModel, name: "A", at: .zero)          // x,z ∈ [-1, 1]
        let b = addBox(to: viewModel, name: "B", at: SIMD3(10, 0, 0)) // x ∈ [9, 11]

        // Top-down orthographic mock: screen = world (x, z).
        let project: (SIMD3<Float>) -> SIMD2<Double>? = {
            SIMD2(Double($0.x), Double($0.z))
        }

        // Window (left→right) around A only.
        viewModel.performAreaSelect(
            dragStart: SIMD2(-2, -2), dragEnd: SIMD2(2, 2), project: project
        )
        XCTAssertEqual(viewModel.selection, [a.id])
        XCTAssertEqual(viewModel.mode, .selected(a.id))

        // Crossing (right→left) touching only B's left vertices at x = 9.
        viewModel.performAreaSelect(
            dragStart: SIMD2(9.5, 2), dragEnd: SIMD2(8, -2), project: project
        )
        XCTAssertEqual(viewModel.selection, [b.id])

        // The same rect as a window drag selects nothing (B not fully inside).
        viewModel.performAreaSelect(
            dragStart: SIMD2(8, -2), dragEnd: SIMD2(9.5, 2), project: project
        )
        XCTAssertTrue(viewModel.selection.isEmpty)
        XCTAssertEqual(viewModel.mode, .idle)
    }

    // MARK: - Select Through (pickAllBodies)

    func testPickAllBodiesReturnsAllHitsSortedByDistance() {
        // Two stacked 2×2×2 boxes: A spans y ∈ [0, 2], B spans y ∈ [5, 7].
        let boxA = Body(
            name: "A", euclidMesh: .primitive(.box(width: 2, depth: 2, height: 2)),
            revision: 1
        )
        var transformB = Transform3D.identity
        transformB.translation = SIMD3(0, 5, 0)
        let boxB = Body(
            name: "B", transform: transformB,
            euclidMesh: .primitive(.box(width: 2, depth: 2, height: 2)),
            revision: 2
        )
        let scene = ViewportScene(bodies: [boxA, boxB].map { body in
            BodyDrawable(
                id: body.id,
                renderMesh: body.render,
                edges: body.edges,
                meshRevision: body.meshRevision,
                modelMatrix: body.transform.matrixFloat,
                baseColor: SIMD4(0.72, 0.74, 0.78, 1)
            )
        })

        let ray = Ray(origin: SIMD3(0, 20, 0), direction: SIMD3(0, -1, 0))
        let hits = HitTester.pickAllBodies(ray: ray, in: scene)
        XCTAssertEqual(hits.count, 2)
        XCTAssertEqual(hits.map(\.bodyID), [boxB.id, boxA.id])
        XCTAssertEqual(hits[0].distance, 13, accuracy: 1e-3)
        XCTAssertEqual(hits[1].distance, 18, accuracy: 1e-3)
        XCTAssertLessThan(hits[0].distance, hits[1].distance)

        // Consistency with the single-hit picker: same nearest body.
        XCTAssertEqual(HitTester.pickBody(ray: ray, in: scene)?.bodyID, boxB.id)
    }
}
