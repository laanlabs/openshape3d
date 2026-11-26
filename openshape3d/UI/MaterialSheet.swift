//
//  MaterialSheet.swift
//  openshape3d
//
//  Body material dialog (plan §B15): preset grid + custom color picker +
//  metallic/roughness/opacity/glow sliders, and texture mapping — a pattern
//  (wood grain, brushed, carbon fibre…) or a picture of your own, with its
//  size and rotation. Apply commits one SetMaterialCommand over the whole
//  selection (EditorViewModel.applyMaterial).
//

import PhotosUI
import SwiftUI
import UniformTypeIdentifiers

struct MaterialSheet: View {
    @State private var color: Color
    @State private var metallic: Double
    @State private var roughness: Double
    @State private var opacity: Double
    @State private var emission: Double
    @State private var pattern: MaterialPattern
    @State private var patternSize: Double
    @State private var patternRotation: Double
    /// The `.image` pattern's picture, and an imported mesh's own texture
    /// (laid on through its texcoords), kept apart: choosing a pattern must
    /// not turn one into the other.
    @State private var image: Data?
    private let meshTexture: Data?
    @State private var showImagePhotos = false
    @State private var imagePhotoItem: PhotosPickerItem?
    @State private var showImageFiles = false
    @State private var imageError = false

    @Environment(\.dismiss) private var dismiss
    let onApply: (BodyMaterialSpec) -> Void

    init(initial: BodyMaterialSpec, onApply: @escaping (BodyMaterialSpec) -> Void) {
        let spec = initial.clamped
        _color = State(initialValue: Color(
            red: spec.baseColor.x, green: spec.baseColor.y, blue: spec.baseColor.z
        ))
        _metallic = State(initialValue: spec.metallic)
        _roughness = State(initialValue: spec.roughness)
        _opacity = State(initialValue: spec.baseColor.w)
        _emission = State(initialValue: spec.emission)
        _pattern = State(initialValue: spec.pattern)
        _patternSize = State(initialValue: spec.patternSize)
        _patternRotation = State(initialValue: spec.patternRotation)
        _image = State(initialValue: spec.pattern == .image ? spec.baseColorTexture : nil)
        meshTexture = spec.pattern == .image ? nil : spec.baseColorTexture
        self.onApply = onApply
    }

    private static let gridColumns = [GridItem(.adaptive(minimum: 74), spacing: 10)]

