//
//  ConstraintApplyTests.swift
//  openshape3dTests
//
//  Applying constraints to a sketch selection (plan §C3): the view model
//  builds a SketchConstraint from the selected points/entities, re-solves the
//  sketch, and commits the constraint + moved geometry as ONE undoable step.
//  Also covers the adaptive enable/disable rules and point-role hit testing.
//

import XCTest
import SwiftData
import simd
@testable import openshape3d

@MainActor
final class ConstraintApplyTests: XCTestCase {

    func testLineSymmetryAxisPairingHistoryAndArchive() throws {
        let previous = AppSettings.shared.anchoredSketchEntity
        defer { AppSettings.shared.anchoredSketchEntity = previous }
        for lastSelected in [false, true] {
            AppSettings.shared.anchoredSketchEntity = lastSelected ? .lastSelected : .firstSelected
            for reverseEndpoints in [false, true] {
                let vm = try makeViewModel()
                let left = line(SIMD2(-5, 1), SIMD2(-3, -1))
                let right = reverseEndpoints ? line(SIMD2(6, 0), SIMD2(3, -1))
                                             : line(SIMD2(3, -1), SIMD2(6, 0))
                let axis = line(SIMD2(0, -5), SIMD2(0, 8))
                let original = openSketch(vm, entities: [left, right, axis])
                vm.mode = .sketching(original.id, tool: nil)
                vm.selectSketchEntitiesInOrder([left.id, right.id])
                vm.selectedSketchPoints = [.init(entityID: axis.id, role: .endpointB)]
                XCTAssertFalse(vm.canApplyConstraint(.symmetric))
                vm.selectedSketchPoints = [.init(entityID: right.id, role: .endpointB)]
                XCTAssertTrue(vm.canApplyConstraint(.symmetric))
                vm.applyConstraint(.symmetric)
                XCTAssertTrue(vm.isPickingSymmetryAxis)
                vm.completeSymmetryAxisPick(left.id)
                XCTAssertTrue(vm.isPickingSymmetryAxis, "An operand cannot be its own axis")
                XCTAssertEqual(vm.activeSketch, original)
                vm.completeSymmetryAxisPick(axis.id)
                XCTAssertFalse(vm.isPickingSymmetryAxis)
                let result = try XCTUnwrap(vm.activeSketch)
                XCTAssertEqual(result.constraints.count, 1)
                let constraint = try XCTUnwrap(result.constraints.first)
                XCTAssertEqual(constraint.kind, .symmetric)
                XCTAssertEqual(constraint.refs.count, 5)
                XCTAssertEqual(Set(constraint.refs.map(\.entityID)), Set([left.id, right.id, axis.id]))
                XCTAssertEqual(result.entities[lastSelected ? 1 : 0], lastSelected ? right : left)
                XCTAssertEqual(result.entities[2], axis)
                func point(_ ref: ConstraintRef) throws -> SIMD2<Double> {
                    guard case let .line(_, a, b)? = result.entities.first(where: { $0.id == ref.entityID })
                    else { throw NSError(domain: "ExpectedLine", code: 1) }
                    return ref.role == .endpointA ? a : b
                }
                for (a, b) in [(0, 1), (3, 4)] {
                    let p = try point(constraint.refs[a]), q = try point(constraint.refs[b])
                    XCTAssertEqual(p.x, -q.x, accuracy: 1e-8)
                    XCTAssertEqual(p.y, q.y, accuracy: 1e-8)
                }
                XCTAssertLessThan(SketchSolverBridge.residualNorm(result), 1e-8)
                XCTAssertTrue(vm.selectedSketchEntityIDs.isEmpty)
                vm.undo(); XCTAssertEqual(vm.activeSketch, original)
                vm.redo(); XCTAssertEqual(vm.activeSketch, result)
                let restored = try JSONDecoder().decode(Sketch.self, from: JSONEncoder().encode(result))
                XCTAssertEqual(restored, result)
                XCTAssertLessThan(SketchSolverBridge.residualNorm(restored), 1e-8)
                var guest = DesignDocument()
                guest.sketches = [restored]
                let imported = try XCTUnwrap(ProjectMergeKit.insert(guest, into: DesignDocument()).document.sketches.first)
                let importedRefs = try XCTUnwrap(imported.constraints.first).refs
                XCTAssertEqual(importedRefs.map(\.role), constraint.refs.map(\.role))
                XCTAssertTrue(Set(importedRefs.map(\.entityID)).isDisjoint(with: Set(constraint.refs.map(\.entityID))))
                XCTAssertTrue(importedRefs.allSatisfy { ref in imported.entities.contains { $0.id == ref.entityID } })
                XCTAssertLessThan(SketchSolverBridge.residualNorm(imported), 1e-8)
            }
        }
    }

    func testCircleSymmetryAxisPickGeometryHistoryAndArchive() throws {
        let previous = AppSettings.shared.anchoredSketchEntity
        AppSettings.shared.anchoredSketchEntity = .firstSelected
        defer { AppSettings.shared.anchoredSketchEntity = previous }
        let vm = try makeViewModel()
        let left = SketchEntity.circle(id: UUID(), center: SIMD2(-4, 3), radius: 2)
        let right = SketchEntity.circle(id: UUID(), center: SIMD2(4, 1), radius: 2)
        let axis = line(SIMD2(0, -5), SIMD2(0, 8))
        let original = openSketch(vm, entities: [left, right, axis])
        vm.mode = .sketching(original.id, tool: nil)
        vm.selectSketchEntitiesInOrder([left.id, right.id])
        // Circle release retains its own center marker alongside the rim.
        vm.selectedSketchPoints = [.init(entityID: axis.id, role: .endpointA)]
        XCTAssertFalse(vm.canApplyConstraint(.symmetric), "An unrelated point is not a two-circle selection")
        vm.selectedSketchPoints = [.init(entityID: right.id, role: .center)]
        XCTAssertTrue(vm.canApplyConstraint(.symmetric))
        vm.applyConstraint(.symmetric)
        XCTAssertTrue(vm.isPickingSymmetryAxis)
        XCTAssertEqual(vm.activeSketch, original)
        let ray = Ray(origin: SIMD3<Float>(original.plane.toWorld(SIMD2(-4, 3)) + original.plane.normal * 10),
                      direction: SIMD3<Float>(-original.plane.normal))
        XCTAssertFalse(vm.beginSketchStroke(ray: ray), "Axis picking must not move selected geometry")
        XCTAssertEqual(vm.activeSketch, original)
        vm.completeSymmetryAxisPick(left.id) // Not a line: keep waiting.
        XCTAssertTrue(vm.isPickingSymmetryAxis)
        vm.handle(.tap(ray: Ray(origin: SIMD3<Float>(original.plane.toWorld(SIMD2(0, 6)) + original.plane.normal * 10),
                                direction: SIMD3<Float>(-original.plane.normal))))
        XCTAssertFalse(vm.isPickingSymmetryAxis)
        XCTAssertTrue(vm.selectedSketchEntityIDs.isEmpty)
        let result = try XCTUnwrap(vm.activeSketch)
        XCTAssertEqual(result.constraints.count, 1)
        XCTAssertEqual(result.constraints[0].kind, .symmetric)
        XCTAssertEqual(result.constraints[0].refs.map(\.entityID), [left.id, right.id, axis.id])
        XCTAssertEqual(result.entities[0], left)
        XCTAssertEqual(result.entities[2], axis)
        guard case let .circle(_, center, radius) = result.entities[1] else { return XCTFail() }
        XCTAssertEqual(center.x, 4, accuracy: 1e-8)
        XCTAssertEqual(center.y, 3, accuracy: 1e-8)
        XCTAssertEqual(radius, 2, accuracy: 1e-8)
        XCTAssertLessThan(SketchSolverBridge.residualNorm(result), 1e-8)
        vm.undo()
        XCTAssertEqual(vm.activeSketch, original)
        vm.redo()
        XCTAssertEqual(vm.activeSketch, result)
        let restored = try JSONDecoder().decode(Sketch.self, from: JSONEncoder().encode(result))
        XCTAssertEqual(restored, result)
        XCTAssertLessThan(SketchSolverBridge.residualNorm(restored), 1e-8)
    }

    func testCircleSymmetryRefusesConflictingLocksWithoutHistory() throws {
        let vm = try makeViewModel()
        let a = SketchEntity.circle(id: UUID(), center: SIMD2(-4, 3), radius: 2)
        let b = SketchEntity.circle(id: UUID(), center: SIMD2(4, 1), radius: 2)
        let axis = line(SIMD2(0, -5), SIMD2(0, 8))
        var sketch = Sketch(plane: .ground, entities: [a, b, axis])
        sketch.constraints = [SketchConstraint(kind: .fixed, refs:
            sketch.entities.map { ConstraintRef(entityID: $0.id, role: .whole) })]
        vm.session.perform(AddSketchCommand(sketch: sketch))
        vm.mode = .sketching(sketch.id, tool: nil)
        vm.selectSketchEntitiesInOrder([a.id, b.id])
        let undoCount = vm.session.undoStack.undoCommands.count
        vm.applyConstraint(.symmetric)
        vm.completeSymmetryAxisPick(axis.id)
        XCTAssertNotNil(vm.errorMessage)
        XCTAssertTrue(vm.isPickingSymmetryAxis, "Refusal permits choosing another axis or cancelling")
        XCTAssertEqual(vm.activeSketch, sketch)
        XCTAssertEqual(vm.session.undoStack.undoCommands.count, undoCount)
        vm.cancelSymmetryAxisPick()
        XCTAssertFalse(vm.isPickingSymmetryAxis)
    }

    func testCircleSymmetryCancellationDoesNotConsumeHistory() throws {
        let vm = try makeViewModel()
        let circles: [SketchEntity] = [.circle(id: UUID(), center: SIMD2(-3, 0), radius: 1),
                                      .circle(id: UUID(), center: SIMD2(3, 2), radius: 1)]
        let original = openSketch(vm, entities: circles)
        vm.mode = .sketching(original.id, tool: nil)
        vm.selectSketchEntitiesInOrder(circles.map(\.id))
        vm.applyConstraint(.symmetric)
        vm.undo() // Cancel pending operation, not creation of the sketch.
        XCTAssertFalse(vm.isPickingSymmetryAxis)
        XCTAssertEqual(vm.activeSketch, original)
        vm.applyConstraint(.symmetric)
        vm.cancelSymmetryAxisPick()
        XCTAssertEqual(vm.activeSketch, original)
        vm.applyConstraint(.symmetric)
        vm.startSketch(tool: .line)
        XCTAssertFalse(vm.isPickingSymmetryAxis)
        XCTAssertEqual(vm.activeSketch, original)
        vm.mode = .sketching(original.id, tool: nil)
        vm.applyConstraint(.symmetric)
        vm.finishSketch()
        XCTAssertFalse(vm.isPickingSymmetryAxis)
        XCTAssertEqual(vm.session.document.sketches.first, original)
    }

    func testUnchangedExpressionAcceptPreservesGeometryAndUndoStep() throws {
        let priorAlwaysShow = AppSettings.shared.alwaysShowDimensions
        AppSettings.shared.alwaysShowDimensions = true
        defer { AppSettings.shared.alwaysShowDimensions = priorAlwaysShow }
        let vm = try makeViewModel(), id = UUID()
        let entity = SketchEntity.circle(id: id, center: SIMD2(3, 4), radius: 2)
        let sketch = openSketch(vm, entities: [entity])
        vm.mode = .sketching(sketch.id, tool: nil)
        vm.selectedSketchEntityIDs = [id]
        vm.beginDimensionEdit(try XCTUnwrap(vm.sketchDimensionLabels.first))
        vm.commitDimensionEdit("1+.5")
        let geometry = try XCTUnwrap(vm.activeSketch).entities
        let dimensions = try XCTUnwrap(vm.activeSketch).dimensions
        vm.beginDimensionEdit(try XCTUnwrap(vm.sketchDimensionLabels.first))
        vm.commitDimensionEdit(try XCTUnwrap(vm.editingDimension).text)
        XCTAssertNil(vm.editingDimension)
        XCTAssertEqual(vm.activeSketch?.entities, geometry)
        XCTAssertEqual(vm.activeSketch?.dimensions, dimensions)
        vm.session.undo()
        XCTAssertEqual(vm.activeSketch?.entities, [entity])
        XCTAssertEqual(vm.activeSketch?.dimensions.count, 0)
        vm.session.redo()
        XCTAssertEqual(vm.activeSketch?.entities, geometry)
        XCTAssertEqual(vm.activeSketch?.dimensions, dimensions)
    }

    /// MainActor view-model dealloc inside an XCTest invocation crashes the
    /// simulator runtime, so retain them for the process lifetime (mirrors
    /// SelectionUXTests.retainedViewModels).
    private static var retained: [EditorViewModel] = []

