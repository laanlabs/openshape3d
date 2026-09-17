//
//  ShapeHealthTests.swift
//  openshape3dTests
//
//  The geometry health report (docs/FREECAD_PLAYBOOK.md D1): a healthy solid
//  reports clean with real context numbers; a deliberately broken one names
//  its faults per sub-shape; the slow BOP check runs only when asked AND only
//  on a shape that already passed BRepCheck. Pure values over OCCTKernel —
//  no DocumentSession/ModelContainer.
//

import XCTest
import simd
@testable import openshape3d

final class ShapeHealthTests: XCTestCase {

    private func box(_ size: Double) throws -> BRepHandle {
        try XCTUnwrap(OCCTKernel.primitiveShape(
            .box(width: size, depth: size, height: size), placement: .identity))
    }

    private func invalidOpenBox(_ size: Double = 10) throws -> BRepHandle {
        try BRepHandle(XCTUnwrap(OCCTBridge.debugInvalidOpenBox(withSize: size)))
    }

    // MARK: - Healthy shapes

    func testAValidBoxReportsHealthyWithRealNumbers() throws {
        let health = OCCTKernel.healthReport(for: try box(10))
        XCTAssertTrue(health.isValid)
        XCTAssertTrue(health.findings.isEmpty)
        XCTAssertNil(health.error)
        XCTAssertEqual(health.counts["solids"], 1)
        XCTAssertEqual(health.counts["faces"], 6)
        XCTAssertEqual(health.counts["edges"], 12)
        XCTAssertEqual(health.counts["vertices"], 8)
        XCTAssertEqual(health.volumeMM3, 1000, accuracy: 1e-9)
        // A fresh analytic primitive sits at Precision::Confusion() (1e-7).
        XCTAssertLessThanOrEqual(health.toleranceMax, 1e-6)
        // A closed solid has no free boundary wires.
        XCTAssertEqual(health.openFreeWires, 0)
    }

    func testACylinderReportsItsAnalyticFaces() throws {
        let cylinder = try XCTUnwrap(OCCTKernel.primitiveShape(
            .cylinder(radius: 4, height: 6), placement: .identity))
        let health = OCCTKernel.healthReport(for: cylinder)
        XCTAssertTrue(health.isValid)
        XCTAssertEqual(health.counts["faces"], 3)  // 2 caps + 1 wall
        XCTAssertEqual(health.volumeMM3, Double.pi * 16 * 6, accuracy: 1e-6)
    }

    // MARK: - Faulty shapes

    /// The DEBUG factory builds a box whose shell is missing one face — the
    /// solid cannot be closed, and the report must SAY so, naming the
    /// offending sub-shape rather than shrugging "invalid".
    func testTheOpenBoxIsDiagnosedAsNotClosed() throws {
        let health = OCCTKernel.healthReport(for: try invalidOpenBox())
        XCTAssertFalse(health.isValid)
        XCTAssertFalse(health.findings.isEmpty,
                       "an invalid shape must carry at least one named finding")
        XCTAssertTrue(health.findings.contains { $0.status == "notClosed" },
                      "expected a notClosed finding, got: \(health.findingsSummary)")
        // Five faces of the box survive; the report's context numbers agree.
        XCTAssertEqual(health.counts["faces"], 5)
        XCTAssertFalse(health.findingsSummary.isEmpty)
    }

    /// The missing face leaves exactly one free boundary loop — and because
    /// its edges close into a rectangle, it is a CLOSED free wire (open free
    /// wires are unclosed chains, a different kind of sick).
    func testTheOpenBoxHasOneFreeBoundaryLoop() throws {
        let health = OCCTKernel.healthReport(for: try invalidOpenBox())
        XCTAssertEqual(health.closedFreeWires, 1)
        XCTAssertEqual(health.openFreeWires, 0)
    }

