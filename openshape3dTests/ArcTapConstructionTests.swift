import XCTest
import SwiftData
import simd
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

    func testDefaultArcIsFortyFiveDegreesToRightOfDirectedChord() throws {
        for b in [SIMD2<Double>(4, 0), SIMD2(-4, 0), SIMD2(3, 4), SIMD2(0, -0.1)] {
            let a = SIMD2<Double>(0, 0)
            let entity = try XCTUnwrap(EditorViewModel.arcEntity(id: UUID(), a: a, b: b,
                sagitta: EditorViewModel.defaultSagitta(a: a, b: b)))
            guard case let .arc(_, center, radius, start, end) = entity else { return XCTFail() }
            let sweep = SketchEntity.arcSweep(startAngle: start, endAngle: end)
            XCTAssertEqual(sweep, .pi / 4, accuracy: 1e-10)
            let first = SketchEntity.arcPoint(center: center, radius: radius, angle: start)
            let last = SketchEntity.arcPoint(center: center, radius: radius, angle: end)
            XCTAssertEqual(simd_length(first - a), 0, accuracy: 1e-10)
            XCTAssertEqual(simd_length(last - b), 0, accuracy: 1e-10)
            let middle = SketchEntity.arcPoint(center: center, radius: radius, angle: start + sweep / 2)
            let displacement = middle - (a + b) / 2
            XCTAssertLessThan(b.x * displacement.y - b.y * displacement.x, 0,
                              "The default bulge follows the directed chord's right side")
        }
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
        let third = EditorViewModel.arcBulgePoint(of: try XCTUnwrap(vm.pendingArc))
        tap(vm, third)
        let committed = vm.activeSketch!.entities
        XCTAssertEqual(committed.count, 1)
        vm.undo()
        XCTAssertTrue(vm.activeSketch!.entities.isEmpty)
        vm.redo()
        XCTAssertEqual(vm.activeSketch!.entities, committed)
    }

    func testReturnAcceptsDefaultArcAndKeepsChainingFromEndpoint() throws {
        let vm = try makeViewModel()
        startArc(vm)
        let endpoint = SIMD2<Double>(14, 10)
        tap(vm, SIMD2(10, 10))
        tap(vm, endpoint)
        let expected = try XCTUnwrap(vm.pendingArcEntity)

        vm.finishArcInput()

        XCTAssertNil(vm.pendingArc)
        XCTAssertEqual(vm.activeSketch?.entities, [expected])
        XCTAssertEqual(vm.mode.sketchTool, .arc)

        let next = SIMD2<Double>(18, 12)
        let plane = try XCTUnwrap(vm.activeSketch?.plane)
        let ray = Ray(origin: SIMD3<Float>(plane.toWorld(next) + plane.normal * 10),
                      direction: SIMD3<Float>(-plane.normal))
        XCTAssertTrue(vm.updateLinePreview(ray: ray))
        guard case let .arc(_, center, radius, start, end) = try XCTUnwrap(vm.pendingEntity)
        else { return XCTFail("Return must retain the accepted endpoint as the chain anchor") }
        let a = SketchEntity.arcPoint(center: center, radius: radius, angle: start)
        let b = SketchEntity.arcPoint(center: center, radius: radius, angle: end)
        XCTAssertEqual(min(simd_length(a - endpoint), simd_length(b - endpoint)),
                       0, accuracy: 1e-9)
    }

    func testThirdPointTangentTransitionIsOneUndoableDrawStep() throws {
        let vm = try makeViewModel()
        startArc(vm)
        let sketchID = try XCTUnwrap(vm.activeSketch?.id)
        let lineID = UUID()
        let line = SketchEntity.line(id: lineID, a: SIMD2(0, 0), b: SIMD2(4, 0))
        vm.session.perform(AddSketchEntityCommand(sketchID: sketchID, entity: line))
        let undoDepth = vm.session.undoStack.undoCommands.count

        tap(vm, SIMD2(4, 0))
        tap(vm, SIMD2(8, 4))
        tap(vm, SIMD2(4 + 4 / sqrt(2), 4 - 4 / sqrt(2)))

        let arc = try XCTUnwrap(vm.activeSketch?.entities.first(where: { $0.id != lineID }))
        let tangent = try XCTUnwrap(vm.activeSketch?.constraints.first(where: { $0.kind == .tangent }))
        XCTAssertEqual(Set(tangent.refs.map(\.entityID)), Set([lineID, arc.id]))
        XCTAssertEqual(vm.session.undoStack.undoCommands.count, undoDepth + 1,
                       "the arc and inferred tangent are one Draw history step")

        vm.undo()
        XCTAssertEqual(vm.activeSketch?.entities, [line])
        XCTAssertTrue(vm.activeSketch?.constraints.isEmpty == true)
        vm.redo()
        XCTAssertEqual(vm.activeSketch?.entities.count, 2)
        XCTAssertEqual(vm.activeSketch?.constraints.filter { $0.kind == .tangent }.count, 1)
    }

    func testHoverThirdPointShapesPendingArcBeforeClickCommit() throws {
        let vm = try makeViewModel()
        startArc(vm)
        tap(vm, SIMD2(10, 10))
        tap(vm, SIMD2(14, 10))
        let initial = try XCTUnwrap(vm.pendingArc)
        let plane = try XCTUnwrap(vm.activeSketch?.plane)
        let third = SIMD2<Double>(12, 14)
        let ray = Ray(origin: SIMD3<Float>(plane.toWorld(third) + plane.normal * 10),
                      direction: SIMD3<Float>(-plane.normal))

        XCTAssertTrue(vm.updateLinePreview(ray: ray))
        let shaped = try XCTUnwrap(vm.pendingArc)
        XCTAssertNotEqual(shaped.sagitta, initial.sagitta)
        XCTAssertEqual(shaped.a, initial.a)
        XCTAssertEqual(shaped.b, initial.b)
        let expected = try XCTUnwrap(vm.pendingArcEntity)
        XCTAssertFalse(vm.updateLinePreview(ray: nil),
                       "leaving hover keeps the last valid third-point shape")

        tap(vm, third)

        XCTAssertNil(vm.pendingArc)
        XCTAssertEqual(vm.activeSketch!.entities, [expected])
        XCTAssertEqual(vm.mode.sketchTool, .arc)
    }

    func testThirdTapShapesAndCommitsArcWithoutHover() throws {
        let vm = try makeViewModel()
        startArc(vm)
        tap(vm, SIMD2(10, 10))
        tap(vm, SIMD2(14, 10))
        let initial = try XCTUnwrap(vm.pendingArc)
        let third = SIMD2<Double>(12, 14)

        tap(vm, third)

        XCTAssertNil(vm.pendingArc)
        guard case let .arc(_, center, radius, start, end) = try XCTUnwrap(vm.activeSketch?.entities.first)
        else { return XCTFail("third tap must commit an arc") }
        let sweep = SketchEntity.arcSweep(startAngle: start, endAngle: end)
        XCTAssertNotEqual(sweep, .pi / 4, accuracy: 1e-6)
        let first = SketchEntity.arcPoint(center: center, radius: radius, angle: start)
        let last = SketchEntity.arcPoint(center: center, radius: radius, angle: end)
        let forward = simd_length(first - initial.a) + simd_length(last - initial.b)
        let reverse = simd_length(first - initial.b) + simd_length(last - initial.a)
        XCTAssertEqual(min(forward, reverse), 0, accuracy: 1e-9)
        XCTAssertTrue(center.x.isFinite)
    }

    func testCommittedArcAutomaticallyAnchorsNextEndpointPreviewAndTap() throws {
        let vm = try makeViewModel()
        startArc(vm)
        let shared = SIMD2<Double>(14, 10)
        tap(vm, SIMD2(10, 10))
        tap(vm, shared)
        tap(vm, SIMD2(12, 14))
        XCTAssertEqual(vm.activeSketch?.entities.count, 1)

        let nextEndpoint = SIMD2<Double>(18, 12)
        let plane = try XCTUnwrap(vm.activeSketch?.plane)
        let ray = Ray(origin: SIMD3<Float>(plane.toWorld(nextEndpoint) + plane.normal * 10),
                      direction: SIMD3<Float>(-plane.normal))
        XCTAssertTrue(vm.updateLinePreview(ray: ray))
        guard case let .arc(_, center, radius, start, end) = try XCTUnwrap(vm.pendingEntity)
        else { return XCTFail("post-commit hover must preview the next arc") }
        let previewA = SketchEntity.arcPoint(center: center, radius: radius, angle: start)
        let previewB = SketchEntity.arcPoint(center: center, radius: radius, angle: end)
        XCTAssertEqual(min(simd_length(previewA - shared), simd_length(previewB - shared)),
                       0, accuracy: 1e-9)

        tap(vm, nextEndpoint)

        XCTAssertNil(vm.pendingEntity)
        XCTAssertEqual(vm.pendingArc?.a, shared)
        XCTAssertEqual(vm.pendingArc?.b, nextEndpoint)
        XCTAssertEqual(vm.activeSketch?.entities.count, 1,
                       "the chained endpoint tap must not commit the next arc early")
    }

    func testEscapeAfterCommittedArcDropsChainedPreviewWithoutHistory() throws {
        let vm = try makeViewModel()
        startArc(vm)
        tap(vm, SIMD2(10, 10))
        tap(vm, SIMD2(14, 10))
        tap(vm, SIMD2(12, 14))
        let committed = vm.activeSketch!.entities
        let undoDepth = vm.session.undoStack.undoCommands.count

        let plane = try XCTUnwrap(vm.activeSketch?.plane)
        let point = SIMD2<Double>(18, 12)
        let ray = Ray(origin: SIMD3<Float>(plane.toWorld(point) + plane.normal * 10),
                      direction: SIMD3<Float>(-plane.normal))
        XCTAssertTrue(vm.updateLinePreview(ray: ray))
        XCTAssertNotNil(vm.pendingEntity)

        vm.cancelArcInput()

        XCTAssertNil(vm.pendingEntity)
        XCTAssertNil(vm.pendingArc)
        XCTAssertNil(vm.mode.sketchTool)
        XCTAssertEqual(vm.activeSketch!.entities, committed)
        XCTAssertEqual(vm.session.undoStack.undoCommands.count, undoDepth)
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

    func testEscapeDropsFirstEndpointAndDisarmsArcWithoutHistory() throws {
        let vm = try makeViewModel()
        startArc(vm)
        let undoDepth = vm.session.undoStack.undoCommands.count
        tap(vm, SIMD2(10, 10))

        vm.cancelArcInput()

        XCTAssertNil(vm.pendingArc)
        XCTAssertNil(vm.mode.sketchTool)
        XCTAssertTrue(vm.activeSketch!.entities.isEmpty)
        XCTAssertEqual(vm.session.undoStack.undoCommands.count, undoDepth)
    }

    func testEscapeDropsPendingArcButPreservesCommittedGeometryAndHistory() throws {
        let vm = try makeViewModel()
        startArc(vm)
        let committed = SketchEntity.line(id: UUID(), a: SIMD2(0, 0), b: SIMD2(4, 0))
        let sketchID = try XCTUnwrap(vm.activeSketch?.id)
        vm.session.perform(AddSketchEntityCommand(sketchID: sketchID, entity: committed))
        let undoDepth = vm.session.undoStack.undoCommands.count
        tap(vm, SIMD2(10, 10))
        tap(vm, SIMD2(14, 10))
        XCTAssertNotNil(vm.pendingArc)

        vm.cancelArcInput()

        XCTAssertNil(vm.pendingArc)
        XCTAssertNil(vm.mode.sketchTool)
        XCTAssertTrue(vm.canExitSketchWithEscape)
        XCTAssertEqual(vm.activeSketch!.entities, [committed])
        XCTAssertEqual(vm.session.undoStack.undoCommands.count, undoDepth)
    }

}
