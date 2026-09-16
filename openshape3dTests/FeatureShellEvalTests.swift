//
//  FeatureShellEvalTests.swift
//  openshape3dTests
//
//  Phase E tranche 4 proof: Shell as a parametric feature-graph node. Mirrors
//  FeatureBlendEvalTests — build the graph programmatically, evaluate, assert
//  geometry, then EDIT the thickness and re-evaluate to prove the persisted
//  FaceRef re-resolves against the rebuilt input body.
//

import XCTest
import simd
import Euclid
@testable import openshape3d

final class FeatureShellEvalTests: XCTestCase {

    private final class RevisionSource {
        private var value: UInt64 = 0
        func next() -> UInt64 { value += 1; return value }
    }

    private func volume(_ body: Body) -> Double {
        MeasureKit.bodyVolume(body.render, scale: 1)
    }

    private let boxFeature = FeatureID()
    private let shellFeature = FeatureID()
    private let boxID = BodyID()

    private func boxNode() -> FeatureNode {
        FeatureNode(
            id: boxFeature, name: "Box",
            kind: .primitive(spec: .box(width: 10, depth: 10, height: 10),
                             placement: .identity),
            outputBodyIDs: [boxID])
    }

    /// Evaluate the lone box and mint a FaceRef for its +Z (top) face, the
    /// same way `EditorViewModel.commitShell` pins open faces.
    private func captureTopFaceRef() throws -> FaceRef {
        let graph = FeatureGraph(nodes: [boxNode()])
        let result = graph.evaluate(sketches: [], planes: [],
                                    naming: SignatureNaming(), nextRevision: RevisionSource().next)
        let body = try XCTUnwrap(result.bodies.first, "box evaluates")
        let render = body.render
        var top: PlanarFace?
        for t in 0..<render.triangleCount {
            let a = render.positions[Int(render.indices[t * 3])]
            let b = render.positions[Int(render.indices[t * 3 + 1])]
            let c = render.positions[Int(render.indices[t * 3 + 2])]
            let n = simd_cross(b - a, c - a)
            let len = simd_length(n)
            guard len > 1e-9, (n / len).z > 0.999 else { continue }
            top = FaceTopology.planarFace(in: render, seedTriangle: t)
            break
        }
        let face = try XCTUnwrap(top, "box has a +Z face")
        let normal = SIMD3<Double>(
            Double(face.normal.x), Double(face.normal.y), Double(face.normal.z))
        var area = abs(Profile.signedArea(face.outline))
        for hole in face.holes { area -= abs(Profile.signedArea(hole)) }
        let signature = FaceSignature(
            kind: .planar, normal: normal, centroid: face.origin,
            area: max(area, 0), planeOffset: simd_dot(normal, face.origin))
        return FaceRef(
            body: BodyRef(producer: boxFeature, bodyID: boxID),
            creator: boxFeature, role: .derived(index: 0), signature: signature)
    }

    private func shellGraph(openFaces: [FaceRef], thickness: Double) -> FeatureGraph {
        FeatureGraph(nodes: [
            boxNode(),
            FeatureNode(id: shellFeature, name: "Shell",
                        kind: .shell(body: BodyRef(producer: boxFeature, bodyID: boxID),
                                     openFaces: openFaces,
                                     thickness: Expr(value: thickness)),
                        outputBodyIDs: []),
        ])
    }

    // MARK: Closed hollow node

    func testClosedShellNodeHollowsBox() throws {
        let result = shellGraph(openFaces: [], thickness: 1)
            .evaluate(sketches: [], planes: [],
                      naming: SignatureNaming(), nextRevision: RevisionSource().next)
        XCTAssertTrue(result.errors.isEmpty, "shell must not error: \(result.errors)")
        let body = try XCTUnwrap(result.bodies.first)
        XCTAssertEqual(body.id, boxID, "the shelled body keeps the box's BodyID")
        // Walls of 1 around an 8³ cavity.
        XCTAssertEqual(volume(body), 1000 - 512, accuracy: 1.0)
    }

    // MARK: Open-face node

