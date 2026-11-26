//
//  ExportAppearanceTests.swift
//  openshape3dTests
//
//  #133: what a design looks like survives export. The palette the
//  exporters share, then GLB and 3MF: names, body materials, painted faces
//  — and a design nobody coloured still exports as it always did.
//

import XCTest
import simd
@testable import openshape3d

@MainActor
final class ExportAppearanceTests: XCTestCase {

    private func cube(_ name: String, at x: Double = 0, material: BodyMaterialSpec? = nil) -> Body {
        var transform = Transform3D.identity
        transform.translation = SIMD3(x, 0, 0)
        var body = Body(name: name, transform: transform,
                        primitive: .box(width: 2, depth: 2, height: 2),
                        euclidMesh: .primitive(.box(width: 2, depth: 2, height: 2)), revision: 1)
        body.material = material
        return body
    }

    private let brass = BodyMaterialSpec(baseColor: SIMD4(0.8, 0.6, 0.2, 1), metallic: 1, roughness: 0.3)
    private let glass = BodyMaterialSpec(baseColor: SIMD4(0.5, 0.75, 1, 0.25), metallic: 0, roughness: 0.1)
    private let paint = BodyMaterialSpec(baseColor: SIMD4(1, 0, 0, 1), metallic: 0, roughness: 0.5)

    /// `body` with the face its first triangle lies on painted `material`.
    private func painting(_ body: Body, with material: BodyMaterialSpec) -> Body {
        var body = body
        let mesh = body.render
        let corner = { (k: Int) in SIMD3<Double>(mesh.positions[Int(mesh.indices[k])]) }
        let (a, b, c) = (corner(0), corner(1), corner(2))
        body.faceMaterials.append(FaceMaterial(point: (a + b + c) / 3,
                                               normal: simd_normalize(simd_cross(b - a, c - a)), material: material))
        return body
    }

    private func glTF(_ glb: Data) throws -> [String: Any] {
        let length = Int(glb.withUnsafeBytes { UInt32(littleEndian: $0.loadUnaligned(fromByteOffset: 12, as: UInt32.self)) })
        let json = try JSONSerialization.jsonObject(with: glb.subdata(in: 20..<(20 + length)))
        return try XCTUnwrap(json as? [String: Any])
    }

    // MARK: - Palette

    func testAPlainDesignHasNoPaletteAndOneUnstyledRunPerBody() {
        let palette = ExportAppearance.palette(for: [cube("A"), cube("B", at: 5)])
        XCTAssertTrue(palette.isPlain)
        XCTAssertEqual(palette.runs.count, 2)
        for runs in palette.runs {
            XCTAssertEqual(runs.count, 1)
            XCTAssertNil(runs[0].material)
            XCTAssertEqual(runs[0].triangles, Array(0..<12), "the whole cube")
        }
    }

    func testBodiesSharingAMaterialShareOneEntryInFirstUseOrder() {
        let palette = ExportAppearance.palette(for: [cube("A", material: brass), cube("B", material: glass),
                                                     cube("C", material: brass), cube("D")])
        XCTAssertEqual(palette.materials, [brass, glass])
        XCTAssertEqual(palette.runs.map { $0.first?.material }, [0, 1, 0, nil])
        XCTAssertEqual(palette.names.count, 2)
        XCTAssertEqual(Set(palette.names).count, 2, "names are unique")
    }

    func testAPaintedFaceLeavesTheBodysRunAndGetsItsOwn() {
        let body = painting(cube("Die", material: brass), with: paint)
        let runs = ExportAppearance.palette(for: [body]).runs[0]
        XCTAssertEqual(runs.count, 2)
        XCTAssertEqual(runs[0].material, 0, "the body's own material comes first")
        XCTAssertEqual(runs[0].triangles.count, 10)
        XCTAssertEqual(runs[1].material, 1)
        XCTAssertEqual(runs[1].triangles.count, 2, "one square face")
        XCTAssertTrue(Set(runs[0].triangles).isDisjoint(with: runs[1].triangles))
        XCTAssertEqual(Set(runs[0].triangles + runs[1].triangles), Set(0..<12), "every triangle exactly once")
    }

    func testAPaintedFaceOnABodyWithoutAMaterialKeepsTheRestUnstyled() {
        let runs = ExportAppearance.palette(for: [painting(cube("Die"), with: paint)]).runs[0]
        XCTAssertEqual(runs.map(\.material), [nil, 0])
        XCTAssertEqual(runs.map(\.triangles.count), [10, 2])
    }

