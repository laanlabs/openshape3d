//
//  ExtrudeCapSearchTests.swift
//  openshape3dTests
//
//  `SignatureNaming.capPair` picks an extrude's two caps among its planar
//  faces. It used to score every pair, which froze the editor on a faceted
//  spline (thousands of wall strips, each a planar face). The search that
//  replaced it must give the SAME pair, ties included, since face names
//  hang off it: it is compared here with the every-pair definition on
//  random and awkward inputs, and timed on a size that used to take minutes.
//

import XCTest
import simd
@testable import openshape3d

final class ExtrudeCapSearchTests: XCTestCase {

    /// A small generator with a fixed seed: failures reproduce.
    private struct Generator {
        var state: UInt64
        mutating func next() -> Double {
            state = state &* 6364136223846793005 &+ 1442695040888963407
            return Double(state >> 11) / Double(1 << 53)
        }
        mutating func unitVector() -> SIMD3<Double> {
            while true {
                let v = SIMD3(next() * 2 - 1, next() * 2 - 1, next() * 2 - 1)
                let length = simd_length(v)
                if length > 0.05, length <= 1 { return v / length }
            }
        }
    }

    private func assertSameAsEveryPair(_ normals: [SIMD3<Double>], _ areas: [Double], profileArea: Double,
                                       _ what: String, file: StaticString = #filePath, line: UInt = #line) {
        let fast = SignatureNaming.capPair(normals: normals, areas: areas, profileArea: profileArea)
        let plain = SignatureNaming.capPairByEveryPair(units: normals.map(SignatureNaming.unit), areas: areas,
                                                       profileArea: profileArea)
        XCTAssertEqual(fast.map { [$0.0, $0.1] }, plain.map { [$0.0, $0.1] }, what, file: file, line: line)
    }

    func testRandomFacesGiveTheSamePairAsScoringEveryPair() {
        var random = Generator(state: 42)
        for trial in 0..<400 {
            let count = 2 + Int(random.next() * 60)
            var normals: [SIMD3<Double>] = [], areas: [Double] = []
            for _ in 0..<count {
                var n = random.unitVector()
                // Often make a face the exact opposite of an earlier one, as caps are.
                if !normals.isEmpty, random.next() < 0.4 { n = -normals[Int(random.next() * Double(normals.count))] }
                normals.append(n * (0.5 + random.next()))            // signatures are not always unit length
                areas.append(random.next() < 0.3 ? 100 : random.next() * 300)
            }
            assertSameAsEveryPair(normals, areas, profileArea: 100, "trial \(trial), \(count) faces")
        }
    }

    func testTiesFallTheWayTheyAlwaysDid() {
        // Many faces with the very same normals and areas: every up/down pair
        // scores alike, and the first pair in order must win.
        var normals: [SIMD3<Double>] = [], areas: [Double] = []
        for i in 0..<40 {
            normals.append(i % 3 == 0 ? SIMD3(0, -1, 0) : SIMD3(0, 1, 0))
            areas.append(i % 5 == 0 ? 50 : 20)
        }
        assertSameAsEveryPair(normals, areas, profileArea: 50, "identical caps")
        assertSameAsEveryPair(normals, areas, profileArea: 1e6, "no area anywhere near the profile's")
        assertSameAsEveryPair(normals, areas, profileArea: 0, "a profile with no area")
        // Nothing faces away from anything.
        XCTAssertNil(SignatureNaming.capPair(normals: [SIMD3(0, 1, 0), SIMD3(0, 1, 0), SIMD3(1, 0, 0)],
                                             areas: [1, 1, 1], profileArea: 1))
        XCTAssertNil(SignatureNaming.capPair(normals: [SIMD3(0, 1, 0)], areas: [1], profileArea: 1))
        XCTAssertNil(SignatureNaming.capPair(normals: [], areas: [], profileArea: 1))
    }

    func testNumbersThatAreNotNumbersFallBackToThePlainSearch() {
        let normals = [SIMD3(0, 1, 0), SIMD3(Double.nan, 0, 0), SIMD3(0, -1, 0), SIMD3(0, 0, 0)]
        assertSameAsEveryPair(normals, [10, 10, 10, 10], profileArea: 10, "a NaN normal and a zero one")
        assertSameAsEveryPair([SIMD3(0, 1, 0), SIMD3(0, -1, 0)], [.nan, 10], profileArea: 10, "a NaN area")
        assertSameAsEveryPair([SIMD3(0, 1, 0), SIMD3(0, -1, 0)], [10, 10], profileArea: .nan, "a NaN profile area")
    }

