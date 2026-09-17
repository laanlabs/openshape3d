//
//  SweepLoftTests.swift
//  openshape3dTests
//
//  KernelOps.sweep / KernelOps.loft / HelixKit: transported sweep sections,
//  mitred corners, loft resampling, helix spine generation.
//

import XCTest
import Euclid
import simd
@testable import openshape3d

final class SweepLoftTests: XCTestCase {

    /// XY sketch plane (normal +Z): plane-local coords equal world XY.
    private let xyPlane = SketchPlane(
        origin: .zero,
        xAxis: SIMD3(1, 0, 0),
        yAxis: SIMD3(0, 1, 0)
    )

    private func squareProfile(
        center: SIMD2<Double> = .zero, halfSize: Double
    ) -> Profile {
        let h = halfSize
        return Profile(
            loop: [
                center + SIMD2(-h, -h), center + SIMD2(h, -h),
                center + SIMD2(h, h), center + SIMD2(-h, h),
            ],
            kind: .polygonal,
            sourceEntityIDs: []
        )
    }

    private func circleProfile(
        center: SIMD2<Double>, radius: Double, segments: Int = 48
    ) -> Profile {
        let loop = (0..<segments).map { i -> SIMD2<Double> in
            let angle = Double(i) / Double(segments) * 2 * .pi
            return center + radius * SIMD2(cos(angle), sin(angle))
        }
        return Profile(
            loop: loop,
            kind: .circle(center: center, radius: radius),
            sourceEntityIDs: []
        )
    }

    /// Signed-tetrahedron volume of a closed mesh.
    private func volume(of mesh: Euclid.Mesh) -> Double {
        var sum = 0.0
        for polygon in mesh.triangulate().polygons {
            let v = polygon.vertices
            let p0 = SIMD3(v[0].position.x, v[0].position.y, v[0].position.z)
            let p1 = SIMD3(v[1].position.x, v[1].position.y, v[1].position.z)
            let p2 = SIMD3(v[2].position.x, v[2].position.y, v[2].position.z)
            sum += simd_dot(p0, simd_cross(p1, p2))
        }
        return abs(sum) / 6
    }

    // MARK: - Sweep

    func testSweepSquareAlongStraightLineMatchesExtrude() {
        // Unit square in [0, 1]² swept 2 up the plane normal == extrude(2).
        let profile = Profile(
            loop: [SIMD2(0, 0), SIMD2(1, 0), SIMD2(1, 1), SIMD2(0, 1)],
            kind: .polygonal,
            sourceEntityIDs: []
        )
        let spine: [SIMD3<Double>] = [SIMD3(0, 0, 0), SIMD3(0, 0, 2)]
        let swept = KernelOps.sweep(profile: profile, in: xyPlane, alongPath: spine)
        let extruded = KernelOps.extrude(profile: profile, in: xyPlane, distance: 2)

        XCTAssertFalse(swept.polygons.isEmpty)
        XCTAssertTrue(swept.isWatertight)

        let s = swept.bounds, e = extruded.bounds
        XCTAssertEqual(s.min.x, e.min.x, accuracy: 1e-9)
        XCTAssertEqual(s.min.y, e.min.y, accuracy: 1e-9)
        XCTAssertEqual(s.min.z, e.min.z, accuracy: 1e-9)
        XCTAssertEqual(s.max.x, e.max.x, accuracy: 1e-9)
        XCTAssertEqual(s.max.y, e.max.y, accuracy: 1e-9)
        XCTAssertEqual(s.max.z, e.max.z, accuracy: 1e-9)
        XCTAssertEqual(volume(of: swept), 2, accuracy: 1e-9)
    }

