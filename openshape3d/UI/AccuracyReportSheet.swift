//
//  AccuracyReportSheet.swift
//  openshape3d
//
//  Views ▸ Accuracy Report…: how closely one body matches another — a part
//  modelled over a 3D scan against the scan itself, a rebuild against the
//  original. The sheet picks the two bodies, runs `AccuracyKit` off the main
//  thread, and shows the orthographic overlays (the reference silhouette
//  filled, the model's outline over it), the surface-deviation numbers and
//  histograms, and a plain-English summary. The same drawing code renders
//  the picture `/v1/accuracy/image` and the `accuracy.image` MCP op return.
//

import SwiftUI
import UIKit

// MARK: - Drawing an overlay

/// Where an overlay's view millimetres land in a picture of `size` points:
/// the union of both silhouettes fitted with a margin, Y up.
nonisolated struct AccuracyOverlayLayout: Sendable {
    let overlay: SilhouetteOverlay
    let size: CGSize
    let scale: Double          // points per mm
    let originPt: SIMD2<Double>

    static let headerHeight: CGFloat = 44
    static let margin: CGFloat = 18

    init(overlay: SilhouetteOverlay, size: CGSize) {
        self.overlay = overlay
        self.size = size
        let widthMM = Double(overlay.width) * overlay.pixelMM
        let heightMM = Double(overlay.height) * overlay.pixelMM
        let availableW = Double(size.width) - 2 * Double(Self.margin)
        let availableH = Double(size.height) - Double(Self.headerHeight) - 2 * Double(Self.margin)
        let s = max(min(availableW / max(widthMM, 1e-9), availableH / max(heightMM, 1e-9)), 1e-9)
        scale = s
        // Centre the drawing in the space under the header.
        let drawnW = widthMM * s, drawnH = heightMM * s
        let left = Double(Self.margin) + (availableW - drawnW) / 2
        let bottom = Double(size.height) - Double(Self.margin) - (availableH - drawnH) / 2
        originPt = SIMD2(left, bottom)
    }

    /// View mm → points (Y flipped: the picture's rows go down).
    func point(_ p: SIMD2<Double>) -> CGPoint {
        let local = p - overlay.origin
        return CGPoint(x: originPt.x + local.x * scale, y: originPt.y - local.y * scale)
    }

    func path(for outlines: [AccuracyOutline]) -> CGPath {
        let path = CGMutablePath()
        for loop in outlines where loop.points.count >= 3 {
            path.move(to: point(loop.points[0]))
            for p in loop.points.dropFirst() { path.addLine(to: point(p)) }
            path.closeSubpath()
        }
        return path
    }

    /// A round scale-bar length in mm that fits a quarter of the width.
    var scaleBarMM: Double {
        let target = (Double(size.width) * 0.22) / scale
        let candidates: [Double] = [0.5, 1, 2, 5, 10, 20, 50, 100, 200, 500, 1000]
        return candidates.last(where: { $0 <= target }) ?? candidates[0]
    }
}

/// The colours every overlay uses, on every platform that draws one.
nonisolated enum AccuracyPalette {
    static let referenceFill = (r: 0.22, g: 0.56, b: 0.96, a: 0.32)
    static let referenceLine = (r: 0.16, g: 0.44, b: 0.86, a: 1.0)
    static let modelFill = (r: 0.98, g: 0.55, b: 0.18, a: 0.22)
    static let modelLine = (r: 0.90, g: 0.40, b: 0.05, a: 1.0)
}