    func testOpenTopShellNodeCutsOpening() throws {
        let topRef = try captureTopFaceRef()
        let result = shellGraph(openFaces: [topRef], thickness: 1)
            .evaluate(sketches: [], planes: [],
                      naming: SignatureNaming(), nextRevision: RevisionSource().next)
        XCTAssertTrue(result.errors.isEmpty, "open shell must not error: \(result.errors)")
        let body = try XCTUnwrap(result.bodies.first)
        // Open-top box: 1000 − 8·8·9.
        XCTAssertEqual(volume(body), 424, accuracy: 1.0)
    }

    // MARK: Edit thickness → FaceRef re-resolves against the rebuilt body

    func testEditingThicknessRebuildsAndFaceStillResolves() throws {
        let topRef = try captureTopFaceRef()
        let thin = shellGraph(openFaces: [topRef], thickness: 1)
            .evaluate(sketches: [], planes: [],
                      naming: SignatureNaming(), nextRevision: RevisionSource().next)
        let thick = shellGraph(openFaces: [topRef], thickness: 2)
            .evaluate(sketches: [], planes: [],
                      naming: SignatureNaming(), nextRevision: RevisionSource().next)
        XCTAssertNil(thick.errors[shellFeature], "edited shell still resolves the face")
        // t=2: 6×6 cavity through 8 of the 10 height → 1000 − 288.
        XCTAssertEqual(volume(try XCTUnwrap(thin.bodies.first)), 424, accuracy: 1.0)
        XCTAssertEqual(volume(try XCTUnwrap(thick.bodies.first)), 712, accuracy: 1.5)
    }

    // MARK: Errors

    func testOverThickShellErrorsNode() throws {
        let result = shellGraph(openFaces: [], thickness: 6)
            .evaluate(sketches: [], planes: [],
                      naming: SignatureNaming(), nextRevision: RevisionSource().next)
        XCTAssertNotNil(result.errors[shellFeature], "an over-thick shell errors the node")
    }

    func testZeroThicknessErrorsNode() throws {
        let result = shellGraph(openFaces: [], thickness: 0)
            .evaluate(sketches: [], planes: [],
                      naming: SignatureNaming(), nextRevision: RevisionSource().next)
        XCTAssertNotNil(result.errors[shellFeature])
    }
}

/// The point a planar face is handed to the kernel by must lie ON the face.
/// An annulus (a top face with a through hole) has its outline centroid in
/// the hole, which is why every ring-topped shell used to be refused.
final class PlanarFacePickPointTests: XCTestCase {
    func testAnnularFacePickPointLiesOnTheRingAndShellSucceeds() throws {
        // Ø100 × 20 disc (Y-up), Ø40 through hole.
        let disc = try XCTUnwrap(OCCTKernel.primitiveShape(.cylinder(radius: 50, height: 20), placement: .identity))
        let hole = try XCTUnwrap(OCCTKernel.primitiveShape(.cylinder(radius: 20, height: 60), placement: .identity))
        let ring = try XCTUnwrap(OCCTKernel.boolean(disc, hole, op: OCCTKernel.booleanOp(.subtract)))
        let raw = OCCTKernel.renderMesh(from: ring)
        let mesh = RenderMesh(positions: raw.positions, normals: raw.normals, indices: raw.indices)
        var top: FaceTopology.PlanarFace?
        var topY = -Double.infinity
        for t in 0..<mesh.triangleCount {
            let a = mesh.positions[Int(mesh.indices[t * 3])]
            let b = mesh.positions[Int(mesh.indices[t * 3 + 1])]
            let c = mesh.positions[Int(mesh.indices[t * 3 + 2])]
            let n = simd_cross(b - a, c - a)
            guard simd_length(n) > 1e-9, simd_normalize(n).y > 0.999 else { continue }
            if Double(a.y) > topY, let face = FaceTopology.planarFace(in: mesh, seedTriangle: t) {
                top = face; topY = Double(a.y)
            }
        }
        let face = try XCTUnwrap(top, "the ring has a +Y annular face")
        XCTAssertFalse(face.holes.isEmpty, "the top face is an annulus")
        let point = FeatureGraph.pointOnPlanarFace(face, mesh: mesh)
        XCTAssertEqual(point.y, topY, accuracy: 1e-6, "on the top plane")
        let radial = hypot(point.x - face.origin.x, point.z - face.origin.z)
        XCTAssertGreaterThan(radial, 20, "outside the hole")
        XCTAssertLessThan(radial, 50, "inside the rim")

        // And the kernel accepts it as the shell's opening.
        let shelled = try OCCTKernel.shellResult(
            ring, openingAt: [point], thickness: 3,
            tolerance: OCCTKernel.matchTolerance(for: ring)).get()
        XCTAssertLessThan(OCCTKernel.volume(shelled), OCCTKernel.volume(ring) * 0.6,
                          "hollowed through the open ring face")
    }

