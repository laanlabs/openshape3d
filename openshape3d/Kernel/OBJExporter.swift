//
//  OBJExporter.swift
//  openshape3d
//
//  Wavefront OBJ export. Transforms are baked into world space; one
//  "o <name>" object per body. Convention: 1 model unit = 1 mm.
//
//  The render mesh is a triangle soup made for the GPU: a cube is 24
//  vertices and 12 triangles, and its faces do not share corners. Written
//  out like that, every other tool opens an unwelded shell. So the file is
//  built from a cleaned copy (`CleanMesh`):
//
//    • each distinct position is one `v`, shared by every face around it,
//      so a closed body arrives closed;
//    • normals are a table of their own (`f v//vn`), so welding positions
//      does not blur a hard edge: each corner keeps the normal it was
//      shaded with;
//    • triangles lying in one plane, shaded alike, are merged back into
//      CONVEX polygons (a box side is a quad, a cylinder's cap a disc, each
//      strip of its wall a quad). Convex only: plenty of OBJ readers split
//      a polygon into a fan from its first corner, which is wrong for an
//      L-shaped face. A concave face comes out as a few convex pieces.
//
//  The merging is Hertel and Mehlhorn's: take the triangulation and remove
//  every shared edge whose removal leaves both of its ends convex. It never
//  adds a vertex, and only drops one that lies on a straight seam between
//  the two pieces being joined, so faces keep meeting edge to edge.
//
//  Materials (#133) cannot live in an OBJ; they go in an MTL library beside
//  it. `objWithMaterials` returns both: the OBJ names the library
//  (`mtllib`) and puts a `usemtl` in front of each run of faces — the
//  body's material, or a painted face's (`ExportAppearance`). Faces are
//  never merged across two materials. A design nobody coloured gets no
//  library and no material statements.
//

import Foundation
import simd

