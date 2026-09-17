//
//  FilletChainCreditTests.swift
//  openshape3dTests
//
//  ChFi3d credits a tangent chain's blend faces to some of its edges only,
//  so an edge inside a chain can generate nothing and still be blended. The
//  bridge counted such an edge as "can't take this size" and refused valid
//  fillets: practice problem 18.5A's R5 port junctions (2 of 5 edges on a
//  port/body chain, 6 of 22 for every junction at once), and the radius
//  probe found no size at all (2026-09-16). Pure values over OCCTKernel, on
//  the committed capture (Fixtures/Captures/port-junction-fillet-chain-credit).
//

import XCTest
import simd
@testable import openshape3d

final class FilletChainCreditTests: XCTestCase {

    private static let bundle = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .appendingPathComponent("Fixtures/Captures/port-junction-fillet-chain-credit", isDirectory: true)

    /// The +z port's junction with the body cylinder and the dome, in the
    /// fixture's edge numbering. Edges 13 and 23 generate no face.
    private static let portOneAndBody = [11, 12, 13, 22, 23]
    /// The two ports' junction with each other. Edge 38 generates no face.
    private static let portOneAndPortTwo = [38, 52, 63, 68]

    private func body() throws -> BRepHandle {
        let blob = try Data(contentsOf: Self.bundle.appendingPathComponent("shape.brep"))
        return BRepHandle(try XCTUnwrap(OCCTBridge.rawShape(fromSerialized: blob)))
    }

    private func allJunctionEdges() throws -> [Int] {
        let params = try XCTUnwrap(KernelCaptureReplay.manifest(bundleAt: Self.bundle)["params"] as? [String: Any])
        return try XCTUnwrap(params["edgeIndices"] as? [Int])
    }

    func testAPortBodyChainBuilds() throws {
        let body = try body()
        let filleted = try OCCTKernel.filletResult(body, edgeIndices: Self.portOneAndBody, radius: 5).get()
        XCTAssertTrue(OCCTKernel.healthReport(for: filleted).isValid)
        XCTAssertEqual(OCCTKernel.volume(filleted) - OCCTKernel.volume(body), 168.340, accuracy: 0.01)
    }

    func testEveryJunctionAtOnceBuilds() throws {
        let body = try body()
        let edges = try allJunctionEdges()
        XCTAssertEqual(edges.count, 22)
        let filleted = try OCCTKernel.filletResult(body, edgeIndices: edges, radius: 5).get()
        XCTAssertTrue(OCCTKernel.healthReport(for: filleted).isValid)
        XCTAssertEqual(OCCTKernel.volume(filleted), 425574.150, accuracy: 0.01)
    }

    /// The drag clamp's probe runs the same per-edge check, so it found no
    /// radius at all for a chain like this.
    func testTheRadiusProbeFindsTheSizeThatBuilds() throws {
        let body = try body()
        let midpoints = OCCTKernel.edgeMidpoints(body)
        let points = try Self.portOneAndPortTwo.map { try XCTUnwrap(midpoints[$0]) }
        let cap = OCCTKernel.maxFilletRadius(body, at: points, tolerance: 1e-3)
        XCTAssertGreaterThanOrEqual(cap, 5)
        XCTAssertNoThrow(try OCCTKernel.filletResult(body, edgeIndices: Self.portOneAndPortTwo, radius: cap).get())
    }

    /// The port/body chain fails at the probe's first tiny size (R0.05
    /// fails validity) though R0.1 to R5 build. The probe gave up there and
    /// the drag went unclamped; it now halves down from its bracket.
    func testTheRadiusProbeLooksPastAFailedTinySize() throws {
        let body = try body()
        XCTAssertThrowsError(try OCCTKernel.filletResult(body, edgeIndices: Self.portOneAndBody, radius: 0.05).get(),
                             "the fixture must still fail at the tiny size for this to test anything")
        let midpoints = OCCTKernel.edgeMidpoints(body)
        let points = try Self.portOneAndBody.map { try XCTUnwrap(midpoints[$0]) }
        let cap = OCCTKernel.maxFilletRadius(body, at: points, tolerance: 1e-3)
        XCTAssertGreaterThanOrEqual(cap, 5)
        XCTAssertNoThrow(try OCCTKernel.filletResult(body, edgeIndices: Self.portOneAndBody, radius: cap).get())
    }

    /// A size the junction really cannot take is still refused.
    func testAnOversizeFilletIsStillRefused() throws {
        let result = OCCTKernel.filletResult(try body(), edgeIndices: Self.portOneAndBody, radius: 20)
        guard case let .failure(error) = result else {
            return XCTFail("R20 on the port junction must fail")
        }
        guard case .partialResult = error else {
            return XCTFail("expected .partialResult, got \(error)")
        }
    }
}
