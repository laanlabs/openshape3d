//
//  BooleanFaceMergeTests.swift
//  openshape3dTests
//
//  Merging same-domain faces after a boolean (ShapeUpgrade_UnifySameDomain)
//  can break a valid result, and it rewrites edges of the shape it is given
//  in place, edges the result shares with the operands, the stored bodies.
//  Practice problem 18.19 in drawing order: the window cut after the Ø13
//  boss came out with an unorientable boss face, and the Ø6 bore through the
//  boss after it left the part itself invalid, healed to a 12.9 mm tolerance,
//  with every later cut removing nothing (2026-09-17). The boolean now merges
//  a copy and keeps the unmerged result when the merge breaks it. Pure values
//  over OCCTKernel on the committed captures (Fixtures/Captures/
//  coincident-boss-arc-window-cut, boss-bore-face-merge).
//

import XCTest
import simd
@testable import openshape3d

final class BooleanFaceMergeTests: XCTestCase {

    private static let bundle = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .appendingPathComponent("Fixtures/Captures/coincident-boss-arc-window-cut", isDirectory: true)

    override func tearDown() {
        OCCTBridge.debugSetBooleanUnmergedFallbackEnabled(true)
        super.tearDown()
    }

    private static let boreBundle = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .appendingPathComponent("Fixtures/Captures/boss-bore-face-merge", isDirectory: true)

    private func load(_ bundle: URL, _ file: String) throws -> BRepHandle {
        let blob = try Data(contentsOf: bundle.appendingPathComponent(file))
        return BRepHandle(try XCTUnwrap(OCCTBridge.rawShape(fromSerialized: blob)))
    }

    private func operands() throws -> (arm: BRepHandle, window: BRepHandle) {
        (try load(Self.bundle, "a.brep"), try load(Self.bundle, "b.brep"))
    }

    func testTheWindowCutAfterTheBossBuildsExactly() throws {
        let (arm, window) = try operands()
        let cut = try OCCTKernel.booleanResult(arm, window, op: 1).get().handle
        let health = OCCTKernel.healthReport(for: cut)
        XCTAssertTrue(health.isValid, health.findingsSummary)
        XCTAssertLessThan(health.toleranceMax, 1e-3)
        XCTAssertEqual(OCCTKernel.volume(cut), 3545.524, accuracy: 0.01)
    }

    /// The loosened body took later cuts as no-ops. This one removes exactly
    /// what it overlaps.
    func testTheCutBodyTakesTheNextCut() throws {
        let (arm, window) = try operands()
        let cut = try OCCTKernel.booleanResult(arm, window, op: 1).get().handle
        let bar = try XCTUnwrap(OCCTKernel.primitiveShape(
            .box(width: 2, depth: 2, height: 200),
            placement: Transform3D(translation: SIMD3(0, -100, 4.5))))
        let overlap = OCCTKernel.volume(try OCCTKernel.booleanResult(cut, bar, op: 2).get().handle)
        XCTAssertGreaterThan(overlap, 1, "the bar must cross the body for this to test anything")
        let after = OCCTKernel.volume(try OCCTKernel.booleanResult(cut, bar, op: 1).get().handle)
        XCTAssertEqual(OCCTKernel.volume(cut) - after, overlap, accuracy: 1e-3)
    }

    /// The bore cut must leave the body it cuts untouched: the merge used to
    /// rewrite edges the result shares with it, and the stored part went
    /// invalid.
    func testTheBoreCutLeavesItsTargetBodyValid() throws {
        let part = try load(Self.boreBundle, "a.brep")
        let bore = try load(Self.boreBundle, "b.brep")
        XCTAssertTrue(OCCTKernel.healthReport(for: part).isValid)
        let cut = try OCCTKernel.booleanResult(part, bore, op: 1).get().handle
        XCTAssertTrue(OCCTKernel.healthReport(for: part).isValid, "the target body was changed by the cut")
        let health = OCCTKernel.healthReport(for: cut)
        XCTAssertTrue(health.isValid, health.findingsSummary)
        XCTAssertLessThan(health.toleranceMax, 1e-3)
        XCTAssertEqual(OCCTKernel.volume(cut), 3291.055, accuracy: 0.01)
        // And the same cut again on the same body gives the same result.
        let again = try OCCTKernel.booleanResult(part, bore, op: 1).get().handle
        XCTAssertEqual(OCCTKernel.volume(again), OCCTKernel.volume(cut), accuracy: 1e-6)
    }

    /// Behind the fallback, a result ShapeFix can only pass by loosening its
    /// tolerance is still refused.
    func testWithoutTheFallbackTheLoosenedHealIsStillRefused() throws {
        OCCTBridge.debugSetBooleanUnmergedFallbackEnabled(false)
        let (arm, window) = try operands()
        guard case let .failure(error) = OCCTKernel.booleanResult(arm, window, op: 1) else {
            return XCTFail("without the fallback this cut must still be refused")
        }
        XCTAssertTrue(error.message.contains("loosening its tolerance"), error.message)
    }

    /// The unmerged result carries the builder's ancestry: every R6.5
    /// face of the result descends from an operand's R6.5 face.
    func testTheUnmergedBossFacesKeepTheirAncestry() throws {
        let (arm, window) = try operands()
        let (outcome, ancestry) = try OCCTKernel.booleanResultWithAncestry(arm, window, op: 1).get()
        func bossFaces(_ h: BRepHandle) -> Set<Int> {
            Set(OCCTKernel.faceInfo(h).filter {
                if case let .cylindrical(radius)? = $0.signature?.kind { return abs(radius - 6.5) < 1e-6 }
                return false
            }.map(\.index))
        }
        let sources = [bossFaces(arm), bossFaces(window)]
        let resultBoss = bossFaces(outcome.handle)
        XCTAssertFalse(resultBoss.isEmpty)
        for face in resultBoss {
            let rows = ancestry.ancestors(ofResultFace: face).filter { $0.inputKind == .face }
            XCTAssertTrue(rows.contains { sources[$0.inputOrdinal].contains($0.inputSubshape) },
                          "result face \(face) has no R6.5 ancestor: \(rows)")
        }
    }
}