    func testSweepAlongLShapedSpine() {
        // 0.5×0.5 square swept up 2 then right 2: the mitred corner makes
        // the solid the union of the two straight legs.
        let profile = squareProfile(halfSize: 0.25)
        let spine: [SIMD3<Double>] = [
            SIMD3(0, 0, 0), SIMD3(0, 0, 2), SIMD3(2, 0, 2),
        ]
        let mesh = KernelOps.sweep(profile: profile, in: xyPlane, alongPath: spine)

        XCTAssertFalse(mesh.polygons.isEmpty)
        XCTAssertTrue(mesh.isWatertight)

        let bounds = mesh.bounds
        XCTAssertEqual(bounds.min.x, -0.25, accuracy: 1e-9)
        XCTAssertEqual(bounds.min.y, -0.25, accuracy: 1e-9)
        XCTAssertEqual(bounds.min.z, 0, accuracy: 1e-9)
        XCTAssertEqual(bounds.max.x, 2, accuracy: 1e-9)
        XCTAssertEqual(bounds.max.y, 0.25, accuracy: 1e-9)
        XCTAssertEqual(bounds.max.z, 2.25, accuracy: 1e-9)

        // Two 0.5×0.5 boxes of centreline length 2.25 minus the shared
        // 0.5³ corner cube.
        XCTAssertEqual(volume(of: mesh), 1.0, accuracy: 1e-9)
    }

    func testSweepWithHoleCarvesTube() {
        // Square ring swept along a straight spine -> square tube.
        let outer = squareProfile(halfSize: 0.5)
        let hole = squareProfile(halfSize: 0.25)
        let spine: [SIMD3<Double>] = [SIMD3(0, 0, 0), SIMD3(0, 0, 1)]
        let mesh = KernelOps.sweep(
            profile: outer, holes: [hole], in: xyPlane, alongPath: spine
        )

        XCTAssertFalse(mesh.polygons.isEmpty)
        XCTAssertTrue(mesh.isWatertight)
        // 1×1×1 minus the 0.5×0.5×1 core.
        XCTAssertEqual(volume(of: mesh), 0.75, accuracy: 1e-6)
    }

    /// The holed sweep is built without a boolean: outer and hole walls from
    /// the same frames, caps triangulated with the hole. So a spline outline's
    /// 1,152 samples with a 64-gon bore — the profile that wedged the extrude
    /// in BSP CSG (gotcha 24) — sweeps in milliseconds, watertight, to the
    /// exact prism volume (A_outer − A_bore) × length.
    func testSweepOfADenseSplineOutlineWithABoreIsFastAndExact() {
        let n = 1152
        let outerLoop = (0..<n).map { i -> SIMD2<Double> in
            let phi = Double(i) / Double(n) * 2 * .pi
            let r = phi <= .pi ? 20 + 10 * (phi / .pi - sin(2 * phi) / (2 * .pi))
                : (phi <= 1.5 * .pi ? 30 : 30 - 10 * ((phi - 1.5 * .pi) / (0.5 * .pi) - sin(2 * .pi * (phi - 1.5 * .pi) / (0.5 * .pi)) / (2 * .pi)))
            return SIMD2(r * cos(phi), r * sin(phi))
        }
        let outer = Profile(loop: outerLoop, kind: .polygonal, sourceEntityIDs: [])
        let bore = circleProfile(center: .zero, radius: 5, segments: 64)
        let spine: [SIMD3<Double>] = [SIMD3(0, 0, 0), SIMD3(0, 0, 8)]
        let start = Date()
        let mesh = KernelOps.sweep(profile: outer, holes: [bore], in: xyPlane, alongPath: spine)
        let seconds = Date().timeIntervalSince(start)
        XCTAssertTrue(mesh.isWatertight)
        let want = (Profile.signedArea(outerLoop) - Profile.signedArea(bore.loop)) * 8
        XCTAssertEqual(volume(of: mesh), want, accuracy: want * 1e-6)
        XCTAssertLessThan(seconds, 1.0, "swept in \(seconds) s")
    }

