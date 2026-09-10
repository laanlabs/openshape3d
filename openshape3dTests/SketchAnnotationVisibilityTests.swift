//
//  SketchAnnotationVisibilityTests.swift
//  openshape3dTests
//
//  Dimensions used to be drawn only while sketching, and only for the sketch
//  being edited — so leaving a sketch hid the very values that define it, and a
//  second sketch's dimensions were never visible at all. `annotatedSketches`
//  now widens that to every visible sketch when "Always Show Dimensions" is on
//  (Shapr3D's "Constraint & Locked Dimension Visibility"). These tests pin both
//  halves, plus the unit-aware label text that replaced a hardcoded " mm".
//

import XCTest
import SwiftData
@testable import openshape3d

@MainActor
final class SketchAnnotationVisibilityTests: XCTestCase {
    /// `EditorViewModel` owns an `@Observable` whose isolated `deinit` crashes
    /// XCTest on dealloc (STATUS gotcha 1) — retain every one we make.
    nonisolated(unsafe) static var retained: [EditorViewModel] = []

    private var savedUnit: DisplayUnit!
    private var savedDimensions: Bool!
    private var savedConstraints: Bool!

    override func setUp() {
        super.setUp()
        // The getters read the shared settings singleton; restore it after each
        // test so these never leak into the rest of the suite.
        savedUnit = AppSettings.shared.unit
        savedDimensions = AppSettings.shared.alwaysShowDimensions
        savedConstraints = AppSettings.shared.alwaysShowConstraints
    }

    override func tearDown() {
        AppSettings.shared.unit = savedUnit
        AppSettings.shared.alwaysShowDimensions = savedDimensions
        AppSettings.shared.alwaysShowConstraints = savedConstraints
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
        let project = Project(name: "Annotation Visibility Test")
        context.insert(project)
        let vm = EditorViewModel(project: project, modelContext: context)
        Self.retained.append(vm)
        return vm
    }

    /// A horizontal line of `length` mm carrying a driving length dimension.
    private func dimensionedLine(length: Double, hidden: Bool = false) -> Sketch {
        let id = UUID()
        let line = SketchEntity.line(id: id, a: SIMD2(0, 0), b: SIMD2(length, 0))
        let dim = SketchDimension(
            kind: .distance,
            refs: [ConstraintRef(entityID: id, role: .endpointA),
                   ConstraintRef(entityID: id, role: .endpointB)],
            value: length)
        return Sketch(plane: .ground, entities: [line], isHidden: hidden,
                      dimensions: [dim])
    }

    // MARK: - The regression this change exists for

    func testDimensionsSurviveLeavingTheSketch() throws {
        let vm = try makeViewModel()
        let sketch = dimensionedLine(length: 40)
        vm.session.perform(AddSketchCommand(sketch: sketch))

        AppSettings.shared.alwaysShowDimensions = true
        vm.mode = .sketching(sketch.id, tool: nil)
        XCTAssertEqual(vm.sketchDimensionLabels.count, 1, "visible while sketching")

        vm.mode = .idle
        XCTAssertEqual(vm.sketchDimensionLabels.count, 1,
                       "a dimension must not vanish when the sketch is closed")
        XCTAssertEqual(vm.sketchDimensionLabels.first?.sketchID, sketch.id)
    }

    /// Off does not mean hidden. Shapr3D's own wording for the off-state is
    /// "shown based on your current selection", so a selected sketch still
    /// shows what defines it.
    func testOffMeansSelectionBasedNotHidden() throws {
        let vm = try makeViewModel()
        let sketch = dimensionedLine(length: 40)
        vm.session.perform(AddSketchCommand(sketch: sketch))
        AppSettings.shared.alwaysShowDimensions = false

        vm.mode = .idle
        XCTAssertTrue(vm.sketchDimensionLabels.isEmpty, "nothing selected, nothing drawn")

        vm.selectedSketchEntityIDs = [sketch.entities[0].id]
        XCTAssertEqual(vm.sketchDimensionLabels.count, 1,
                       "selecting the sketch shows what defines it")

        vm.selectedSketchEntityIDs = []
        XCTAssertTrue(vm.sketchDimensionLabels.isEmpty)

        vm.mode = .sketching(sketch.id, tool: nil)
        XCTAssertTrue(vm.sketchDimensionLabels.isEmpty, "active sketch still requires a selection")
    }

