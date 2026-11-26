//
//  AssistantTools.swift
//  openshape3d
//
//  Running one of the built-in assistant's tool calls (#119).
//
//  The call itself is `AgentLocalCall.run`: the same path an assistant
//  connected from outside takes, minus the socket. What is added here is
//  where an export lands on this device, the one op an iPad cannot serve,
//  and the words the panel shows while a call runs.
//

import Foundation

enum AssistantTools {

    /// Run `call` against the open design and return what the model should
    /// see. Synchronous on the main actor, like every editor operation.
    static func run(_ call: AssistantToolCall) -> (content: [AssistantToolContent], isError: Bool) {
        if let problem = call.problem { return ([.text(problem)], true) }
        if let refusal = platformRefusal(op: call.op) { return ([.text(refusal)], true) }

        let reply = AgentLocalCall.run(name: call.name, arguments: call.input) { data, requestedName, format in
            AgentExportFolder.save(data, requestedName: requestedName, format: format)
        }
        return AnthropicWire.toolContent(fromMCPReply: reply.body)
    }

    /// `document.export` writes into the Downloads folder, which a person can
    /// open on a Mac. On an iPad or iPhone that folder is inside the app,
    /// where they cannot reach it, so the assistant is told to point them at
    /// the Export menu instead of saving a file nobody will find.
    static func platformRefusal(op: String) -> String? {
        guard op == "document.export", !ProcessInfo.processInfo.isMacCatalystApp else { return nil }
        return "On iPad and iPhone the assistant cannot save a file where the person can open it. "
             + "Tell them to use the Export menu in the top bar, which saves or shares the design in "
             + "the format they pick."
    }

    // MARK: - What the panel says while a call runs

    /// A few words for the transcript: what this call is doing, in the
    /// app's own vocabulary rather than the operation's name.
    nonisolated static func label(op: String, args: [String: Any]) -> String {
        switch op {
        case "health", "commands": return "Checking the app"
        case "guide": return "Reading the modelling guide"
        case "state": return "Reading the design"
        case "faces": return "Listing faces"
        case "edges": return "Listing edges"
        case "sketches": return "Reading the sketches"
        case "check": return "Checking the solid"
        case "screenshot": return "Looking at the viewport"
        case "accuracy", "accuracy.image": return "Comparing with the reference"
        case "view.deviationPreview": return "Deviation preview"
        case "sketch.create": return "New sketch"
        case "sketch.addEntities": return "Drawing in the sketch"
        case "body.setMaterial": return "Material"
        case "item.setHidden": return "Show or hide"
        case "item.select": return "Selection"
        case "item.rename": return "Rename"
        case "document.export":
            let format = (args["format"] as? String ?? "stl").uppercased()
            return "Export \(format)"
        case "command.run":
            switch args["id"] as? String ?? "" {
            case "edit.undo": return "Undo"
            case "edit.redo": return "Redo"
            case "view.fit": return "Fit the view"
            case let id where id.hasPrefix("view."): return "Change the view"
            case let id: return id.isEmpty ? "Command" : "Command \(id)"
            }
        default:
            // feature.pushPull → "Push pull", feature.extrude → "Extrude"
            let name = op.split(separator: ".").last.map(String.init) ?? op
            var words = ""
            for character in name {
                if character.isUppercase, !words.isEmpty { words.append(" ") }
                words.append(contentsOf: words.isEmpty ? character.uppercased() : character.lowercased())
            }
            return words.isEmpty ? "Working" : words
        }
    }
}
