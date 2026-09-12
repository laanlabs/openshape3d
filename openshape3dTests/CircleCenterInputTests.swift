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
    func testRadiusConstructionDirectionSurvivesSizingHistoryAndDecode() throws {
        let prior = AppSettings.shared.circularAnnotations
        let priorGrid = AppSettings.shared.snapToGrid
        defer {
            AppSettings.shared.circularAnnotations = prior
            AppSettings.shared.snapToGrid = priorGrid
        }
        AppSettings.shared.circularAnnotations = .alwaysRadius
        // Construction direction is the subject here. A persisted Grid choice
        // must not quantize the oblique fixture before that direction is saved.
        AppSettings.shared.snapToGrid = false
        for direction in [SIMD2<Double>(-1, 0), SIMD2(0, 1), SIMD2(0, -1), SIMD2(0.6, 0.8)] {
            let vm = try model()
            drag(vm, SIMD2(10, 10), SIMD2(10, 10) + direction * 3)
            let fresh = try XCTUnwrap(vm.activeSketch)
            let id = try XCTUnwrap(fresh.entities.first?.id)
            XCTAssertEqual(try XCTUnwrap(fresh.circleRadiusDirections[id]).x, direction.x, accuracy: 1e-6)
            let label = try XCTUnwrap(vm.sketchDimensionLabels.first)
            let delta = label.worldEnd - label.worldStart
            let expected = fresh.plane.toWorld(SIMD2(10, 10) + direction * 3) - fresh.plane.toWorld(SIMD2(10, 10))
            XCTAssertLessThan(simd_length(delta - expected), 1e-5)
            vm.beginDimensionEdit(label)
            vm.commitDimensionEdit("2")
            let sized = try XCTUnwrap(vm.activeSketch)
            XCTAssertEqual(sized.circleRadiusDirections, fresh.circleRadiusDirections)
            XCTAssertEqual(try JSONDecoder().decode(Sketch.self, from: JSONEncoder().encode(sized)), sized)
            vm.undo()
            XCTAssertEqual(vm.activeSketch, fresh)
            vm.redo()
            XCTAssertEqual(vm.activeSketch, sized)
            var legacy = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(sized)) as? [String: Any])
            legacy.removeValue(forKey: "circleRadiusDirections")
            let decoded = try JSONDecoder().decode(Sketch.self, from: JSONSerialization.data(withJSONObject: legacy))
            XCTAssertTrue(decoded.circleRadiusDirections.isEmpty)
            XCTAssertEqual(decoded.entities, sized.entities)
        }
    }

    func testCircleEscapeRetainsCommittedRadiusSelectionWithoutHistory() throws {
        let prior = AppSettings.shared.circularAnnotations
        defer { AppSettings.shared.circularAnnotations = prior }
        AppSettings.shared.circularAnnotations = .alwaysRadius
        let vm = try model()
        drag(vm, SIMD2(10, 10), SIMD2(7, 10))
        vm.beginDimensionEdit(try XCTUnwrap(vm.sketchDimensionLabels.first))
        vm.commitDimensionEdit("2")
        let before = try XCTUnwrap(vm.activeSketch)
        let selected = vm.selectedDimensionID
        let historyCount = vm.session.undoStack.undoCommands.count
        vm.cancelCircleInput()
        XCTAssertNil(vm.mode.sketchTool)
        XCTAssertEqual(vm.activeSketch, before)
        XCTAssertEqual(vm.selectedDimensionID, selected)
        XCTAssertEqual(vm.sketchDimensionLabels.count, 1)
        XCTAssertEqual(vm.session.undoStack.undoCommands.count, historyCount)
    }

    func testArmedRadiusCommitSelectsDimensionAndUnlockPreservesGeometry() throws {
        let prior = AppSettings.shared.circularAnnotations
        defer { AppSettings.shared.circularAnnotations = prior }
        AppSettings.shared.circularAnnotations = .alwaysRadius
        let vm = try model()
        drag(vm, SIMD2(10, 10), SIMD2(13, 10))
        vm.beginDimensionEdit(try XCTUnwrap(vm.sketchDimensionLabels.first))
        vm.commitDimensionEdit("2")
        let driven = try XCTUnwrap(vm.activeSketch)
        let dimension = try XCTUnwrap(driven.dimensions.first)
        XCTAssertEqual(vm.mode.sketchTool, .circle)
        XCTAssertEqual(vm.selectedDimensionID, dimension.id)
        XCTAssertNil(vm.selectedCircleCenterID)
        vm.deleteDimension(dimension.id)
        XCTAssertTrue(try XCTUnwrap(vm.activeSketch).dimensions.isEmpty)
        XCTAssertEqual(vm.activeSketch?.entities, driven.entities)
        XCTAssertEqual(vm.mode.sketchTool, .circle)
        vm.undo()
        XCTAssertEqual(vm.activeSketch, driven)
        XCTAssertNil(vm.mode.sketchTool)
        XCTAssertTrue(vm.selectedSketchEntityIDs.isEmpty)
        XCTAssertTrue(vm.sketchDimensionLabels.isEmpty)
        vm.redo()
        XCTAssertNil(vm.mode.sketchTool)
        XCTAssertTrue(vm.sketchDimensionLabels.isEmpty)
        XCTAssertTrue(try XCTUnwrap(vm.activeSketch).dimensions.isEmpty)
        XCTAssertEqual(vm.activeSketch?.entities, driven.entities)
    }

    func testDisarmedCircleNumericCommitAndHistoryClearSelectionWithoutExtraSteps() throws {
        let prior = AppSettings.shared.circularAnnotations
        defer { AppSettings.shared.circularAnnotations = prior }
        AppSettings.shared.circularAnnotations = .alwaysRadius
        let vm = try model()
        drag(vm, SIMD2(10, 10), SIMD2(13, 10))
        let original = try XCTUnwrap(vm.activeSketch)
        let id = try XCTUnwrap(original.entities.first?.id)
        vm.deselectSketchTool()
        vm.selectedSketchPoints.removeAll()
        vm.selectedSketchEntityIDs = [id]
        let count = vm.session.undoStack.undoCommands.count
        vm.beginDimensionEdit(try XCTUnwrap(vm.sketchDimensionLabels.first))
        vm.commitDimensionEdit("2")
        let edited = try XCTUnwrap(vm.activeSketch)
        XCTAssertNotEqual(edited, original)
        XCTAssertTrue(vm.selectedSketchEntityIDs.isEmpty)
        XCTAssertTrue(vm.selectedSketchPoints.isEmpty)
        XCTAssertTrue(vm.sketchDimensionLabels.isEmpty)
        XCTAssertEqual(vm.session.undoStack.undoCommands.count, count + 1)
        vm.selectedSketchEntityIDs = [id]
        vm.undo()
        XCTAssertEqual(vm.activeSketch, original)
        XCTAssertTrue(vm.sketchDimensionLabels.isEmpty)
        vm.selectedSketchEntityIDs = [id]
        vm.redo()
        XCTAssertEqual(vm.activeSketch, edited)
        XCTAssertTrue(vm.sketchDimensionLabels.isEmpty)
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
    func testCircularAnnotationSwitchAndEditPreserveGeometryIdentityAndHistory() throws {
        let vm = try model()
        let oldMode = AppSettings.shared.circularAnnotations
        let oldUnit = AppSettings.shared.unit
        defer {
            AppSettings.shared.circularAnnotations = oldMode
            AppSettings.shared.unit = oldUnit
        }
        AppSettings.shared.unit = .millimeters
        AppSettings.shared.circularAnnotations = .radiusAndDiameter
        drag(vm, SIMD2(10, 10), SIMD2(13, 10))
        let id = try XCTUnwrap(vm.activeSketch?.entities.first?.id)
        vm.beginDimensionEdit(try XCTUnwrap(vm.sketchDimensionLabels.first))
        vm.commitDimensionEdit("10 mm")
        let diameterSketch = try XCTUnwrap(vm.activeSketch)
        let dimensionID = try XCTUnwrap(diameterSketch.dimensions.first?.id)
        XCTAssertEqual(diameterSketch.dimensions.count, 1)
        vm.selectedSketchEntityIDs = [id]
        vm.selectedSketchPoints = []
        AppSettings.shared.circularAnnotations = .alwaysRadius
        XCTAssertEqual(vm.activeSketch, diameterSketch, "Preference must not mutate the document")
        XCTAssertEqual(vm.sketchDimensionLabels.count, 1)
        let radius = try XCTUnwrap(vm.sketchDimensionLabels.first)
        XCTAssertEqual(radius.kind, .radius)
        XCTAssertEqual(radius.displayValue, 5, accuracy: 1e-6)
        XCTAssertTrue(radius.isArcRadius)
        vm.beginDimensionForSelection()
        XCTAssertEqual(vm.editingDimension?.dimensionID, dimensionID)
        vm.commitDimensionEdit(try XCTUnwrap(vm.editingDimension?.text))
        XCTAssertEqual(vm.activeSketch, diameterSketch, "Untouched converted seed retains original source")
        vm.beginDimensionForSelection()
        vm.commitDimensionEdit("6")
        let radiusSketch = try XCTUnwrap(vm.activeSketch)
        XCTAssertEqual(radiusSketch.dimensions.count, 1)
        XCTAssertEqual(radiusSketch.dimensions[0].id, dimensionID)
        XCTAssertEqual(radiusSketch.dimensions[0].kind, .radius)
        guard case let .circle(_, center, r) = radiusSketch.entities[0] else { return XCTFail() }
        XCTAssertEqual(center, SIMD2(10, 10))
        XCTAssertEqual(r, 6, accuracy: 1e-6)
        AppSettings.shared.circularAnnotations = .radiusAndDiameter
        vm.selectedSketchEntityIDs = [id]
        XCTAssertEqual(vm.sketchDimensionLabels.count, 1)
        XCTAssertEqual(vm.sketchDimensionLabels[0].kind, .diameter)
        XCTAssertEqual(vm.sketchDimensionLabels[0].displayValue, 12, accuracy: 1e-6)
        XCTAssertEqual(vm.activeSketch, radiusSketch)
        vm.undo()
        XCTAssertEqual(vm.activeSketch, diameterSketch)
        vm.redo()
        XCTAssertEqual(vm.activeSketch, radiusSketch)
    }

    func testCircleLiveRadiusAndDiameterHaveEquivalentGeometry() {
        let circle = SketchEntity.circle(id: UUID(), center: SIMD2(2, 3), radius: 10)
        let d = LiveDimensionKit.dimensions(for: circle)[0]
        let r = LiveDimensionKit.dimensions(for: circle, circleUsesRadius: true)[0]
        XCTAssertEqual(d.value, 20)
        XCTAssertEqual(r.value, 10)
        XCTAssertEqual(r.kind, .radius)
        XCTAssertEqual(d.kind, .diameter)
        XCTAssertEqual(r.start, SIMD2(2, 3))
        XCTAssertEqual(r.end, d.end)
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