    /// An extruded spline as the namer sees it: two caps, and a ring of wall
    /// strips whose normals go all the way round. `axis` is the extrude
    /// direction, so the ring is tried in every orientation.
    private func extrusion(strips: Int, axis: SIMD3<Double>, radius: Double = 800, depth: Double = 20)
        -> (normals: [SIMD3<Double>], areas: [Double], profileArea: Double) {
        let up = simd_normalize(axis)
        let side = simd_normalize(simd_cross(up, abs(up.x) < 0.9 ? SIMD3(1, 0, 0) : SIMD3(0, 1, 0)))
        let other = simd_cross(up, side)
        var normals: [SIMD3<Double>] = [], areas: [Double] = []
        let strip = 2 * Double.pi * radius / Double(strips) * depth
        for i in 0..<strips {
            let angle = 2 * Double.pi * Double(i) / Double(strips)
            // A wavy outline: neighbours are not evenly turned, and some strips face inwards.
            let wobble = 0.6 * sin(7 * angle)
            normals.append(simd_normalize(side * cos(angle + wobble) + other * sin(angle + wobble)))
            areas.append(strip * (0.5 + 0.5 * abs(sin(3 * angle))))
        }
        let profileArea = Double.pi * radius * radius
        // The caps sit in the middle of the list, not at its ends.
        normals.insert(up, at: strips / 3); areas.insert(profileArea, at: strips / 3)
        normals.insert(-up, at: 2 * strips / 3); areas.insert(profileArea * 0.999, at: 2 * strips / 3)
        return (normals, areas, profileArea)
    }

    func testAnExtrudedOutlineFindsItsCapsInEveryOrientation() {
        for axis in [SIMD3<Double>(0, 1, 0), SIMD3(1, 0, 0), SIMD3(0, 0, 1), SIMD3(1, 2, 3), SIMD3(-2, 0.1, 5)] {
            let shape = extrusion(strips: 300, axis: axis)
            assertSameAsEveryPair(shape.normals, shape.areas, profileArea: shape.profileArea, "axis \(axis)")
            let pair = SignatureNaming.capPair(normals: shape.normals, areas: shape.areas, profileArea: shape.profileArea)
            XCTAssertEqual(pair.map { [$0.0, $0.1] }, [100, 200], "the two caps, where they were put")
        }
    }

    func testAThickWalledRingWithoutCapsIsStillTheSame() {
        // No face has the profile's area: the walls decide it among themselves.
        var shape = extrusion(strips: 240, axis: SIMD3(0, 1, 0))
        shape.normals.remove(at: 160); shape.areas.remove(at: 160)
        shape.normals.remove(at: 80); shape.areas.remove(at: 80)
        assertSameAsEveryPair(shape.normals, shape.areas, profileArea: shape.profileArea, "no caps")
    }

    /// The whole path on a real extrusion: a 300-point star, whose sharp
    /// corners keep every wall strip a face of its own. Its face table names
    /// exactly one start cap and one end cap, and every strip a wall.
    func testAnExtrudedStarIsNamedCapsAndWalls() {
        let points = 300
        let loop: [SIMD2<Double>] = (0..<points).map { i in
            let angle = 2 * Double.pi * Double(i) / Double(points)
            let radius = i % 2 == 0 ? 800.0 : 700.0
            return SIMD2(radius * cos(angle), radius * sin(angle))
        }
        let profile = Profile(loop: loop, kind: .polygonal, sourceEntityIDs: [UUID()])
        let mesh = KernelOps.extrude(profile: profile, in: .ground, distance: 25)
        let body = Body(name: "Star", transform: .identity, euclidMesh: mesh, revision: 1)
        let table = SignatureNaming().faceTable(for: body, createdBy: FeatureID(), scheme: .extrude(profile))
        XCTAssertEqual(table.entries.filter { $0.role == .extrudeStartCap }.count, 1)
        XCTAssertEqual(table.entries.filter { $0.role == .extrudeEndCap }.count, 1)
        let walls = table.entries.filter { if case .extrudeWall = $0.role { return true } else { return false } }
        XCTAssertEqual(walls.count, points, "one wall per edge of the star")
        XCTAssertEqual(table.entries.count, points + 2)
    }

    /// What used to take minutes: tens of thousands of wall strips.
    func testTwentyThousandWallStripsTakeNoTimeAtAll() {
        let shape = extrusion(strips: 20_000, axis: SIMD3(0.2, 1, 0.1))
        let started = Date()
        let pair = SignatureNaming.capPair(normals: shape.normals, areas: shape.areas, profileArea: shape.profileArea)
        let seconds = Date().timeIntervalSince(started)
        XCTAssertEqual(pair.map { [$0.0, $0.1] }, [20_000 / 3, 2 * 20_000 / 3])
        XCTAssertLessThan(seconds, 1, "the cap search took \(seconds) s on 20 002 faces")
    }

    /// The same size with nothing to set the bar early: no caps at all.
    func testTwentyThousandWallStripsWithoutCapsStayAffordable() {
        var shape = extrusion(strips: 20_000, axis: SIMD3(0.2, 1, 0.1))
        shape.normals.remove(at: 2 * 20_000 / 3); shape.areas.remove(at: 2 * 20_000 / 3)
        shape.normals.remove(at: 20_000 / 3); shape.areas.remove(at: 20_000 / 3)
        let started = Date()
        let pair = SignatureNaming.capPair(normals: shape.normals, areas: shape.areas, profileArea: shape.profileArea)
        let seconds = Date().timeIntervalSince(started)
        XCTAssertNotNil(pair, "some two strips face away from each other")
        XCTAssertLessThan(seconds, 5, "the cap search took \(seconds) s on 20 000 faces with no caps")
    }
}