    /// The Shell TOOL's live preview must hand OCCT the same on-face points as
    /// the evaluator. It sent the outline centroid, which on a holed face lies
    /// in the hole: the preview never computed and Apply stayed disabled,
    /// though the same shell built fine over the bridge (2026-09-16).
    func testShellToolOpenPointsHollowAHoledFace() throws {
        // 10 × 10 × 6 box (centred in X/Z, base on y = 0) with a Ø4 hole
        // straight through along Y: the OS3D_DEBUG_SEED_HOLE shape.
        let box = try XCTUnwrap(OCCTKernel.primitiveShape(.box(width: 10, depth: 10, height: 6), placement: .identity))
        let hole = try XCTUnwrap(OCCTKernel.primitiveShape(.cylinder(radius: 2, height: 60), placement: .identity))
        let holed = try XCTUnwrap(OCCTKernel.boolean(box, hole, op: OCCTKernel.booleanOp(.subtract)))
        let solidBox: Double = 10 * 10 * 6
        let throughHole: Double = Double.pi * 2 * 2 * 6
        XCTAssertEqual(OCCTKernel.volume(holed), solidBox - throughHole, accuracy: 1e-3,
                       "the hole goes straight through")

        let raw = OCCTKernel.renderMesh(from: holed)
        let mesh = RenderMesh(positions: raw.positions, normals: raw.normals, indices: raw.indices)
        var top: FaceTopology.PlanarFace?
        for t in 0..<mesh.triangleCount {
            let a = mesh.positions[Int(mesh.indices[t * 3])]
            let b = mesh.positions[Int(mesh.indices[t * 3 + 1])]
            let c = mesh.positions[Int(mesh.indices[t * 3 + 2])]
            let n = simd_cross(b - a, c - a)
            guard simd_length(n) > 1e-9, simd_normalize(n).y > 0.999, abs(a.y - 6) < 1e-4 else { continue }
            top = FaceTopology.planarFace(in: mesh, seedTriangle: t)
            break
        }
        let face = try XCTUnwrap(top, "the box has a +Y top face")
        XCTAssertFalse(face.holes.isEmpty, "the top face has the hole in it")

        // The tool's points: OCCT accepts the face and the wall is exact.
        // Cavity with the top open: 9 × 9 × 5.5, less the Ø5 zone around the hole.
        let points = EditorViewModel.shellOpenPoints(for: [face], mesh: mesh)
        let shelled = try OCCTKernel.shellResult(
            holed, openingAt: points, thickness: 0.5,
            tolerance: OCCTKernel.matchTolerance(for: holed)).get()
        let openBox: Double = 9 * 9 * 5.5
        let holeZone: Double = Double.pi * 2.5 * 2.5 * 5.5
        let cavity: Double = openBox - holeZone
        XCTAssertEqual(OCCTKernel.volume(shelled), OCCTKernel.volume(holed) - cavity, accuracy: 0.05)

        // What the tool used to send, the outline centroid, lies in the hole
        // and OCCT refuses it: the failure this test guards against.
        let centre = face.outline.reduce(SIMD2<Double>.zero, +) / Double(face.outline.count)
        let outlineCentroid = face.origin + face.basisX * centre.x + face.basisY * centre.y
        XCTAssertLessThan(hypot(outlineCentroid.x, outlineCentroid.z), 2, "the outline centroid is in the hole")
        if case .success = OCCTKernel.shellResult(
            holed, openingAt: [outlineCentroid], thickness: 0.5,
            tolerance: OCCTKernel.matchTolerance(for: holed)) {
            XCTFail("a point in the hole should not identify the face")
        }
    }
}