nonisolated enum AccuracyOverlayRenderer {

    /// A PNG of one overlay: reference silhouette filled, model outline over
    /// it, the view's numbers in a header, a scale bar. `width` pixels; the
    /// height follows the silhouettes' aspect.
    static func png(overlay: SilhouetteOverlay, report: AccuracyReport, width: Int) -> Data? {
        let w = CGFloat(max(width, 64))
        let aspect = Double(overlay.height) / Double(max(overlay.width, 1))
        let h = (w - 2 * AccuracyOverlayLayout.margin) * CGFloat(aspect) + AccuracyOverlayLayout.headerHeight
            + 2 * AccuracyOverlayLayout.margin
        let size = CGSize(width: w, height: min(max(h, 160), 4096))
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        return UIGraphicsImageRenderer(size: size, format: format).pngData { context in
            draw(overlay: overlay, report: report, in: context.cgContext, size: size)
        }
    }

    static func draw(overlay: SilhouetteOverlay, report: AccuracyReport, in cg: CGContext, size: CGSize) {
        cg.setFillColor(UIColor.white.cgColor)
        cg.fill(CGRect(origin: .zero, size: size))
        let layout = AccuracyOverlayLayout(overlay: overlay, size: size)

        let rf = AccuracyPalette.referenceFill, rl = AccuracyPalette.referenceLine
        let mf = AccuracyPalette.modelFill, ml = AccuracyPalette.modelLine
        let reference = layout.path(for: overlay.referenceOutlines)
        let model = layout.path(for: overlay.modelOutlines)
        cg.addPath(reference)
        cg.setFillColor(CGColor(red: rf.r, green: rf.g, blue: rf.b, alpha: rf.a))
        cg.fillPath(using: .evenOdd)
        cg.addPath(model)
        cg.setFillColor(CGColor(red: mf.r, green: mf.g, blue: mf.b, alpha: mf.a))
        cg.fillPath(using: .evenOdd)
        cg.setLineJoin(.round)
        cg.addPath(reference)
        cg.setStrokeColor(CGColor(red: rl.r, green: rl.g, blue: rl.b, alpha: rl.a))
        cg.setLineWidth(1.2)
        cg.strokePath()
        cg.addPath(model)
        cg.setStrokeColor(CGColor(red: ml.r, green: ml.g, blue: ml.b, alpha: ml.a))
        cg.setLineWidth(2)
        cg.strokePath()

        // Header: view, IoU, outline deviation; legend swatches.
        let title = "\(overlay.view.title) view"
        let numbers = String(format: "overlap %.1f%%   outline mean %.2f mm   95%% within %.2f mm",
                             overlay.iou * 100, overlay.boundaryMeanMM, overlay.boundaryP95MM)
        text(title, at: CGPoint(x: 18, y: 12), size: 17, bold: true, color: .black)
        text(numbers, at: CGPoint(x: 18, y: 34), size: 12, bold: false, color: .darkGray)
        let legendY: CGFloat = 12
        var x = size.width - 18
        for (label, color) in [("model", ml), ("reference", rl)].reversed() {
            let width = textWidth(label, size: 12)
            x -= width
            text(label, at: CGPoint(x: x, y: legendY), size: 12, bold: false, color: .darkGray)
            x -= 16
            cg.setFillColor(CGColor(red: color.r, green: color.g, blue: color.b, alpha: 1))
            cg.fill(CGRect(x: x, y: legendY + 3, width: 11, height: 11))
            x -= 14
        }
        // Scale bar, bottom-left.
        let barMM = layout.scaleBarMM
        let barPt = CGFloat(barMM * layout.scale)
        let barY = size.height - 10
        cg.setStrokeColor(UIColor.darkGray.cgColor)
        cg.setLineWidth(2)
        cg.move(to: CGPoint(x: 18, y: barY))
        cg.addLine(to: CGPoint(x: 18 + barPt, y: barY))
        cg.strokePath()
        text(barMM >= 1 ? "\(Int(barMM)) mm" : String(format: "%.1f mm", barMM),
             at: CGPoint(x: 18 + barPt + 6, y: barY - 8), size: 11, bold: false, color: .darkGray)
    }

    private static func text(_ string: String, at point: CGPoint, size: CGFloat, bold: Bool, color: UIColor) {
        let font = bold ? UIFont.boldSystemFont(ofSize: size) : UIFont.systemFont(ofSize: size)
        NSAttributedString(string: string, attributes: [.font: font, .foregroundColor: color]).draw(at: point)
    }

    private static func textWidth(_ string: String, size: CGFloat) -> CGFloat {
        NSAttributedString(string: string, attributes: [.font: UIFont.systemFont(ofSize: size)]).size().width
    }
}

