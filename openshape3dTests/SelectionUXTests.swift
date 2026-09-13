//
//  SelectionUXTests.swift
//  openshape3dTests
//
//  Selection UX (plan §B13 UI, spec §8.2–8.3): select-mode toggle + marquee
//  lifecycle, the Bodies | Sketches filter chips, multi-selection info-bar
//  rows (count + combined bounds), and Select Through candidate routing.
//

import XCTest
import SwiftData
import simd
import Euclid
@testable import openshape3d

@MainActor
final class SelectionUXTests: XCTestCase {

    /// See SelectionTests.retainedViewModels: MainActor class dealloc inside
    /// an XCTest invocation crashes the simulator runtime, so view models
    /// leak deliberately.
    private static var retainedViewModels: [EditorViewModel] = []

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
        let project = Project(name: "Selection UX Test")
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

    /// Top-down orthographic mock projection: screen = world (x, z).
    private let topDownProject: (SIMD3<Float>) -> SIMD2<Double>? = {
        SIMD2(Double($0.x), Double($0.z))
    }

    // MARK: - Filter (AreaSelect + chips)

    func testSketchEntitiesOnlyFilterSkipsBodies() {
        let body = BodyID()
        let entity = UUID()
        let candidates = [
            AreaSelectCandidate(item: .body(body), points: [SIMD3(1, 1, 0)]),
            AreaSelectCandidate(item: .sketchEntity(entity), points: [SIMD3(2, 2, 0)]),
        ]
        let items = AreaSelect.select(
            candidates: candidates,
            dragStart: SIMD2(0, 0), dragEnd: SIMD2(10, 10),
            filter: .sketchEntitiesOnly,
            project: { SIMD2(Double($0.x), Double($0.y)) }
        )
        XCTAssertEqual(items, [.sketchEntity(entity)])
    }

    func testFilterChipsMapToFilterAndKeepOneKindOn() throws {
        let viewModel = try makeViewModel()
        XCTAssertEqual(viewModel.areaSelectFilter, .bodiesAndSketchEntities)

        viewModel.toggleAreaSelectSketches()
        XCTAssertEqual(viewModel.areaSelectFilter, .bodiesOnly)

        // Turning Bodies off while Sketches is off would leave nothing — the
        // toggle refuses.
        viewModel.toggleAreaSelectBodies()
        XCTAssertTrue(viewModel.areaSelectIncludesBodies)
        XCTAssertEqual(viewModel.areaSelectFilter, .bodiesOnly)

        viewModel.toggleAreaSelectSketches()
        viewModel.toggleAreaSelectBodies()
        XCTAssertEqual(viewModel.areaSelectFilter, .sketchEntitiesOnly)
    }

    // MARK: - Select mode + marquee lifecycle

    func testSelectModeMarqueeSelectsAdditively() throws {
        let viewModel = try makeViewModel()
        let a = addBox(to: viewModel, name: "A", at: .zero)          // x,z ∈ [-1, 1]
        let b = addBox(to: viewModel, name: "B", at: SIMD3(10, 0, 0)) // x ∈ [9, 11]

        // Outside select mode a drag never becomes a marquee.
        XCTAssertFalse(viewModel.beginMarquee(at: SIMD2(0, 0)))

        viewModel.toggleSelectMode()
        XCTAssertTrue(viewModel.selectModeActive)
        XCTAssertTrue(viewModel.selectionAdditive)

        // Window (L→R) marquee around A.
        XCTAssertTrue(viewModel.beginMarquee(at: SIMD2(-2, -2)))
        viewModel.updateMarquee(to: SIMD2(2, 2))
        XCTAssertEqual(viewModel.marqueeState?.isWindow, true)
        viewModel.endMarquee(project: topDownProject)
        XCTAssertNil(viewModel.marqueeState)
        XCTAssertEqual(viewModel.selection, [a.id])

        // Crossing (R→L) marquee over B adds to the selection (additive).
        XCTAssertTrue(viewModel.beginMarquee(at: SIMD2(12, 2)))
        viewModel.updateMarquee(to: SIMD2(8, -2))
        XCTAssertEqual(viewModel.marqueeState?.isWindow, false)
        viewModel.endMarquee(project: topDownProject)
        XCTAssertEqual(viewModel.selection, [a.id, b.id])

        viewModel.exitSelectMode()
        XCTAssertFalse(viewModel.selectModeActive)
        XCTAssertFalse(viewModel.selectionAdditive)
        XCTAssertNil(viewModel.marqueeState)
        // The selection survives leaving select mode.
        XCTAssertEqual(viewModel.selection, [a.id, b.id])
    }

