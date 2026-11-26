//
//  WelcomeView.swift
//  openshape3d
//
//  First-launch welcome (and Gallery › Welcome… afterwards): what the app is,
//  the three things it does, and the bundled sample designs as the fastest way
//  in. Two exits — install the samples and open the Demos folder, or start a
//  blank design — plus a plain Close. The sheet marks itself seen on appear.
//

import SwiftUI

struct WelcomeView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var sizeClass

    let samples: [SampleDesigns.Sample]
    let onAddSamples: () -> Void
    let onNewDesign: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    header
                    features
                    if !samples.isEmpty { sampleList }
                }
                .padding(.horizontal, sizeClass == .regular ? 40 : 20)
                .padding(.top, 12)
                .padding(.bottom, 16)
                .frame(maxWidth: 640)
                .frame(maxWidth: .infinity)
            }
            // Pinned, so the way in is on screen without scrolling — on a
            // phone the feature list alone fills the first screen.
            .safeAreaInset(edge: .bottom) {
                actions
                    .padding(.horizontal, sizeClass == .regular ? 40 : 20)
                    .padding(.top, 12)
                    .padding(.bottom, 8)
                    .frame(maxWidth: 640)
                    .frame(maxWidth: .infinity)
                    .background(.bar)
            }
            .defaultScrollAnchor(.top)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .accessibilityIdentifier("WelcomeCloseButton")
                }
            }
        }
        .pageSized()
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("WelcomeView")
    }

    // MARK: Sections

    private var header: some View {
        VStack(spacing: 14) {
            appIcon
                .frame(width: 96, height: 96)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .shadow(color: .black.opacity(0.18), radius: 10, y: 4)
            Text("Welcome to OpenShape 3D")
                .font(.largeTitle.weight(.bold))
                .multilineTextAlignment(.center)
            Text("Free, open-source solid modeling on a true B-rep kernel. "
                 + "Sketch with exact dimensions, push and pull real solids, "
                 + "and keep every step editable.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    @ViewBuilder
    private var appIcon: some View {
        if let image = UIImage(named: "AppIcon") {
            Image(uiImage: image).resizable()
        } else {
            ZStack {
                RoundedRectangle(cornerRadius: 22, style: .continuous).fill(Color.accentColor)
                Image(systemName: "cube.transparent")
                    .font(.system(size: 48, weight: .medium))
                    .foregroundStyle(.white)
            }
        }
    }

    private var features: some View {
        VStack(alignment: .leading, spacing: 18) {
            FeatureRow(systemImage: "pencil.and.ruler",
                       title: "Sketch precisely",
                       detail: "Lines, arcs, splines and constraints that hold. Type a dimension and the sketch follows.")
            FeatureRow(systemImage: "cube",
                       title: "Model real solids",
                       detail: "Extrude, revolve, sweep, loft, fillet, shell and boolean on analytic B-rep geometry.")
            FeatureRow(systemImage: "clock.arrow.circlepath",
                       title: "Change anything, any time",
                       detail: "Every feature stays in the history. Edit a radius and the whole model rebuilds.")
            FeatureRow(systemImage: "square.and.arrow.up",
                       title: "Your files stay yours",
                       detail: "Export STEP, STL, 3MF, OBJ and DXF. No account, no cloud, no subscription.")
        }
    }

    private var sampleList: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Sample Designs")
                .font(.headline)
            Text("Open one to see how a part is built. They go into a “\(SampleDesigns.folderName)” folder in your gallery.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            VStack(spacing: 0) {
                ForEach(samples) { sample in
                    SampleRow(sample: sample)
                    if sample != samples.last { Divider().padding(.leading, 76) }
                }
            }
            .background(.quaternary.opacity(0.4), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    private var actions: some View {
        VStack(spacing: 12) {
            if !samples.isEmpty {
                Button {
                    dismiss()
                    onAddSamples()
                } label: {
                    Label("Add Sample Designs", systemImage: "shippingbox")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .accessibilityIdentifier("WelcomeAddSamplesButton")
            }
            Button {
                dismiss()
                onNewDesign()
            } label: {
                Label("Start a Blank Design", systemImage: "plus")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .accessibilityIdentifier("WelcomeNewDesignButton")
        }
    }
}

private extension View {
    /// A page-sized sheet on the iPad: the default form sheet is too short
    /// for the feature list and the samples together. iOS 17 keeps the form.
    @ViewBuilder
    func pageSized() -> some View {
        if #available(iOS 18.0, *) {
            presentationSizing(.page)
        } else {
            self
        }
    }
}

// MARK: - Rows

private struct FeatureRow: View {
    let systemImage: String
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: systemImage)
                .font(.title2)
                .foregroundStyle(Color.accentColor)
                .frame(width: 36, height: 36)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.headline)
                Text(detail).font(.subheadline).foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

private struct SampleRow: View {
    let sample: SampleDesigns.Sample

    var body: some View {
        HStack(spacing: 14) {
            thumbnail
                .frame(width: 52, height: 52)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(sample.name).font(.body.weight(.medium))
                Text(sample.blurb).font(.caption).foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("WelcomeSample-\(sample.id)")
    }

    @ViewBuilder
    private var thumbnail: some View {
        if let url = SampleDesigns.thumbnailURL(for: sample),
           let image = UIImage(contentsOfFile: url.path) {
            Image(uiImage: image).resizable().scaledToFill()
        } else {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.accentColor.opacity(0.12))
                Image(systemName: sample.systemImage)
                    .font(.title3)
                    .foregroundStyle(Color.accentColor)
            }
        }
    }
}
