//
//  FacePickUnderBlendTests.swift
//  openshape3dTests
//
//  Picking faces on a BLENDED solid. A fillet is tangent to what it blends,
//  so the smooth-region flood fill runs straight over it — which raised the
//  question of whether a flat face survives as its own pick once its rim is
//  rounded. It does, and these pin that: the picker's two passes
//  (`planarFace` / `smoothRegion`) disagree exactly where they should.
//
//  Written after a live mis-read: tapping an isometric view near the rim of a
//  filleted cylinder selects the curved wall (whole tangent region, 860 mm²),
//  which looks like the flat cap having been swallowed. It has not been — a
//  top-view tap on the same body selects the 155 mm² cap.
//

import XCTest
import simd
import Euclid
@testable import openshape3d

final class FacePickUnderBlendTests: XCTestCase {

    /// r8 × h10 cylinder, both rims filleted at 1 mm.
    private func filletedCylinder() throws -> BRepHandle {
        let cyl = try XCTUnwrap(OCCTKernel.primitiveShape(
            .cylinder(radius: 8, height: 10), placement: .identity))
        return try XCTUnwrap(try? OCCTKernel.filletResult(
            cyl, edgeIndices: [2, 3], radius: 1).get())
    }

    private func render(_ handle: BRepHandle) -> RenderMesh {
        let r = OCCTKernel.renderMesh(from: handle)
        return RenderMesh(positions: r.positions, normals: r.normals, indices: r.indices)
    }

    private func triangleNormal(_ mesh: RenderMesh, _ t: Int) -> SIMD3<Float> {
        let a = mesh.positions[Int(mesh.indices[t * 3])]
        let b = mesh.positions[Int(mesh.indices[t * 3 + 1])]
        let c = mesh.positions[Int(mesh.indices[t * 3 + 2])]
        return simd_normalize(simd_cross(b - a, c - a))
    }

    /// The flat cap of a filleted cylinder is still its own planar face: the
    /// coplanar patch covers the whole kernel face, and the smooth region
    /// STOPS there (it reports not-curved), so the picker's curved-region
    /// branch never fires and push/pull and the face transforms stay live.
    func testFlatCapSurvivesAsItsOwnFace() throws {
        let brep = try filletedCylinder()
        let mesh = render(brep)
        let channel = OCCTKernel.renderMeshFaceChannel(from: brep)
        XCTAssertEqual(channel.count, mesh.triangleCount,
                       "the kernel face channel is parallel to the render triangles")

        var capSeed: Int?
        for t in 0..<mesh.triangleCount where triangleNormal(mesh, t).y > 0.999 {
            capSeed = t
            break
        }
        let seed = try XCTUnwrap(capSeed, "a filleted cylinder still has a flat top cap")
        let cap = try XCTUnwrap(FaceTopology.planarFace(in: mesh, seedTriangle: seed),
                                "the cap is a planar face")

        // It is the WHOLE kernel face, not a sliver of one.
        let kernelFace = channel[seed]
        XCTAssertNotEqual(kernelFace, 0)
        let kernelTriangles = channel.filter { $0 == kernelFace }.count
        let covered = cap.triangles.filter { channel[$0] == kernelFace }.count
        XCTAssertEqual(covered, kernelTriangles,
                       "the coplanar patch covers the cap's entire kernel face")

        // And the smooth region does not run off over the fillet from here.
        let smooth = try XCTUnwrap(FaceTopology.smoothRegion(in: mesh, seedTriangle: seed))
        XCTAssertFalse(smooth.isCurved, "the cap's smooth region is flat, so the "
                       + "curved-region branch of the picker never claims it")
        XCTAssertEqual(smooth.triangles.count, cap.triangles.count,
                       "and it is exactly the cap")
    }

    /// The other side of the same coin: a facet of the curved WALL is only a
    /// sliver of its kernel face, and its smooth region spans the tangent
    /// blend — which is why the picker prefers the region there.
    func testCurvedWallPrefersTheSmoothRegion() throws {
        let brep = try filletedCylinder()
        let mesh = render(brep)

        var wallSeed: Int?
        for t in 0..<mesh.triangleCount {
            let n = triangleNormal(mesh, t)
            if abs(n.y) < 0.01, simd_length(SIMD2(n.x, n.z)) > 0.99 { wallSeed = t; break }
        }
        let seed = try XCTUnwrap(wallSeed, "the cylinder has a radial wall")
        let smooth = try XCTUnwrap(FaceTopology.smoothRegion(in: mesh, seedTriangle: seed))
        XCTAssertTrue(smooth.isCurved)

        let sliver = FaceTopology.planarFace(in: mesh, seedTriangle: seed)
        XCTAssertLessThan(sliver?.triangles.count ?? 0, smooth.triangles.count / 10,
                          "no two facets of a curved wall are coplanar, so the "
                          + "planar patch there is a sliver and the region wins")
    }
}
