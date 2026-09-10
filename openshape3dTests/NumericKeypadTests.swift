//
//  NumericKeypadTests.swift
//  openshape3dTests
//
//  The keypad's text rules and the two behaviours behind its non-digit keys:
//  a unit suffix that actually converts, and the lock that decides whether a
//  typed value is recorded as a driving dimension.
//

import XCTest
import SwiftData
@testable import openshape3d

final class NumericKeypadTextTests: XCTestCase {

    func testTrailingUnitPrefersTheLongerToken() {
        // "mm" must never be read as a trailing "m", or 20 mm becomes 20 m.
        XCTAssertEqual(NumericKeypad.trailingUnit(in: "20 mm"), "mm")
        XCTAssertEqual(NumericKeypad.trailingUnit(in: "20 m"), "m")
        XCTAssertEqual(NumericKeypad.trailingUnit(in: "20 cm"), "cm")
        XCTAssertEqual(NumericKeypad.trailingUnit(in: "45 deg"), "deg")
        XCTAssertNil(NumericKeypad.trailingUnit(in: "20"))
        XCTAssertNil(NumericKeypad.trailingUnit(in: "25.4/2"))
    }

    func testLengthUnitMapping() {
        XCTAssertEqual(EditorViewModel.lengthUnit(forSuffix: "mm"), .millimeters)
        XCTAssertEqual(EditorViewModel.lengthUnit(forSuffix: "cm"), .centimeters)
        XCTAssertEqual(EditorViewModel.lengthUnit(forSuffix: "m"), .meters)
        // deg is an angle, not a length — it must not scale a distance.
        XCTAssertNil(EditorViewModel.lengthUnit(forSuffix: "deg"))
        XCTAssertNil(EditorViewModel.lengthUnit(forSuffix: nil))
    }

    /// The pad prints × ÷ − but the evaluator parses ASCII, so every operator
    /// the pad can produce has to survive a round trip.
    func testEveryOperatorThePadEmitsEvaluates() {
        XCTAssertEqual(ExpressionEvaluator.evaluate("6*7"), 42)
        XCTAssertEqual(ExpressionEvaluator.evaluate("84/2"), 42)
        XCTAssertEqual(ExpressionEvaluator.evaluate("50-8"), 42)
        XCTAssertEqual(ExpressionEvaluator.evaluate("40+2"), 42)
        XCTAssertEqual(ExpressionEvaluator.evaluate("(1+5)*7"), 42)
        XCTAssertEqual(ExpressionEvaluator.evaluate("-42"), -42)
        XCTAssertEqual(ExpressionEvaluator.evaluate("42 mm"), 42)
    }
}

@MainActor
final class DimensionKeypadCommitTests: XCTestCase {
    nonisolated(unsafe) static var retained: [EditorViewModel] = []

    private var savedUnit: DisplayUnit!

    override func setUp() {
        super.setUp()
        savedUnit = AppSettings.shared.unit
    }
    override func tearDown() {
        AppSettings.shared.unit = savedUnit
        super.tearDown()
    }