    /// No holes at all is the same builder, and just as fast: the dense
    /// outline swept and lofted without a bore, exact prism / frustum volumes.
    func testDenseOutlinesWithoutHolesSweepAndLoftFast() {
        let n = 1152
        let loop = (0..<n).map { i -> SIMD2<Double> in
            let phi = Double(i) / Double(n) * 2 * .pi
            let r = 25 + 5 * sin(3 * phi)
            return SIMD2(r * cos(phi), r * sin(phi))
        }
        let base = Profile(loop: loop, kind: .polygonal, sourceEntityIDs: [])
        let top = Profile(loop: loop.map { $0 * 0.9 }, kind: .polygonal, sourceEntityIDs: [])
        let z8 = SketchPlane(origin: SIMD3(0, 0, 8), xAxis: SIMD3(1, 0, 0), yAxis: SIMD3(0, 1, 0))
        let start = Date()
        let swept = KernelOps.sweep(profile: base, in: xyPlane, alongPath: [SIMD3(0, 0, 0), SIMD3(0, 0, 8)])
        let lofted = KernelOps.loft(profiles: [(profile: base, holes: [], plane: xyPlane), (profile: top, holes: [], plane: z8)])
        let seconds = Date().timeIntervalSince(start)
        XCTAssertTrue(swept.isWatertight)
        XCTAssertTrue(lofted.isWatertight)
        let a = Profile.signedArea(loop)
        XCTAssertEqual(volume(of: swept), a * 8, accuracy: a * 8 * 1e-6)
        XCTAssertEqual(volume(of: lofted), 8.0 / 3 * (a + a * 0.81 + (a * a * 0.81).squareRoot()), accuracy: a * 8 * 1e-6)
        XCTAssertLessThan(seconds, 1.0, "sweep + loft took \(seconds) s")
    }

    /// A holed sweep round a mitred corner: the walls follow the stretched
    /// bisector section like the outer does, so the tube stays watertight and
    /// its volume is the outer L-solid less the hole's L-solid.
    func testSweepWithHoleAroundACornerStaysWatertight() {
        let spine: [SIMD3<Double>] = [SIMD3(0, 0, 0), SIMD3(0, 0, 2), SIMD3(2, 0, 2)]
        let solid = KernelOps.sweep(profile: squareProfile(halfSize: 0.25), in: xyPlane, alongPath: spine)
        let core = KernelOps.sweep(profile: squareProfile(halfSize: 0.125), in: xyPlane, alongPath: spine)
        let tube = KernelOps.sweep(profile: squareProfile(halfSize: 0.25),
                                   holes: [squareProfile(halfSize: 0.125)], in: xyPlane, alongPath: spine)
        XCTAssertTrue(tube.isWatertight)
        XCTAssertEqual(volume(of: tube), volume(of: solid) - volume(of: core), accuracy: 1e-9)
    }

    // MARK: - Loft

    /// A holed loft is built without a boolean: a square ring lofted from
    /// z = 0 (outer 1, hole 0.5) to z = 2 (outer 0.8, hole 0.4) is the outer
    /// frustum less the hole frustum, watertight, outward-facing.
    func testLoftOfASquareRingIsAHollowFrustumWithoutBooleans() {
        let z2 = SketchPlane(origin: SIMD3(0, 0, 2), xAxis: SIMD3(1, 0, 0), yAxis: SIMD3(0, 1, 0))
        let mesh = KernelOps.loft(profiles: [
            (profile: squareProfile(halfSize: 0.5), holes: [squareProfile(halfSize: 0.25)], plane: xyPlane),
            (profile: squareProfile(halfSize: 0.4), holes: [squareProfile(halfSize: 0.2)], plane: z2),
        ])
        XCTAssertTrue(mesh.isWatertight)
        func frustum(_ a: Double, _ b: Double) -> Double { 2.0 / 3 * (a + b + (a * b).squareRoot()) }
        XCTAssertEqual(volume(of: mesh), frustum(1, 0.64) - frustum(0.25, 0.16), accuracy: 1e-9)
        XCTAssertGreaterThan(SweepLoftKit.signedVolume(of: mesh), 0, "normals face outward")
    }