// MARK: - The sheet

/// A taller sheet where the system offers one (iOS 18's page sizing): the
/// report's first overlay then fits above the fold.
struct PageSheetSizing: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 18.0, *) {
            content.presentationSizing(.page)
        } else {
            content
        }
    }
}

struct AccuracyReportSheet: View {
    @Bindable var viewModel: EditorViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var referenceID: BodyID?
    @State private var modelID: BodyID?
    @State private var alignment: AccuracyAlignment = .none
    @State private var toleranceMM: Double = 1
    @State private var allSixViews = false
    @State private var report: AccuracyReport?
    @State private var computing = false
    @State private var problem: String?
    @State private var shareURL: URL?
    @State private var copied = false

    private var bodies: [Body] { viewModel.session.document.bodies }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    bodyPicker("Reference", selection: $referenceID, identifier: "AccuracyReferencePicker")
                    bodyPicker("Model", selection: $modelID, identifier: "AccuracyModelPicker")
                    Picker("Alignment", selection: $alignment) {
                        ForEach(AccuracyAlignment.allCases, id: \.self) { Text($0.title).tag($0) }
                    }
                    .accessibilityIdentifier("AccuracyAlignmentPicker")
                    HStack {
                        Text("Tolerance")
                        Spacer()
                        Stepper(value: $toleranceMM, in: 0.05...50, step: toleranceMM < 1 ? 0.05 : 0.5) {
                            Text(String(format: "%.2f mm", toleranceMM)).monospacedDigit()
                        }
                        .accessibilityIdentifier("AccuracyToleranceStepper")
                    }
                    Toggle("All six views", isOn: $allSixViews)
                    Button {
                        compare()
                    } label: {
                        HStack {
                            Text(report == nil ? "Compare" : "Compare Again")
                            if computing { Spacer(); ProgressView() }
                        }
                    }
                    .disabled(computing || referenceID == nil || modelID == nil || referenceID == modelID)
                    .accessibilityIdentifier("AccuracyCompareButton")
                } header: {
                    Text("Bodies")
                } footer: {
                    Text("The reference is what the model should match — a scan or the original part. "
                         + "Outlines are compared view by view; the surfaces point by point, both ways.")
                }
                if let problem {
                    Section { Text(problem).foregroundStyle(.red) }
                }
                if let report {
                    Section {
                        Button {
                            guard let referenceID, let modelID else { return }
                            let tolerance = toleranceMM
                            dismiss()
                            Task { await viewModel.showDeviationPreview(reference: referenceID, model: modelID,
                                                                       toleranceMM: tolerance) }
                        } label: {
                            Label("Show Deviation in Viewport", systemImage: "paintpalette")
                        }
                        .accessibilityIdentifier("AccuracyShowDeviationButton")
                    } footer: {
                        Text("The reference coloured by its distance to the model, on the part itself: "
                             + "blue where the model is missing material, orange where it has too much, grey within tolerance.")
                    }
                    results(report)
                }
            }
            .navigationTitle("Accuracy Report")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
                if let report {
                    ToolbarItem(placement: .primaryAction) {
                        Menu {
                            Button("Share Report Image…") { shareImage(report) }
                            Button(copied ? "Copied" : "Copy Summary") {
                                UIPasteboard.general.string = report.summary
                                copied = true
                            }
                            Button("Copy JSON") {
                                if let data = try? JSONEncoder().encode(report.wire) {
                                    UIPasteboard.general.string = String(decoding: data, as: UTF8.self)
                                    copied = true
                                }
                            }
                        } label: {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }
                        .accessibilityIdentifier("AccuracyShareMenu")
                    }
                }
            }
            .sheet(item: Binding(get: { shareURL.map { SlicerShare(url: $0) } },
                                 set: { shareURL = $0?.url })) { share in
                ActivityShareSheet(items: [share.url])
            }
        }
        .onAppear {
            pickDefaults()
            runRequest()
        }
        .onChange(of: viewModel.accuracyReportRequest) { _, _ in runRequest() }
    }

    /// A comparison the agent bridge asked for (`view.accuracyReport`): pick
    /// its bodies and compare at once.
    private func runRequest() {
        guard let request = viewModel.accuracyReportRequest else { return }
        viewModel.accuracyReportRequest = nil
        referenceID = request.reference
        modelID = request.model
        toleranceMM = request.toleranceMM
        compare()
    }

    private func bodyPicker(_ title: String, selection: Binding<BodyID?>, identifier: String) -> some View {
        Picker(title, selection: selection) {
            Text("Choose…").tag(BodyID?.none)
            ForEach(bodies) { body in
                Text(body.name + (body.brep == nil ? "  (mesh)" : "")).tag(BodyID?.some(body.id))
            }
        }
        .accessibilityIdentifier(identifier)
    }

    /// Two selected bodies win; otherwise the first mesh-only body is the
    /// reference (a scan has no B-rep) and the first analytic body the model.
    private func pickDefaults() {
        guard referenceID == nil, modelID == nil else { return }
        let selected = bodies.filter { viewModel.selection.contains($0.id) }.map(\.id)
        if selected.count >= 2 {
            referenceID = selected[0]
            modelID = selected[1]
            return
        }
        referenceID = bodies.first(where: { $0.brep == nil })?.id ?? bodies.first?.id
        modelID = bodies.first(where: { $0.brep != nil && $0.id != referenceID })?.id
            ?? bodies.first(where: { $0.id != referenceID })?.id
    }

    private func compare() {
        guard let referenceID, let modelID,
              let reference = bodies.first(where: { $0.id == referenceID }),
              let model = bodies.first(where: { $0.id == modelID }) else { return }
        let referenceMesh = AccuracyMesh(body: reference)
        let modelMesh = AccuracyMesh(body: model)
        let options = AccuracyOptions(
            views: allSixViews ? [.front, .top, .right, .back, .bottom, .left] : [.front, .top, .right],
            toleranceMM: toleranceMM, alignment: alignment)
        computing = true
        problem = nil
        copied = false
        Task.detached(priority: .userInitiated) {
            let result = AccuracyKit.compare(reference: referenceMesh, model: modelMesh, options: options)
            await MainActor.run {
                computing = false
                if let result {
                    report = result
                } else {
                    problem = "These bodies have no geometry to compare."
                }
            }
        }
    }

    @ViewBuilder
    private func results(_ report: AccuracyReport) -> some View {
        // The pictures first: an overlay says more at a glance than the
        // paragraph, and on a sheet the first section is the one seen.
        ForEach(report.overlays, id: \.view) { overlay in
            Section {
                AccuracyOverlayView(overlay: overlay, report: report)
                    .frame(height: 320)
                    .listRowInsets(EdgeInsets())
                LabeledContent("Overlap (IoU)", value: String(format: "%.1f%%", overlay.iou * 100))
                LabeledContent("Outline deviation",
                               value: String(format: "mean %.2f · 95%% %.2f · max %.2f mm",
                                             overlay.boundaryMeanMM, overlay.boundaryP95MM, overlay.boundaryMaxMM))
                LabeledContent("Area reference / model",
                               value: String(format: "%.0f / %.0f mm²", overlay.referenceAreaMM2, overlay.modelAreaMM2))
                LabeledContent("Missing / excess",
                               value: String(format: "%.0f / %.0f mm²", overlay.missingAreaMM2, overlay.excessAreaMM2))
            } header: {
                overlay.view == report.overlays.first?.view
                    ? Text(String(format: "Overlap %.1f%% · %@ view", report.overallIoU * 100, overlay.view.title))
                    : Text("\(overlay.view.title) view")
            }
        }
        Section("In words") {
            Text(report.summary)
                .font(.callout)
                .accessibilityIdentifier("AccuracySummary")
        }
        deviationSection("Reference → model", report.referenceToModel, tolerance: report.options.toleranceMM)
        deviationSection("Model → reference", report.modelToReference, tolerance: report.options.toleranceMM)
        Section("Size and volume") {
            let r = report.referenceBounds.max - report.referenceBounds.min
            let m = report.modelBounds.max - report.modelBounds.min
            LabeledContent("Reference", value: String(format: "%.1f × %.1f × %.1f mm", r.x, r.y, r.z))
            LabeledContent("Model", value: String(format: "%.1f × %.1f × %.1f mm", m.x, m.y, m.z))
            let d = report.extentDeltaMM
            LabeledContent("Difference", value: String(format: "%+.1f × %+.1f × %+.1f mm", d.x, d.y, d.z))
            LabeledContent("Volume reference",
                           value: report.referenceWatertight
                               ? String(format: "%.0f mm³", report.referenceVolumeMM3) : "open mesh")
            LabeledContent("Volume model",
                           value: report.modelWatertight
                               ? String(format: "%.0f mm³", report.modelVolumeMM3) : "open mesh")
            if report.appliedTranslation != .zero {
                let t = report.appliedTranslation
                LabeledContent("Model moved by", value: String(format: "%.1f, %.1f, %.1f mm", t.x, t.y, t.z))
            }
        }
    }

    private func deviationSection(_ title: String, _ stats: DeviationStats, tolerance: Double) -> some View {
        Section(title) {
            LabeledContent("Mean / RMS", value: String(format: "%.2f / %.2f mm", stats.meanMM, stats.rmsMM))
            LabeledContent("Median / 95% / max",
                           value: String(format: "%.2f / %.2f / %.2f mm", stats.medianMM, stats.p95MM, stats.maxMM))
            LabeledContent(String(format: "Within %.2f mm", tolerance),
                           value: String(format: "%.1f%% of %d points", stats.withinTolerance * 100, stats.samples))
            LabeledContent("Bias", value: String(format: "%+.2f mm", stats.meanSignedMM))
            DeviationHistogramView(stats: stats, tolerance: tolerance)
                .frame(height: 90)
        }
    }

    private func shareImage(_ report: AccuracyReport) {
        let page = AccuracyReportPage(report: report)
        let renderer = ImageRenderer(content: page)
        renderer.scale = 2
        guard let image = renderer.uiImage, let png = image.pngData() else { return }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("Accuracy Report.png")
        do {
            try png.write(to: url, options: .atomic)
            shareURL = url
        } catch {
            problem = "The report image could not be written."
        }
    }
}