    // MARK: - Radius vs diameter (the app used to disagree with itself)

    /// A circle read Ø while you dragged it out (`LiveDimensionKit`) but its
    /// committed badge showed a bare, unprefixed radius. Both leaders are now
    /// on the badge, so "20 mm" is never ambiguous.
    func testRadiusAndDiameterBadgesCarryTheirLeader() throws {
        let vm = try makeViewModel()
        let id = UUID()
        let circle = SketchEntity.circle(id: id, center: SIMD2(0, 0), radius: 20)
        let ref = [ConstraintRef(entityID: id, role: .whole)]

        for (kind, expected) in [(DimensionKind.diameter, "Ø40 mm"),
                                 (DimensionKind.radius, "R20 mm")] {
            let sketch = Sketch(plane: .ground, entities: [circle],
                                dimensions: [SketchDimension(kind: kind, refs: ref,
                                                             value: kind == .diameter ? 40 : 20)])
            let vm2 = try makeViewModel()
            vm2.session.perform(AddSketchCommand(sketch: sketch))
            AppSettings.shared.alwaysShowDimensions = true
            AppSettings.shared.unit = .millimeters
            vm2.mode = .sketching(sketch.id, tool: nil)
            XCTAssertEqual(vm2.sketchDimensionLabels.first?.text, expected)
        }
        _ = vm
    }

    func testEveryVisibleSketchContributesNotJustTheActiveOne() throws {
        let vm = try makeViewModel()
        let a = dimensionedLine(length: 40)
        let b = dimensionedLine(length: 25)
        vm.session.perform(AddSketchCommand(sketch: a))
        vm.session.perform(AddSketchCommand(sketch: b))

        AppSettings.shared.alwaysShowDimensions = true
        vm.mode = .sketching(a.id, tool: nil)

        let owners = Set(vm.sketchDimensionLabels.map(\.sketchID))
        XCTAssertEqual(owners, [a.id, b.id],
                       "the other sketch's dimensions are visible too")
    }

    func testHiddenSketchesAreExcludedUnlessTheyAreTheActiveOne() throws {
        let vm = try makeViewModel()
        let shown = dimensionedLine(length: 40)
        let hidden = dimensionedLine(length: 25, hidden: true)
        vm.session.perform(AddSketchCommand(sketch: shown))
        vm.session.perform(AddSketchCommand(sketch: hidden))
        AppSettings.shared.alwaysShowDimensions = true

        vm.mode = .idle
        XCTAssertEqual(Set(vm.sketchDimensionLabels.map(\.sketchID)), [shown.id])

        // Editing a hidden sketch still renders it, so its own dimensions show.
        vm.mode = .sketching(hidden.id, tool: nil)
        XCTAssertEqual(Set(vm.sketchDimensionLabels.map(\.sketchID)),
                       [shown.id, hidden.id])
    }

    // MARK: - Constraint glyphs mirror dimensions

    func testConstraintGlyphsFollowTheirOwnSetting() throws {
        let vm = try makeViewModel()
        let id = UUID()
        let sketch = Sketch(
            plane: .ground,
            entities: [.line(id: id, a: SIMD2(0, 0), b: SIMD2(40, 0))],
            constraints: [SketchConstraint(
                kind: .horizontal,
                refs: [ConstraintRef(entityID: id, role: .whole)])])
        vm.session.perform(AddSketchCommand(sketch: sketch))
        vm.mode = .idle

        AppSettings.shared.alwaysShowConstraints = true
        XCTAssertEqual(vm.sketchConstraintGlyphs.count, 1)
        XCTAssertEqual(vm.sketchConstraintGlyphs.first?.sketchID, sketch.id)

        AppSettings.shared.alwaysShowConstraints = false
        XCTAssertTrue(vm.sketchConstraintGlyphs.isEmpty)
    }