    func testMarqueeIsRefusedWhileAToolOwnsInput() throws {
        let viewModel = try makeViewModel()
        addBox(to: viewModel, name: "A", at: .zero)
        viewModel.toggleSelectMode()
        viewModel.toggleMeasure() // .measuring is not a passive mode
        XCTAssertFalse(viewModel.beginMarquee(at: SIMD2(0, 0)))
    }

    // MARK: - Multi-selection info bar

    func testMultiSelectionMeasurementsShowCountAndCombinedBounds() throws {
        let viewModel = try makeViewModel()
        let a = addBox(to: viewModel, name: "A", at: .zero)
        let b = addBox(to: viewModel, name: "B", at: SIMD3(10, 0, 0))

        viewModel.toggleSelection(of: a.id)
        viewModel.toggleSelection(of: b.id)

        let rows = viewModel.selectionMeasurements
        XCTAssertEqual(rows.count, 2)
        XCTAssertEqual(rows[0].label, "Selected")
        XCTAssertEqual(rows[0].value, "2 bodies")
        XCTAssertEqual(rows[1].label, "Bounds")
        // Combined AABB: x -1…11, y 0…2, z -1…1.
        XCTAssertEqual(rows[1].value, "12.00 × 2.00 × 2.00 mm")
    }

    // MARK: - Select Through

    func testBodyRenameHistoryClearsSelectionWithoutChangingGeometry() throws {
        let vm = try makeViewModel()
        let body = addBox(to: vm, name: "Original", at: .zero)
        vm.selectItemBody(body.id)
        vm.renameItem(.body(body.id), to: "part24")
        XCTAssertEqual(vm.selection, [body.id])
        vm.undo()
        XCTAssertEqual(vm.session.document.body(with: body.id)?.name, "Original")
        XCTAssertTrue(vm.selection.isEmpty)
        XCTAssertEqual(vm.mode, .idle)
        vm.selectItemBody(body.id)
        vm.redo()
        XCTAssertEqual(vm.session.document.body(with: body.id)?.name, "part24")
        XCTAssertTrue(vm.selection.isEmpty)
        XCTAssertEqual(vm.mode, .idle)
        XCTAssertEqual(vm.session.document.bodies.count, 1)
        XCTAssertEqual(vm.session.document.body(with: body.id)?.transform, body.transform)
    }

    func testSelectThroughIncludesFrontAndBackFacesAlongsideBody() throws {
        let viewModel = try makeViewModel()
        addBox(to: viewModel, name: "Layered Box", at: .zero)
        viewModel.presentSelectThrough(ray: Ray(
            origin: SIMD3(0.2, 20, 0.3), direction: SIMD3(0, -1, 0)))
        let candidates = try XCTUnwrap(viewModel.selectThroughCandidates)
        XCTAssertEqual(candidates.filter { $0.name == "Layered Box" }.count, 1)
        XCTAssertEqual(candidates.filter { $0.name.hasPrefix("Face") }.count, 2,
                       "Select Through must expose front and back faces, not only the body")
    }

