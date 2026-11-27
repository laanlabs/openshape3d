//
//  CommandAvailability.swift
//  openshape3d
//
//  Why a command cannot run right now, in words.
//
//  `EditorViewModel.runCommand` answers with one `Bool`, and for a person
//  that is enough: the palette button is greyed out and the reason is on
//  screen. An assistant driving the app sees only "false". Building a house
//  over the agent channel, one asked for Extrude and was told the command
//  "does not apply in mode 'idle' with 0 selected", four times; the cause
//  was that it had hidden its sketches a step earlier, and nothing said so.
//
//  So the guards are stated here a second time, as rules over a plain value
//  (`CommandContext`) that say what is missing. They explain a refusal and
//  mark the command list; they do not decide anything. `runCommand` still
//  runs on its own guards, and where the two ever disagree the refusal falls
//  back to the plain message (and a Debug build logs it), so a rule that has
//  drifted can make an explanation vaguer but never a command behave
//  differently.
//

import Foundation

/// What stands in a command's way: a short code to branch on, and a
/// sentence that says what to do about it.
nonisolated struct CommandBlocker: Equatable, Sendable {
    let code: String
    let message: String
}

/// The parts of the editor's state the command guards read.
nonisolated struct CommandContext: Equatable, Sendable {
    /// A sketch is open for drawing.
    var isSketching = false
    /// The editor is waiting for a plane to sketch on.
    var isPickingSketchPlane = false
    /// Selected entities in the open sketch.
    var sketchSelectionCount = 0
    /// Sketch entities selected from the model (no sketch open).
    var hasModelSketchSelection = false
    var bodyCount = 0
    /// Selected bodies.
    var selectionCount = 0
    var sketchCount = 0
    /// Sketches that have a closed profile, by whether they are shown.
    var visibleProfileSketches = 0
    var hiddenProfileSketches = 0
    var canUndo = false
    var canRedo = false
    var canPaste = false
    /// One body selected, or a profile armed for extrude.
    var canBeginPattern = false
    /// The pointer is over the viewport (a hover-capable device).
    var hasHover = false
    var sectionActive = false
    /// The boolean being picked for, as its command id ("bool.union").
    var armedBoolean: String?
    var deviationPreviewShowing = false
    /// A reference body and a model body exist to compare.
    var hasDeviationPair = false
}

