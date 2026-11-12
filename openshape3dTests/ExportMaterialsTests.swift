//
//  ExportMaterialsTests.swift
//  openshape3dTests
//
//  Exported files keep each body's name and appearance (#133): glTF writes a
//  material per distinct body/face material and a primitive per material a
//  body wears, 3MF a named object with core-spec base materials.
//  `item.rename` names the parts.
//

import XCTest
import simd
@testable import openshape3d

@MainActor
final class ExportMaterialsTests: XCTestCase {

    private func box(_ name: String, at x: Double = 0, color: SIMD4<Double>? = nil) -> Body {
        var transform = Transform3D.identity
        transform.translation = SIMD3(x, 0, 0)
        var body = Body(name: name, transform: transform,
                        primitive: .box(width: 2, depth: 2, height: 2),
                        euclidMesh: .primitive(.box(width: 2, depth: 2, height: 2)), revision: 1)
        if let color { body.material = BodyMaterialSpec(baseColor: color, metallic: 0.2, roughness: 0.7) }
        return body
    }

    /// `body` with the face under its first triangle painted `color`.
    private func painted(_ body: Body, _ color: SIMD4<Double>) throws -> Body {
        var body = body
        let anchor = try XCTUnwrap(FaceMaterialKit.anchor(in: body.render, triangle: 0))
        body.faceMaterials = [FaceMaterial(point: anchor.point, normal: anchor.normal,
                                           material: BodyMaterialSpec(baseColor: color))]
        return body
    }

    private func gltfJSON(_ glb: Data) throws -> [String: Any] {
        func u32(_ o: Int) -> Int { Int(glb.withUnsafeBytes { UInt32(littleEndian: $0.loadUnaligned(fromByteOffset: o, as: UInt32.self)) }) }
        XCTAssertEqual(u32(0), Int(GLBExporter.magic))
        let length = u32(12)
        return try XCTUnwrap(JSONSerialization.jsonObject(with: glb.subdata(in: 20..<(20 + length))) as? [String: Any])
    }

    // MARK: - Table

    func testTableSharesEqualMaterialsAndNamesThem() throws {
        let red = SIMD4<Double>(0.8, 0.1, 0.1, 1)
        let steel = try XCTUnwrap(MaterialPreset.library.first { $0.name == "Steel" })
        var b = box("B", at: 5); b.material = steel.spec
        let table = ExportMaterials.table(for: [box("A", color: red), b, box("C", at: 10, color: red), box("D", at: 15)])
        XCTAssertEqual(table.materials.count, 3, "red is shared by A and C")
        XCTAssertEqual(table.names, ["Material 1", "Steel", "Default"])
        XCTAssertEqual(table.groups.map { $0.map(\.material) }, [[0], [1], [0], [2]])
        XCTAssertEqual(table.groups[0][0].triangles.count, 12)
    }

    func testPaintedFaceIsItsOwnGroup() throws {
        let body = try painted(box("A", color: SIMD4(0, 0, 1, 1)), SIMD4(1, 1, 0, 1))
        let groups = ExportMaterials.table(for: [body]).groups[0]
        XCTAssertEqual(groups.count, 2)
        XCTAssertEqual(groups[1].triangles.count, 2, "one face of a box: two triangles")
        XCTAssertEqual(groups[0].triangles.count + groups[1].triangles.count, 12)
    }

    // MARK: - glTF

    func testGLBWritesNamesAndAMaterialPerBody() throws {
        let json = try gltfJSON(GLBExporter.glb(bodies: [
            box("Wheel", color: SIMD4(0.1, 0.1, 0.1, 1)), box("Body & roof", at: 5, color: SIMD4(0.9, 0.2, 0.1, 0.5)),
        ]))
        let nodes = try XCTUnwrap(json["nodes"] as? [[String: Any]])
        XCTAssertEqual(nodes.compactMap { $0["name"] as? String }, ["Wheel", "Body & roof"])
        let materials = try XCTUnwrap(json["materials"] as? [[String: Any]])
        XCTAssertEqual(materials.count, 2)
        let pbr = try XCTUnwrap(materials[1]["pbrMetallicRoughness"] as? [String: Any])
        let factor = try XCTUnwrap(pbr["baseColorFactor"] as? [Double])
        XCTAssertEqual(factor, [0.9, 0.2, 0.1, 0.5])
        XCTAssertEqual(pbr["metallicFactor"] as? Double ?? -1, 0.2, accuracy: 1e-9)
        XCTAssertEqual(pbr["roughnessFactor"] as? Double ?? -1, 0.7, accuracy: 1e-9)
        XCTAssertEqual(materials[1]["alphaMode"] as? String, "BLEND")
        XCTAssertNil(materials[0]["alphaMode"])
        let meshes = try XCTUnwrap(json["meshes"] as? [[String: Any]])
        let firstPrimitive = try XCTUnwrap((meshes[1]["primitives"] as? [[String: Any]])?.first)
        XCTAssertEqual(firstPrimitive["material"] as? Int, 1)
    }