    var body: some View {
        NavigationStack {
            Form {
                Section("Presets") {
                    LazyVGrid(columns: Self.gridColumns, spacing: 10) {
                        ForEach(MaterialPreset.library) { preset in
                            presetSwatch(preset)
                        }
                    }
                    .padding(.vertical, 4)
                }
                Section("Custom") {
                    ColorPicker("Color", selection: $color, supportsOpacity: false)
                        .accessibilityIdentifier("MaterialColorPicker")
                    sliderRow(
                        "Metallic", value: $metallic,
                        sliderID: "MaterialMetallicSlider",
                        valueID: "MaterialMetallicValue"
                    )
                    sliderRow(
                        "Roughness", value: $roughness,
                        sliderID: "MaterialRoughnessSlider",
                        valueID: "MaterialRoughnessValue"
                    )
                    sliderRow(
                        "Opacity", value: $opacity,
                        sliderID: "MaterialOpacitySlider",
                        valueID: "MaterialOpacityValue"
                    )
                    sliderRow(
                        "Glow", value: $emission,
                        sliderID: "MaterialGlowSlider",
                        valueID: "MaterialGlowValue"
                    )
                }
                Section("Texture Mapping") {
                    Picker("Pattern", selection: Binding(get: { pattern }, set: { next in
                        // A new pattern starts at its own size.
                        if next != pattern { patternSize = next.defaultSize }
                        pattern = next
                    })) {
                        ForEach(MaterialPattern.allCases, id: \.self) { Text($0.title).tag($0) }
                    }
                    .accessibilityIdentifier("MaterialPatternPicker")
                    if pattern == .image { imageRow }
                    if pattern != .none {
                        HStack {
                            Text("Size")
                            Slider(value: Binding(get: { log10(patternSize) }, set: { patternSize = DecalKit.tidyWidth(pow(10, $0)) }),
                                   in: log10(MaterialPattern.sizeRange.lowerBound)...log10(MaterialPattern.sizeRange.upperBound))
                                .accessibilityIdentifier("MaterialPatternSize")
                            Text(AppSettings.shared.unit.compactLengthString(fromMM: patternSize))
                                .font(.callout.monospacedDigit())
                                .foregroundStyle(.secondary)
                                .frame(minWidth: 60, alignment: .trailing)
                        }
                        HStack {
                            Text("Rotation")
                            Slider(value: $patternRotation, in: -180...180, step: 1)
                                .accessibilityIdentifier("MaterialPatternRotation")
                            Text("\(Int(patternRotation.rounded()))°")
                                .font(.callout.monospacedDigit())
                                .foregroundStyle(.secondary)
                                .frame(minWidth: 44, alignment: .trailing)
                        }
                    }
                }
            }
            .navigationTitle("Material")
            .onDisappear { MacWindowTitle.restore() }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .accessibilityIdentifier("MaterialCancel")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        onApply(currentSpec)
                        dismiss()
                    }
                    .disabled(pattern == .image && image == nil)
                    .accessibilityIdentifier("MaterialApply")
                }
            }
        }
        .presentationDetents([.medium, .large])
        .photosPicker(isPresented: $showImagePhotos, selection: $imagePhotoItem, matching: .images)
        .onChange(of: imagePhotoItem) { _, item in
            guard let item else { return }
            imagePhotoItem = nil
            Task { setImage(try? await item.loadTransferable(type: Data.self)) }
        }
        .fileImporter(isPresented: $showImageFiles, allowedContentTypes: [.png, .jpeg, .image]) { result in
            guard case .success(let url) = result else { return }
            let scoped = url.startAccessingSecurityScopedResource()
            defer { if scoped { url.stopAccessingSecurityScopedResource() } }
            setImage(try? Data(contentsOf: url))
        }
        .alert("Couldn't read the selected image.", isPresented: $imageError) { Button("OK", role: .cancel) {} }
    }

    /// Texture Mapping ▸ Image: the picture, and where to get another.
    @ViewBuilder
    private var imageRow: some View {
        HStack {
            if let image, let picture = UIImage(data: image) {
                Image(uiImage: picture)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 44, height: 44)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .accessibilityIdentifier("MaterialImagePreview")
            } else {
                Text("Choose a picture to lay on the part.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Menu(image == nil ? "Choose Image…" : "Replace…") {
                Button("Photos") { pickImage(fromPhotos: true) }
                Button("Files") { pickImage(fromPhotos: false) }
            }
            .accessibilityIdentifier("MaterialChooseImage")
        }
    }

    private func pickImage(fromPhotos: Bool) {
        // The system pickers can't be driven by XCUITest:
        // OS3D_DEBUG_MATERIAL_IMAGE stands the debug seed picture in.
        #if DEBUG
        if ProcessInfo.processInfo.environment["OS3D_DEBUG_MATERIAL_IMAGE"] != nil {
            setImage(EditorViewModel.debugSeedImagePNG)
            return
        }
        #endif
        if fromPhotos { showImagePhotos = true } else { showImageFiles = true }
    }

    private func setImage(_ data: Data?) {
        guard let data, let prepared = MaterialImage.prepare(data) else {
            imageError = true
            return
        }
        // A first picture shows as it is: white leaves it untinted.
        if image == nil { color = .white }
        image = prepared
    }

    private func presetSwatch(_ preset: MaterialPreset) -> some View {
        Button {
            let spec = preset.spec
            color = Color(
                red: spec.baseColor.x, green: spec.baseColor.y, blue: spec.baseColor.z
            )
            metallic = spec.metallic
            roughness = spec.roughness
            opacity = spec.baseColor.w
            emission = spec.emission
            pattern = spec.pattern
            patternSize = spec.patternSize
            patternRotation = spec.patternRotation
        } label: {
            VStack(spacing: 4) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(
                        red: preset.spec.baseColor.x,
                        green: preset.spec.baseColor.y,
                        blue: preset.spec.baseColor.z
                    ))
                    .frame(height: 34)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(Color.primary.opacity(0.15))
                    )
                Text(preset.name)
                    .font(.caption2)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(
            "MaterialPreset\(preset.name.replacingOccurrences(of: " ", with: ""))"
        )
    }

    private func sliderRow(
        _ title: String, value: Binding<Double>, sliderID: String, valueID: String
    ) -> some View {
        HStack {
            Text(title)
            Slider(value: value, in: 0...1)
                .accessibilityIdentifier(sliderID)
            Text("\(Int((value.wrappedValue * 100).rounded()))%")
                .font(.callout.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(minWidth: 44, alignment: .trailing)
                .accessibilityIdentifier(valueID)
        }
    }

    /// The sheet state as a model spec (sRGB components from the picker).
    private var currentSpec: BodyMaterialSpec {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 1
        UIColor(color).getRed(&r, green: &g, blue: &b, alpha: &a)
        return BodyMaterialSpec(
            baseColor: SIMD4(Double(r), Double(g), Double(b), max(opacity, 0.05)),
            metallic: metallic,
            roughness: roughness,
            baseColorTexture: pattern == .image ? image : meshTexture,
            emission: emission,
            pattern: pattern,
            patternSize: patternSize,
            patternRotation: patternRotation
        ).clamped
    }
}

/// A picked picture made ready to be a material's image (spec §14 texture
/// mapping): at most `maxPixels` on a side — a tiled texture needs no more,
/// and it is stored in every body that wears it — as JPEG, or PNG when it
/// has transparency.
enum MaterialImage {
    static let maxPixels: CGFloat = 1024

    static func prepare(_ data: Data) -> Data? {
        guard let image = UIImage(data: data), let cg = image.cgImage, image.size.width > 0, image.size.height > 0 else {
            return nil
        }
        let pixels = CGSize(width: image.size.width * image.scale, height: image.size.height * image.scale)
        let scale = min(1, maxPixels / max(pixels.width, pixels.height))
        let target = CGSize(width: max(1, (pixels.width * scale).rounded()), height: max(1, (pixels.height * scale).rounded()))
        let alpha = cg.alphaInfo
        let opaque = alpha == .none || alpha == .noneSkipFirst || alpha == .noneSkipLast
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = opaque
        let renderer = UIGraphicsImageRenderer(size: target, format: format)
        let draw: (UIGraphicsImageRendererContext) -> Void = { _ in image.draw(in: CGRect(origin: .zero, size: target)) }
        return opaque ? renderer.jpegData(withCompressionQuality: 0.85, actions: draw) : renderer.pngData(actions: draw)
    }
}
