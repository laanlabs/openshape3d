//
//  USDZExportTests.swift
//  openshape3dTests
//
//  #137: USDZ is written directly (a text layer in an aligned zip), so it
//  exists on every platform and carries names, materials and the unit.
//  The package is also read back through Model I/O — Apple's own USD
//  reader, the one behind Quick Look — wherever that is available.
//

import XCTest
import ModelIO
import simd
@testable import openshape3d

@MainActor
final class USDZExportTests: XCTestCase {

    private func box(_ name: String, size: Double = 2, at translation: SIMD3<Double> = .zero,
                     color: SIMD4<Double>? = nil, metallic: Double = 0.2, roughness: Double = 0.7) -> Body {
        var transform = Transform3D.identity
        transform.translation = translation
        var body = Body(name: name, transform: transform,
                        primitive: .box(width: size, depth: size, height: size),
                        euclidMesh: .primitive(.box(width: size, depth: size, height: size)), revision: 1)
        if let color { body.material = BodyMaterialSpec(baseColor: color, metallic: metallic, roughness: roughness) }
        return body
    }

    private func painted(_ body: Body, _ color: SIMD4<Double>) -> Body {
        var body = body
        let mesh = body.render
        let a = SIMD3<Double>(mesh.positions[Int(mesh.indices[0])])
        let b = SIMD3<Double>(mesh.positions[Int(mesh.indices[1])])
        let c = SIMD3<Double>(mesh.positions[Int(mesh.indices[2])])
        body.faceMaterials = [FaceMaterial(point: (a + b + c) / 3, normal: simd_normalize(simd_cross(b - a, c - a)),
                                           material: BodyMaterialSpec(baseColor: color, metallic: 0, roughness: 0.5))]
        return body
    }

    func testAvailableEverywhereAndEmptyDesignsGiveNothing() {
        XCTAssertTrue(USDZExporter.isSupported, "no longer depends on Model I/O's writer")
        XCTAssertNil(USDZExporter.usdz(bodies: []))
        XCTAssertNotNil(USDZExporter.usdz(bodies: [box("Box")]))
    }

    func testPackageIsAStoredZipWithTheLayerFirstOnA64ByteBoundary() throws {
        for name in ["B", "Body with a longer name"] {
            let data = try XCTUnwrap(USDZExporter.usdz(bodies: [box(name)]))
            let bytes = [UInt8](data)
            XCTAssertEqual(Array(bytes[0..<4]), [0x50, 0x4B, 0x03, 0x04], "local file header first")
            XCTAssertEqual(Int(bytes[8]) | Int(bytes[9]) << 8, 0, "stored, not deflated")
            let nameLength = Int(bytes[26]) | Int(bytes[27]) << 8
            let extraLength = Int(bytes[28]) | Int(bytes[29]) << 8
            XCTAssertEqual(String(decoding: bytes[30..<30 + nameLength], as: UTF8.self), USDZExporter.layerName)
            let dataStart = 30 + nameLength + extraLength
            XCTAssertEqual(dataStart % 64, 0, "USDZ: file data starts on a 64-byte boundary")
            XCTAssertEqual(String(decoding: bytes[dataStart..<dataStart + 9], as: UTF8.self), "#usda 1.0")

            // The app's own zip reader still finds the layer past the padding.
            let entries = try ZipReader.entries(in: data)
            XCTAssertEqual(entries.keys.sorted(), [USDZExporter.layerName])
            XCTAssertEqual(entries[USDZExporter.layerName].map { String(decoding: $0, as: UTF8.self) },
                           USDZExporter.usda(bodies: [box(name)]))
        }
    }

    func testAlignedZipEntriesKeepTheirBytesWhateverTheOffset() throws {
        // Every remainder: names of growing length shift the header each time.
        for length in 1...70 {
            var zip = MinimalZipWriter()
            zip.addFile(path: String(repeating: "a", count: length), data: Data([1, 2, 3]), alignment: 64)
            zip.addFile(path: "second", data: Data([4, 5]), alignment: 64)
            let entries = try ZipReader.entries(in: zip.finish())
            XCTAssertEqual(entries[String(repeating: "a", count: length)], Data([1, 2, 3]))
            XCTAssertEqual(entries["second"], Data([4, 5]))
        }
    }

