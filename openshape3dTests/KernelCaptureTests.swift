//
//  KernelCaptureTests.swift
//  openshape3dTests
//
//  The failing-op capture loop, end to end (docs/FREECAD_PLAYBOOK.md D2/D3):
//  a real kernel failure writes a bundle, and replaying that bundle through
//  the SAME kernel entry points reproduces the same typed failure — which is
//  the entire promise ("a bug found live becomes a one-command repro").
//  Pure values over OCCTKernel; no DocumentSession/ModelContainer.
//

import XCTest
import simd
@testable import openshape3d

final class KernelCaptureTests: XCTestCase {

    private var captureDir: URL!

    override func setUpWithError() throws {
        captureDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("KernelCaptureTests-\(UUID().uuidString)")
        KernelCapture.directoryOverride = captureDir
        KernelCapture.forceEnabledForTesting = true
    }

    override func tearDownWithError() throws {
        KernelCapture.forceEnabledForTesting = false
        KernelCapture.directoryOverride = nil
        try? FileManager.default.removeItem(at: captureDir)
    }

    private func bundles() throws -> [URL] {
        (try? FileManager.default.contentsOfDirectory(
            at: captureDir, includingPropertiesForKeys: nil)) ?? []
    }

    /// A Ø10 rim cannot take a 6 mm fillet — the classic over-radius failure,
    /// now expected to leave a replayable bundle behind.
    private func overRadiusFillet() throws
        -> (handle: BRepHandle, result: Result<BRepHandle, OCCTOpError>) {
        let cylinder = try XCTUnwrap(OCCTKernel.primitiveShape(
            .cylinder(radius: 5, height: 8), placement: .identity))
        // Euclid convention: base on y=0, axis +Y — the top rim passes (5, 8, 0).
        let rim = [SIMD3<Double>(5, 8, 0)]
        let result = OCCTKernel.filletResult(
            cylinder, at: rim, radius: 6,
            tolerance: OCCTKernel.matchTolerance(for: cylinder))
        return (cylinder, result)
    }

    // MARK: - The loop

    func testAFailedFilletWritesABundleThatReplaysToTheSameFailure() throws {
        let (_, result) = try overRadiusFillet()
        guard case .failure = result else {
            return XCTFail("the over-radius fillet was supposed to fail")
        }

        let written = try bundles()
        XCTAssertEqual(written.count, 1, "one failure, one bundle")
        let bundle = try XCTUnwrap(written.first)
        XCTAssertTrue(FileManager.default.fileExists(
            atPath: bundle.appendingPathComponent("manifest.json").path))
        XCTAssertTrue(FileManager.default.fileExists(
            atPath: bundle.appendingPathComponent("shape.brep").path))

        let manifest = try KernelCaptureReplay.manifest(bundleAt: bundle)
        XCTAssertEqual(manifest["op"] as? String, "fillet")
        XCTAssertNotNil(manifest["error"] as? String)
        // The input row says the failing op was fed a HEALTHY shape — so the
        // bug is the op, not garbage-in. That one bit is half a diagnosis.
        let inputs = try XCTUnwrap(manifest["inputs"] as? [[String: Any]])
        XCTAssertEqual(inputs.first?["valid"] as? Bool, true)
        XCTAssertEqual(inputs.first?["volumeMM3"] as? Double ?? 0,
                       .pi * 25 * 8, accuracy: 1e-6)

        // Replay reproduces the SAME typed failure offline.
        let outcome = try KernelCaptureReplay.replay(bundleAt: bundle)
        XCTAssertEqual(outcome.op, "fillet")
        XCTAssertFalse(outcome.succeeded)
        XCTAssertEqual(outcome.detail, manifest["error"] as? String,
                       "replay must fail exactly as the live op did")
    }

    func testAFailedBooleanCapturesBothOperands() throws {
        // Disjoint solids: common (intersect) of two boxes that do not touch
        // produces an empty result, which the bridge reports as a failure.
        let a = try XCTUnwrap(OCCTKernel.primitiveShape(
            .box(width: 4, depth: 4, height: 4), placement: .identity))
        let b = try XCTUnwrap(OCCTKernel.primitiveShape(
            .box(width: 4, depth: 4, height: 4),
            placement: Transform3D(translation: SIMD3(100, 0, 0))))
        guard case .failure = OCCTKernel.booleanResult(a, b, op: 2) else {
            return XCTFail("intersecting two distant boxes was supposed to fail")
        }
        let bundle = try XCTUnwrap(try bundles().first)
        for file in ["a.brep", "b.brep", "manifest.json"] {
            XCTAssertTrue(FileManager.default.fileExists(
                atPath: bundle.appendingPathComponent(file).path), file)
        }
        let outcome = try KernelCaptureReplay.replay(bundleAt: bundle)
        XCTAssertFalse(outcome.succeeded)
    }

