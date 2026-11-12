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

    /// Curved-surface density for bodies that carry an OCCT B-rep. The
    /// viewport meshes at ~4.6° per segment (40 per 90° on a fillet blend);
    /// an export does not need that, so it re-meshes the exact solid at its
    /// own deflections. `nil` writes the render mesh as it is.
    struct Tessellation: Equatable, Sendable {
        var angularDeflection: Double   // radians per segment, at most
        var linearDeflection: Double    // mm of chord sag, at most

        /// ~11.5° per segment (8 per quarter turn, like a modest bevel), at
        /// most 0.5 mm off the true surface. A 1400×1900×220 mattress with
        /// R60 fillets on all 12 edges: 7344 → 1400 vertices, volume −0.01 %.
        static let standard = Tessellation(angularDeflection: 0.2, linearDeflection: 0.5)
    }

    /// One merged OBJ containing every body as its own object.
    static func obj(bodies: [Body], tessellation: Tessellation? = .standard) -> String {
        var out = header
        var vertexOffset = 0
        var normalOffset = 0
        for body in bodies {
            let written = append(body: body, to: &out, tessellation: tessellation,
                                 vertexOffset: vertexOffset, normalOffset: normalOffset)
            vertexOffset += written.vertices
            normalOffset += written.normals
        }
        return out
    }

    /// One OBJ string per body ("save each body separately").
    static func objPerBody(bodies: [Body],
                           tessellation: Tessellation? = .standard) -> [(name: String, obj: String)] {
        bodies.map { body in
            var out = header
            append(body: body, to: &out, tessellation: tessellation,
                   vertexOffset: 0, normalOffset: 0)
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

        // 3. Shading normal of every triangle corner: the render normals when
        //    the mesh carries them (OCCT and Euclid both do), else a smooth
        //    normal averaged over the corner's incident triangles that are
        //    neither across a sharp edge (> ~30°) nor in another kernel face.
        let cornerNormals = shadingNormals(mesh: mesh, corners: corners)
        func flatNormal(_ c: [Int]) -> SIMD3<Float> {
            simd_cross(welded[c[1]] - welded[c[0]], welded[c[2]] - welded[c[0]])
        }

        // 4. Planar faces → polygons. A triangle belongs to a flat face only
        //    when it is SHADED flat (its corner normals are the face normal):
        //    a fillet or fine curved patch is locally planar, and a coplanar
        //    flood-fill alone would turn every one of its facets into a tiny
        //    "planar face" with a flat normal.
        var polygons: [[(v: Int, n: Int)]] = []
        var claimed = [Bool](repeating: false, count: triangleCount)
        for face in FaceTopology.enumerateFaces(in: mesh).planar {
            let faceNormal = simd_normalize(face.normal)
            var triangles: [[Int]] = []
            for t in face.triangles where t >= 0 && t < triangleCount && !claimed[t] {
                let shadedFlat = (0..<3).allSatisfy {
                    simd_dot(simd_normalize(cornerNormals[t * 3 + $0]), faceNormal) > flatShadingCos
                }
                guard shadedFlat else { continue }   // left for the curved path
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

        // 5. Curved facets keep their per-corner smooth normals. Two
        //    triangles of one flat facet (a cylinder's side strip between two
        //    generatrices, a fillet's strip) are written as one quad.
        var curved: [[(v: Int, n: Int)]] = []
        var curvedNormals: [SIMD3<Float>] = []
        for t in 0..<triangleCount where !claimed[t] {
            let c = corners(t)
            guard !isDegenerate(c) else { continue }
            curved.append((0..<3).map { (v: c[$0], n: normalIndex(cornerNormals[t * 3 + $0])) })
            curvedNormals.append(simd_normalize(flatNormal(c)))
        }
        polygons += pairedCoplanarTriangles(curved, facetNormals: curvedNormals, positions: welded)

        // 6. Keep only referenced positions, in welded order.
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

    /// cos of the largest corner-normal deviation still shaded "flat"
    /// (~0.08°). Flat faces carry their plane normal to float precision;
    /// OCCT tessellates fillets finely enough (~1.5° between strips) that a
    /// looser bound mistakes a fillet strip for a flat face.
    private static let flatShadingCos: Float = 0.999999
    /// Dihedral beyond which the fallback normal smoothing stops (~30°).
    private static let smoothingCos: Float = 0.866

    private static func shadingNormals(mesh: RenderMesh,
                                       corners: (Int) -> [Int]) -> [SIMD3<Float>] {
        let count = mesh.triangleCount
        if mesh.normals.count == mesh.positions.count {
            return (0..<(count * 3)).map { mesh.normals[Int(mesh.indices[$0])] }
        }
        let regions = mesh.validFaceRegions
        var faceNormals = [SIMD3<Float>](repeating: .zero, count: count)
        var incident: [Int: [Int]] = [:]
        for t in 0..<count {
            let c = corners(t)
            let p = (0..<3).map { mesh.positions[Int(mesh.indices[t * 3 + $0])] }
            faceNormals[t] = simd_cross(p[1] - p[0], p[2] - p[0])   // area-weighted
            for v in Set(c) { incident[v, default: []].append(t) }
        }
        var result = [SIMD3<Float>](repeating: .zero, count: count * 3)
        for t in 0..<count {
            let own = faceNormals[t]
            let ownUnit = simd_length(own) > 0 ? simd_normalize(own) : SIMD3<Float>(0, 0, 1)
            for (k, v) in corners(t).enumerated() {
                var sum = SIMD3<Float>.zero
                for u in incident[v] ?? [] {
                    let n = faceNormals[u]
                    guard simd_length(n) > 0,
                          regions.map({ $0[u] == $0[t] }) ?? true,
                          simd_dot(simd_normalize(n), ownUnit) > smoothingCos else { continue }
                    sum += n
                }
                result[t * 3 + k] = simd_length(sum) > 0 ? simd_normalize(sum) : ownUnit
            }
        }
        return result
    }

    /// Pair triangles that share an edge and lie in one plane into convex
    /// quads, keeping each corner's own normal. Unpaired triangles pass
    /// through. No vertex is added or removed, so shared edges stay shared.
    private static func pairedCoplanarTriangles(_ triangles: [[(v: Int, n: Int)]],
                                                facetNormals: [SIMD3<Float>],
                                                positions: [SIMD3<Float>]) -> [[(v: Int, n: Int)]] {
        var owner: [DirectedEdge: Int] = [:]
        for (i, tri) in triangles.enumerated() {
            for k in 0..<3 { owner[DirectedEdge(from: tri[k].v, to: tri[(k + 1) % 3].v)] = i }
        }
        var paired = [Bool](repeating: false, count: triangles.count)
        var result: [[(v: Int, n: Int)]] = []
        for i in triangles.indices where !paired[i] {
            let tri = triangles[i]
            var quad: [(v: Int, n: Int)]?
            for k in 0..<3 {
                let a = tri[k], b = tri[(k + 1) % 3], c = tri[(k + 2) % 3]
                guard let j = owner[DirectedEdge(from: b.v, to: a.v)], j != i, !paired[j],
                      simd_dot(facetNormals[i], facetNormals[j]) > 0.99999,
                      let d = triangles[j].first(where: { $0.v != a.v && $0.v != b.v }) else { continue }
                // Coplanar: d on tri's plane, relative to the quad's size.
                let pa = positions[a.v], pd = positions[d.v]
                let size = max(simd_length(positions[b.v] - pa), simd_length(positions[c.v] - pa))
                guard abs(simd_dot(pd - pa, facetNormals[i])) <= 1e-4 * size + 1e-6 else { continue }
                // Quad b, c, a, d — accept only if convex.
                let candidate = [b, c, a, d]
                let convex = (0..<4).allSatisfy { m in
                    let p0 = positions[candidate[m].v]
                    let p1 = positions[candidate[(m + 1) % 4].v]
                    let p2 = positions[candidate[(m + 2) % 4].v]
                    return simd_dot(simd_cross(p1 - p0, p2 - p1), facetNormals[i]) > 0
                }
                guard convex else { continue }
                paired[i] = true
                paired[j] = true
                quad = candidate
                break
            }
            if let quad { result.append(quad) }
        }
        for i in triangles.indices where !paired[i] { result.append(triangles[i]) }
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
    private static func append(body: Body, to out: inout String, tessellation: Tessellation?,
                               vertexOffset: Int, normalOffset: Int) -> (vertices: Int, normals: Int) {
        out += "o \(sanitized(body.name))\n"
        let transform = body.transform
        let mesh = polygonMesh(from: exportSource(for: body, tessellation: tessellation))
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

    /// The mesh to write: the B-rep re-meshed at `tessellation` when the body
    /// has one, else (or if that fails, or does not line up with what the
    /// viewport shows — a stale handle) the body's render mesh.
    static func exportSource(for body: Body, tessellation: Tessellation?) -> RenderMesh {
        guard let tessellation, let brep = body.brep, !body.render.positions.isEmpty,
              let mesh = OCCTKernel.exportMesh(from: brep,
                                               angularDeflection: tessellation.angularDeflection,
                                               linearDeflection: tessellation.linearDeflection)
        else { return body.render }
        let a = body.render.localAABB, b = mesh.localAABB
        let size = simd_length(a.max - a.min)
        let slack = Float(tessellation.linearDeflection) * 2 + size * 1e-3
        guard simd_length(a.min - b.min) <= slack, simd_length(a.max - b.max) <= slack else {
            return body.render
        }
        return mesh
    }

    private static func sanitized(_ name: String) -> String {
        let cleaned = name.map { $0.isWhitespace ? "_" : String($0) }.joined()
        return cleaned.isEmpty ? "Body" : cleaned
    }
}
