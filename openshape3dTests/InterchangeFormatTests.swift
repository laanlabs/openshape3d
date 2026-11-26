//
//  InterchangeFormatTests.swift
//  openshape3dTests
//
//  Spec §12 (Import / Export) coverage. Before this file the ONLY interchange
//  test was `STLExportTests` — OBJ, 3MF, GLB, DXF and STL *import* all shipped
//  untested, so a regression in any of them would have been silent.
//
//  These are format-shape tests: they assert each writer emits something a
//  consumer can actually parse (counts, required markers, structure), and that
//  the STL importer round-trips what the STL exporter produced.
//

import XCTest
import Euclid
@testable import openshape3d

final class InterchangeFormatTests: XCTestCase {

    /// A 10 mm cube body — 12 triangles, known vertex count.
    private func cubeBody(name: String = "Cube") -> Body {
        Body(name: name,
             transform: .identity,
             primitive: .box(width: 10, depth: 10, height: 10),
             euclidMesh: .primitive(.box(width: 10, depth: 10, height: 10)),
             revision: 1)
    }

    // MARK: - OBJ (§12.2)

    func testOBJExportEmitsParsableVertexAndFaceRecords() {
        let obj = OBJExporter.obj(bodies: [cubeBody()])
        let lines = obj.split(separator: "\n").map(String.init)
        let vertices = lines.filter { $0.hasPrefix("v ") }
        let normals = lines.filter { $0.hasPrefix("vn ") }
        let faces = lines.filter { $0.hasPrefix("f ") }

        XCTAssertFalse(vertices.isEmpty, "OBJ must emit vertex records")
        XCTAssertFalse(faces.isEmpty, "OBJ must emit face records")
        XCTAssertEqual(faces.count, 12, "a cube triangulates to 12 faces")
        XCTAssertFalse(normals.isEmpty, "OBJ should carry normals")

        // OBJ indices are 1-based; a 0 index is the classic off-by-one bug.
        for face in faces {
            for token in face.dropFirst(2).split(separator: " ") {
                let index = Int(token.split(separator: "/").first ?? "") ?? 0
                XCTAssertGreaterThan(index, 0, "OBJ indices are 1-based, never 0")
                XCTAssertLessThanOrEqual(index, vertices.count, "index within range")
            }
        }
    }

    func testOBJPerBodyKeepsBodiesSeparate() {
        let parts = OBJExporter.objPerBody(bodies: [cubeBody(name: "A"), cubeBody(name: "B")])
        XCTAssertEqual(parts.count, 2, "one OBJ per body")
        XCTAssertEqual(Set(parts.map(\.name)).count, 2, "names stay distinct")
        for part in parts {
            XCTAssertTrue(part.obj.contains("v "), "each part carries geometry")
        }
    }

    // MARK: - 3MF (§12.2)

    func testThreeMFIsAZipContainingModelXML() {
        let data = ThreeMFExporter.threeMF(bodies: [cubeBody()])
        XCTAssertGreaterThan(data.count, 4, "3MF must not be empty")
        // 3MF is a ZIP (OPC) package — "PK\003\004" local file header.
        XCTAssertEqual(Array(data.prefix(4)), [0x50, 0x4B, 0x03, 0x04],
                       "3MF must be a ZIP container")

        let xml = ThreeMFExporter.modelXML(bodies: [cubeBody()])
        XCTAssertTrue(xml.contains("<model"), "model root element")
        XCTAssertTrue(xml.contains("<vertices>"), "vertex block")
        XCTAssertTrue(xml.contains("<triangles>"), "triangle block")
        XCTAssertTrue(xml.contains("unit=\"millimeter\"") || xml.contains("millimeter"),
                      "3MF declares millimetre units — the document space")
    }

    // MARK: - GLB (§12.2, also the AR/web-viewer path)

    func testGLBHasValidBinaryHeader() {
        let data = GLBExporter.glb(bodies: [cubeBody()])
        XCTAssertGreaterThan(data.count, 12, "GLB needs at least a header")
        // glTF binary: magic 'glTF' (0x46546C67 little-endian), version 2.
        let magic = Array(data.prefix(4))
        XCTAssertEqual(magic, Array("glTF".utf8), "GLB magic")
        let version = data.subdata(in: 4..<8).withUnsafeBytes { $0.load(as: UInt32.self) }
        XCTAssertEqual(version, 2, "glTF 2.0")
        let declared = data.subdata(in: 8..<12).withUnsafeBytes { $0.load(as: UInt32.self) }
        XCTAssertEqual(Int(declared), data.count,
                       "GLB header length must match the actual payload")
    }

    // MARK: - DXF (§12.2 export / §12.1 import)

    func testDXFExportEmitsWellFormedSections() {
        let entities: [SketchEntity] = [
            .line(id: UUID(), a: SIMD2(0, 0), b: SIMD2(10, 0)),
            .circle(id: UUID(), center: SIMD2(5, 5), radius: 2.5),
        ]
        let dxf = DXFKit.exportSketch(entities: entities, plane: .ground)
        XCTAssertTrue(dxf.contains("SECTION"), "DXF has sections")
        XCTAssertTrue(dxf.contains("ENTITIES"), "DXF has an ENTITIES section")
        XCTAssertTrue(dxf.contains("EOF"), "DXF terminates with EOF")
        XCTAssertTrue(dxf.contains("LINE"), "the line is exported")
        XCTAssertTrue(dxf.contains("CIRCLE"), "the circle is exported")
    }

    // MARK: - STL round-trip (§12.2 export → §12.1 import)

    func testSTLBinaryRoundTripsThroughTheImporter() throws {
        let body = cubeBody()
        let stl = STLExporter.binarySTL(bodies: [body])
        XCTAssertGreaterThan(stl.count, 84, "binary STL = 80-byte header + count + facets")

        // Facet count is a UInt32 at offset 80 and must match the payload size.
        let facets = stl.subdata(in: 80..<84).withUnsafeBytes { $0.load(as: UInt32.self) }
        XCTAssertEqual(Int(facets), 12, "a cube is 12 triangles")
        XCTAssertEqual(stl.count, 84 + Int(facets) * 50, "binary STL facet stride is 50 bytes")

        let imported = try STLImporter.importSTL(stl)
        XCTAssertEqual(imported.triangleCount, 12, "every triangle survives the round-trip")
        XCTAssertFalse(imported.positions.isEmpty)

        // The cube's bounding box must come back the same size.
        let box = imported.localAABB
        let size = box.max - box.min
        XCTAssertEqual(Double(size.x), 10, accuracy: 1e-4)
        XCTAssertEqual(Double(size.y), 10, accuracy: 1e-4)
        XCTAssertEqual(Double(size.z), 10, accuracy: 1e-4)
    }

    func testSTLImporterRejectsGarbageRatherThanCrashing() {
        // A truncated/garbage payload must throw, not trap — imports come from
        // arbitrary user files.
        let garbage = Data(repeating: 0xAB, count: 37)
        XCTAssertThrowsError(try STLImporter.importSTL(garbage),
                             "a malformed STL must surface an error")
    }

    func testSTLImporterAppliesUnitScale() throws {
        let stl = STLExporter.binarySTL(bodies: [cubeBody()])
        let scaled = try STLImporter.importSTL(stl, unitScale: 25.4)  // inches → mm
        let size = scaled.localAABB.max - scaled.localAABB.min
        XCTAssertEqual(Double(size.x), 254, accuracy: 1e-3,
                       "unit scale must be applied on import (§12.1 unit options)")
    }
}
