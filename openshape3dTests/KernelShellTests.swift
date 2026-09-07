//
//  KernelShellTests.swift
//  openshape3dTests
//
//  Phase E tranche 4 proof: the pure mesh-kernel Shell — inner-cavity vertex
//  offset, face openings via inset-outline prisms, and the loop offsetter that
//  feeds them. Plain Euclid meshes + RenderMesh only, per repo convention.
//
//  A cube of side 10 shelled at t=1 leaves walls around an 8³ cavity:
//  closed hollow = 1000 − 512 = 488. Opening the top face additionally removes
//  the 8×8×1 wall patch above the cavity → 424 (= the open-top box volume).
//

import XCTest
import simd
import Euclid
@testable import openshape3d

final class KernelShellTests: XCTestCase {

    private func cube(side: Double) -> Euclid.Mesh {
        Euclid.Mesh.cube(center: Vector(0, 0, 0), size: Vector(side, side, side))
    }

    private func volume(_ mesh: Euclid.Mesh) -> Double {
        MeasureKit.bodyVolume(EuclidBridge.renderMesh(from: mesh), scale: 1)
    }

    /// The cube's planar face whose normal points along `direction`.
    private func face(
        of mesh: Euclid.Mesh, along direction: SIMD3<Float>
    ) throws -> PlanarFace {
        let render = EuclidBridge.renderMesh(from: mesh)
        for t in 0..<render.triangleCount {
            let a = render.positions[Int(render.indices[t * 3])]
            let b = render.positions[Int(render.indices[t * 3 + 1])]
            let c = render.positions[Int(render.indices[t * 3 + 2])]
            let n = simd_cross(b - a, c - a)
            let len = simd_length(n)
            guard len > 1e-9, simd_dot(n / len, direction) > 0.999 else { continue }
            return try XCTUnwrap(FaceTopology.planarFace(in: render, seedTriangle: t))
        }
        XCTFail("no face along \(direction)")
        throw XCTSkip("unreachable")
    }

    // MARK: Closed hollow

    func testClosedShellHollowsCube() {
        let out = KernelOps.shell(mesh: cube(side: 10), thickness: 1)
        XCTAssertFalse(out.polygons.isEmpty)
        // Walls of 1 around an 8³ cavity.
        XCTAssertEqual(volume(out), 1000 - 512, accuracy: 1.0)
        XCTAssertTrue(out.isWatertight, "shelled solid is watertight")
    }

    // MARK: Open face

    func testOpenTopShellMatchesOpenBoxVolume() throws {
        let mesh = cube(side: 10)
        let top = try face(of: mesh, along: SIMD3(0, 0, 1))
        let out = KernelOps.shell(mesh: mesh, thickness: 1, openFaces: [top])
        XCTAssertFalse(out.polygons.isEmpty)
        // 5 walls of thickness 1: 1000 − 8·8·9.
        XCTAssertEqual(volume(out), 424, accuracy: 1.0)
    }

    func testTwoOpenFacesCutBothWalls() throws {
        let mesh = cube(side: 10)
        let top = try face(of: mesh, along: SIMD3(0, 0, 1))
        let side = try face(of: mesh, along: SIMD3(1, 0, 0))
        let out = KernelOps.shell(mesh: mesh, thickness: 1, openFaces: [top, side])
        XCTAssertFalse(out.polygons.isEmpty)
        // Two adjacent openings leave four walls: bottom, back, left, right —
        // 1000 − 8·9·9. The 1×1×8 bar along the shared edge goes too, exactly
        // as OCCT's MakeThickSolid removes it (the old two-cut CSG kept it).
        XCTAssertEqual(volume(out), 1000 - 8 * 9 * 9, accuracy: 1.5)
    }

    // MARK: Validity

    func testThicknessEatingBodyReturnsEmpty() {
        // t=6 on a side-10 cube: the cavity collapses — invalid.
        let out = KernelOps.shell(mesh: cube(side: 10), thickness: 6)
        XCTAssertTrue(out.polygons.isEmpty, "over-thick shell signals invalid")
    }

    func testZeroThicknessReturnsEmpty() {
        let out = KernelOps.shell(mesh: cube(side: 10), thickness: 0)
        XCTAssertTrue(out.polygons.isEmpty)
    }

    // MARK: Loop offset