    func testSelectThroughFaceAndOccludedProfileChoicesDoNotEditGeometry() throws {
        let vm = try makeViewModel()
        let body = addBox(to: vm, name: "Solid", at: .zero)
        let sketch = Sketch(name: "Base", plane: .ground,
                            entities: [.circle(id: UUID(), center: .zero, radius: 0.8)])
        vm.session.perform(AddSketchCommand(sketch: sketch))
        let ray = Ray(origin: SIMD3(0.2, 20, 0.3), direction: SIMD3(0, -1, 0))
        vm.presentSelectThrough(ray: ray)
        let choices = try XCTUnwrap(vm.selectThroughCandidates)
        let faces = choices.filter { if case .face = $0.target { return true }; return false }
        XCTAssertEqual(faces.count, 2)
        for (index, face) in faces.enumerated() {
            vm.chooseSelectThrough(face)
            XCTAssertEqual(vm.mode, .faceSelected(body.id))
            XCTAssertEqual(vm.toolContext?.sourceBody, body.id)
            XCTAssertEqual(try XCTUnwrap(vm.toolContext).plane.origin.y,
                           index == 0 ? 2 : 0, accuracy: 1e-6)
        }
        let profile = try XCTUnwrap(choices.first { if case .profile = $0.target { return true }; return false })
        vm.chooseSelectThrough(profile)
        XCTAssertEqual(vm.mode, .extruding)
        XCTAssertEqual(vm.toolContext?.sketchID, sketch.id)
        XCTAssertNil(vm.toolContext?.sourceBody)
        XCTAssertEqual(vm.session.document.bodies.count, 1)
        XCTAssertEqual(vm.session.document.sketches.first?.entities, sketch.entities)
        vm.cancelTool()
        XCTAssertEqual(vm.session.document.bodies.count, 1)
        vm.setItemHidden(.sketch(sketch.id), hidden: true)
        vm.presentSelectThrough(ray: ray)
        XCTAssertFalse(try XCTUnwrap(vm.selectThroughCandidates).contains {
            if case .profile = $0.target { return true }; return false
        })
        vm.chooseSelectThrough(profile) // stale hidden profile cannot arm extrusion
        XCTAssertNotEqual(vm.mode, .extruding)
        XCTAssertEqual(vm.session.document.bodies.count, 1)
    }

    func testSelectThroughListsHitsFrontToBackAndChoosingSelects() throws {
        let viewModel = try makeViewModel()
        let near = addBox(to: viewModel, name: "Near", at: SIMD3(0, 5, 0)) // y 5…7
        let far = addBox(to: viewModel, name: "Far", at: .zero)            // y 0…2

        // Ray straight down through both boxes.
        let ray = Ray(origin: SIMD3(0, 20, 0), direction: SIMD3(0, -1, 0))
        viewModel.presentSelectThrough(ray: ray)
        let candidates = try XCTUnwrap(viewModel.selectThroughCandidates)
        XCTAssertEqual(candidates.filter(\.isBody).map(\.name), ["Near", "Far"])

        viewModel.chooseSelectThrough(far.id)
        XCTAssertNil(viewModel.selectThroughCandidates)
        XCTAssertEqual(viewModel.selection, [far.id])
        XCTAssertEqual(viewModel.mode, .selected(far.id))

        // Additive (select mode): choosing the other body extends.
        viewModel.toggleSelectMode()
        viewModel.presentSelectThrough(ray: ray)
        viewModel.chooseSelectThrough(near.id)
        XCTAssertEqual(viewModel.selection, [far.id, near.id])
    }

    /// Active tools keep their long-presses: no popup while measuring.
    func testSelectThroughIsRefusedWhileAToolOwnsInput() throws {
        let viewModel = try makeViewModel()
        addBox(to: viewModel, name: "A", at: .zero)
        viewModel.toggleMeasure()
        viewModel.presentSelectThrough(
            ray: Ray(origin: SIMD3(0, 20, 0), direction: SIMD3(0, -1, 0))
        )
        XCTAssertNil(viewModel.selectThroughCandidates)
    }
}
