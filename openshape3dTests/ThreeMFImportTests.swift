//
//  ThreeMFImportTests.swift
//  openshape3dTests
//
//  #137: 3MF comes back in — the app's own export (names, colours, Y-up as
//  modelled), a slicer-style Z-up file, and the parts of the format other
//  tools write: units, components and their transforms, colour groups per
//  triangle, objects kept in a second model part.
//

import XCTest
import simd
@testable import openshape3d

@MainActor
final class ThreeMFImportTests: XCTestCase {

    private func box(_ name: String, width: Double = 2, depth: Double = 2, height: Double = 2,
                     at translation: SIMD3<Double> = .zero, color: SIMD4<Double>? = nil) -> Body {
        var transform = Transform3D.identity
        transform.translation = translation
        var body = Body(name: name, transform: transform,
                        primitive: .box(width: width, depth: depth, height: height),
                        euclidMesh: .primitive(.box(width: width, depth: depth, height: height)), revision: 1)
        if let color { body.material = BodyMaterialSpec(baseColor: color, metallic: 0.2, roughness: 0.7) }
        return body
    }

    private func bounds(_ mesh: RenderMesh) -> (min: SIMD3<Float>, max: SIMD3<Float>) { mesh.localAABB }

    /// A 3MF package around hand-written model XML.
    private func package(_ model: String, extra: [(path: String, xml: String)] = []) -> Data {
        var zip = MinimalZipWriter()
        zip.addFile(path: "[Content_Types].xml", data: Data("<Types/>".utf8))
        zip.addFile(path: "3D/3dmodel.model", data: Data(model.utf8))
        for file in extra { zip.addFile(path: file.path, data: Data(file.xml.utf8)) }
        return zip.finish()
    }

    /// A unit tetrahedron's mesh element (volume 1/6), outward wound.
    private let tetra = """
    <mesh><vertices>
    <vertex x="0" y="0" z="0"/><vertex x="1" y="0" z="0"/><vertex x="0" y="1" z="0"/><vertex x="0" y="0" z="1"/>
    </vertices><triangles>
    <triangle v1="0" v2="2" v3="1"/><triangle v1="0" v2="1" v3="3"/>
    <triangle v1="1" v2="2" v3="3"/><triangle v1="0" v2="3" v3="2"/>
    </triangles></mesh>
    """

    private func model(unit: String = "millimeter", _ body: String) -> String {
        """
        <?xml version="1.0" encoding="UTF-8"?>
        <model unit="\(unit)" xmlns="http://schemas.microsoft.com/3dmanufacturing/core/2015/02" \
        xmlns:m="http://schemas.microsoft.com/3dmanufacturing/material/2015/02" \
        xmlns:p="http://schemas.microsoft.com/3dmanufacturing/production/2015/06">
        \(body)
        </model>
        """
    }

    // MARK: - The app's own files

    func testOwnExportComesBackWithNamesColoursAndPlacement() throws {
        let red = SIMD4<Double>(1, 0, 0, 1), teal = SIMD4<Double>(0, 0.5019607843137255, 0.5019607843137255, 1)
        let bodies = [box("Walls", width: 4, depth: 2, height: 6, color: red),
                      box("Roof & <Trim>", at: SIMD3(10, 3, -1), color: teal)]
        let data = ThreeMFExporter.threeMF(bodies: bodies)

        let probe = try MeshImportKit.probe(data: data, fileName: "house.3mf")
        XCTAssertEqual(probe.format, "3MF")
        XCTAssertTrue(probe.unitIsDeclared)
        XCTAssertEqual(probe.detectedScale, 1, "millimetres, as written")
        XCTAssertEqual(probe.parts.map(\.name), ["Walls", "Roof & <Trim>"], "names survive, XML escapes undone")
        XCTAssertEqual(probe.parts[0].material?.baseColor, red)
        XCTAssertEqual(probe.parts[1].material?.baseColor, teal)

        // Y-up as modelled: nothing turned, nothing moved.
        for (part, body) in zip(probe.parts, bodies) {
            let got = bounds(part.mesh)
            let local = body.render.localAABB
            let t = SIMD3<Float>(body.transform.translation)
            XCTAssertEqual(simd_distance(got.min, local.min + t), 0, accuracy: 1e-4)
            XCTAssertEqual(simd_distance(got.max, local.max + t), 0, accuracy: 1e-4)
            XCTAssertEqual(MeasureKit.bodyVolume(part.mesh), MeasureKit.bodyVolume(body.render), accuracy: 1e-3)
        }
    }