    // MARK: - Gating and retention

    func testCaptureIsInertWhenDisabled() throws {
        KernelCapture.forceEnabledForTesting = false
        // Under XCTest the default is OFF — the suite exercises failure
        // paths on purpose, and a capture per exercised failure would be
        // hundreds of writes a run.
        guard case .failure = try overRadiusFillet().result else {
            return XCTFail("the over-radius fillet was supposed to fail")
        }
        XCTAssertFalse(FileManager.default.fileExists(atPath: captureDir.path),
                       "no bundle may be written while capture is off")
    }

    func testRetentionKeepsOnlyTheNewestBundles() throws {
        let box = try XCTUnwrap(OCCTKernel.primitiveShape(
            .box(width: 2, depth: 2, height: 2), placement: .identity))
        for _ in 0..<(KernelCapture.keepCount + 3) {
            KernelCapture.recordFailure(
                op: "fillet", inputs: [("shape", box)],
                params: [:], error: .kernelRefused("retention test"))
        }
        XCTAssertEqual(try bundles().count, KernelCapture.keepCount)
    }

    // MARK: - Snapshots

    func testASnapshotReplaysAsAHealthCheck() throws {
        let box = try XCTUnwrap(OCCTKernel.primitiveShape(
            .box(width: 3, depth: 3, height: 3), placement: .identity))
        let bundle = try XCTUnwrap(KernelCapture.recordSnapshot(
            inputs: [("Body", box)], note: "test snapshot"))
        let outcome = try KernelCaptureReplay.replay(bundleAt: bundle)
        XCTAssertTrue(outcome.succeeded)
        XCTAssertTrue(outcome.detail.contains("all valid"), outcome.detail)
    }

    /// Two bodies with one name ("Extrude") each keep their own file.
    func testASnapshotOfTwoSameNamedBodiesKeepsBoth() throws {
        let small = try XCTUnwrap(OCCTKernel.primitiveShape(
            .box(width: 2, depth: 2, height: 2), placement: .identity))
        let large = try XCTUnwrap(OCCTKernel.primitiveShape(
            .box(width: 3, depth: 3, height: 3), placement: .identity))
        let bundle = try XCTUnwrap(KernelCapture.recordSnapshot(
            inputs: [("Extrude", small), ("Extrude", large)], note: "same names"))
        let rows = try XCTUnwrap(KernelCaptureReplay.manifest(bundleAt: bundle)["inputs"] as? [[String: Any]])
        let files = rows.compactMap { $0["file"] as? String }
        XCTAssertEqual(files, ["Extrude.brep", "Extrude-2.brep"])
        let volumes = try files.map { file -> Double in
            let blob = try Data(contentsOf: bundle.appendingPathComponent(file))
            return OCCTKernel.volume(BRepHandle(try XCTUnwrap(OCCTBridge.rawShape(fromSerialized: blob))))
        }
        XCTAssertEqual(volumes[0], 8, accuracy: 1e-6)
        XCTAssertEqual(volumes[1], 27, accuracy: 1e-6)
    }

    // MARK: - Bundle hygiene

    func testReplayThrowsOnAMissingBundle() {
        XCTAssertThrowsError(try KernelCaptureReplay.replay(
            bundleAt: captureDir.appendingPathComponent("no-such-bundle")))
    }

    /// The replay input path must NOT heal: it hands the op exactly the bytes
    /// the failing op saw. Proven by round-tripping the deliberately invalid
    /// open box through raw deserialization — the healing path refuses or
    /// repairs it, the raw path returns it as-is, still invalid.
    func testRawDeserializationPreservesAnInvalidShape() throws {
        let sick = try BRepHandle(XCTUnwrap(OCCTBridge.debugInvalidOpenBox(withSize: 6)))
        let blob = try XCTUnwrap(OCCTKernel.serialize(sick))
        let raw = try XCTUnwrap(OCCTBridge.rawShape(fromSerialized: blob))
        XCTAssertFalse(OCCTKernel.healthReport(for: BRepHandle(raw)).isValid,
                       "raw deserialization must not heal what it reads")
    }
}
