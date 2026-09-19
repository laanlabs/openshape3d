//
//  FaceSketchPlaneTests.swift
//  openshape3dTests
//
//  The sketch plane a picked face gets (`SketchPlane.readable`): up/down
//  faces take the ground's in-plane axes, everything else is upright like the
//  front and side planes. Before this, a face sketch took the face's mesh
//  basis — its first boundary edge — so a box's top face sketched with
//  xAxis +Z and Text on it ran across the view (found recording the keychain
//  tutorial, 2026-09-18).
//

import XCTest
import simd
import Euclid
@testable import openshape3d

final class FaceSketchPlaneTests: XCTestCase {

    private func assertVector(_ v: SIMD3<Double>, _ expected: SIMD3<Double>,
                              _ message: String = "", file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertEqual(simd_distance(v, expected), 0, accuracy: 1e-9,
                       "\(message) got \(v), expected \(expected)", file: file, line: line)
    }

    /// Orthonormal, and the normal is the face's.
    private func assertFrame(_ p: SketchPlane, normal: SIMD3<Double>,
                             file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertEqual(simd_length(p.xAxis), 1, accuracy: 1e-12, file: file, line: line)
        XCTAssertEqual(simd_length(p.yAxis), 1, accuracy: 1e-12, file: file, line: line)
        XCTAssertEqual(simd_dot(p.xAxis, p.yAxis), 0, accuracy: 1e-12, file: file, line: line)
        XCTAssertEqual(simd_distance(p.normal, simd_normalize(normal)), 0, accuracy: 1e-9,
                       "normal", file: file, line: line)
    }

    func testUpFacingFaceGetsTheGroundAxes() {
        let p = SketchPlane.readable(origin: SIMD3(2, 3, -1), normal: SIMD3(0, 1, 0))
        assertVector(p.xAxis, SIMD3(1, 0, 0), "xAxis")
        assertVector(p.yAxis, SIMD3(0, 0, -1), "yAxis")
        assertVector(p.xAxis, SketchPlane.ground.xAxis)
        assertVector(p.yAxis, SketchPlane.ground.yAxis)
        XCTAssertEqual(p.origin, SIMD3(2, 3, -1), "the face's origin is kept")
        assertFrame(p, normal: SIMD3(0, 1, 0))
    }

    func testDownFacingFaceMirrorsTheGroundAxes() {
        let p = SketchPlane.readable(origin: .zero, normal: SIMD3(0, -1, 0))
        assertVector(p.xAxis, SIMD3(1, 0, 0), "xAxis")
        assertVector(p.yAxis, SIMD3(0, 0, 1), "yAxis")
        assertFrame(p, normal: SIMD3(0, -1, 0))
    }

    /// Mesh normals carry float noise; a face that is horizontal within it
    /// still gets the ground layout, exactly in its own plane.
    func testNearlyHorizontalFaceStillReadsLikeTheGround() {
        let n = simd_normalize(SIMD3<Double>(2e-6, 1, -3e-6))
        let p = SketchPlane.readable(origin: .zero, normal: n)
        XCTAssertGreaterThan(simd_dot(p.xAxis, SIMD3(1, 0, 0)), 1 - 1e-9)
        XCTAssertGreaterThan(simd_dot(p.yAxis, SIMD3(0, 0, -1)), 1 - 1e-9)
        assertFrame(p, normal: n)
    }