    func testMigratedRectangleSingleEdgeKeepsBothSavedSizesWithoutDuplicates() throws {
        let vm = try makeViewModel(), id = UUID(), unrelated = UUID()
        var source = Sketch(plane: .ground, entities: [
            .rect(id: id, min: SIMD2(0, 0), max: SIMD2(4, 2))])
        source.rectangleSizingAnchors[id] = .center
        source.constraints = [.init(kind: .fixed, refs: [.init(entityID: id, role: .center)])]
        let refs: [ConstraintRef] = [.init(entityID: id, role: .endpointA), .init(entityID: id, role: .endpointB)]
        source.dimensions = [.init(kind: .horizontal, refs: refs, value: 4),
                             .init(kind: .vertical, refs: refs, value: 2)]
        var migrated = try XCTUnwrap(RectangleConstruction.prepareCenterRotation(
            source, id: id, edgeIDs: [id, UUID(), UUID(), UUID()]))
        migrated.entities.append(.line(id: unrelated, a: SIMD2(8, 0), b: SIMD2(10, 0)))
        vm.session.perform(AddSketchCommand(sketch: migrated))
        vm.mode = .sketching(migrated.id, tool: nil)
        AppSettings.shared.alwaysShowDimensions = false
        for edge in try XCTUnwrap(migrated.rotatedRectangleEdges[id]) {
            vm.selectedSketchEntityIDs = [edge]
            XCTAssertEqual(vm.sketchDimensionLabels.count, 2, "Every side must show exactly the two saved sizes")
            XCTAssertEqual(Set(vm.sketchDimensionLabels.compactMap(\.dimensionID)), Set(source.dimensions.map(\.id)))
            let group = try XCTUnwrap(migrated.rotatedRectangleEdges[id])
            let edgeIndex = try XCTUnwrap(group.firstIndex(of: edge))
            let selectedSize = try XCTUnwrap(vm.sketchDimensionLabels.first {
                $0.dimensionID == source.dimensions[edgeIndex % 2].id
            })
            guard case let .line(_, a, b)? = migrated.entities.first(where: { $0.id == edge }) else {
                return XCTFail("Expected rectangle side")
            }
            XCTAssertEqual(selectedSize.worldStart, migrated.plane.toWorld(a))
            XCTAssertEqual(selectedSize.worldEnd, migrated.plane.toWorld(b))
            XCTAssertEqual(selectedSize.refs, migrated.dimensions[edgeIndex % 2].refs,
                           "Presentation must not remap driving geometry")
            vm.beginDimensionEdit(selectedSize)
            XCTAssertEqual(vm.selectedSketchEntityIDs, [edge], "Editor must not jump to the opposite driving side")
            XCTAssertEqual(vm.editingDimension?.refs, selectedSize.refs)
            let editingLabel = try XCTUnwrap(vm.sketchDimensionLabels.first { $0.id == selectedSize.id })
            XCTAssertEqual(editingLabel.worldStart, selectedSize.worldStart)
            XCTAssertEqual(editingLabel.worldEnd, selectedSize.worldEnd)
            vm.cancelDimensionEdit()
            XCTAssertEqual(vm.selectedSketchEntityIDs, [edge])
            XCTAssertEqual(vm.activeSketch, migrated, "Opening/dismissing an editor must not mutate the sketch")
            let height = try XCTUnwrap(vm.sketchDimensionLabels.first { $0.dimensionID == source.dimensions[1].id })
            vm.beginDimensionEdit(height)
            XCTAssertEqual(vm.sketchDimensionLabels.count, 2)
            vm.commitDimensionEdit("1")
            XCTAssertEqual(vm.activeSketch?.dimensions.count, 2)
            XCTAssertEqual(vm.activeSketch?.dimensions.map(\.value), [4, 1])
            vm.session.undo()
            XCTAssertEqual(vm.activeSketch, migrated)
        }
        // A real geometry tap clears explicit dimension selection; changing
        // only entity IDs in this fixture must not simulate that incompletely.
        vm.selectedDimensionID = nil
        vm.cancelDimensionEdit()
        vm.selectedSketchEntityIDs = [unrelated]
        XCTAssertTrue(vm.sketchDimensionLabels.allSatisfy { $0.dimensionID == nil })
        vm.selectedSketchEntityIDs = []
        vm.selectedSketchPoints = [.init(entityID: id, role: .center)]
        XCTAssertFalse(vm.sketchDimensionLabels.contains { $0.dimensionID == source.dimensions[1].id },
                       "Center selection must not expand to the entire saved group")
        // A malformed/unsolved opposite edge must not silently replace the
        // driving reference's measurement merely because that edge is selected.
        var divergent = migrated
        let opposite = try XCTUnwrap(migrated.rotatedRectangleEdges[id])[2]
        let oppositeIndex = try XCTUnwrap(divergent.entities.firstIndex { $0.id == opposite })
        divergent.entities[oppositeIndex] = .line(id: opposite, a: SIMD2(6, 2), b: SIMD2(0, 2))
        vm.session.perform(ReplaceSketchGeometryCommand(title: "Unsolved fixture", before: migrated, after: divergent))
        vm.selectedSketchPoints = []
        vm.selectedSketchEntityIDs = [opposite]
        let drivingWidth = try XCTUnwrap(vm.sketchDimensionLabels.first { $0.dimensionID == source.dimensions[0].id })
        XCTAssertEqual(drivingWidth.displayValue, 4, "Selection must not replace driving-side measurement")
    }