    func testPaintedFaceComesBackAsItsOwnPart() throws {
        var body = box("Block", color: SIMD4(0.2, 0.4, 0.6, 1))
        let mesh = body.render
        let a = SIMD3<Double>(mesh.positions[Int(mesh.indices[0])])
        let b = SIMD3<Double>(mesh.positions[Int(mesh.indices[1])])
        let c = SIMD3<Double>(mesh.positions[Int(mesh.indices[2])])
        let yellow = BodyMaterialSpec(baseColor: SIMD4(1, 1, 0, 1), metallic: 0, roughness: 0.5)
        body.faceMaterials = [FaceMaterial(point: (a + b + c) / 3, normal: simd_normalize(simd_cross(b - a, c - a)),
                                           material: yellow)]
        let parts = try MeshImportKit.parts(from: ThreeMFExporter.threeMF(bodies: [body]), fileName: "block.3mf")
        XCTAssertEqual(parts.count, 2, "the body's colour and the painted face")
        XCTAssertEqual(Set(parts.compactMap { $0.material?.baseColor }),
                       [SIMD4(0.2, 0.4, 0.6, 1), SIMD4(1, 1, 0, 1)])
        XCTAssertEqual(parts.reduce(0) { $0 + $1.mesh.triangleCount }, mesh.triangleCount)
        let painted = try XCTUnwrap(parts.first { $0.material?.baseColor == SIMD4(1, 1, 0, 1) })
        XCTAssertEqual(painted.mesh.triangleCount, 2, "one face of the box")
    }

    func testSlicerExportIsZUpAndComesBackStanding() throws {
        // 10 wide, 6 tall (Y), 4 deep, sitting on the ground.
        let body = box("Post", width: 10, depth: 4, height: 6, at: SIMD3(0, 3, 0))
        let parts = try MeshImportKit.parts(from: SlicerExport.threeMF(bodies: [body]), fileName: "post.3mf")
        let b = bounds(try XCTUnwrap(parts.first).mesh)
        XCTAssertEqual(b.max.y - b.min.y, 6, accuracy: 1e-4, "still 6 tall after the round trip through Z-up")
        XCTAssertEqual(b.max.x - b.min.x, 10, accuracy: 1e-4)
        XCTAssertEqual(b.max.z - b.min.z, 4, accuracy: 1e-4)
        XCTAssertEqual(b.min.y, 0, accuracy: 1e-4, "on the bed, which is the ground")
    }

    // MARK: - What other tools write

    func testStandardFileIsTurnedFromZUpAndScaledByItsUnit() throws {
        let data = package(model(unit: "inch", """
        <resources><object id="1" type="model">\(tetra)</object></resources>
        <build><item objectid="1"/></build>
        """))
        let probe = try MeshImportKit.probe(data: data, fileName: "tetra.3mf")
        XCTAssertEqual(probe.detectedScale, 25.4)
        let parts = try MeshImportKit.parts(from: data, fileName: "tetra.3mf")
        XCTAssertEqual(parts.map(\.name), ["tetra"], "a nameless single object takes the file's name")
        let b = bounds(parts[0].mesh)
        // The file's +Z (up) is the design's +Y; its +Y is the design's −Z.
        XCTAssertEqual(b.max.y, 25.4, accuracy: 1e-3)
        XCTAssertEqual(b.min.z, -25.4, accuracy: 1e-3)
        XCTAssertEqual(b.max.z, 0, accuracy: 1e-4)
        XCTAssertEqual(MeasureKit.bodyVolume(parts[0].mesh), pow(25.4, 3) / 6, accuracy: 1e-2,
                       "positive: the turn kept the winding outward")
        XCTAssertNil(parts[0].material)
    }