    func testLayerCarriesUnitNamesAndMaterials() throws {
        let layer = try XCTUnwrap(USDZExporter.usda(bodies: [
            box("Walls", color: SIMD4(1, 0.5, 0.25, 1), metallic: 1, roughness: 0.25),
            box("2nd \"Roof\"", at: SIMD3(5, 0, 0)),
        ]))
        XCTAssertTrue(layer.hasPrefix("#usda 1.0\n"))
        XCTAssertTrue(layer.contains("metersPerUnit = 0.001"), "millimetres, so AR shows true size")
        XCTAssertTrue(layer.contains("upAxis = \"Y\""))
        XCTAssertTrue(layer.contains("def Mesh \"Walls\""))
        XCTAssertTrue(layer.contains("def Mesh \"_2nd__Roof_\""), "a prim name is an identifier")
        XCTAssertTrue(layer.contains("displayName = \"2nd \\\"Roof\\\"\""), "the exact name rides along, escaped")
        XCTAssertTrue(layer.contains("color3f inputs:diffuseColor = (1, 0.5, 0.25)"))
        XCTAssertTrue(layer.contains("float inputs:metallic = 1"))
        XCTAssertTrue(layer.contains("float inputs:roughness = 0.25"))
        XCTAssertEqual(layer.components(separatedBy: "def Material ").count - 1, 2, "the colour and the default look")
        XCTAssertEqual(layer.components(separatedBy: "rel material:binding").count - 1, 2)
        XCTAssertFalse(layer.contains("nan"))
        XCTAssertFalse(layer.contains("inf,") || layer.contains("inf)"), "no infinite number")
    }

    func testPaintedFaceBecomesItsOwnMeshWithItsOwnMaterial() throws {
        let body = painted(box("Block", color: SIMD4(0.2, 0.4, 0.6, 1)), SIMD4(1, 1, 0, 0.5))
        let layer = try XCTUnwrap(USDZExporter.usda(bodies: [body]))
        XCTAssertEqual(layer.components(separatedBy: "def Mesh ").count - 1, 2)
        XCTAssertEqual(layer.components(separatedBy: "def Material ").count - 1, 2)
        XCTAssertTrue(layer.contains("float inputs:opacity = 0.5"), "a see-through paint keeps its opacity")
        // Two triangles in the painted mesh, the other ten in the body's.
        let counts = layer.components(separatedBy: "int[] faceVertexCounts = [").dropFirst()
            .map { $0.prefix { $0 != "]" }.split(separator: ",").count }
        XCTAssertEqual(counts.sorted(), [2, 10])
    }

    func testBodiesSharingANameGetDistinctPrims() throws {
        let layer = try XCTUnwrap(USDZExporter.usda(bodies: [box("Extrude"), box("Extrude", at: SIMD3(4, 0, 0))]))
        XCTAssertTrue(layer.contains("def Mesh \"Extrude\""))
        XCTAssertTrue(layer.contains("def Mesh \"Extrude_2\""))
    }

    func testIdentifiersAndStrings() {
        var used: Set<String> = []
        XCTAssertEqual(USDZExporter.uniqueIdentifier("Gear 12 (steel)", used: &used), "Gear_12__steel_")
        XCTAssertEqual(USDZExporter.uniqueIdentifier("9lives", used: &used), "_9lives")
        XCTAssertEqual(USDZExporter.uniqueIdentifier("", used: &used), "Body")
        XCTAssertEqual(USDZExporter.uniqueIdentifier("Zahnrad größe", used: &used), "Zahnrad_gr__e")
        XCTAssertEqual(USDZExporter.uniqueIdentifier("Body", used: &used), "Body_2")
        XCTAssertEqual(USDZExporter.quoted("a\"b\\c\nd"), "\"a\\\"b\\\\c\\nd\"")
    }

    /// Model I/O (the USD reader Quick Look uses) opens the package and finds
    /// the same geometry, placement, unit and colours.
    func testPackageReadsBackThroughModelIO() throws {
        try XCTSkipUnless(MDLAsset.canImportFileExtension("usdz"), "Model I/O has no USD reader here")
        let bodies = [box("Walls", size: 4, color: SIMD4(1, 0, 0, 1)),
                      box("Roof", size: 2, at: SIMD3(10, 3, -1), color: SIMD4(0, 0, 1, 1))]
        let data = try XCTUnwrap(USDZExporter.usdz(bodies: bodies))

        let probe = try MeshImportKit.probe(data: data, fileName: "house.usdz")
        XCTAssertEqual(probe.detectedScale, 1, accuracy: 1e-9, "metersPerUnit 0.001 is millimetres")
        XCTAssertEqual(probe.parts.count, 2)
        for body in bodies {
            let part = try XCTUnwrap(probe.parts.first { $0.name == body.name }, "\(probe.parts.map(\.name))")
            XCTAssertEqual(part.mesh.triangleCount, body.render.triangleCount)
            let got = part.mesh.localAABB, local = body.render.localAABB
            let t = SIMD3<Float>(body.transform.translation)
            XCTAssertEqual(simd_distance(got.min, local.min + t), 0, accuracy: 1e-4)
            XCTAssertEqual(simd_distance(got.max, local.max + t), 0, accuracy: 1e-4)
            XCTAssertEqual(MeasureKit.bodyVolume(part.mesh), MeasureKit.bodyVolume(body.render), accuracy: 1e-3)
            let color = try XCTUnwrap(part.material?.baseColor)
            let expected = try XCTUnwrap(body.material?.baseColor)
            XCTAssertEqual(simd_distance(SIMD3(color.x, color.y, color.z), SIMD3(expected.x, expected.y, expected.z)),
                           0, accuracy: 1e-3, "the colour came through UsdPreviewSurface")
        }
    }
}