    func testMigratedRectangleStructuralBadgesStayImplicitButAccessible() throws {
        let vm = try makeViewModel(), id = UUID(), outsideID = UUID()
        var source = Sketch(plane: .ground, entities: [
            .rect(id: id, min: SIMD2(0, 0), max: SIMD2(4, 2))])
        source.rectangleSizingAnchors[id] = .center
        source.constraints = [.init(kind: .fixed, refs: [.init(entityID: id, role: .center)])]
        var migrated = try XCTUnwrap(RectangleConstruction.prepareCenterRotation(
            source, id: id, edgeIDs: [id, UUID(), UUID(), UUID()]))
        let structural = Array(migrated.constraints.dropFirst())
        migrated.entities.append(.line(id: outsideID, a: SIMD2(5, 0), b: SIMD2(9, 0)))
        let external = SketchConstraint(kind: .parallel, refs: [
            .init(entityID: id, role: .whole), .init(entityID: outsideID, role: .whole)])
        migrated.constraints.append(external)
        vm.session.perform(AddSketchCommand(sketch: migrated))
        vm.mode = .sketching(migrated.id, tool: nil)
        vm.selectedSketchEntityIDs = Set(migrated.entities.map(\.id))
        for always in [false, true] {
            AppSettings.shared.alwaysShowConstraints = always
            XCTAssertEqual(Set(vm.sketchConstraintGlyphs.map(\.id)), [source.constraints[0].id, external.id])
            XCTAssertTrue(try XCTUnwrap(vm.sketchConstraintGlyphs.first {
                $0.id == source.constraints[0].id
            }).isRectangleCenterLock, "Use the existing selected-center control, not another generic padlock")
            for relation in structural {
                vm.selectedConstraintID = relation.id
                XCTAssertTrue(vm.sketchConstraintGlyphs.contains { $0.id == relation.id },
                              "Items selection must still expose the structural rule")
                vm.selectedConstraintID = nil
            }
        }
        vm.sketchConflictAttribution.constraintIDs = [structural[0].id]
        XCTAssertTrue(vm.sketchConstraintGlyphs.contains { $0.id == structural[0].id },
                      "A conflicting structural rule must remain visible for diagnosis")
        vm.sketchConflictAttribution = .init()
        XCTAssertEqual(vm.activeSketch, migrated, "Visibility must not change saved constraints or geometry")
        XCTAssertEqual(structural.count, 7)
        XCTAssertFalse(RectangleConstruction.isStructuralRelation(external, in: migrated))
        var ordinary = migrated
        ordinary.rotatedRectangleEdges = [:]
        XCTAssertFalse(RectangleConstruction.isStructuralRelation(structural[0], in: ordinary))
    }

