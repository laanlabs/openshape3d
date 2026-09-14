import XCTest
import SwiftData
@testable import openshape3d

/// The active sketch's definition state (entity colours + the status chip's
/// DOF) is a Jacobian null-space analysis — cubic in the variable count. It
/// used to run on the main thread inside the `scene` getter on every viewport
/// update while sketching, and again in the status chip. Now it is memoised
/// on the sketch value and solved once, in the background, latest wins.
@MainActor
final class SketchDefinitionCacheTests: XCTestCase {
    nonisolated(unsafe) static var retained: [EditorViewModel] = []

    private func makeViewModel() throws -> EditorViewModel {
        let schema = Schema([
            Project.self, PersistedBody.self, PersistedSketch.self,
            PersistedPlane.self, PersistedImage.self, PersistedSymbol.self,
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let context = ModelContext(container)
        let project = Project(name: "Definition Cache Test")
        context.insert(project)
        let vm = EditorViewModel(project: project, modelContext: context)
        Self.retained.append(vm)
        return vm
    }

    /// A chain of `n` alternating horizontal/vertical lines, welded end to
    /// end: 2n + (n − 1) constraints, no dimensions — under-defined.
    private func chain(_ n: Int) -> Sketch {
        var entities: [SketchEntity] = []
        var constraints: [SketchConstraint] = []
        var p = SIMD2<Double>(0, 0)
        var ids: [UUID] = []
        for i in 0..<n {
            let q = (i % 2 == 0) ? p + SIMD2(10, 0) : p + SIMD2(0, 10)
            let id = UUID()
            entities.append(.line(id: id, a: p, b: q))
            ids.append(id)
            constraints.append(SketchConstraint(
                kind: i % 2 == 0 ? .horizontal : .vertical,
                refs: [ConstraintRef(entityID: id, role: .whole)]))
            if i > 0 {
                constraints.append(SketchConstraint(kind: .coincident, refs: [
                    ConstraintRef(entityID: ids[i - 1], role: .endpointB),
                    ConstraintRef(entityID: id, role: .endpointA),
                ]))
            }
            p = q
        }
        return Sketch(plane: .ground, entities: entities, constraints: constraints)
    }

    private final class CallCounter: @unchecked Sendable {
        private let lock = NSLock()
        private var value = 0
        var count: Int { lock.withLock { value } }
        func bump() { lock.withLock { value += 1 } }
    }

    private func sketchColors(_ vm: EditorViewModel) -> Set<SIMD4<Float>> {
        Set(vm.scene.sketchLines.map(\.color))
    }

    func testPartialRectangleLockColorsSurviveSingleEdgeSelection() async throws {
        let vm = try makeViewModel()
        let id = UUID()
        let sketch = Sketch(plane: .ground, entities: [
            .rect(id: id, min: SIMD2(2, 3), max: SIMD2(12, 9))], constraints: [
                .init(kind: .fixed, refs: [.init(entityID: id, role: .whole, rectangleEdge: 3)])])
        vm.session.perform(AddSketchCommand(sketch: sketch))
        vm.mode = .sketching(sketch.id, tool: nil)
        _ = vm.scene
        await vm.settleSketchDefinition()
        let before = vm.scene.sketchLines
        XCTAssertEqual(before.filter { $0.color == EditorViewModel.definedSketchColor }.count, 3)
        XCTAssertEqual(before.filter { $0.color == EditorViewModel.underDefinedSketchColor }.count, 1)
        vm.selectedSketchEntityIDs = [id]
        vm.selectedAxisRectangleEdge = (id, 3)
        let selected = vm.scene.sketchLines
        XCTAssertTrue(selected.contains { $0.color == SIMD4<Float>(1, 0.60, 0, 1) })
        XCTAssertTrue(selected.contains { $0.color == EditorViewModel.underDefinedSketchColor },
                      "Selecting the fixed edge must not paint the free opposite edge green")
    }

    func testTheSceneSolvesOnceAndReusesItUntilTheSketchChanges() async throws {
        let vm = try makeViewModel()
        let counter = CallCounter()
        vm.definitionSolver = { sketch in
            counter.bump()
            return SketchSolverBridge.definitionReport(sketch)
        }
        let sketch = chain(4)
        vm.session.perform(AddSketchCommand(sketch: sketch))
        vm.mode = .sketching(sketch.id, tool: .line)

        // First read: nothing is known yet, nothing solved on this thread.
        XCTAssertNil(vm.sketchDefinitionStatus)
        for _ in 0..<5 { _ = vm.scene }
        await vm.settleSketchDefinition()
        XCTAssertEqual(counter.count, 1, "five scene builds share one solve")

        // Landed: the chain is under-defined, so every committed line is blue.
        XCTAssertEqual(sketchColors(vm), [EditorViewModel.underDefinedSketchColor])
        let status = try XCTUnwrap(vm.sketchDefinitionStatus)
        XCTAssertFalse(status.fullyDefined)
        XCTAssertGreaterThan(status.dof, 0)

        // View-model state that leaves the sketch alone never re-solves.
        vm.selectedSketchEntityIDs = [sketch.entities[0].id]
        vm.selectionAdditive.toggle()
        for _ in 0..<5 { _ = vm.scene; _ = vm.sketchDefinitionStatus }
        await vm.settleSketchDefinition()
        XCTAssertEqual(counter.count, 1)

        // A sketch edit (a drag tick goes through `preview`) is a miss …
        vm.session.preview { document in
            guard let index = document.sketches.firstIndex(where: { $0.id == sketch.id }),
                  case let .line(id, a, b) = document.sketches[index].entities[3]
            else { return }
            document.sketches[index].entities[3] = .line(id: id, a: a, b: b + SIMD2(1, 0))
        }
        vm.selectedSketchEntityIDs = []
        // … that still answers from the previous report while the solve runs.
        XCTAssertEqual(sketchColors(vm), [EditorViewModel.underDefinedSketchColor])
        await vm.settleSketchDefinition()
        XCTAssertEqual(counter.count, 2, "one more solve for the edited sketch")
    }

    func testAFullyDefinedSketchComesBackGreenWithZeroDOF() async throws {
        let vm = try makeViewModel()
        // One horizontal line, both ends fixed: every variable is determined.
        let id = UUID()
        let sketch = Sketch(
            plane: .ground,
            entities: [.line(id: id, a: SIMD2(0, 0), b: SIMD2(10, 0))],
            constraints: [
                SketchConstraint(kind: .fixed, refs: [ConstraintRef(entityID: id, role: .endpointA)]),
                SketchConstraint(kind: .fixed, refs: [ConstraintRef(entityID: id, role: .endpointB)]),
            ])
        vm.session.perform(AddSketchCommand(sketch: sketch))
        vm.mode = .sketching(sketch.id, tool: .line)
        _ = vm.scene
        await vm.settleSketchDefinition()
        XCTAssertEqual(sketchColors(vm), [EditorViewModel.definedSketchColor])
        let status = try XCTUnwrap(vm.sketchDefinitionStatus)
        XCTAssertTrue(status.fullyDefined)
        XCTAssertEqual(status.dof, 0)
    }

    func testDragTicksCoalesceToTheNewestSketchAndLandingBumpsTheEpoch() async throws {
        let vm = try makeViewModel()
        let counter = CallCounter()
        vm.definitionSolver = { sketch in
            counter.bump()
            Thread.sleep(forTimeInterval: 0.05) // a slow solve, so ticks pile up behind it
            return SketchSolverBridge.definitionReport(sketch)
        }
        let sketch = chain(3)
        vm.session.perform(AddSketchCommand(sketch: sketch))
        vm.mode = .sketching(sketch.id, tool: .line)
        let epoch0 = vm.sketchDefinitionEpoch
        _ = vm.scene // solve 1 in flight
        for tick in 1...6 { // six drag ticks while it runs
            vm.session.preview { document in
                guard let index = document.sketches.firstIndex(where: { $0.id == sketch.id }),
                      case let .line(id, a, b) = document.sketches[index].entities[2]
                else { return }
                document.sketches[index].entities[2] =
                    .line(id: id, a: a, b: b + SIMD2(Double(tick), 0))
            }
            _ = vm.scene
        }
        await vm.settleSketchDefinition()
        XCTAssertEqual(counter.count, 2, "the first solve, then ONE for the newest tick")
        XCTAssertEqual(vm.sketchDefinitionEpoch, epoch0 + 2)
        // The memo is for the sketch as it is NOW: another read is a hit.
        _ = vm.scene
        await vm.settleSketchDefinition()
        XCTAssertEqual(counter.count, 2)
    }

    /// The whole point: a viewport update while editing a large constrained
    /// sketch must not stall. 150 welded lines cost ~1.5 s to analyse in
    /// Debug; the scene build must cost nothing like it, before OR after the
    /// report lands.
    func testASceneBuildNeverWaitsForTheSolve() async throws {
        let vm = try makeViewModel()
        let sketch = chain(150)
        vm.session.perform(AddSketchCommand(sketch: sketch))
        vm.mode = .sketching(sketch.id, tool: .line)
        var t0 = Date()
        _ = vm.scene
        XCTAssertLessThan(Date().timeIntervalSince(t0), 0.2, "first build: report missing, no solve here")
        await vm.settleSketchDefinition()
        t0 = Date()
        _ = vm.scene
        XCTAssertLessThan(Date().timeIntervalSince(t0), 0.2, "second build: report memoised")
        XCTAssertEqual(sketchColors(vm), [EditorViewModel.underDefinedSketchColor])
    }
}
