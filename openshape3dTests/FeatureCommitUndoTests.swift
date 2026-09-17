import XCTest
import SwiftData
@testable import openshape3d

/// A committed feature is ONE undo step whether or not it builds — the
/// contract the agent bridge's `undoSteps: 1` relies on. The bridge used to
/// append and rebuild separately: two steps for a feature that built, one for
/// a feature that failed (its rebuild changed no body, so it committed
/// nothing), while every reply said 2. A caller undoing twice after a failure
/// also reverted the feature before it (practice problems round 6, bug 4).
@MainActor
final class FeatureCommitUndoTests: XCTestCase {
    nonisolated(unsafe) static var retained: [EditorViewModel] = []

    private func makeViewModel() throws -> EditorViewModel {
        let schema = Schema([
            Project.self, PersistedBody.self, PersistedSketch.self,
            PersistedPlane.self, PersistedImage.self, PersistedSymbol.self,
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let context = ModelContext(container)
        let project = Project(name: "Feature Commit Undo Test")
        context.insert(project)
        let vm = EditorViewModel(project: project, modelContext: context)
        Self.retained.append(vm)
        return vm
    }

    private func extrude(_ sketch: Sketch, seed: SIMD2<Double>, entityIDs: [UUID]) -> FeatureNode {
        FeatureNode(name: "Extrude", kind: .extrude(
            profile: ProfileRef(sketchID: sketch.id, entityIDs: entityIDs, holeEntityIDs: [], seedPoint: seed),
            plane: PlaneRef(source: .sketch(sketch.id)), distance: Expr(value: 10),
            symmetric: false, boolean: BooleanIntent(op: .newBody, resolvedTargets: []), extraProfiles: []),
            outputBodyIDs: [BodyID()])
    }

    func testAFeatureIsOneUndoStepWhetherItBuildsOrFails() throws {
        let vm = try makeViewModel()
        let p = [SIMD2<Double>(-5, -10), SIMD2(5, -10), SIMD2(5, 10), SIMD2(-5, 10)]
        let sketch = Sketch(name: "A", plane: .ground,
                            entities: (0..<4).map { .line(id: UUID(), a: p[$0], b: p[($0 + 1) % 4]) })
        vm.session.perform(AddSketchCommand(sketch: sketch))

        let builds = extrude(sketch, seed: .zero, entityIDs: sketch.entities.map(\.id))
        var depth = vm.session.undoStack.undoCommands.count
        vm.session.recordAndRebuild([builds], title: builds.name)
        XCTAssertNil(vm.session.lastEvalErrors[builds.id])
        XCTAssertEqual(vm.session.undoStack.undoCommands.count, depth + 1, "a feature that builds: one step")
        let bodyID = try XCTUnwrap(builds.outputBodyIDs.first)
        XCTAssertNotNil(vm.session.document.body(with: bodyID))

        // No closed region under the seed: the node is recorded and fails.
        let fails = extrude(sketch, seed: SIMD2(500, 500), entityIDs: [])
        depth = vm.session.undoStack.undoCommands.count
        vm.session.recordAndRebuild([fails], title: fails.name)
        XCTAssertNotNil(vm.session.lastEvalErrors[fails.id])
        XCTAssertEqual(vm.session.undoStack.undoCommands.count, depth + 1, "a feature that fails: one step")
        XCTAssertEqual(vm.session.document.features.nodes.count, 2)

        // One undo removes exactly the failed node; the first stays built.
        vm.session.undo()
        XCTAssertEqual(vm.session.document.features.nodes.map(\.id), [builds.id])
        XCTAssertNotNil(vm.session.document.body(with: bodyID))

        // And one more removes the first feature and its body together.
        vm.session.undo()
        XCTAssertTrue(vm.session.document.features.nodes.isEmpty)
        XCTAssertNil(vm.session.document.body(with: bodyID))
    }
}
