//
//  OBJExporter.swift
//  openshape3d
//
//  Wavefront OBJ export from RenderMesh buffers. Transforms are baked into
//  world space; one "o <name>" object per body. Convention: 1 model unit = 1 mm.
//
//  The mesh is written CLEAN rather than as the raw render triangles:
//    • positions are welded — each distinct point is one `v`, so the body
//      imports closed (no "merge by distance" needed);
//    • normals are their own `vn` table and faces reference them separately
//      (`f v//vn`): a planar face shares one flat normal, curved facets keep
//      their smooth per-corner normals;
//    • every planar face (coplanar connected triangles, as `FaceTopology`
//      recovers them — kernel face regions respected) becomes ONE polygon
//      when it has a single boundary loop. A face with holes can't be one
//      OBJ polygon, so its triangles are merged into as few simple polygons
//      as possible. No vertex is ever added, and no boundary vertex dropped,
//      so neighbouring faces still share every edge.
//  Curved surfaces stay triangulated. STL and 3MF are triangle-only formats
//  and keep their own exporters.
//

import Foundation
import simd

nonisolated enum OBJExporter {

    /// One merged OBJ containing every body as its own object.
    static func obj(bodies: [Body]) -> String {
        var out = header
        var vertexOffset = 0
        var normalOffset = 0
        for body in bodies {
            let written = append(body: body, to: &out,
                                 vertexOffset: vertexOffset, normalOffset: normalOffset)
            vertexOffset += written.vertices
            normalOffset += written.normals
        }
        return out
    }

    /// One OBJ string per body ("save each body separately").
    static func objPerBody(bodies: [Body]) -> [(name: String, obj: String)] {
        bodies.map { body in
            var out = header
            append(body: body, to: &out, vertexOffset: 0, normalOffset: 0)
            return (sanitized(body.name), out)
        }
    }

    private static let header = "# openshape3d OBJ export (units: mm)\n"

    // MARK: - Clean polygon mesh

    /// A polygon mesh in the body's local space: welded positions, a
    /// de-duplicated normal table, and faces as (position, normal) corner
    /// indices (0-based), wound counter-clockwise about the outward normal.
    struct PolygonMesh {
        var positions: [SIMD3<Float>] = []
        var normals: [SIMD3<Float>] = []
        var faces: [[(v: Int, n: Int)]] = []
    }

    private static let weldQuantum: Float = 1e-5   // same as FaceTopology

    private struct PositionKey: Hashable {
        let x, y, z: Int64
        init(_ p: SIMD3<Float>, inverseQuantum: Float) {
            x = MeshQuantize.key64(p.x, inverseQuantum: inverseQuantum)
            y = MeshQuantize.key64(p.y, inverseQuantum: inverseQuantum)
            z = MeshQuantize.key64(p.z, inverseQuantum: inverseQuantum)
        }
    }

    private struct DirectedEdge: Hashable {
        let from, to: Int
    }

    private struct UndirectedEdge: Hashable {
        let a, b: Int
        init(_ p: Int, _ q: Int) { a = min(p, q); b = max(p, q) }
    }

    static func polygonMesh(from mesh: RenderMesh) -> PolygonMesh {
        let triangleCount = mesh.triangleCount
        guard triangleCount > 0 else { return PolygonMesh() }

        // 1. Weld positions.
        var welded: [SIMD3<Float>] = []
        var weldIndex = [Int](repeating: 0, count: mesh.positions.count)
        var lookup: [PositionKey: Int] = [:]
        let inverse = 1 / weldQuantum
        for (i, p) in mesh.positions.enumerated() {
            let key = PositionKey(p, inverseQuantum: inverse)
            if let existing = lookup[key] {
                weldIndex[i] = existing
            } else {
                lookup[key] = welded.count
                weldIndex[i] = welded.count
                welded.append(p)
            }
        }
        func corners(_ t: Int) -> [Int] {
            (0..<3).map { weldIndex[Int(mesh.indices[t * 3 + $0])] }
        }
        func isDegenerate(_ c: [Int]) -> Bool {
            c[0] == c[1] || c[1] == c[2] || c[2] == c[0]
        }

        // 2. De-duplicated normal table.
        var normals: [SIMD3<Float>] = []
        var normalLookup: [PositionKey: Int] = [:]
        func normalIndex(_ n: SIMD3<Float>) -> Int {
            let length = simd_length(n)
            let unit = length > 1e-12 ? n / length : SIMD3<Float>(0, 0, 1)
            let key = PositionKey(unit, inverseQuantum: 1e6)
            if let existing = normalLookup[key] { return existing }
            normalLookup[key] = normals.count
            normals.append(unit)
            return normals.count - 1
        }

        // 3. Planar faces → polygons.
        var polygons: [[(v: Int, n: Int)]] = []
        var claimed = [Bool](repeating: false, count: triangleCount)
        for face in FaceTopology.enumerateFaces(in: mesh).planar {
            var triangles: [[Int]] = []
            for t in face.triangles where t >= 0 && t < triangleCount && !claimed[t] {
                claimed[t] = true
                let c = corners(t)
                if !isDegenerate(c) { triangles.append(c) }
            }
            guard !triangles.isEmpty else { continue }
            let n = normalIndex(face.normal)
            for loop in coplanarPolygons(triangles) {
                polygons.append(loop.map { (v: $0, n: n) })
            }
        }

        // 4. Everything else (curved facets) stays a triangle, keeping its
        //    per-corner render normals so smooth shading survives.
        let hasNormals = mesh.normals.count == mesh.positions.count
        for t in 0..<triangleCount where !claimed[t] {
            let c = corners(t)
            guard !isDegenerate(c) else { continue }
            let flat = simd_cross(welded[c[1]] - welded[c[0]], welded[c[2]] - welded[c[0]])
            polygons.append((0..<3).map { k in
                let raw = Int(mesh.indices[t * 3 + k])
                return (v: c[k], n: normalIndex(hasNormals ? mesh.normals[raw] : flat))
            })
        }

        // 5. Keep only referenced positions, in welded order.
        var used = [Bool](repeating: false, count: welded.count)
        for polygon in polygons { for corner in polygon { used[corner.v] = true } }
        var remap = [Int](repeating: -1, count: welded.count)
        var result = PolygonMesh()
        for i in welded.indices where used[i] {
            remap[i] = result.positions.count
            result.positions.append(welded[i])
        }
        result.normals = normals
        result.faces = polygons.map { $0.map { (v: remap[$0.v], n: $0.n) } }
        return result
    }

    /// Polygons covering a connected set of coplanar triangles (welded
    /// indices), with no new vertices. One boundary loop → that loop as a
    /// single n-gon; otherwise (holes, pinched boundaries) the triangles are
    /// merged greedily into simple polygons.
    private static func coplanarPolygons(_ triangles: [[Int]]) -> [[Int]] {
        var edgeUse: [UndirectedEdge: Int] = [:]
        for c in triangles {
            for k in 0..<3 { edgeUse[UndirectedEdge(c[k], c[(k + 1) % 3]), default: 0] += 1 }
        }
        var next: [Int: Int] = [:]
        var boundaryCount = 0
        var pinched = false
        var firstFrom: Int?
        for c in triangles {
            for k in 0..<3 {
                let a = c[k], b = c[(k + 1) % 3]
                guard edgeUse[UndirectedEdge(a, b)] == 1 else { continue }
                if next[a] != nil { pinched = true }
                next[a] = b
                boundaryCount += 1
                if firstFrom == nil { firstFrom = a }
            }
        }
        if !pinched, let start = firstFrom {
            var loop = [start]
            var current = next[start]!
            while current != start, loop.count <= boundaryCount {
                loop.append(current)
                guard let following = next[current] else { break }
                current = following
            }
            if current == start, loop.count == boundaryCount, loop.count >= 3 {
                return [loop]
            }
        }
        return mergedSimplePolygons(triangles)
    }

    /// Greedy merge of adjacent triangles across shared edges, accepting a
    /// merge only while the result stays a simple polygon (no repeated
    /// vertex). Within a conforming planar triangulation that is enough: two
    /// interior-disjoint simple polygons meeting only along one edge union to
    /// a simple polygon.
    private static func mergedSimplePolygons(_ triangles: [[Int]]) -> [[Int]] {
        var polygons: [[Int]?] = triangles.map { $0 }
        var owner: [DirectedEdge: Int] = [:]
        for (i, c) in triangles.enumerated() {
            for k in 0..<3 { owner[DirectedEdge(from: c[k], to: c[(k + 1) % 3])] = i }
        }

        var changed = true
        while changed {
            changed = false
            for p in polygons.indices {
                var merging = true
                while merging {
                    merging = false
                    guard let poly = polygons[p] else { break }
                    for i in poly.indices {
                        let a = poly[i], b = poly[(i + 1) % poly.count]
                        guard let q = owner[DirectedEdge(from: b, to: a)], q != p,
                              let other = polygons[q],
                              let j = other.indices.first(where: {
                                  other[$0] == b && other[($0 + 1) % other.count] == a
                              }) else { continue }
                        // poly rotated to run b … a; other rotated to run a … b.
                        let pr = Array(poly[((i + 1) % poly.count)...] + poly[..<((i + 1) % poly.count)])
                        let start = (j + 1) % other.count
                        let qr = Array(other[start...] + other[..<start])
                        let merged = pr + qr.dropFirst().dropLast()
                        guard Set(merged).count == merged.count else { continue }

                        polygons[p] = merged
                        polygons[q] = nil
                        owner[DirectedEdge(from: a, to: b)] = nil
                        owner[DirectedEdge(from: b, to: a)] = nil
                        for k in merged.indices {
                            owner[DirectedEdge(from: merged[k], to: merged[(k + 1) % merged.count])] = p
                        }
                        merging = true
                        changed = true
                        break
                    }
                }
            }
        }
        return polygons.compactMap { $0 }
    }

    // MARK: - Writing

    @discardableResult
    private static func append(body: Body, to out: inout String,
                               vertexOffset: Int, normalOffset: Int) -> (vertices: Int, normals: Int) {
        out += "o \(sanitized(body.name))\n"
        let transform = body.transform
        let mesh = polygonMesh(from: body.render)
        for p in mesh.positions {
            let world = transform.applying(to: SIMD3<Double>(p))
            out += String(format: "v %.6f %.6f %.6f\n", world.x, world.y, world.z)
        }
        for n in mesh.normals {
            // Uniform scale: rotating the normal is sufficient.
            let world = simd_normalize(transform.rotation.act(SIMD3<Double>(n)))
            out += String(format: "vn %.6f %.6f %.6f\n", world.x, world.y, world.z)
        }
        for face in mesh.faces {
            out += "f"
            for corner in face {
                out += " \(corner.v + vertexOffset + 1)//\(corner.n + normalOffset + 1)"
            }
            out += "\n"
        }
        return (mesh.positions.count, mesh.normals.count)
    }

    private static func sanitized(_ name: String) -> String {
        let cleaned = name.map { $0.isWhitespace ? "_" : String($0) }.joined()
        return cleaned.isEmpty ? "Body" : cleaned
    }
}
