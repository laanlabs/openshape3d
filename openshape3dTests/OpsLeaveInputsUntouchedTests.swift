//
//  OpsLeaveInputsUntouchedTests.swift
//  openshape3dTests
//
//  A kernel op must not change the shapes it is given: an input is a stored
//  body, and undo snapshots share its handles. Two ops did. The boolean's
//  same-domain face merge rewrote edges its result shares with the operands,
//  which left 18.19's part invalid (BooleanFaceMergeTests). The enclosed-
//  hollow shell's cut ran destructively and wrote 24 pcurves onto the
//  filleted body's edges (2026-09-17). Each op here runs on a committed
//  capture or a primitive, and its input must serialize to the same bytes
//  afterwards. Pure values over OCCTKernel.
//

import XCTest
import simd
@testable import openshape3d

final class OpsLeaveInputsUntouchedTests: XCTestCase {

    private static let captures = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .appendingPathComponent("Fixtures/Captures", isDirectory: true)

    private func load(_ bundle: String, _ file: String) throws -> BRepHandle {
        let blob = try Data(contentsOf: Self.captures.appendingPathComponent(bundle).appendingPathComponent(file))
        return BRepHandle(try XCTUnwrap(OCCTBridge.rawShape(fromSerialized: blob)))
    }

    /// The serialized shape, without the TShape flag lines ("1100000": free,
    /// modified, checked, ...). OCCT clears a shape's Free flag whenever it
    /// is placed inside another, as an outward hollow's cut does with the
    /// body it grows from; geometry, tolerances and pcurves are all still
    /// compared.
    private func snapshot(_ shape: BRepHandle) -> String? {
        guard let data = OCCTKernel.serialize(shape), let text = String(data: data, encoding: .utf8) else { return nil }
        return text.split(separator: "\n", omittingEmptySubsequences: false)
            .filter { line in !(line.count == 7 && line.allSatisfy { $0 == "0" || $0 == "1" }) }
            .joined(separator: "\n")
    }

    private func assertUntouched(_ inputs: [BRepHandle], file: StaticString = #filePath, line: UInt = #line,
                                 _ op: () throws -> Void) rethrows {
        let before = inputs.map(snapshot)
        XCTAssertFalse(before.contains(nil), file: file, line: line)
        try op()
        for (i, input) in inputs.enumerated() {
            XCTAssertTrue(snapshot(input) == before[i], "input \(i) was changed by the op", file: file, line: line)
        }
    }

    private func holedPlate() throws -> BRepHandle {
        let plate = try XCTUnwrap(OCCTKernel.primitiveShape(.box(width: 20, depth: 20, height: 10), placement: .identity))
        let pin = try XCTUnwrap(OCCTKernel.primitiveShape(.cylinder(radius: 3, height: 30),
                                                           placement: Transform3D(translation: SIMD3(0, -10, 0))))
        let holed = try OCCTKernel.booleanResult(plate, pin, op: 1).get().handle
        // A fresh copy, so no other shape shares its sub-shapes.
        return BRepHandle(try XCTUnwrap(OCCTBridge.rawShape(fromSerialized: try XCTUnwrap(OCCTKernel.serialize(holed)))))
    }

    func testAnEnclosedHollowLeavesTheBodyUntouched() throws {
        let body = try load("filleted-pipe-junction-shell-c0", "shape.brep")
        try assertUntouched([body]) {
            _ = try OCCTKernel.shellResult(body, openingAt: [], thickness: 3, tolerance: 0.4).get()
        }
        let plate = try holedPlate()
        try assertUntouched([plate]) {
            _ = try OCCTKernel.shellResult(plate, openingAt: [], thickness: -2, tolerance: 0.4).get()
        }
    }

    func testAnOpenShellOverAFilletLeavesTheBodyUntouched() throws {
        let body = try load("filleted-pipe-junction-shell-c0", "shape.brep")
        let params = try XCTUnwrap(KernelCaptureReplay.manifest(
            bundleAt: Self.captures.appendingPathComponent("filleted-pipe-junction-shell-c0"))["params"] as? [String: Any])
        let points = try XCTUnwrap(params["points"] as? [[Double]]).map { SIMD3($0[0], $0[1], $0[2]) }
        try assertUntouched([body]) {
            _ = try OCCTKernel.shellResult(body, openingAt: points, thickness: 3, tolerance: 0.4).get()
        }
    }

    func testBooleansLeaveTheirOperandsUntouched() throws {
        for bundle in ["coincident-boss-arc-window-cut", "boss-bore-face-merge"] {
            let a = try load(bundle, "a.brep"), b = try load(bundle, "b.brep")
            try assertUntouched([a, b]) {
                _ = try OCCTKernel.booleanResult(a, b, op: 1).get()
            }
        }
    }

    func testAFilletLeavesTheBodyUntouched() throws {
        let body = try load("port-junction-fillet-chain-credit", "shape.brep")
        try assertUntouched([body]) {
            _ = try OCCTKernel.filletResult(body, edgeIndices: [11, 12, 13, 22, 23], radius: 5).get()
        }
    }

    func testRemovingAFaceLeavesTheBodyUntouched() throws {
        let plate = try holedPlate()
        try assertUntouched([plate]) {
            _ = try OCCTKernel.removingFacesResult(plate, at: [SIMD3(3, 5, 0)], tolerance: 0.4).get()
        }
    }
}
