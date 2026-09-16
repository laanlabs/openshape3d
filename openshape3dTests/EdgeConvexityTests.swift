//
//  EdgeConvexityTests.swift
//  openshape3dTests
//
//  `SelectableEdge.isConvex` on NON-convex solids. The classification used to
//  compare each edge's outward bisector with the direction from the mesh's
//  vertex centroid to the edge, which is only sound for a convex solid. On a
//  T-beam both inside corners came back convex (practice-problem round 6, bug
//  3, 2026-09-16), so `/v1/edges` reported them convex and the mesh blend path
//  would cut those corners away instead of filling them.
//
//  The T-beam also caught the collinear merge joining two disjoint edges
//  across the stem into one span (see `testTBeamInsideCornersAreConcave`).
//
//  The oracle is point containment, independent of the classifier: a point
//  just above face A's plane and just below face B's lies in the solid exactly
//  when the edge is concave (a convex edge's material is below BOTH planes, a
//  concave edge's below EITHER).
//

import XCTest
import simd
import Euclid
@testable import openshape3d

final class EdgeConvexityTests: XCTestCase {

    private let depth = 20.0

    /// A prism along z from an axis-aligned union of rectangles
    /// `(x0, y0, x1, y1)`.
    private func prism(_ rects: [(Double, Double, Double, Double)]) -> Euclid.Mesh {
        let boxes = rects.map { r in
            Euclid.Mesh.cube(
                center: Vector((r.0 + r.2) / 2, (r.1 + r.3) / 2, 0),
                size: Vector(r.2 - r.0, r.3 - r.1, depth))
        }
        return boxes.dropFirst().reduce(boxes[0]) { $0.union($1) }.makeWatertight()
    }

    /// The round-6 shape: a stem x∈[−5, 5], y∈[0, 10] under a bar
    /// x∈[−15, 15], y∈[10, 20]. Inside corners at (±5, 10).
    private var tBeam: Euclid.Mesh { prism([(-5, 0, 5, 10), (-15, 10, 15, 20)]) }

    private var lBeam: Euclid.Mesh { prism([(0, 0, 6, 2), (0, 0, 2, 6)]) }

    /// Base x∈[0, 12], y∈[0, 2] with two uprights; inside corners at (2, 2)
    /// and (10, 2).
    private var uChannel: Euclid.Mesh { prism([(0, 0, 12, 2), (0, 0, 2, 8), (10, 0, 12, 8)]) }

    /// A 20×20×10 block with a 8×6×4 pocket cut into its top, off centre.
    private var pocketedBlock: Euclid.Mesh {
        let block = Euclid.Mesh.cube(center: Vector(0, 0, 0), size: Vector(20, 20, 10))
        let pocket = Euclid.Mesh.cube(center: Vector(4, -3, 4), size: Vector(8, 6, 6))
        return block.subtracting(pocket).makeWatertight()
    }

    private func edges(_ mesh: Euclid.Mesh) -> [SelectableEdge] {
        EdgeTopology.selectableEdges(from: EuclidBridge.renderMesh(from: mesh))
    }

    /// Containment says whether the edge is concave.
    private func isConcaveByContainment(_ edge: SelectableEdge, in mesh: Euclid.Mesh) -> Bool {
        let off = simd_normalize(edge.normalA - edge.normalB) * 0.01
        let p = edge.midpoint + off
        return mesh.intersects(Vector(Double(p.x), Double(p.y), Double(p.z)))
    }

    private func assertClassificationMatchesContainment(
        _ mesh: Euclid.Mesh, _ name: String,
        file: StaticString = #filePath, line: UInt = #line
    ) {
        let all = edges(mesh)
        XCTAssertFalse(all.isEmpty, "\(name): no edges", file: file, line: line)
        for edge in all {
            XCTAssertEqual(
                edge.isConvex, !isConcaveByContainment(edge, in: mesh),
                "\(name): edge at \(edge.midpoint) along \(edge.direction) is classified "
                    + (edge.isConvex ? "convex" : "concave") + " against containment",
                file: file, line: line)
        }
    }

    // MARK: - The reported shape

    func testTBeamInsideCornersAreConcave() {
        let all = edges(tBeam)
        let concave = all.filter { !$0.isConvex }
        XCTAssertEqual(concave.count, 2, "a T-beam has exactly two inside corners")
        for x in [-5.0, 5.0] {
            XCTAssertTrue(concave.contains {
                abs(Double($0.midpoint.x) - x) < 1e-3 && abs(Double($0.midpoint.y) - 10) < 1e-3
                    && abs(Double($0.length) - depth) < 1e-3
            }, "the inside corner at (\(x), 10) should be concave")
        }
        // Eight profile corners: eight edges along z and eight on each cap.
        // The bar's two underside edges share a line and a face pair with the
        // stem between them; merged by that key alone they became one 30 mm
        // edge across the junction and the count was 22.
        XCTAssertEqual(all.count, 24)
    }