    private func makeViewModel() throws -> EditorViewModel {
        let schema = Schema([
            Project.self,
            PersistedBody.self,
            PersistedSketch.self,
            PersistedPlane.self,
            PersistedImage.self,
            PersistedSymbol.self,
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let context = ModelContext(container)
        let project = Project(name: "Constraint Apply Test")
        context.insert(project)
        let vm = EditorViewModel(project: project, modelContext: context)
        Self.retained.append(vm)
        return vm
    }

    /// Open a sketch containing `entities` and enter sketching mode.
    private func openSketch(
        _ vm: EditorViewModel, entities: [SketchEntity]
    ) -> Sketch {
        let sketch = Sketch(plane: .ground, entities: entities)
        vm.session.perform(AddSketchCommand(sketch: sketch))
        vm.mode = .sketching(sketch.id, tool: .line)
        return sketch
    }

    private func line(_ a: SIMD2<Double>, _ b: SIMD2<Double>) -> SketchEntity {
        .line(id: UUID(), a: a, b: b)
    }

    private func currentLine(_ vm: EditorViewModel, id: UUID) -> (a: SIMD2<Double>, b: SIMD2<Double>)? {
        for sketch in vm.session.document.sketches {
            for e in sketch.entities {
                if case let .line(eid, a, b) = e, eid == id { return (a, b) }
            }
        }
        return nil
    }

    func testDiagonalRectangleLeaderSidesSurviveReloadAndRespectSelectedEdge() throws {
        // Observed Front-view creation directions: down-left top/left,
        // up-right bottom/right, down-right bottom/left, up-left top/right.
        let cases: [(RectangleSizingAnchor?, Double, Double)] = [
            (.maxMax, 9, 2), (.minMin, 3, 12),
            (.minMax, 3, 2), (.maxMin, 9, 12),
            (.center, 3, 2), (nil, 3, 2),
            (.centerMaxMax, 9, 2), (.centerMinMin, 3, 12),
            (.centerMinMax, 9, 12), (.centerMaxMin, 3, 2)
        ]
        for (anchor, widthY, heightX) in cases {
            let vm = try makeViewModel(), id = UUID()
            let original = Sketch(plane: .ground,
                entities: [.rect(id: id, min: SIMD2(2, 3), max: SIMD2(12, 9))],
                rectangleSizingAnchors: anchor.map { [id: $0] } ?? [:])
            let sketch = try JSONDecoder().decode(Sketch.self, from: JSONEncoder().encode(original))
            vm.session.perform(AddSketchCommand(sketch: sketch))
            vm.mode = .sketching(sketch.id, tool: nil)
            vm.selectedSketchEntityIDs = [id]
            let width = try XCTUnwrap(vm.sketchDimensionLabels.first { $0.kind == .horizontal })
            let height = try XCTUnwrap(vm.sketchDimensionLabels.first { $0.kind == .vertical })
            XCTAssertEqual(width.worldStart, sketch.plane.toWorld(SIMD2(2, widthY)))
            XCTAssertEqual(width.worldEnd, sketch.plane.toWorld(SIMD2(12, widthY)))
            XCTAssertEqual(height.worldStart, sketch.plane.toWorld(SIMD2(heightX, 3)))
            XCTAssertEqual(height.worldEnd, sketch.plane.toWorld(SIMD2(heightX, 9)))
            XCTAssertEqual(width.displayValue, 10)
            XCTAssertEqual(height.displayValue, 6)
            for index in 0..<4 {
                vm.selectedAxisRectangleEdge = (id, index)
                let kind: DimensionKind = index % 2 == 0 ? .horizontal : .vertical
                let label = try XCTUnwrap(vm.sketchDimensionLabels.first { $0.kind == kind })
                let edge = try XCTUnwrap(RectangleConstruction.axisEdge(sketch.entities[0], index: index))
                XCTAssertEqual(label.worldStart, sketch.plane.toWorld(edge.a))
                XCTAssertEqual(label.worldEnd, sketch.plane.toWorld(edge.b))
            }
            XCTAssertEqual(vm.activeSketch?.entities, original.entities)
        }
    }

    func testCenterRectangleDragRetainsLeaderDirectionWithoutChangingSizingIntent() throws {
        let settings = AppSettings.shared
        let oldGrid = settings.snapToGrid
        settings.snapToGrid = false
        defer { settings.snapToGrid = oldGrid }
        for (delta, expected) in [
            (SIMD2<Double>(5, 3), RectangleSizingAnchor.centerMinMin),
            (SIMD2<Double>(5, -3), .centerMinMax),
            (SIMD2<Double>(-5, 3), .centerMaxMin),
            (SIMD2<Double>(-5, -3), .centerMaxMax)
        ] {
            let vm = try makeViewModel()
            let original = openSketch(vm, entities: [])
            vm.mode = .sketching(original.id, tool: .rect)
            vm.setRectangleType(.center)
            vm.autoConstrainSettings.enabled = false
            let center = SIMD2<Double>(20, 20)
            func ray(_ p: SIMD2<Double>) -> Ray {
                Ray(origin: SIMD3<Float>(original.plane.toWorld(p) + original.plane.normal * 10),
                    direction: SIMD3<Float>(-original.plane.normal))
            }
            XCTAssertTrue(vm.beginSketchStroke(ray: ray(center)))
            vm.updateSketchStroke(ray: ray(center + delta))
            vm.endSketchStroke(ray: ray(center + delta))
            let saved = try XCTUnwrap(vm.activeSketch)
            let id = try XCTUnwrap(saved.entities.first?.id)
            XCTAssertEqual(saved.rectangleSizingAnchors[id], expected)
            XCTAssertNil(expected.cornerUsesMax, "Label direction must not turn center sizing into corner sizing")
            XCTAssertEqual(vm.sketchDimensionLabels.count, 2)
            vm.undo()
            XCTAssertTrue(vm.activeSketch!.rectangleSizingAnchors.isEmpty)
            vm.redo()
            XCTAssertEqual(vm.activeSketch?.rectangleSizingAnchors[id], expected)
            let decoded = try JSONDecoder().decode(Sketch.self, from: JSONEncoder().encode(saved))
            XCTAssertEqual(decoded.rectangleSizingAnchors[id], expected)
        }
    }

    func testDrivingReadoutIgnoresRoundingNoiseButShowsRealGeometryDifferences() throws {
        let previousUnit = AppSettings.shared.unit
        AppSettings.shared.unit = .millimeters
        defer { AppSettings.shared.unit = previousUnit }
        for value in [0.4345, 0.43445] {
            for residual in [-1e-12, 1e-12, 0.01] {
                let vm = try makeViewModel(), id = UUID()
                let dimension = SketchDimension(kind: .horizontal, refs: [
                    ConstraintRef(entityID: id, role: .endpointA),
                    ConstraintRef(entityID: id, role: .endpointB)
                ], value: value, displayExpression: "(0.869/2) mm")
                let sketch = Sketch(plane: .ground, entities: [
                    .rect(id: id, min: SIMD2(1.1313221349728357, 2.4110153731990893),
                          max: SIMD2(1.1313221349728357 + value + residual, 2.724015373200147))
                ], dimensions: [dimension])
                vm.session.perform(AddSketchCommand(sketch: sketch))
                vm.mode = .sketching(sketch.id, tool: nil)
                vm.selectedSketchEntityIDs = [id]
                let label = try XCTUnwrap(vm.sketchDimensionLabels.first { $0.dimensionID == dimension.id })
                let expected = residual == 0.01 ? value + residual : value
                XCTAssertEqual(label.displayValue, expected, accuracy: 1e-14)
                XCTAssertEqual(label.text, DisplayUnit.millimeters.compactLengthString(fromMM: expected))
                XCTAssertEqual(vm.activeSketch?.entities, sketch.entities,
                               "Readout stabilization must not modify geometry")
            }
        }
    }

    func testTypedArcRotationUsesVisibleBoundsPivot() throws {
        let vm = try makeViewModel(), id = UUID()
        let arc = SketchEntity.arc(id: id, center: .zero, radius: 2,
                                  startAngle: -.pi / 2, endAngle: .pi / 2)
        let sketch = openSketch(vm, entities: [arc])
        vm.mode = .sketching(sketch.id, tool: nil)
        vm.selectedSketchEntityIDs = [id]
        vm.sketchTransformActive = true
        XCTAssertEqual(vm.sketchSelectionCentroid!.x, 1, accuracy: 1e-8)
        XCTAssertEqual(vm.sketchSelectionCentroid!.y, 0, accuracy: 1e-8)
        XCTAssertTrue(vm.commitSketchTransformControl(.rotation, text: "45 deg"))
        guard case let .arc(_, center, radius, start, end) = vm.activeSketch?.entities.first else { return XCTFail() }
        XCTAssertEqual(center.x, 1 - sqrt(0.5), accuracy: 1e-5)
        XCTAssertEqual(center.y, -sqrt(0.5), accuracy: 1e-5)
        XCTAssertEqual(radius, 2, accuracy: 1e-5)
        XCTAssertEqual(start, -.pi / 4, accuracy: 1e-5)
        XCTAssertEqual(SketchEntity.arcSweep(startAngle: start, endAngle: end), .pi, accuracy: 1e-5)
        vm.session.undo()
        XCTAssertEqual(vm.activeSketch?.entities, [arc])
    }

    func testReferencedRectangleRotationDoesNotDiscardIntentOrAddHistory() throws {
        for hasDimension in [false, true] {
            let vm = try makeViewModel(), id = UUID()
            var sketch = Sketch(plane: .ground, entities: [.rect(id: id, min: .zero, max: SIMD2(4, 3))])
            sketch.rectangleSizingAnchors[id] = .minMin
            if hasDimension {
                sketch.dimensions = [.init(kind: .horizontal, refs: [
                    .init(entityID: id, role: .endpointA), .init(entityID: id, role: .endpointB)
                ], value: 4, displayExpression: "(2+2) mm")]
            } else {
                sketch.constraints = [.init(kind: .fixed, refs: [.init(entityID: id, role: .center)])]
            }
            vm.session.perform(AddSketchCommand(sketch: sketch))
            vm.mode = .sketching(sketch.id, tool: nil)
            vm.selectedSketchEntityIDs = [id]
            vm.sketchTransformActive = true
            XCTAssertFalse(vm.commitSketchTransformControl(.rotation, text: "45"))
            vm.updateSketchTransformControl(.rotation, value: 30)
            vm.endSketchTransformControl()
            XCTAssertEqual(vm.activeSketch?.entities, sketch.entities)
            XCTAssertEqual(vm.activeSketch?.dimensions, sketch.dimensions)
            XCTAssertEqual(vm.activeSketch?.constraints, sketch.constraints)
            vm.session.undo()
            XCTAssertNil(vm.activeSketch, "Rejected rotation must not insert a history step")
        }
    }

    func testMigratedCenterAndCornerLockRejectsSizeWithoutModalOrHistory() throws {
        let vm = try makeViewModel(), id = UUID()
        var sketch = Sketch(plane: .ground, entities: [.rect(id: id, min: SIMD2(2, 3), max: SIMD2(6, 5))])
        sketch.rectangleSizingAnchors[id] = .center
        sketch.constraints = [.init(kind: .fixed, refs: [.init(entityID: id, role: .center)])]
        let refs: [ConstraintRef] = [.init(entityID: id, role: .endpointA), .init(entityID: id, role: .endpointB)]
        sketch.dimensions = [.init(kind: .horizontal, refs: refs, value: 4),
                             .init(kind: .vertical, refs: refs, value: 2)]
        vm.session.perform(AddSketchCommand(sketch: sketch))
        vm.mode = .sketching(sketch.id, tool: nil)
        vm.selectedSketchEntityIDs = [id]
        vm.sketchTransformActive = true
        XCTAssertTrue(vm.commitSketchTransformControl(.rotation, text: "35"))
        vm.sketchTransformActive = false
        let rotated = try XCTUnwrap(vm.activeSketch)
        vm.selectedSketchEntityIDs = []
        vm.selectedSketchPoints = [.init(entityID: rotated.entities[0].id, role: .endpointA)]
        vm.applyConstraint(.fixed)
        let locked = try XCTUnwrap(vm.activeSketch)
        XCTAssertGreaterThan(locked.constraints.count, rotated.constraints.count)
        let cornerLock = try XCTUnwrap(locked.constraints.first { !rotated.constraints.contains($0) })
        XCTAssertTrue(vm.canUnlockSketchSelection)
        XCTAssertFalse(vm.sketchConstraintGlyphs.contains { $0.id == cornerLock.id })
        let cornerMarkers = vm.sketchPointMarkers.filter { $0.isRectangleCorner }
        XCTAssertEqual(cornerMarkers.count, 8, "Both endpoint references on all four migrated sides stay hollow")
        XCTAssertTrue(cornerMarkers.allSatisfy { $0.state != .free })
        vm.selectedConstraintID = cornerLock.id
        XCTAssertTrue(vm.sketchConstraintGlyphs.contains { $0.id == cornerLock.id }, "Explicit constraint inspection stays available")
        vm.selectedConstraintID = nil
        vm.beginDimensionEdit(try XCTUnwrap(vm.sketchDimensionLabels.first { $0.dimensionID == sketch.dimensions[0].id }))
        vm.commitDimensionEdit("5 mm")
        XCTAssertEqual(vm.activeSketch, locked, "Refusal preserves exact geometry and saved constraints/dimensions")
        XCTAssertNil(vm.editingDimension)
        XCTAssertNil(vm.errorMessage, "Expected conflict must not require dismissing a modal alert")
        XCTAssertEqual(vm.selectedSketchPoints.count, 1, "Refusal retains the selected corner")
        XCTAssertTrue(vm.selectedSketchEntityIDs.isEmpty)
        XCTAssertEqual(vm.notice, "This constraint would conflict with existing ones.")
        vm.undo()
        XCTAssertEqual(vm.activeSketch, rotated, "Rejected size must not consume Undo; remove corner Lock")
        vm.redo()
        XCTAssertEqual(vm.activeSketch, locked)
    }

    func testCenterRectangleRotationMigratesIntentInOneUndoStep() throws {
        let vm = try makeViewModel(), id = UUID()
        var sketch = Sketch(plane: .ground, entities: [.rect(id: id, min: SIMD2(2, 3), max: SIMD2(6, 5))])
        sketch.rectangleSizingAnchors[id] = .center
        sketch.constraints = [.init(kind: .fixed, refs: [.init(entityID: id, role: .center)])]
        let refs: [ConstraintRef] = [.init(entityID: id, role: .endpointA), .init(entityID: id, role: .endpointB)]
        sketch.dimensions = [.init(kind: .horizontal, refs: refs, value: 4, displayExpression: "(2+2) mm"),
                             .init(kind: .vertical, refs: refs, value: 2)]
        vm.session.perform(AddSketchCommand(sketch: sketch))
        vm.mode = .sketching(sketch.id, tool: nil)
        vm.selectedSketchEntityIDs = [id]
        vm.sketchTransformActive = true
        XCTAssertTrue(vm.commitSketchTransformControl(.rotation, text: "45"))
        let rotated = try XCTUnwrap(vm.activeSketch)
        XCTAssertEqual(rotated.entities.count, 4)
        XCTAssertEqual(rotated.dimensions.map(\.id), sketch.dimensions.map(\.id))
        XCTAssertEqual(rotated.dimensions.map(\.value), [4, 2])
        XCTAssertEqual(rotated.dimensions.first?.displayExpression, "(2+2) mm")
        XCTAssertTrue(rotated.constraints.contains(sketch.constraints[0]))
        XCTAssertTrue(vm.commitSketchTransformControl(.rotation, text: "90"))
        let reedited = try XCTUnwrap(vm.activeSketch)
        XCTAssertNotEqual(reedited.entities, rotated.entities)
        XCTAssertEqual(reedited.dimensions, rotated.dimensions)
        XCTAssertEqual(reedited.rotatedRectangleEdges, rotated.rotatedRectangleEdges)
        vm.session.undo()
        XCTAssertEqual(vm.activeSketch, rotated, "Retained angle re-edit is a separate exact Undo step")
        let center = try XCTUnwrap(vm.sketchRectangleCenterMarkers.first)
        XCTAssertEqual(center.state, .locked)
        XCTAssertLessThan(simd_distance(center.world, SIMD3<Float>(sketch.plane.toWorld(SIMD2(4, 4)))), 1e-5)
        vm.session.undo()
        XCTAssertEqual(vm.activeSketch, sketch)
        vm.session.redo()
        XCTAssertEqual(vm.activeSketch, rotated)
        XCTAssertEqual(try JSONDecoder().decode(Sketch.self, from: JSONEncoder().encode(rotated)), rotated)
        vm.selectedSketchEntityIDs = Set(rotated.entities.map(\.id))
        let widthLabel = try XCTUnwrap(vm.sketchDimensionLabels.first { $0.dimensionID == sketch.dimensions[0].id })
        vm.beginDimensionEdit(widthLabel)
        vm.commitDimensionEdit("1")
        XCTAssertEqual(vm.activeSketch?.dimensions.count, 2, "Edit existing driving size, never add a duplicate")
        XCTAssertEqual(vm.activeSketch?.dimensions.map(\.id), sketch.dimensions.map(\.id))
        XCTAssertEqual(vm.activeSketch?.dimensions.map(\.value), [1, 2])
        vm.session.undo()
        XCTAssertEqual(vm.activeSketch, rotated)
        vm.session.undo()
        vm.sketchTransformActive = false
        vm.selectedSketchEntityIDs = []
        func ray(_ p: SIMD2<Double>) -> Ray {
            Ray(origin: SIMD3<Float>(sketch.plane.toWorld(p) + sketch.plane.normal * 10),
                direction: SIMD3<Float>(-sketch.plane.normal))
        }
        XCTAssertTrue(vm.beginSketchStroke(ray: ray(SIMD2(6, 5))))
        vm.updateSketchStroke(ray: ray(SIMD2(4 + sqrt(5), 4)))
        vm.endSketchStroke(ray: ray(SIMD2(4 + sqrt(5), 4)))
        let direct = try XCTUnwrap(vm.activeSketch)
        XCTAssertEqual(direct.entities.count, 4)
        XCTAssertTrue(vm.usesExplicitSketchTransform, "Migrated rectangle must not show a default transform ring")
        XCTAssertEqual(direct.dimensions.map(\.id), sketch.dimensions.map(\.id))
        XCTAssertTrue(direct.constraints.contains(sketch.constraints[0]))
        guard case let .line(edgeID, corner, _) = direct.entities[0] else { return XCTFail("Expected migrated edge") }
        vm.selectedSketchEntityIDs = []
        vm.selectedSketchPoints = [.init(entityID: edgeID, role: .endpointA)]
        let centerPoint = SIMD2<Double>(4, 4)
        let delta = corner - centerPoint
        let nextCorner = centerPoint + SIMD2(delta.x * cos(0.3) - delta.y * sin(0.3),
                                            delta.x * sin(0.3) + delta.y * cos(0.3))
        XCTAssertTrue(vm.beginSketchStroke(ray: ray(corner)))
        vm.updateSketchStroke(ray: ray(nextCorner))
        vm.endSketchStroke(ray: ray(nextCorner))
        XCTAssertTrue(vm.usesExplicitSketchTransform, "Reselected migrated corner must not expose a default ring")
        XCTAssertTrue(vm.selectedSketchEntityIDs.isEmpty, "Corner drag must not select an entire edge")
        XCTAssertEqual(vm.selectedSketchPoints.count, 1)
        XCTAssertNotNil(vm.selectedMigratedRectangleCornerMarker)
        XCTAssertNil(vm.rectangleHandleGeometry, "A selected corner must not expose an edge-move handle")
        XCTAssertEqual(vm.sketchDimensionLabels.count, 2, "Keep both sizes, not a stale point-to-edge zero candidate")
        XCTAssertFalse(vm.sketchDimensionLabels.contains { $0.dimensionID == nil && $0.displayValue == 0 })
        XCTAssertEqual(vm.activeSketch?.dimensions, direct.dimensions)
        XCTAssertTrue(vm.activeSketch?.constraints.contains(sketch.constraints[0]) == true)
        let redragged = vm.activeSketch
        vm.undo()
        XCTAssertEqual(vm.activeSketch, direct)
        XCTAssertTrue(vm.selectedSketchPoints.isEmpty)
        XCTAssertNil(vm.selectedMigratedRectangleCornerMarker)
        XCTAssertTrue(vm.sketchDimensionLabels.isEmpty)
        vm.redo()
        XCTAssertEqual(vm.activeSketch, redragged)
        XCTAssertTrue(vm.selectedSketchPoints.isEmpty)
        XCTAssertTrue(vm.sketchDimensionLabels.isEmpty)
        vm.undo()
        XCTAssertEqual(vm.activeSketch, direct)
        vm.session.undo()
        XCTAssertEqual(vm.activeSketch, sketch)
        vm.session.perform(CompositeCommand(title: "Legacy Decomposition", commands: [
            RemoveSketchEntitiesCommand(ids: [id], sketch: sketch),
            AddSketchEntityCommand(sketchID: sketch.id, entity: .line(id: id, a: .zero, b: SIMD2(1, 0)))
        ]))
        vm.session.undo()
        XCTAssertEqual(vm.activeSketch, sketch, "Undo must restore rectangle sizing metadata too")
    }

    func testRetainedTransformReeditUsesOriginalPivotAndSeparateUndo() throws {
        let vm = try makeViewModel(), id = UUID()
        let arc = SketchEntity.arc(id: id, center: .zero, radius: 2,
                                  startAngle: -.pi / 2, endAngle: .pi / 2)
        let sketch = openSketch(vm, entities: [arc])
        vm.mode = .sketching(sketch.id, tool: nil)
        vm.selectedSketchEntityIDs = [id]
        vm.sketchTransformActive = true
        XCTAssertTrue(vm.commitSketchTransformControl(.rotation, text: "45"))
        let first = vm.activeSketch!.entities
        XCTAssertEqual(vm.retainedSketchTransformValue(.rotation), 45)
        XCTAssertEqual(vm.sketchSelectionCentroid!.x, 1, accuracy: 1e-6)
        XCTAssertEqual(vm.sketchSelectionCentroid!.y, 0, accuracy: 1e-6)
        XCTAssertTrue(vm.commitSketchTransformControl(.rotation, text: "90"))
        guard case let .arc(_, center, radius, start, _) = vm.activeSketch?.entities.first else { return XCTFail() }
        XCTAssertEqual(center.x, 1, accuracy: 1e-5)
        XCTAssertEqual(center.y, -1, accuracy: 1e-5)
        XCTAssertEqual(radius, 2, accuracy: 1e-5)
        XCTAssertEqual(start, 0, accuracy: 1e-5)
        vm.session.undo()
        XCTAssertEqual(vm.activeSketch?.entities, first)
        vm.session.redo()
        XCTAssertTrue(vm.commitSketchTransformControl(.rotation, text: "0"))
        guard case let .arc(_, restored, _, _, _) = vm.activeSketch?.entities.first else { return XCTFail() }
        XCTAssertEqual(simd_length(restored), 0, accuracy: 1e-5)
        vm.sketchTransformActive = false
        XCTAssertNil(vm.retainedSketchTransformValue(.rotation))
    }

    func testMigratedRectangleCenterUnlockAndDragPreserveDimensions() throws {
        let vm = try makeViewModel(), id = UUID()
        var primitive = Sketch(plane: .ground, entities: [.rect(id: id, min: SIMD2(2, 3), max: SIMD2(6, 5))])
        primitive.rectangleSizingAnchors[id] = .center
        primitive.constraints = [.init(kind: .fixed, refs: [.init(entityID: id, role: .center)])]
        let refs: [ConstraintRef] = [.init(entityID: id, role: .endpointA), .init(entityID: id, role: .endpointB)]
        primitive.dimensions = [.init(kind: .horizontal, refs: refs, value: 4), .init(kind: .vertical, refs: refs, value: 2)]
        let sketch = try XCTUnwrap(RectangleConstruction.prepareCenterRotation(primitive, id: id,
            edgeIDs: [id, UUID(), UUID(), UUID()]))
        vm.session.perform(AddSketchCommand(sketch: sketch))
        vm.mode = .sketching(sketch.id, tool: nil)
        func ray(_ p: SIMD2<Double>) -> Ray {
            Ray(origin: SIMD3<Float>(sketch.plane.toWorld(p) + sketch.plane.normal * 10),
                direction: SIMD3<Float>(-sketch.plane.normal))
        }
        vm.handle(.tap(ray: ray(SIMD2(4, 4))))
        XCTAssertTrue(vm.canUnlockSketchSelection)
        XCTAssertEqual(vm.sketchRectangleCenterLockMarkers.count, 1)
        vm.toggleRectangleCenterLock()
        XCTAssertFalse(vm.canUnlockSketchSelection)
        XCTAssertTrue(vm.beginSketchStroke(ray: ray(SIMD2(4, 4))))
        vm.updateSketchStroke(ray: ray(SIMD2(7, 6)))
        vm.endSketchStroke(ray: ray(SIMD2(7, 6)))
        let center = try XCTUnwrap(vm.sketchRectangleCenterMarkers.first)
        XCTAssertLessThan(simd_distance(center.world, SIMD3<Float>(sketch.plane.toWorld(SIMD2(7, 6)))), 1e-5)
        XCTAssertEqual(vm.activeSketch?.dimensions, sketch.dimensions)
        vm.session.undo()
        vm.session.undo()
        XCTAssertEqual(vm.activeSketch, sketch)
    }

    func testRotatedSketchAxisMovementPreservesFrameAndAbsoluteReedit() throws {
        let vm = try makeViewModel(), id = UUID()
        let arc = SketchEntity.arc(id: id, center: .zero, radius: 2,
                                  startAngle: -.pi / 2, endAngle: .pi / 2)
        let sketch = openSketch(vm, entities: [arc])
        vm.mode = .sketching(sketch.id, tool: nil)
        vm.selectedSketchEntityIDs = [id]
        vm.sketchTransformActive = true
        XCTAssertTrue(vm.commitSketchTransformControl(.rotation, text: "45"))
        guard case let .arc(_, rotated, _, _, _) = vm.activeSketch?.entities.first else { return XCTFail() }
        XCTAssertTrue(vm.commitSketchTransformControl(.x, text: "2 mm"))
        guard case let .arc(_, moved, radius, _, _) = vm.activeSketch?.entities.first else { return XCTFail() }
        XCTAssertEqual(moved.x - rotated.x, sqrt(2), accuracy: 1e-5)
        XCTAssertEqual(moved.y - rotated.y, sqrt(2), accuracy: 1e-5)
        XCTAssertEqual(radius, 2, accuracy: 1e-5)
        XCTAssertEqual(vm.sketchTransformFrameAngle, .pi / 4, accuracy: 1e-8)
        XCTAssertEqual(vm.sketchSelectionCentroid!.x, 1 + sqrt(2), accuracy: 1e-5)
        XCTAssertTrue(vm.commitSketchTransformControl(.x, text: "4 mm"))
        guard case let .arc(_, edited, _, _, _) = vm.activeSketch?.entities.first else { return XCTFail() }
        XCTAssertEqual(edited.x - rotated.x, 2 * sqrt(2), accuracy: 1e-5)
        XCTAssertEqual(edited.y - rotated.y, 2 * sqrt(2), accuracy: 1e-5)
        vm.session.undo()
        guard case let .arc(_, undone, _, _, _) = vm.activeSketch?.entities.first else { return XCTFail() }
        XCTAssertEqual(simd_length(undone - moved), 0, accuracy: 1e-5)
    }

    func testDiameterLabelPlacementTransientThenSavedUndoableWithoutGeometryChange() throws {
        let priorAlwaysShow = AppSettings.shared.alwaysShowDimensions
        let priorCircular = AppSettings.shared.circularAnnotations
        AppSettings.shared.alwaysShowDimensions = true
        AppSettings.shared.circularAnnotations = .radiusAndDiameter
        defer {
            AppSettings.shared.alwaysShowDimensions = priorAlwaysShow
            AppSettings.shared.circularAnnotations = priorCircular
        }
        let vm = try makeViewModel(), id = UUID()
        let entity = SketchEntity.circle(id: id, center: SIMD2(3, 4), radius: 2)
        let sketch = openSketch(vm, entities: [entity])
        vm.mode = .sketching(sketch.id, tool: nil)
        vm.selectedSketchEntityIDs = [id]
        let label = try XCTUnwrap(vm.sketchDimensionLabels.first)
        let firstOffset = SIMD2<Double>(-5, 3)
        vm.moveDiameterLabel(label, offset: firstOffset)
        XCTAssertEqual(vm.sketchDimensionLabels.first?.worldDiameterLabelAnchor,
                       sketch.plane.toWorld(SIMD2(-2, 7)))
        XCTAssertTrue(vm.activeSketch!.dimensions.isEmpty)
        XCTAssertEqual(vm.activeSketch!.entities, [entity])
        vm.selectedSketchEntityIDs = []
        vm.selectedSketchEntityIDs = [id]
        XCTAssertNil(vm.sketchDimensionLabels.first?.worldDiameterLabelAnchor)
        vm.moveDiameterLabel(label, offset: firstOffset)
        vm.beginDimensionEdit(try XCTUnwrap(vm.sketchDimensionLabels.first))
        vm.commitDimensionEdit("4 mm")
        XCTAssertEqual(vm.activeSketch?.dimensions.first?.labelOffset, firstOffset)
        let geometry = vm.activeSketch!.entities
        let driven = try XCTUnwrap(vm.sketchDimensionLabels.first)
        let secondOffset = SIMD2<Double>(-3, 6)
        vm.moveDiameterLabel(driven, offset: secondOffset)
        XCTAssertEqual(vm.activeSketch?.dimensions.first?.value, 4)
        XCTAssertEqual(vm.activeSketch?.entities, geometry)
        vm.session.undo()
        XCTAssertEqual(vm.activeSketch?.dimensions.first?.labelOffset, firstOffset)
        XCTAssertEqual(vm.activeSketch?.entities, geometry)
        vm.session.redo()
        XCTAssertEqual(vm.activeSketch?.dimensions.first?.labelOffset, secondOffset)
        vm.selectedSketchEntityIDs = []
        vm.selectedSketchEntityIDs = [id]
        XCTAssertEqual(vm.sketchDimensionLabels.first?.worldDiameterLabelAnchor,
                       sketch.plane.toWorld(SIMD2(0, 10)))
        let reopened = try JSONDecoder().decode(Sketch.self, from: JSONEncoder().encode(vm.activeSketch!))
        XCTAssertEqual(reopened.dimensions.first?.labelOffset, secondOffset)
        XCTAssertEqual(reopened.entities, geometry)
        let dimension = try XCTUnwrap(reopened.dimensions.first)
        var legacy = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(dimension)) as? [String: Any])
        legacy.removeValue(forKey: "labelOffset")
        let decoded = try JSONDecoder().decode(SketchDimension.self, from: JSONSerialization.data(withJSONObject: legacy))
        XCTAssertNil(decoded.labelOffset)
        XCTAssertEqual(decoded.value, 4)
    }