    func testComponentsAreFlattenedWithTheirTransformsAndMirrorsRewound() throws {
        // Object 2 = the tetrahedron moved +10 in x, and a mirrored copy at −10.
        let data = package(model("""
        <resources>
        <object id="1" type="model" name="Tooth">\(tetra)</object>
        <object id="2" type="model" name="Pair"><components>
        <component objectid="1" transform="1 0 0 0 1 0 0 0 1 10 0 0"/>
        <component objectid="1" transform="-1 0 0 0 1 0 0 0 1 -10 0 0"/>
        </components></object>
        </resources>
        <build><item objectid="2" transform="2 0 0 0 2 0 0 0 2 0 0 5"/></build>
        """))
        let parts = try ThreeMFImporter.parts(from: data).parts
        XCTAssertEqual(parts.count, 1)
        XCTAssertEqual(parts[0].name, "Pair")
        XCTAssertEqual(parts[0].mesh.triangleCount, 8)
        let b = bounds(parts[0].mesh)
        XCTAssertEqual(b.max.x, 22, accuracy: 1e-4, "(10 + 1) × 2")
        XCTAssertEqual(b.min.x, -22, accuracy: 1e-4)
        XCTAssertEqual(b.min.y, 5, accuracy: 1e-4, "the item's +5 in z is up")
        XCTAssertEqual(MeasureKit.bodyVolume(parts[0].mesh), 2 * 8.0 / 6, accuracy: 1e-4,
                       "both copies count positive: the mirrored one was rewound")
    }

    func testColourGroupsSplitAnObjectByTriangle() throws {
        let data = package(model("""
        <resources>
        <m:colorgroup id="7"><m:color color="#FF0000"/><m:color color="#0000FF80"/></m:colorgroup>
        <object id="1" type="model" name="Die" pid="7" pindex="0"><mesh><vertices>
        <vertex x="0" y="0" z="0"/><vertex x="1" y="0" z="0"/><vertex x="0" y="1" z="0"/><vertex x="0" y="0" z="1"/>
        </vertices><triangles>
        <triangle v1="0" v2="2" v3="1"/><triangle v1="0" v2="1" v3="3" pid="7" p1="1"/>
        <triangle v1="1" v2="2" v3="3" p1="1"/><triangle v1="0" v2="3" v3="2"/>
        </triangles></mesh></object>
        </resources>
        <build><item objectid="1"/></build>
        """))
        let parts = try ThreeMFImporter.parts(from: data).parts
        XCTAssertEqual(parts.count, 2)
        XCTAssertEqual(parts.map(\.name), ["Die", "Die 2"])
        XCTAssertEqual(parts[0].material?.baseColor, SIMD4(1, 0, 0, 1))
        XCTAssertEqual(parts[0].mesh.triangleCount, 2)
        let blue = try XCTUnwrap(parts[1].material?.baseColor)
        XCTAssertEqual(blue.z, 1)
        XCTAssertEqual(blue.w, 128.0 / 255, accuracy: 1e-9, "#RRGGBBAA")
        XCTAssertEqual(parts[1].mesh.triangleCount, 2, "pid+p1, and p1 alone against the object's group")
    }

    func testObjectsInASecondModelPartAreFollowed() throws {
        // The Production extension layout slicer projects use.
        let root = model("""
        <resources><object id="3" type="model" name="Plate"><components>
        <component p:path="/3D/Objects/object_1.model" objectid="1"/>
        </components></object></resources>
        <build><item objectid="3"/></build>
        """)
        let child = model("<resources><object id=\"1\" type=\"model\">\(tetra)</object></resources>")
        let data = package(root, extra: [("3D/Objects/object_1.model", child)])
        let parts = try ThreeMFImporter.parts(from: data).parts
        XCTAssertEqual(parts.count, 1)
        XCTAssertEqual(parts[0].name, "Plate")
        XCTAssertEqual(parts[0].mesh.triangleCount, 4)
    }