    /// The report judges a meshed shape on a copy without its render mesh
    /// (see `TangentPocketValidityTests`). The copy must name findings the
    /// same way ("Shell1", "Edge7" index the same sub-shapes).
    func testAMeshedShapeReportsTheSameNamedFindings() throws {
        let plain = OCCTKernel.healthReport(for: try invalidOpenBox())
        let meshed = try invalidOpenBox()
        XCTAssertFalse(OCCTKernel.renderMesh(from: meshed).indices.isEmpty,
                       "the open box must actually carry a mesh for this to test anything")
        let report = OCCTKernel.healthReport(for: meshed)
        XCTAssertFalse(report.isValid)
        XCTAssertEqual(report.findings, plain.findings)
        XCTAssertEqual(report.counts, plain.counts)
    }

    // MARK: - BOP check gating

    func testBOPCheckRunsOnAValidShapeAndFindsNothingWrongWithABox() throws {
        let health = OCCTKernel.healthReport(for: try box(10), runBOPCheck: true)
        XCTAssertTrue(health.bopCheckRan)
        XCTAssertTrue(health.bopFindings.isEmpty,
                      "a plain box has no BOP faults, got: \(health.bopFindings)")
    }

    func testBOPCheckIsDeclinedForAnInvalidShape() throws {
        // FreeCAD's gating, kept deliberately: the BOP check is advisory and
        // slow, and running it on a shape BRepCheck already condemned only
        // buries the real findings.
        let health = OCCTKernel.healthReport(for: try invalidOpenBox(),
                                             runBOPCheck: true)
        XCTAssertFalse(health.bopCheckRan)
    }

    func testBOPCheckIsNotRunUnlessRequested() throws {
        let health = OCCTKernel.healthReport(for: try box(4))
        XCTAssertFalse(health.bopCheckRan)
    }

    // MARK: - Kernel-side face info (the identity source for assigned renders)

    /// A REVOLVED solid's caps carry a mirrored face location, so the plane
    /// axis flipped by the orientation flag pointed the base cap INTO the
    /// body — a FaceRef minted from it never resolved. The oriented normal
    /// (`BRepGProp_Face`, the one the volume integral uses) is outward.
    func testFaceInfoOfARevolvedCylinderHasOutwardCaps() throws {
        let plane = SketchPlane(origin: .zero, xAxis: SIMD3(1, 0, 0), yAxis: SIMD3(0, 1, 0))
        let ids = [UUID(), UUID(), UUID(), UUID()]
        let rect = Profile(loop: [SIMD2(0, 0), SIMD2(10, 0), SIMD2(10, 20), SIMD2(0, 20)],
                           kind: .polygonal, sourceEntityIDs: Set(ids), edgeEntityIDs: ids)
        let cylinder = try XCTUnwrap(OCCTKernel.revolveSolid(
            outer: rect, holes: [], plane: plane,
            axisOrigin: .zero, axisDirection: SIMD3(0, 1, 0), angleRadians: 2 * .pi))
        let caps = OCCTKernel.faceInfo(cylinder).filter { $0.signature?.kind == .planar }
        XCTAssertEqual(caps.count, 2)
        for cap in caps {
            // Outward: away from the body's centre at y = 10.
            let outward = cap.centroid.y > 10 ? 1.0 : -1.0
            XCTAssertEqual(cap.normal.y, outward, accuracy: 1e-9,
                           "cap at y=\(cap.centroid.y) reports \(cap.normal)")
            XCTAssertEqual(cap.area, .pi * 100, accuracy: 1e-6)
        }
    }

    func testFaceInfoDescribesABoxWithOutwardNormals() throws {
        let box = try box(10)
        let infos = OCCTKernel.faceInfo(box)
        XCTAssertEqual(infos.count, 6)
        XCTAssertEqual(Set(infos.map(\.index)), Set(1...6), "dense 1-based")
        for info in infos {
            let signature = try XCTUnwrap(info.signature)
            XCTAssertEqual(signature.kind, .planar)
            XCTAssertEqual(info.area, 100, accuracy: 1e-9)
            // Outward: the normal agrees with centroid-minus-body-centre.
            let centre = SIMD3<Double>(0, 5, 0)  // box is centred x/z, base y=0
            XCTAssertGreaterThan(simd_dot(info.normal, info.centroid - centre),
                                 4.9, "normal must point OUT at \(info.centroid)")
        }
    }

