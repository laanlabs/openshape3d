//
//  ExportMaterials.swift
//  openshape3d
//
//  The appearance the exporters write: each body's material (or the default
//  look) and the per-face materials painted on it, gathered into one table of
//  distinct materials and, per body, which triangles wear which of them.
//  glTF writes one primitive per group, 3MF one base material per entry.
//

import Foundation
import simd

nonisolated enum ExportMaterials {

    /// Triangles (indices into the body's render mesh, in mesh order) that
    /// wear `material`, an index into `Table.materials`.
    struct Group: Equatable {
        var material: Int
        var triangles: [Int]
    }

    struct Table {
        /// Distinct materials, in the order bodies first use them.
        var materials: [BodyMaterialSpec]
        /// A name per material: "Default" for the default look, the Material
        /// sheet preset it equals, else "Material N".
        var names: [String]
        /// Per body, in `bodies` order: the body's own material first, then
        /// each painted face material; groups with no triangles are left out.
        var groups: [[Group]]
    }

    static func table(for bodies: [Body]) -> Table {
        var materials: [BodyMaterialSpec] = []
        func index(of spec: BodyMaterialSpec) -> Int {
            if let i = materials.firstIndex(of: spec) { return i }
            materials.append(spec)
            return materials.count - 1
        }
        var groups: [[Group]] = []
        for body in bodies {
            let count = body.render.triangleCount
            let base = index(of: body.material ?? .default)
            guard !body.faceMaterials.isEmpty, count > 0 else {
                groups.append(count > 0 ? [Group(material: base, triangles: Array(0..<count))] : [])
                continue
            }
            var owner = [Int](repeating: base, count: count)
            let painted = FaceMaterialKit.resolve(body.faceMaterials, in: body.render)
            var order = [base]
            for (face, triangles) in zip(body.faceMaterials, painted) where !triangles.isEmpty {
                let m = index(of: face.material)
                if !order.contains(m) { order.append(m) }
                for t in triangles where t < count { owner[t] = m }
            }
            var byMaterial: [Int: [Int]] = [:]
            for (t, m) in owner.enumerated() { byMaterial[m, default: []].append(t) }
            groups.append(order.compactMap { m in
                guard let triangles = byMaterial[m], !triangles.isEmpty else { return nil }
                return Group(material: m, triangles: triangles)
            })
        }
        var used: [String: Int] = [:]
        let names = materials.enumerated().map { i, spec -> String in
            let base = spec == .default ? "Default"
                : MaterialPreset.library.first(where: { $0.spec == spec })?.name ?? "Material \(i + 1)"
            used[base, default: 0] += 1
            return used[base]! > 1 ? "\(base) \(used[base]!)" : base
        }
        return Table(materials: materials, names: names, groups: groups)
    }

    /// The colour clamped to 0…1. The app's importers read glTF
    /// `baseColorFactor` and MTL `Kd` into `baseColor` as they are, so
    /// writing it as it is keeps a round trip exact.
    static func rgba(_ spec: BodyMaterialSpec) -> SIMD4<Double> {
        simd_clamp(spec.baseColor, SIMD4(repeating: 0), SIMD4(repeating: 1))
    }

    /// glTF roughness. The app's 0 means "the legacy fixed highlight", not
    /// a mirror, which is what 0 means in glTF; it is written as 0.5.
    static func roughness(_ spec: BodyMaterialSpec) -> Double {
        spec.roughness > 0 ? min(spec.roughness, 1) : 0.5
    }

    /// `#RRGGBB`, or `#RRGGBBAA` when not opaque (3MF `displaycolor`).
    static func hex(_ spec: BodyMaterialSpec) -> String {
        let c = rgba(spec)
        func byte(_ v: Double) -> String { String(format: "%02X", Int((v * 255).rounded())) }
        return "#" + byte(c.x) + byte(c.y) + byte(c.z) + (c.w < 1 ? byte(c.w) : "")
    }
}
