//
//  AssistantPanelView.swift
//  openshape3d
//
//  The built-in assistant (#119): a panel beside the viewport where the
//  person types what they want and an AI model builds it in the open design.
//
//  It runs on the person's own API key, for whichever provider they choose:
//  Claude (Anthropic), ChatGPT's models (OpenAI) or Gemini (Google). Before a
//  key is saved the panel is the notice: what leaves this device, where it
//  goes, who is billed. Saving a key is how they agree to it, and a line
//  under the message box repeats it for as long as the panel is in use.
//
//  The other way to have an assistant build here needs no key at all: an
//  assistant app the person already has (Claude Desktop, ChatGPT) connects
//  over MCP. That is Settings ▸ AI Assistant, and the panel offers it too.
//

import SwiftUI

struct AssistantPanelView: View {
    @Bindable var session: AssistantSession
    var onClose: () -> Void

    @State private var draft = ""
    @State private var keyDraft = ""
    @State private var keyProblem: String?
    @State private var confirmRemoveKey = false
    @State private var showAssistantApps = false
    @FocusState private var messageFocused: Bool

    /// Whether assistant apps can connect over MCP on this device: on a Mac,
    /// where they run (and in DEBUG builds anywhere, so it can be tested).
    static var offersAssistantApps: Bool {
        #if targetEnvironment(macCatalyst) || DEBUG
        return true
        #else
        return false
        #endif
    }