    func testCircularTransformHidesTemporaryReadoutsButKeepsDrivenDimensions() throws {
        let priorAlwaysShow = AppSettings.shared.alwaysShowDimensions
        let priorCircular = AppSettings.shared.circularAnnotations
        AppSettings.shared.alwaysShowDimensions = true
        AppSettings.shared.circularAnnotations = .radiusAndDiameter
        defer {
            AppSettings.shared.alwaysShowDimensions = priorAlwaysShow
            AppSettings.shared.circularAnnotations = priorCircular
        }
        for isArc in [false, true] {
            let vm = try makeViewModel(), id = UUID()
            let entity: SketchEntity = isArc
                ? .arc(id: id, center: .zero, radius: 2, startAngle: 0, endAngle: .pi / 2)
                : .circle(id: id, center: .zero, radius: 2)
            let sketch = openSketch(vm, entities: [entity])
            vm.mode = .sketching(sketch.id, tool: nil)
            vm.selectedSketchEntityIDs = [id]
            XCTAssertEqual(vm.sketchDimensionLabels.count, isArc ? 2 : 1)
            vm.sketchTransformActive = true
            XCTAssertTrue(vm.sketchDimensionLabels.isEmpty)
            vm.sketchTransformActive = false
            XCTAssertEqual(vm.sketchDimensionLabels.count, isArc ? 2 : 1)
            vm.beginDimensionForSelection()
            vm.commitDimensionEdit(isArc ? "2 mm" : "4 mm")
            let stored = try XCTUnwrap(vm.activeSketch?.dimensions.first)
            vm.sketchTransformActive = true
            XCTAssertEqual(vm.sketchDimensionLabels.map(\.dimensionID), [stored.id])
            let label = try XCTUnwrap(vm.sketchDimensionLabels.first)
            vm.beginDimensionEdit(label)
            XCTAssertEqual(vm.editingDimension?.dimensionID, stored.id)
            vm.cancelDimensionEdit()
            XCTAssertEqual(vm.sketchDimensionLabels.map(\.dimensionID), [stored.id])
            XCTAssertEqual(vm.activeSketch?.entities, [entity])
        }
    }

    func testSketchHistoryClearsSelectionButKeepsTransformArmed() throws {
        let vm = try makeViewModel(), id = UUID()
        let circle = SketchEntity.circle(id: id, center: .zero, radius: 2)
        let sketch = openSketch(vm, entities: [circle])
        vm.mode = .sketching(sketch.id, tool: nil)
        vm.selectedSketchEntityIDs = [id]
        vm.sketchTransformActive = true
        XCTAssertTrue(vm.commitSketchTransformControl(.x, text: "1 mm"))
        let moved = vm.activeSketch!.entities
        vm.undo()
        XCTAssertTrue(vm.sketchTransformActive)
        XCTAssertTrue(vm.selectedSketchEntityIDs.isEmpty)
        XCTAssertNil(vm.retainedSketchTransformValue(.x))
        XCTAssertEqual(vm.activeSketch?.entities, [circle])
        vm.redo()
        XCTAssertTrue(vm.sketchTransformActive)
        XCTAssertTrue(vm.selectedSketchEntityIDs.isEmpty)
        XCTAssertEqual(vm.activeSketch?.entities, moved)
        vm.selectedSketchEntityIDs = [id]
        XCTAssertTrue(vm.sketchTransformActive)
        vm.mode = .sketching(sketch.id, tool: .line)
        XCTAssertFalse(vm.sketchTransformActive)
    }

    func testCircleRotationRetainsFrameWithoutGeometryPerturbationOrHistoryFallthrough() throws {
        let vm = try makeViewModel(), id = UUID()
        let circle = SketchEntity.circle(id: id, center: SIMD2(2, 3), radius: 4)
        let sketch = openSketch(vm, entities: [circle])
        vm.mode = .sketching(sketch.id, tool: nil)
        vm.selectedSketchEntityIDs = [id]
        vm.selectedSketchEntityIDs = [id]
        vm.sketchTransformActive = true
        XCTAssertTrue(vm.commitSketchTransformControl(.rotation, text: "45"))
        XCTAssertEqual(vm.activeSketch?.entities, [circle])
        XCTAssertEqual(vm.sketchTransformFrameAngle, .pi / 4, accuracy: 1e-8)
        XCTAssertEqual(vm.retainedSketchTransformValue(.rotation), 45)
        vm.undo()
        XCTAssertTrue(vm.sketchTransformActive)
        XCTAssertTrue(vm.selectedSketchEntityIDs.isEmpty)
        XCTAssertEqual(vm.activeSketch?.entities, [circle], "Undo the frame, not circle creation")
        vm.redo()
        XCTAssertEqual(vm.activeSketch?.entities, [circle])
        vm.selectedSketchEntityIDs = [id]
        vm.sketchTransformActive = true
        XCTAssertTrue(vm.commitSketchTransformControl(.rotation, text: "45"))
        XCTAssertTrue(vm.commitSketchTransformControl(.x, text: "2 mm"))
        guard case let .circle(_, center, radius) = vm.activeSketch?.entities.first else { return XCTFail() }
        XCTAssertEqual(center.x, 2 + sqrt(2), accuracy: 1e-5)
        XCTAssertEqual(center.y, 3 + sqrt(2), accuracy: 1e-5)
        XCTAssertEqual(radius, 4, accuracy: 1e-5)
    }

    func testExactSketchAxisInputPreservesDiameterAndLocksAndHistory() throws {
        let vm = try makeViewModel(), id = UUID()
        let circle = SketchEntity.circle(id: id, center: SIMD2(2, 3), radius: 4)
        let sketch = openSketch(vm, entities: [circle])
        vm.mode = .sketching(sketch.id, tool: nil)
        vm.selectedSketchEntityIDs = [id]
        vm.sketchTransformActive = true
        XCTAssertTrue(vm.commitSketchTransformControl(.y, text: "2 cm"))
        guard case let .circle(_, center, radius) = vm.activeSketch?.entities.first else { return XCTFail() }
        XCTAssertEqual(center.x, 2, accuracy: 1e-5)
        XCTAssertEqual(center.y, 23, accuracy: 1e-5)
        XCTAssertEqual(radius, 4, accuracy: 1e-5)
        vm.session.undo()
        XCTAssertEqual(vm.activeSketch?.entities, [circle])
        vm.session.redo()
        let moved = vm.activeSketch!.entities
        vm.session.perform(AddSketchConstraintCommand(sketchID: sketch.id,
            constraint: .init(kind: .fixed, refs: [.init(entityID: id, role: .whole)])))
        XCTAssertTrue(vm.commitSketchTransformControl(.x, text: "5 mm"))
        XCTAssertEqual(vm.activeSketch?.entities, moved)
        XCTAssertFalse(vm.commitSketchTransformControl(.x, text: "5 deg"))
        XCTAssertFalse(vm.commitSketchTransformControl(.rotation, text: "5 cm"))
        XCTAssertEqual(vm.activeSketch?.entities, moved)
    }

    func testMixedLineAndCircleTransformCopyOffAndOnRemainIndependentThroughHistory() throws {
        let vm = try makeViewModel()
        let line = SketchEntity.line(id: UUID(), a: SIMD2(0, 0), b: SIMD2(4, 0))
        let circle = SketchEntity.circle(id: UUID(), center: SIMD2(8, 2), radius: 1.5)
        let sketch = openSketch(vm, entities: [line, circle])
        vm.mode = .sketching(sketch.id, tool: nil)
        vm.selectedSketchEntityIDs = [line.id, circle.id]
        vm.sketchTransformActive = true
        func assertGeometry(_ actual: [SketchEntity], _ expected: [SketchEntity],
                            file: StaticString = #filePath, line sourceLine: UInt = #line) {
            XCTAssertEqual(actual.count, expected.count, file: file, line: sourceLine)
            for (lhs, rhs) in zip(actual, expected) {
                XCTAssertEqual(lhs.id, rhs.id, file: file, line: sourceLine)
                XCTAssertEqual(EditorViewModel.entityCenter(lhs).x,
                               EditorViewModel.entityCenter(rhs).x,
                               accuracy: 1e-8, file: file, line: sourceLine)
                XCTAssertEqual(EditorViewModel.entityCenter(lhs).y,
                               EditorViewModel.entityCenter(rhs).y,
                               accuracy: 1e-8, file: file, line: sourceLine)
            }
        }

        XCTAssertTrue(vm.commitSketchTransformControl(.x, text: "3 mm"))
        let moved = SketchTransform.translate(entities: [line, circle], by: SIMD2(3, 0))
        assertGeometry(try XCTUnwrap(vm.activeSketch).entities, moved)
        XCTAssertEqual(vm.activeSketch?.entities.count, 2, "Copy off moves the selected sources")
        vm.session.undo()
        XCTAssertEqual(vm.activeSketch, sketch)
        vm.session.redo()
        assertGeometry(try XCTUnwrap(vm.activeSketch).entities, moved)
        vm.session.undo()

        vm.selectedSketchEntityIDs = [line.id, circle.id]
        vm.sketchTransformActive = true
        vm.sketchCopyOnDrag = true
        XCTAssertTrue(vm.commitSketchTransformControl(.y, text: "2 mm"))
        let copiedAndMoved = try XCTUnwrap(vm.activeSketch)
        XCTAssertEqual(copiedAndMoved.entities.count, 4)
        XCTAssertEqual(Array(copiedAndMoved.entities.prefix(2)), [line, circle],
                       "Copy on must leave both mixed-selection sources in place")
        XCTAssertEqual(Set(copiedAndMoved.entities.suffix(2).map(\.id)), vm.selectedSketchEntityIDs)
        let translatedCopies = SketchTransform.translate(
            entities: Array(copiedAndMoved.entities.suffix(2)), by: SIMD2(0, -2))
        for (actual, expected) in zip(
            translatedCopies.map { EditorViewModel.entityCenter($0) },
            [EditorViewModel.entityCenter(line), EditorViewModel.entityCenter(circle)]
        ) {
            XCTAssertEqual(actual.x, expected.x, accuracy: 1e-8)
            XCTAssertEqual(actual.y, expected.y, accuracy: 1e-8)
        }

        vm.session.undo()
        XCTAssertEqual(vm.activeSketch?.entities.count, 4,
                       "First Undo restores the new copy to its creation position")
        vm.session.undo()
        XCTAssertEqual(vm.activeSketch, sketch, "Second Undo removes the mixed copy atomically")
        vm.session.redo()
        vm.session.redo()
        XCTAssertEqual(vm.activeSketch, copiedAndMoved)
    }

    func testUnlockSelectedRectangleSidePreservesOtherLocksAndHistory() throws {
        let vm = try makeViewModel(), id = UUID()
        let sketch = openSketch(vm, entities: [.rect(id: id, min: .zero, max: SIMD2(10, 6))])
        let right = ConstraintRef(entityID: id, role: .whole, rectangleEdge: 1)
        let left = ConstraintRef(entityID: id, role: .whole, rectangleEdge: 3)
        let lock = SketchConstraint(kind: .fixed, refs: [right, left])
        vm.session.perform(AddSketchConstraintCommand(sketchID: sketch.id, constraint: lock))
        vm.selectedSketchEntityIDs = [id]
        vm.selectedAxisRectangleEdge = (id, 1)
        XCTAssertTrue(vm.canUnlockSketchSelection)
        vm.toggleSketchSelectionLock()
        XCTAssertFalse(vm.canUnlockSketchSelection)
        XCTAssertEqual(vm.activeSketch?.constraints.first?.refs, [left])
        vm.undo()
        XCTAssertEqual(vm.activeSketch?.constraints, [lock])
        vm.redo()
        XCTAssertEqual(vm.activeSketch?.constraints.first?.refs, [left])
        vm.selectedAxisRectangleEdge = (id, 3)
        XCTAssertTrue(vm.canUnlockSketchSelection)
        vm.toggleSketchSelectionLock()
        XCTAssertTrue(vm.activeSketch?.constraints.isEmpty == true)
        XCTAssertEqual(vm.activeSketch?.entities, sketch.entities, "Unlock must not relocate geometry")
    }

    // MARK: - Coincident welds a shared corner

    func testCoincidentOnTwoLinesWeldsCorner() throws {
        let vm = try makeViewModel()
        let l0 = line(SIMD2(0, 0), SIMD2(10, 0))
        let l1 = line(SIMD2(10.1, 0.1), SIMD2(20, 5))
        let sketch = openSketch(vm, entities: [l0, l1])
        vm.selectedSketchEntityIDs = [l0.id, l1.id]

        XCTAssertTrue(vm.canApplyConstraint(.coincident),
                      "Two lines sharing a near corner should enable Coincident")
        vm.applyConstraint(.coincident)

        // The constraint is recorded on the sketch.
        let solved = vm.session.document.sketches.first { $0.id == sketch.id }
        XCTAssertEqual(solved?.constraints.count, 1)
        XCTAssertEqual(solved?.constraints.first?.kind, .coincident)

        // Line 0's end and line 1's start now coincide.
        guard let a = currentLine(vm, id: l0.id), let b = currentLine(vm, id: l1.id) else {
            return XCTFail("Lines missing after solve")
        }
        XCTAssertLessThan(simd_distance(a.b, b.a), 1e-6,
                          "Coincident should weld the shared endpoints together")

        // Re-solving the committed sketch is stable (no further motion).
        let (again, _) = SketchSolverBridge.solve(solved!, movingEntity: nil, dragTarget: nil)
        for (before, after) in zip(solved!.entities, again) {
            XCTAssertEqual(before, after, "A satisfied sketch must not drift on re-solve")
        }
    }

    func testCoincidentIsOneUndoStep() throws {
        let vm = try makeViewModel()
        let l0 = line(SIMD2(0, 0), SIMD2(10, 0))
        let l1 = line(SIMD2(10.2, 0.2), SIMD2(20, 5))
        _ = openSketch(vm, entities: [l0, l1])
        vm.selectedSketchEntityIDs = [l0.id, l1.id]

        XCTAssertTrue(vm.session.undoStack.canUndo, "Adding the sketch is undoable")
        let sketchesBefore = vm.session.document.sketches.count
        vm.applyConstraint(.coincident)
        XCTAssertEqual(vm.session.document.sketches.count, sketchesBefore)

        vm.undo() // removes the constraint + geometry move in one step
        let afterUndo = vm.session.document.sketches.first
        XCTAssertEqual(afterUndo?.constraints.count, 0,
                       "One undo removes the whole constraint application")
        // Geometry restored to the pre-solve corner gap.
        guard let a = currentLine(vm, id: l0.id) else { return XCTFail("line gone") }
        XCTAssertEqual(a.b, SIMD2(10, 0), "Undo restores the original endpoint")
    }

    // MARK: - Horizontal levels a near-horizontal line