    func testGLBDefaultLookIsNotAMirror() throws {
        let json = try gltfJSON(GLBExporter.glb(bodies: [box("Plain")]))
        let material = try XCTUnwrap((json["materials"] as? [[String: Any]])?.first)
        XCTAssertEqual(material["name"] as? String, "Default")
        let pbr = try XCTUnwrap(material["pbrMetallicRoughness"] as? [String: Any])
        XCTAssertEqual(pbr["roughnessFactor"] as? Double, 0.5, "app roughness 0 is its legacy highlight")
    }

    func testGLBPaintedFaceIsASecondPrimitiveOverTheSameVertices() throws {
        let body = try painted(box("A", color: SIMD4(0, 0, 1, 1)), SIMD4(1, 1, 0, 1))
        let json = try gltfJSON(GLBExporter.glb(bodies: [body]))
        let primitives = try XCTUnwrap((json["meshes"] as? [[String: Any]])?.first?["primitives"] as? [[String: Any]])
        XCTAssertEqual(primitives.map { $0["material"] as? Int }, [0, 1])
        let accessors = try XCTUnwrap(json["accessors"] as? [[String: Any]])
        let counts = primitives.compactMap { $0["indices"] as? Int }.map { accessors[$0]["count"] as? Int ?? 0 }
        XCTAssertEqual(counts, [30, 6])
        let positions = primitives.compactMap { ($0["attributes"] as? [String: Int])?["POSITION"] }
        XCTAssertEqual(Set(positions).count, 1)
    }

    // MARK: - 3MF

    func testThreeMFNamesObjectsAndAssignsBaseMaterials() throws {
        let body = try painted(box("Lid <top>", color: SIMD4(1, 0, 0, 1)), SIMD4(0, 1, 0, 0.5))
        let xml = ThreeMFExporter.modelXML(bodies: [body, box("Base", at: 5)])
        XCTAssertTrue(xml.contains("<basematerials id=\"3\">"), xml)
        XCTAssertTrue(xml.contains("<base name=\"Material 1\" displaycolor=\"#FF0000\"/>"))
        XCTAssertTrue(xml.contains("displaycolor=\"#00FF0080\""))
        XCTAssertTrue(xml.contains("<base name=\"Default\""))
        XCTAssertTrue(xml.contains("<object id=\"1\" name=\"Lid &lt;top&gt;\" type=\"model\" pid=\"3\" pindex=\"0\">"))
        XCTAssertTrue(xml.contains("<object id=\"2\" name=\"Base\" type=\"model\" pid=\"3\" pindex=\"2\">"))
        XCTAssertEqual(xml.components(separatedBy: "p1=\"1\"").count - 1, 2, "the painted face's two triangles")
        let materials = try XCTUnwrap(xml.range(of: "<basematerials"))
        let firstObject = try XCTUnwrap(xml.range(of: "<object "))
        XCTAssertLessThan(materials.lowerBound, firstObject.lowerBound, "defined before use")
        XCTAssertTrue(XMLParser(data: Data(xml.utf8)).parse(), "well-formed")
    }

    // MARK: - item.rename

    func testRenameParses() {
        let id = UUID()
        guard case let .success(.rename(got, name)) = AgentExec.parse(["op": "item.rename",
                                                                        "args": ["id": id.uuidString, "name": "  Wheel FL "]])
        else { return XCTFail("parse") }
        XCTAssertEqual(got, id); XCTAssertEqual(name, "Wheel FL")
        for (args, code) in [([:], "missing_id"), (["id": "x"], "bad_uuid"),
                             (["id": id.uuidString, "name": "  "], "missing_name")] as [([String: Any], String)] {
            guard case let .failure(e) = AgentExec.parse(["op": "item.rename", "args": args]) else { return XCTFail(code) }
            XCTAssertEqual(e.code, code)
        }
    }
}
