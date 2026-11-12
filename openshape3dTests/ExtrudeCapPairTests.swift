//
//  ExtrudeCapPairTests.swift
//  openshape3dTests
//
//  `SignatureNaming.capPair` finds an extrude's two caps among the planar
//  faces of its render mesh. It used to score every pair (O(n²)); a curved
//  wall meshed into thousands of thin planar strips froze the editor for
//  minutes. These tests pin that the pruned search returns exactly what the
//  exhaustive one did — ties included — and that it stays fast.
//

import XCTest
import simd
@testable import openshape3d

@MainActor
final class ExtrudeCapPairTests: XCTestCase {

    /// The search as it was before (exhaustive, first best score wins).
    private func exhaustive(_ normals: [SIMD3<Double>], _ areas: [Double], _ profileArea: Double) -> (Int, Int)? {
        func unit(_ v: SIMD3<Double>) -> SIMD3<Double> { let l = simd_length(v); return l > 1e-12 ? v / l : v }
        var best: (Int, Int)?
        var bestScore = -Double.infinity
        for a in 0..<normals.count {
            for b in (a + 1)..<normals.count {
                let anti = -simd_dot(unit(normals[a]), unit(normals[b]))
                guard anti > 0.9 else { continue }
                let areaMatch = 1 - min(1, (abs(areas[a] - profileArea) + abs(areas[b] - profileArea)) / max(profileArea, 1e-9))
                let s = anti + areaMatch
                if s > bestScore { bestScore = s; best = (a, b) }
            }
        }
        return best
    }

    /// Deterministic pseudo-random numbers (no global state).
    private struct LCG {
        var state: UInt64
        mutating func next() -> Double {
            state = state &* 6364136223846793005 &+ 1442695040888963407
            return Double(state >> 11) / Double(1 << 53)
        }
    }

    /// The planar faces of an extrude as the render mesh shows them: two caps
    /// (area ≈ profile) at random positions in the list, `strips` thin wall
    /// facets around the axis, plus a few odd faces (a boss, a pocket floor).
    private func extrudeLikeFaces(strips: Int, seed: UInt64) -> ([SIMD3<Double>], [Double], Double) {
        var rng = LCG(state: seed)
        let axis = simd_normalize(SIMD3(rng.next() - 0.5, rng.next() - 0.5, rng.next() - 0.5))
        let side = simd_normalize(simd_cross(axis, abs(axis.x) < 0.9 ? SIMD3(1, 0, 0) : SIMD3(0, 1, 0)))
        let up = simd_cross(axis, side)
        let profileArea = 1000 + 50_000 * rng.next()
        var faces: [(SIMD3<Double>, Double)] = []
        for k in 0..<strips {
            let a = 2 * Double.pi * (Double(k) + rng.next() * 0.3) / Double(strips)
            faces.append((cos(a) * side + sin(a) * up, profileArea * (0.2 + rng.next()) / Double(max(strips, 1)) * 4))
        }
        for _ in 0..<3 {   // odd extra planar faces, any orientation
            faces.append((simd_normalize(SIMD3(rng.next() - 0.5, rng.next() - 0.5, rng.next() - 0.5)), profileArea * rng.next()))
        }
        let cap1 = (axis, profileArea * (1 + 0.01 * (rng.next() - 0.5)))
        let cap2 = (-axis, profileArea * (1 + 0.01 * (rng.next() - 0.5)))
        faces.insert(cap1, at: Int(rng.next() * Double(faces.count)))
        faces.insert(cap2, at: Int(rng.next() * Double(faces.count)))
        return (faces.map(\.0), faces.map(\.1), profileArea)
    }

    func testSameCapsAsTheExhaustiveSearchOnExtrudeLikeFaces() {
        for (i, strips) in [8, 40, 70, 150, 400, 900].enumerated() {
            for seed in 0..<6 as Range<UInt64> {
                let (normals, areas, profile) = extrudeLikeFaces(strips: strips, seed: seed &* 7919 &+ UInt64(i))
                let expected = exhaustive(normals, areas, profile)
                let got = SignatureNaming.capPair(normals: normals, areas: areas, profileArea: profile)
                XCTAssertEqual(got?.0, expected?.0, "strips \(strips) seed \(seed)")
                XCTAssertEqual(got?.1, expected?.1, "strips \(strips) seed \(seed)")
            }
        }
    }

    /// A cube extruded from a square: all three opposite pairs score the same;
    /// the first pair in face order must still win, as before.
    func testTiesResolveToTheSameFirstPair() {
        let normals: [SIMD3<Double>] = [SIMD3(1, 0, 0), SIMD3(0, 1, 0), SIMD3(0, 0, 1),
                                        SIMD3(-1, 0, 0), SIMD3(0, -1, 0), SIMD3(0, 0, -1)]
        let areas = [Double](repeating: 100, count: 6)
        let expected = exhaustive(normals, areas, 100)
        let got = SignatureNaming.capPair(normals: normals, areas: areas, profileArea: 100)
        XCTAssertEqual(got?.0, expected?.0); XCTAssertEqual(got?.1, expected?.1)
        // Same with many strips around it, so the pruned path is the one taken.
        var n2 = normals, a2 = areas
        for k in 0..<500 { let t = Double(k) * 0.0125; n2.append(SIMD3(cos(t), 0, sin(t)) * 0.5 + SIMD3(0, 0.3, 0)); a2.append(0.2) }
        let e2 = exhaustive(n2, a2, 100), g2 = SignatureNaming.capPair(normals: n2, areas: a2, profileArea: 100)
        XCTAssertEqual(g2?.0, e2?.0); XCTAssertEqual(g2?.1, e2?.1)
    }

    /// Up to the candidate limit it is the exhaustive search, whatever the faces.
    func testSmallSetsMatchForAnyFaces() {
        var rng = LCG(state: 42)
        for _ in 0..<200 {
            let n = 2 + Int(rng.next() * 60)
            let normals = (0..<n).map { _ in SIMD3(rng.next() - 0.5, rng.next() - 0.5, rng.next() - 0.5) }
            let areas = (0..<n).map { _ in rng.next() * 100 }
            let p = rng.next() * 100
            let e = exhaustive(normals, areas, p), g = SignatureNaming.capPair(normals: normals, areas: areas, profileArea: p)
            XCTAssertEqual(g?.0, e?.0); XCTAssertEqual(g?.1, e?.1)
        }
    }

    /// The case that froze the editor: a large closed spline meshed into tens of
    /// thousands of planar strips. The exhaustive search scores ~2·10⁸ pairs.
    func testTwentyThousandStripsFindTheCapsQuickly() {
        let (normals, areas, profile) = extrudeLikeFaces(strips: 20_000, seed: 7)
        let start = Date()
        let pair = SignatureNaming.capPair(normals: normals, areas: areas, profileArea: profile)
        let seconds = Date().timeIntervalSince(start)
        let found = try? XCTUnwrap(pair)
        XCTAssertNotNil(found)
        if let (a, b) = found {
            XCTAssertLessThan(simd_dot(simd_normalize(normals[a]), simd_normalize(normals[b])), -0.99, "the two caps")
            XCTAssertEqual(areas[a], profile, accuracy: profile * 0.01)
        }
        XCTAssertLessThan(seconds, 1.0, "was minutes with the exhaustive search")
    }
}
