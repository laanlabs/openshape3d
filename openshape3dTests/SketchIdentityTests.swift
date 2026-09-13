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

    func testItemsEntrySelectsOnlyNamedSketchAndRetainsUntouchedSelectionOnExit() throws {
        let vm = try makeViewModel()
        let line = SketchEntity.line(id: UUID(), a: .zero, b: SIMD2(3, 0))
        let circle = SketchEntity.circle(id: UUID(), center: SIMD2(5, 2), radius: 1)
        let named = Sketch(name: "Named", plane: .ground, entities: [line, circle])
        let other = Sketch(name: "Other", plane: .ground,
            entities: [.circle(id: UUID(), center: .zero, radius: 7)])
        vm.session.perform(AddSketchCommand(sketch: named))
        vm.session.perform(AddSketchCommand(sketch: other))
        let original = vm.session.document.sketches
        vm.selectItemSketch(named.id)
        XCTAssertEqual(vm.activeSketch?.id, named.id)
        XCTAssertEqual(vm.selectedSketchEntityIDs, Set([line.id, circle.id]))
        vm.finishSketch()
        XCTAssertEqual(vm.selectedSketchEntityIDs, Set([line.id, circle.id]))
        XCTAssertEqual(vm.session.document.sketches, original)
        vm.openItemSketch(other.id)
        XCTAssertTrue(vm.selectedSketchEntityIDs.isEmpty,
                      "Non-Items entry must retain its existing passive semantics")
        vm.finishSketch()
        vm.selectItemSketch(named.id)
        vm.selectedSketchEntityIDs.removeAll()
        vm.finishSketch()
        XCTAssertTrue(vm.selectedSketchEntityIDs.isEmpty,
                      "Explicit deselection must not be resurrected on Exit")
        vm.selectItemSketch(named.id)
        vm.finishSketch()
        vm.renameItem(.sketch(named.id), to: "Renamed")
        vm.undo()
        XCTAssertTrue(vm.selectedSketchEntityIDs.isEmpty,
                      "Native sketch Rename Undo clears retained item selection")
        vm.selectItemSketch(named.id)
        vm.finishSketch()
        vm.redo()
        XCTAssertTrue(vm.selectedSketchEntityIDs.isEmpty,
                      "Native sketch Rename Redo clears retained item selection")
        XCTAssertEqual(vm.session.document.sketches.first { $0.id == named.id }?.name, "Renamed")
    }

    func testItemsExitRetainsSelectionMeasurementsWithoutUnrelatedGeometry() throws {
        let vm = try makeViewModel()
        let first = SketchEntity.line(id: UUID(), a: .zero, b: SIMD2(3, 0))
        let second = SketchEntity.line(id: UUID(), a: SIMD2(0, 2), b: SIMD2(4, 2))
        let named = Sketch(name: "Named", plane: .ground, entities: [first, second])
        let other = Sketch(name: "Other", plane: .ground,
            entities: [.circle(id: UUID(), center: .zero, radius: 100)])
        vm.session.perform(AddSketchCommand(sketch: named))
        vm.session.perform(AddSketchCommand(sketch: other))
        vm.selectItemSketch(named.id)
        let activeLength = vm.selectionMeasurements.first { $0.label == "Total Length" }?.value
        XCTAssertEqual(activeLength, EditorViewModel.formattedLength(7))
        vm.finishSketch()
        XCTAssertEqual(vm.selectionMeasurements.first { $0.label == "Total Length" }?.value, activeLength)
        XCTAssertEqual(vm.selectionMeasurements.first { $0.label == "Edges" }?.value, "2")
        vm.selectedSketchEntityIDs = [first.id, UUID()]
        XCTAssertEqual(vm.selectionMeasurements.first { $0.label == "Length" }?.value,
                       EditorViewModel.formattedLength(3))
        XCTAssertEqual(vm.selectionMeasurements.first { $0.label == "Edges" }?.value, "1")
        vm.selectedSketchEntityIDs.removeAll()
        XCTAssertTrue(vm.selectionMeasurements.isEmpty)
        XCTAssertEqual(vm.session.document.sketches, [named, other])
        let rectangle = SketchEntity.rect(id: UUID(), lo: .zero, hi: SIMD2(3, 4))
        let polygon = SketchEntity.polygon(id: UUID(), center: SIMD2(8, 0), radius: 2, sides: 5, rotation: 0)
        let loops = Sketch(name: "Loops", plane: .ground, entities: [rectangle, polygon])
        vm.session.perform(AddSketchCommand(sketch: loops))
        vm.selectItemSketch(loops.id)
        vm.finishSketch()
        XCTAssertEqual(vm.selectionMeasurements.first { $0.label == "Edges" }?.value, "9",
                       "Primitive loops count their actual edges, not storage records")
        XCTAssertEqual(vm.selectionMeasurements.first { $0.label == "Total Length" }?.value,
                       EditorViewModel.formattedLength(14 + 20 * sin(.pi / 5)))
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
