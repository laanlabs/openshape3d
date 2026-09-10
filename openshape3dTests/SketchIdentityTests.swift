import XCTest
import SwiftData
@testable import openshape3d

@MainActor
final class SketchIdentityTests: XCTestCase {
    private static var retained: [EditorViewModel] = []

    private func makeViewModel() throws -> EditorViewModel {
        let schema = Schema([Project.self, PersistedBody.self, PersistedSketch.self,
                             PersistedPlane.self, PersistedImage.self, PersistedSymbol.self])
        let container = try ModelContainer(for: schema,
            configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)])
        let context = ModelContext(container)
        let project = Project(name: "Independent coplanar sketches")
        context.insert(project)
        let vm = EditorViewModel(project: project, modelContext: context)
        Self.retained.append(vm)
        return vm
    }

    private func enterGround(_ vm: EditorViewModel) throws -> Sketch {
        vm.startSketch(tool: .line)
        vm.handle(.tap(ray: Ray(origin: SIMD3(50, 10, 50), direction: SIMD3(0, -1, 0))))
        let sketch = try XCTUnwrap(vm.activeSketch)
        XCTAssertTrue(sketch.plane.isCoincident(with: .ground))
        return sketch
    }

    func testNewCoplanarEntryKeepsSeparateOwnershipAndUndo() throws {
        let vm = try makeViewModel()
        let first = try enterGround(vm)
        let circle = SketchEntity.circle(id: UUID(), center: .zero, radius: 2)
        vm.session.perform(AddSketchEntityCommand(sketchID: first.id, entity: circle))
        vm.finishSketch()
        let second = try enterGround(vm)
        XCTAssertNotEqual(first.id, second.id)
        XCTAssertNotEqual(first.name, second.name)
        XCTAssertTrue(second.entities.isEmpty)
        let line = SketchEntity.line(id: UUID(), a: SIMD2(10, 10), b: SIMD2(20, 10))
        vm.session.perform(AddSketchEntityCommand(sketchID: second.id, entity: line))
        vm.finishSketch()
        XCTAssertEqual(vm.session.document.sketches.first { $0.id == first.id }?.entities, [circle])
        XCTAssertEqual(vm.session.document.sketches.first { $0.id == second.id }?.entities, [line])
        vm.undo()
        XCTAssertEqual(vm.session.document.sketches.first { $0.id == first.id }?.entities, [circle])
        XCTAssertTrue(vm.session.document.sketches.first { $0.id == second.id }!.entities.isEmpty)
        vm.redo()
        XCTAssertEqual(vm.session.document.sketches.first { $0.id == second.id }?.entities, [line])
        let decoded = try JSONDecoder().decode(Sketch.self, from: JSONEncoder().encode(vm.session.document.sketches[1]))
        XCTAssertEqual(decoded.id, second.id)
        XCTAssertEqual(decoded.entities, [line])
    }

    func testEmptyNewEntryDoesNotUnhideOrRemoveExistingSketch() throws {
        let vm = try makeViewModel()
        var original = Sketch(name: "Consumed", plane: .ground,
            entities: [.circle(id: UUID(), center: .zero, radius: 2)])
        original.isHidden = true
        vm.session.perform(AddSketchCommand(sketch: original))
        let fresh = try enterGround(vm)
        XCTAssertNotEqual(fresh.id, original.id)
        XCTAssertEqual(vm.itemSketches, [original])
        vm.finishSketch()
        XCTAssertEqual(vm.session.document.sketches, [original])
    }

    func testNewEntryItemsRowFollowsGeometryWithoutRemovingHistoryIdentity() throws {
        let vm = try makeViewModel()
        let persisted = Sketch(name: "Persisted empty", plane: .ground)
        vm.session.perform(AddSketchCommand(sketch: persisted))
        let fresh = try enterGround(vm)
        XCTAssertEqual(vm.itemSketches.map(\.id), [persisted.id])
        let line = SketchEntity.line(id: UUID(), a: .zero, b: SIMD2(2, 0))
        vm.session.perform(AddSketchEntityCommand(sketchID: fresh.id, entity: line))
        XCTAssertEqual(vm.itemSketches.map(\.id), [persisted.id, fresh.id])
        vm.undo()
        XCTAssertEqual(vm.itemSketches.map(\.id), [persisted.id])
        XCTAssertTrue(vm.session.document.sketches.contains { $0.id == fresh.id },
                      "Only presentation hides the empty row; Redo retains its target")
        vm.redo()
        XCTAssertEqual(vm.itemSketches.last?.entities, [line])
    }

    func testExplicitNamedContinuationKeepsIdentityAcrossToolSwitches() throws {
        let vm = try makeViewModel()
        let first = Sketch(name: "First", plane: .ground)
        let second = Sketch(name: "Second", plane: .ground)
        vm.session.perform(AddSketchCommand(sketch: first))
        vm.session.perform(AddSketchCommand(sketch: second))
        vm.openItemSketch(second.id)
        vm.startSketch(tool: .line)
        XCTAssertEqual(vm.activeSketch?.id, second.id)
        vm.startSketch(tool: .circle)
        XCTAssertEqual(vm.activeSketch?.id, second.id)
        vm.finishSketch()
        XCTAssertEqual(vm.session.document.sketches.count, 2)
        vm.openItemSketch(first.id)
        XCTAssertEqual(vm.activeSketch?.id, first.id)
    }

    func testReferenceProfilesStayClearDuringSketchingButReturnForModelHandoff() throws {
        let vm = try makeViewModel()
        let reference = Sketch(name: "Reference", plane: .ground,
            entities: [.circle(id: UUID(), center: .zero, radius: 2)])
        vm.session.perform(AddSketchCommand(sketch: reference))
        XCTAssertFalse(vm.scene.profileFills.isEmpty,
                       "Closed regions remain visible for model-mode extrusion")
        let active = try enterGround(vm)
        XCTAssertNotEqual(active.id, reference.id)
        XCTAssertTrue(vm.scene.profileFills.isEmpty,
                      "An inactive coplanar circle must not appear as a filled active region")
        XCTAssertFalse(vm.scene.sketchLines.isEmpty, "Reference outlines remain visible")
        vm.finishSketch()
        XCTAssertFalse(vm.scene.profileFills.isEmpty)
    }
}