/// One overlay drawn live from the report's outlines.
struct AccuracyOverlayView: View {
    let overlay: SilhouetteOverlay
    let report: AccuracyReport

    var body: some View {
        Canvas { context, size in
            let layout = AccuracyOverlayLayout(overlay: overlay, size: size)
            let rf = AccuracyPalette.referenceFill, rl = AccuracyPalette.referenceLine
            let mf = AccuracyPalette.modelFill, ml = AccuracyPalette.modelLine
            let reference = Path(layout.path(for: overlay.referenceOutlines))
            let model = Path(layout.path(for: overlay.modelOutlines))
            context.fill(reference, with: .color(Color(red: rf.r, green: rf.g, blue: rf.b).opacity(rf.a)), style: FillStyle(eoFill: true))
            context.fill(model, with: .color(Color(red: mf.r, green: mf.g, blue: mf.b).opacity(mf.a)), style: FillStyle(eoFill: true))
            context.stroke(reference, with: .color(Color(red: rl.r, green: rl.g, blue: rl.b)), lineWidth: 1.2)
            context.stroke(model, with: .color(Color(red: ml.r, green: ml.g, blue: ml.b)), lineWidth: 2)
            let header = Text("\(overlay.view.title) view").font(.headline)
            context.draw(header, at: CGPoint(x: 18, y: 14), anchor: .leading)
            let numbers = Text(String(format: "overlap %.1f%% · outline mean %.2f mm", overlay.iou * 100, overlay.boundaryMeanMM))
                .font(.caption).foregroundStyle(.secondary)
            context.draw(numbers, at: CGPoint(x: 18, y: 34), anchor: .leading)
            // Scale bar.
            let barMM = layout.scaleBarMM
            let barPt = CGFloat(barMM * layout.scale)
            var bar = Path()
            bar.move(to: CGPoint(x: 18, y: size.height - 12))
            bar.addLine(to: CGPoint(x: 18 + barPt, y: size.height - 12))
            context.stroke(bar, with: .color(.secondary), lineWidth: 2)
            let label = Text(barMM >= 1 ? "\(Int(barMM)) mm" : String(format: "%.1f mm", barMM))
                .font(.caption2).foregroundStyle(.secondary)
            context.draw(label, at: CGPoint(x: 18 + barPt + 6, y: size.height - 12), anchor: .leading)
        }
        .background(Color(uiColor: .systemBackground))
        .accessibilityIdentifier("AccuracyOverlay-\(overlay.view.rawValue)")
    }
}

