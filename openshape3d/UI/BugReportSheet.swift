//
//  BugReportSheet.swift
//  openshape3d
//
//  "Report a Bug": a short form — summary, what happened, steps, optional
//  contact — with an optional attachment of the open design (.os3d), sent
//  to Firestore by `BugReportService`. The footer lists exactly what goes
//  along automatically. Without a bundled Firebase config the sheet says
//  so and Send stays disabled.
//

import SwiftUI

struct BugReportSheet: View {
    let context: BugReportContext
    /// Builds the attachment on demand (saves the session, encodes the
    /// archive). nil when there is no open design (the gallery).
    let attachmentProvider: (() -> BugAttachment?)?

    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var details = ""
    @State private var steps = ""
    @State private var contactEmail = ""
    @State private var attachDesign = true
    @State private var isSending = false
    @State private var receipt: BugReportReceipt?
    @State private var errorMessage: String?

    private var config: FirebaseConfig? { FirebaseConfig.bundled }

    private var canSend: Bool {
        config != nil && !isSending
            && !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                if config == nil {
                    Section {
                        Label {
                            Text("Bug reporting isn't configured in this build. Add GoogleService-Info.plist to the app target to enable it.")
                        } icon: {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundStyle(.orange)
                        }
                        .accessibilityIdentifier("BugReportNotConfigured")
                    }
                }

                Section("What went wrong?") {
                    TextField("Short summary", text: $title)
                        .accessibilityIdentifier("BugTitleField")
                    TextEditor(text: $details)
                        .frame(minHeight: 96)
                        .overlay(alignment: .topLeading) {
                            if details.isEmpty {
                                Text("What happened, and what you expected instead")
                                    .foregroundStyle(.tertiary)
                                    .padding(.top, 8)
                                    .padding(.leading, 5)
                                    .allowsHitTesting(false)
                            }
                        }
                        .accessibilityIdentifier("BugDetailsField")
                }

                Section("Steps to reproduce") {
                    TextEditor(text: $steps)
                        .frame(minHeight: 72)
                        .overlay(alignment: .topLeading) {
                            if steps.isEmpty {
                                Text("1. … 2. … 3. …")
                                    .foregroundStyle(.tertiary)
                                    .padding(.top, 8)
                                    .padding(.leading, 5)
                                    .allowsHitTesting(false)
                            }
                        }
                        .accessibilityIdentifier("BugStepsField")
                }

                Section {
                    TextField("Email (optional)", text: $contactEmail)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .accessibilityIdentifier("BugEmailField")
                } header: {
                    Text("Contact")
                } footer: {
                    Text("Only used to follow up on this report.")
                }

                if attachmentProvider != nil {
                    Section {
                        Toggle("Attach this design (.os3d)", isOn: $attachDesign)
                            .accessibilityIdentifier("BugAttachToggle")
                    } footer: {
                        Text("The archive contains your sketches, features and geometry, and is the fastest way for us to reproduce the problem. Attachments are limited to \(BugAttachment.maxBytes / 1_048_576) MB.")
                    }
                }

                Section {
                    ForEach(context.summaryLines, id: \.self) { line in
                        Text(line).font(.footnote).foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Included with your report")
                } footer: {
                    Text("Nothing else is collected: no analytics, no identifiers, and nothing is sent until you press Send.")
                }
            }
            .navigationTitle("Report a Bug")
            .onDisappear { MacWindowTitle.restore() }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .disabled(isSending)
                        .accessibilityIdentifier("BugReportCancel")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Send", action: send)
                        .disabled(!canSend)
                        .accessibilityIdentifier("BugReportSend")
                }
            }
            .overlay {
                if isSending {
                    ZStack {
                        Color.black.opacity(0.15).ignoresSafeArea()
                        ProgressView("Sending…")
                            .padding(20)
                            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
                    }
                    .accessibilityIdentifier("BugReportSending")
                }
            }
            .interactiveDismissDisabled(isSending)
            .alert(receipt?.attachmentError == nil ? "Thanks — report sent"
                                                   : "Report sent without the design",
                   isPresented: Binding(get: { receipt != nil },
                                        set: { if !$0 { receipt = nil; dismiss() } })) {
                Button("OK") { receipt = nil; dismiss() }
            } message: {
                if let error = receipt?.attachmentError {
                    Text("\(error)\n\nReport ID \(receipt?.reportID ?? ""). Keep it if you follow up by email.")
                } else {
                    Text("Report ID \(receipt?.reportID ?? ""). Keep it if you follow up by email.")
                }
            }
            .alert("Couldn't send the report",
                   isPresented: Binding(get: { errorMessage != nil },
                                        set: { if !$0 { errorMessage = nil } })) {
                Button("OK", role: .cancel) { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
        }
        .presentationDetents([.large])
    }

    private func send() {
        guard let config else { return }
        let report = BugReport(
            title: title, details: details, steps: steps,
            contactEmail: contactEmail, context: context)
        // Build the attachment on the main actor (it saves the session and
        // encodes the archive), then upload off it.
        let attachment = (attachDesign ? attachmentProvider?() : nil)
        isSending = true
        let service = BugReportService(config: config)
        Task {
            do {
                let result = try await service.submit(report, attachment: attachment)
                await MainActor.run {
                    isSending = false
                    receipt = result
                }
            } catch {
                await MainActor.run {
                    isSending = false
                    errorMessage = (error as? LocalizedError)?.errorDescription
                        ?? error.localizedDescription
                }
            }
        }
    }
}