    func testPresetsKeepTheirNamesAndOthersAreNumbered() throws {
        let steel = try XCTUnwrap(MaterialPreset.library.first)
        let palette = ExportAppearance.palette(for: [cube("A", material: steel.spec), cube("B", material: paint),
                                                     cube("C", material: glass)])
        XCTAssertEqual(palette.names[0], steel.name)
        XCTAssertEqual(Array(palette.names[1...]), ["Material 1", "Material 2"])
    }

    func testColourValuesAreClampedAndFormatted() {
        XCTAssertEqual(ExportAppearance.hex(paint), "#FF0000")
        XCTAssertEqual(ExportAppearance.hex(glass), "#80BFFF40", "alpha appended when not opaque")
        let wild = BodyMaterialSpec(baseColor: SIMD4(2, -1, .nan, 1), metallic: 7, roughness: 0)
        XCTAssertEqual(ExportAppearance.color(wild), SIMD4(1, 0, 0, 1))
        XCTAssertEqual(ExportAppearance.metallic(wild), 1)
        XCTAssertEqual(ExportAppearance.roughness(wild), 0.5, "the app's 0 is not a mirror")
        XCTAssertEqual(ExportAppearance.roughness(brass), 0.3)
        XCTAssertEqual(ExportAppearance.xmlAttribute("A & <B> \"c\"\u{1}"), "A &amp; &lt;B&gt; &quot;c&quot;")
    }

    // MARK: - GLB

    func testGLBOfAPlainDesignKeepsTheStockMaterialAndOnePrimitivePerBody() throws {
        let json = try glTF(GLBExporter.glb(bodies: [cube("A"), cube("B", at: 5)]))
        let materials = try XCTUnwrap(json["materials"] as? [[String: Any]])
        XCTAssertEqual(materials.count, 1)
        XCTAssertEqual(materials[0]["name"] as? String, "Default")
        let meshes = try XCTUnwrap(json["meshes"] as? [[String: Any]])
        for mesh in meshes {
            let primitives = try XCTUnwrap(mesh["primitives"] as? [[String: Any]])
            XCTAssertEqual(primitives.count, 1)
            XCTAssertEqual(primitives[0]["material"] as? Int, 0)
        }
    }

    func testGLBCarriesNamesMaterialsAndPaintedFaces() throws {
        let die = painting(cube("Die", material: brass), with: paint)
        let json = try glTF(GLBExporter.glb(bodies: [die, cube("Window", at: 5, material: glass), cube("Plain", at: 9)]))

        let nodes = try XCTUnwrap(json["nodes"] as? [[String: Any]])
        XCTAssertEqual(nodes.compactMap { $0["name"] as? String }, ["Die", "Window", "Plain"])

        let materials = try XCTUnwrap(json["materials"] as? [[String: Any]])
        XCTAssertEqual(materials.count, 4, "the stock one, brass, the paint, glass")
        let brassOut = try XCTUnwrap(materials[1]["pbrMetallicRoughness"] as? [String: Any])
        XCTAssertEqual(brassOut["baseColorFactor"] as? [Double], [0.8, 0.6, 0.2, 1])
        XCTAssertEqual(brassOut["metallicFactor"] as? Double, 1)
        XCTAssertEqual(brassOut["roughnessFactor"] as? Double, 0.3)
        XCTAssertNil(materials[1]["alphaMode"])
        XCTAssertEqual(materials[3]["alphaMode"] as? String, "BLEND", "see-through glass blends")

        let meshes = try XCTUnwrap(json["meshes"] as? [[String: Any]])
        let accessors = try XCTUnwrap(json["accessors"] as? [[String: Any]])
        let diePrimitives = try XCTUnwrap(meshes[0]["primitives"] as? [[String: Any]])
        XCTAssertEqual(diePrimitives.compactMap { $0["material"] as? Int }, [1, 2])
        let counts = try diePrimitives.map { primitive -> Int in
            let accessor = try XCTUnwrap(primitive["indices"] as? Int)
            return try XCTUnwrap(accessors[accessor]["count"] as? Int)
        }
        XCTAssertEqual(counts, [30, 6], "ten triangles in brass, the painted face's two")
        let shared = Set(diePrimitives.compactMap { ($0["attributes"] as? [String: Int])?["POSITION"] })
        XCTAssertEqual(shared.count, 1, "both primitives use the body's one vertex buffer")
        XCTAssertEqual((meshes[1]["primitives"] as? [[String: Any]])?.first?["material"] as? Int, 3)
        XCTAssertEqual((meshes[2]["primitives"] as? [[String: Any]])?.first?["material"] as? Int, 0)
    }

