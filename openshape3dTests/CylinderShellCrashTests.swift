//
//  CylinderShellCrashTests.swift
//  openshape3dTests
//
//  Bug report 6cb10527 (2026-09-05, iPad): "creating a cylinder, then Modify →
//  Shell and tapping that cylinder crashes the app". The attached design's
//  cylinder was an extruded circle with NO brep (its exact render mesh is the
//  committed fixture), so the pick ran the MESH shell (`KernelOps.shell`) and
//  the face pick ran `FaceTopology.planarFace` on it; the brep path is pinned
//  too. Either path may refuse — neither may take the process down.
//

import Darwin
import XCTest
import simd
import Euclid
@testable import openshape3d

final class CylinderShellCrashTests: XCTestCase {

    private static let fixture = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .appendingPathComponent("Fixtures/bugreport-6cb10527-cylinder.d3so")

    /// Print a native backtrace on a trap so the failing frame is in the log
    /// (a Swift `assert`/`fatalError` in the simulator writes no .ips).
    private static let installTrapHooks: Void = {
        let handler: @convention(c) (Int32) -> Void = { sig in
            var frames = [UnsafeMutableRawPointer?](repeating: nil, count: 128)
            let n = backtrace(&frames, Int32(frames.count))
            let msg = "\n=== CylinderShellCrashTests caught signal \(sig) ===\n"
            _ = msg.withCString { write(STDERR_FILENO, $0, strlen($0)) }
            backtrace_symbols_fd(&frames, n, STDERR_FILENO)
            _exit(128 + sig)
        }
        for sig in [SIGTRAP, SIGSEGV, SIGBUS, SIGILL, SIGABRT] { signal(sig, handler) }
    }()

    override func setUp() {
        super.setUp()
        _ = Self.installTrapHooks
    }

    /// The report's cylinder: a circle of radius ≈2.06 on the front plane,
    /// extruded 10 mm, as the mesh fallback builds it.
    private func extrudedCircle(radius: Double = 2.0615528128088303,
                                height: Double = 10, segments: Int = 48) -> Euclid.Mesh {
        let center = SIMD2<Double>(-4.5, 3.5)
        let loop = (0..<segments).map { i -> SIMD2<Double> in
            let a = Double(i) / Double(segments) * 2 * .pi
            return center + SIMD2(cos(a), sin(a)) * radius
        }
        let profile = Profile(loop: loop, kind: .circle(center: center, radius: radius),
                              sourceEntityIDs: [])
        let plane = SketchPlane(origin: .zero, xAxis: SIMD3(1, 0, 0), yAxis: SIMD3(0, 0, -1))
        return KernelOps.extrude(profile: profile, in: plane, distance: height)
    }

    private func volume(_ mesh: Euclid.Mesh) -> Double {
        MeasureKit.bodyVolume(EuclidBridge.renderMesh(from: mesh), scale: 1)
    }

    /// The planar face whose normal points along `direction`, if any.
    private func face(of mesh: Euclid.Mesh, along direction: SIMD3<Float>) -> PlanarFace? {
        let render = EuclidBridge.renderMesh(from: mesh)
        for t in 0..<render.triangleCount {
            let a = render.positions[Int(render.indices[t * 3])]
            let b = render.positions[Int(render.indices[t * 3 + 1])]
            let c = render.positions[Int(render.indices[t * 3 + 2])]
            let n = simd_cross(b - a, c - a)
            let len = simd_length(n)
            guard len > 1e-9, simd_dot(n / len, direction) > 0.999 else { continue }
            return FaceTopology.planarFace(in: render, seedTriangle: t)
        }
        return nil
    }

    // MARK: The report's exact body

    /// Every step the Shell pick runs on the archived mesh: the closed hollow
    /// preview, a planar-face pick from EVERY triangle (the user tapped the
    /// wall somewhere), and the open-face shell for each face found.
    func testArchivedCylinderSurvivesTheWholeShellPick() throws {
        let data = try Data(contentsOf: Self.fixture)
        let render = try MeshBlob.decode(data)
        NSLog("archived cylinder: \(render.positions.count) vertices, \(render.triangleCount) triangles")
        let body = Body(id: BodyID(), name: "Extrude", transform: .identity, primitive: nil,
                        euclidMesh: EuclidBridge.euclidMesh(from: render), revision: 1)
        let mesh = body.euclidMesh()
        let full = volume(mesh)

        for thickness in [1.0, 0.5, 2.0, 0.1, 1.03] {
            let out = KernelOps.shell(mesh: mesh, thickness: thickness)
            NSLog("archived closed shell t=\(thickness): polygons=\(out.polygons.count) volume=\(volume(out)) of \(full)")
        }

        var faces: [PlanarFace] = []
        var seen = Set<Set<Int>>()
        for t in 0..<body.render.triangleCount {
            guard let face = FaceTopology.planarFace(in: body.render, seedTriangle: t) else { continue }
            let key = Set(face.triangles)
            if seen.insert(key).inserted { faces.append(face) }
        }
        NSLog("archived cylinder planar faces: \(faces.count) (outline sizes \(faces.map { $0.outline.count }))")
        // 2.0 is the default the bar arms for this body (min(2, 10/4)) — the
        // one that trapped: the cap opening's prism wall coincided with the
        // cavity wall and the CSG left slivers `makeWatertight` could not cap.
        for thickness in [1.0, 2.0, 2.5] {
            let closed = volume(KernelOps.shell(mesh: mesh, thickness: thickness))
            for face in faces {
                let out = KernelOps.shell(mesh: mesh, thickness: thickness, openFaces: [face])
                if face.outline.count > 4 || !out.polygons.isEmpty {
                    NSLog("archived open shell t=\(thickness) (\(face.outline.count)-point outline): polygons=\(out.polygons.count) volume=\(volume(out))")
                }
                if face.outline.count > 4 {
                    // A cap opening on a Ø21 × 10 cylinder is a legitimate
                    // cup at any of these walls: it must build, and open less
                    // than the closed hollow leaves.
                    XCTAssertFalse(out.polygons.isEmpty, "cap opening at t=\(thickness) produced nothing")
                    XCTAssertTrue(KernelOps.isFinite(out))
                    XCTAssertLessThan(volume(out), closed, "opening the cap removes the lid (t=\(thickness))")
                }
                if !out.polygons.isEmpty {
                    let preview = Body(id: body.id, name: body.name, transform: body.transform,
                                       primitive: nil, euclidMesh: out, revision: 2)
                    XCTAssertFalse(preview.render.positions.isEmpty)
                }
            }
            let all = KernelOps.shell(mesh: mesh, thickness: thickness, openFaces: faces)
            NSLog("archived open shell t=\(thickness) (all faces): polygons=\(all.polygons.count)")
        }
    }

