//
//  AgentBridgeDevice.swift
//  openshape3d
//
//  The routes of the agent bridge that need the device itself: a picture of
//  the viewport, the accuracy overlay drawn as an image, the design as a
//  file, a SpaceMouse fed by hand, a kernel capture written to disk.
//
//  They are apart from `AgentBridge.swift` because that file is also compiled
//  into the web app's engine (openshape-cloud `core/scripts/sync_ios_sources.py`),
//  where there is no UIKit. The web engine has its own `handleDeviceRoute`
//  (`Web/AgentHost.swift`); everything else in the bridge is the same code on
//  both.
//

import Foundation
import UIKit

extension AgentBridge {

    /// The answer to a device route, or nil when `route` is not one.
    func handleDeviceRoute(_ route: AgentRoute, on viewModel: EditorViewModel) -> AgentResponse? {
        switch route {
        case .archive:
            // Flush live edits and the viewport thumbnail into the rows
            // first: `archive(from:)` snapshots PERSISTED state only.
            viewModel.saveThumbnail()
            viewModel.session.save()
            guard let data = ProjectArchive.archive(from: viewModel.session.project).encoded() else {
                return .failure(500, "Internal Server Error", error: "archive_failed",
                                message: "The design could not be encoded as a .os3d archive.")
            }
            return AgentResponse(status: 200, reason: "OK",
                                 contentType: "application/octet-stream", body: data)

        case let .accuracyImage(query, view, width, format, maxBytes):
            // One view, outlines only: a picture needs no surface sampling.
            var options = query.options
            options.views = [view]
            options.includeDeviation = false
            switch accuracyReport(AccuracyQuery(referenceID: query.referenceID, modelID: query.modelID,
                                                options: options), on: viewModel) {
            case .report(let report):
                guard let overlay = report.overlays.first(where: { $0.view == view }),
                      let png = AccuracyOverlayRenderer.png(overlay: overlay, report: report, width: width) else {
                    return .failure(500, "Internal Server Error", error: "render_failed",
                                    message: "The overlay could not be drawn.")
                }
                guard format == .jpeg else { return .png(png) }
                guard let jpeg = Self.jpeg(fromPNG: png, maxBytes: maxBytes) else {
                    return .failure(500, "Internal Server Error", error: "render_failed",
                                    message: "The overlay could not be re-encoded as JPEG.")
                }
                return .image(jpeg, contentType: AgentShotFormat.jpeg.contentType)
            case .refused(let reply): return reply
            }

        case let .spaceMouse(axes, seconds, buttons):
            // Exactly what the device sends: report 1 with all six axes,
            // ticked at 60 Hz, released, then report 3 for the buttons.
            let driver = SpaceMouseDriver.shared
            func report(_ values: [Double]) -> [UInt8] {
                values.flatMap { value -> [UInt8] in
                    let bits = UInt16(bitPattern: Int16(clamping: Int(value.rounded())))
                    return [UInt8(bits & 0xFF), UInt8(bits >> 8)]
                }
            }
            driver.receive(reportID: 1, payload: report(axes))
            for _ in 0..<Int((seconds * 60).rounded()) { driver.tick(dt: 1.0 / 60) }
            driver.receive(reportID: 1, payload: report(Array(repeating: 0, count: 6)))
            if buttons != 0 {
                let mask = UInt32(truncatingIfNeeded: buttons)
                driver.receive(reportID: 3, payload: (0..<4).map { UInt8(truncatingIfNeeded: mask >> (8 * $0)) })
                driver.receive(reportID: 3, payload: [0, 0, 0, 0])
            }
            return .ok(["device": driver.deviceName ?? NSNull(), "ticks": Int((seconds * 60).rounded())])

        case let .latency(record, reset):
            let recorder = InteractionLatencyRecorder.shared
            if reset { recorder.reset() }
            if let record { recorder.setRecording(record) }
            return .ok(recorder.report())

        case let .capture(note):
            let analytic = viewModel.session.document.bodies.compactMap { body in
                body.brep.map { (label: body.name, handle: $0) }
            }
            guard !analytic.isEmpty else {
                return .failure(409, "Conflict", error: "nothing_to_capture",
                                message: "No body carries a brep — a snapshot captures "
                                       + "analytic solids, and every body here is mesh-only.")
            }
            guard let bundle = KernelCapture.recordSnapshot(
                inputs: analytic, note: note.isEmpty ? "requested over /v1/capture" : note)
            else {
                return .failure(500, "Internal Server Error", error: "capture_failed",
                                message: "The capture bundle could not be written "
                                       + "(OS3D_KERNEL_CAPTURE=0 disables capture entirely).")
            }
            return .ok([
                "path": bundle.path,
                "bodies": analytic.map(\.label),
                "message": "Replayable bundle written. Pull it with scripts/fetch_captures.sh, "
                         + "or promote it to openshape3dTests/Fixtures/Captures as a regression fixture.",
            ])

        case let .screenshot(width, height, format, maxBytes):
            guard let png = viewModel.captureScreenshot(
                width: width, height: height, transparentBackground: false, showGrid: true
            ) else {
                return .failure(500, "Internal Server Error", error: "screenshot_failed",
                                message: "The viewport did not return an image. It has to be on screen "
                                       + "and rendered at least once before it can be captured.")
            }
            guard format == .jpeg else { return .png(png) }
            guard let jpeg = Self.jpeg(fromPNG: png, maxBytes: maxBytes) else {
                return .failure(500, "Internal Server Error", error: "screenshot_failed",
                                message: "The viewport image could not be re-encoded as JPEG.")
            }
            return .image(jpeg, contentType: AgentShotFormat.jpeg.contentType)

        default:
            return nil
        }
    }

    // MARK: - Screenshot encoding

    /// A JPEG of the rendered PNG that fits `maxBytes`: quality first, then
    /// the image is shrunk. An MCP client shows the picture in a chat, where
    /// a fixed cap on the tool result (1 MB in Claude Desktop) beats pixels.
    nonisolated static func jpeg(fromPNG png: Data, maxBytes: Int?) -> Data? {
        guard var image = UIImage(data: png) else { return nil }
        var quality: CGFloat = 0.85
        for _ in 0..<6 {
            guard let data = image.jpegData(compressionQuality: quality) else { return nil }
            guard let budget = maxBytes, data.count > budget else { return data }
            if quality > 0.6 {
                quality = 0.6
            } else {
                let factor = max(0.35, sqrt(Double(budget) / Double(data.count)) * 0.95)
                let size = CGSize(width: (image.size.width * factor).rounded(),
                                  height: (image.size.height * factor).rounded())
                // Scale 1: one point per pixel. The default format takes the
                // screen's scale, which would double the pixels on a Retina
                // Mac and undo the shrink.
                let format = UIGraphicsImageRendererFormat()
                format.scale = 1
                format.opaque = true
                let renderer = UIGraphicsImageRenderer(size: size, format: format)
                image = renderer.image { _ in image.draw(in: CGRect(origin: .zero, size: size)) }
            }
        }
        return image.jpegData(compressionQuality: 0.5)
    }
}
