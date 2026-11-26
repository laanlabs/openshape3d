//
//  WebHandoffSheet.swift
//  openshape3d
//
//  "Open on the Web" (Export menu): says what will be sent, sends it only on
//  Send, then shows the link as a QR code with Open in Browser, Share and
//  Copy. See WebHandoff.swift for the request and its limits.
//

import CoreImage.CIFilterBuiltins
import SwiftUI
import UIKit

struct WebHandoffSheet: View {
    let designName: String
    /// Saves the session and encodes the archive (main actor); nil on failure.
    let designProvider: () -> Data?
    var service: WebHandoffService = .shared

    @Environment(\.dismiss) private var dismiss

    private enum Phase: Equatable {
        case ready
        case sending
        case sent(WebHandoffLink)
        case failed(String)

        var isSent: Bool { if case .sent = self { return true }; return false }
    }
    @State private var phase: Phase = .ready
    @State private var copied = false

    var body: some View {
        NavigationStack {
            content
                .padding(24)
                .frame(maxWidth: 520)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .navigationTitle("Open on the Web")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(phase.isSent ? "Done" : "Cancel") { dismiss() }
                            .disabled(phase == .sending)
                            .accessibilityIdentifier("WebHandoffClose")
                    }
                }
        }
        .presentationDetents([.large])
        .interactiveDismissDisabled(phase == .sending)
    }

    @ViewBuilder
    private var content: some View {
        switch phase {
        case .ready, .failed:
            VStack(alignment: .leading, spacing: 16) {
                Label {
                    Text("Open “\(designName)” in a web browser — on a computer, or anyone you share the link with.")
                        .font(.headline)
                } icon: {
                    Image(systemName: "globe").foregroundStyle(.blue)
                }
                VStack(alignment: .leading, spacing: 8) {
                    Text("Send uploads this design (.os3d) to app.openshape3d.com and gives you a link.")
                    Text("Anyone with the link can open the design for 24 hours; then it's deleted. Nothing else is sent, and your design stays on this device.")
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                if case .failed(let message) = phase {
                    Label(message, systemImage: "exclamationmark.triangle")
                        .font(.subheadline)
                        .foregroundStyle(.orange)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityIdentifier("WebHandoffError")
                }
                Button(action: send) {
                    Text(phase == .ready ? "Send" : "Try Again")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .accessibilityIdentifier("WebHandoffSend")
            }
        case .sending:
            VStack(spacing: 16) {
                ProgressView()
                    .controlSize(.large)
                Text("Sending…").foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, minHeight: 240)
            .accessibilityIdentifier("WebHandoffSending")
        case .sent(let link):
            VStack(spacing: 18) {
                if let qr = Self.qrCode(for: link.url) {
                    Image(uiImage: qr)
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 220, height: 220)
                        .accessibilityLabel("QR code for the link")
                }
                Text("Scan with a phone, or open the link on any computer.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                Text(link.url.absoluteString)
                    .font(.callout.monospaced())
                    .textSelection(.enabled)
                    .multilineTextAlignment(.center)
                    .accessibilityIdentifier("WebHandoffLink")
                VStack(spacing: 10) {
                    Link(destination: link.url) {
                        Label("Open in Browser", systemImage: "safari").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    HStack(spacing: 10) {
                        ShareLink(item: link.url) {
                            Label("Share Link", systemImage: "square.and.arrow.up").frame(maxWidth: .infinity)
                        }
                        Button {
                            UIPasteboard.general.url = link.url
                            copied = true
                        } label: {
                            Label(copied ? "Copied" : "Copy Link",
                                  systemImage: copied ? "checkmark" : "doc.on.doc")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.bordered)
                }
                .controlSize(.large)
                Text("The link works until \(link.expiresAt.formatted(date: .abbreviated, time: .shortened)). Your design stays on this device.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func send() {
        // Build the archive here, on the main actor (it saves the session),
        // then upload off it.
        guard let design = designProvider() else {
            phase = .failed(WebHandoffError.empty.localizedDescription)
            return
        }
        phase = .sending
        Task {
            do {
                let link = try await service.send(design: design)
                phase = .sent(link)
            } catch {
                phase = .failed((error as? LocalizedError)?.errorDescription ?? error.localizedDescription)
            }
        }
    }

    /// A crisp QR code (medium error correction) for the link.
    static func qrCode(for url: URL) -> UIImage? {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(url.absoluteString.utf8)
        filter.correctionLevel = "M"
        guard let output = filter.outputImage?.transformed(by: CGAffineTransform(scaleX: 12, y: 12)),
              let image = CIContext().createCGImage(output, from: output.extent)
        else { return nil }
        return UIImage(cgImage: image)
    }
}