    private func makeViewModel() throws -> EditorViewModel {
        let schema = Schema([
            Project.self, PersistedBody.self, PersistedSketch.self,
            PersistedPlane.self, PersistedImage.self, PersistedSymbol.self,
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let context = ModelContext(container)
        let project = Project(name: "Keypad Commit Test")
        context.insert(project)
        let vm = EditorViewModel(project: project, modelContext: context)
        Self.retained.append(vm)
        return vm
    }

    /// A horizontal line, selected, with its length dimension open for edit.
    private func lineReadyToDimension(_ vm: EditorViewModel) -> (Sketch, UUID) {
        let id = UUID()
        let sketch = Sketch(plane: .ground,
                            entities: [.line(id: id, a: SIMD2(0, 0), b: SIMD2(40, 0))])
        vm.session.perform(AddSketchCommand(sketch: sketch))
        vm.mode = .sketching(sketch.id, tool: nil)
        vm.selectedSketchEntityIDs = [id]
        vm.beginDimensionForSelection()
        return (sketch, id)
    }

    private func length(_ vm: EditorViewModel, _ sketchID: SketchID) -> Double? {
        guard let s = vm.session.document.sketches.first(where: { $0.id == sketchID }),
              case let .line(_, a, b) = s.entities[0] else { return nil }
        return simd_distance(a, b)
    }

    func testScalarExpressionRetainsUnitsReopensAndClearsWithPlainValue() throws {
        let vm = try makeViewModel()
        AppSettings.shared.unit = .centimeters
        let (original, id) = lineReadyToDimension(vm)
        vm.commitDimensionEdit("10+5")
        let dimension = try XCTUnwrap(vm.activeSketch?.dimensions.first)
        XCTAssertEqual(dimension.value, 150, accuracy: 1e-6)
        XCTAssertEqual(dimension.displayExpression, "(10+5) cm")
        XCTAssertNil(dimension.formula, "Constant arithmetic must not become a variable-driven mm formula")
        XCTAssertTrue(try XCTUnwrap(vm.sketchDimensionLabels.first).hasExpression)
        let decoded = try JSONDecoder().decode(Sketch.self, from: JSONEncoder().encode(try XCTUnwrap(vm.activeSketch)))
        XCTAssertEqual(decoded.dimensions.first?.displayExpression, dimension.displayExpression)
        AppSettings.shared.unit = .inches
        vm.beginDimensionEdit(try XCTUnwrap(vm.sketchDimensionLabels.first))
        XCTAssertEqual(vm.editingDimension?.text, "(10+5) cm")
        vm.commitDimensionEdit(try XCTUnwrap(vm.editingDimension?.text))
        XCTAssertEqual(vm.activeSketch?.dimensions.first?.value, 150)
        XCTAssertEqual(vm.activeSketch?.dimensions.first?.displayExpression, "(10+5) cm")
        vm.beginDimensionEdit(try XCTUnwrap(vm.sketchDimensionLabels.first))
        AppSettings.shared.unit = .millimeters
        vm.commitDimensionEdit("2")
        XCTAssertNil(vm.activeSketch?.dimensions.first?.displayExpression)
        XCTAssertFalse(try XCTUnwrap(vm.sketchDimensionLabels.first).hasExpression)
        vm.session.undo()
        XCTAssertEqual(vm.activeSketch?.dimensions.first?.displayExpression, "(10+5) cm")
        vm.session.redo()
        XCTAssertEqual(try XCTUnwrap(length(vm, original.id)), 2, accuracy: 1e-6)
        vm.beginDimensionEdit(try XCTUnwrap(vm.sketchDimensionLabels.first))
        vm.commitDimensionEdit("= 1+2 cm")
        XCTAssertEqual(vm.activeSketch?.dimensions.first?.displayExpression, "(1+2) cm")
        vm.beginDimensionEdit(try XCTUnwrap(vm.sketchDimensionLabels.first))
        vm.commitDimensionEdit(try XCTUnwrap(vm.editingDimension?.text))
        XCTAssertEqual(try XCTUnwrap(length(vm, original.id)), 30, accuracy: 1e-6)
        let legacy = SketchDimension(kind: .distance, refs: [.init(entityID: id, role: .whole)], value: 4)
        let legacyRoundTrip = try JSONDecoder().decode(SketchDimension.self, from: JSONEncoder().encode(legacy))
        XCTAssertNil(legacyRoundTrip.displayExpression)
    }

    func testExplicitScalarUnitRetainsSourceAcrossReopenAndUnitChange() throws {
        let vm = try makeViewModel()
        AppSettings.shared.unit = .millimeters
        let (original, _) = lineReadyToDimension(vm)
        vm.commitDimensionEdit("0.1 cm")
        XCTAssertEqual(vm.activeSketch?.dimensions.first?.displayExpression, "0.1 cm")
        XCTAssertTrue(try XCTUnwrap(vm.sketchDimensionLabels.first).hasExpression)
        AppSettings.shared.unit = .inches
        vm.beginDimensionEdit(try XCTUnwrap(vm.sketchDimensionLabels.first))
        XCTAssertEqual(vm.editingDimension?.text, "0.1 cm")
        vm.commitDimensionEdit(try XCTUnwrap(vm.editingDimension?.text))
        XCTAssertEqual(try XCTUnwrap(length(vm, original.id)), 1, accuracy: 1e-6)
        vm.beginDimensionEdit(try XCTUnwrap(vm.sketchDimensionLabels.first))
        vm.commitDimensionEdit("1 mm")
        XCTAssertEqual(vm.activeSketch?.dimensions.first?.displayExpression, "1 mm")
        AppSettings.shared.unit = .millimeters
        vm.beginDimensionEdit(try XCTUnwrap(vm.sketchDimensionLabels.first))
        vm.commitDimensionEdit("2")
        XCTAssertNil(vm.activeSketch?.dimensions.first?.displayExpression)
        vm.session.undo()
        XCTAssertEqual(vm.activeSketch?.dimensions.first?.displayExpression, "1 mm")
    }

    func testMixedLengthSourceConversionRecoveryAndHistory() throws {
        let vm = try makeViewModel()
        AppSettings.shared.unit = .inches
        let (original, _) = lineReadyToDimension(vm)
        vm.commitDimensionEdit("0.1 cm + 0.2 mm")
        XCTAssertEqual(try XCTUnwrap(length(vm, original.id)), 1.2, accuracy: 1e-6)
        XCTAssertNil(vm.activeSketch?.dimensions.first?.formula)
        XCTAssertEqual(vm.activeSketch?.dimensions.first?.displayExpression, "0.1 cm + 0.2 mm")
        vm.beginDimensionEdit(try XCTUnwrap(vm.sketchDimensionLabels.first))
        vm.commitDimensionEdit("1 cm + 2 deg")
        XCTAssertNotNil(vm.editingDimension?.validationMessage)
        XCTAssertEqual(try XCTUnwrap(length(vm, original.id)), 1.2, accuracy: 1e-6)
        vm.commitDimensionEdit("1 cm - 2 mm")
        XCTAssertEqual(try XCTUnwrap(length(vm, original.id)), 8, accuracy: 1e-6)
        vm.session.undo()
        XCTAssertEqual(try XCTUnwrap(length(vm, original.id)), 1.2, accuracy: 1e-6)
        vm.beginDimensionEdit(try XCTUnwrap(vm.sketchDimensionLabels.first))
        XCTAssertEqual(vm.editingDimension?.text, "0.1 cm + 0.2 mm")
        vm.commitDimensionEdit(try XCTUnwrap(vm.editingDimension?.text))
        XCTAssertEqual(try XCTUnwrap(length(vm, original.id)), 1.2, accuracy: 1e-6)
    }

    func testPolygonCountEditsPreserveGeometryReferencesAndHistory() throws {
        let vm = try makeViewModel()
        AppSettings.shared.unit = .inches
        let id = UUID()
        let original = SketchEntity.polygon(id: id, center: SIMD2(7, -3), radius: 15,
                                           sides: 5, rotation: 0.4)
        let sketch = Sketch(plane: .ground, entities: [original])
        vm.session.perform(AddSketchCommand(sketch: sketch))
        vm.mode = .sketching(sketch.id, tool: nil)
        vm.selectedSketchEntityIDs = [id]
        func openCount() throws {
            vm.beginDimensionEdit(try XCTUnwrap(vm.sketchDimensionLabels.first { $0.isPolygonSideCount }))
        }
        try openCount()
        XCTAssertEqual(vm.editingDimension?.text, "5", "Count must not convert with display units")
        XCTAssertFalse(vm.canToggleDimensionLock("5"))
        vm.commitDimensionEdit("2")
        XCTAssertEqual(vm.activeSketch?.entities, [original])
        try openCount()
        vm.commitDimensionEdit("1/0")
        XCTAssertNotNil(vm.editingDimension?.validationMessage)
        vm.commitDimensionEdit("3.5")
        let triangle = SketchEntity.polygon(id: id, center: SIMD2(7, -3), radius: 15,
                                           sides: 3, rotation: 0.4)
        XCTAssertEqual(vm.activeSketch?.entities, [triangle])
        XCTAssertEqual(vm.activeSketch?.dimensions.count, 0, "Count is not a radius dimension")
        XCTAssertEqual(vm.polygonSides, 6, "Editing an existing polygon must not change future defaults")
        vm.session.undo()
        XCTAssertEqual(vm.activeSketch?.entities, [original])
        vm.session.redo()
        XCTAssertEqual(vm.activeSketch?.entities, [triangle])
        vm.selectedSketchEntityIDs = [id]
        try openCount()
        vm.commitDimensionEdit("65")
        guard case let .polygon(resultID, center, radius, sides, rotation)? = vm.activeSketch?.entities.first else {
            return XCTFail("Expected polygon")
        }
        XCTAssertEqual(resultID, id)
        XCTAssertEqual(center, SIMD2(7, -3))
        XCTAssertEqual(radius, 15)
        XCTAssertEqual(sides, 65)
        XCTAssertEqual(rotation, 0.4)
        try openCount()
        vm.commitDimensionEdit("10001")
        XCTAssertEqual(vm.activeSketch?.entities.first?.id, id)
        XCTAssertNil(vm.editingDimension)
        vm.session.undo()
        XCTAssertEqual(vm.activeSketch?.entities, [triangle], "Invalid counts add no history")
    }

    // MARK: Unit keys

    /// The evaluator DROPS a trailing unit before parsing, so without explicit
    /// handling "20 cm" meant "20 display units". The unit keys would have been
    /// decoration.
    func testATypedUnitBeatsTheDisplayUnit() throws {
        let vm = try makeViewModel()
        AppSettings.shared.unit = .millimeters
        let (sketch, _) = lineReadyToDimension(vm)

        vm.commitDimensionEdit("20 cm")
        XCTAssertEqual(try XCTUnwrap(length(vm, sketch.id)), 200, accuracy: 1e-6,
                       "20 cm is 200 mm, whatever the document is displaying")
    }

    func testWithoutASuffixTheDisplayUnitStillApplies() throws {
        let vm = try makeViewModel()
        AppSettings.shared.unit = .centimeters
        let (sketch, _) = lineReadyToDimension(vm)

        vm.commitDimensionEdit("20")
        XCTAssertEqual(try XCTUnwrap(length(vm, sketch.id)), 200, accuracy: 1e-6)
    }

    /// Invalid submissions must not become dimensions or consume history, and
    /// the next valid edit must remain usable after any rejected expression.
    func testInvalidLengthInputsPreserveGeometryAndAllowRecovery() throws {
        for raw in ["0", "-1", "", "1/0", "2+", "unknown_dimension"] {
            let vm = try makeViewModel()
            AppSettings.shared.unit = .millimeters
            let (sketch, id) = lineReadyToDimension(vm)
            let original = try XCTUnwrap(vm.activeSketch)
            vm.commitDimensionEdit(raw)
            XCTAssertNil(vm.errorMessage, "Numeric refusal must not block the canvas: \(raw)")
            if raw == "0" || raw == "-1" {
                XCTAssertNil(vm.editingDimension, raw)
                XCTAssertNotNil(vm.notice, raw)
            } else {
                XCTAssertNotNil(vm.editingDimension, "Malformed expressions stay editable: \(raw)")
                XCTAssertNotNil(vm.editingDimension?.validationMessage, raw)
                vm.updateDimensionDraft("25", sessionID: try XCTUnwrap(vm.editingDimension?.sessionID))
                XCTAssertNil(vm.editingDimension?.validationMessage, "Editing clears the stale warning")
            }
            XCTAssertEqual(vm.activeSketch?.entities, original.entities, raw)
            XCTAssertTrue(try XCTUnwrap(vm.activeSketch).dimensions.isEmpty, raw)
            if vm.editingDimension == nil {
                vm.selectedSketchEntityIDs = [id]
                vm.beginDimensionForSelection()
            }
            vm.commitDimensionEdit("25")
            XCTAssertNil(vm.errorMessage, raw)
            XCTAssertEqual(try XCTUnwrap(length(vm, sketch.id)), 25, accuracy: 1e-6)
            vm.session.undo()
            XCTAssertEqual(vm.activeSketch?.entities, original.entities, raw)
            vm.session.undo()
            XCTAssertFalse(vm.session.document.sketches.contains { $0.id == sketch.id },
                           "Rejected input must not insert a history step: \(raw)")
        }
    }

    // MARK: The lock key

    func testImmediateLockUnlockPreservesGeometryAndHistoryRejectsDraft() throws {
        let vm = try makeViewModel()
        AppSettings.shared.unit = .millimeters
        let (sketch, id) = lineReadyToDimension(vm)
        let geometry = vm.activeSketch!.entities
        let seed = try XCTUnwrap(vm.editingDimension?.text)
        XCTAssertTrue(vm.canToggleDimensionLock(seed))
        XCTAssertFalse(vm.canToggleDimensionLock("25"))
        vm.toggleDimensionLock("25")
        XCTAssertNotNil(vm.editingDimension)
        XCTAssertTrue(vm.activeSketch!.dimensions.isEmpty)
        vm.toggleDimensionLock(seed)
        XCTAssertNil(vm.editingDimension)
        XCTAssertTrue(vm.selectedSketchEntityIDs.isEmpty)
        let dimension = try XCTUnwrap(vm.activeSketch?.dimensions.first)
        XCTAssertEqual(dimension.value, 40)
        XCTAssertEqual(vm.activeSketch?.entities, geometry)
        vm.selectedSketchEntityIDs = [id]
        vm.beginDimensionEdit(try XCTUnwrap(vm.sketchDimensionLabels.first))
        vm.toggleDimensionLock(try XCTUnwrap(vm.editingDimension?.text))
        XCTAssertTrue(vm.activeSketch!.dimensions.isEmpty)
        XCTAssertEqual(vm.activeSketch?.entities, geometry)
        vm.session.undo()
        XCTAssertEqual(vm.activeSketch?.dimensions, [dimension])
        XCTAssertEqual(vm.activeSketch?.entities, geometry)
        vm.session.redo()
        XCTAssertTrue(vm.activeSketch!.dimensions.isEmpty)
        XCTAssertEqual(try XCTUnwrap(length(vm, sketch.id)), 40, accuracy: 1e-8)
    }

    func testLockedCommitRecordsADrivingDimension() throws {
        let vm = try makeViewModel()
        AppSettings.shared.unit = .millimeters
        let (sketch, _) = lineReadyToDimension(vm)
        vm.dimensionCommitLocked = true

        vm.commitDimensionEdit("20")
        let stored = vm.session.document.sketches.first { $0.id == sketch.id }
        XCTAssertEqual(stored?.dimensions.count, 1)
        XCTAssertEqual(try XCTUnwrap(length(vm, sketch.id)), 20, accuracy: 1e-6)
    }

    func testPaletteReopensStoredDimensionWithoutDuplicatingIt() throws {
        let vm = try makeViewModel()
        AppSettings.shared.unit = .millimeters
        let (sketch, id) = lineReadyToDimension(vm)
        vm.commitDimensionEdit("20")
        let stored = try XCTUnwrap(vm.activeSketch?.dimensions.first)
        vm.selectedSketchEntityIDs = [id]
        vm.beginDimensionForSelection()
        let edit = try XCTUnwrap(vm.editingDimension)
        XCTAssertEqual(edit.dimensionID, stored.id)
        XCTAssertTrue(vm.sketchDimensionLabels.contains { $0.id == edit.labelID },
                      "The editor must target a rendered label, not a suppressed candidate")
        vm.commitDimensionEdit("30")
        XCTAssertEqual(vm.activeSketch?.dimensions.count, 1)
        XCTAssertEqual(vm.activeSketch?.dimensions.first?.id, stored.id)
        XCTAssertEqual(try XCTUnwrap(length(vm, sketch.id)), 30, accuracy: 1e-6)
        vm.session.undo()
        XCTAssertEqual(try XCTUnwrap(length(vm, sketch.id)), 20, accuracy: 1e-6)
        vm.beginDimensionForSelection()
        vm.toggleDimensionLock(try XCTUnwrap(vm.editingDimension?.text))
        XCTAssertTrue(vm.activeSketch!.dimensions.isEmpty)
        XCTAssertEqual(try XCTUnwrap(length(vm, sketch.id)), 20, accuracy: 1e-6)
    }

    /// Unlocked, the value still drives the solve — the geometry lands exactly
    /// where it was asked to — it just is not written down as a constraint.
    func testUnlockedCommitResizesWithoutRecordingADimension() throws {
        let vm = try makeViewModel()
        AppSettings.shared.unit = .millimeters
        let (sketch, _) = lineReadyToDimension(vm)
        vm.dimensionCommitLocked = false

        vm.commitDimensionEdit("20")
        let stored = vm.session.document.sketches.first { $0.id == sketch.id }
        XCTAssertEqual(stored?.dimensions.count, 0,
                       "no driving dimension recorded")
        XCTAssertEqual(try XCTUnwrap(length(vm, sketch.id)), 20, accuracy: 1e-6,
                       "but the geometry still went where it was told")
    }

    func testEveryFreshEditStartsLocked() throws {
        let vm = try makeViewModel()
        let (_, _) = lineReadyToDimension(vm)
        vm.dimensionCommitLocked = false
        // Re-opening the field is a new decision; a sticky unlock would quietly
        // stop recording dimensions.
        vm.beginDimensionForSelection()
        XCTAssertTrue(vm.dimensionCommitLocked)
    }
}