    func testAComponentCycleEndsInsteadOfRecursingForever() throws {
        let data = package(model("""
        <resources>
        <object id="1" type="model">\(tetra)</object>
        <object id="2" type="model"><components><component objectid="1"/><component objectid="2"/></components></object>
        </resources>
        <build><item objectid="2"/></build>
        """))
        let parts = try ThreeMFImporter.parts(from: data).parts
        XCTAssertFalse(parts.isEmpty)
        XCTAssertLessThanOrEqual(parts[0].mesh.triangleCount, 4 * 16)
    }

    // MARK: - Refusals

    func testNotAZipAndAZipWithoutAModelAreRefusedClearly() {
        XCTAssertThrowsError(try ThreeMFImporter.parts(from: Data("not a zip".utf8))) {
            guard case .malformed = $0 as? MeshImportError else { return XCTFail("\($0)") }
        }
        var zip = MinimalZipWriter()
        zip.addFile(path: "readme.txt", data: Data("hello".utf8))
        XCTAssertThrowsError(try ThreeMFImporter.parts(from: zip.finish())) {
            XCTAssertEqual($0 as? MeshImportError, .malformed("3mf: no 3D model part in the archive"))
        }
    }

    func testAModelWithNoTrianglesIsEmptyNotACrash() {
        let data = package(model("""
        <resources><object id="1" type="model"><mesh><vertices><vertex x="0" y="0" z="0"/></vertices>
        <triangles><triangle v1="0" v2="5" v3="9"/></triangles></mesh></object></resources>
        <build><item objectid="1"/></build>
        """))
        XCTAssertThrowsError(try ThreeMFImporter.parts(from: data)) {
            XCTAssertEqual($0 as? MeshImportError, .empty)
        }
    }

    // MARK: - The scanner

    func testScannerSkipsCommentsAndCDATAAndDropsPrefixes() {
        let xml = """
        <?xml version="1.0"?><!-- <fake a="1"/> --><m:group id = '7' p:path="/a&amp;b&#65;&#x42;"><![CDATA[<nope/>]]>text &lt;here&gt;</m:group><leaf/>
        """
        var scanner = XMLScanner(Array(xml.utf8))
        let open = scanner.next()
        XCTAssertEqual(open?.name, "group")
        XCTAssertEqual(open?["id"], "7")
        XCTAssertEqual(open?["path"], "/a&bAB")
        XCTAssertEqual(open?.selfClosing, false)
        let close = scanner.next()
        XCTAssertEqual(close?.name, "group")
        XCTAssertEqual(close?.closing, true)
        let leaf = scanner.next()
        XCTAssertEqual(leaf?.name, "leaf")
        XCTAssertEqual(leaf?.selfClosing, true)
        XCTAssertNil(scanner.next())

        var texts = XMLScanner(Array("<a>one &amp; two</a>".utf8))
        _ = texts.next()
        XCTAssertEqual(texts.text(), "one & two")
    }

    func testTransformReadsRowVectorsAndRefusesNonsense() {
        let t = ThreeMFImporter.transform("1 0 0 0 1 0 0 0 1 3 4 5")
        let p = t * SIMD4<Double>(1, 1, 1, 1)
        XCTAssertEqual(SIMD3(p.x, p.y, p.z), SIMD3(4, 5, 6))
        // A quarter turn about z: x → y.
        let r = ThreeMFImporter.transform("0 1 0 -1 0 0 0 0 1 0 0 0") * SIMD4<Double>(1, 0, 0, 1)
        XCTAssertEqual(SIMD3(r.x, r.y, r.z), SIMD3(0, 1, 0))
        XCTAssertEqual(ThreeMFImporter.transform("1 2 3"), matrix_identity_double4x4)
        XCTAssertEqual(ThreeMFImporter.transform(nil), matrix_identity_double4x4)
    }
}
