//
//  ShellOverFilletTests.swift
//  openshape3dTests
//
//  A fillet over a curved junction comes back from OCCT as a B-spline face
//  with C0 knots, and BRepOffset refuses C0 geometry before it tries any
//  join: the body could not be shelled at all ("OCCT offset: C0Geometry",
//  practice problem 18.23, 2026-09-16). The shell now splits the body at
//  those knots and retries. Pure values over OCCTKernel, on the committed
//  capture (Fixtures/Captures/filleted-pipe-junction-shell-c0).
//

import XCTest
import simd
@testable import openshape3d

final class ShellOverFilletTests: XCTestCase {

    private static let bundle = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .appendingPathComponent("Fixtures/Captures/filleted-pipe-junction-shell-c0", isDirectory: true)

    private func fixture() throws -> (body: BRepHandle, openings: [SIMD3<Double>], thickness: Double, tolerance: Double) {
        let blob = try Data(contentsOf: Self.bundle.appendingPathComponent("shape.brep"))
        let body = BRepHandle(try XCTUnwrap(OCCTBridge.rawShape(fromSerialized: blob)))
        let params = try XCTUnwrap(KernelCaptureReplay.manifest(bundleAt: Self.bundle)["params"] as? [String: Any])
        let points = try XCTUnwrap(params["points"] as? [[Double]]).map { SIMD3($0[0], $0[1], $0[2]) }
        return (body, points, try XCTUnwrap(params["thickness"] as? Double),
                try XCTUnwrap(params["tolerance"] as? Double))
    }

    /// Face 3 of the fixture is the pipe-junction blend, the B-spline face
    /// OCCT reports as C0 (read with a continuity dump, 2026-09-16).
    private static let c0BlendFace = 3

    func testAShellOverAFilletedPipeJunctionBuilds() throws {
        let (body, openings, thickness, tolerance) = try fixture()
        XCTAssertTrue(OCCTKernel.healthReport(for: body).isValid)
        let shelled = try OCCTKernel.shellResult(body, openingAt: openings,
                                                 thickness: thickness, tolerance: tolerance).get()
        XCTAssertTrue(OCCTKernel.healthReport(for: shelled).isValid)
        XCTAssertEqual(OCCTKernel.volume(shelled), 33324.749, accuracy: 0.01)
    }

    /// A thinner wall goes through the same retry and removes less.
    func testATwoMillimetreShellBuildsToo() throws {
        let (body, openings, _, tolerance) = try fixture()
        let shelled = try OCCTKernel.shellResult(body, openingAt: openings,
                                                 thickness: 2, tolerance: tolerance).get()
        XCTAssertTrue(OCCTKernel.healthReport(for: shelled).isValid)
        XCTAssertEqual(OCCTKernel.volume(shelled), 23034.235, accuracy: 0.01)
    }

    /// With no opening the shell offsets the whole solid and subtracts it,
    /// and that offset hit the same refusal. The closed hollow keeps a 3 mm
    /// cap where the open shell has each opening: the flange cavity outline
    /// (R25 about the origin, R10 at x ±38), the Ø19 neck bore and the Ø16
    /// pipe bore. The two are built differently (thick solid; offset copy
    /// cut from the body) and agree to 0.16 mm³ (4 ppm).
    func testAClosedHollowOfTheFilletedBodyBuilds() throws {
        let (body, openings, thickness, tolerance) = try fixture()
        let open = try OCCTKernel.shellResult(body, openingAt: openings,
                                              thickness: thickness, tolerance: tolerance).get()
        let closed = try OCCTKernel.shellResult(body, openingAt: [],
                                                thickness: thickness, tolerance: tolerance).get()
        XCTAssertTrue(OCCTKernel.healthReport(for: closed).isValid)
        let angle = acos(15.0 / 38)
        let flangeCavity = 625 * (.pi - 2 * angle) + 100 * 2 * angle + 2 * 35 * 38 * sin(angle)
        let caps = 3 * (flangeCavity + .pi * 9.5 * 9.5 + .pi * 8 * 8)
        XCTAssertEqual(OCCTKernel.volume(closed), OCCTKernel.volume(open) + caps, accuracy: 0.5)
    }

    /// Splitting renumbers faces, but the ancestry still names the INPUT's
    /// faces: the split blend's pieces descend from the blend face, and no
    /// row points past the input's own face map.
    func testTheSplitBlendFaceKeepsItsAncestry() throws {
        let (body, openings, thickness, tolerance) = try fixture()
        let inputFaces = OCCTKernel.faceInfo(body).count
        let (shelled, ancestry) = try OCCTKernel.shellResultWithAncestry(
            body, openingAt: openings, thickness: thickness, tolerance: tolerance).get()
        let faceRows = ancestry.rows.filter { $0.inputKind == .face }
        XCTAssertTrue(faceRows.allSatisfy { (1...inputFaces).contains($0.inputSubshape) })
        let resultFaces = OCCTKernel.faceInfo(shelled).count
        XCTAssertTrue(faceRows.allSatisfy { (1...resultFaces).contains($0.resultFace) })
        let curved = OCCTKernel.faceInfo(body).filter { $0.signature == nil }.map(\.index)
        XCTAssertTrue(curved.contains(Self.c0BlendFace))
        for blend in curved {
            XCTAssertFalse(faceRows.filter { $0.inputSubshape == blend }.isEmpty,
                           "input face \(blend) (not planar or cylindrical) has no descendant in the shell")
        }
        // Most of the outside survives as-is; the inner wall is generated.
        XCTAssertGreaterThan(faceRows.filter { $0.relation == .same }.count, inputFaces / 2)
        XCTAssertFalse(faceRows.filter { $0.relation != .same }.isEmpty)
    }
}
