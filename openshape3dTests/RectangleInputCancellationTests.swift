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
    func testThreePointCenterControlLocksOnlyCenterAndPersistsGroupIdentity() throws {
        let vm = try makeViewModel()
        vm.setRectangleType(.threePoint)
        tap(vm, SIMD2(14, 11)); tap(vm, SIMD2(10, 10)); tap(vm, SIMD2(10, 14))
        let beforeLock = try XCTUnwrap(vm.activeSketch)
        let center = try XCTUnwrap(vm.sketchRectangleCenterLockMarkers.first)
        XCTAssertTrue(center.isSelected)
        XCTAssertEqual(vm.sketchDimensionLabels.count, 2)
        XCTAssertTrue(vm.sketchConstraintGlyphs.isEmpty, "Structural rules must not cover the released shape")
        XCTAssertTrue(beforeLock.rectangleSizingAnchors.isEmpty, "Control identity must not impose center sizing")
        XCTAssertEqual(beforeLock.rotatedRectangleEdges.count, 1)
        let id = try XCTUnwrap(beforeLock.rotatedRectangleEdges.keys.first)
        vm.toggleRectangleCenterLock()
        let locked = try XCTUnwrap(vm.activeSketch)
        XCTAssertEqual(locked.entities, beforeLock.entities)
        XCTAssertEqual(locked.constraints.filter { $0.kind == .fixed }.map(\.refs),
                       [[.init(entityID: id, role: .center)]])
        XCTAssertTrue(vm.selectedSketchPoints.isEmpty)
        let reopened = try JSONDecoder().decode(Sketch.self, from: JSONEncoder().encode(locked))
        XCTAssertNotNil(RectangleConstruction.centerDiagonalReferences(id, in: reopened))
        vm.deselectSketchTool()
        vm.selectedSketchPoints = [.init(entityID: id, role: .center)]
        vm.toggleRectangleCenterLock()
        XCTAssertEqual(vm.activeSketch?.entities, beforeLock.entities)
        XCTAssertFalse(vm.activeSketch!.constraints.contains { $0.kind == .fixed })
        XCTAssertEqual(vm.selectedSketchPoints, [.init(entityID: id, role: .center)])
        vm.undo()
        XCTAssertEqual(vm.activeSketch, locked)
        vm.redo()
        XCTAssertEqual(vm.activeSketch?.entities, beforeLock.entities)
        vm.selectedSketchPoints = [.init(entityID: id, role: .center)]
        let plane = beforeLock.plane
        let origin = center.world + SIMD3<Float>(plane.normal * 10)
        let direction = SIMD3<Float>(-plane.normal)
        XCTAssertTrue(vm.beginSketchStroke(ray: Ray(origin: origin, direction: direction)))
        let movedRay = Ray(origin: origin + SIMD3<Float>(3, 0, 2), direction: direction)
        vm.updateSketchStroke(ray: movedRay)
        vm.endSketchStroke(ray: movedRay)
        let moved = try XCTUnwrap(vm.activeSketch)
        XCTAssertNotEqual(moved.entities, beforeLock.entities)
        vm.undo()
        XCTAssertEqual(vm.activeSketch?.entities, beforeLock.entities)
        XCTAssertTrue(vm.selectedSketchPoints.isEmpty)
        XCTAssertTrue(vm.sketchRectangleCenterLockMarkers.isEmpty)
        vm.redo()
        XCTAssertEqual(vm.activeSketch, moved)
        XCTAssertTrue(vm.selectedSketchPoints.isEmpty)
    }

    func testTypedPendingBaselineDefersDocumentAndDimensionUntilRectangleCompletion() throws {
        let vm = try makeViewModel()
        vm.setRectangleType(.threePoint)
        tap(vm, SIMD2(14, 11))
        tap(vm, SIMD2(10, 10))
        let before = try XCTUnwrap(vm.activeSketch)
        let depth = vm.session.undoStack.undoCommands.count
        XCTAssertTrue(vm.canTypeRectangleBaseline)
        vm.beginRectangleBaselineEdit(firstCharacter: "2")
        XCTAssertNotNil(vm.pendingRectangleEditorAnchor)
        vm.commitDimensionEdit("1/0")
        XCTAssertNotNil(vm.editingDimension?.validationMessage)
        XCTAssertEqual(vm.activeSketch, before)
        vm.commitDimensionEdit("2 cm")
        XCTAssertNil(vm.editingDimension)
        XCTAssertEqual(vm.activeSketch, before)
        XCTAssertEqual(vm.session.undoStack.undoCommands.count, depth)
        let pending = try XCTUnwrap(vm.liveDimensionLabels.first)
        XCTAssertEqual(simd_distance(pending.worldWitnessStart, pending.worldWitnessEnd), 20, accuracy: 1e-8)
        XCTAssertEqual(pending.worldWitnessStart, before.plane.toWorld(SIMD2(14, 11)))
        tap(vm, SIMD2(10, 14))
        let completed = try XCTUnwrap(vm.activeSketch)
        XCTAssertEqual(completed.entities.count, 4)
        XCTAssertEqual(completed.dimensions.count, 1)
        XCTAssertEqual(completed.dimensions.first?.value, 20)
        XCTAssertEqual(completed.dimensions.first?.displayExpression, "2 cm")
        XCTAssertEqual(vm.session.undoStack.undoCommands.count, depth + 1)
        let reopened = try JSONDecoder().decode(Sketch.self, from: JSONEncoder().encode(completed))
        XCTAssertEqual(reopened, completed)
        vm.undo()
        XCTAssertEqual(vm.activeSketch, before)
        XCTAssertNil(vm.mode.sketchTool, "Committed three-point Undo disarms drawing")
        vm.redo()
        XCTAssertEqual(vm.activeSketch, completed)
        XCTAssertNil(vm.mode.sketchTool, "Redo must not rearm rectangle construction")
        vm.selectedSketchEntityIDs = [completed.entities[1].id]
        let dimensionID = try XCTUnwrap(completed.dimensions.first?.id)
        XCTAssertEqual(vm.sketchDimensionLabels.filter { $0.dimensionID == dimensionID }.count, 1,
                       "Three-point identity must not inherit two-sided center-rectangle aliases")
        vm.selectedSketchEntityIDs = []
        vm.selectedDimensionID = dimensionID
        XCTAssertEqual(vm.sketchDimensionLabels.filter { $0.dimensionID == dimensionID }.count, 1)

        // A later draft/cancel must not leak its dimension into a fresh rectangle.
        vm.startSketch(tool: .rect)
        tap(vm, SIMD2(30, 30)); tap(vm, SIMD2(34, 31))
        vm.beginRectangleBaselineEdit(firstCharacter: "3")
        vm.commitDimensionEdit("3")
        vm.cancelRectangleInput()
        tap(vm, SIMD2(30, 30)); tap(vm, SIMD2(34, 31)); tap(vm, SIMD2(32, 34))
        XCTAssertEqual(vm.activeSketch?.dimensions.count, 1)
    }

}
