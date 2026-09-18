//
//  AIAssistantSettingsSection.swift
//  openshape3d
//
//  Settings ▸ AI Assistant: the one switch that lets Claude or ChatGPT on this
//  Mac build in the open design, and the two ways to connect them — a
//  one-click Claude Desktop extension, and an address for everything else.
//  Written for someone who has never opened a terminal: no ports, no JSON.
//

import SwiftUI
import UIKit

struct AIAssistantSettingsSection: View {
    @Bindable var control: AIControl
    @State private var notice: String?

    var body: some View {
        Section {
            Toggle("Let AI Assistants Build Here", isOn: $control.isEnabled)
                .accessibilityIdentifier("SettingsAIControl")
            if control.isEnabled {
                statusRow
                LabeledContent("Pairing Code") {
                    HStack(spacing: 8) {
                        Text(control.pairingCode)
                            .font(.system(.footnote, design: .monospaced))
                            .textSelection(.enabled)
                            .accessibilityIdentifier("SettingsAIPairingCode")
                        Button("Copy") { copy(control.pairingCode, saying: "Pairing code copied.") }
                            .buttonStyle(.bordered).controlSize(.small)
                            .accessibilityIdentifier("SettingsAICopyCode")
                    }
                }
                Button("Add to Claude Desktop…") { addToClaude() }
                    .accessibilityIdentifier("SettingsAIAddToClaude")
                Button("Copy Address for ChatGPT") {
                    copy(control.address ?? "", saying: "Address copied. In ChatGPT (Codex), add it as an MCP server "
                         + "and use the pairing code as the bearer token.")
                }
                .disabled(control.address == nil)
                .accessibilityIdentifier("SettingsAICopyAddress")
                Button("New Pairing Code", role: .destructive) {
                    control.replacePairingCode()
                    notice = "New code made. Assistants paired with the old one need the new code."
                }
                .accessibilityIdentifier("SettingsAINewCode")
            }
        } header: {
            Text("AI Assistant")
        } footer: {
            Text(notice ?? "Ask Claude or ChatGPT on this Mac for a part — “design a flowerpot I can 3D print” — and it "
                 + "models it here, then saves an STL to Downloads. Only apps on this Mac that have your pairing "
                 + "code can connect, and only while this is on.")
        }
    }

    @ViewBuilder private var statusRow: some View {
        switch control.status {
        case .listening:
            Label("Ready for Claude and ChatGPT", systemImage: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .accessibilityIdentifier("SettingsAIReady")
        case .starting, .stopped:
            Label("Starting…", systemImage: "circle.dotted").foregroundStyle(.secondary)
        case .failed(let reason):
            Label("Couldn't start: \(reason)", systemImage: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
        }
    }

    private func copy(_ text: String, saying message: String) {
        UIPasteboard.general.string = text
        notice = message
    }

    /// Put the extension in Downloads and open it: Claude Desktop owns
    /// `.mcpb`, so this lands on its install dialog, which asks for the
    /// pairing code — already on the clipboard.
    private func addToClaude() {
        guard let bundled = Bundle.main.url(forResource: "OpenShape3D", withExtension: "mcpb"),
              let data = try? Data(contentsOf: bundled),
              let folder = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first else {
            notice = "The Claude Desktop extension is missing from this build."
            return
        }
        let target = folder.appendingPathComponent("OpenShape 3D.mcpb")
        do {
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            try data.write(to: target, options: .atomic)
        } catch {
            notice = "Couldn't save the extension to Downloads: \(error.localizedDescription)"
            return
        }
        UIPasteboard.general.string = control.pairingCode
        UIApplication.shared.open(target) { opened in
            notice = opened
                ? "In Claude: click Install, paste the pairing code (already copied), Save, then switch the "
                  + "extension to Enabled."
                : "Saved “OpenShape 3D.mcpb” to Downloads. Double-click it, click Install, paste the pairing "
                  + "code (already copied), Save, then switch the extension to Enabled."
        }
    }
}