    /// The dense spline outline with a bore lofted to a 90 % copy: fast,
    /// watertight, and the analytic difference of two frustums.
    func testLoftOfADenseHoledOutlineIsFast() {
        let n = 1152
        let outerLoop = (0..<n).map { i -> SIMD2<Double> in
            let phi = Double(i) / Double(n) * 2 * .pi
            let r = 25 + 5 * sin(3 * phi)
            return SIMD2(r * cos(phi), r * sin(phi))
        }
        let bore = circleProfile(center: .zero, radius: 5, segments: 64)
        let base = Profile(loop: outerLoop, kind: .polygonal, sourceEntityIDs: [])
        let top = Profile(loop: outerLoop.map { $0 * 0.9 }, kind: .polygonal, sourceEntityIDs: [])
        let boreTop = circleProfile(center: .zero, radius: 4.5, segments: 64)
        let z8 = SketchPlane(origin: SIMD3(0, 0, 8), xAxis: SIMD3(1, 0, 0), yAxis: SIMD3(0, 1, 0))
        let start = Date()
        let mesh = KernelOps.loft(profiles: [(profile: base, holes: [bore], plane: xyPlane),
                                             (profile: top, holes: [boreTop], plane: z8)])
        let seconds = Date().timeIntervalSince(start)
        XCTAssertTrue(mesh.isWatertight)
        func frustum(_ a: Double, _ b: Double) -> Double { 8.0 / 3 * (a + b + (a * b).squareRoot()) }
        let ao = Profile.signedArea(outerLoop), ah = Profile.signedArea(bore.loop)
        let want = frustum(ao, ao * 0.81) - frustum(ah, ah * 0.81)
        XCTAssertEqual(volume(of: mesh), want, accuracy: want * 1e-6)
        XCTAssertLessThan(seconds, 1.0, "lofted in \(seconds) s")
    }

    func testLoftSquareToSmallerSquareMakesFrustum() {
        let bottom = squareProfile(halfSize: 0.5) // area 1 at z = 0
        let top = squareProfile(halfSize: 0.25) // area 0.25 at z = 1
        let topPlane = SketchPlane(
            origin: SIMD3(0, 0, 1),
            xAxis: SIMD3(1, 0, 0),
            yAxis: SIMD3(0, 1, 0)
        )
        let mesh = KernelOps.loft(profiles: [
            (profile: bottom, holes: [], plane: xyPlane),
            (profile: top, holes: [], plane: topPlane),
        ])

        XCTAssertFalse(mesh.polygons.isEmpty)
        XCTAssertTrue(mesh.isWatertight)

        let bounds = mesh.bounds
        XCTAssertEqual(bounds.min.z, 0, accuracy: 1e-9)
        XCTAssertEqual(bounds.max.z, 1, accuracy: 1e-9)
        XCTAssertEqual(bounds.max.x, 0.5, accuracy: 1e-9)

        // Frustum volume h/3·(A1 + A2 + √(A1·A2)) = 7/12, strictly between
        // the two prism volumes.
        let v = volume(of: mesh)
        XCTAssertGreaterThan(v, 0.25)
        XCTAssertLessThan(v, 1.0)
        XCTAssertEqual(v, 7.0 / 12.0, accuracy: 1e-9)
    }

    func testLoftSquareToCircleIsWatertight() {
        // 4-point square resampled against a 48-point circle.
        let bottom = squareProfile(halfSize: 1)
        let top = circleProfile(center: .zero, radius: 0.8)
        let topPlane = SketchPlane(
            origin: SIMD3(0, 0, 1),
            xAxis: SIMD3(1, 0, 0),
            yAxis: SIMD3(0, 1, 0)
        )
        let mesh = KernelOps.loft(profiles: [
            (profile: bottom, holes: [], plane: xyPlane),
            (profile: top, holes: [], plane: topPlane),
        ])

        XCTAssertFalse(mesh.polygons.isEmpty)
        XCTAssertTrue(mesh.isWatertight)

        let bounds = mesh.bounds
        // Square corners survive the resampling (48 is a multiple of 4).
        XCTAssertEqual(bounds.min.x, -1, accuracy: 1e-9)
        XCTAssertEqual(bounds.max.x, 1, accuracy: 1e-9)
        XCTAssertEqual(bounds.min.z, 0, accuracy: 1e-9)
        XCTAssertEqual(bounds.max.z, 1, accuracy: 1e-9)

        // Between the inscribed prisms of the two sections.
        let v = volume(of: mesh)
        XCTAssertGreaterThan(v, .pi * 0.8 * 0.8 * 0.95) // > circle prism
        XCTAssertLessThan(v, 4.0) // < square prism
    }

