//
//  OBJImporter.swift
//  openshape3d
//
//  Wavefront OBJ parsing into RenderMesh — the read half of `OBJExporter`, and
//  the format most mesh tools hand you when STL would lose the grouping.
//
//  Like the STL path, normals are recomputed from triangle winding rather than
//  trusted from the file (`vn` records in the wild are frequently absent,
//  stale, or averaged across hard edges), and vertices are welded with the same
//  quantized position+normal key so creases survive. `o`/`g` groups are read
//  and returned separately, so an OBJ carrying several parts imports as several
//  bodies instead of one welded lump.
//

import Foundation
import simd

nonisolated enum OBJImporter {

    enum ImportError: Error, Equatable {
        case malformed(String)
        case empty
    }

    /// One `o`/`g` group in the file.
    nonisolated struct Group: Sendable {
        var name: String
        var mesh: RenderMesh
    }

    /// Mirrors `STLImporter.weldQuantum` / `EuclidBridge.weldQuantum`.
    private static let weldQuantum: Float = 1e-5

    private struct WeldKey: Hashable {
        let px, py, pz, nx, ny, nz: Int64

        init(position: SIMD3<Float>, normal: SIMD3<Float>, quantum: Float) {
            let inv = 1 / quantum
            // key64: a raw Int32/Int64(_: Float) traps on NaN, and an Int32
            // key at this quantum saturates at ±21 m — which silently WELDED
            // far-apart vertices together instead. Int64 + NaN guard.
            px = MeshQuantize.key64(position.x, inverseQuantum: inv)
            py = MeshQuantize.key64(position.y, inverseQuantum: inv)
            pz = MeshQuantize.key64(position.z, inverseQuantum: inv)
            nx = MeshQuantize.key64(normal.x, inverseQuantum: inv)
            ny = MeshQuantize.key64(normal.y, inverseQuantum: inv)
            nz = MeshQuantize.key64(normal.z, inverseQuantum: inv)
        }
    }

    /// Every group in the file, in declaration order. Faces appearing before
    /// any `o`/`g` land in a leading unnamed group.
    ///
    /// `unitScale` maps file units to model units (OBJ is unitless, like STL).
    static func importOBJ(_ data: Data, unitScale: Double = 1.0) throws -> [Group] {
        guard let text = String(data: data, encoding: .utf8)
                ?? String(data: data, encoding: .isoLatin1) else {
            throw ImportError.malformed("OBJ is not text")
        }

        // `v` indices are FILE-global and 1-based (negative = relative to the
        // end), so vertices are collected across the whole file even though
        // faces are bucketed per group.
        var vertices = [SIMD3<Double>]()
        var groups = [(name: String, corners: [SIMD3<Double>])]()
        var current = (name: "", corners: [SIMD3<Double>]())

        func flush() {
            if !current.corners.isEmpty { groups.append(current) }
        }

        for rawLine in text.split(separator: "\n", omittingEmptySubsequences: false) {
            let line = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !line.isEmpty, !line.hasPrefix("#") else { continue }
            let fields = line.split(whereSeparator: { $0 == " " || $0 == "\t" })
            guard let keyword = fields.first else { continue }

            switch keyword {
            case "v":
                guard fields.count >= 4,
                      let x = Double(fields[1]), let y = Double(fields[2]),
                      let z = Double(fields[3]) else {
                    throw ImportError.malformed("bad vertex: \(line)")
                }
                vertices.append(SIMD3(x, y, z) * unitScale)

            case "o", "g":
                flush()
                current = (fields.dropFirst().joined(separator: " "), [])

            case "f":
                let refs = fields.dropFirst()
                guard refs.count >= 3 else {
                    throw ImportError.malformed("face with fewer than 3 corners")
                }
                // "v", "v/vt", "v//vn", "v/vt/vn" — only the position index matters.
                let corner: [SIMD3<Double>] = try refs.map { ref in
                    guard let first = ref.split(separator: "/", omittingEmptySubsequences: false).first,
                          let raw = Int(first) else {
                        throw ImportError.malformed("bad face index: \(ref)")
                    }
                    let index = raw > 0 ? raw - 1 : vertices.count + raw
                    guard vertices.indices.contains(index) else {
                        throw ImportError.malformed("face references vertex \(raw)")
                    }
                    return vertices[index]
                }
                // Planar polygons; concave ones (an exported L-shaped or
                // notched face) are ear-clipped, convex ones fanned.
                for (a, b, c) in triangulatePolygon(corner) {
                    current.corners.append(contentsOf: [corner[a], corner[b], corner[c]])
                }

            default:
                continue  // vn/vt/usemtl/mtllib/s — nothing we need
            }
        }
        flush()

        let meshes = groups.compactMap { group -> Group? in
            guard let mesh = weldedMesh(corners: group.corners) else { return nil }
            return Group(name: group.name, mesh: mesh)
        }
        guard !meshes.isEmpty else { throw ImportError.empty }
        return meshes
    }

    /// Every group welded into ONE mesh — the "import as a single body" path.
    static func importSingleMesh(_ data: Data, unitScale: Double = 1.0) throws -> RenderMesh {
        let groups = try importOBJ(data, unitScale: unitScale)
        if groups.count == 1 { return groups[0].mesh }
        var positions = [SIMD3<Float>]()
        var normals = [SIMD3<Float>]()
        var indices = [UInt32]()
        for group in groups {
            let base = UInt32(positions.count)
            positions.append(contentsOf: group.mesh.positions)
            normals.append(contentsOf: group.mesh.normals)
            indices.append(contentsOf: group.mesh.indices.map { $0 + base })
        }
        return RenderMesh(positions: positions, normals: normals, indices: indices)
    }

    // MARK: - Helpers

    /// Triangles (corner-index triples) covering a planar polygon, keeping its
    /// winding. Convex polygons fan from corner 0; anything else is
    /// ear-clipped in the polygon's own plane (Newell normal). Falls back to
    /// the fan if clipping gets stuck (self-intersecting input).
    static func triangulatePolygon(_ corners: [SIMD3<Double>]) -> [(Int, Int, Int)] {
        let count = corners.count
        let fan = (1..<(count - 1)).map { (0, $0, $0 + 1) }
        guard count > 3 else { return fan }

        var normal = SIMD3<Double>.zero
        for i in 0..<count {
            let p = corners[i], q = corners[(i + 1) % count]
            normal += SIMD3((p.y - q.y) * (p.z + q.z),
                            (p.z - q.z) * (p.x + q.x),
                            (p.x - q.x) * (p.y + q.y))
        }
        guard simd_length(normal) > 1e-30 else { return fan }
        normal = simd_normalize(normal)

        func turn(_ a: Int, _ b: Int, _ c: Int) -> Double {
            simd_dot(simd_cross(corners[b] - corners[a], corners[c] - corners[b]), normal)
        }
        let isConvex = (0..<count).allSatisfy {
            turn($0, ($0 + 1) % count, ($0 + 2) % count) >= -1e-12
        }
        if isConvex { return fan }

        func inside(_ p: Int, _ a: Int, _ b: Int, _ c: Int) -> Bool {
            let x = corners[p]
            func side(_ u: Int, _ v: Int) -> Double {
                simd_dot(simd_cross(corners[v] - corners[u], x - corners[u]), normal)
            }
            return side(a, b) >= 0 && side(b, c) >= 0 && side(c, a) >= 0
        }

        var remaining = Array(0..<count)
        var triangles: [(Int, Int, Int)] = []
        while remaining.count > 3 {
            let n = remaining.count
            var clipped = false
            for i in 0..<n {
                let a = remaining[(i + n - 1) % n], b = remaining[i], c = remaining[(i + 1) % n]
                guard turn(a, b, c) > 1e-12 else { continue }
                let blocked = remaining.contains { p in
                    p != a && p != b && p != c && corners[p] != corners[a]
                        && corners[p] != corners[b] && corners[p] != corners[c]
                        && inside(p, a, b, c)
                }
                if blocked { continue }
                triangles.append((a, b, c))
                remaining.remove(at: i)
                clipped = true
                break
            }
            if !clipped { return fan }
        }
        triangles.append((remaining[0], remaining[1], remaining[2]))
        return triangles
    }

    /// Nil (rather than throwing) when a group holds no non-degenerate triangle
    /// — an empty `g` line is common and must not fail the whole import.
    private static func weldedMesh(corners: [SIMD3<Double>]) -> RenderMesh? {
        var positions = [SIMD3<Float>]()
        var normals = [SIMD3<Float>]()
        var indices = [UInt32]()
        var lookup = [WeldKey: UInt32]()

        var i = 0
        while i + 2 < corners.count {
            let a = corners[i], b = corners[i + 1], c = corners[i + 2]
            i += 3
            let cross = simd_cross(b - a, c - a)
            let lengthSquared = simd_length_squared(cross)
            guard lengthSquared > 1e-24 else { continue }
            let normal = SIMD3<Float>(cross / lengthSquared.squareRoot())
            for corner in [a, b, c] {
                let p = SIMD3<Float>(corner)
                let key = WeldKey(position: p, normal: normal, quantum: weldQuantum)
                if let existing = lookup[key] {
                    indices.append(existing)
                } else {
                    let index = UInt32(positions.count)
                    lookup[key] = index
                    positions.append(p)
                    normals.append(normal)
                    indices.append(index)
                }
            }
        }
        guard !indices.isEmpty else { return nil }
        return RenderMesh(positions: positions, normals: normals, indices: indices)
    }
}
