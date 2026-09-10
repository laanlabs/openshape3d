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

    func testUnchangedExpressionAcceptPreservesGeometryAndUndoStep() throws {
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