    func testFaceInfoDescribesACylinderWall() throws {
        let cylinder = try XCTUnwrap(OCCTKernel.primitiveShape(
            .cylinder(radius: 4, height: 6), placement: .identity))
        let infos = OCCTKernel.faceInfo(cylinder)
        XCTAssertEqual(infos.count, 3)
        let wall = try XCTUnwrap(infos.first {
            if case .cylindrical = $0.signature?.kind { return true }
            return false
        })
        guard case let .cylindrical(radius)? = wall.signature?.kind else {
            return XCTFail("expected cylindrical")
        }
        XCTAssertEqual(radius, 4, accuracy: 1e-9)
        XCTAssertEqual(abs(wall.normal.y), 1, accuracy: 1e-9,
                       "a cylinder wall's \"normal\" is its axis")
        XCTAssertEqual(wall.area, 2 * .pi * 4 * 6, accuracy: 1e-6)
    }

    /// The regression that motivated faceInfo: a revolved washer's render is
    /// NOT the kernel tessellation, so the mesh-channel path served
    /// duplicate kernel indices. Kernel-side info must be dense and sane.
    func testFaceInfoIsDenseAndDistinctForARevolvedWasher() throws {
        let plane = SketchPlane(origin: .zero, xAxis: SIMD3(1, 0, 0),
                                yAxis: SIMD3(0, 1, 0))
        let profile = Profile(
            loop: [SIMD2(4, 0), SIMD2(6, 0), SIMD2(6, 3), SIMD2(4, 3)],
            kind: .polygonal, sourceEntityIDs: [])
        let washer = try XCTUnwrap(OCCTKernel.revolveSolid(
            outer: profile, holes: [], plane: plane,
            axisOrigin: .zero, axisDirection: SIMD3(0, 1, 0),
            angleRadians: 2 * .pi))
        let infos = OCCTKernel.faceInfo(washer)
        XCTAssertEqual(infos.count, 4, "2 annular caps + 2 cylindrical walls")
        XCTAssertEqual(Set(infos.map(\.index)).count, 4,
                       "indices are DISTINCT — the duplicated-index bug class")
        let radii = infos.compactMap { info -> Double? in
            if case let .cylindrical(radius)? = info.signature?.kind { return radius }
            return nil
        }
        XCTAssertEqual(Set(radii.map { ($0 * 1e9).rounded() / 1e9 }), [4, 6])
    }

    // MARK: - Transport

    /// The raw dictionary is served verbatim by /v1/check, so it must be
    /// JSON-encodable exactly as the bridge hands it over — for the healthy,
    /// the broken, and the BOP-checked case alike.
    func testHealthReportDictionariesAreJSONSafe() throws {
        for handle in [try box(10), try invalidOpenBox()] {
            let dictionary = OCCTKernel.healthReportDictionary(
                for: handle, runBOPCheck: true)
            XCTAssertTrue(JSONSerialization.isValidJSONObject(dictionary))
            XCTAssertNoThrow(try JSONSerialization.data(withJSONObject: dictionary))
        }
    }

    /// A result straight out of a boolean must read as healthy — this is the
    /// integration the report exists for: "did the op hand back something
    /// sick" answered by numbers instead of squinting at the viewport.
    func testABooleanResultReportsHealthy() throws {
        let plate = try box(10)
        let cutter = try XCTUnwrap(OCCTKernel.primitiveShape(
            .cylinder(radius: 2, height: 20), placement: .identity))
        let result = try OCCTKernel.booleanResult(plate, cutter, op: 1).get()
        let health = OCCTKernel.healthReport(for: result.handle, runBOPCheck: true)
        XCTAssertTrue(health.isValid)
        XCTAssertTrue(health.bopCheckRan)
        XCTAssertTrue(health.bopFindings.isEmpty)
    }
}
