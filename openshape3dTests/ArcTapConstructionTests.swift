import XCTest
import SwiftData
@testable import openshape3d

@MainActor
final class ArcTapConstructionTests: XCTestCase {
    private static var retained: [EditorViewModel] = []

    private func makeViewModel() throws -> EditorViewModel {
        let schema = Schema([Project.self, PersistedBody.self, PersistedSketch.self,
                             PersistedPlane.self, PersistedImage.self, PersistedSymbol.self])
        let container = try ModelContainer(for: schema,
            configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)])
        let context = ModelContext(container)
        let project = Project(name: "Arc tap construction")
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

    private func startArc(_ vm: EditorViewModel) {
        vm.startSketch(tool: .arc)
        vm.handle(.tap(ray: Ray(origin: SIMD3(50, 10, 50), direction: SIMD3(0, -1, 0))))
    }

    func testTwoEndpointTapsCommitOneUndoableArc() throws {
        let vm = try makeViewModel()
        startArc(vm)
        tap(vm, SIMD2(10, 10))
        XCTAssertNil(vm.pendingArc)
        XCTAssertTrue(vm.activeSketch!.entities.isEmpty)
        tap(vm, SIMD2(14, 10))
        XCTAssertNotNil(vm.pendingArc)
        XCTAssertTrue(vm.activeSketch!.entities.isEmpty)
        let expected = try XCTUnwrap(vm.pendingArcEntity)
        tap(vm, SIMD2(20, 20))
        XCTAssertEqual(vm.activeSketch!.entities, [expected])
        vm.undo()
        XCTAssertTrue(vm.activeSketch!.entities.isEmpty)
        vm.redo()
        XCTAssertEqual(vm.activeSketch!.entities, [expected])
    }

    func testToolSwitchDropsOnlyUnfinishedFirstEndpoint() throws {
        let vm = try makeViewModel()
        startArc(vm)
        tap(vm, SIMD2(10, 10))
        vm.startSketch(tool: .line)
        vm.startSketch(tool: .arc)
        tap(vm, SIMD2(20, 20))
        XCTAssertNil(vm.pendingArc)
        XCTAssertTrue(vm.activeSketch!.entities.isEmpty)
        tap(vm, SIMD2(24, 20))
        XCTAssertEqual(vm.pendingArc?.a, SIMD2(20, 20))
        XCTAssertEqual(vm.pendingArc?.b, SIMD2(24, 20))
    }

    func testRepeatedFirstEndpointDoesNotCreateDegenerateArc() throws {
        let vm = try makeViewModel()
        startArc(vm)
        tap(vm, SIMD2(10, 10))
        tap(vm, SIMD2(10, 10))
        XCTAssertNil(vm.pendingArc)
        vm.deselectSketchTool()
        XCTAssertTrue(vm.activeSketch!.entities.isEmpty)
    }
}