    func testRectangleSideLockUsesContextualUnlockWithoutMidpointGlyph() throws {
        let vm = try makeViewModel()
        let id = UUID()
        let sketch = Sketch(plane: .ground, entities: [
            .rect(id: id, min: SIMD2(0, 0), max: SIMD2(10, 6))], constraints: [
                .init(kind: .fixed, refs: [.init(entityID: id, role: .whole, rectangleEdge: 0)])])
        vm.session.perform(AddSketchCommand(sketch: sketch))
        vm.mode = .sketching(sketch.id, tool: nil)
        vm.selectedSketchEntityIDs = [id]
        vm.selectedAxisRectangleEdge = (id, 0)
        for always in [false, true] {
            AppSettings.shared.alwaysShowConstraints = always
            XCTAssertTrue(vm.sketchConstraintGlyphs.isEmpty)
        }
        vm.toggleSketchSelectionLock()
        XCTAssertTrue(vm.activeSketch?.constraints.isEmpty == true,
                      "Hiding the badge must retain the contextual Unlock route")
        vm.session.undo()
        XCTAssertEqual(vm.activeSketch?.constraints, sketch.constraints)
    }

    // MARK: - Label text is unit-aware (was hardcoded "%.2f mm")

    func testLabelTextFollowsTheDisplayUnit() throws {
        let vm = try makeViewModel()
        let sketch = dimensionedLine(length: 25.4)
        vm.session.perform(AddSketchCommand(sketch: sketch))
        AppSettings.shared.alwaysShowDimensions = true
        vm.mode = .sketching(sketch.id, tool: nil)

        AppSettings.shared.unit = .millimeters
        XCTAssertEqual(vm.sketchDimensionLabels.first?.text, "25.4 mm")

        AppSettings.shared.unit = .inches
        XCTAssertEqual(vm.sketchDimensionLabels.first?.text, "1\"",
                       "25.4 mm is exactly one inch")
    }

    // MARK: - Defaults

    func testVisibilityDefaultsOnAndAnExplicitFalseSurvives() {
        let suite = "os3d.tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }

        // Both off out of the box, verified against the running Shapr3D:
        // annotations follow the selection rather than papering the canvas.
        XCTAssertFalse(AppSettings(defaults: defaults).alwaysShowDimensions)
        XCTAssertFalse(AppSettings(defaults: defaults).alwaysShowConstraints)

        let first = AppSettings(defaults: defaults)
        first.alwaysShowDimensions = true
        first.alwaysShowConstraints = true
        // `bool(forKey:)` cannot tell "false" from "never set" — this is the
        // regression that would silently re-enable it on the next launch.
        XCTAssertTrue(AppSettings(defaults: defaults).alwaysShowDimensions,
                      "an explicit choice survives — `bool(forKey:)` could not "
                      + "tell it from unset")
        XCTAssertTrue(AppSettings(defaults: defaults).alwaysShowConstraints)
    }

    // MARK: - A selected rectangle offers BOTH of its dimensions

    /// Shapr3D shows a rectangle's width AND height at once. openshape3d
    /// derives them as two candidates off one selection.
    func testSelectedRectangleOffersWidthAndHeight() throws {
        let vm = try makeViewModel()
        let id = UUID()
        let sketch = Sketch(plane: .ground,
                            entities: [.rect(id: id, min: SIMD2(0, 0), max: SIMD2(40, 25))])
        vm.session.perform(AddSketchCommand(sketch: sketch))
        AppSettings.shared.unit = .millimeters
        vm.mode = .sketching(sketch.id, tool: nil)
        vm.selectedSketchEntityIDs = [id]

        let labels = vm.sketchDimensionLabels
        XCTAssertEqual(labels.count, 2,
                       "width and height, got \(labels.map(\.text))")
        XCTAssertEqual(Set(labels.map(\.kind)), [.horizontal, .vertical])
        XCTAssertEqual(Set(labels.map(\.text)), ["40 mm", "25 mm"])
    }
}