    func testHorizontalLevelsLine() throws {
        let vm = try makeViewModel()
        let l0 = line(SIMD2(0, 0), SIMD2(10, 0.5))
        _ = openSketch(vm, entities: [l0])
        vm.selectedSketchEntityIDs = [l0.id]

        XCTAssertTrue(vm.canApplyConstraint(.horizontal),
                      "A single selected line should enable Horizontal")
        vm.applyConstraint(.horizontal)

        guard let a = currentLine(vm, id: l0.id) else { return XCTFail("line gone") }
        XCTAssertLessThan(abs(a.a.y - a.b.y), 1e-6,
                          "Horizontal should level the line's endpoints")
    }

    func testLineHoverNamesSnapsBeforePlacementWithoutEditingGeometry() throws {
        let vm = try makeViewModel()
        let settings = AppSettings.shared
        let guidepoints = settings.snapToSketchGuidepoints
        let hints = settings.showSnapHints
        defer { settings.snapToSketchGuidepoints = guidepoints; settings.showSnapHints = hints }
        settings.snapToSketchGuidepoints = true
        settings.showSnapHints = true
        let original = Sketch(plane: .ground, entities: [line(SIMD2(0, 0), SIMD2(10, 0))])
        vm.session.perform(AddSketchCommand(sketch: original))
        vm.mode = .sketching(original.id, tool: .line)
        func ray(_ x: Double) -> Ray {
            let p = original.plane.toWorld(SIMD2(x, 0))
            let n = original.plane.normal
            return Ray(origin: SIMD3<Float>(Float(p.x+n.x*10), Float(p.y+n.y*10), Float(p.z+n.z*10)),
                       direction: SIMD3<Float>(Float(-n.x), Float(-n.y), Float(-n.z)))
        }
        XCTAssertTrue(vm.updateLinePreview(ray: ray(0)))
        XCTAssertEqual(vm.activeSnapLabel?.text, "Endpoint")
        XCTAssertNil(vm.pendingEntity)
        XCTAssertEqual(vm.activeSketch, original)
        XCTAssertTrue(vm.updateLinePreview(ray: ray(5)))
        XCTAssertEqual(vm.activeSnapLabel?.text, "Midpoint")
        XCTAssertTrue(vm.updateLinePreview(ray: nil))
        XCTAssertNil(vm.activeSnapLabel)
        settings.snapToSketchGuidepoints = false
        _ = vm.updateLinePreview(ray: ray(0))
        XCTAssertNil(vm.activeSnapLabel)
        vm.session.undo()
        XCTAssertNil(vm.activeSketch, "Hover must not add an undoable edit")
    }

    func testCopiedLinesRemainIndependentThroughHistoryAndReload() throws {
        let vm = try makeViewModel()
        let a = line(SIMD2(0, 0), SIMD2(10, 0))
        let b = line(SIMD2(10, 0), SIMD2(10, 5))
        let original = Sketch(plane: .ground, entities: [a, b])
        vm.session.perform(AddSketchCommand(sketch: original))
        vm.mode = .sketching(original.id, tool: nil)
        let copies = vm.duplicateSketchEntities([a, b], in: original.id)
        let copied = try XCTUnwrap(vm.activeSketch)
        let reopened = try JSONDecoder().decode(Sketch.self, from: JSONEncoder().encode(copied))
        let targets = SketchTransform.translate(entities: copies, by: SIMD2(0, 3))
        let moved = try XCTUnwrap(SketchSolverBridge.solveLineTransform(reopened, targets: targets))
        XCTAssertEqual(Array(moved.prefix(2)), original.entities, "Copy must not move sources")
        for index in copies.indices {
            guard case let .line(_, a, b) = moved[index + 2],
                  case let .line(_, c, d) = targets[index] else { return XCTFail("Expected line") }
            XCTAssertLessThan(simd_distance(a, c), 1e-4)
            XCTAssertLessThan(simd_distance(b, d), 1e-4)
        }
        XCTAssertEqual(copied.constraints.filter { $0.kind == .coincident }.count, 1)
        vm.session.undo()
        XCTAssertEqual(vm.activeSketch, original)
        vm.session.redo()
        XCTAssertEqual(vm.activeSketch, copied)
    }

    func testCopyDoesNotReconnectPreviouslyDisconnectedSources() throws {
        let vm = try makeViewModel()
        let a = line(SIMD2(0, 0), SIMD2(10, 0))
        let b = line(SIMD2(10, 0), SIMD2(10, 5))
        var original = Sketch(plane: .ground, entities: [a, b])
        original.disconnectedEndpoints = [.init(entityID: a.id, role: .endpointB)]
        vm.session.perform(AddSketchCommand(sketch: original))
        vm.mode = .sketching(original.id, tool: nil)
        _ = vm.duplicateSketchEntities([a, b], in: original.id)
        XCTAssertTrue(try XCTUnwrap(vm.activeSketch).constraints.isEmpty)
    }

    func testDisconnectPreservesDimensionsAndIndependentMovementThroughHistoryAndReload() throws {
        let vm = try makeViewModel()
        let edges = RectangleConstruction.threePoint(a: SIMD2(0, 0), b: SIMD2(10, 2),
            heightPoint: SIMD2(9, 7), ids: (0..<4).map { _ in UUID() })
        let original = Sketch(plane: .ground, entities: edges,
            constraints: RectangleConstruction.constraints(for: edges),
            dimensions: [.init(kind: .distance, refs: [.init(entityID: edges[0].id, role: .endpointA),
                .init(entityID: edges[0].id, role: .endpointB)], value: sqrt(104))])
        vm.session.perform(AddSketchCommand(sketch: original))
        vm.mode = .sketching(original.id, tool: nil)
        vm.selectedSketchEntityIDs = [edges[0].id]
        XCTAssertNotNil(vm.rectangleHandleGeometry)
        XCTAssertTrue(vm.canDisconnectSketchSelection)
        vm.disconnectSketchSelection()
        let detached = try XCTUnwrap(vm.activeSketch)
        XCTAssertEqual(detached.entities, original.entities)
        XCTAssertEqual(detached.dimensions, original.dimensions)
        XCTAssertEqual(detached.constraints.filter { $0.kind != .coincident },
                       original.constraints.filter { $0.kind != .coincident })
        XCTAssertEqual(detached.constraints.filter { $0.kind == .coincident }.count, 2)
        vm.selectedSketchEntityIDs = [edges[0].id]
        XCTAssertFalse(vm.canDisconnectSketchSelection)
        XCTAssertNil(vm.rectangleHandleGeometry)
        let reopened = try JSONDecoder().decode(Sketch.self, from: JSONEncoder().encode(detached))
        let targets = SketchTransform.translate(entities: [edges[0]], by: SIMD2(0, 3))
        let moved = try XCTUnwrap(SketchSolverBridge.solveLineTransform(reopened, targets: targets))
        for index in edges.indices {
            guard case let .line(_, a, b) = moved[index],
                  case let .line(_, c, d) = (index == 0 ? targets[0] : edges[index]) else {
                return XCTFail("Expected line")
            }
            XCTAssertLessThan(simd_distance(a, c), 1e-3)
            XCTAssertLessThan(simd_distance(b, d), 1e-3)
        }
        vm.session.undo()
        XCTAssertEqual(vm.activeSketch, original)
        XCTAssertNotNil(vm.rectangleHandleGeometry)
        vm.session.redo()
        XCTAssertEqual(vm.activeSketch, detached)
        XCTAssertNil(vm.rectangleHandleGeometry)
    }