    /// The same pick on a thread with a DEVICE-sized stack: iOS gives the main
    /// thread 1 MB (the simulator's process gets 8 MB), so a recursion that is
    /// fine here can overflow on the iPad.
    func testArchivedCylinderShellFitsADeviceStack() throws {
        let data = try Data(contentsOf: Self.fixture)
        let render = try MeshBlob.decode(data)
        let mesh = EuclidBridge.euclidMesh(from: render)
        var faces: [PlanarFace] = []
        var seen = Set<Set<Int>>()
        for t in 0..<render.triangleCount {
            guard let face = FaceTopology.planarFace(in: render, seedTriangle: t) else { continue }
            if seen.insert(Set(face.triangles)).inserted { faces.append(face) }
        }
        let done = expectation(description: "shell on a 512 KB stack")
        let thread = Thread {
            for thickness in [2.0, 1.0] {
                _ = KernelOps.shell(mesh: mesh, thickness: thickness)
                for face in faces {
                    let out = KernelOps.shell(mesh: mesh, thickness: thickness, openFaces: [face])
                    if !out.polygons.isEmpty {
                        _ = Body(id: BodyID(), name: "preview", transform: .identity,
                                 primitive: nil, euclidMesh: out, revision: 2)
                    }
                }
            }
            done.fulfill()
        }
        thread.stackSize = 512 * 1024
        thread.start()
        wait(for: [done], timeout: 120)
    }

    // MARK: Mesh path (a fresh 48-gon prism)

    func testMeshShellOfExtrudedCircleClosedDoesNotCrash() {
        let cyl = extrudedCircle()
        XCTAssertFalse(cyl.polygons.isEmpty)
        let full = volume(cyl)
        for thickness in [1.0, 0.5, 2.0, 0.1] {
            let out = KernelOps.shell(mesh: cyl, thickness: thickness)
            NSLog("mesh closed shell t=\(thickness): polygons=\(out.polygons.count) volume=\(volume(out)) of \(full)")
            if !out.polygons.isEmpty {
                XCTAssertLessThan(volume(out), full, "a hollow removes material (t=\(thickness))")
            }
        }
    }

    func testMeshShellOfExtrudedCircleOpenCapDoesNotCrash() throws {
        let cyl = extrudedCircle()
        // The cap along the extrude direction (+Y on the front plane).
        let cap = try XCTUnwrap(face(of: cyl, along: SIMD3(0, 1, 0)), "the prism has a planar cap")
        let out = KernelOps.shell(mesh: cyl, thickness: 1.0, openFaces: [cap])
        NSLog("mesh open-cap shell: polygons=\(out.polygons.count) volume=\(volume(out))")
    }

    // MARK: B-rep path

    func testOCCTEnclosedShellOfCylinderDoesNotCrash() throws {
        let cyl = try XCTUnwrap(OCCTKernel.primitiveShape(
            .cylinder(radius: 2.0615528128088303, height: 10), placement: .identity))
        let tol = OCCTKernel.matchTolerance(for: cyl)
        for thickness in [1.0, 0.5, 2.0] {
            let result = OCCTKernel.shellResult(cyl, openingAt: [], thickness: thickness, tolerance: tol)
            switch result {
            case .success(let hollow):
                XCTAssertFalse(OCCTKernel.renderMesh(from: hollow).positions.isEmpty)
            case .failure(let error):
                NSLog("occt closed shell t=\(thickness) refused: \(error)")
            }
        }
    }

    func testOCCTShellOpeningCurvedWallDoesNotCrash() throws {
        let cyl = try XCTUnwrap(OCCTKernel.primitiveShape(
            .cylinder(radius: 2.0615528128088303, height: 10), placement: .identity))
        let tol = OCCTKernel.matchTolerance(for: cyl)
        // A point on the curved wall, and one on the top cap.
        for point in [SIMD3<Double>(2.0615528128088303, 5, 0), SIMD3<Double>(0, 10, 0)] {
            let result = OCCTKernel.shellResult(cyl, openingAt: [point], thickness: 1.0, tolerance: tol)
            switch result {
            case .success(let hollow):
                XCTAssertFalse(OCCTKernel.renderMesh(from: hollow).positions.isEmpty)
            case .failure(let error):
                NSLog("occt shell opening at \(point) refused: \(error)")
            }
        }
    }
}
