//
//  ExportAppearance.swift
//  openshape3d
//
//  What the exporters need to know about how a design looks (#133): the
//  distinct materials in use, a name for each, and — body by body — which
//  triangles wear which. A body's own material covers it; a face painted
//  with its own material (`Body.faceMaterials`) takes its triangles out of
//  that and into a run of its own.
//
//  A body nobody gave a material has `material == nil` in its run, so each
//  format keeps writing such a body exactly as it did before materials
//  were exported (glTF's stock grey, no `pid` in 3MF, no `usemtl` in OBJ).
//

import Foundation
import simd

nonisolated enum ExportAppearance {

    /// Some of a body's triangles and the one material they wear.
    struct Run: Equatable, Sendable {
        /// Index into `Palette.materials`; nil when the body has no material.
        var material: Int?
        /// Triangle indices into the mesh the palette was built for.
        var triangles: [Int]
    }

    struct Palette: Sendable {
        /// Every distinct material, in the order the bodies first use it.
        var materials: [BodyMaterialSpec] = []
        /// One name per material, unique: the Material sheet's preset name
        /// when the material is one, otherwise "Material 1", "Material 2", …
        var names: [String] = []
        /// Per body, in the order given: its own material's run first (when
        /// any triangle still wears it), then one run per painted material.
        var runs: [[Run]] = []

        /// No body has a material and no face is painted.
        var isPlain: Bool { materials.isEmpty }
    }

    /// The palette of `bodies`. `meshes` replaces a body's render mesh when
    /// the exporter writes a different one (run triangles index into it).
    static func palette(for bodies: [Body], meshes: [RenderMesh]? = nil) -> Palette {
        var palette = Palette()
        func slot(_ spec: BodyMaterialSpec) -> Int {
            if let found = palette.materials.firstIndex(of: spec) { return found }
            palette.materials.append(spec)
            return palette.materials.count - 1
        }

        for (index, body) in bodies.enumerated() {
            let mesh = meshes.flatMap { index < $0.count ? $0[index] : nil } ?? body.render
            let triangleCount = mesh.triangleCount
            guard triangleCount > 0 else { palette.runs.append([]); continue }
            let own = body.material.map(slot)

            // -1: still the body's own; otherwise the painting's slot.
            var painted = [Int](repeating: -1, count: triangleCount)
            var paintOrder: [Int] = []
            if !body.faceMaterials.isEmpty {
                let faces = FaceMaterialKit.resolve(body.faceMaterials, in: mesh)
                for (face, triangles) in zip(body.faceMaterials, faces) where !triangles.isEmpty {
                    let material = slot(face.material)
                    if !paintOrder.contains(material) { paintOrder.append(material) }
                    for t in triangles where t >= 0 && t < triangleCount { painted[t] = material }
                }
            }

            var runs: [Run] = []
            let unpainted = painted.indices.filter { painted[$0] < 0 }
            if !unpainted.isEmpty { runs.append(Run(material: own, triangles: unpainted)) }
            for material in paintOrder {
                // A later painting can cover an earlier one completely.
                let triangles = painted.indices.filter { painted[$0] == material }
                if !triangles.isEmpty { runs.append(Run(material: material, triangles: triangles)) }
            }
            palette.runs.append(runs)
        }

        var taken: Set<String> = []
        var unnamed = 0
        for spec in palette.materials {
            var name = MaterialPreset.library.first(where: { $0.spec == spec })?.name ?? ""
            if name.isEmpty {
                unnamed += 1
                name = "Material \(unnamed)"
            }
            var candidate = name
            var copy = 2
            while taken.contains(candidate) {
                candidate = "\(name) \(copy)"
                copy += 1
            }
            taken.insert(candidate)
            palette.names.append(candidate)
        }
        return palette
    }

    // MARK: - Values as files want them

    /// RGBA with every channel inside 0…1. The colour is written as the app
    /// stores it; the importers read `baseColorFactor`, `Kd` and
    /// `displaycolor` back the same way, so a round trip returns the number.
    static func color(_ spec: BodyMaterialSpec) -> SIMD4<Double> {
        func unit(_ v: Double) -> Double { v.isFinite ? min(max(v, 0), 1) : 0 }
        return SIMD4(unit(spec.baseColor.x), unit(spec.baseColor.y), unit(spec.baseColor.z), unit(spec.baseColor.w))
    }

    static func metallic(_ spec: BodyMaterialSpec) -> Double {
        spec.metallic.isFinite ? min(max(spec.metallic, 0), 1) : 0
    }

    /// Roughness for a PBR file. In the app 0 means "the classic highlight",
    /// which is nothing like the mirror 0 is in glTF or USD: that case is
    /// written as a middling 0.5.
    static func roughness(_ spec: BodyMaterialSpec) -> Double {
        guard spec.roughness.isFinite, spec.roughness > 0 else { return 0.5 }
        return min(spec.roughness, 1)
    }

    /// How strongly the surface glows, 0…1.
    static func glow(_ spec: BodyMaterialSpec) -> Double {
        spec.emission.isFinite ? min(max(spec.emission, 0), 1) : 0
    }

    /// `#RRGGBB`, with `AA` appended when the colour is not opaque.
    static func hex(_ spec: BodyMaterialSpec) -> String {
        let c = color(spec)
        let digits = Array("0123456789ABCDEF")
        func pair(_ v: Double) -> String {
            let byte = Int((v * 255).rounded())
            return String([digits[byte >> 4], digits[byte & 15]])
        }
        return "#" + pair(c.x) + pair(c.y) + pair(c.z) + (c.w < 1 ? pair(c.w) : "")
    }

    /// `text` safe inside a double-quoted XML attribute.
    static func xmlAttribute(_ text: String) -> String {
        var out = ""
        out.reserveCapacity(text.count)
        for scalar in text.unicodeScalars {
            switch scalar {
            case "&": out += "&amp;"
            case "<": out += "&lt;"
            case ">": out += "&gt;"
            case "\"": out += "&quot;"
            case "\n": out += "&#10;"
            case "\t": out += "&#9;"
            default:
                // XML 1.0 forbids the other control characters outright.
                if scalar.value >= 0x20 { out.unicodeScalars.append(scalar) }
            }
        }
        return out
    }
}