/// Deviation histogram: bins of distance, the tolerance marked.
struct DeviationHistogramView: View {
    let stats: DeviationStats
    let tolerance: Double

    var body: some View {
        Canvas { context, size in
            let bins = stats.histogram
            guard !bins.isEmpty, let peak = bins.max(), peak > 0 else { return }
            let w = size.width / CGFloat(bins.count)
            for (i, count) in bins.enumerated() {
                let h = size.height * 0.82 * CGFloat(count) / CGFloat(peak)
                let rect = CGRect(x: CGFloat(i) * w + 1, y: size.height - 16 - h, width: max(w - 2, 1), height: h)
                let within = Double(i + 1) * stats.histogramBinMM <= tolerance + 1e-9
                context.fill(Path(rect), with: .color(within ? .green.opacity(0.7) : .orange.opacity(0.7)))
            }
            let tx = CGFloat(tolerance / max(stats.histogramBinMM * Double(bins.count), 1e-9)) * size.width
            if tx <= size.width {
                var line = Path()
                line.move(to: CGPoint(x: tx, y: 0))
                line.addLine(to: CGPoint(x: tx, y: size.height - 16))
                context.stroke(line, with: .color(.secondary), style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
            }
            let axis = Text(String(format: "0 … %.1f mm", stats.histogramBinMM * Double(bins.count)))
                .font(.caption2).foregroundStyle(.secondary)
            context.draw(axis, at: CGPoint(x: 2, y: size.height - 7), anchor: .leading)
        }
    }
}

/// The shareable page: every overlay and the numbers on one tall image.
struct AccuracyReportPage: View {
    let report: AccuracyReport

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Accuracy Report").font(.title.bold())
            Text(report.summary).font(.callout)
            ForEach(report.overlays, id: \.view) { overlay in
                AccuracyOverlayView(overlay: overlay, report: report)
                    .frame(width: 720, height: 420)
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.secondary.opacity(0.3)))
            }
            HStack(alignment: .top, spacing: 24) {
                deviationColumn("Reference → model", report.referenceToModel)
                deviationColumn("Model → reference", report.modelToReference)
            }
        }
        .padding(24)
        .frame(width: 768)
        .background(Color.white)
        .foregroundStyle(Color.black)
    }

    private func deviationColumn(_ title: String, _ stats: DeviationStats) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.headline)
            Text(String(format: "mean %.2f mm · RMS %.2f mm", stats.meanMM, stats.rmsMM)).font(.caption)
            Text(String(format: "95%% within %.2f mm · max %.2f mm", stats.p95MM, stats.maxMM)).font(.caption)
            Text(String(format: "%.1f%% within %.2f mm · bias %+.2f mm",
                        stats.withinTolerance * 100, report.options.toleranceMM, stats.meanSignedMM)).font(.caption)
            DeviationHistogramView(stats: stats, tolerance: report.options.toleranceMM)
                .frame(width: 340, height: 80)
        }
    }
}
