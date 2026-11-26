//
//  USDZExporter.swift
//  openshape3d
//
//  USDZ export, written directly: a text USD layer (`.usda`) in an
//  uncompressed, 64-byte-aligned zip, which is all a .usdz package is.
//
//  It used to go through ModelIO's `MDLAsset.export(to:)`, which cannot
//  write .usdz on a Mac or in the simulator (#137: the Export entry and AR
//  Preview were simply missing there) and wrote every body without a
//  material. Writing the layer here works on every platform, and carries:
//    • one Mesh per body, named after it (`displayName` keeps the exact
//      name; the prim name is the identifier USD requires);
//    • the body's material and each painted face's as UsdPreviewSurface
//      (colour, metallic, roughness, opacity, glow), one Mesh per material a
//      body wears (`ExportAppearance`), bound to shared Material prims; a
//      body with no material gets the stock grey;
//    • `metersPerUnit = 0.001`, so AR Quick Look shows a 20 mm part at
//      20 mm instead of 20 m, and the importer reads the unit back.
//  Transforms are baked into world space, as in the other exporters.
//  Image textures and patterns are not written.
//

import Foundation
import simd

nonisolated enum USDZExporter {

    /// Always true since the package is written here; kept because the UI
    /// asks before offering the format.
    static var isSupported: Bool { true }

    /// The layer's file name inside the package.
    static let layerName = "model.usda"

    /// USDZ archive bytes, or nil when no body has triangles.
    static func usdz(bodies: [Body]) -> Data? {
        guard let layer = usda(bodies: bodies) else { return nil }
        var zip = MinimalZipWriter()
        // The first file is the package's default layer; USDZ wants every
        // file's bytes on a 64-byte boundary so they can be mapped in place.
        zip.addFile(path: layerName, data: Data(layer.utf8), alignment: 64)
        return zip.finish()
    }

    /// The text layer, or nil when no body has triangles.
    static func usda(bodies: [Body]) -> String? {
        let palette = ExportAppearance.palette(for: bodies)
        var meshes = ""
        var usedNames: Set<String> = ["Materials"]
        var usedMaterials = Set<Int>()
        var usesStock = false

        for (bodyIndex, body) in bodies.enumerated() {
            let render = body.render
            guard !render.positions.isEmpty, !render.indices.isEmpty else { continue }
            let transform = body.transform
            let runs = palette.runs[bodyIndex]
            for (runIndex, run) in runs.enumerated() {
                // Each mesh gets only the vertices its triangles use.
                var remap = [Int32](repeating: -1, count: render.positions.count)
                var points: [SIMD3<Double>] = []
                var normals: [SIMD3<Double>] = []
                var indices: [Int32] = []
                indices.reserveCapacity(run.triangles.count * 3)
                for t in run.triangles where t >= 0 && 3 * t + 2 < render.indices.count {
                    for k in 0..<3 {
                        let v = Int(render.indices[3 * t + k])
                        guard v < render.positions.count else { continue }
                        if remap[v] < 0 {
                            remap[v] = Int32(points.count)
                            points.append(transform.applying(to: SIMD3<Double>(render.positions[v])))
                            // Uniform scale: rotating the normal is sufficient.
                            let n = v < render.normals.count ? SIMD3<Double>(render.normals[v]) : SIMD3(0, 1, 0)
                            let world = transform.rotation.act(n)
                            normals.append(simd_length(world) > 1e-12 ? simd_normalize(world) : SIMD3(0, 1, 0))
                        }
                        indices.append(remap[v])
                    }
                }
                guard indices.count >= 3, indices.count % 3 == 0 else { continue }

                // The body's own run carries its name; a painted face adds
                // the material's.
                var display = body.name
                if runIndex > 0, let material = run.material { display += " " + palette.names[material] }
                let prim = uniqueIdentifier(display, used: &usedNames)
                let binding: String
                if let material = run.material {
                    usedMaterials.insert(material)
                    binding = "Material_\(material)"
                } else {
                    usesStock = true
                    binding = "Default"
                }

                meshes += "    def Mesh \"\(prim)\" (\n"
                meshes += "        prepend apiSchemas = [\"MaterialBindingAPI\"]\n"
                meshes += "        displayName = \(quoted(display))\n"
                meshes += "    )\n    {\n"
                meshes += "        uniform bool doubleSided = 0\n"
                meshes += "        float3[] extent = \(extent(points))\n"
                meshes += "        int[] faceVertexCounts = [" + repeated("3", count: indices.count / 3) + "]\n"
                meshes += "        int[] faceVertexIndices = [" + indices.map(String.init).joined(separator: ", ") + "]\n"
                meshes += "        rel material:binding = </Root/Materials/\(binding)>\n"
                meshes += "        normal3f[] normals = [" + tuples(normals) + "] (\n"
                meshes += "            interpolation = \"vertex\"\n        )\n"
                meshes += "        point3f[] points = [" + tuples(points) + "]\n"
                meshes += "        uniform token subdivisionScheme = \"none\"\n"
                meshes += "    }\n\n"
            }
        }
        guard !meshes.isEmpty else { return nil }

        var out = """
        #usda 1.0
        (
            defaultPrim = "Root"
            doc = "openshape3d USDZ export (units: mm)"
            metersPerUnit = 0.001
            upAxis = "Y"
        )

        def Xform "Root" (
            kind = "component"
        )
        {

        """
        out += meshes
        out += "    def Scope \"Materials\"\n    {\n"
        func material(prim: String, display: String, color: SIMD4<Double>, glow: Double,
                      metallic: Double, roughness: Double) -> String {
            let path = "/Root/Materials/\(prim)"
            var text = "        def Material \"\(prim)\" (\n"
            text += "            displayName = \(quoted(display))\n        )\n        {\n"
            text += "            token outputs:surface.connect = <\(path)/Surface.outputs:surface>\n\n"
            text += "            def Shader \"Surface\"\n            {\n"
            text += "                uniform token info:id = \"UsdPreviewSurface\"\n"
            text += "                color3f inputs:diffuseColor = (\(number(color.x)), \(number(color.y)), \(number(color.z)))\n"
            if glow > 0 {
                text += "                color3f inputs:emissiveColor = (\(number(color.x * glow)), \(number(color.y * glow)), \(number(color.z * glow)))\n"
            }
            text += "                float inputs:metallic = \(number(metallic))\n"
            text += "                float inputs:opacity = \(number(color.w))\n"
            text += "                float inputs:roughness = \(number(roughness))\n"
            text += "                token outputs:surface\n"
            text += "            }\n        }\n\n"
            return text
        }
        // The stock look of a body without a material: the glTF export's grey.
        if usesStock {
            out += material(prim: "Default", display: "Default", color: SIMD4(0.72, 0.75, 0.78, 1), glow: 0,
                            metallic: 0.1, roughness: 0.6)
        }
        for index in usedMaterials.sorted() {
            let spec = palette.materials[index]
            out += material(prim: "Material_\(index)", display: palette.names[index],
                            color: ExportAppearance.color(spec), glow: ExportAppearance.glow(spec),
                            metallic: ExportAppearance.metallic(spec), roughness: ExportAppearance.roughness(spec))
        }
        out += "    }\n}\n"
        return out
    }

    // MARK: - Text helpers

    /// A USD prim name: letters, digits and underscores, not starting with a
    /// digit, unique among its siblings.
    static func uniqueIdentifier(_ name: String, used: inout Set<String>) -> String {
        var base = String(name.unicodeScalars.map { scalar -> Character in
            let isASCIILetter = (scalar.value >= 65 && scalar.value <= 90) || (scalar.value >= 97 && scalar.value <= 122)
            let isDigit = scalar.value >= 48 && scalar.value <= 57
            return isASCIILetter || isDigit || scalar == "_" ? Character(scalar) : "_"
        })
        if base.isEmpty { base = "Body" }
        if let first = base.unicodeScalars.first, first.value >= 48, first.value <= 57 { base = "_" + base }
        var candidate = base
        var suffix = 2
        while used.contains(candidate) {
            candidate = "\(base)_\(suffix)"
            suffix += 1
        }
        used.insert(candidate)
        return candidate
    }

    /// A double-quoted USD string.
    static func quoted(_ text: String) -> String {
        var out = "\""
        for scalar in text.unicodeScalars {
            switch scalar {
            case "\"": out += "\\\""
            case "\\": out += "\\\\"
            case "\n": out += "\\n"
            case "\r": out += "\\r"
            case "\t": out += "\\t"
            default:
                if scalar.value >= 0x20 { out.unicodeScalars.append(scalar) }
            }
        }
        return out + "\""
    }

    /// Shortest text that reads back as the same Float (what the mesh holds),
    /// never "nan" or "inf", which USD's text format does not take here.
    private static func number(_ value: Double) -> String {
        guard value.isFinite else { return "0" }
        let f = Float(value)
        if f == f.rounded(), abs(f) < 1e7 { return String(Int(f)) }
        return "\(f)"
    }

    private static func tuples(_ values: [SIMD3<Double>]) -> String {
        var out = ""
        out.reserveCapacity(values.count * 28)
        for (i, v) in values.enumerated() {
            if i > 0 { out += ", " }
            out += "(\(number(v.x)), \(number(v.y)), \(number(v.z)))"
        }
        return out
    }

    private static func extent(_ points: [SIMD3<Double>]) -> String {
        var lo = points[0], hi = points[0]
        for p in points { lo = simd_min(lo, p); hi = simd_max(hi, p) }
        return "[" + tuples([lo, hi]) + "]"
    }

    private static func repeated(_ item: String, count: Int) -> String {
        Array(repeating: item, count: count).joined(separator: ", ")
    }
}