    func testDisconnectProximityAndExplicitReconnectAndLegacyDecode() throws {
        let vm = try makeViewModel()
        let a = line(SIMD2(0, 0), SIMD2(10, 0))
        let b = line(SIMD2(10, 0), SIMD2(10, 5))
        let sketch = openSketch(vm, entities: [a, b])
        vm.mode = .sketching(sketch.id, tool: nil)
        vm.selectedSketchPoints = [.init(entityID: a.id, role: .endpointB)]
        XCTAssertTrue(vm.canDisconnectSketchSelection)
        vm.disconnectSketchSelection()
        var detached = try XCTUnwrap(vm.activeSketch)
        XCTAssertEqual(detached.disconnectedEndpoints, [.init(entityID: a.id, role: .endpointB)])
        XCTAssertEqual(SketchSolverBridge.solve(detached, movingEntity: nil, dragTarget: nil).dof, 8)
        detached.constraints.append(.init(kind: .coincident, refs: [
            .init(entityID: a.id, role: .endpointB), .init(entityID: b.id, role: .endpointA)]))
        XCTAssertEqual(SketchSolverBridge.solve(detached, movingEntity: nil, dragTarget: nil).dof, 6,
                       "Explicit reconnection must override the proximity exclusion")
        var json = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(sketch)) as? [String: Any])
        json.removeValue(forKey: "disconnectedEndpoints")
        let legacy = try JSONDecoder().decode(Sketch.self, from: JSONSerialization.data(withJSONObject: json))
        XCTAssertTrue(legacy.disconnectedEndpoints.isEmpty)
        XCTAssertEqual(SketchSolverBridge.solve(legacy, movingEntity: nil, dragTarget: nil).dof, 6)

        var document = DesignDocument()
        document.sketches = [detached]
        let deletion = RemoveSketchEntitiesCommand(ids: [a.id], sketch: detached)
        deletion.apply(to: &document)
        XCTAssertTrue(document.sketches[0].validateConstraintRefs())
        XCTAssertTrue(document.sketches[0].disconnectedEndpoints.isEmpty)
        deletion.revert(in: &document)
        XCTAssertEqual(document.sketches[0], detached)
        let fragment = line(SIMD2(5, 0), SIMD2(10, 0))
        let trim = TrimCommand(sketch: detached, index: 0, removed: a, fragments: [fragment])
        trim.apply(to: &document)
        XCTAssertEqual(document.sketches[0].disconnectedEndpoints,
                       [.init(entityID: fragment.id, role: .endpointB)])
        XCTAssertTrue(document.sketches[0].validateConstraintRefs())
        trim.revert(in: &document)
        XCTAssertEqual(document.sketches[0], detached)
    }

    func testDisconnectCoversMidpointNonLineAndPrimitiveConnectionsWithoutDataLoss() throws {
        // Midpoint is a connection relationship, but Equal Length is not.
        let midpointVM = try makeViewModel()
        let target = line(SIMD2(0, 0), SIMD2(10, 0))
        let source = line(SIMD2(5, 0), SIMD2(5, 4))
        let midpoint = SketchConstraint(kind: .midpoint, refs: [
            .init(entityID: source.id, role: .endpointA),
            .init(entityID: target.id, role: .whole),
        ])
        let unrelated = SketchConstraint(kind: .equalLength, refs: [
            .init(entityID: source.id, role: .whole),
            .init(entityID: target.id, role: .whole),
        ])
        let midpointSketch = Sketch(plane: .ground, entities: [target, source],
            constraints: [midpoint, unrelated])
        midpointVM.session.perform(AddSketchCommand(sketch: midpointSketch))
        midpointVM.mode = .sketching(midpointSketch.id, tool: nil)
        midpointVM.selectedSketchPoints = [.init(entityID: source.id, role: .endpointA)]
        XCTAssertTrue(midpointVM.canDisconnectSketchSelection)
        midpointVM.disconnectSketchSelection()
        let midpointDetached = try XCTUnwrap(midpointVM.activeSketch)
        XCTAssertEqual(midpointDetached.entities, midpointSketch.entities)
        XCTAssertFalse(midpointDetached.constraints.contains(midpoint))
        XCTAssertTrue(midpointDetached.constraints.contains(unrelated))
        midpointVM.undo()
        XCTAssertEqual(midpointVM.activeSketch, midpointSketch)
        midpointVM.redo()
        XCTAssertEqual(midpointVM.activeSketch, midpointDetached)

        // Non-line centers can be explicitly coincident without being subject
        // to the solver's endpoint-proximity welding.
        let centerVM = try makeViewModel()
        let circle = SketchEntity.circle(id: UUID(), center: SIMD2(0, 0), radius: 3)
        let endpoint = line(SIMD2(0, 0), SIMD2(4, 0))
        let joined = SketchConstraint(kind: .coincident, refs: [
            .init(entityID: circle.id, role: .center),
            .init(entityID: endpoint.id, role: .endpointA),
        ])
        let radius = SketchDimension(kind: .radius,
            refs: [.init(entityID: circle.id, role: .whole)], value: 3)
        let centerSketch = Sketch(plane: .ground, entities: [circle, endpoint],
            constraints: [joined], dimensions: [radius])
        centerVM.session.perform(AddSketchCommand(sketch: centerSketch))
        centerVM.mode = .sketching(centerSketch.id, tool: nil)
        centerVM.selectedSketchPoints = [.init(entityID: circle.id, role: .center)]
        XCTAssertTrue(centerVM.canDisconnectSketchSelection)
        centerVM.disconnectSketchSelection()
        let centerDetached = try XCTUnwrap(centerVM.activeSketch)
        XCTAssertEqual(centerDetached.entities, centerSketch.entities)
        XCTAssertTrue(centerDetached.constraints.isEmpty)
        XCTAssertEqual(centerDetached.dimensions, [radius])
        XCTAssertTrue(centerDetached.disconnectedEndpoints.isEmpty,
                      "Non-proximity center connections need no exclusion marker")
        centerVM.undo()
        XCTAssertEqual(centerVM.activeSketch, centerSketch)

        // A primitive rectangle stays one entity. Disconnecting an addressable
        // diagonal corner removes only its external joint and preserves sizing.
        let rectVM = try makeViewModel()
        let rect = SketchEntity.rect(id: UUID(), min: SIMD2(0, 0), max: SIMD2(8, 6))
        let neighbour = line(SIMD2(0, 0), SIMD2(-3, -2))
        let rectJoint = SketchConstraint(kind: .coincident, refs: [
            .init(entityID: rect.id, role: .endpointA),
            .init(entityID: neighbour.id, role: .endpointA),
        ])
        let width = SketchDimension(kind: .horizontal, refs: [
            .init(entityID: rect.id, role: .endpointA),
            .init(entityID: rect.id, role: .endpointB),
        ], value: 8)
        let rectSketch = Sketch(plane: .ground, entities: [rect, neighbour],
            constraints: [rectJoint], dimensions: [width])
        rectVM.session.perform(AddSketchCommand(sketch: rectSketch))
        rectVM.mode = .sketching(rectSketch.id, tool: nil)
        rectVM.selectedSketchPoints = [.init(entityID: rect.id, role: .endpointA)]
        XCTAssertTrue(rectVM.canDisconnectSketchSelection)
        rectVM.disconnectSketchSelection()
        let rectDetached = try XCTUnwrap(rectVM.activeSketch)
        XCTAssertEqual(rectDetached.entities, rectSketch.entities)
        XCTAssertTrue(rectDetached.constraints.isEmpty)
        XCTAssertEqual(rectDetached.dimensions, [width])
        XCTAssertEqual(rectDetached.disconnectedEndpoints,
                       [.init(entityID: rect.id, role: .endpointA)])
        let reopened = try JSONDecoder().decode(Sketch.self,
            from: JSONEncoder().encode(rectDetached))
        XCTAssertEqual(reopened, rectDetached)
        rectVM.undo()
        XCTAssertEqual(rectVM.activeSketch, rectSketch)
        rectVM.redo()
        XCTAssertEqual(rectVM.activeSketch, rectDetached)
    }

    // MARK: - Adaptive enable/disable rules

    /// Spec §3.2 lists Parallel as taking "2+ lines". Three selected lines must
    /// therefore enable it and end up mutually parallel — stored as a pairwise
    /// chain, which is equivalent because parallelism is transitive.
    func testParallelAcceptsMoreThanTwoLines() throws {
        let vm = try makeViewModel()
        let l0 = line(SIMD2(0, 0), SIMD2(10, 0))          // horizontal
        let l1 = line(SIMD2(0, 5), SIMD2(10, 6))          // slightly tilted
        let l2 = line(SIMD2(0, 12), SIMD2(9, 14))         // more tilted
        _ = openSketch(vm, entities: [l0, l1, l2])

        vm.selectedSketchEntityIDs = [l0.id, l1.id, l2.id]
        XCTAssertTrue(vm.canApplyConstraint(.parallel),
                      "Parallel must enable for 2+ lines (spec §3.2)")
        // Perpendicular is NOT transitive — three mutually perpendicular lines
        // are impossible in 2D, so it stays a strict pair.
        XCTAssertFalse(vm.canApplyConstraint(.perpendicular),
                       "Perpendicular stays a strict two-line relation")

        vm.applyConstraint(.parallel)

        guard let a = currentLine(vm, id: l0.id),
              let b = currentLine(vm, id: l1.id),
              let c = currentLine(vm, id: l2.id) else {
            return XCTFail("lines missing after solve")
        }
        func angle(_ l: (a: SIMD2<Double>, b: SIMD2<Double>)) -> Double {
            let d = l.b - l.a
            return atan2(d.y, d.x).truncatingRemainder(dividingBy: .pi)
        }
        XCTAssertEqual(angle(a), angle(b), accuracy: 1e-3, "line 0 ∥ line 1")
        XCTAssertEqual(angle(b), angle(c), accuracy: 1e-3, "line 1 ∥ line 2")
    }

    func testAdaptiveEnablement() throws {
        let vm = try makeViewModel()
        let l0 = line(SIMD2(0, 0), SIMD2(10, 0))
        let l1 = line(SIMD2(0, 5), SIMD2(10, 6))
        let c0 = SketchEntity.circle(id: UUID(), center: SIMD2(0, 0), radius: 2)
        let c1 = SketchEntity.circle(id: UUID(), center: SIMD2(8, 0), radius: 3)
        _ = openSketch(vm, entities: [l0, l1, c0, c1])

        // Two lines: parallel/perpendicular/equalLength enabled; concentric not.
        vm.selectedSketchEntityIDs = [l0.id, l1.id]
        XCTAssertTrue(vm.canApplyConstraint(.parallel))
        XCTAssertTrue(vm.canApplyConstraint(.perpendicular))
        XCTAssertTrue(vm.canApplyConstraint(.equalLength))
        XCTAssertFalse(vm.canApplyConstraint(.concentric))
        XCTAssertFalse(vm.canApplyConstraint(.tangent))

        // Two circles: concentric/equalRadius enabled; parallel not.
        vm.selectedSketchEntityIDs = [c0.id, c1.id]
        XCTAssertTrue(vm.canApplyConstraint(.concentric))
        XCTAssertTrue(vm.canApplyConstraint(.equalRadius))
        XCTAssertFalse(vm.canApplyConstraint(.parallel))

        // Line + circle: tangent enabled.
        vm.selectedSketchEntityIDs = [l0.id, c0.id]
        XCTAssertTrue(vm.canApplyConstraint(.tangent))
        XCTAssertFalse(vm.canApplyConstraint(.parallel))

        // A point + a line: midpoint enabled, symmetric not (needs 2 points).
        vm.selectedSketchEntityIDs = [l1.id]
        vm.selectedSketchPoints = [.init(entityID: l0.id, role: .endpointA)]
        XCTAssertTrue(vm.canApplyConstraint(.midpoint))
        XCTAssertFalse(vm.canApplyConstraint(.symmetric))

        // Two points: coincident + horizontal/vertical enabled.
        vm.selectedSketchEntityIDs = []
        vm.selectedSketchPoints = [
            .init(entityID: l0.id, role: .endpointA),
            .init(entityID: l1.id, role: .endpointB),
        ]
        XCTAssertTrue(vm.canApplyConstraint(.coincident))
        XCTAssertTrue(vm.canApplyConstraint(.horizontal))
        XCTAssertTrue(vm.canApplyConstraint(.vertical))
    }

    func testFiniteConstraintTypeMatrixAppliesAndRestoresHistory() throws {
        struct Recipe {
            let kind: SketchConstraintKind
            let entities: [SketchEntity]
            let selectedIDs: [UUID]
            let points: [EditorViewModel.SketchPointSelection]
        }
        func l(_ a: SIMD2<Double>, _ b: SIMD2<Double>) -> SketchEntity {
            .line(id: UUID(), a: a, b: b)
        }
        func c(_ center: SIMD2<Double>, _ radius: Double) -> SketchEntity {
            .circle(id: UUID(), center: center, radius: radius)
        }

        let horizontal = l(.zero, SIMD2(10, 1))
        let vertical = l(.zero, SIMD2(1, 10))
        let parallelA = l(.zero, SIMD2(10, 0))
        let parallelB = l(SIMD2(0, 4), SIMD2(9, 5))
        let perpendicularA = l(.zero, SIMD2(10, 0))
        let perpendicularB = l(SIMD2(4, 2), SIMD2(5, 9))
        let coincidentA = l(.zero, SIMD2(4, 0))
        let coincidentB = l(SIMD2(5, 1), SIMD2(8, 1))
        let midpointSource = l(SIMD2(4, 3), SIMD2(4, 5))
        let midpointTarget = l(.zero, SIMD2(10, 0))
        let tangentLine = l(SIMD2(-5, 2), SIMD2(5, 2))
        let tangentCircle = c(.zero, 2)
        let concentricA = c(.zero, 2), concentricB = c(SIMD2(1, 1), 3)
        let equalLineA = l(.zero, SIMD2(10, 0)), equalLineB = l(SIMD2(0, 4), SIMD2(6, 4))
        let equalCircleA = c(.zero, 2), equalCircleB = c(SIMD2(8, 0), 3)
        let symmetricA = l(SIMD2(-2, 1), SIMD2(-2, 3))
        let symmetricB = l(SIMD2(2, 1), SIMD2(2, 3))
        let symmetricAxis = l(SIMD2(0, -5), SIMD2(0, 5))

        let recipes: [Recipe] = [
            .init(kind: .horizontal, entities: [horizontal], selectedIDs: [horizontal.id], points: []),
            .init(kind: .vertical, entities: [vertical], selectedIDs: [vertical.id], points: []),
            .init(kind: .parallel, entities: [parallelA, parallelB], selectedIDs: [parallelA.id, parallelB.id], points: []),
            .init(kind: .perpendicular, entities: [perpendicularA, perpendicularB], selectedIDs: [perpendicularA.id, perpendicularB.id], points: []),
            .init(kind: .coincident, entities: [coincidentA, coincidentB], selectedIDs: [], points: [
                .init(entityID: coincidentA.id, role: .endpointB), .init(entityID: coincidentB.id, role: .endpointA)]),
            .init(kind: .midpoint, entities: [midpointSource, midpointTarget], selectedIDs: [midpointTarget.id], points: [
                .init(entityID: midpointSource.id, role: .endpointA)]),
            .init(kind: .tangent, entities: [tangentLine, tangentCircle], selectedIDs: [tangentLine.id, tangentCircle.id], points: []),
            .init(kind: .concentric, entities: [concentricA, concentricB], selectedIDs: [concentricA.id, concentricB.id], points: []),
            .init(kind: .equalLength, entities: [equalLineA, equalLineB], selectedIDs: [equalLineA.id, equalLineB.id], points: []),
            .init(kind: .equalRadius, entities: [equalCircleA, equalCircleB], selectedIDs: [equalCircleA.id, equalCircleB.id], points: []),
            .init(kind: .symmetric, entities: [symmetricA, symmetricB, symmetricAxis], selectedIDs: [symmetricAxis.id], points: [
                .init(entityID: symmetricA.id, role: .endpointA), .init(entityID: symmetricB.id, role: .endpointA)]),
        ]

        for recipe in recipes {
            let vm = try makeViewModel()
            let original = openSketch(vm, entities: recipe.entities)
            vm.mode = .sketching(original.id, tool: nil)
            vm.selectedSketchEntityIDs = Set(recipe.selectedIDs)
            vm.selectedSketchPoints = Set(recipe.points)
            XCTAssertTrue(vm.canApplyConstraint(recipe.kind), "\(recipe.kind) should enable")
            vm.applyConstraint(recipe.kind)
            let constrained = try XCTUnwrap(vm.activeSketch)
            XCTAssertTrue(constrained.constraints.contains { $0.kind == recipe.kind })
            XCTAssertLessThanOrEqual(SketchSolverBridge.residualNorm(constrained),
                                     EditorViewModel.overConstraintTolerance)
            vm.undo()
            XCTAssertEqual(vm.activeSketch, original, "Undo restores \(recipe.kind)")
            vm.redo()
            XCTAssertEqual(vm.activeSketch, constrained, "Redo restores \(recipe.kind)")
            XCTAssertEqual(try JSONDecoder().decode(Sketch.self,
                from: JSONEncoder().encode(constrained)), constrained)
        }
    }

    func testTangentFreeCirclePreservesRadiusAndNearbyCenterWithHistory() throws {
        let prior = AppSettings.shared.anchoredSketchEntity
        AppSettings.shared.anchoredSketchEntity = .lastSelected
        defer { AppSettings.shared.anchoredSketchEntity = prior }
        for firstSelected in [false, true] {
            AppSettings.shared.anchoredSketchEntity = firstSelected ? .firstSelected : .lastSelected
            for slope in [0.0, 0.00000023841858, 0.4] {
                for side in [-1.0, 1.0] {
                    let vm = try makeViewModel()
                    let a = SIMD2<Double>(0.96910429, -3.99125981)
                    let b = a + SIMD2<Double>(0.74064648, slope)
                    let direction = simd_normalize(b - a)
                    let normal = SIMD2<Double>(-direction.y, direction.x) * side
                    let center = (a + b) / 2 + normal * 0.984
                    let radius = 0.37262403965
                    let circle = SketchEntity.circle(id: UUID(), center: center, radius: radius)
                    let target = line(a, b)
                    let original = openSketch(vm, entities: [circle, target])
                    vm.mode = .sketching(original.id, tool: nil)
                    vm.selectSketchEntitiesInOrder(firstSelected ? [target.id, circle.id] : [circle.id, target.id])
                    XCTAssertTrue(vm.canApplyConstraint(.tangent))
                    vm.applyConstraint(.tangent)
                    let result = try XCTUnwrap(vm.activeSketch)
                    guard case let .circle(_, c, r) = result.entities[0] else { return XCTFail("Circle missing") }
                    XCTAssertEqual(r, radius, accuracy: 1e-8)
                    XCTAssertLessThan(simd_distance(c, (a + b) / 2 + normal * radius), 1e-7)
                    XCTAssertEqual(result.entities[1], target)
                    XCTAssertEqual(result.constraints.map(\.kind), [.tangent])
                    XCTAssertEqual(result.dimensions, original.dimensions)
                    XCTAssertTrue(vm.selectedSketchEntityIDs.isEmpty)
                    vm.selectSketchEntitiesInOrder(firstSelected ? [target.id, circle.id] : [circle.id, target.id]); vm.undo()
                    XCTAssertEqual(vm.activeSketch, original)
                    XCTAssertTrue(vm.selectedSketchEntityIDs.isEmpty)
                    vm.selectSketchEntitiesInOrder(firstSelected ? [target.id, circle.id] : [circle.id, target.id]); vm.redo()
                    XCTAssertEqual(vm.activeSketch, result)
                    XCTAssertTrue(vm.selectedSketchEntityIDs.isEmpty)
                    XCTAssertEqual(try JSONDecoder().decode(Sketch.self, from: JSONEncoder().encode(result)), result)
                    XCTAssertLessThan(SketchSolverBridge.residualNorm(result), 1e-7)
                }
            }
        }
    }

    func testTangentLockedCirclePreservesFreeLineLengthEndpointAndHistory() throws {
        let prior = AppSettings.shared.anchoredSketchEntity
        AppSettings.shared.anchoredSketchEntity = .lastSelected
        defer { AppSettings.shared.anchoredSketchEntity = prior }
        for pinStart in [false, true] {
            for lineSelectedLast in [false, true] {
                let vm = try makeViewModel()
                let center = SIMD2<Double>(-0.5131351352, -2.514377594)
                let radius = 0.24733865261
                let circle = SketchEntity.circle(id: UUID(), center: center, radius: radius)
                let a = SIMD2<Double>(-0.7598895431, -3.1285703182)
                let b = SIMD2<Double>(-0.2655923963, -3.1285700798)
                let target = line(a, b)
                var original = Sketch(plane: .ground, entities: [circle, target], constraints: [
                    .init(kind: .fixed, refs: [.init(entityID: circle.id, role: .center)])
                ], dimensions: [SketchDimension(kind: .diameter,
                    refs: [.init(entityID: circle.id, role: .whole)], value: radius * 2)])
                if pinStart {
                    original.constraints.append(.init(kind: .fixed,
                        refs: [.init(entityID: target.id, role: .endpointA)]))
                }
                vm.session.perform(AddSketchCommand(sketch: original))
                vm.mode = .sketching(original.id, tool: nil)
                vm.selectSketchEntitiesInOrder(lineSelectedLast ? [circle.id, target.id] : [target.id, circle.id])
                vm.applyConstraint(.tangent)
                let result = try XCTUnwrap(vm.activeSketch)
                guard case let .line(_, movedA, movedB) = result.entities[1] else { return XCTFail("Line missing") }
                guard case let .circle(id, solvedCenter, solvedRadius) = result.entities[0] else {
                    return XCTFail("Circle missing")
                }
                XCTAssertEqual(id, circle.id)
                XCTAssertEqual(solvedCenter, center)
                XCTAssertEqual(solvedRadius, radius, accuracy: 1e-9)
                XCTAssertEqual(simd_length(movedB - movedA), simd_length(b - a), accuracy: 1e-7)
                if pinStart {
                    XCTAssertEqual(movedA, a, "Saved endpoint Lock overrides transient endpoint preference")
                } else {
                    XCTAssertLessThan(simd_distance(movedB, b), 1e-8)
                    XCTAssertLessThan(simd_distance(movedA, a), simd_length(b - a))
                }
                XCTAssertLessThan(SketchSolverBridge.residualNorm(result), 1e-7)
                XCTAssertEqual(result.constraints.map(\.kind), original.constraints.map(\.kind) + [.tangent])
                XCTAssertEqual(result.dimensions, original.dimensions)
                XCTAssertTrue(vm.selectedSketchEntityIDs.isEmpty)
                vm.undo(); XCTAssertEqual(vm.activeSketch, original)
                vm.redo(); XCTAssertEqual(vm.activeSketch, result)
                XCTAssertEqual(try JSONDecoder().decode(Sketch.self, from: JSONEncoder().encode(result)), result)
            }
        }
    }

    func testTangentSavedLocksOverridePreferenceAndRefusalRetainsSelection() throws {
        let prior = AppSettings.shared.anchoredSketchEntity
        AppSettings.shared.anchoredSketchEntity = .lastSelected
        defer { AppSettings.shared.anchoredSketchEntity = prior }
        for wholeCircleLocked in [false, true] {
            let vm = try makeViewModel()
            let circle = SketchEntity.circle(id: UUID(), center: SIMD2(0.5, 2), radius: 0.4)
            let target = line(.zero, SIMD2(1, 0))
            let original = Sketch(plane: .ground, entities: [circle, target], constraints: [
                .init(kind: .fixed, refs: [.init(entityID: circle.id, role: wholeCircleLocked ? .whole : .center)]),
                .init(kind: .fixed, refs: [.init(entityID: target.id, role: .whole)])
            ])
            vm.session.perform(AddSketchCommand(sketch: original))
            vm.mode = .sketching(original.id, tool: nil)
            vm.selectSketchEntitiesInOrder([circle.id, target.id])
            vm.applyConstraint(.tangent)
            if wholeCircleLocked {
                XCTAssertEqual(vm.activeSketch, original)
                XCTAssertNotNil(vm.errorMessage)
                XCTAssertEqual(vm.selectedSketchEntityIDs, [circle.id, target.id])
            } else {
                let result = try XCTUnwrap(vm.activeSketch)
                guard case let .circle(_, center, radius) = result.entities[0] else { return XCTFail("Circle missing") }
                XCTAssertEqual(center, SIMD2(0.5, 2))
                XCTAssertEqual(radius, 2, accuracy: 1e-7)
                XCTAssertEqual(result.entities[1], target)
                XCTAssertEqual(result.constraints.count, 3)
                XCTAssertTrue(result.dimensions.isEmpty)
                XCTAssertTrue(vm.selectedSketchEntityIDs.isEmpty)
                vm.undo(); XCTAssertEqual(vm.activeSketch, original)
                vm.redo(); XCTAssertEqual(vm.activeSketch, result)
            }
        }
    }

    func testCoincidentPointOnLineExtensionPreservesTargetAndHistory() throws {
        let prior = AppSettings.shared.anchoredSketchEntity
        AppSettings.shared.anchoredSketchEntity = .lastSelected
        defer { AppSettings.shared.anchoredSketchEntity = prior }
        let vm = try makeViewModel()
        let source = line(SIMD2(-1.5, -0.3), SIMD2(-0.5, -0.7))
        let target = line(.zero, SIMD2(1, 0))
        let original = openSketch(vm, entities: [source, target])
        vm.mode = .sketching(original.id, tool: nil)
        func selectOperands(_ model: EditorViewModel) {
            model.selectSketchEntitiesInOrder([])
            model.selectedSketchPoints = [.init(entityID: source.id, role: .endpointA)]
            model.selectedSketchEntityIDs = [target.id]
        }
        selectOperands(vm)
        XCTAssertTrue(vm.canApplyConstraint(.coincident))
        vm.applyConstraint(.coincident)
        let applied = try XCTUnwrap(vm.activeSketch)
        XCTAssertEqual(applied.constraints.map(\.kind), [.coincident])
        XCTAssertEqual(applied.constraints.first?.refs, [
            .init(entityID: source.id, role: .endpointA),
            .init(entityID: target.id, role: .whole)])
        XCTAssertEqual(applied.dimensions, original.dimensions)
        guard case let .line(_, point, end) = applied.entities[0],
              case let .line(_, a, b) = applied.entities[1] else {
            return XCTFail("Expected two lines")
        }
        XCTAssertEqual(point.x, -1.5, accuracy: 1e-8)
        XCTAssertEqual(point.y, 0, accuracy: 1e-8) // Infinite extension, not nearest endpoint.
        XCTAssertLessThan(simd_distance(end, SIMD2(-0.5, -0.7)), 1e-8)
        XCTAssertLessThan(simd_distance(a, .zero), 1e-8)
        XCTAssertLessThan(simd_distance(b, SIMD2(1, 0)), 1e-8)
        XCTAssertTrue(vm.selectedSketchEntityIDs.isEmpty)
        XCTAssertTrue(vm.selectedSketchPoints.isEmpty)
        selectOperands(vm); vm.undo()
        XCTAssertEqual(vm.activeSketch, original)
        XCTAssertTrue(vm.selectedSketchEntityIDs.isEmpty)
        XCTAssertTrue(vm.selectedSketchPoints.isEmpty)
        selectOperands(vm); vm.redo()
        XCTAssertEqual(vm.activeSketch, applied)
        XCTAssertTrue(vm.selectedSketchEntityIDs.isEmpty)
        XCTAssertTrue(vm.selectedSketchPoints.isEmpty)
        XCTAssertEqual(try JSONDecoder().decode(Sketch.self,
            from: JSONEncoder().encode(applied)), applied)

        let refused = try makeViewModel()
        let locked = Sketch(plane: .ground, entities: [source, target], constraints: [source, target].map {
            .init(kind: .fixed, refs: [.init(entityID: $0.id, role: .whole)])
        })
        refused.session.perform(AddSketchCommand(sketch: locked))
        refused.mode = .sketching(locked.id, tool: nil)
        selectOperands(refused); refused.applyConstraint(.coincident)
        XCTAssertEqual(refused.activeSketch, locked)
        XCTAssertEqual(refused.selectedSketchEntityIDs, [target.id])
        XCTAssertEqual(refused.selectedSketchPoints, [.init(entityID: source.id, role: .endpointA)])
        XCTAssertNotNil(refused.errorMessage)
        refused.selectedSketchEntityIDs = [source.id]
        XCTAssertFalse(refused.canApplyConstraint(.coincident), "A point on its own line is not a new relation")
    }

    func testMidpointFreeLineAnchorModesMatchPairedNativeGeometry() throws {
        let prior = AppSettings.shared.anchoredSketchEntity
        defer { AppSettings.shared.anchoredSketchEntity = prior }
        for first in [false, true] {
            AppSettings.shared.anchoredSketchEntity = first ? .firstSelected : .lastSelected
            let vm = try makeViewModel()
            let source = line(SIMD2(0, 1), SIMD2(0, 0.3))
            let target = line(.zero, SIMD2(1, 0))
            let original = openSketch(vm, entities: [source, target])
            vm.mode = .sketching(original.id, tool: nil)
            vm.selectSketchEntitiesInOrder([source.id, target.id])
            vm.selectedSketchPoints = [.init(entityID: source.id, role: .endpointB)]
            vm.selectedSketchEntityIDs = [target.id]
            XCTAssertTrue(vm.canApplyConstraint(.midpoint))
            vm.applyConstraint(.midpoint)
            let applied = try XCTUnwrap(vm.activeSketch)
            guard case let .line(_, sa, sb) = applied.entities[0],
                  case let .line(_, ta, tb) = applied.entities[1] else {
                return XCTFail("Expected source and target lines")
            }
            let expectedSA = first ? SIMD2(0.5, 0.7) : SIMD2(0, 1)
            let expectedSB = first ? SIMD2(0.5, 0) : SIMD2(0, 0)
            let expectedTA: SIMD2<Double> = first ? SIMD2(0, 0) : SIMD2(-1, 0)
            XCTAssertLessThan(simd_distance(sa, expectedSA), 1e-8)
            XCTAssertLessThan(simd_distance(sb, expectedSB), 1e-8)
            XCTAssertLessThan(simd_distance(ta, expectedTA), 1e-8)
            XCTAssertLessThan(simd_distance(tb, SIMD2(1, 0)), 1e-8)
            XCTAssertEqual(applied.constraints.map(\.kind), [.midpoint])
            XCTAssertEqual(applied.dimensions, original.dimensions)
            XCTAssertTrue(vm.selectedSketchPoints.isEmpty)
            XCTAssertTrue(vm.selectedSketchEntityIDs.isEmpty)
            vm.undo()
            XCTAssertEqual(vm.activeSketch, original)
            vm.redo()
            XCTAssertEqual(vm.activeSketch, applied)
            XCTAssertEqual(try JSONDecoder().decode(Sketch.self,
                from: JSONEncoder().encode(applied)), applied)
        }
    }

    func testMidpointPlacementPreferencesRespectLockedTargetAndDrivingLength() throws {
        let prior = AppSettings.shared.anchoredSketchEntity
        defer { AppSettings.shared.anchoredSketchEntity = prior }
        for first in [false, true] {
            AppSettings.shared.anchoredSketchEntity = first ? .firstSelected : .lastSelected
            let vm = try makeViewModel()
            let source = line(SIMD2(0, 1), SIMD2(0, 0.3))
            let target = line(.zero, SIMD2(1, 0))
            let lock = SketchConstraint(kind: .fixed, refs: [.init(entityID: target.id, role: .whole)])
            let dimension = SketchDimension(kind: .distance, refs: [
                .init(entityID: source.id, role: .endpointA),
                .init(entityID: source.id, role: .endpointB)
            ], value: 0.7)
            var original = Sketch(plane: .ground, entities: [source, target], constraints: [lock])
            original.dimensions = [dimension]
            vm.session.perform(AddSketchCommand(sketch: original))
            vm.mode = .sketching(original.id, tool: nil)
            vm.selectSketchEntitiesInOrder([source.id, target.id])
            vm.selectedSketchPoints = [.init(entityID: source.id, role: .endpointB)]
            vm.selectedSketchEntityIDs = [target.id]
            vm.applyConstraint(.midpoint)
            let applied = try XCTUnwrap(vm.activeSketch)
            XCTAssertNil(vm.errorMessage)
            XCTAssertEqual(applied.entities[1], target)
            XCTAssertEqual(applied.dimensions, [dimension])
            XCTAssertTrue(applied.constraints.contains(lock))
            XCTAssertEqual(applied.constraints.filter { $0.kind == .midpoint }.count, 1)
            guard case let .line(_, a, b) = applied.entities[0] else { return XCTFail("Expected source line") }
            XCTAssertEqual(simd_distance(a, b), 0.7, accuracy: 1e-8)
            XCTAssertLessThan(simd_distance(b, SIMD2(0.5, 0)), 1e-8)
            vm.undo()
            XCTAssertEqual(vm.activeSketch, original)
            vm.redo()
            XCTAssertEqual(vm.activeSketch, applied)
        }
    }

    func testMidpointClearsMixedSelectionOnSuccessAndHistoryButNotRefusal() throws {
        let prior = AppSettings.shared.anchoredSketchEntity
        AppSettings.shared.anchoredSketchEntity = .lastSelected
        defer { AppSettings.shared.anchoredSketchEntity = prior }
        let vm = try makeViewModel()
        let source = line(SIMD2(0, -0.5), SIMD2(0.5, -0.8))
        let target = line(.zero, SIMD2(1, 0))
        let original = openSketch(vm, entities: [source, target])
        vm.mode = .sketching(original.id, tool: nil)
        func selectOperands(_ model: EditorViewModel) {
            model.selectSketchEntitiesInOrder([])
            model.selectedSketchPoints = [.init(entityID: source.id, role: .endpointA)]
            model.selectedSketchEntityIDs = [target.id]
        }
        selectOperands(vm)
        vm.applyConstraint(.midpoint)
        let applied = try XCTUnwrap(vm.activeSketch)
        XCTAssertEqual(applied.constraints.map(\.kind), [.midpoint])
        XCTAssertEqual(applied.dimensions, original.dimensions)
        guard case let .line(_, point, _) = applied.entities[0],
              case let .line(_, a, b) = applied.entities[1] else {
            return XCTFail("Expected two lines")
        }
        XCTAssertLessThan(simd_distance(point, (a + b) / 2), 1e-8)
        XCTAssertTrue(vm.selectedSketchEntityIDs.isEmpty)
        XCTAssertTrue(vm.selectedSketchPoints.isEmpty)
        selectOperands(vm)
        vm.undo()
        XCTAssertEqual(vm.activeSketch, original)
        XCTAssertTrue(vm.selectedSketchEntityIDs.isEmpty)
        XCTAssertTrue(vm.selectedSketchPoints.isEmpty)
        selectOperands(vm)
        vm.redo()
        XCTAssertEqual(vm.activeSketch, applied)
        XCTAssertTrue(vm.selectedSketchEntityIDs.isEmpty)
        XCTAssertTrue(vm.selectedSketchPoints.isEmpty)
        XCTAssertEqual(try JSONDecoder().decode(Sketch.self,
            from: JSONEncoder().encode(applied)), applied)

        let refusedVM = try makeViewModel()
        let locked = Sketch(plane: .ground, entities: [source, target], constraints: [source, target].map {
            .init(kind: .fixed, refs: [.init(entityID: $0.id, role: .whole)])
        })
        refusedVM.session.perform(AddSketchCommand(sketch: locked))
        refusedVM.mode = .sketching(locked.id, tool: nil)
        selectOperands(refusedVM)
        refusedVM.applyConstraint(.midpoint)
        XCTAssertEqual(refusedVM.activeSketch, locked)
        XCTAssertEqual(refusedVM.selectedSketchEntityIDs, [target.id])
        XCTAssertEqual(refusedVM.selectedSketchPoints, [.init(entityID: source.id, role: .endpointA)])
        XCTAssertNotNil(refusedVM.errorMessage)
    }

    func testTwoCircleExternalTangentPreservesRadiiAndPreferredCenter() throws {
        let prior = AppSettings.shared.anchoredSketchEntity
        AppSettings.shared.anchoredSketchEntity = .lastSelected
        defer { AppSettings.shared.anchoredSketchEntity = prior }
        let vm = try makeViewModel()
        let a = SketchEntity.circle(id: UUID(), center: SIMD2(0, 0), radius: 0.4)
        let b = SketchEntity.circle(id: UUID(), center: SIMD2(1.6, -0.32), radius: 0.3)
        let original = openSketch(vm, entities: [a, b])
        vm.mode = .sketching(original.id, tool: nil)
        vm.selectSketchEntitiesInOrder([a.id, b.id])
        XCTAssertTrue(vm.canApplyConstraint(.tangent))
        vm.applyConstraint(.tangent)
        let applied = try XCTUnwrap(vm.activeSketch)
        XCTAssertTrue(applied.constraints.contains { $0.kind == .tangent })
        guard case let .circle(_, ca, ra) = applied.entities[0],
              case let .circle(_, cb, rb) = applied.entities[1] else {
            return XCTFail("Missing circles")
        }
        XCTAssertEqual(ra, 0.4, accuracy: 1e-8)
        XCTAssertEqual(rb, 0.3, accuracy: 1e-8)
        XCTAssertEqual(cb.x, 1.6, accuracy: 1e-8)
        XCTAssertEqual(cb.y, -0.32, accuracy: 1e-8)
        XCTAssertEqual(simd_length(cb - ca), ra + rb, accuracy: 1e-8)
        XCTAssertEqual(applied.dimensions, original.dimensions)
        XCTAssertTrue(vm.selectedSketchEntityIDs.isEmpty)
        XCTAssertEqual(try JSONDecoder().decode(Sketch.self, from: JSONEncoder().encode(applied)), applied)
        vm.undo()
        XCTAssertEqual(vm.activeSketch, original)
        vm.redo()
        XCTAssertEqual(vm.activeSketch, applied)
    }

    func testFreeArcCircleExternalTangentPreservesSweepRadiusAndHistory() throws {
        let prior = AppSettings.shared.anchoredSketchEntity
        AppSettings.shared.anchoredSketchEntity = .lastSelected
        defer { AppSettings.shared.anchoredSketchEntity = prior }
        let vm = try makeViewModel()
        let arc = SketchEntity.arc(id: UUID(), center: SIMD2(0, 0), radius: 1,
                                  startAngle: .pi, endAngle: 2 * .pi)
        let circle = SketchEntity.circle(id: UUID(), center: SIMD2(0, -2.2), radius: 0.5)
        let original = openSketch(vm, entities: [arc, circle])
        vm.mode = .sketching(original.id, tool: nil)
        vm.selectSketchEntitiesInOrder([arc.id, circle.id])
        XCTAssertTrue(vm.canApplyConstraint(.tangent))
        vm.applyConstraint(.tangent)
        let applied = try XCTUnwrap(vm.activeSketch)
        XCTAssertEqual(applied.constraints.first { $0.kind == .tangent }?.circleTangency, .externalContact)
        guard case let .arc(_, center, radius, start, end) = applied.entities[0] else {
            return XCTFail("Missing arc")
        }
        XCTAssertEqual(center.x, 0, accuracy: 1e-8)
        XCTAssertEqual(center.y, -0.7, accuracy: 1e-8)
        XCTAssertEqual(radius, 1, accuracy: 1e-8)
        XCTAssertEqual(start, .pi, accuracy: 1e-8)
        XCTAssertEqual(end, 2 * .pi, accuracy: 1e-8)
        XCTAssertEqual(applied.entities[1], circle)
        XCTAssertEqual(applied.dimensions, original.dimensions)
        XCTAssertTrue(vm.selectedSketchEntityIDs.isEmpty)
        XCTAssertLessThan(SketchSolverBridge.residualNorm(applied), 1e-8)
        XCTAssertEqual(try JSONDecoder().decode(Sketch.self, from: JSONEncoder().encode(applied)), applied)
        vm.undo(); XCTAssertEqual(vm.activeSketch, original)
        vm.redo(); XCTAssertEqual(vm.activeSketch, applied)
    }

    func testOffSpanArcCircleTangentUsesSupportingCircleAndGuide() throws {
        let prior = AppSettings.shared.anchoredSketchEntity
        let priorVisibility = AppSettings.shared.alwaysShowConstraints
        AppSettings.shared.anchoredSketchEntity = .lastSelected
        AppSettings.shared.alwaysShowConstraints = false
        defer {
            AppSettings.shared.anchoredSketchEntity = prior
            AppSettings.shared.alwaysShowConstraints = priorVisibility
        }
        let vm = try makeViewModel()
        let arc = SketchEntity.arc(id: UUID(), center: SIMD2(0, 0), radius: 1,
                                  startAngle: .pi, endAngle: 2 * .pi)
        let circle = SketchEntity.circle(id: UUID(), center: SIMD2(0, 2.2), radius: 0.5)
        let original = openSketch(vm, entities: [arc, circle])
        vm.mode = .sketching(original.id, tool: nil)
        vm.selectSketchEntitiesInOrder([arc.id, circle.id])
        XCTAssertTrue(vm.canApplyConstraint(.tangent))
        vm.applyConstraint(.tangent)
        let applied = try XCTUnwrap(vm.activeSketch)
        guard case let .arc(_, center, radius, start, end) = applied.entities[0] else {
            return XCTFail("Missing arc")
        }
        XCTAssertEqual(center.y, 0.7, accuracy: 1e-8)
        XCTAssertEqual(center.x, 0, accuracy: 1e-8)
        XCTAssertEqual(radius, 1, accuracy: 1e-8)
        XCTAssertEqual(start, .pi, accuracy: 1e-8)
        XCTAssertEqual(end, 2 * .pi, accuracy: 1e-8)
        XCTAssertEqual(applied.entities[1], circle)
        XCTAssertEqual(applied.constraints.last?.circleTangency, .externalContact)
        let guideColor = SIMD4<Float>(0.55, 0.30, 0.95, 1)
        XCTAssertFalse(vm.scene.sketchLines.contains { $0.color == guideColor })
        XCTAssertTrue(vm.selectedSketchEntityIDs.isEmpty)
        for id in [arc.id, circle.id] {
            vm.selectSketchEntitiesInOrder([id])
            XCTAssertTrue(vm.scene.sketchLines.contains { $0.color == guideColor && !$0.segments.isEmpty })
        }
        vm.selectedSketchEntityIDs.removeAll()
        XCTAssertFalse(vm.scene.sketchLines.contains { $0.color == guideColor })
        XCTAssertEqual(applied.dimensions, original.dimensions)
        XCTAssertEqual(try JSONDecoder().decode(Sketch.self, from: JSONEncoder().encode(applied)), applied)
        vm.undo(); XCTAssertEqual(vm.activeSketch, original)
        XCTAssertFalse(vm.scene.sketchLines.contains { $0.color == guideColor })
        vm.redo(); XCTAssertEqual(vm.activeSketch, applied)
        XCTAssertFalse(vm.scene.sketchLines.contains { $0.color == guideColor })
        vm.selectSketchEntitiesInOrder([arc.id])
        XCTAssertTrue(vm.scene.sketchLines.contains { $0.color == guideColor })
        vm.finishSketch()
        XCTAssertFalse(vm.scene.sketchLines.contains { $0.color == guideColor })
    }

    func testSmallerArcDeepCircleTangentUsesInternalContactAndOppositeGuide() throws {
        let prior = AppSettings.shared.anchoredSketchEntity
        let priorVisibility = AppSettings.shared.alwaysShowConstraints
        AppSettings.shared.anchoredSketchEntity = .lastSelected
        AppSettings.shared.alwaysShowConstraints = false
        defer {
            AppSettings.shared.anchoredSketchEntity = prior
            AppSettings.shared.alwaysShowConstraints = priorVisibility
        }
        let vm = try makeViewModel()
        let arc = SketchEntity.arc(id: UUID(), center: SIMD2(0, 0), radius: 0.5,
                                  startAngle: .pi, endAngle: 2 * .pi)
        let circle = SketchEntity.circle(id: UUID(), center: SIMD2(0, -0.625), radius: 1)
        let original = openSketch(vm, entities: [arc, circle])
        vm.mode = .sketching(original.id, tool: nil)
        vm.selectSketchEntitiesInOrder([arc.id, circle.id])
        XCTAssertTrue(vm.canApplyConstraint(.tangent))
        vm.applyConstraint(.tangent)
        let applied = try XCTUnwrap(vm.activeSketch)
        guard case let .arc(_, center, radius, start, end) = applied.entities[0] else {
            return XCTFail("Missing arc")
        }
        XCTAssertEqual(center.y, -0.125, accuracy: 1e-8)
        XCTAssertEqual(center.x, 0, accuracy: 1e-8)
        XCTAssertEqual(radius, 0.5, accuracy: 1e-8)
        XCTAssertEqual(start, .pi, accuracy: 1e-8)
        XCTAssertEqual(end, 2 * .pi, accuracy: 1e-8)
        XCTAssertEqual(applied.entities[1], circle)
        XCTAssertEqual(applied.constraints.last?.circleTangency, .internalContact)
        let guideColor = SIMD4<Float>(0.55, 0.30, 0.95, 1)
        XCTAssertFalse(vm.scene.sketchLines.contains { $0.color == guideColor })
        XCTAssertTrue(vm.selectedSketchEntityIDs.isEmpty)
        for id in [arc.id, circle.id] {
            vm.selectSketchEntitiesInOrder([id])
            XCTAssertTrue(vm.scene.sketchLines.contains { $0.color == guideColor && !$0.segments.isEmpty })
        }
        vm.selectedSketchEntityIDs.removeAll()
        XCTAssertFalse(vm.scene.sketchLines.contains { $0.color == guideColor })
        XCTAssertEqual(applied.dimensions, original.dimensions)
        XCTAssertEqual(try JSONDecoder().decode(Sketch.self, from: JSONEncoder().encode(applied)), applied)
        vm.undo(); XCTAssertEqual(vm.activeSketch, original)
        XCTAssertFalse(vm.scene.sketchLines.contains { $0.color == guideColor })
        vm.redo(); XCTAssertEqual(vm.activeSketch, applied)
        XCTAssertFalse(vm.scene.sketchLines.contains { $0.color == guideColor })
        vm.selectSketchEntitiesInOrder([arc.id])
        XCTAssertTrue(vm.scene.sketchLines.contains { $0.color == guideColor })
        vm.finishSketch()
        XCTAssertFalse(vm.scene.sketchLines.contains { $0.color == guideColor })
    }

    func testSmallerArcNestedCircleTangentUsesInternalContactAndOppositeGuide() throws {
        let prior = AppSettings.shared.anchoredSketchEntity
        let priorVisibility = AppSettings.shared.alwaysShowConstraints
        AppSettings.shared.anchoredSketchEntity = .lastSelected
        AppSettings.shared.alwaysShowConstraints = false
        defer {
            AppSettings.shared.anchoredSketchEntity = prior
            AppSettings.shared.alwaysShowConstraints = priorVisibility
        }
        let vm = try makeViewModel()
        let arc = SketchEntity.arc(id: UUID(), center: SIMD2(0, 0), radius: 0.5,
                                  startAngle: .pi, endAngle: 2 * .pi)
        let circle = SketchEntity.circle(id: UUID(), center: SIMD2(0, -0.25), radius: 1)
        let original = openSketch(vm, entities: [arc, circle])
        vm.mode = .sketching(original.id, tool: nil)
        vm.selectSketchEntitiesInOrder([arc.id, circle.id])
        XCTAssertTrue(vm.canApplyConstraint(.tangent))
        vm.applyConstraint(.tangent)
        let applied = try XCTUnwrap(vm.activeSketch)
        guard case let .arc(_, center, radius, start, end) = applied.entities[0] else {
            return XCTFail("Missing arc")
        }
        XCTAssertEqual(center.y, 0.25, accuracy: 1e-8)
        XCTAssertEqual(center.x, 0, accuracy: 1e-8)
        XCTAssertEqual(radius, 0.5, accuracy: 1e-8)
        XCTAssertEqual(start, .pi, accuracy: 1e-8)
        XCTAssertEqual(end, 2 * .pi, accuracy: 1e-8)
        XCTAssertEqual(applied.entities[1], circle)
        XCTAssertEqual(applied.constraints.last?.circleTangency, .internalContact)
        let guideColor = SIMD4<Float>(0.55, 0.30, 0.95, 1)
        XCTAssertFalse(vm.scene.sketchLines.contains { $0.color == guideColor })
        XCTAssertTrue(vm.selectedSketchEntityIDs.isEmpty)
        for id in [arc.id, circle.id] {
            vm.selectSketchEntitiesInOrder([id])
            XCTAssertTrue(vm.scene.sketchLines.contains { $0.color == guideColor && !$0.segments.isEmpty })
        }
        vm.selectedSketchEntityIDs.removeAll()
        XCTAssertFalse(vm.scene.sketchLines.contains { $0.color == guideColor })
        XCTAssertEqual(applied.dimensions, original.dimensions)
        XCTAssertEqual(try JSONDecoder().decode(Sketch.self, from: JSONEncoder().encode(applied)), applied)
        vm.undo(); XCTAssertEqual(vm.activeSketch, original)
        XCTAssertFalse(vm.scene.sketchLines.contains { $0.color == guideColor })
        vm.redo(); XCTAssertEqual(vm.activeSketch, applied)
        XCTAssertFalse(vm.scene.sketchLines.contains { $0.color == guideColor })
        vm.selectSketchEntitiesInOrder([arc.id])
        XCTAssertTrue(vm.scene.sketchLines.contains { $0.color == guideColor })
        vm.finishSketch()
        XCTAssertFalse(vm.scene.sketchLines.contains { $0.color == guideColor })
    }

    func testShallowOverlapArcCircleTangentPreservesGeometryAndHistory() throws {
        let prior = AppSettings.shared.anchoredSketchEntity
        AppSettings.shared.anchoredSketchEntity = .lastSelected
        defer { AppSettings.shared.anchoredSketchEntity = prior }
        let vm = try makeViewModel()
        let arc = SketchEntity.arc(id: UUID(), center: SIMD2(0, 0), radius: 1,
                                  startAngle: .pi, endAngle: 2 * .pi)
        let circle = SketchEntity.circle(id: UUID(), center: SIMD2(0, -1.4), radius: 0.5)
        let original = openSketch(vm, entities: [arc, circle])
        vm.mode = .sketching(original.id, tool: nil)
        vm.selectSketchEntitiesInOrder([arc.id, circle.id])
        XCTAssertTrue(vm.canApplyConstraint(.tangent))
        vm.applyConstraint(.tangent)
        let applied = try XCTUnwrap(vm.activeSketch)
        guard case let .arc(_, center, radius, start, end) = applied.entities[0] else {
            return XCTFail("Missing arc")
        }
        XCTAssertEqual(center.x, 0, accuracy: 1e-8)
        XCTAssertEqual(center.y, 0.1, accuracy: 1e-8)
        XCTAssertEqual(radius, 1, accuracy: 1e-8)
        XCTAssertEqual(start, .pi, accuracy: 1e-8)
        XCTAssertEqual(end, 2 * .pi, accuracy: 1e-8)
        XCTAssertEqual(applied.entities[1], circle)
        XCTAssertEqual(applied.constraints.last?.circleTangency, .externalContact)
        XCTAssertEqual(applied.dimensions, original.dimensions)
        XCTAssertTrue(vm.selectedSketchEntityIDs.isEmpty)
        XCTAssertEqual(try JSONDecoder().decode(Sketch.self, from: JSONEncoder().encode(applied)), applied)
        vm.undo(); XCTAssertEqual(vm.activeSketch, original)
        vm.redo(); XCTAssertEqual(vm.activeSketch, applied)
    }

    func testDeepOverlapArcCircleTangentUsesInternalContactAndHistory() throws {
        let prior = AppSettings.shared.anchoredSketchEntity
        AppSettings.shared.anchoredSketchEntity = .lastSelected
        defer { AppSettings.shared.anchoredSketchEntity = prior }
        let vm = try makeViewModel()
        let arc = SketchEntity.arc(id: UUID(), center: SIMD2(0, 0), radius: 1,
                                  startAngle: .pi, endAngle: 2 * .pi)
        let circle = SketchEntity.circle(id: UUID(), center: SIMD2(0, -0.625), radius: 0.5)
        let original = openSketch(vm, entities: [arc, circle])
        vm.mode = .sketching(original.id, tool: nil)
        vm.selectSketchEntitiesInOrder([arc.id, circle.id])
        XCTAssertTrue(vm.canApplyConstraint(.tangent))
        vm.applyConstraint(.tangent)
        let applied = try XCTUnwrap(vm.activeSketch)
        guard case let .arc(_, center, radius, start, end) = applied.entities[0] else {
            return XCTFail("Missing arc")
        }
        XCTAssertEqual(center.x, 0, accuracy: 1e-8)
        XCTAssertEqual(center.y, -0.125, accuracy: 1e-8)
        XCTAssertEqual(radius, 1, accuracy: 1e-8)
        XCTAssertEqual(start, .pi, accuracy: 1e-8)
        XCTAssertEqual(end, 2 * .pi, accuracy: 1e-8)
        XCTAssertEqual(applied.entities[1], circle)
        XCTAssertEqual(applied.constraints.last?.circleTangency, .internalContact)
        XCTAssertEqual(applied.dimensions, original.dimensions)
        XCTAssertTrue(vm.selectedSketchEntityIDs.isEmpty)
        XCTAssertEqual(try JSONDecoder().decode(Sketch.self, from: JSONEncoder().encode(applied)), applied)
        vm.undo(); XCTAssertEqual(vm.activeSketch, original)
        vm.redo(); XCTAssertEqual(vm.activeSketch, applied)
    }

    func testNestedArcCircleTangentUsesInternalContactAndHistory() throws {
        let prior = AppSettings.shared.anchoredSketchEntity
        AppSettings.shared.anchoredSketchEntity = .lastSelected
        defer { AppSettings.shared.anchoredSketchEntity = prior }
        let vm = try makeViewModel()
        let arc = SketchEntity.arc(id: UUID(), center: SIMD2(0, 0), radius: 1,
                                  startAngle: .pi, endAngle: 2 * .pi)
        let circle = SketchEntity.circle(id: UUID(), center: SIMD2(0, -0.25), radius: 0.5)
        let original = openSketch(vm, entities: [arc, circle])
        vm.mode = .sketching(original.id, tool: nil)
        vm.selectSketchEntitiesInOrder([arc.id, circle.id])
        XCTAssertTrue(vm.canApplyConstraint(.tangent))
        vm.applyConstraint(.tangent)
        let applied = try XCTUnwrap(vm.activeSketch)
        guard case let .arc(_, center, radius, start, end) = applied.entities[0] else {
            return XCTFail("Missing arc")
        }
        XCTAssertEqual(center.x, 0, accuracy: 1e-8)
        XCTAssertEqual(center.y, 0.25, accuracy: 1e-8)
        XCTAssertEqual(radius, 1, accuracy: 1e-8)
        XCTAssertEqual(start, .pi, accuracy: 1e-8)
        XCTAssertEqual(end, 2 * .pi, accuracy: 1e-8)
        XCTAssertEqual(applied.entities[1], circle)
        XCTAssertEqual(applied.constraints.last?.circleTangency, .internalContact)
        XCTAssertEqual(applied.dimensions, original.dimensions)
        XCTAssertTrue(vm.selectedSketchEntityIDs.isEmpty)
        XCTAssertEqual(try JSONDecoder().decode(Sketch.self, from: JSONEncoder().encode(applied)), applied)
        vm.undo(); XCTAssertEqual(vm.activeSketch, original)
        vm.redo(); XCTAssertEqual(vm.activeSketch, applied)
    }

    func testArcCircleTangentSpanBoundaryAndLockedRefusal() throws {
        let arc = SketchEntity.arc(id: UUID(), center: SIMD2(0, 0), radius: 1,
                                  startAngle: .pi, endAngle: 2 * .pi)
        for other in [
            SketchEntity.circle(id: UUID(), center: SIMD2(0, -0.5), radius: 0.5),
            .arc(id: UUID(), center: SIMD2(0, -2.2), radius: 0.5, startAngle: 0, endAngle: .pi)
        ] {
            let vm = try makeViewModel()
            let original = openSketch(vm, entities: [arc, other])
            vm.mode = .sketching(original.id, tool: nil)
            vm.selectSketchEntitiesInOrder([arc.id, other.id])
            XCTAssertFalse(vm.canApplyConstraint(.tangent))
            vm.applyConstraint(.tangent)
            XCTAssertEqual(vm.activeSketch, original)
        }
        let vm = try makeViewModel()
        let circle = SketchEntity.circle(id: UUID(), center: SIMD2(0, -2.2), radius: 0.5)
        var original = Sketch(plane: .ground, entities: [arc, circle])
        original.constraints = [arc, circle].map {
            .init(kind: .fixed, refs: [.init(entityID: $0.id, role: .whole)])
        }
        vm.session.perform(AddSketchCommand(sketch: original))
        vm.mode = .sketching(original.id, tool: nil)
        vm.selectSketchEntitiesInOrder([arc.id, circle.id])
        vm.applyConstraint(.tangent)
        XCTAssertEqual(vm.activeSketch, original)
        XCTAssertEqual(vm.selectedSketchEntityIDs, Set([arc.id, circle.id]))
    }

    func testAlreadyConcentricEqualCirclesAcceptTangentWithoutGeometryChange() throws {
        let vm = try makeViewModel()
        let a = SketchEntity.circle(id: UUID(), center: SIMD2(2, 3), radius: 1)
        let b = SketchEntity.circle(id: UUID(), center: SIMD2(2, 3), radius: 1)
        let concentric = SketchConstraint(kind: .concentric, refs: [
            .init(entityID: a.id, role: .whole), .init(entityID: b.id, role: .whole)])
        var original = Sketch(plane: .ground, entities: [a, b])
        original.constraints = [concentric]
        vm.session.perform(AddSketchCommand(sketch: original))
        vm.mode = .sketching(original.id, tool: nil)
        vm.selectSketchEntitiesInOrder([a.id, b.id])
        XCTAssertTrue(vm.canApplyConstraint(.tangent))
        vm.applyConstraint(.tangent)
        let applied = try XCTUnwrap(vm.activeSketch)
        XCTAssertEqual(applied.entities, original.entities)
        XCTAssertTrue(applied.constraints.contains(concentric))
        XCTAssertEqual(applied.constraints.count, 2)
        XCTAssertEqual(applied.constraints.first { $0.kind == .tangent }?.circleTangency, .internalContact)
        XCTAssertTrue(vm.selectedSketchEntityIDs.isEmpty)
        XCTAssertEqual(try JSONDecoder().decode(Sketch.self, from: JSONEncoder().encode(applied)), applied)
        XCTAssertLessThan(SketchSolverBridge.residualNorm(applied), 1e-8)
        vm.undo(); XCTAssertEqual(vm.activeSketch, original)
        vm.redo(); XCTAssertEqual(vm.activeSketch, applied)
    }

    func testEqualRadiusDeepOverlapTangentRetainsTwoCoincidentCircles() throws {
        let prior = AppSettings.shared.anchoredSketchEntity
        AppSettings.shared.anchoredSketchEntity = .lastSelected
        defer { AppSettings.shared.anchoredSketchEntity = prior }
        let vm = try makeViewModel()
        let a = SketchEntity.circle(id: UUID(), center: .zero, radius: 1)
        let b = SketchEntity.circle(id: UUID(), center: SIMD2(0.78, 0), radius: 1)
        let original = openSketch(vm, entities: [a, b])
        vm.mode = .sketching(original.id, tool: nil)
        vm.selectSketchEntitiesInOrder([a.id, b.id])
        XCTAssertTrue(vm.canApplyConstraint(.tangent))
        vm.applyConstraint(.tangent)
        let applied = try XCTUnwrap(vm.activeSketch)
        XCTAssertEqual(applied.entities.map(\.id), [a.id, b.id])
        XCTAssertEqual(applied.entities[1], b)
        XCTAssertEqual(applied.constraints.first { $0.kind == .tangent }?.circleTangency, .internalContact)
        guard case let .circle(_, ca, ra) = applied.entities[0],
              case let .circle(_, cb, rb) = applied.entities[1] else { return XCTFail("Missing circles") }
        XCTAssertEqual(ra, 1, accuracy: 1e-8)
        XCTAssertEqual(rb, 1, accuracy: 1e-8)
        XCTAssertEqual(simd_length(cb - ca), 0, accuracy: 1e-8)
        XCTAssertEqual(applied.dimensions, original.dimensions)
        XCTAssertTrue(vm.selectedSketchEntityIDs.isEmpty)
        XCTAssertEqual(try JSONDecoder().decode(Sketch.self, from: JSONEncoder().encode(applied)), applied)
        var repeated = applied
        for _ in 0..<3 { repeated.entities = SketchSolverBridge.solve(repeated, movingEntity: nil, dragTarget: nil).entities }
        XCTAssertLessThan(SketchSolverBridge.residualNorm(repeated), 1e-7)
        guard case let .circle(_, repeatedA, _) = repeated.entities[0],
              case let .circle(_, repeatedB, _) = repeated.entities[1] else { return XCTFail("Missing circles") }
        XCTAssertEqual(simd_length(repeatedB - repeatedA), 0, accuracy: 1e-8)
        vm.undo()
        XCTAssertEqual(vm.activeSketch, original)
        vm.redo()
        XCTAssertEqual(vm.activeSketch, applied)
    }

    func testIntersectingCircleTangentChoosesNearestContactAndRestoresHistory() throws {
        let prior = AppSettings.shared.anchoredSketchEntity
        defer { AppSettings.shared.anchoredSketchEntity = prior }
        for first in [false, true] {
            AppSettings.shared.anchoredSketchEntity = first ? .firstSelected : .lastSelected
            for distance in [0.6, 1.2] {
                for reversed in [false, true] {
                    let vm = try makeViewModel()
                    let entities: [SketchEntity] = [
                        .circle(id: UUID(), center: .zero, radius: 1),
                        .circle(id: UUID(), center: SIMD2(distance, 0), radius: 0.625)]
                    let original = openSketch(vm, entities: entities)
                    vm.mode = .sketching(original.id, tool: nil)
                    let ids = entities.map(\.id)
                    let order = reversed ? Array(ids.reversed()) : ids
                    vm.selectSketchEntitiesInOrder(order)
                    XCTAssertTrue(vm.canApplyConstraint(.tangent))
                    vm.applyConstraint(.tangent)
                    let applied = try XCTUnwrap(vm.activeSketch)
                    let internalContact = distance < 1
                    XCTAssertEqual(applied.constraints.first { $0.kind == .tangent }?.circleTangency,
                                   internalContact ? .internalContact : .externalContact)
                    guard case let .circle(_, a, ra) = applied.entities[0],
                          case let .circle(_, b, rb) = applied.entities[1] else { return XCTFail("Missing circles") }
                    XCTAssertEqual(ra, 1, accuracy: 1e-8)
                    XCTAssertEqual(rb, 0.625, accuracy: 1e-8)
                    XCTAssertEqual(simd_length(b - a), internalContact ? 0.375 : 1.625, accuracy: 1e-8)
                    let anchor = first ? order[0] : order[1]
                    XCTAssertEqual(applied.entities.first { $0.id == anchor }, entities.first { $0.id == anchor })
                    XCTAssertEqual(applied.dimensions, original.dimensions)
                    XCTAssertTrue(vm.selectedSketchEntityIDs.isEmpty)
                    XCTAssertEqual(try JSONDecoder().decode(Sketch.self, from: JSONEncoder().encode(applied)), applied)
                    var repeated = applied
                    for _ in 0..<3 { repeated.entities = SketchSolverBridge.solve(repeated, movingEntity: nil, dragTarget: nil).entities }
                    XCTAssertLessThan(SketchSolverBridge.residualNorm(repeated), 1e-7)
                    XCTAssertEqual(repeated.constraints, applied.constraints)
                    vm.undo()
                    XCTAssertEqual(vm.activeSketch, original)
                    vm.redo()
                    XCTAssertEqual(vm.activeSketch, applied)
                }
            }
        }
    }

    func testNestedCircleTangentPreservesInternalContactAndHistory() throws {
        let prior = AppSettings.shared.anchoredSketchEntity
        AppSettings.shared.anchoredSketchEntity = .lastSelected
        defer { AppSettings.shared.anchoredSketchEntity = prior }
        let vm = try makeViewModel()
        let a = SketchEntity.circle(id: UUID(), center: SIMD2(0, 0), radius: 1.0)
        let b = SketchEntity.circle(id: UUID(), center: SIMD2(0.2, -0.14), radius: 0.3)
        let original = openSketch(vm, entities: [a, b])
        vm.mode = .sketching(original.id, tool: nil)
        vm.selectSketchEntitiesInOrder([a.id, b.id])
        XCTAssertTrue(vm.canApplyConstraint(.tangent))
        vm.applyConstraint(.tangent)
        let applied = try XCTUnwrap(vm.activeSketch)
        XCTAssertEqual(applied.constraints.first { $0.kind == .tangent }?.circleTangency, .internalContact)
        guard case let .circle(_, ca, ra) = applied.entities[0],
              case let .circle(_, cb, rb) = applied.entities[1] else {
            return XCTFail("Missing circles")
        }
        XCTAssertEqual(ra, 1.0, accuracy: 1e-8)
        XCTAssertEqual(rb, 0.3, accuracy: 1e-8)
        XCTAssertEqual(cb.x, 0.2, accuracy: 1e-8)
        XCTAssertEqual(cb.y, -0.14, accuracy: 1e-8)
        XCTAssertEqual(simd_length(cb - ca), abs(ra - rb), accuracy: 1e-8)
        XCTAssertEqual(applied.dimensions, original.dimensions)
        XCTAssertTrue(vm.selectedSketchEntityIDs.isEmpty)
        XCTAssertEqual(try JSONDecoder().decode(Sketch.self, from: JSONEncoder().encode(applied)), applied)
        var repeated = applied
        for _ in 0..<3 { repeated.entities = SketchSolverBridge.solve(repeated, movingEntity: nil, dragTarget: nil).entities }
        XCTAssertLessThan(SketchSolverBridge.residualNorm(repeated), 1e-7)
        XCTAssertEqual(repeated.constraints, applied.constraints)
        vm.undo()
        XCTAssertEqual(vm.activeSketch, original)
        vm.redo()
        XCTAssertEqual(vm.activeSketch, applied)
    }

    func testTwoCircleExternalTangentAnchorOrdersAndLockedRefusal() throws {
        let prior = AppSettings.shared.anchoredSketchEntity
        defer { AppSettings.shared.anchoredSketchEntity = prior }
        for first in [true, false] {
            AppSettings.shared.anchoredSketchEntity = first ? .firstSelected : .lastSelected
            for reversed in [false, true] {
                let vm = try makeViewModel()
                let entities: [SketchEntity] = [
                    .circle(id: UUID(), center: SIMD2(-1, 0.3), radius: 0.4),
                    .circle(id: UUID(), center: SIMD2(0.6, -0.5), radius: 0.3)]
                let original = openSketch(vm, entities: entities)
                vm.mode = .sketching(original.id, tool: nil)
                let ids = entities.map(\.id)
                let order = reversed ? Array(ids.reversed()) : ids
                vm.selectSketchEntitiesInOrder(order)
                vm.applyConstraint(.tangent)
                XCTAssertNil(vm.errorMessage, "Unexpected refusal: \(vm.errorMessage ?? "none")")
                let applied = try XCTUnwrap(vm.activeSketch)
                let anchor = first ? order[0] : order[1]
                XCTAssertEqual(applied.entities.first { $0.id == anchor }, entities.first { $0.id == anchor })
                guard case let .circle(_, a, ra) = applied.entities[0],
                      case let .circle(_, b, rb) = applied.entities[1] else { return XCTFail("Missing circles") }
                XCTAssertEqual(ra, 0.4, accuracy: 1e-8)
                XCTAssertEqual(rb, 0.3, accuracy: 1e-8)
                XCTAssertEqual(simd_length(b - a), 0.7, accuracy: 1e-8)
                XCTAssertEqual(applied.constraints.filter { $0.kind == .tangent }.count, 1)
                XCTAssertEqual(applied.dimensions, original.dimensions)
                XCTAssertLessThan(SketchSolverBridge.residualNorm(applied), 1e-7)
            }
        }
        let vm = try makeViewModel()
        let entities: [SketchEntity] = [
            .circle(id: UUID(), center: .zero, radius: 0.4),
            .circle(id: UUID(), center: SIMD2(2, 0), radius: 0.3)]
        let locked = Sketch(plane: .ground, entities: entities, constraints: entities.map {
            .init(kind: .fixed, refs: [.init(entityID: $0.id, role: .whole)])
        })
        vm.session.perform(AddSketchCommand(sketch: locked))
        vm.mode = .sketching(locked.id, tool: nil)
        vm.selectSketchEntitiesInOrder(entities.map(\.id))
        vm.applyConstraint(.tangent)
        XCTAssertEqual(vm.activeSketch, locked)
        XCTAssertNotNil(vm.errorMessage)
        XCTAssertEqual(vm.selectedSketchEntityIDs, Set(entities.map(\.id)))
    }

    func testNestedCircleTangentAnchorOrdersAndLockedRefusal() throws {
        let prior = AppSettings.shared.anchoredSketchEntity
        defer { AppSettings.shared.anchoredSketchEntity = prior }
        for first in [true, false] {
            AppSettings.shared.anchoredSketchEntity = first ? .firstSelected : .lastSelected
            for reversed in [false, true] {
                let vm = try makeViewModel()
                let entities: [SketchEntity] = [
                    .circle(id: UUID(), center: SIMD2(0, 0), radius: 1.0),
                    .circle(id: UUID(), center: SIMD2(0.2, -0.14), radius: 0.3)]
                let original = openSketch(vm, entities: entities)
                vm.mode = .sketching(original.id, tool: nil)
                let ids = entities.map(\.id)
                let order = reversed ? Array(ids.reversed()) : ids
                vm.selectSketchEntitiesInOrder(order)
                vm.applyConstraint(.tangent)
                XCTAssertNil(vm.errorMessage, "Unexpected refusal: \(vm.errorMessage ?? "none")")
                let applied = try XCTUnwrap(vm.activeSketch)
                let anchor = first ? order[0] : order[1]
                XCTAssertEqual(applied.entities.first { $0.id == anchor }, entities.first { $0.id == anchor })
                guard case let .circle(_, a, ra) = applied.entities[0],
                      case let .circle(_, b, rb) = applied.entities[1] else { return XCTFail("Missing circles") }
                XCTAssertEqual(ra, 1.0, accuracy: 1e-8)
                XCTAssertEqual(rb, 0.3, accuracy: 1e-8)
                XCTAssertEqual(simd_length(b - a), 0.7, accuracy: 1e-8)
                XCTAssertEqual(applied.constraints.filter { $0.kind == .tangent }.count, 1)
                XCTAssertEqual(applied.dimensions, original.dimensions)
                XCTAssertLessThan(SketchSolverBridge.residualNorm(applied), 1e-7)
            }
        }
        let vm = try makeViewModel()
        let entities: [SketchEntity] = [
            .circle(id: UUID(), center: .zero, radius: 1.0),
            .circle(id: UUID(), center: SIMD2(0.2, -0.14), radius: 0.3)]
        let locked = Sketch(plane: .ground, entities: entities, constraints: entities.map {
            .init(kind: .fixed, refs: [.init(entityID: $0.id, role: .whole)])
        })
        vm.session.perform(AddSketchCommand(sketch: locked))
        vm.mode = .sketching(locked.id, tool: nil)
        vm.selectSketchEntitiesInOrder(entities.map(\.id))
        vm.applyConstraint(.tangent)
        XCTAssertEqual(vm.activeSketch, locked)
        XCTAssertNotNil(vm.errorMessage)
        XCTAssertEqual(vm.selectedSketchEntityIDs, Set(entities.map(\.id)))
    }

    func testConcentricPreservesRadiiAndClearsSelectionOnSuccessAndHistoryButNotRefusal() throws {
        let vm = try makeViewModel()
        let prior = AppSettings.shared.anchoredSketchEntity
        AppSettings.shared.anchoredSketchEntity = .lastSelected
        defer { AppSettings.shared.anchoredSketchEntity = prior }
        let entities: [SketchEntity] = [
            .circle(id: UUID(), center: SIMD2(0, 0), radius: 0.37),
            .circle(id: UUID(), center: SIMD2(2.4, -0.4), radius: 0.25)]
        let original = openSketch(vm, entities: entities)
        vm.mode = .sketching(original.id, tool: nil)
        vm.selectSketchEntitiesInOrder(entities.map(\.id))
        vm.selectedSketchPoints = [.init(entityID: entities[0].id, role: .center)]
        vm.applyConstraint(.concentric)
        let applied = try XCTUnwrap(vm.activeSketch)
        XCTAssertTrue(applied.constraints.contains { $0.kind == .concentric })
        guard case let .circle(_, center, radius) = applied.entities[0] else {
            return XCTFail("Circle missing")
        }
        XCTAssertEqual(center.x, 2.4, accuracy: 1e-8)
        XCTAssertEqual(center.y, -0.4, accuracy: 1e-8)
        XCTAssertEqual(radius, 0.37, accuracy: 1e-8)
        XCTAssertEqual(applied.entities[1], entities[1])
        XCTAssertEqual(applied.dimensions, original.dimensions)
        XCTAssertEqual(try JSONDecoder().decode(Sketch.self, from: JSONEncoder().encode(applied)), applied)
        XCTAssertTrue(vm.selectedSketchEntityIDs.isEmpty)
        XCTAssertTrue(vm.selectedSketchPoints.isEmpty)
        XCTAssertNil(vm.selectedConstraintID)
        XCTAssertNil(vm.selectedDimensionID)
        vm.selectSketchEntitiesInOrder([entities[0].id])
        vm.undo()
        XCTAssertEqual(vm.activeSketch, original)
        XCTAssertTrue(vm.selectedSketchEntityIDs.isEmpty)
        vm.selectSketchEntitiesInOrder([entities[1].id])
        vm.redo()
        XCTAssertEqual(vm.activeSketch, applied)
        XCTAssertTrue(vm.selectedSketchEntityIDs.isEmpty)

        let refusedVM = try makeViewModel()
        let locked = Sketch(plane: .ground, entities: entities, constraints: entities.map {
            .init(kind: .fixed, refs: [.init(entityID: $0.id, role: .whole)])
        })
        refusedVM.session.perform(AddSketchCommand(sketch: locked))
        refusedVM.mode = .sketching(locked.id, tool: nil)
        refusedVM.selectSketchEntitiesInOrder(entities.map(\.id))
        refusedVM.applyConstraint(.concentric)
        XCTAssertEqual(refusedVM.activeSketch, locked)
        XCTAssertEqual(refusedVM.selectedSketchEntityIDs, Set(entities.map(\.id)))
        XCTAssertNotNil(refusedVM.errorMessage)
    }

    func testPerpendicularClearsSelectionOnSuccessAndHistoryButNotRefusal() throws {
        let vm = try makeViewModel()
        let entities = [line(SIMD2(0, 0), SIMD2(0.9, -0.4)),
                        line(SIMD2(2.1, 0), SIMD2(2.9, -0.5))]
        let original = openSketch(vm, entities: entities)
        vm.mode = .sketching(original.id, tool: nil)
        vm.selectSketchEntitiesInOrder(entities.map(\.id))
        vm.selectedSketchPoints = [.init(entityID: entities[0].id, role: .endpointA)]
        vm.applyConstraint(.perpendicular)
        let applied = try XCTUnwrap(vm.activeSketch)
        XCTAssertTrue(applied.constraints.contains { $0.kind == .perpendicular })
        XCTAssertTrue(vm.selectedSketchEntityIDs.isEmpty)
        XCTAssertTrue(vm.selectedSketchPoints.isEmpty)
        XCTAssertNil(vm.selectedConstraintID)
        XCTAssertNil(vm.selectedDimensionID)
        vm.selectSketchEntitiesInOrder([entities[0].id])
        vm.undo()
        XCTAssertEqual(vm.activeSketch, original)
        XCTAssertTrue(vm.selectedSketchEntityIDs.isEmpty)
        vm.selectSketchEntitiesInOrder([entities[1].id])
        vm.redo()
        XCTAssertEqual(vm.activeSketch, applied)
        XCTAssertTrue(vm.selectedSketchEntityIDs.isEmpty)

        let refusedVM = try makeViewModel()
        let locked = Sketch(plane: .ground, entities: entities, constraints: entities.map {
            .init(kind: .fixed, refs: [.init(entityID: $0.id, role: .whole)])
        })
        refusedVM.session.perform(AddSketchCommand(sketch: locked))
        refusedVM.mode = .sketching(locked.id, tool: nil)
        refusedVM.selectSketchEntitiesInOrder(entities.map(\.id))
        refusedVM.applyConstraint(.perpendicular)
        XCTAssertEqual(refusedVM.activeSketch, locked)
        XCTAssertEqual(refusedVM.selectedSketchEntityIDs, Set(entities.map(\.id)))
        XCTAssertNotNil(refusedVM.errorMessage)
    }

    func testPerpendicularPreservesFreeLineLengthsAndHistory() throws {
        let prior = AppSettings.shared.anchoredSketchEntity
        defer { AppSettings.shared.anchoredSketchEntity = prior }
        for preference in [AnchoredSketchEntity.firstSelected, .lastSelected] {
            for order in [[0, 1], [1, 0]] {
                AppSettings.shared.anchoredSketchEntity = preference
                let vm = try makeViewModel()
                let entities = [line(SIMD2(0, 0), SIMD2(0.9, -0.4)),
                                line(SIMD2(2.1, 0), SIMD2(2.9, -0.5))]
                let original = openSketch(vm, entities: entities)
                vm.mode = .sketching(original.id, tool: nil)
                vm.selectSketchEntitiesInOrder(order.map { entities[$0].id })
                vm.applyConstraint(.perpendicular)
                let result = try XCTUnwrap(vm.activeSketch)
                XCTAssertEqual(result.constraints.map(\.kind), [.perpendicular])
                XCTAssertEqual(result.dimensions, original.dimensions)
                let anchor = preference == .firstSelected ? order[0] : order[1]
                XCTAssertEqual(result.entities[anchor], entities[anchor])
                var directions: [SIMD2<Double>] = []
                for (before, after) in zip(entities, result.entities) {
                    guard case let .line(_, a, b) = before,
                          case let .line(_, c, d) = after else { return XCTFail("Expected lines") }
                    XCTAssertEqual(simd_length(d - c), simd_length(b - a), accuracy: 1e-8)
                    directions.append(simd_normalize(d - c))
                }
                XCTAssertEqual(simd_dot(directions[0], directions[1]), 0, accuracy: 1e-8)
                vm.undo()
                XCTAssertEqual(vm.activeSketch, original)
                vm.redo()
                XCTAssertEqual(vm.activeSketch, result)
                XCTAssertEqual(try JSONDecoder().decode(Sketch.self,
                    from: JSONEncoder().encode(result)), result)
            }
        }
    }

    func testPerpendicularLengthPreferenceYieldsToSavedPointConstraints() throws {
        let prior = AppSettings.shared.anchoredSketchEntity
        AppSettings.shared.anchoredSketchEntity = .firstSelected
        defer { AppSettings.shared.anchoredSketchEntity = prior }
        let vm = try makeViewModel()
        let anchor = line(SIMD2(3, 2), SIMD2(5, 4))
        let moving = line(SIMD2(0, 0), SIMD2(2, 1))
        let guide = line(SIMD2(2, -10), SIMD2(2, 10))
        let original = Sketch(plane: .ground, entities: [anchor, moving, guide], constraints: [
            .init(kind: .fixed, refs: [.init(entityID: moving.id, role: .endpointA)]),
            .init(kind: .fixed, refs: [.init(entityID: guide.id, role: .whole)]),
            .init(kind: .coincident, refs: [.init(entityID: moving.id, role: .endpointB),
                                           .init(entityID: guide.id, role: .whole)]),
        ])
        vm.session.perform(AddSketchCommand(sketch: original))
        vm.mode = .sketching(original.id, tool: nil)
        vm.selectSketchEntitiesInOrder([anchor.id, moving.id])
        vm.applyConstraint(.perpendicular)
        let result = try XCTUnwrap(vm.activeSketch)
        XCTAssertEqual(result.entities[0], anchor)
        XCTAssertEqual(result.entities[2], guide)
        XCTAssertEqual(result.constraints.count, original.constraints.count + 1)
        XCTAssertEqual(result.dimensions, original.dimensions)
        guard case let .line(_, a, b) = result.entities[1] else { return XCTFail("Expected line") }
        XCTAssertEqual(a.x, 0, accuracy: 1e-8)
        XCTAssertEqual(a.y, 0, accuracy: 1e-8)
        XCTAssertEqual(b.x, 2, accuracy: 1e-8)
        XCTAssertEqual(b.y, -2, accuracy: 1e-8)
        XCTAssertLessThan(SketchSolverBridge.residualNorm(result), 1e-8)
        vm.undo()
        XCTAssertEqual(vm.activeSketch, original)
        vm.redo()
        XCTAssertEqual(vm.activeSketch, result)
    }

    func testEqualLengthPreservesFreeLineDirectionsAndHistory() throws {
        let prior = AppSettings.shared.anchoredSketchEntity
        defer { AppSettings.shared.anchoredSketchEntity = prior }
        for preference in [AnchoredSketchEntity.firstSelected, .lastSelected] {
            AppSettings.shared.anchoredSketchEntity = preference
            let vm = try makeViewModel()
            let entities = [line(SIMD2(0, 0), SIMD2(3.1, 0)),
                            line(SIMD2(0, -1.36), SIMD2(2.6, -1.86))]
            let original = openSketch(vm, entities: entities)
            vm.mode = .sketching(original.id, tool: nil)
            vm.selectSketchEntitiesInOrder([entities[1].id, entities[0].id])
            vm.applyConstraint(.equalLength)
            let result = try XCTUnwrap(vm.activeSketch)
            XCTAssertEqual(result.constraints.map(\.kind), [.equalLength])
            let anchor = preference == .firstSelected ? 1 : 0
            XCTAssertEqual(result.entities[anchor], entities[anchor])
            var lengths: [Double] = []
            for (before, after) in zip(entities, result.entities) {
                guard case let .line(_, a, b) = before,
                      case let .line(_, c, d) = after else { return XCTFail("Expected lines") }
                let initialDirection = simd_normalize(b - a)
                let finalDirection = simd_normalize(d - c)
                XCTAssertEqual(finalDirection.x, initialDirection.x, accuracy: 1e-8)
                XCTAssertEqual(finalDirection.y, initialDirection.y, accuracy: 1e-8)
                lengths.append(simd_length(d - c))
            }
            XCTAssertEqual(lengths[0], lengths[1], accuracy: 1e-8)
            vm.undo()
            XCTAssertEqual(vm.activeSketch, original)
            vm.redo()
            XCTAssertEqual(vm.activeSketch, result)
            XCTAssertEqual(try JSONDecoder().decode(Sketch.self,
                from: JSONEncoder().encode(result)), result)
        }
    }

    func testEqualLengthDirectionPreferenceYieldsToSavedPointConstraints() throws {
        let prior = AppSettings.shared.anchoredSketchEntity
        AppSettings.shared.anchoredSketchEntity = .firstSelected
        defer { AppSettings.shared.anchoredSketchEntity = prior }
        let vm = try makeViewModel()
        let anchor = line(SIMD2(0, 5), SIMD2(3.1, 5))
        let moving = line(SIMD2(0, 0), SIMD2(2, 1))
        let guide = line(SIMD2(2, -10), SIMD2(2, 10))
        let original = Sketch(plane: .ground, entities: [anchor, moving, guide], constraints: [
            .init(kind: .fixed, refs: [.init(entityID: moving.id, role: .endpointA)]),
            .init(kind: .fixed, refs: [.init(entityID: guide.id, role: .whole)]),
            .init(kind: .coincident, refs: [.init(entityID: moving.id, role: .endpointB),
                                           .init(entityID: guide.id, role: .whole)]),
        ])
        vm.session.perform(AddSketchCommand(sketch: original))
        vm.mode = .sketching(original.id, tool: nil)
        vm.selectSketchEntitiesInOrder([anchor.id, moving.id])
        vm.applyConstraint(.equalLength)
        let result = try XCTUnwrap(vm.activeSketch)
        XCTAssertEqual(result.entities[0], anchor)
        XCTAssertEqual(result.entities[2], guide)
        XCTAssertEqual(result.constraints.count, original.constraints.count + 1)
        guard case let .line(_, a, b) = result.entities[1] else { return XCTFail("Expected line") }
        XCTAssertEqual(a.x, 0, accuracy: 1e-8)
        XCTAssertEqual(a.y, 0, accuracy: 1e-8)
        XCTAssertEqual(b.x, 2, accuracy: 1e-8)
        XCTAssertEqual(simd_length(b - a), 3.1, accuracy: 1e-8)
        XCTAssertGreaterThan(b.y, 2, "Saved point constraints require direction to change")
        vm.undo()
        XCTAssertEqual(vm.activeSketch, original)
        vm.redo()
        XCTAssertEqual(vm.activeSketch, result)
    }

    func testAnchoredSketchEntityPreferenceUsesSelectionOrderAndExistingLocksWin() throws {
        let prior = AppSettings.shared.anchoredSketchEntity
        defer { AppSettings.shared.anchoredSketchEntity = prior }

        func verify(
            preference: AnchoredSketchEntity,
            order: [Int],
            anchoredIndex: Int,
            file: StaticString = #filePath, sourceLine: UInt = #line
        ) throws {
            let vm = try makeViewModel()
            let entities = [
                line(SIMD2(0, 0), SIMD2(10, 0)),
                line(SIMD2(0, 4), SIMD2(8, 6)),
            ]
            let original = openSketch(vm, entities: entities)
            vm.mode = .sketching(original.id, tool: nil)
            AppSettings.shared.anchoredSketchEntity = preference
            vm.selectSketchEntitiesInOrder(order.map { entities[$0].id })
            XCTAssertEqual(vm.selectedSketchEntityOrder, order.map { entities[$0].id },
                           file: file, line: sourceLine)
            vm.applyConstraint(.parallel)
            let constrained = try XCTUnwrap(vm.activeSketch, file: file, line: sourceLine)
            XCTAssertEqual(constrained.entities[anchoredIndex], entities[anchoredIndex],
                           "Preferred entity must remain exactly in place", file: file, line: sourceLine)
            XCTAssertNotEqual(constrained.entities[1 - anchoredIndex], entities[1 - anchoredIndex],
                              "The other entity should satisfy the relationship", file: file, line: sourceLine)
            XCTAssertLessThanOrEqual(SketchSolverBridge.residualNorm(constrained),
                                     EditorViewModel.overConstraintTolerance, file: file, line: sourceLine)
            let repeated = SketchSolverBridge.solve(
                constrained, movingEntity: nil, dragTarget: nil).0
            XCTAssertEqual(repeated, constrained.entities,
                           "A settled anchored solve must be stable", file: file, line: sourceLine)
            vm.undo()
            XCTAssertEqual(vm.activeSketch, original, file: file, line: sourceLine)
            vm.redo()
            XCTAssertEqual(vm.activeSketch, constrained, file: file, line: sourceLine)
        }

        try verify(preference: .firstSelected, order: [0, 1], anchoredIndex: 0)
        try verify(preference: .firstSelected, order: [1, 0], anchoredIndex: 1)
        try verify(preference: .lastSelected, order: [0, 1], anchoredIndex: 1)
        try verify(preference: .lastSelected, order: [1, 0], anchoredIndex: 0)

        // Existing relationships outrank the preference: the selected-first
        // line cannot also stay fixed when the selected-last line is already
        // explicitly locked at a different angle.
        let vm = try makeViewModel()
        let preferred = line(SIMD2(0, 0), SIMD2(10, 0))
        let locked = line(SIMD2(0, 4), SIMD2(8, 6))
        let original = Sketch(plane: .ground, entities: [preferred, locked],
            constraints: [.init(kind: .fixed,
                refs: [.init(entityID: locked.id, role: .whole)])])
        vm.session.perform(AddSketchCommand(sketch: original))
        vm.mode = .sketching(original.id, tool: nil)
        AppSettings.shared.anchoredSketchEntity = .firstSelected
        vm.selectSketchEntitiesInOrder([preferred.id, locked.id])
        vm.applyConstraint(.parallel)
        let constrained = try XCTUnwrap(vm.activeSketch)
        XCTAssertEqual(constrained.entities[1], locked, "Saved Lock must override the transient anchor")
        XCTAssertNotEqual(constrained.entities[0], preferred)
        XCTAssertLessThanOrEqual(SketchSolverBridge.residualNorm(constrained),
                                 EditorViewModel.overConstraintTolerance)
        vm.undo()
        XCTAssertEqual(vm.activeSketch, original)
        vm.redo()
        XCTAssertEqual(vm.activeSketch, constrained)
    }

    // MARK: - Point-role hit testing

    func testNearestPointReturnsRole() {
        let id = UUID()
        let entities: [SketchEntity] = [.line(id: id, a: SIMD2(0, 0), b: SIMD2(10, 0))]
        let hitA = SketchHitTester.nearestPoint(to: SIMD2(0.1, 0.1), in: entities, tolerance: 0.5)
        XCTAssertEqual(hitA?.role, .endpointA)
        XCTAssertEqual(hitA?.entityID, id)
        let hitB = SketchHitTester.nearestPoint(to: SIMD2(9.9, 0.05), in: entities, tolerance: 0.5)
        XCTAssertEqual(hitB?.role, .endpointB)
        // The middle of the line is not a model point.
        XCTAssertNil(SketchHitTester.nearestPoint(to: SIMD2(5, 0), in: entities, tolerance: 0.5))
    }
}