    /// A square-to-circle loft is a smooth surface with four ridge columns
    /// (one per square corner). Its preview mesh used to be one row of ruled
    /// quads, and near a corner a quad twists ~45° from ring to ring, so its
    /// two triangles sat more than 20° apart and `FeatureEdges` drew creases
    /// down a smooth wall (the shapes tutorial, 2026-09-17). Every crease
    /// above the 20° threshold must now lie on a cap or a corner ridge.
    func testLoftSquareToCircleHasNoCreasesOffTheRidges() {
        let bottom = squareProfile(halfSize: 9)
        let top = circleProfile(center: .zero, radius: 5)
        let topPlane = SketchPlane(origin: SIMD3(0, 0, 22), xAxis: SIMD3(1, 0, 0), yAxis: SIMD3(0, 1, 0))
        let mesh = KernelOps.loft(profiles: [
            (profile: bottom, holes: [], plane: xyPlane),
            (profile: top, holes: [], plane: topPlane),
        ])
        XCTAssertTrue(mesh.isWatertight)

        // Dihedral angle per shared edge, from the triangulated mesh.
        struct Key: Hashable { let a: SIMD3<Int64>; let b: SIMD3<Int64> }
        func q(_ v: Vector) -> SIMD3<Int64> { SIMD3(Int64((v.x * 1e6).rounded()), Int64((v.y * 1e6).rounded()), Int64((v.z * 1e6).rounded())) }
        func key(_ p: Vector, _ r: Vector) -> Key {
            let (x, y) = (q(p), q(r))
            return x.x < y.x || (x.x == y.x && (x.y < y.y || (x.y == y.y && x.z <= y.z))) ? Key(a: x, b: y) : Key(a: y, b: x)
        }
        var faces = [Key: [(SIMD3<Double>, Vector, Vector)]]()
        for tri in mesh.triangulate().polygons {
            let v = tri.vertices.map(\.position)
            let p = v.map { SIMD3($0.x, $0.y, $0.z) }
            let n = simd_cross(p[1] - p[0], p[2] - p[0])
            guard simd_length(n) > 1e-12 else { continue }
            for i in 0..<3 {
                faces[key(v[i], v[(i + 1) % 3]), default: []].append((simd_normalize(n), v[i], v[(i + 1) % 3]))
            }
        }
        var offRidge = 0, ridges = 0
        for (_, adj) in faces where adj.count == 2 {
            let angle = acos(max(-1, min(1, simd_dot(adj[0].0, adj[1].0)))) * 180 / .pi
            guard angle > 20 else { continue }
            let (p, r) = (adj[0].1, adj[0].2)
            let onCap = (abs(p.z) < 1e-6 && abs(r.z) < 1e-6) || (abs(p.z - 22) < 1e-6 && abs(r.z - 22) < 1e-6)
            let onRidge = abs(abs(p.x) - abs(p.y)) < 1e-6 && abs(abs(r.x) - abs(r.y)) < 1e-6
            if onCap { continue }
            if onRidge { ridges += 1 } else { offRidge += 1 }
        }
        XCTAssertEqual(offRidge, 0, "creases drawn across the smooth walls")
        XCTAssertGreaterThan(ridges, 0, "the four corner ridges are real creases")
    }

    /// A band with no twist (a frustum between two squares) stays one row.
    func testBandSlicesAreOneForAFrustumAndMoreForATwistedBand() {
        let a = (0..<4).map { i -> SIMD3<Double> in [SIMD3(-1, -1, 0), SIMD3(1, -1, 0), SIMD3(1, 1, 0), SIMD3(-1, 1, 0)][i] }
        let b = a.map { SIMD3($0.x * 0.5, $0.y * 0.5, 1) }
        XCTAssertEqual(SweepLoftKit.bandSlices(a, b, count: 4), 1)
        // The same square lofted to a square rotated 45° twists every quad.
        let c = (0..<4).map { i -> SIMD3<Double> in
            let t = Double(i) * .pi / 2 + .pi / 4
            return SIMD3(cos(t) * 0.7, sin(t) * 0.7, 1)
        }
        XCTAssertGreaterThan(SweepLoftKit.bandSlices(a, c, count: 4), 1)
    }

