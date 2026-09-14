import XCTest
import SwiftData
import simd
@testable import openshape3d

@MainActor
final class LineGuideWorkflowTests: XCTestCase {
    private static var retained: [EditorViewModel] = []
    private static var cameras: [GuideCamera] = []
    private final class GuideCamera: ViewportCameraControl {
        var worldUnitsPerPoint = 1.0
        func fitScene() {}
        func moveCameraHeadOn(to plane: SketchPlane) {}
        func animateToStandardView(_ view: StandardView) {}
        func setProjection(orthographic: Bool) {}
        func fitTo(bounds: (min: SIMD3<Float>, max: SIMD3<Float>)) {}
        func worldToScreenPoint(_ world: SIMD3<Double>) -> CGPoint? { nil }
        func offAxisDegrees(to plane: SketchPlane) -> Double { 0 }
        func orientationCubeLabels() -> [OrientationCube.FaceLabel] { [] }
        func gizmoWorldScale(at origin: SIMD3<Float>) -> Float { 1 }
    }

    private func makeViewModel() throws -> EditorViewModel {
        let schema = Schema([Project.self, PersistedBody.self, PersistedSketch.self,
                             PersistedPlane.self, PersistedImage.self, PersistedSymbol.self])
        let container = try ModelContainer(for: schema,
            configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)])
        let context = ModelContext(container)
        let project = Project(name: "Line Delete input")
        context.insert(project)
        let vm = EditorViewModel(project: project, modelContext: context)
        let camera = GuideCamera()
        Self.cameras.append(camera)
        vm.cameraControl = camera
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

    func testTapPreviewCommitAndHistoryUseIndependentGuideSetting() throws {
        let settings = AppSettings.shared
        let old = (settings.snapToGrid, settings.snapToSketchGuidepoints,
                   settings.snapToFaceGuidepoints, settings.snapToSketchGuidelines)
        defer {
            settings.snapToGrid = old.0
            settings.snapToSketchGuidepoints = old.1
            settings.snapToFaceGuidepoints = old.2
            settings.snapToSketchGuidelines = old.3
        }
        settings.snapToGrid = false
        settings.snapToSketchGuidepoints = false
        settings.snapToFaceGuidepoints = false
        for guides in [false, true] {
            for auto in [false, true] {
                let vm = try makeViewModel()
                startLine(vm)
                vm.autoConstrainSettings.enabled = auto
                settings.snapToSketchGuidelines = guides
                let a = SIMD2<Double>(10, 10), b = SIMD2<Double>(110, 11)
                tap(vm, a)
                let plane = vm.activeSketch!.plane
                XCTAssertTrue(vm.updateLinePreview(ray: Ray(
                    origin: SIMD3<Float>(plane.toWorld(b) + plane.normal * 10),
                    direction: SIMD3<Float>(-plane.normal))))
                if guides { XCTAssertFalse(vm.activeGuides.isEmpty) }
                let preview = try XCTUnwrap(vm.pendingEntity)
                guard case let .line(_, pa, pb) = preview else { return XCTFail() }
                XCTAssertEqual(pa.y, a.y, accuracy: 1e-6)
                XCTAssertEqual(pb.y, guides ? a.y : b.y, accuracy: 1e-6)
                tap(vm, b)
                let sketch = try XCTUnwrap(vm.activeSketch)
                guard case let .line(_, ca, cb) = try XCTUnwrap(sketch.entities.first) else { return XCTFail() }
                XCTAssertEqual(ca.y, pa.y, accuracy: 1e-6)
                XCTAssertEqual(cb.y, pb.y, accuracy: 1e-6)
                XCTAssertEqual(sketch.constraints.filter { $0.kind == .horizontal }.count,
                               guides && auto ? 1 : 0)
                // A new hover after commit must disappear completely on Delete.
                let next = b + SIMD2<Double>(100, 1)
                _ = vm.updateLinePreview(ray: Ray(
                    origin: SIMD3<Float>(plane.toWorld(next) + plane.normal * 10),
                    direction: SIMD3<Float>(-plane.normal)))
                vm.deleteLineInput()
                XCTAssertTrue(vm.activeGuides.isEmpty)
                XCTAssertNil(vm.pendingEntity)
                vm.undo()
                XCTAssertTrue(vm.activeSketch!.entities.isEmpty)
                vm.redo()
                XCTAssertEqual(vm.activeSketch!.entities, sketch.entities)
            }
        }
    }
    func testDragPreviewCommitAtBothSidesOfGuideThreshold() throws {
        let settings = AppSettings.shared
        let old = (settings.snapToGrid, settings.snapToSketchGuidepoints,
                   settings.snapToFaceGuidepoints, settings.snapToSketchGuidelines)
        defer {
            settings.snapToGrid = old.0
            settings.snapToSketchGuidepoints = old.1
            settings.snapToFaceGuidepoints = old.2
            settings.snapToSketchGuidelines = old.3
        }
        settings.snapToGrid = false
        settings.snapToSketchGuidepoints = false
        settings.snapToFaceGuidepoints = false
        for guides in [false, true] {
            settings.snapToSketchGuidelines = guides
            for auto in [false, true] {
                for scale in [0.01, 1.0] {
                    for rise in [-5.0, -4.0, -1.0, 1.0, 4.0, 5.0] {
                        let vm = try makeViewModel()
                        (vm.cameraControl as? GuideCamera)?.worldUnitsPerPoint = scale
                        startLine(vm)
                        vm.autoConstrainSettings.enabled = auto
                        let a = SIMD2<Double>(10, 10) * scale
                        let b = a + SIMD2<Double>(100, rise) * scale
                        let plane = vm.activeSketch!.plane
                        func ray(_ p: SIMD2<Double>) -> Ray {
                            Ray(origin: SIMD3<Float>(plane.toWorld(p) + plane.normal * 10),
                                direction: SIMD3<Float>(-plane.normal))
                        }
                        XCTAssertTrue(vm.beginSketchStroke(ray: ray(a)))
                        vm.updateSketchStroke(ray: ray(b))
                        let preview = try XCTUnwrap(vm.pendingEntity)
                        guard case let .line(_, pa, pb) = preview else { return XCTFail() }
                        let snaps = guides && abs(rise) <= 4
                        XCTAssertEqual(pa.y, a.y, accuracy: 1e-5)
                        XCTAssertEqual(pb.y, snaps ? a.y : b.y, accuracy: 1e-5)
                        vm.endSketchStroke(ray: ray(b))
                        let sketch = try XCTUnwrap(vm.activeSketch)
                        XCTAssertEqual(sketch.entities.count, 1)
                        guard case let .line(_, ca, cb) = sketch.entities[0] else { return XCTFail() }
                        XCTAssertEqual(ca.y, pa.y, accuracy: 1e-5)
                        XCTAssertEqual(cb.y, pb.y, accuracy: 1e-5)
                        XCTAssertEqual(sketch.constraints.filter { $0.kind == .horizontal }.count,
                                       snaps && auto ? 1 : 0)
                        XCTAssertTrue(vm.activeGuides.isEmpty)
                        vm.undo()
                        XCTAssertTrue(vm.activeSketch!.entities.isEmpty)
                        vm.redo()
                        XCTAssertEqual(vm.activeSketch!.entities, sketch.entities)
                    }
                }
            }
        }
    }

}
