//
//  CommandAvailabilityTests.swift
//  openshape3dTests
//
//  Pins `CommandRegistry.unavailableReason(for:in:)` — the rule `runCommand`
//  applies before running a command, and the reason `/v1/commands?available=1`
//  and a refused `/v1/command` hand an agent. Pure values: no EditorViewModel.
//

import XCTest
@testable import openshape3d

final class CommandAvailabilityTests: XCTestCase {

    private func reason(_ id: String, _ context: CommandContext) -> String? {
        CommandRegistry.unavailableReason(for: id, in: context)
    }

    /// An editor where every rule is satisfied: a sketch open with entities
    /// selected, bodies selected, both undo directions, a section, a pair to
    /// compare, a visible profile, the pointer over a plane.
    private var everythingReady: CommandContext {
        var c = CommandContext()
        c.isSketching = true
        c.hasActiveSketch = true
        c.selectedSketchEntityCount = 2
        c.bodyCount = 2
        c.selectionCount = 1
        c.selectedBodyCount = 1
        c.hasModelSketchSelection = true
        c.canBeginPattern = true
        c.canUndo = true
        c.canRedo = true
        c.clipboard = .sketchEntities
        c.sectionActive = true
        c.hasDeviationPair = true
        c.sketchCount = 1
        c.visibleSketchCount = 1
        c.hasExtrudableProfile = true
        return c
    }

    func testNothingIsRefusedWhenEveryConditionHolds() {
        var ready = everythingReady
        for command in CommandRegistry.launchableCommands where command.id != "sketch.onHoveredPlane" {
            XCTAssertNil(reason(command.id, ready), command.id)
        }
        // Sketching on the hovered plane is the one command that wants NO open sketch.
        ready.isSketching = false
        ready.hasHoverRay = true
        XCTAssertNil(reason("sketch.onHoveredPlane", ready))
    }

    /// A fresh, empty design: which commands an agent can run before it has
    /// built anything. Adding a command makes this list a decision, not an
    /// accident.
    func testAnEmptyDesignRefusesExactlyTheCommandsThatNeedSomething() {
        let empty = CommandContext()
        let refused = Set(CommandRegistry.launchableCommands.map(\.id).filter { reason($0, empty) != nil })
        XCTAssertEqual(refused, [
            "sketch.line", "sketch.rectangle", "sketch.circle", "sketch.arc", "sketch.ellipse",
            "sketch.spline", "sketch.polygon", "sketch.text", "sketch.trim", "sketch.offset",
            "sketch.construction", "sketch.onHoveredPlane", "model.project",
            "model.extrude", "model.revolve", "model.sweep", "model.loft",
            "model.fillet", "model.chamfer", "model.shell", "model.deleteFace", "model.replaceFace",
            "model.imprint", "bool.union", "bool.subtract", "bool.intersect",
            "model.move", "transform.scaleUniform", "transform.pattern",
            "edit.undo", "edit.redo", "edit.delete", "edit.cut", "edit.copy", "edit.paste",
            "view.accuracyReport", "view.deviationPreview",
            "view.editSection", "view.section2D", "view.sectionOnly", "view.sectionFlip",
        ])
        for id in refused {
            let why = reason(id, empty) ?? ""
            XCTAssertTrue(why.hasSuffix("."), "\(id): a reason is a sentence — \(why)")
        }
    }

    /// The case found by driving the app: sketches with closed profiles exist
    /// but are hidden, and Extrude only looks at visible ones. The reason has
    /// to say so, or an agent cannot tell what to fix.
    func testCreatorsExplainMissingOrHiddenProfiles() {
        var c = CommandContext()
        c.hasExtrudableProfile = false
        XCTAssertEqual(reason("model.extrude", c), "Needs a sketch with a closed profile.")
        c.sketchCount = 4
        c.visibleSketchCount = 0
        XCTAssertTrue(reason("model.extrude", c)?.contains("hidden") == true)
        c.visibleSketchCount = 1
        XCTAssertEqual(reason("model.revolve", c), "No visible sketch has a closed profile.")
        c.hasExtrudableProfile = true
        XCTAssertNil(reason("model.loft", c))
    }

    func testRunningTheBooleanBeingPickedCancelsWithoutASelection() {
        var c = CommandContext()
        c.pickingBooleanCommandID = "bool.subtract"
        XCTAssertNil(reason("bool.subtract", c), "a second press cancels the pick")
        XCTAssertNotNil(reason("bool.union", c), "another boolean still needs its target")
    }

    func testUndoRedoAndPasteSayWhatIsMissing() {
        var c = CommandContext()
        XCTAssertEqual(reason("edit.undo", c), "Nothing to undo.")
        XCTAssertEqual(reason("edit.redo", c), "Nothing to redo.")
        XCTAssertEqual(reason("edit.paste", c), "The clipboard is empty.")
        c.clipboard = .bodies
        c.isSketching = true
        XCTAssertTrue(reason("edit.paste", c)?.contains("close the sketch") == true)
        c.isSketching = false
        XCTAssertNil(reason("edit.paste", c))
    }

    func testCopyFollowsWhatIsSelectedInTheCurrentMode() {
        var c = CommandContext()
        c.selectionCount = 1          // an id that is not a body (a plane, a decal)
        XCTAssertEqual(reason("edit.copy", c), "Needs a selected body.")
        c.selectedBodyCount = 1
        XCTAssertNil(reason("edit.copy", c))
        c.isSketching = true
        c.hasActiveSketch = true
        XCTAssertEqual(reason("edit.cut", c), "Needs selected sketch entities.")
    }

    func testDeviationPreviewTurnsOffEvenWithoutAPair() {
        var c = CommandContext()
        XCTAssertNotNil(reason("view.deviationPreview", c))
        c.deviationPreviewActive = true
        XCTAssertNil(reason("view.deviationPreview", c))
    }

    func testUnknownAndUnroutedIdsAreRefusedWithDifferentReasons() {
        let c = everythingReady
        let unknown = reason("not.a.command", c)
        XCTAssertTrue(unknown?.contains("Unknown command") == true)
        if let unrouted = CommandRegistry.unroutedChordedCommands.first {
            XCTAssertTrue(reason(unrouted.id, c)?.contains("no editor entry point") == true)
        }
    }

    /// Only the creators pay for profile detection.
    func testProfileDetectionIsOnlyForTheCreators() {
        XCTAssertEqual(CommandRegistry.profileCommandIDs,
                       ["model.extrude", "model.revolve", "model.sweep", "model.loft"])
    }
}
