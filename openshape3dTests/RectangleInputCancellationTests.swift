import XCTest
import SwiftData
import simd
@testable import openshape3d

@MainActor
final class RectangleInputCancellationTests: XCTestCase {
    private static var retained: [EditorViewModel] = []

    private func makeViewModel() throws -> EditorViewModel {
        let schema = Schema([Project.self, PersistedBody.self, PersistedSketch.self,
                             PersistedPlane.self, PersistedImage.self, PersistedSymbol.self])
        let container = try ModelContainer(for: schema,
            configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)])
        let context = ModelContext(container)
        let project = Project(name: "Rectangle cancellation")
        context.insert(project)
        let vm = EditorViewModel(project: project, modelContext: context)
        Self.retained.append(vm)
        vm.startSketch(tool: .rect)
        vm.handle(.tap(ray: Ray(origin: SIMD3(50, 10, 50), direction: SIMD3(0, -1, 0))))
        return vm
    }

    private func tap(_ vm: EditorViewModel, _ p: SIMD2<Double>) {
        let plane = vm.activeSketch!.plane
        vm.handle(.tap(ray: Ray(origin: SIMD3<Float>(plane.toWorld(p) + plane.normal * 10),
                                direction: SIMD3<Float>(-plane.normal))))
    }

    func testEscapeDiscardsEachPlacementStageWithoutChangingCommittedGeometryOrHistory() throws {
        for type in RectangleType.allCases {
            let vm = try makeViewModel()
            vm.setRectangleType(type)
            tap(vm, SIMD2(10, 10))
            tap(vm, SIMD2(14, 11))
            if type == .threePoint { tap(vm, SIMD2(13, 14)) }
            let committed = try XCTUnwrap(vm.activeSketch)
            XCTAssertFalse(committed.entities.isEmpty)
            let depth = vm.session.undoStack.undoCommands.count
            for stage in 1...(type == .threePoint ? 2 : 1) {
                tap(vm, SIMD2(20, 20))
                if stage == 2 { tap(vm, SIMD2(24, 21)) }
                XCTAssertTrue(vm.hasPendingRectangle)
                vm.cancelRectangleInput()
                XCTAssertFalse(vm.hasPendingRectangle)
                XCTAssertEqual(vm.mode.sketchTool, .rect)
                XCTAssertTrue(vm.liveDimensionLabels.isEmpty)
                XCTAssertEqual(vm.activeSketch, committed)
                XCTAssertEqual(vm.session.undoStack.undoCommands.count, depth)
            }
            vm.cancelRectangleInput()
            XCTAssertNil(vm.mode.sketchTool)
            XCTAssertEqual(vm.activeSketch, committed)
            XCTAssertEqual(vm.session.undoStack.undoCommands.count, depth)
        }
    }
}