    func testOffsetLoopShrinkAndGrow() throws {
        let square: [SIMD2<Double>] = [
            SIMD2(0, 0), SIMD2(10, 0), SIMD2(10, 10), SIMD2(0, 10),
        ]
        let shrunk = try XCTUnwrap(KernelOps.offsetLoop(square, by: -1))
        XCTAssertEqual(Profile.signedArea(shrunk), 64, accuracy: 1e-9)
        let grown = try XCTUnwrap(KernelOps.offsetLoop(square, by: 1))
        XCTAssertEqual(Profile.signedArea(grown), 144, accuracy: 1e-9)
    }

    func testOffsetLoopCollapseReturnsNil() {
        let square: [SIMD2<Double>] = [
            SIMD2(0, 0), SIMD2(10, 0), SIMD2(10, 10), SIMD2(0, 10),
        ]
        XCTAssertNil(KernelOps.offsetLoop(square, by: -6),
                     "a shrink past the midlines collapses the loop")
    }

    func testOffsetLoopHandlesClockwiseInput() throws {
        // CW winding must normalize — grow still grows.
        let squareCW: [SIMD2<Double>] = [
            SIMD2(0, 10), SIMD2(10, 10), SIMD2(10, 0), SIMD2(0, 0),
        ]
        let grown = try XCTUnwrap(KernelOps.offsetLoop(squareCW, by: 1))
        XCTAssertEqual(abs(Profile.signedArea(grown)), 144, accuracy: 1e-9)
    }
}

// MARK: - Extruded-profile bodies (the app's real meshes)

extension KernelShellTests {
    /// Shell must work on the mesh an app extrude actually produces (CSG-healed
    /// triangle soup), not just pristine Euclid primitives.
    func testShellOnExtrudedRectBody() throws {
        let profile = Profile(
            loop: [SIMD2(0, 0), SIMD2(40, 0), SIMD2(40, 30), SIMD2(0, 30)],
            kind: .polygonal, sourceEntityIDs: [])
        let mesh = KernelOps.extrude(
            profile: profile, in: SketchPlane.ground, distance: 20)
        XCTAssertFalse(mesh.polygons.isEmpty)
        let closed = KernelOps.shell(mesh: mesh, thickness: 2)
        // 40×30×20 with a 36×26×16 cavity.
        XCTAssertFalse(closed.polygons.isEmpty, "closed shell on extruded box")
        XCTAssertEqual(volume(closed), 24000 - 14976, accuracy: 20)

        // The ground plane is world-XZ (y-up): the extrude's 40×30 cap faces +Y.
        let top = try face(of: mesh, along: SIMD3(0, 1, 0))
        let open = KernelOps.shell(mesh: mesh, thickness: 2, openFaces: [top])
        XCTAssertFalse(open.polygons.isEmpty, "open-top shell on extruded box")
        // Open top: cavity 36×26 through 18 of the 20 height.
        XCTAssertEqual(volume(open), 24000 - 36.0 * 26 * 18, accuracy: 25)
    }
}

extension KernelShellTests {
    /// A NEGATIVE thickness grows the wall outward — the original surface
    /// becomes the cavity. Open top on a 10-cube, 2 mm out: the walls and
    /// floor thicken outward (14 × 14 × 12 outer minus the 10-cube). Closed:
    /// a 14-cube minus the 10-cube.
    func testNegativeThicknessShellsOutward() throws {
        let cube = try XCTUnwrap(OCCTKernel.primitiveShape(
            .box(width: 10, depth: 10, height: 10), placement: .identity))
        // OCCT's arc joins ROUND the offset's edges and corners (quarter
        // cylinders of radius 2 along the edges, eighth-spheres at the
        // corners), so the outer solid is the rounded offset, not a bigger box.
        let edge = Double.pi * 4 / 4 * 10, corner = 4.0 / 3 * Double.pi * 8 / 8
        let openTop = try XCTUnwrap(OCCTKernel.shell(
            cube, openingAt: [SIMD3(0, 10, 0)], thickness: -2, tolerance: 0.5))
        let openOuter = 1000 + 5 * 100 * 2 + 8 * edge + 4 * corner   // top face and its edges stay
        XCTAssertEqual(OCCTKernel.volume(openTop), openOuter - 1000, accuracy: 0.5)
        let closed = try XCTUnwrap(OCCTKernel.shell(
            cube, openingAt: [], thickness: -2, tolerance: 0.5))
        let closedOuter = 1000 + 6 * 100 * 2 + 12 * edge + 8 * corner
        XCTAssertEqual(OCCTKernel.volume(closed), closedOuter - 1000, accuracy: 0.5)
        XCTAssertNil(OCCTKernel.shell(cube, openingAt: [], thickness: 0, tolerance: 0.5))
    }
}
