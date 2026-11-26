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

    // MARK: - OBJ + MTL (#133)

    private func lines(_ text: String, _ key: String) -> [String] {
        text.split(separator: "\n").map(String.init).filter { $0.hasPrefix(key + " ") }
    }

    func testOBJOfADefaultDesignStaysASingleFileWithoutMaterialStatements() {
        let files = OBJExporter.objWithMaterials(bodies: [box("Plain")], materialLibrary: "house.mtl")
        XCTAssertNil(files.mtl, "nothing but the default look: no library")
        XCTAssertFalse(files.obj.contains("mtllib"))
        XCTAssertFalse(files.obj.contains("usemtl"))
        XCTAssertNil(OBJExporter.mtl(bodies: [box("Plain")]))
        XCTAssertEqual(files.obj, OBJExporter.obj(bodies: [box("Plain")]), "geometry untouched")
    }

    func testOBJNamesItsLibraryAndTagsEachBodysFaces() throws {
        let walls = box("Walls", color: SIMD4(1, 0, 0, 1))
        let roof = box("Roof", at: 5, color: SIMD4(0, 0, 1, 0.5))
        let files = OBJExporter.objWithMaterials(bodies: [walls, roof, box("Base", at: 10)],
                                                 materialLibrary: "house.mtl")
        XCTAssertEqual(lines(files.obj, "mtllib"), ["mtllib house.mtl"])
        XCTAssertEqual(lines(files.obj, "o"), ["o Walls", "o Roof", "o Base"])
        let used = lines(files.obj, "usemtl")
        XCTAssertEqual(used.count, 3, "one material run per body")
        XCTAssertEqual(Set(used).count, 3)

        let mtl = try XCTUnwrap(files.mtl)
        let declared = lines(mtl, "newmtl").map { String($0.dropFirst("newmtl ".count)) }
        XCTAssertEqual(Set(declared), Set(used.map { String($0.dropFirst("usemtl ".count)) }),
                       "every usemtl names a material the library declares")
        XCTAssertTrue(declared.allSatisfy { !$0.contains(" ") }, "a usemtl name cannot hold a space")
        XCTAssertTrue(mtl.contains("Kd 1.000000 0.000000 0.000000"))
        XCTAssertTrue(mtl.contains("Kd 0.000000 0.000000 1.000000"))
        XCTAssertTrue(mtl.contains("d 0.500000"), "opacity")
        XCTAssertTrue(mtl.contains("Pm 0.200000"), "metallic")
        XCTAssertTrue(mtl.contains("Pr 0.700000"), "roughness")
        // The faces themselves are the plain export's: materials only add lines.
        XCTAssertEqual(lines(files.obj, "f").count,
                       lines(OBJExporter.obj(bodies: [walls, roof, box("Base", at: 10)]), "f").count)
    }

    func testOBJPaintedFaceIsItsOwnMaterialRunAndNeverMergedWithItsNeighbours() throws {
        let body = try painted(box("Block", color: SIMD4(0.2, 0.4, 0.6, 1)), SIMD4(1, 1, 0, 1))
        let files = OBJExporter.objWithMaterials(bodies: [body], materialLibrary: "block.mtl")
        let text = files.obj.split(separator: "\n").map(String.init)
        var runs: [(name: String, faces: Int)] = []
        for line in text {
            if line.hasPrefix("usemtl ") { runs.append((String(line.dropFirst(7)), 0)) }
            else if line.hasPrefix("f "), !runs.isEmpty { runs[runs.count - 1].faces += 1 }
        }
        XCTAssertEqual(runs.count, 2)
        XCTAssertEqual(runs.map(\.faces).sorted(), [1, 5], "the painted face is one quad, the other five keep the body's colour")
        XCTAssertEqual(lines(try XCTUnwrap(files.mtl), "newmtl").count, 2)
    }

    func testOBJWithMaterialsComesBackThroughTheAppsOwnImporter() throws {
        let walls = box("Walls", color: SIMD4(1, 0, 0, 1))
        let roof = box("Roof", at: 5, color: SIMD4(0, 0, 1, 1))
        let files = OBJExporter.objWithMaterials(bodies: [walls, roof], materialLibrary: "house.mtl")
        let parts = try MeshImportKit.parts(from: Data(files.obj.utf8), fileName: "house.obj",
                                            siblings: ["house.mtl": Data(try XCTUnwrap(files.mtl).utf8)],
                                            unitScale: 1)
        XCTAssertEqual(parts.map(\.name), ["Walls", "Roof"])
        XCTAssertEqual(parts[0].material?.baseColor, SIMD4(1, 0, 0, 1))
        XCTAssertEqual(parts[1].material?.baseColor, SIMD4(0, 0, 1, 1))
        XCTAssertEqual(parts[0].material?.metallic ?? -1, 0.2, accuracy: 1e-6, "Pm is read back")
        XCTAssertEqual(parts[0].material?.roughness ?? -1, 0.7, accuracy: 1e-6, "Pr is read back")
        XCTAssertEqual(MeasureKit.bodyVolume(parts[0].mesh), 8, accuracy: 1e-4)
    }

    /// Blender writes n-gons as they are; a concave one must not be fanned.
    func testTexturedOBJImporterEarClipsAConcavePolygon() throws {
        // An L (area 6) as one hexagon in the XY plane, and its mirror below
        // so the pair encloses nothing but still has area to measure.
        let obj = """
        o L
        v 0 0 0
        v 4 0 0
        v 4 1 0
        v 1 1 0
        v 1 3 0
        v 0 3 0
        f 1 2 3 4 5 6
        """
        let parts = try MeshImportKit.parts(from: Data(obj.utf8), fileName: "l.obj", unitScale: 1)
        let mesh = try XCTUnwrap(parts.first).mesh
        XCTAssertEqual(mesh.triangleCount, 4)
        var area = 0.0
        for t in 0..<mesh.triangleCount {
            let a = SIMD3<Double>(mesh.positions[Int(mesh.indices[3 * t])])
            let b = SIMD3<Double>(mesh.positions[Int(mesh.indices[3 * t + 1])])
            let c = SIMD3<Double>(mesh.positions[Int(mesh.indices[3 * t + 2])])
            let cross = simd_cross(b - a, c - a)
            XCTAssertGreaterThan(cross.z, 0, "every triangle keeps the polygon's winding")
            area += simd_length(cross) / 2
        }
        XCTAssertEqual(area, 6, accuracy: 1e-9, "a fan from the first corner would cover 7.5")
    }
}
