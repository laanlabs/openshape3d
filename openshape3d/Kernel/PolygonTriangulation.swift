//
//  PolygonTriangulation.swift
//  openshape3d
//
//  Triangles for a planar polygon given as a ring of corners — what an OBJ
//  `f` line with more than three corners needs. A convex ring is a fan from
//  its first corner. A concave one (Blender writes an L-shaped face as one
//  n-gon) is ear-clipped: a fan there would lay triangles across the notch.
//

import Foundation
import simd

nonisolated enum PolygonTriangulation {

    /// Index triples into `ring`, wound the way the ring is. Always
    /// `ring.count - 2` triangles for three or more corners; empty below.
    static func triangles(of ring: [SIMD3<Double>]) -> [(Int, Int, Int)] {
        let count = ring.count
        guard count >= 3 else { return [] }
        let fan = (1..<(count - 1)).map { (0, $0, $0 + 1) }
        guard count > 3 else { return fan }

        // Newell's normal: robust for any planar ring, convex or not.
        var normal = SIMD3<Double>.zero
        for i in 0..<count {
            let a = ring[i], b = ring[(i + 1) % count]
            normal.x += (a.y - b.y) * (a.z + b.z)
            normal.y += (a.z - b.z) * (a.x + b.x)
            normal.z += (a.x - b.x) * (a.y + b.y)
        }
        let length = simd_length(normal)
        guard length > 1e-30, length.isFinite else { return fan }   // no area: nothing better to do
        normal /= length

        // Work in the plane: drop the axis the normal mostly points along,
        // keeping the ring counter-clockwise.
        let flat: [SIMD2<Double>] = ring.map { p in
            if abs(normal.z) >= abs(normal.x), abs(normal.z) >= abs(normal.y) {
                return normal.z > 0 ? SIMD2(p.x, p.y) : SIMD2(p.y, p.x)
            } else if abs(normal.y) >= abs(normal.x) {
                return normal.y > 0 ? SIMD2(p.z, p.x) : SIMD2(p.x, p.z)
            } else {
                return normal.x > 0 ? SIMD2(p.y, p.z) : SIMD2(p.z, p.y)
            }
        }
        func turn(_ a: Int, _ b: Int, _ c: Int) -> Double {
            let u = flat[b] - flat[a], v = flat[c] - flat[b]
            return u.x * v.y - u.y * v.x
        }
        var extent = 0.0
        for p in flat { extent = max(extent, abs(p.x), abs(p.y)) }
        let slack = 1e-12 * max(extent * extent, 1e-300)

        if (0..<count).allSatisfy({ turn($0, ($0 + 1) % count, ($0 + 2) % count) >= -slack }) { return fan }

        func holds(_ p: Int, _ a: Int, _ b: Int, _ c: Int) -> Bool {
            func side(_ u: Int, _ v: Int) -> Double {
                let e = flat[v] - flat[u], d = flat[p] - flat[u]
                return e.x * d.y - e.y * d.x
            }
            return side(a, b) >= -slack && side(b, c) >= -slack && side(c, a) >= -slack
        }

        var left = Array(0..<count)
        var out: [(Int, Int, Int)] = []
        out.reserveCapacity(count - 2)
        while left.count > 3 {
            var cut: Int?
            for i in left.indices {
                let a = left[(i + left.count - 1) % left.count], b = left[i], c = left[(i + 1) % left.count]
                guard turn(a, b, c) > slack else { continue }      // a reflex or straight corner is no ear
                // An ear holds no other corner (ones sitting exactly on its
                // own corners do not count: a ring may touch itself there).
                let blocked = left.contains { p in
                    p != a && p != b && p != c
                        && flat[p] != flat[a] && flat[p] != flat[b] && flat[p] != flat[c]
                        && holds(p, a, b, c)
                }
                if !blocked { cut = i; break }
            }
            guard let cut else {
                // Self-crossing or degenerate: finish what is left as a fan.
                for k in 1..<(left.count - 1) { out.append((left[0], left[k], left[k + 1])) }
                return out
            }
            out.append((left[(cut + left.count - 1) % left.count], left[cut], left[(cut + 1) % left.count]))
            left.remove(at: cut)
        }
        out.append((left[0], left[1], left[2]))
        return out
    }
}
