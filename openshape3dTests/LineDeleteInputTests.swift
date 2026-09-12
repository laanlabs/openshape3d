import XCTest
import SwiftData
import simd
@testable import openshape3d

@MainActor
final class LineDeleteInputTests: XCTestCase {
    private static var retained: [EditorViewModel] = []

    private func makeViewModel() throws -> EditorViewModel {
        let schema = Schema([Project.self, PersistedBody.self, PersistedSketch.self,
                             PersistedPlane.self, PersistedImage.self, PersistedSymbol.self])
        let container = try ModelContainer(for: schema,
            configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)])
        let context = ModelContext(container)
        let project = Project(name: "Line Delete input")
        context.insert(project)
        let vm = EditorViewModel(project: project, modelContext: context)
        Self.retained.append(vm)
        return vm
    }

    private func tap(_ vm: EditorViewModel, _ p: SIMD2<Double>) {
        let plane = vm.activeSketch!.plane
        vm.handle(.tap(ray: Ray(origin: SIMD3<Float>(plane.toWorld(p) + plane.normal * 10),
                                direction: SIMD3<Float>(-plane.normal))))
    }

    private func startLine(_ vm: EditorViewModel) {
        vm.startSketch(tool: .line)
        vm.handle(.tap(ray: Ray(origin: SIMD3(50, 10, 50), direction: SIMD3(0, -1, 0))))
    }

    func testDeleteDiscardsContinuationWithoutDeletingCommittedLineOrAddingHistory() throws {
        let vm = try makeViewModel()
        startLine(vm)
        tap(vm, SIMD2(10, 10))
        tap(vm, SIMD2(14, 10))
        let committed = try XCTUnwrap(vm.activeSketch).entities
        XCTAssertEqual(committed.count, 1)
        let plane = vm.activeSketch!.plane
        let p = SIMD2<Double>(14, 14)
        XCTAssertTrue(vm.updateLinePreview(ray: Ray(
            origin: SIMD3<Float>(plane.toWorld(p) + plane.normal * 10),
            direction: SIMD3<Float>(-plane.normal))))
        XCTAssertNotNil(vm.pendingEntity)
        let depth = vm.session.undoStack.undoCommands.count
        vm.deleteLineInput()
        XCTAssertNil(vm.mode.sketchTool)
        XCTAssertNotNil(vm.activeSketch)
        XCTAssertNil(vm.pendingEntity)
        XCTAssertFalse(vm.tapChainActive)
        XCTAssertEqual(vm.activeSketch!.entities, committed)
        XCTAssertEqual(vm.session.undoStack.undoCommands.count, depth)
        vm.undo()
        XCTAssertTrue(vm.activeSketch!.entities.isEmpty)
        vm.redo()
        XCTAssertEqual(vm.activeSketch!.entities, committed)
    }

    func testDeleteDropsOnlyFirstPointAndDoesNotTouchDimensionEditing() throws {
        let vm = try makeViewModel()
        startLine(vm)
        tap(vm, SIMD2(10, 10))
        let depth = vm.session.undoStack.undoCommands.count
        vm.deleteLineInput()
        XCTAssertNil(vm.mode.sketchTool)
        XCTAssertTrue(vm.activeSketch!.entities.isEmpty)
        XCTAssertEqual(vm.session.undoStack.undoCommands.count, depth)
        vm.startSketch(tool: .line)
        vm.editingDimension = .init(labelID: "draft", kind: .distance, refs: [], text: "12")
        vm.deleteLineInput()
        XCTAssertEqual(vm.mode.sketchTool, .line)
        XCTAssertEqual(vm.editingDimension?.text, "12")
    }
}