    func testVerticalFacesAreUprightLikeTheWorldPlanes() {
        let front = SketchPlane.readable(origin: .zero, normal: SIMD3(0, 0, 1))
        assertVector(front.xAxis, SketchPlane.worldXY.xAxis, "+Z face xAxis")
        assertVector(front.yAxis, SketchPlane.worldXY.yAxis, "+Z face yAxis")
        let side = SketchPlane.readable(origin: .zero, normal: SIMD3(1, 0, 0))
        assertVector(side.xAxis, SketchPlane.worldYZ.xAxis, "+X face xAxis")
        assertVector(side.yAxis, SketchPlane.worldYZ.yAxis, "+X face yAxis")
        // Back and left faces read the right way round seen from outside.
        let back = SketchPlane.readable(origin: .zero, normal: SIMD3(0, 0, -1))
        assertVector(back.xAxis, SIMD3(-1, 0, 0), "-Z face xAxis")
        assertVector(back.yAxis, SIMD3(0, 1, 0), "-Z face yAxis")
        let left = SketchPlane.readable(origin: .zero, normal: SIMD3(-1, 0, 0))
        assertVector(left.xAxis, SIMD3(0, 0, 1), "-X face xAxis")
        assertVector(left.yAxis, SIMD3(0, 1, 0), "-X face yAxis")
        for p in [front, side, back, left] { assertFrame(p, normal: p.normal) }
    }

    /// A slope reads upright: y climbs the face, x stays level.
    func testSlopedFaceClimbsUpTheSlope() {
        let n = simd_normalize(SIMD3<Double>(0, 1, 1))
        let p = SketchPlane.readable(origin: .zero, normal: n)
        assertVector(p.xAxis, SIMD3(1, 0, 0), "xAxis stays level")
        XCTAssertGreaterThan(p.yAxis.y, 0, "yAxis climbs")
        XCTAssertEqual(simd_dot(p.yAxis, n), 0, accuracy: 1e-12)
        assertFrame(p, normal: n)
    }

    /// The case that was wrong: a real box's top face. Its mesh basis is the
    /// first boundary edge — not +X — while the sketch plane built from it is
    /// the ground's layout.
    func testBoxTopFaceSketchesWithXAlongWorldX() throws {
        let render = EuclidBridge.renderMesh(from: Euclid.Mesh.primitive(.box(width: 60, depth: 20, height: 3)))
        let seed = try XCTUnwrap((0..<render.triangleCount).first { t in
            let a = render.positions[Int(render.indices[t * 3])]
            let b = render.positions[Int(render.indices[t * 3 + 1])]
            let c = render.positions[Int(render.indices[t * 3 + 2])]
            return simd_normalize(simd_cross(b - a, c - a)).y > 0.999
        })
        let face = try XCTUnwrap(FaceTopology.planarFace(in: render, seedTriangle: seed))
        let plane = SketchPlane.readable(origin: face.origin, normal: simd_cross(face.basisX, face.basisY))
        assertVector(plane.xAxis, SIMD3(1, 0, 0), "xAxis")
        assertVector(plane.yAxis, SIMD3(0, 0, -1), "yAxis")
        assertFrame(plane, normal: SIMD3(0, 1, 0))
    }

    /// What the user sees: Text on an up-facing face runs along world +X and
    /// its letters rise towards -Z (away from the default camera), so it reads
    /// left to right in the top and isometric views.
    func testTextOnATopFaceRunsAlongWorldX() {
        let plane = SketchPlane.readable(origin: SIMD3(0, 3, 0), normal: SIMD3(0, 1, 0))
        let entities = TextSketch.glyphEntities(text: "JULES", height: 10)
        XCTAssertFalse(entities.isEmpty)
        var world: [SIMD3<Double>] = []
        for case let .line(_, a, b) in entities {
            world.append(plane.toWorld(a)); world.append(plane.toWorld(b))
        }
        let xs = world.map(\.x), zs = world.map(\.z)
        let spanX = xs.max()! - xs.min()!, spanZ = zs.max()! - zs.min()!
        XCTAssertGreaterThan(spanX, 3 * spanZ, "the text runs along X (\(spanX) vs \(spanZ) mm)")
        XCTAssertEqual(spanZ, 10, accuracy: 0.6, "cap height spans Z")
        XCTAssertLessThan(zs.min()!, -9, "letters rise towards -Z from the baseline")
        for p in world { XCTAssertEqual(p.y, 3, accuracy: 1e-9) }
    }
}