    static let suggestions = [
        "Make a 40 × 30 × 10 mm block with 3 mm rounded edges",
        "Design a flowerpot I can 3D print",
        "What are the size and volume of this part?",
    ]

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            if session.hasKey {
                transcript
                Divider()
                composer
            } else {
                setup
            }
        }
        .frame(width: 320)
        .frame(maxHeight: 640)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18))
        .confirmationDialog("Remove the \(session.provider.company) API key from this device?",
                            isPresented: $confirmRemoveKey, titleVisibility: .visible) {
            Button("Remove Key", role: .destructive) { session.removeKey() }
        } message: {
            Text("\(session.provider.name) stops working here until a key is added again. The key itself is not "
                 + "deleted from your \(session.provider.company) account.")
        }
        .sheet(isPresented: $showAssistantApps) {
            NavigationStack {
                Form {
                    AIAssistantSettingsSection(control: AIControl.shared)
                }
                .navigationTitle("Assistant Apps")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { showAssistantApps = false }
                            .accessibilityIdentifier("AssistantAppsDone")
                    }
                }
            }
        }
    }

    // MARK: Header

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: "sparkles")
                .foregroundStyle(.tint)
            Text("Assistant")
                .font(.headline)
                .accessibilityIdentifier("AssistantTitle")
            Spacer()
            if session.hasKey {
                Menu {
                    // Changing provider starts a new chat; one without a key
                    // yet shows its key form.
                    Picker("Assistant", selection: $session.provider) {
                        ForEach(AssistantProvider.allCases) { provider in
                            Text(provider.name).tag(provider)
                        }
                    }
                    .disabled(session.isRunning)
                    Picker("Model", selection: $session.modelID) {
                        ForEach(session.provider.models) { model in
                            Text("\(model.name) (\(model.note))").tag(model.id)
                        }
                    }
                    .disabled(session.isRunning)
                    Divider()
                    Button("New Chat", systemImage: "square.and.pencil") { session.newChat() }
                    if session.tokensIn + session.tokensOut > 0 {
                        Text("This chat: \(session.tokensIn.formatted()) tokens in, "
                             + "\(session.tokensOut.formatted()) out")
                    }
                    Divider()
                    if Self.offersAssistantApps {
                        Button("Connect Claude Desktop or ChatGPT…", systemImage: "app.connected.to.app.below.fill") {
                            showAssistantApps = true
                        }
                    }
                    Button("Remove \(session.provider.company) API Key…", systemImage: "key.slash", role: .destructive) {
                        confirmRemoveKey = true
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .frame(width: 30, height: 30)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel("Assistant Options")
                .accessibilityIdentifier("AssistantOptions")
            }
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .semibold))
                    .frame(width: 30, height: 30)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .accessibilityLabel("Close Assistant")
            .accessibilityIdentifier("AssistantClose")
        }
        .padding(.leading, 14)
        .padding(.trailing, 8)
        .padding(.vertical, 8)
    }

    // MARK: Before there is a key

    private var setup: some View {
        let provider = session.provider
        return ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Describe a part or a change, and the assistant models it in this design. "
                     + "Every step it takes can be undone.")
                    .font(.subheadline)

                Picker("Assistant", selection: $session.provider) {
                    ForEach(AssistantProvider.allCases) { provider in
                        Text(provider.name).tag(provider)
                    }
                }
                .pickerStyle(.segmented)
                .accessibilityIdentifier("AssistantProviderPicker")

                VStack(alignment: .leading, spacing: 6) {
                    Label("Before you add a key", systemImage: "exclamationmark.triangle.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.orange)
                    Text("\(provider.name) runs here with an API key from your own \(provider.company) account. "
                         + "When you use it, your messages and what it reads from this design to do the "
                         + "work (sizes, sketches, and pictures of the viewport) are sent from this device "
                         + "straight to \(provider.company), and \(provider.company) bills your key for the usage.")
                    Text("Nothing passes through OpenShape 3D's servers. The key is kept in this device's "
                         + "keychain and is sent only to \(provider.company).")
                }
                .font(.footnote)
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
                .accessibilityElement(children: .combine)
                .accessibilityIdentifier("AssistantNotice")

                SecureField(provider.keyPlaceholder, text: $keyDraft)
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    // Return saves: on a phone the button below is under the keyboard.
                    .submitLabel(.done)
                    .onSubmit(saveKey)
                    .accessibilityIdentifier("AssistantKeyField")

                if let keyProblem {
                    Text(keyProblem)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .accessibilityIdentifier("AssistantKeyProblem")
                }

                Button(action: saveKey) {
                    Text("Save Key and Start")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(keyDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .accessibilityIdentifier("AssistantSaveKey")

                Link("Get an API key from \(provider.company)", destination: provider.keysPage)
                    .font(.footnote)

                Divider()

                // The other way in: an assistant app the person already has.
                VStack(alignment: .leading, spacing: 6) {
                    Text("No API key?")
                        .font(.subheadline.weight(.semibold))
                    if Self.offersAssistantApps {
                        Text("Claude Desktop or ChatGPT on this Mac can build in this design over MCP, using the "
                             + "account you already have with them.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        Button("Connect Claude Desktop or ChatGPT…") { showAssistantApps = true }
                            .font(.footnote)
                            .accessibilityIdentifier("AssistantConnectApps")
                    } else {
                        Text("On a Mac, Claude Desktop or ChatGPT can build in OpenShape 3D over MCP, using the "
                             + "account you already have with them. It is in the Mac app's Settings, under AI Assistant.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                .accessibilityIdentifier("AssistantAppsOffer")
            }
            .padding(14)
        }
        .scrollDismissesKeyboard(.interactively)
        .onChange(of: session.provider) { _, _ in
            keyDraft = ""
            keyProblem = nil
        }
    }

    private func saveKey() {
        keyProblem = session.saveKey(keyDraft)
        if keyProblem == nil {
            keyDraft = ""
            messageFocused = true
        }
    }

    // MARK: Conversation

    private var transcript: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    if session.entries.isEmpty {
                        emptyState
                    }
                    ForEach(session.entries) { entry in
                        row(entry)
                    }
                    if let status = session.status {
                        HStack(spacing: 6) {
                            ProgressView().controlSize(.small)
                            Text(status).font(.footnote).foregroundStyle(.secondary)
                        }
                        .accessibilityIdentifier("AssistantStatus")
                    }
                    Color.clear.frame(height: 1).id("end")
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            // Drag the conversation down to put the keyboard away and read it.
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: session.entries) { _, _ in proxy.scrollTo("end", anchor: .bottom) }
            .onChange(of: session.status) { _, _ in proxy.scrollTo("end", anchor: .bottom) }
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Ask for a part, or for a change to what is here.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            ForEach(Self.suggestions, id: \.self) { suggestion in
                Button {
                    session.send(suggestion)
                } label: {
                    Text(suggestion)
                        .font(.footnote)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(Color.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
            }
        }
    }

    @ViewBuilder private func row(_ entry: AssistantSession.Entry) -> some View {
        switch entry.kind {
        case .user(let text):
            Text(text)
                .font(.subheadline)
                .textSelection(.enabled)
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(Color.accentColor.opacity(0.18), in: RoundedRectangle(cornerRadius: 12))
                .frame(maxWidth: .infinity, alignment: .trailing)
                .accessibilityIdentifier("AssistantUserMessage")
        case .reply(let text):
            Text(Self.formatted(text))
                .font(.subheadline)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityIdentifier("AssistantReply")
        case let .activity(label, progress):
            activityRow(label, progress)
        case .notice(let text):
            Text(text)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityIdentifier("AssistantNoticeRow")
        case .problem(let text):
            Label(text, systemImage: "exclamationmark.triangle.fill")
                .font(.footnote)
                .foregroundStyle(.red)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityIdentifier("AssistantProblem")
        }
    }

    private func activityRow(_ label: String, _ progress: AssistantSession.Entry.Progress) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 6) {
                switch progress {
                case .running:
                    ProgressView().controlSize(.mini).frame(width: 14)
                case .done:
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(.green).frame(width: 14)
                case .failed:
                    Image(systemName: "xmark.circle.fill").foregroundStyle(.orange).frame(width: 14)
                }
                Text(label)
            }
            if case .failed(let why) = progress, !why.isEmpty {
                Text(why)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
                    .padding(.leading, 20)
            }
        }
        .font(.footnote)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("AssistantActivity")
    }

    /// The reply with its inline Markdown (bold, code, links) applied and its
    /// line breaks kept. Text that is not valid Markdown is shown as written.
    static func formatted(_ text: String) -> AttributedString {
        let options = AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        return (try? AttributedString(markdown: text, options: options)) ?? AttributedString(text)
    }

    // MARK: Message box

    private var composer: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .bottom, spacing: 8) {
                TextField("Ask for a part or a change", text: $draft, axis: .vertical)
                    .lineLimit(1...5)
                    .textFieldStyle(.plain)
                    .font(.subheadline)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(Color.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
                    .focused($messageFocused)
                    .onSubmit(send)
                    .accessibilityIdentifier("AssistantInput")
                if session.isRunning {
                    Button(action: session.stop) {
                        Image(systemName: "stop.circle.fill").font(.system(size: 28))
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.red)
                    .accessibilityLabel("Stop")
                    .accessibilityIdentifier("AssistantStop")
                } else {
                    Button(action: send) {
                        Image(systemName: "arrow.up.circle.fill").font(.system(size: 28))
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.tint)
                    .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .accessibilityLabel("Send")
                    .accessibilityIdentifier("AssistantSend")
                }
            }
            Text("Your messages and details of this design go to \(session.provider.company) under your API key.")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .accessibilityIdentifier("AssistantFootnote")
        }
        .padding(10)
    }

    private func send() {
        guard !session.isRunning else { return }
        let text = draft
        draft = ""
        session.send(text)
    }
}