nonisolated enum CommandAvailability {

    private static let sketchTools: Set<String> = [
        "sketch.line", "sketch.rectangle", "sketch.circle", "sketch.arc", "sketch.ellipse", "sketch.spline",
        "sketch.polygon", "sketch.text", "sketch.trim", "sketch.offset", "model.project",
    ]
    private static let creators: Set<String> = ["model.extrude", "model.revolve", "model.sweep", "model.loft"]
    private static let needABody: Set<String> = [
        "model.fillet", "model.chamfer", "model.shell", "model.deleteFace", "model.replaceFace",
    ]
    private static let needASection: Set<String> = [
        "view.editSection", "view.section2D", "view.sectionOnly", "view.sectionFlip",
    ]

    /// What stops command `id` in `context`, or nil when nothing here does.
    static func blocker(for id: String, in context: CommandContext) -> CommandBlocker? {
        func selected(_ count: Int) -> String { count == 0 ? "nothing is selected" : "\(count) are selected" }
        let oneBody = CommandBlocker(
            code: "needs_one_body_selected",
            message: "Select exactly one body first (\(selected(context.selectionCount))).")

        if sketchTools.contains(id) {
            return context.isSketching ? nil : CommandBlocker(
                code: "needs_open_sketch",
                message: "This is a sketch tool: it works while a sketch is open for drawing, and none is.")
        }
        if creators.contains(id) {
            guard context.visibleProfileSketches == 0 else { return nil }
            if context.hiddenProfileSketches > 0 {
                let which = context.hiddenProfileSketches == 1 ? "The one sketch with a closed profile is hidden"
                    : "All \(context.hiddenProfileSketches) sketches with a closed profile are hidden"
                return CommandBlocker(code: "profiles_hidden",
                                      message: "\(which). Show a sketch first: a hidden sketch is not offered as a profile.")
            }
            if context.sketchCount == 0 {
                return CommandBlocker(code: "no_sketch", message: "There is no sketch yet. Draw a closed outline first.")
            }
            return CommandBlocker(code: "no_closed_profile",
                                  message: "No sketch has a closed profile. An outline's ends must meet before it can be used.")
        }
        if needABody.contains(id) {
            return context.bodyCount > 0 ? nil : CommandBlocker(code: "no_bodies", message: "There are no bodies yet.")
        }
        if needASection.contains(id) {
            return context.sectionActive ? nil : CommandBlocker(
                code: "no_section", message: "The section view is off. Turn it on first (view.section).")
        }

        switch id {
        case "sketch.construction":
            if !context.isSketching {
                return CommandBlocker(code: "needs_open_sketch",
                                      message: "Construction applies to entities of an open sketch, and no sketch is open.")
            }
            return context.sketchSelectionCount > 0 ? nil : CommandBlocker(
                code: "needs_sketch_selection", message: "Select the sketch entities to switch first.")
        case "sketch.onHoveredPlane":
            if context.isSketching || context.isPickingSketchPlane {
                return CommandBlocker(code: "already_sketching", message: "A sketch is already open or being placed.")
            }
            return context.hasHover ? nil : CommandBlocker(
                code: "needs_pointer", message: "This starts a sketch on the plane under the pointer, and the pointer is not over the model.")

        case "model.imprint":
            return context.selectionCount == 1 ? nil : oneBody
        case "bool.union", "bool.subtract", "bool.intersect":
            // Running the armed one again puts it down.
            if context.armedBoolean == id { return nil }
            return context.selectionCount == 1 ? nil : oneBody

        case "model.move":
            return context.selectionCount > 0 || context.hasModelSketchSelection ? nil : CommandBlocker(
                code: "needs_selection", message: "Select what to move first: nothing is selected.")
        case "transform.scaleUniform":
            return context.selectionCount > 0 ? nil : CommandBlocker(
                code: "needs_selection", message: "Select what to scale first: nothing is selected.")
        case "transform.pattern":
            return context.canBeginPattern ? nil : CommandBlocker(
                code: "needs_one_body_selected",
                message: "Select exactly one body to pattern (\(selected(context.selectionCount))), or arm a profile for extrude to pattern its sketch.")

        case "edit.undo":
            return context.canUndo ? nil : CommandBlocker(code: "nothing_to_undo", message: "There is nothing to undo.")
        case "edit.redo":
            return context.canRedo ? nil : CommandBlocker(code: "nothing_to_redo", message: "There is nothing to redo.")
        case "edit.delete":
            return context.selectionCount > 0 || context.sketchSelectionCount > 0 ? nil : CommandBlocker(
                code: "needs_selection", message: "Select what to delete first: nothing is selected.")
        case "edit.cut", "edit.copy":
            if context.isSketching {
                return context.sketchSelectionCount > 0 ? nil : CommandBlocker(
                    code: "needs_sketch_selection", message: "Select sketch entities first: none is selected.")
            }
            return context.selectionCount > 0 ? nil : CommandBlocker(
                code: "needs_selection", message: "Select a body first: nothing is selected.")
        case "edit.paste":
            return context.canPaste ? nil : CommandBlocker(
                code: "nothing_to_paste",
                message: context.isSketching ? "Nothing copied can be pasted into a sketch."
                                             : "Nothing copied can be pasted here.")

        case "view.accuracyReport":
            return context.bodyCount >= 2 ? nil : CommandBlocker(
                code: "needs_two_bodies", message: "An accuracy report compares two bodies, and the design has \(context.bodyCount).")
        case "view.deviationPreview":
            if context.deviationPreviewShowing { return nil }
            return context.hasDeviationPair ? nil : CommandBlocker(
                code: "needs_two_bodies", message: "The deviation preview compares a body with a reference, and there is no such pair.")

        default:
            return nil
        }
    }
}

extension EditorViewModel {

    /// The editor's state as the command rules read it.
    var commandContext: CommandContext {
        var context = CommandContext()
        context.isSketching = mode.isSketching
        if case .pickingSketchPlane = mode { context.isPickingSketchPlane = true }
        context.sketchSelectionCount = selectedSketchEntityIDs.count
        context.hasModelSketchSelection = hasModelSketchSelection
        context.bodyCount = session.document.bodies.count
        context.selectionCount = selection.count
        context.sketchCount = session.document.sketches.count
        for sketch in session.document.sketches where !ProfileDetector.detectProfiles(in: sketch).isEmpty {
            if sketch.isHidden { context.hiddenProfileSketches += 1 } else { context.visibleProfileSketches += 1 }
        }
        context.canUndo = session.undoStack.canUndo
        context.canRedo = session.undoStack.canRedo
        context.canPaste = canPaste
        context.canBeginPattern = canBeginPattern
        context.hasHover = hoverRay != nil
        context.sectionActive = sectionState != nil
        if case .pickingBooleanTool(let kind, _) = mode {
            switch kind {
            case .union: context.armedBoolean = "bool.union"
            case .subtract: context.armedBoolean = "bool.subtract"
            case .intersect: context.armedBoolean = "bool.intersect"
            }
        }
        context.deviationPreviewShowing = deviationPreview != nil || deviationPreviewComputing
        context.hasDeviationPair = deviationPreviewDefaults() != nil
        return context
    }

    /// What stops command `id` right now, or nil.
    func commandBlocker(_ id: String) -> CommandBlocker? {
        CommandAvailability.blocker(for: id, in: commandContext)
    }
}
