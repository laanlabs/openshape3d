//
//  CommandAvailabilityTests.swift
//  openshape3dTests
//
//  The rules that say why a command cannot run. They are plain functions of
//  a `CommandContext`, so they are tested without an editor: each kind of
//  refusal, the case that started this (profiles in hidden sketches), and
//  that the command list carries the answer.
//

import XCTest
@testable import openshape3d

final class CommandAvailabilityTests: XCTestCase {

    private func blocker(_ id: String, _ edit: (inout CommandContext) -> Void = { _ in }) -> CommandBlocker? {
        var context = CommandContext()
        edit(&context)
        return CommandAvailability.blocker(for: id, in: context)
    }

    // MARK: - The case that started it

    func testExtrudeSaysWhenItsProfilesAreHidden() {
        // Four closed profiles, all in sketches that were hidden a step earlier.
        let hidden = blocker("model.extrude") { $0.sketchCount = 4; $0.hiddenProfileSketches = 4 }
        XCTAssertEqual(hidden?.code, "profiles_hidden")
        XCTAssertTrue(hidden?.message.contains("All 4 sketches") ?? false, hidden?.message ?? "")
        XCTAssertTrue(hidden?.message.contains("Show a sketch first") ?? false)

        let one = blocker("model.revolve") { $0.sketchCount = 1; $0.hiddenProfileSketches = 1 }
        XCTAssertTrue(one?.message.hasPrefix("The one sketch") ?? false, one?.message ?? "")

        // One shown profile is enough, whatever else is hidden.
        XCTAssertNil(blocker("model.extrude") { $0.sketchCount = 4; $0.hiddenProfileSketches = 3; $0.visibleProfileSketches = 1 })
    }

    func testCreatorsTellNoSketchFromNoClosedProfile() {
        for id in ["model.extrude", "model.revolve", "model.sweep", "model.loft"] {
            XCTAssertEqual(blocker(id)?.code, "no_sketch", id)
            XCTAssertEqual(blocker(id) { $0.sketchCount = 2 }?.code, "no_closed_profile", id)
        }
    }

    // MARK: - Each kind of refusal

    func testSketchToolsNeedAnOpenSketch() {
        for id in ["sketch.line", "sketch.circle", "sketch.trim", "sketch.offset", "model.project"] {
            XCTAssertEqual(blocker(id)?.code, "needs_open_sketch", id)
            XCTAssertNil(blocker(id) { $0.isSketching = true }, id)
        }
        XCTAssertEqual(blocker("sketch.construction")?.code, "needs_open_sketch")
        XCTAssertEqual(blocker("sketch.construction") { $0.isSketching = true }?.code, "needs_sketch_selection")
        XCTAssertNil(blocker("sketch.construction") { $0.isSketching = true; $0.sketchSelectionCount = 2 })
    }

    func testSketchOnTheHoveredPlaneNeedsAPointerAndNoSketchUnderWay() {
        XCTAssertEqual(blocker("sketch.onHoveredPlane")?.code, "needs_pointer")
        XCTAssertNil(blocker("sketch.onHoveredPlane") { $0.hasHover = true })
        XCTAssertEqual(blocker("sketch.onHoveredPlane") { $0.hasHover = true; $0.isSketching = true }?.code, "already_sketching")
        XCTAssertEqual(blocker("sketch.onHoveredPlane") { $0.hasHover = true; $0.isPickingSketchPlane = true }?.code,
                       "already_sketching")
    }

    func testBodyToolsNeedABody() {
        for id in ["model.fillet", "model.chamfer", "model.shell", "model.deleteFace", "model.replaceFace"] {
            XCTAssertEqual(blocker(id)?.code, "no_bodies", id)
            XCTAssertNil(blocker(id) { $0.bodyCount = 1 }, id)
        }
    }

    func testBooleansAndImprintNeedExactlyOneBodySelected() {
        for id in ["bool.union", "bool.subtract", "bool.intersect", "model.imprint"] {
            XCTAssertEqual(blocker(id)?.code, "needs_one_body_selected", id)
            XCTAssertTrue(blocker(id)?.message.contains("nothing is selected") ?? false, id)
            XCTAssertTrue(blocker(id) { $0.selectionCount = 3 }?.message.contains("3 are selected") ?? false, id)
            XCTAssertNil(blocker(id) { $0.selectionCount = 1 }, id)
        }
        // The armed boolean can always be put down again, and only that one.
        XCTAssertNil(blocker("bool.subtract") { $0.armedBoolean = "bool.subtract" })
        XCTAssertNotNil(blocker("bool.union") { $0.armedBoolean = "bool.subtract" })
    }

    func testTransformsNeedSomethingSelected() {
        XCTAssertEqual(blocker("model.move")?.code, "needs_selection")
        XCTAssertNil(blocker("model.move") { $0.selectionCount = 2 })
        XCTAssertNil(blocker("model.move") { $0.hasModelSketchSelection = true })
        XCTAssertEqual(blocker("transform.scaleUniform")?.code, "needs_selection")
        XCTAssertNil(blocker("transform.scaleUniform") { $0.selectionCount = 1 })
        XCTAssertEqual(blocker("transform.pattern")?.code, "needs_one_body_selected")
        XCTAssertNil(blocker("transform.pattern") { $0.canBeginPattern = true })
    }

