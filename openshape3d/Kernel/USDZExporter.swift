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
//      body wears (`ExportMaterials`), bound to shared Material prims;
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
        let table = ExportMaterials.table(for: bodies)
        var meshes = ""
        var usedNames: Set<String> = ["Materials"]
        var usedMaterials = Set<Int>()

        for (bodyIndex, body) in bodies.enumerated() {
            let render = body.render
            guard !render.positions.isEmpty, !render.indices.isEmpty else { continue }
            let transform = body.transform
            let groups = table.groups[bodyIndex]
            for (groupIndex, group) in groups.enumerated() {
                // Each mesh gets only the vertices its triangles use.
                var remap = [Int32](repeating: -1, count: render.positions.count)
                var points: [SIMD3<Double>] = []
                var normals: [SIMD3<Double>] = []
                var indices: [Int32] = []
                indices.reserveCapacity(group.triangles.count * 3)
                for t in group.triangles where 3 * t + 2 < render.indices.count {
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

                let display = groups.count > 1 && groupIndex > 0
                    ? body.name + " " + table.names[group.material] : body.name
                let prim = uniqueIdentifier(display, used: &usedNames)
                usedMaterials.insert(group.material)

                meshes += "    def Mesh \"\(prim)\" (\n"
                meshes += "        prepend apiSchemas = [\"MaterialBindingAPI\"]\n"
                meshes += "        displayName = \(quoted(display))\n"
                meshes += "    )\n    {\n"
                meshes += "        uniform bool doubleSided = 0\n"
                meshes += "        float3[] extent = \(extent(points))\n"
                meshes += "        int[] faceVertexCounts = [" + repeated("3", count: indices.count / 3) + "]\n"
                meshes += "        int[] faceVertexIndices = [" + indices.map(String.init).joined(separator: ", ") + "]\n"
                meshes += "        rel material:binding = </Root/Materials/Material_\(group.material)>\n"
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
        for index in usedMaterials.sorted() {
            let spec = table.materials[index]
            let c = ExportMaterials.rgba(spec)
            let glow = min(max(spec.emission, 0), 1)
            let path = "/Root/Materials/Material_\(index)"
            out += "        def Material \"Material_\(index)\" (\n"
            out += "            displayName = \(quoted(table.names[index]))\n        )\n        {\n"
            out += "            token outputs:surface.connect = <\(path)/Surface.outputs:surface>\n\n"
            out += "            def Shader \"Surface\"\n            {\n"
            out += "                uniform token info:id = \"UsdPreviewSurface\"\n"
            out += "                color3f inputs:diffuseColor = (\(number(c.x)), \(number(c.y)), \(number(c.z)))\n"
            if glow > 0 {
                out += "                color3f inputs:emissiveColor = (\(number(c.x * glow)), \(number(c.y * glow)), \(number(c.z * glow)))\n"
            }
            out += "                float inputs:metallic = \(number(min(max(spec.metallic, 0), 1)))\n"
            out += "                float inputs:opacity = \(number(c.w))\n"
            out += "                float inputs:roughness = \(number(ExportMaterials.roughness(spec)))\n"
            out += "                token outputs:surface\n"
            out += "            }\n        }\n\n"
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
