//
//  UnionThenSubtractBugReportTests.swift
//  openshape3dTests
//
//  Bug report a1ee4e4a (2026-09-05, iPad): "I can't seem to get subtract to
//  work when I've made a union of two different shape objects and then I go
//  to subtract and I hit the second one." The attached design's four bodies
//  are committed fixtures (render mesh + transform, brep where the body had
//  one); the union result is MESH-ONLY. This replays every subtract pairing
//  the Combine tool could run on them and reports what the kernel does.
//

import XCTest
import simd
import Euclid
@testable import openshape3d

final class UnionThenSubtractBugReportTests: XCTestCase {

    private static let fixtures = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .appendingPathComponent("Fixtures/bugreport-a1ee4e4a-subtract", isDirectory: true)

    private static let ids = ["57BE4069", "F8CB255A", "B4D895F5", "8394ACCA"]

    private func load(_ id: String) throws -> Body {
        let dir = Self.fixtures
        let render = try MeshBlob.decode(Data(contentsOf: dir.appendingPathComponent("\(id).d3so")))
        let transform = try JSONDecoder().decode(
            Transform3D.self, from: Data(contentsOf: dir.appendingPathComponent("\(id).transform.json")))
        var body = Body(id: BodyID(), name: id, transform: transform, primitive: nil,
                        euclidMesh: EuclidBridge.euclidMesh(from: render), revision: 1)
        let brepURL = dir.appendingPathComponent("\(id).brep")
        if let data = try? Data(contentsOf: brepURL), let handle = OCCTKernel.deserialize(data) {
            body.brep = handle
        }
        return body
    }

    private func volume(_ mesh: Euclid.Mesh) -> Double {
        MeasureKit.bodyVolume(EuclidBridge.renderMesh(from: mesh), scale: 1)
    }

    func testEverySubtractPairingOnTheReportedDesign() throws {
        let bodies = try Self.ids.map(load)
        for body in bodies {
            let world = body.euclidMesh().transformed(by: body.transform.euclid)
            NSLog("body \(body.name): brep=\(body.brep != nil) triangles=\(body.render.triangleCount) volume=\(volume(world)) bounds=\(world.bounds)")
        }
        for target in bodies {
            for tool in bodies where tool.name != target.name {
                let start = Date()
                let mesh = KernelOps.boolean(.subtract, target: target, tool: tool)
                let composed = OCCTKernel.composedBooleanResult(.subtract, target: target, tool: tool)
                let composedNote: String
                switch composed {
                case nil: composedNote = "mesh-only operand"
                case .success(let outcome)?: composedNote = "OCCT ok (\(outcome.solidCount) solids)"
                case .failure(let error)?: composedNote = "OCCT failed: \(error.message)"
                }
                NSLog("subtract \(target.name) − \(tool.name): polygons=\(mesh.polygons.count) volume=\(volume(mesh)) in \(String(format: "%.2f", Date().timeIntervalSince(start)))s; \(composedNote)")
            }
        }
    }
}