    func testEditCommands() {
        XCTAssertEqual(blocker("edit.undo")?.code, "nothing_to_undo")
        XCTAssertNil(blocker("edit.undo") { $0.canUndo = true })
        XCTAssertEqual(blocker("edit.redo")?.code, "nothing_to_redo")
        XCTAssertNil(blocker("edit.redo") { $0.canRedo = true })
        XCTAssertEqual(blocker("edit.delete")?.code, "needs_selection")
        XCTAssertNil(blocker("edit.delete") { $0.sketchSelectionCount = 1 })
        XCTAssertNil(blocker("edit.delete") { $0.selectionCount = 1 })
        for id in ["edit.cut", "edit.copy"] {
            XCTAssertEqual(blocker(id)?.code, "needs_selection", id)
            XCTAssertNil(blocker(id) { $0.selectionCount = 1 }, id)
            // In a sketch it is the sketch's selection that counts.
            XCTAssertEqual(blocker(id) { $0.isSketching = true; $0.selectionCount = 1 }?.code, "needs_sketch_selection", id)
            XCTAssertNil(blocker(id) { $0.isSketching = true; $0.sketchSelectionCount = 1 }, id)
        }
        XCTAssertEqual(blocker("edit.paste")?.code, "nothing_to_paste")
        XCTAssertNil(blocker("edit.paste") { $0.canPaste = true })
    }

    func testViewCommands() {
        XCTAssertEqual(blocker("view.accuracyReport") { $0.bodyCount = 1 }?.code, "needs_two_bodies")
        XCTAssertNil(blocker("view.accuracyReport") { $0.bodyCount = 2 })
        XCTAssertEqual(blocker("view.deviationPreview")?.code, "needs_two_bodies")
        XCTAssertNil(blocker("view.deviationPreview") { $0.hasDeviationPair = true })
        XCTAssertNil(blocker("view.deviationPreview") { $0.deviationPreviewShowing = true }, "it can always be turned off")
        for id in ["view.editSection", "view.section2D", "view.sectionOnly", "view.sectionFlip"] {
            XCTAssertEqual(blocker(id)?.code, "no_section", id)
            XCTAssertNil(blocker(id) { $0.sectionActive = true }, id)
        }
    }

    // MARK: - The whole catalog

    /// In an empty new design, exactly these commands are stopped. A command
    /// added to the catalog with a guard but no rule shows up here.
    func testWhatAnEmptyDesignRefuses() {
        let stopped = Set(CommandRegistry.routableIDs.filter { CommandAvailability.blocker(for: $0, in: CommandContext()) != nil })
        XCTAssertEqual(stopped, [
            "sketch.line", "sketch.rectangle", "sketch.circle", "sketch.arc", "sketch.ellipse", "sketch.polygon",
            "sketch.text", "sketch.trim", "sketch.offset", "sketch.construction", "sketch.onHoveredPlane", "sketch.spline",
            "model.project", "model.extrude", "model.revolve", "model.sweep", "model.loft",
            "model.fillet", "model.chamfer", "model.shell", "model.deleteFace", "model.replaceFace", "model.imprint",
            "bool.union", "bool.subtract", "bool.intersect",
            "model.move", "transform.scaleUniform", "transform.pattern",
            "edit.undo", "edit.redo", "edit.delete", "edit.cut", "edit.copy", "edit.paste",
            "view.accuracyReport", "view.deviationPreview",
            "view.editSection", "view.section2D", "view.sectionOnly", "view.sectionFlip",
        ])
        // Every message is a sentence someone can act on.
        for id in stopped {
            let message = CommandAvailability.blocker(for: id, in: CommandContext())?.message ?? ""
            XCTAssertTrue(message.count > 20 && message.hasSuffix("."), "\(id): \(message)")
        }
    }

    // MARK: - The command list

    private func commands(_ response: AgentResponse) throws -> (payload: [String: Any], byID: [String: [String: Any]]) {
        let payload = try XCTUnwrap(JSONSerialization.jsonObject(with: response.body) as? [String: Any])
        let list = try XCTUnwrap(payload["commands"] as? [[String: Any]])
        return (payload, Dictionary(uniqueKeysWithValues: list.map { ($0["id"] as? String ?? "", $0) }))
    }

    func testTheCommandListSaysWhatCanRunWhenADesignIsOpen() throws {
        var context = CommandContext()
        context.sketchCount = 1
        context.hiddenProfileSketches = 1
        let (payload, byID) = try commands(AgentRouter.commandsResponse { CommandAvailability.blocker(for: $0, in: context) })
        XCTAssertEqual(byID["view.fit"]?["available"] as? Bool, true)
        XCTAssertNil(byID["view.fit"]?["why"])
        XCTAssertEqual(byID["model.extrude"]?["available"] as? Bool, false)
        XCTAssertEqual(byID["model.extrude"]?["blocker"] as? String, "profiles_hidden")
        XCTAssertTrue((byID["model.extrude"]?["why"] as? String ?? "").contains("hidden"))
        let available = byID.values.filter { $0["available"] as? Bool == true }.count
        XCTAssertEqual(payload["available"] as? Int, available)
        XCTAssertLessThan(available, byID.count)
    }

    func testTheCommandListWithoutADesignIsThePlainCatalog() throws {
        let (payload, byID) = try commands(AgentRouter.commandsResponse())
        XCTAssertNil(payload["available"])
        XCTAssertNil(byID["model.extrude"]?["available"], "with nothing open there is nothing to say")
        XCTAssertEqual(payload["count"] as? Int, byID.count)
    }
}