    // MARK: - Helix

    func testHelixPointCountPitchAndRadius() {
        let path = HelixKit.path(
            radius: 2, pitch: 1, turns: 2, in: xyPlane, segmentsPerTurn: 48
        )
        XCTAssertEqual(path.count, 97) // 2 × 48 segments + 1

        // Starts on the plane at angle 0, ends after 2 turns at height 2.
        XCTAssertEqual(path[0].x, 2, accuracy: 1e-12)
        XCTAssertEqual(path[0].y, 0, accuracy: 1e-12)
        XCTAssertEqual(path[0].z, 0, accuracy: 1e-12)
        XCTAssertEqual(path[96].x, 2, accuracy: 1e-9)
        XCTAssertEqual(path[96].y, 0, accuracy: 1e-9)
        XCTAssertEqual(path[96].z, 2, accuracy: 1e-9)

        for (i, p) in path.enumerated() {
            // Constant radius about the plane normal through the origin.
            let radial = (p.x * p.x + p.y * p.y).squareRoot()
            XCTAssertEqual(radial, 2, accuracy: 1e-9)
            // Height climbs pitch per turn.
            XCTAssertEqual(p.z, Double(i) / 48.0, accuracy: 1e-9)
        }

        // Counter-clockwise by default (as seen down +normal); clockwise
        // flips the coil direction.
        XCTAssertGreaterThan(path[1].y, 0)
        let cw = HelixKit.path(
            radius: 2, pitch: 1, turns: 2, clockwise: true, in: xyPlane,
            segmentsPerTurn: 48
        )
        XCTAssertEqual(cw.count, 97)
        XCTAssertLessThan(cw[1].y, 0)
    }

    func testHelixFractionalTurnsEndsAtExactHeight() {
        let path = HelixKit.path(
            radius: 1, pitch: 4, turns: 1.5, in: xyPlane, segmentsPerTurn: 48
        )
        XCTAssertEqual(path.count, 73) // ceil(1.5 × 48) + 1
        // 1.5 turns from angle 0 ends at angle π: (-1, 0), height 6.
        let last = path[path.count - 1]
        XCTAssertEqual(last.x, -1, accuracy: 1e-9)
        XCTAssertEqual(last.y, 0, accuracy: 1e-9)
        XCTAssertEqual(last.z, 6, accuracy: 1e-9)
    }

    // MARK: - Sweep along helix

    func testSweepCircleAlongHelixMakesThread() {
        // Small circular profile at the helix start, swept two coils.
        let spine = HelixKit.path(
            radius: 2, pitch: 1, turns: 2, in: xyPlane, segmentsPerTurn: 48
        )
        let profile = circleProfile(
            center: SIMD2(2, 0), radius: 0.2, segments: 16
        )
        let mesh = KernelOps.sweep(profile: profile, in: xyPlane, alongPath: spine)

        XCTAssertFalse(mesh.polygons.isEmpty)
        XCTAssertTrue(mesh.isWatertight)

        // Bounded by helix radius + profile radius (tiny mitre slack) and
        // the coil height span.
        let bounds = mesh.bounds
        XCTAssertGreaterThan(bounds.min.x, -2.3)
        XCTAssertLessThan(bounds.max.x, 2.3)
        XCTAssertGreaterThan(bounds.min.y, -2.3)
        XCTAssertLessThan(bounds.max.y, 2.3)
        XCTAssertGreaterThan(bounds.min.z, -0.3)
        XCTAssertLessThan(bounds.max.z, 2.3)

        // Hollow core: nothing near the helix axis.
        let minRadial = mesh.polygons
            .flatMap(\.vertices)
            .map { ($0.position.x * $0.position.x + $0.position.y * $0.position.y).squareRoot() }
            .min() ?? 0
        XCTAssertGreaterThan(minRadial, 1.5)
    }
}
