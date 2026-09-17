//
//  EdgeMidpointTests.swift
//  openshape3dTests
//
//  `OCCTKernel.edgeGeometry`, what `/v1/edges` reports per kernel edge. It
//  used to keep the midpoint of the FIRST mesh segment that mapped to an
//  edge, and `EdgeTopology` returns segments in per-process dictionary
//  order, so a curved edge's midpoint moved from one launch of the app to the
//  next (practice problem 4.5, 2026-09-16: the hole rim's reported midpoint
//  went from (29.1, 45.7) to (26.9, 37.5) on a relaunch). The midpoint is now
//  the kernel curve's own, halfway along it by arc length.
//
//  The body is a stadium plate (two lines, two semicircular caps) with a
//  round hole, built and tessellated by OCCT exactly as a body's render mesh
//  is (`Body.adoptBRep`).
//

import XCTest
import simd
@testable import openshape3d

final class EdgeMidpointTests: XCTestCase {

    private let halfLength = 10.0
    private let capRadius = 5.0
    private let thickness = 4.0
    private let holeCenter = SIMD2<Double>(-10, 0)
    private let holeRadius = 2.0

    private func plate() throws -> (brep: BRepHandle, edges: [SelectableEdge]) {
        let r = capRadius, h = halfLength
        let outline = Sketch(plane: .ground, entities: [
            .line(id: UUID(), a: SIMD2(-h, -r), b: SIMD2(h, -r)),
            .arc(id: UUID(), center: SIMD2(h, 0), radius: r,
                 startAngle: -.pi / 2, endAngle: .pi / 2),
            .line(id: UUID(), a: SIMD2(h, r), b: SIMD2(-h, r)),
            .arc(id: UUID(), center: SIMD2(-h, 0), radius: r,
                 startAngle: .pi / 2, endAngle: 3 * .pi / 2),
        ])
        let circle = Sketch(plane: .ground, entities: [
            .circle(id: UUID(), center: holeCenter, radius: holeRadius),
        ])
        let outer = try XCTUnwrap(ProfileDetector.detectProfiles(in: outline).first)
        let hole = try XCTUnwrap(ProfileDetector.detectProfiles(in: circle).first)
        let brep = try XCTUnwrap(OCCTKernel.extrudeShape(
            outerLoop: outer.loop, holes: OCCTKernel.extrudeHoles([hole]),
            zMin: 0, zMax: thickness,
            origin: .zero, xAxis: SIMD3(1, 0, 0), yAxis: SIMD3(0, 1, 0),
            normal: SIMD3(0, 0, 1), outerSegments: outer.segments))
        let m = OCCTKernel.renderMesh(from: brep)
        let render = RenderMesh(positions: m.positions, normals: m.normals, indices: m.indices)
        return (brep, EdgeTopology.selectableEdges(from: render))
    }

    private func geometry(_ brep: BRepHandle, _ edges: [SelectableEdge])
        -> [Int: OCCTKernel.EdgeGeometry] {
        OCCTKernel.edgeGeometry(brep, meshEdges: edges,
                                tolerance: OCCTKernel.matchTolerance(for: brep))
    }

    private func d3(_ v: SIMD3<Float>) -> SIMD3<Double> {
        SIMD3(Double(v.x), Double(v.y), Double(v.z))
    }

    /// The fixture has what the bug needs: curved edges that several mesh
    /// segments map to, each with a different midpoint.
    func testCurvedEdgesSpanSeveralMeshSegments() throws {
        let (brep, edges) = try plate()
        let tolerance = OCCTKernel.matchTolerance(for: brep)
        var midpoints: [Int: Set<[Double]>] = [:]
        for edge in edges {
            let m = d3(edge.midpoint)
            guard let index = OCCTKernel.nearestEdgeIndex(brep, to: m, tolerance: tolerance)
            else { continue }
            midpoints[index, default: []].insert([m.x, m.y, m.z])
        }
        XCTAssertGreaterThanOrEqual(midpoints.values.filter { $0.count > 1 }.count, 6,
                                    "four cap arcs and two hole rims tessellate into many segments")
    }

    func testGeometryDoesNotDependOnMeshEdgeOrder() throws {
        let (brep, edges) = try plate()
        let reference = geometry(brep, edges)
        XCTAssertFalse(reference.isEmpty)
        let k = edges.count / 3
        let orders = [
            Array(edges.reversed()),
            Array(edges[k...] + edges[..<k]),
            edges.sorted { ($0.midpoint.y, $0.midpoint.x) > ($1.midpoint.y, $1.midpoint.x) },
        ]
        for order in orders {
            XCTAssertEqual(geometry(brep, order), reference)
        }
    }

    /// Each reported midpoint lies on its own kernel edge.
    func testEveryMidpointLiesOnItsOwnEdge() throws {
        let (brep, edges) = try plate()
        for (index, edge) in geometry(brep, edges) {
            XCTAssertEqual(OCCTKernel.nearestEdgeIndex(brep, to: edge.midpoint, tolerance: 1e-6),
                           index, "edge \(index) midpoint \(edge.midpoint) is not on the edge")
        }
    }

    /// Halfway by arc length: a semicircular cap's midpoint is its angular
    /// middle, a straight edge's is the segment midpoint, and the hole's rim
    /// is a point on the circle.
    func testMidpointsAreHalfwayAlongTheCurve() throws {
        let (brep, edges) = try plate()
        let reported = geometry(brep, edges).values.map(\.midpoint)
        func reports(_ p: SIMD3<Double>) -> Bool {
            reported.contains { simd_distance($0, p) < 1e-6 }
        }
        let r = capRadius, h = halfLength
        for z in [0.0, thickness] {
            XCTAssertTrue(reports(SIMD3(h + r, 0, z)), "right cap arc at z = \(z)")
            XCTAssertTrue(reports(SIMD3(-h - r, 0, z)), "left cap arc at z = \(z)")
            XCTAssertTrue(reports(SIMD3(0, -r, z)), "bottom line at z = \(z)")
            XCTAssertTrue(reports(SIMD3(0, r, z)), "top line at z = \(z)")
            let center = SIMD3(holeCenter.x, holeCenter.y, z)
            XCTAssertTrue(reported.contains {
                abs($0.z - z) < 1e-6 && abs(simd_distance($0, center) - holeRadius) < 1e-6
            }, "hole rim at z = \(z)")
        }
    }
}