    // MARK: - Every edge, several non-convex solids

    func testTBeamEdgesMatchContainment() { assertClassificationMatchesContainment(tBeam, "T-beam") }
    func testLBeamEdgesMatchContainment() { assertClassificationMatchesContainment(lBeam, "L-beam") }
    func testUChannelEdgesMatchContainment() { assertClassificationMatchesContainment(uChannel, "U-channel") }
    func testPocketedBlockEdgesMatchContainment() {
        assertClassificationMatchesContainment(pocketedBlock, "pocketed block")
    }

    // MARK: - OCCT tessellation (what `/v1/edges` classifies)

    /// A B-rep body's render mesh comes from OCCT, not Euclid, and the winding
    /// rule depends on its triangles being wound outward.
    private func occtPrism(_ loop: [SIMD2<Double>], zMin: Double, zMax: Double) throws -> BRepHandle {
        try XCTUnwrap(OCCTKernel.extrudeShape(
            outerLoop: loop, holes: [], zMin: zMin, zMax: zMax,
            origin: .zero, xAxis: SIMD3(1, 0, 0), yAxis: SIMD3(0, 1, 0),
            normal: SIMD3(0, 0, 1)))
    }

    private func render(_ handle: BRepHandle) throws -> (RenderMesh, Euclid.Mesh) {
        let m = OCCTKernel.renderMesh(from: handle)
        XCTAssertFalse(m.indices.isEmpty)
        let mesh = RenderMesh(positions: m.positions, normals: m.normals, indices: m.indices)
        return (mesh, EuclidBridge.euclidMesh(from: mesh))
    }

    func testOCCTTBeamInsideCornersAreConcaveAndEdgesMatchContainment() throws {
        let t: [SIMD2<Double>] = [
            SIMD2(-5, 0), SIMD2(5, 0), SIMD2(5, 10), SIMD2(15, 10),
            SIMD2(15, 20), SIMD2(-15, 20), SIMD2(-15, 10), SIMD2(-5, 10),
        ]
        let (mesh, solid) = try render(try occtPrism(t, zMin: 0, zMax: depth))
        let all = EdgeTopology.selectableEdges(from: mesh)
        let concave = all.filter { !$0.isConvex }
        XCTAssertEqual(concave.count, 2, "a T-beam has exactly two inside corners")
        for x in [-5.0, 5.0] {
            XCTAssertTrue(concave.contains {
                abs(Double($0.midpoint.x) - x) < 1e-3 && abs(Double($0.midpoint.y) - 10) < 1e-3
            }, "the inside corner at (\(x), 10) should be concave")
        }
        XCTAssertEqual(all.count, 24, "no edge may span the stem junction")
        for edge in all {
            XCTAssertEqual(edge.isConvex, !isConcaveByContainment(edge, in: solid),
                           "OCCT T-beam: edge at \(edge.midpoint) against containment")
        }
    }

    func testOCCTPocketedBlockEdgesMatchContainment() throws {
        let block = try occtPrism(
            [SIMD2(-10, -10), SIMD2(10, -10), SIMD2(10, 10), SIMD2(-10, 10)], zMin: -5, zMax: 5)
        let pocket = try occtPrism(
            [SIMD2(0, -6), SIMD2(8, -6), SIMD2(8, 0), SIMD2(0, 0)], zMin: 1, zMax: 7)
        let cut = try XCTUnwrap(OCCTKernel.boolean(block, pocket, op: OCCTKernel.booleanOp(.subtract)))
        let (mesh, solid) = try render(cut)
        let all = EdgeTopology.selectableEdges(from: mesh)
        // Eight pocket edges are concave (four floor, four vertical corners);
        // the four rim edges and the block's twelve are convex.
        XCTAssertEqual(all.filter { !$0.isConvex }.count, 8)
        for edge in all {
            XCTAssertEqual(edge.isConvex, !isConcaveByContainment(edge, in: solid),
                           "OCCT pocketed block: edge at \(edge.midpoint) against containment")
        }
    }

    /// A convex solid stays all-convex.
    func testBoxEdgesAreAllConvex() {
        let box = Euclid.Mesh.cube(center: Vector(3, -2, 1), size: Vector(4, 6, 8))
        let all = edges(box)
        XCTAssertEqual(all.count, 12)
        XCTAssertTrue(all.allSatisfy(\.isConvex))
    }
}
