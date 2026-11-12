//
//  CommandAvailability.swift
//  openshape3d
//
//  "Can this command run right now, and if not, why?" — answered BEFORE
//  running it, from a plain snapshot of the editor.
//
//  `runCommand(_:)` used to find out by trying: each case in `perform` held
//  its own guard and returned false, so a refused hotkey, a refused
//  Command Search pick and a refused agent call all learned the same thing —
//  "not applicable". An assistant driving the app over `/v1/command` got
//  "does not apply in mode 'idle' with 0 selected" whether the cause was a
//  missing sketch, an empty undo stack or hidden sketches, and could not tell
//  which to fix.
//
//  `CommandRegistry.unavailableReason(for:in:)` is the one place those guards
//  live now. It is pure (a `CommandContext` in, a sentence out), so a unit
//  test pins every rule without an `EditorViewModel`, which XCTest cannot
//  build (STATUS gotcha 1). `runCommand` asks it first, so the reason an
//  agent reads is exactly the rule that blocks the key and the palette.
//

import Foundation

/// The editor facts the command guards read. Plain values: built on the main
/// actor by `EditorViewModel.commandContext(…)`, read anywhere.
nonisolated struct CommandContext: Equatable, Sendable {
    enum Clipboard: Equatable, Sendable { case empty, bodies, sketchEntities }

    var isSketching = false
    var isPickingSketchPlane = false
    var hasHoverRay = false
    var hasActiveSketch = false
    var selectedSketchEntityCount = 0
    var bodyCount = 0
    /// Selected ids, bodies or not.
    var selectionCount = 0
    /// Selected ids that are bodies in the document (what Copy copies).
    var selectedBodyCount = 0
    var hasModelSketchSelection = false
    var canBeginPattern = false
    var canUndo = false
    var canRedo = false
    var clipboard: Clipboard = .empty
    var sectionActive = false
    var deviationPreviewActive = false
    var hasDeviationPair = false
    /// The boolean command whose picking is in progress (`"bool.union"`, …):
    /// running it again cancels the pick, which needs no selection.
    var pickingBooleanCommandID: String?
    var sketchCount = 0
    var visibleSketchCount = 0
    /// A visible sketch with a closed profile. The one fact that costs work
    /// (profile detection over every sketch), so it is only filled in when
    /// asked for — `nil` means "not evaluated".
    var hasExtrudableProfile: Bool?
}

extension CommandRegistry {

    /// Commands whose rule reads `hasExtrudableProfile`: the only ones worth
    /// running profile detection for.
    nonisolated static let profileCommandIDs: Set<String> = [
        "model.extrude", "model.revolve", "model.sweep", "model.loft",
    ]

    /// Why `id` cannot run in `context`, or `nil` when it can.
    ///
    /// The sentence says what is missing and, where there is one obvious way,
    /// how to get it — it is read by people (Command Search) and by agents.
    /// Ids the editor does not route answer too, so a caller never has to
    /// tell "unknown" from "not now" itself.
    nonisolated static func unavailableReason(for id: String, in context: CommandContext) -> String? {
        guard routableIDs.contains(id) else {
            return command(inCatalog: id) == nil
                ? "Unknown command. GET /v1/commands lists the ones this build can run."
                : "This build has no editor entry point for this command yet."
        }
        let c = context
        switch id {

        // Sketch tools act inside an open sketch.
        case "sketch.line", "sketch.rectangle", "sketch.circle", "sketch.arc",
             "sketch.ellipse", "sketch.spline", "sketch.polygon", "sketch.text",
             "sketch.trim", "sketch.offset", "model.project":
            return c.isSketching ? nil : "Needs a sketch open for editing."

        case "sketch.onHoveredPlane":
            if c.isSketching || c.isPickingSketchPlane { return "A sketch is already open or being placed." }
            return c.hasHoverRay ? nil : "Needs the pointer over a face or plane to sketch on."

        case "sketch.construction":
            if !c.isSketching { return "Needs a sketch open for editing." }
            return c.selectedSketchEntityCount > 0 ? nil : "Needs selected sketch entities."

        // Creators need a closed profile in a visible sketch.
        case "model.extrude", "model.revolve", "model.sweep", "model.loft":
            if c.hasExtrudableProfile == true { return nil }
            if c.sketchCount == 0 { return "Needs a sketch with a closed profile." }
            if c.visibleSketchCount == 0 {
                return "Every sketch is hidden. Show the one with the profile (item.setHidden with hidden: false)."
            }
            return "No visible sketch has a closed profile."

        // Blends, shell and the face tools act on a body.
        case "model.fillet", "model.chamfer", "model.shell", "model.deleteFace", "model.replaceFace":
            return c.bodyCount > 0 ? nil : "Needs a body."

        case "model.imprint":
            return c.selectionCount == 1 ? nil : "Needs exactly one selected body."

        case "bool.union", "bool.subtract", "bool.intersect":
            if c.pickingBooleanCommandID == id { return nil }   // runs as "cancel"
            return c.selectionCount == 1 ? nil : "Needs exactly one selected body (the target)."

        case "model.move":
            return c.selectionCount > 0 || c.hasModelSketchSelection ? nil : "Needs a selection to move."
        case "transform.scaleUniform":
            return c.selectionCount > 0 ? nil : "Needs a selection to scale."
        case "transform.pattern":
            return c.canBeginPattern ? nil : "Needs exactly one selected body, or an extrude in progress."

        case "edit.undo":
            return c.canUndo ? nil : "Nothing to undo."
        case "edit.redo":
            return c.canRedo ? nil : "Nothing to redo."
        case "edit.delete":
            return c.selectionCount > 0 || c.selectedSketchEntityCount > 0 ? nil : "Nothing selected to delete."
        case "edit.copy", "edit.cut":
            if c.isSketching {
                return c.hasActiveSketch && c.selectedSketchEntityCount > 0 ? nil : "Needs selected sketch entities."
            }
            return c.selectedBodyCount > 0 ? nil : "Needs a selected body."
        case "edit.paste":
            switch c.clipboard {
            case .empty: return "The clipboard is empty."
            case .bodies: return c.isSketching ? "The clipboard holds bodies: close the sketch to paste them." : nil
            case .sketchEntities: return c.isSketching ? nil : "The clipboard holds sketch entities: open a sketch to paste them."
            }

        case "view.accuracyReport":
            return c.bodyCount >= 2 ? nil : "Needs two bodies to compare."
        case "view.deviationPreview":
            if c.deviationPreviewActive { return nil }   // runs as "turn off"
            return c.hasDeviationPair ? nil : "Needs two bodies to compare."
        case "view.editSection", "view.section2D", "view.sectionOnly", "view.sectionFlip":
            return c.sectionActive ? nil : "Needs a section view (view.section)."

        // Views, construction planes and axes, visibility, the launcher:
        // always available in the editor.
        default:
            return nil
        }
    }
}
