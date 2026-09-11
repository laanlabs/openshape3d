import XCTest
import SwiftData
import simd
@testable import openshape3d

@MainActor
final class CircleCenterInputTests: XCTestCase {
    private static var retained: [EditorViewModel] = []
    private func model() throws -> EditorViewModel {
        let schema = Schema([Project.self, PersistedBody.self, PersistedSketch.self,
                             PersistedPlane.self, PersistedImage.self, PersistedSymbol.self])
        let container = try ModelContainer(for: schema,
            configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)])
        let context = ModelContext(container)
        let project = Project(name: "Circle center input")
        context.insert(project)
        let vm = EditorViewModel(project: project, modelContext: context)
        Self.retained.append(vm)
        vm.startSketch(tool: .circle)
        vm.handle(.tap(ray: Ray(origin: SIMD3(50, 10, 50), direction: SIMD3(0, -1, 0))))
        return vm
    }
    private func ray(_ vm: EditorViewModel, _ p: SIMD2<Double>) -> Ray {
        let plane = vm.activeSketch!.plane
        return Ray(origin: SIMD3<Float>(plane.toWorld(p) + plane.normal * 10),
                   direction: SIMD3<Float>(-plane.normal))
    }
    private func drag(_ vm: EditorViewModel, _ a: SIMD2<Double>, _ b: SIMD2<Double>) {
        XCTAssertTrue(vm.beginSketchStroke(ray: ray(vm, a)))
        vm.updateSketchStroke(ray: ray(vm, b))
        vm.endSketchStroke(ray: ray(vm, b))
    }
    func testReleasedSelectedCenterMovesButUnselectedCenterCreatesConcentricCircle() throws {
        let vm = try model()
        drag(vm, SIMD2(10, 10), SIMD2(13, 10))
        let original = try XCTUnwrap(vm.activeSketch)
        let id = try XCTUnwrap(original.entities.first?.id)
        XCTAssertEqual(vm.selectedCircleCenterID, id)
        XCTAssertEqual(vm.sketchDimensionLabels.count, 1)
        XCTAssertEqual(vm.sketchRectangleCenterLockMarkers.count, 1)
        drag(vm, SIMD2(10, 10), SIMD2(16, 10))
        let moved = try XCTUnwrap(vm.activeSketch)
        XCTAssertEqual(moved.entities.count, 1, "Selected center must move, not draw")
        guard case let .circle(_, center, radius) = moved.entities[0] else { return XCTFail() }
        XCTAssertEqual(center.x, 16, accuracy: 1e-6)
        XCTAssertEqual(center.y, 10, accuracy: 1e-6)
        XCTAssertEqual(radius, 3, accuracy: 1e-6)
        vm.undo()
        XCTAssertEqual(vm.activeSketch?.entities, original.entities)
        XCTAssertNil(vm.mode.sketchTool)
        XCTAssertTrue(vm.selectedSketchPoints.isEmpty)
        XCTAssertTrue(vm.sketchDimensionLabels.isEmpty)
        vm.startSketch(tool: .circle)
        vm.selectedSketchPoints = []
        vm.selectedSketchEntityIDs = []
        drag(vm, SIMD2(10, 10), SIMD2(15, 10))
        let concentric = try XCTUnwrap(vm.activeSketch)
        XCTAssertEqual(concentric.entities.count, 2)
        XCTAssertEqual(concentric.entities.first, original.entities.first)
        guard case let .circle(_, outerCenter, outerRadius) = concentric.entities[1] else { return XCTFail() }
        XCTAssertEqual(outerCenter.x, 10, accuracy: 1e-6)
        XCTAssertEqual(outerCenter.y, 10, accuracy: 1e-6)
        XCTAssertEqual(outerRadius, 5, accuracy: 1e-6)
    }
    func testSelectedConcentricCenterDoesNotRetargetOlderCircle() throws {
        let vm = try model()
        let oldSettings = vm.autoConstrainSettings
        defer { vm.autoConstrainSettings = oldSettings }
        vm.autoConstrainSettings.enabled = false
        drag(vm, SIMD2(10, 10), SIMD2(13, 10))
        vm.selectedSketchPoints = []
        vm.selectedSketchEntityIDs = []
        drag(vm, SIMD2(10, 10), SIMD2(15, 10))
        let original = try XCTUnwrap(vm.activeSketch)
        let selectedID = try XCTUnwrap(vm.selectedCircleCenterID)
        XCTAssertEqual(selectedID, original.entities.last?.id)
        drag(vm, SIMD2(10, 10), SIMD2(16, 14))
        let moved = try XCTUnwrap(vm.activeSketch)
        XCTAssertEqual(moved.entities.first, original.entities.first)
        guard case let .circle(id, center, radius) = moved.entities[1] else { return XCTFail() }
        XCTAssertEqual(id, selectedID)
        XCTAssertEqual(center.x, 16, accuracy: 1e-6)
        XCTAssertEqual(center.y, 14, accuracy: 1e-6)
        XCTAssertEqual(radius, 5, accuracy: 1e-6)
        XCTAssertEqual(vm.selectedCircleCenterID, selectedID)
        vm.undo()
        XCTAssertEqual(vm.activeSketch?.entities, original.entities)
        XCTAssertNil(vm.mode.sketchTool)
        vm.redo()
        XCTAssertEqual(vm.activeSketch?.entities, moved.entities)
    }
    func testAcquiredCircleCenterConnectionIsAtomicAndMovesBothCircles() throws {
        let vm = try model()
        let oldSettings = vm.autoConstrainSettings
        let oldGuidepoints = AppSettings.shared.snapToSketchGuidepoints
        defer {
            vm.autoConstrainSettings = oldSettings
            AppSettings.shared.snapToSketchGuidepoints = oldGuidepoints
        }
        vm.autoConstrainSettings.enabled = true
        vm.autoConstrainSettings.pointSnap = true
        AppSettings.shared.snapToSketchGuidepoints = true
        drag(vm, SIMD2(10, 10), SIMD2(13, 10))
        let inner = try XCTUnwrap(vm.activeSketch)
        vm.selectedSketchPoints = []
        vm.selectedSketchEntityIDs = []
        drag(vm, SIMD2(10, 10), SIMD2(15, 10))
        let pair = try XCTUnwrap(vm.activeSketch)
        XCTAssertTrue(pair.constraints.contains {
            $0.kind == .coincident && $0.refs.count == 2 && $0.refs.allSatisfy { $0.role == .center }
        })
        vm.undo()
        XCTAssertEqual(vm.activeSketch, inner, "Creation and center relation undo atomically")
        vm.redo()
        XCTAssertEqual(vm.activeSketch, pair)
        let outerID = pair.entities[1].id
        vm.startSketch(tool: .circle)
        vm.selectedSketchPoints = [.init(entityID: outerID, role: .center)]
        vm.selectedSketchEntityIDs = [outerID]
        drag(vm, SIMD2(10, 10), SIMD2(16, 14))
        let moved = try XCTUnwrap(vm.activeSketch)
        for (index, entity) in moved.entities.enumerated() {
            guard case let .circle(_, center, radius) = entity else { return XCTFail() }
            XCTAssertEqual(center.x, 16, accuracy: 1e-5)
            XCTAssertEqual(center.y, 14, accuracy: 1e-5)
            XCTAssertEqual(radius, index == 0 ? 3 : 5, accuracy: 1e-5)
        }
        vm.undo()
        XCTAssertEqual(vm.activeSketch?.entities, pair.entities)
        vm.redo()
        XCTAssertEqual(vm.activeSketch?.entities, moved.entities)
    }

    func testDisabledGuidepointsDoNotCreateCircleCenterConstraint() throws {
        let vm = try model()
        let oldSettings = vm.autoConstrainSettings
        let oldGuidepoints = AppSettings.shared.snapToSketchGuidepoints
        defer {
            vm.autoConstrainSettings = oldSettings
            AppSettings.shared.snapToSketchGuidepoints = oldGuidepoints
        }
        vm.autoConstrainSettings.enabled = true
        vm.autoConstrainSettings.pointSnap = true
        AppSettings.shared.snapToSketchGuidepoints = false
        drag(vm, SIMD2(10, 10), SIMD2(13, 10))
        vm.selectedSketchPoints = []
        vm.selectedSketchEntityIDs = []
        drag(vm, SIMD2(10, 10), SIMD2(15, 10))
        XCTAssertEqual(vm.activeSketch?.entities.count, 2)
        XCTAssertFalse(vm.activeSketch!.constraints.contains { $0.kind == .coincident })
    }
    func testCircleCenterLockChangesOnlyCenterConstraintAndUndoRestoresGeometry() throws {
        let vm = try model()
        drag(vm, SIMD2(10, 10), SIMD2(13, 10))
        let original = try XCTUnwrap(vm.activeSketch)
        let id = try XCTUnwrap(original.entities.first?.id)
        vm.toggleRectangleCenterLock()
        XCTAssertEqual(vm.activeSketch?.entities, original.entities)
        XCTAssertTrue(vm.activeSketch!.constraints.contains { $0.kind == .fixed && $0.refs == [.init(entityID: id, role: .center)] })
        XCTAssertTrue(vm.selectedSketchPoints.isEmpty)
        XCTAssertEqual(vm.sketchDimensionLabels.count, 1, "Center Lock retains the free diameter readout")
        XCTAssertTrue(vm.activeSketch!.dimensions.isEmpty)
        vm.undo()
        XCTAssertEqual(vm.activeSketch, original)
    }
}