nonisolated enum OBJExporter {

    // MARK: - Files

    /// One merged OBJ containing every body as its own object.
    /// `materialLibrary` is the file name of the MTL written beside it; it
    /// is only mentioned when some body or face has a material.
    static func obj(bodies: [Body], materialLibrary: String? = nil) -> String {
        files(bodies: bodies, materialLibrary: materialLibrary).obj
    }

    /// The OBJ and the MTL it refers to as `materialLibrary` (nil when the
    /// design has no materials), from one pass over the bodies.
    static func objWithMaterials(bodies: [Body], materialLibrary: String) -> (obj: String, mtl: String?) {
        files(bodies: bodies, materialLibrary: materialLibrary)
    }

    /// The MTL alone: nil when no body or face has a material.
    static func mtl(bodies: [Body]) -> String? {
        // The runs do not depend on the mesh here: only on what exists.
        let palette = ExportAppearance.palette(for: bodies)
        return palette.isPlain ? nil : library(palette)
    }

    /// One OBJ string per body ("save each body separately"). With a
    /// `materialLibrary` every file names that one shared MTL, and uses the
    /// same material names a merged export would.
    static func objPerBody(bodies: [Body], materialLibrary: String? = nil) -> [(name: String, obj: String)] {
        let palette = ExportAppearance.palette(for: bodies)
        let styled = materialLibrary != nil && !palette.isPlain
        let names = palette.names.map(label)
        return bodies.enumerated().map { index, body in
            var out = header
            if styled, let materialLibrary { out += "mtllib \(materialLibrary)\n" }
            var offsets = (vertices: 0, normals: 0)
            append(body, runs: styled ? palette.runs[index] : nil, names: names, to: &out, offsets: &offsets)
            return (label(body.name), out)
        }
    }

    /// What an OBJ export puts on disk, named: "<design>.obj" — or one
    /// "<body>.obj" per body — and "<design>.mtl" beside them when anything
    /// has a material. Two bodies of one name get "<body>.obj" and
    /// "<body> 2.obj", so neither overwrites the other.
    static func files(bodies: [Body], designName: String, perBody: Bool) -> [(fileName: String, data: Data)] {
        let stem = fileStem(for: designName)
        let library = stem + ".mtl"
        var out: [(fileName: String, data: Data)] = []
        if perBody {
            var used: [String: Int] = [:]
            for (name, obj) in objPerBody(bodies: bodies, materialLibrary: library) {
                let safe = fileStem(for: name)
                let count = (used[safe.lowercased()] ?? 0) + 1
                used[safe.lowercased()] = count
                out.append(((count > 1 ? "\(safe)_\(count)" : safe) + ".obj", Data(obj.utf8)))
            }
        } else {
            out.append((stem + ".obj", Data(obj(bodies: bodies, materialLibrary: library).utf8)))
        }
        if let mtl = mtl(bodies: bodies) { out.append((library, Data(mtl.utf8))) }
        return out
    }

    /// "<design>" for "<design>.obj" and "<design>.mtl": safe in a path and
    /// in an `mtllib` line, which ends at the first space.
    static func fileStem(for designName: String) -> String {
        let cleaned = String(designName.map { $0.isWhitespace || "/\\:".contains($0) ? "_" : $0 })
        return cleaned.isEmpty ? "Design" : cleaned
    }

    private static let header = "# openshape3d OBJ export (units: mm)\n"

    private static func files(bodies: [Body], materialLibrary: String?) -> (obj: String, mtl: String?) {
        let palette = ExportAppearance.palette(for: bodies)
        let styled = materialLibrary != nil && !palette.isPlain
        let names = palette.names.map(label)
        var out = header
        if styled, let materialLibrary { out += "mtllib \(materialLibrary)\n" }
        var offsets = (vertices: 0, normals: 0)
        for (index, body) in bodies.enumerated() {
            append(body, runs: styled ? palette.runs[index] : nil, names: names, to: &out, offsets: &offsets)
        }
        return (out, styled ? library(palette) : nil)
    }

    /// What a body without a material is called in a file that has some.
    private static let stockName = "Default"

    /// `newmtl` per palette entry: `Kd` colour, `d` opacity, the PBR
    /// extension's `Pm` / `Pr` (metallic, roughness), `Ke` for a glow.
    private static func library(_ palette: ExportAppearance.Palette) -> String {
        var out = "# openshape3d MTL export\n"
        // Bodies without a material need an entry too once the file has
        // materials, or they would take on whichever came before them: the
        // stock grey the glTF export gives them.
        if palette.runs.contains(where: { $0.contains(where: { $0.material == nil }) }) {
            out += "\nnewmtl \(stockName)\nKd 0.720000 0.750000 0.780000\nd 1.000000\nPm 0.100000\nPr 0.600000\nillum 2\n"
        }
        for (spec, name) in zip(palette.materials, palette.names) {
            let color = ExportAppearance.color(spec)
            let glow = ExportAppearance.glow(spec)
            out += "\nnewmtl \(label(name))\n"
            out += String(format: "Kd %.6f %.6f %.6f\n", color.x, color.y, color.z)
            out += String(format: "d %.6f\n", color.w)
            out += String(format: "Pm %.6f\n", ExportAppearance.metallic(spec))
            out += String(format: "Pr %.6f\n", ExportAppearance.roughness(spec))
            if glow > 0 { out += String(format: "Ke %.6f %.6f %.6f\n", color.x * glow, color.y * glow, color.z * glow) }
            out += "illum 2\n"
        }
        return out
    }

    /// `runs`: the body's material runs (nil writes no `usemtl`); `names`:
    /// the label of each palette material.
    private static func append(_ body: Body, runs: [ExportAppearance.Run]?, names: [String],
                               to out: inout String, offsets: inout (vertices: Int, normals: Int)) {
        out += "o \(label(body.name))\n"
        let source = body.render
        // Which run each triangle is in; -1 where no material applies.
        var groups: [Int]?
        var groupMaterial: [Int?] = []
        if let runs {
            var owner = [Int](repeating: -1, count: source.triangleCount)
            for (index, run) in runs.enumerated() {
                groupMaterial.append(run.material)
                for t in run.triangles where t >= 0 && t < owner.count { owner[t] = index }
            }
            groups = owner
        }
        let mesh = cleanMesh(from: source, triangleGroups: groups)

        let transform = body.transform
        for p in mesh.positions {
            let world = transform.applying(to: SIMD3<Double>(p))
            out += String(format: "v %.6f %.6f %.6f\n", world.x, world.y, world.z)
        }
        for n in mesh.normals {
            // Uniform scale: rotating the normal is sufficient.
            let world = simd_normalize(transform.rotation.act(SIMD3<Double>(n)))
            out += String(format: "vn %.6f %.6f %.6f\n", world.x, world.y, world.z)
        }
        // Faces in run order, so each material is stated once per body.
        var current: Int?? = .none
        let order = runs == nil ? Array(mesh.faces.indices)
            : mesh.faces.indices.sorted { (mesh.faces[$0].group, $0) < (mesh.faces[$1].group, $1) }
        for index in order {
            let face = mesh.faces[index]
            if runs != nil, face.group >= 0, face.group < groupMaterial.count {
                let material = groupMaterial[face.group]
                if current == nil || current! != material {
                    current = .some(material)
                    out += "usemtl \(material.flatMap { $0 < names.count ? names[$0] : nil } ?? stockName)\n"
                }
            }
            out += "f"
            for corner in face.corners {
                out += " \(corner.v + offsets.vertices + 1)//\(corner.n + offsets.normals + 1)"
            }
            out += "\n"
        }
        offsets.vertices += mesh.positions.count
        offsets.normals += mesh.normals.count
    }

    /// A name with no white space in it (OBJ and MTL names end at a space).
    private static func label(_ name: String) -> String {
        let cleaned = String(name.map { $0.isWhitespace ? "_" : $0 })
        return cleaned.isEmpty ? "Body" : cleaned
    }

    // MARK: - Clean mesh

    struct Face {
        /// Indices into `CleanMesh.positions` / `.normals`, counter-clockwise
        /// seen from outside.
        var corners: [(v: Int, n: Int)]
        /// The group of the triangles it was made from (0 without groups).
        var group: Int
    }

    struct CleanMesh {
        var positions: [SIMD3<Float>] = []
        var normals: [SIMD3<Float>] = []
        var faces: [Face] = []
    }

    /// Positions closer than this (model units, mm) are one vertex.
    private static let weld: Double = 1e-5
    /// Two triangles are "in one plane" when their unit normals agree to
    /// this cosine (about 0.08°). A cylinder wall's neighbouring strips
    /// differ by degrees, a fillet's by more than one: neither merges.
    private static let coplanarCosine: Double = 0.999999
    /// How far a corner may bend the wrong way and still count as convex,
    /// as the sine of the turn (so it does not depend on the face's size).
    private static let convexSlack: Double = 1e-7

    /// The welded, polygon-merged form of `mesh`. `triangleGroups` gives a
    /// group per triangle; triangles of different groups never merge.
    static func cleanMesh(from mesh: RenderMesh, triangleGroups: [Int]? = nil) -> CleanMesh {
        let triangleCount = mesh.triangleCount
        guard triangleCount > 0 else { return CleanMesh() }

        // Weld positions, de-duplicate normals.
        var vertexOf: [SIMD3<Int64>: Int] = [:]
        var positions: [SIMD3<Double>] = []
        func vertex(_ p: SIMD3<Float>) -> Int {
            let d = SIMD3<Double>(p)
            let key = SIMD3<Int64>(Int64((d.x / weld).rounded()), Int64((d.y / weld).rounded()), Int64((d.z / weld).rounded()))
            if let found = vertexOf[key] { return found }
            vertexOf[key] = positions.count
            positions.append(d)
            return positions.count - 1
        }
        var normalOf: [SIMD3<Int32>: Int] = [:]
        var normals: [SIMD3<Float>] = []
        func normal(_ n: SIMD3<Double>) -> Int {
            let length = simd_length(n)
            let unit = length > 1e-12 && length.isFinite ? n / length : SIMD3<Double>(0, 1, 0)
            let key = SIMD3<Int32>(Int32((unit.x * 1e5).rounded()), Int32((unit.y * 1e5).rounded()), Int32((unit.z * 1e5).rounded()))
            if let found = normalOf[key] { return found }
            normalOf[key] = normals.count
            normals.append(SIMD3<Float>(unit))
            return normals.count - 1
        }

        // Half-edges: three per kept triangle, edge k running from corner k
        // to corner k + 1. Zero-area triangles are dropped.
        var origin: [Int] = []          // welded vertex the half-edge leaves
        var shading: [Int] = []         // normal index at that vertex
        var next: [Int] = [], prev: [Int] = []
        var piece: [Int] = []           // the polygon (by its first triangle) it bounds
        var planeNormal: [SIMD3<Double>] = []   // per piece
        var pieceGroup: [Int] = []
        let hasNormals = mesh.normals.count == mesh.positions.count
        for t in 0..<triangleCount {
            let raw = (0..<3).map { Int(mesh.indices[3 * t + $0]) }
            guard raw.allSatisfy({ $0 < mesh.positions.count }) else { continue }
            let v = raw.map { vertex(mesh.positions[$0]) }
            guard v[0] != v[1], v[1] != v[2], v[2] != v[0] else { continue }
            let cross = simd_cross(positions[v[1]] - positions[v[0]], positions[v[2]] - positions[v[0]])
            let area2 = simd_length(cross)
            guard area2 > 1e-18, area2.isFinite else { continue }
            let flat = cross / area2
            let base = origin.count
            let id = planeNormal.count
            for k in 0..<3 {
                origin.append(v[k])
                shading.append(normal(hasNormals ? SIMD3<Double>(mesh.normals[raw[k]]) : flat))
                next.append(base + (k + 1) % 3)
                prev.append(base + (k + 2) % 3)
                piece.append(id)
            }
            planeNormal.append(flat)
            pieceGroup.append(triangleGroups.flatMap { t < $0.count ? $0[t] : nil } ?? 0)
        }
        let edgeCount = origin.count
        guard edgeCount > 0 else { return CleanMesh() }

        // Twins: the half-edge running the other way along the same edge.
        // An edge used more than once in one direction is non-manifold and
        // gets no twin, so nothing merges across it.
        struct Span: Hashable { let from: Int, to: Int }
        var bySpan: [Span: Int] = [:]
        var crowded: Set<Span> = []
        for h in 0..<edgeCount {
            let span = Span(from: origin[h], to: origin[next[h]])
            if bySpan.updateValue(h, forKey: span) != nil { crowded.insert(span) }
        }
        var twin = [Int](repeating: -1, count: edgeCount)
        for h in 0..<edgeCount {
            let span = Span(from: origin[h], to: origin[next[h]])
            let back = Span(from: span.to, to: span.from)
            guard !crowded.contains(span), !crowded.contains(back), let other = bySpan[back] else { continue }
            twin[h] = other
        }

        // Pieces merge; `root` finds the piece a half-edge's polygon now is.
        var parent = Array(planeNormal.indices)
        var size = [Int](repeating: 3, count: planeNormal.count)
        func root(_ p: Int) -> Int {
            var r = p
            while parent[r] != r { r = parent[r] }
            var walk = p
            while parent[walk] != r { let up = parent[walk]; parent[walk] = r; walk = up }
            return r
        }
        var removed = [Bool](repeating: false, count: edgeCount)
        func destination(_ h: Int) -> Int { origin[next[h]] }
        func convex(at corner: Int, from before: Int, to after: Int, about n: SIMD3<Double>) -> Bool {
            let incoming = positions[corner] - positions[before]
            let outgoing = positions[after] - positions[corner]
            let scale = simd_length(incoming) * simd_length(outgoing)
            return simd_dot(simd_cross(incoming, outgoing), n) >= -convexSlack * scale
        }

        // Hertel–Mehlhorn: drop each shared edge that both ends can spare.
        for seed in 0..<edgeCount where !removed[seed] && twin[seed] >= 0 && !removed[twin[seed]] {
            let p = root(piece[seed]), q = root(piece[twin[seed]])
            guard p != q, pieceGroup[p] == pieceGroup[q],
                  simd_dot(planeNormal[p], planeNormal[q]) > coplanarCosine else { continue }

            // The two pieces may meet along several edges in a row (a
            // straight seam with a vertex on it): take the whole seam.
            var first = seed, last = seed, seam = 1
            while seam < size[p] {
                let before = prev[first]
                guard twin[before] >= 0, !removed[twin[before]], twin[before] == next[twin[first]] else { break }
                first = before; seam += 1
            }
            while seam < size[p] {
                let after = next[last]
                guard twin[after] >= 0, !removed[twin[after]], twin[after] == prev[twin[last]] else { break }
                last = after; seam += 1
            }
            guard size[p] + size[q] - 2 * seam >= 3, seam < size[p], seam < size[q] else { continue }

            // Around the seam's two ends, A (where it starts in p) and B:
            //   p:  … x → A ═seam═ B → z …        q:  … w → B ═seam═ A → y …
            let a = origin[first], b = destination(last)
            let intoA = prev[first], outOfA = next[twin[first]]
            let intoB = prev[twin[last]], outOfB = next[last]
            let x = origin[intoA], y = destination(outOfA)
            let w = origin[intoB], z = destination(outOfB)
            guard x != y, w != z,
                  // Both sides shade A and B alike, so no crease is erased.
                  shading[first] == shading[outOfA], shading[twin[last]] == shading[outOfB],
                  convex(at: a, from: x, to: y, about: planeNormal[p]),
                  convex(at: b, from: w, to: z, about: planeNormal[p]) else { continue }

            var h = first
            while true {
                removed[h] = true
                removed[twin[h]] = true
                if h == last { break }
                h = next[h]
            }
            next[intoA] = outOfA; prev[outOfA] = intoA
            next[intoB] = outOfB; prev[outOfB] = intoB
            parent[q] = p
            size[p] += size[q] - 2 * seam
        }

        // Read the surviving rings back out.
        var faces: [Face] = []
        var seen = [Bool](repeating: false, count: edgeCount)
        for start in 0..<edgeCount where !removed[start] && !seen[start] {
            var corners: [(v: Int, n: Int)] = []
            var h = start
            while !seen[h] {
                seen[h] = true
                corners.append((origin[h], shading[h]))
                h = next[h]
                if corners.count > edgeCount { break }   // a broken ring: never loop forever
            }
            if corners.count >= 3 { faces.append(Face(corners: corners, group: pieceGroup[root(piece[start])])) }
        }

        // Keep only the positions some face still uses, in their first order.
        var remap = [Int](repeating: -1, count: positions.count)
        var result = CleanMesh()
        for face in faces {
            for corner in face.corners where remap[corner.v] < 0 { remap[corner.v] = 0 }
        }
        for index in positions.indices where remap[index] == 0 {
            remap[index] = result.positions.count
            result.positions.append(SIMD3<Float>(positions[index]))
        }
        result.normals = normals
        result.faces = faces.map { Face(corners: $0.corners.map { (remap[$0.v], $0.n) }, group: $0.group) }
        return result
    }
}