    func testGLBGlowBecomesEmissive() throws {
        var lamp = paint
        lamp.emission = 0.5
        let material = GLBExporter.material(lamp, name: "Lamp")
        XCTAssertEqual(material["emissiveFactor"] as? [Double], [0.5, 0, 0])
    }

    // MARK: - 3MF

    func testThreeMFOfAPlainDesignHasNamesButNoMaterials() {
        let xml = ThreeMFExporter.modelXML(bodies: [cube("Lid & <Base>")])
        XCTAssertTrue(xml.contains("name=\"Lid &amp; &lt;Base&gt;\""), "named, and escaped")
        XCTAssertFalse(xml.contains("basematerials"))
        XCTAssertFalse(xml.contains("pid="))
        XCTAssertFalse(xml.contains("p1="))
    }

    func testThreeMFWritesAGroupObjectDefaultsAndPerTrianglePaint() {
        let die = painting(cube("Die", material: brass), with: paint)
        let xml = ThreeMFExporter.modelXML(bodies: [die, cube("Plain", at: 5)])
        // Two objects, so the material group is resource 3 — defined first.
        let group = try? XCTUnwrap(xml.range(of: "<basematerials id=\"3\">"))
        let firstObject = try? XCTUnwrap(xml.range(of: "<object "))
        if let group, let firstObject { XCTAssertLessThan(group.lowerBound, firstObject.lowerBound) }
        XCTAssertTrue(xml.contains("displaycolor=\"#CC9933\""))
        XCTAssertTrue(xml.contains("displaycolor=\"#FF0000\""))
        XCTAssertTrue(xml.contains("<object id=\"1\" name=\"Die\" type=\"model\" pid=\"3\" pindex=\"0\">"))
        XCTAssertTrue(xml.contains("<object id=\"2\" name=\"Plain\" type=\"model\">"), "no material, no default")
        XCTAssertEqual(xml.components(separatedBy: " pid=\"3\" p1=\"1\"/>").count - 1, 2, "the painted face's two triangles")
        XCTAssertEqual(xml.components(separatedBy: "<triangle ").count - 1, 24)
    }

    func testThreeMFPaintOnABodyWithoutAMaterialDoesNotSpreadToItsOtherFaces() {
        let xml = ThreeMFExporter.modelXML(bodies: [painting(cube("Die"), with: paint)])
        XCTAssertTrue(xml.contains("<object id=\"1\" name=\"Die\" type=\"model\">"), "no object default")
        XCTAssertEqual(xml.components(separatedBy: " pid=\"2\" p1=\"0\"/>").count - 1, 2)
    }

    // MARK: - Renaming over the agent channel

    private func parseRename(_ args: [String: Any]) -> Result<AgentExecOp, AgentExecError> {
        AgentExec.parse(["op": "item.rename", "args": args])
    }

    func testRenameParsesAndTidiesTheName() {
        let id = UUID()
        XCTAssertEqual(try? parseRename(["id": id.uuidString, "name": "  Walls\n "]).get(),
                       .rename(id: id, name: "Walls"))
        guard case let .success(.rename(_, name)) = parseRename(["id": id.uuidString,
                                                                 "name": String(repeating: "x", count: 500)])
        else { return XCTFail("a long name is cut, not refused") }
        XCTAssertEqual(name.count, AgentExec.maxItemNameLength)
    }

    func testRenameRefusesABadIDOrAnEmptyName() {
        func code(_ args: [String: Any]) -> String? {
            if case let .failure(error) = parseRename(args) { return error.code }
            return nil
        }
        XCTAssertEqual(code(["id": "not-a-uuid", "name": "A"]), "bad_uuid")
        XCTAssertEqual(code(["name": "A"]), "bad_uuid")
        XCTAssertEqual(code(["id": UUID().uuidString, "name": " \t "]), "missing_name")
        XCTAssertEqual(code(["id": UUID().uuidString]), "missing_name")
    }
}
