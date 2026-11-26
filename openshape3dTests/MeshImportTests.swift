//
//  MeshImportTests.swift
//  openshape3dTests
//
//  Textured-mesh import: glTF/GLB (round trip through our own exporter plus
//  a hand-built textured file), OBJ with MTL and a texture inside a zip, USDZ
//  through Model I/O, and the MeshBlob v2 persistence that keeps texcoords.
//

import Compression
import ModelIO
import XCTest
import simd
import Euclid
@testable import openshape3d

final class MeshImportTests: XCTestCase {

    // 1×1 PNG, the smallest valid image a texture slot can hold.
    private let tinyPNG = Data(base64Encoded:
        "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8DwHwAFBQIAX8jx0gAAAABJRU5ErkJggg==")!

    private func box(_ w: Double, _ h: Double, _ d: Double, name: String = "Box") -> Body {
        Body(name: name,
             euclidMesh: Euclid.Mesh.cube(center: Vector(w / 2, h / 2, d / 2), size: Vector(w, h, d)),
             revision: 1)
    }

    private func extents(_ mesh: RenderMesh) -> SIMD3<Float> {
        let aabb = mesh.localAABB
        return aabb.max - aabb.min
    }

    // MARK: glTF / GLB

    func testGLBRoundTripKeepsGeometry() throws {
        let body = box(10, 20, 30, name: "Block")
        let glb = GLBExporter.glb(bodies: [body])
        let parts = try MeshImportKit.parts(from: glb, fileName: "block.glb", unitScale: 1)
        XCTAssertEqual(parts.count, 1)
        XCTAssertEqual(parts[0].name, "Block")
        XCTAssertEqual(parts[0].mesh.indices.count, body.render.indices.count)
        XCTAssertEqual(extents(parts[0].mesh), SIMD3(10, 20, 30), accuracy: 1e-4)
        XCTAssertNil(parts[0].mesh.texcoords)
        XCTAssertEqual(parts[0].mesh.normals.count, parts[0].mesh.positions.count)
    }

    func testGLBDefaultScaleIsMetresToMillimetres() throws {
        let glb = GLBExporter.glb(bodies: [box(0.01, 0.02, 0.03)])
        let parts = try MeshImportKit.parts(from: glb, fileName: "m.glb")
        XCTAssertEqual(extents(parts[0].mesh), SIMD3(10, 20, 30), accuracy: 1e-3)
    }

    /// A single textured quad built by hand: TEXCOORD_0, an embedded PNG, a
    /// base colour factor, and a node with translation + scale.
    private func texturedQuadGLTF(binary: Bool) throws -> Data {
        var bin = Data()
        func append<T>(_ values: [T]) -> (offset: Int, length: Int) {
            while bin.count % 4 != 0 { bin.append(0) }
            let offset = bin.count
            values.withUnsafeBufferPointer { bin.append(Data(buffer: $0)) }
            return (offset, bin.count - offset)
        }
        let positions: [SIMD3<Float>] = [SIMD3(0, 0, 0), SIMD3(1, 0, 0), SIMD3(1, 1, 0), SIMD3(0, 1, 0)]
        // SIMD3<Float> is 16 bytes in memory; pack as tight floats.
        let p = append(positions.flatMap { [$0.x, $0.y, $0.z] })
        let n = append([Float](repeating: 0, count: 12).enumerated().map { $0.offset % 3 == 2 ? Float(1) : 0 })
        let t = append([Float](arrayLiteral: 0, 0, 1, 0, 1, 1, 0, 1))
        let i = append([UInt16](arrayLiteral: 0, 1, 2, 0, 2, 3))
        let img = append([UInt8](tinyPNG))
        let json: [String: Any] = [
            "asset": ["version": "2.0"],
            "scene": 0,
            "scenes": [["nodes": [0]]],
            "nodes": [["name": "Quad", "mesh": 0, "translation": [1, 2, 3], "scale": [2, 2, 2]]],
            "meshes": [["primitives": [[
                "attributes": ["POSITION": 0, "NORMAL": 1, "TEXCOORD_0": 2],
                "indices": 3, "material": 0]]]],
            "materials": [["pbrMetallicRoughness": [
                "baseColorFactor": [1, 0, 0, 1], "baseColorTexture": ["index": 0],
                "metallicFactor": 0.25, "roughnessFactor": 0.75]]],
            "textures": [["source": 0]],
            "images": [["bufferView": 4, "mimeType": "image/png"]],
            "buffers": [binary ? ["byteLength": bin.count]
                               : ["byteLength": bin.count, "uri": "data:application/octet-stream;base64," + bin.base64EncodedString()]],
            "bufferViews": [
                ["buffer": 0, "byteOffset": p.offset, "byteLength": p.length],
                ["buffer": 0, "byteOffset": n.offset, "byteLength": n.length],
                ["buffer": 0, "byteOffset": t.offset, "byteLength": t.length],
                ["buffer": 0, "byteOffset": i.offset, "byteLength": i.length],
                ["buffer": 0, "byteOffset": img.offset, "byteLength": img.length],
            ],
            "accessors": [
                ["bufferView": 0, "componentType": 5126, "count": 4, "type": "VEC3"],
                ["bufferView": 1, "componentType": 5126, "count": 4, "type": "VEC3"],
                ["bufferView": 2, "componentType": 5126, "count": 4, "type": "VEC2"],
                ["bufferView": 3, "componentType": 5123, "count": 6, "type": "SCALAR"],
            ],
        ]
        var jsonData = try JSONSerialization.data(withJSONObject: json)
        guard binary else { return jsonData }
        while jsonData.count % 4 != 0 { jsonData.append(0x20) }
        while bin.count % 4 != 0 { bin.append(0) }
        var out = Data()
        func u32(_ v: UInt32) { withUnsafeBytes(of: v.littleEndian) { out.append(contentsOf: $0) } }
        u32(0x46546C67); u32(2); u32(UInt32(12 + 8 + jsonData.count + 8 + bin.count))
        u32(UInt32(jsonData.count)); u32(0x4E4F534A); out.append(jsonData)
        u32(UInt32(bin.count)); u32(0x004E4942); out.append(bin)
        return out
    }

    func testTexturedGLBCarriesUVsImageAndMaterialThroughNodeTransform() throws {
        let parts = try MeshImportKit.parts(from: try texturedQuadGLTF(binary: true), fileName: "quad.glb", unitScale: 1)
        XCTAssertEqual(parts.count, 1)
        let part = parts[0]
        XCTAssertEqual(part.name, "Quad")
        XCTAssertEqual(part.mesh.texcoords?.count, 4)
        XCTAssertEqual(part.mesh.texcoords?[2], SIMD2(1, 1))
        XCTAssertEqual(part.material?.baseColorTexture, tinyPNG)
        XCTAssertEqual(part.material?.baseColor.x ?? 0, 1, accuracy: 1e-9)
        XCTAssertEqual(part.material?.baseColor.y ?? 1, 0, accuracy: 1e-9)
        XCTAssertEqual(part.material?.metallic ?? 0, 0.25, accuracy: 1e-9)
        XCTAssertEqual(part.material?.roughness ?? 0, 0.75, accuracy: 1e-9)
        // (1,1,0) scaled ×2 then moved by (1,2,3) → (3,4,3)
        XCTAssertEqual(part.mesh.positions[2], SIMD3(3, 4, 3), accuracy: 1e-5)
        XCTAssertEqual(part.mesh.normals[0], SIMD3(0, 0, 1), accuracy: 1e-5)
    }

    func testGLTFJSONWithDataURIBuffer() throws {
        let parts = try MeshImportKit.parts(from: try texturedQuadGLTF(binary: false), fileName: "quad.gltf", unitScale: 1)
        XCTAssertEqual(parts.count, 1)
        XCTAssertEqual(parts[0].mesh.indices, [0, 1, 2, 0, 2, 3])
        XCTAssertEqual(parts[0].material?.baseColorTexture, tinyPNG)
    }

    func testGLBRejectsGarbage() {
        XCTAssertThrowsError(try MeshImportKit.parts(from: Data("nope".utf8), fileName: "x.glb"))
        XCTAssertThrowsError(try MeshImportKit.parts(from: Data(), fileName: "x.bin"))
    }

    // MARK: OBJ + MTL + texture, inside a zip

    private let objText = """
    mtllib cube.mtl
    o Cube
    v 0 0 0
    v 1 0 0
    v 1 1 0
    v 0 1 0
    vt 0 0
    vt 1 0
    vt 1 1
    vt 0 1
    usemtl Painted
    f 1/1 2/2 3/3 4/4
    """
    private let mtlText = """
    newmtl Painted
    Kd 0.2 0.4 0.6
    map_Kd -s 1 1 1 textures/paint.PNG
    """

    /// A zip built by hand, with one deflated entry, so the reader's inflate
    /// path is exercised too.
    private func zip(_ entries: [(String, Data, deflate: Bool)]) -> Data {
        var out = Data(); var central = Data()
        func u16(_ v: Int, into d: inout Data) { withUnsafeBytes(of: UInt16(v).littleEndian) { d.append(contentsOf: $0) } }
        func u32(_ v: Int, into d: inout Data) { withUnsafeBytes(of: UInt32(v).littleEndian) { d.append(contentsOf: $0) } }
        for (name, bytes, deflate) in entries {
            let payload: Data
            if deflate {
                var buf = Data(count: bytes.count + 64)
                let n = buf.withUnsafeMutableBytes { dst in
                    bytes.withUnsafeBytes { src in
                        compression_encode_buffer(dst.bindMemory(to: UInt8.self).baseAddress!, bytes.count + 64,
                                                  src.bindMemory(to: UInt8.self).baseAddress!, bytes.count,
                                                  nil, COMPRESSION_ZLIB)
                    }
                }
                buf.count = n; payload = buf
            } else { payload = bytes }
            let offset = out.count
            let nameData = Data(name.utf8)
            u32(0x04034b50, into: &out); u16(20, into: &out); u16(0, into: &out); u16(deflate ? 8 : 0, into: &out)
            u16(0, into: &out); u16(0, into: &out); u32(0, into: &out)
            u32(payload.count, into: &out); u32(bytes.count, into: &out)
            u16(nameData.count, into: &out); u16(0, into: &out); out.append(nameData); out.append(payload)
            u32(0x02014b50, into: &central); u16(20, into: &central); u16(20, into: &central); u16(0, into: &central)
            u16(deflate ? 8 : 0, into: &central); u16(0, into: &central); u16(0, into: &central); u32(0, into: &central)
            u32(payload.count, into: &central); u32(bytes.count, into: &central)
            u16(nameData.count, into: &central); u16(0, into: &central); u16(0, into: &central)
            u16(0, into: &central); u16(0, into: &central); u32(0, into: &central); u32(offset, into: &central)
            central.append(nameData)
        }
        let centralOffset = out.count
        out.append(central)
        u32(0x06054b50, into: &out); u16(0, into: &out); u16(0, into: &out)
        u16(entries.count, into: &out); u16(entries.count, into: &out)
        u32(central.count, into: &out); u32(centralOffset, into: &out); u16(0, into: &out)
        return out
    }

    func testZippedOBJWithMTLAndTexture() throws {
        let archive = zip([
            ("model/cube.obj", Data(objText.utf8), deflate: true),
            ("model/cube.mtl", Data(mtlText.utf8), deflate: false),
            ("model/textures/paint.png", tinyPNG, deflate: false),
        ])
        let parts = try MeshImportKit.parts(from: archive, fileName: "download.zip")
        XCTAssertEqual(parts.count, 1)
        let part = parts[0]
        XCTAssertEqual(part.name, "Cube")
        XCTAssertEqual(part.mesh.indices.count, 6, "quad fan-triangulated")
        XCTAssertEqual(part.mesh.texcoords?.count, 4)
        // OBJ's bottom-left origin becomes the renderer's top-left.
        XCTAssertEqual(part.mesh.texcoords?[0], SIMD2(0, 1))
        XCTAssertEqual(part.mesh.texcoords?[2], SIMD2(1, 0))
        XCTAssertEqual(part.material?.baseColorTexture, tinyPNG, "found case-insensitively by path")
        XCTAssertEqual(part.material?.baseColor.z ?? 0, 0.6, accuracy: 1e-9)
        XCTAssertEqual(part.mesh.normals[0], SIMD3(0, 0, 1), accuracy: 1e-5, "computed from winding")
    }

    func testOBJWithoutMaterialKeepsUVsButNoTexture() throws {
        let parts = try MeshImportKit.parts(from: Data(objText.utf8), fileName: "cube.obj")
        XCTAssertEqual(parts.count, 1)
        XCTAssertEqual(parts[0].mesh.texcoords?.count, 4)
        XCTAssertNil(parts[0].material?.baseColorTexture)
    }

    func testZipWithoutModelIsRefused() {
        let archive = zip([("readme.txt", Data("hi".utf8), deflate: false)])
        XCTAssertThrowsError(try MeshImportKit.parts(from: archive, fileName: "x.zip")) { error in
            XCTAssertEqual(error as? MeshImportError, .unsupportedFormat("zip without a .glb, .gltf, .usdz, .obj, .blend or .stl inside"))
        }
    }

    // MARK: USDZ

    /// A textured quad in USD's text form. Export is unsupported on the
    /// simulator, so import is checked against a hand-written layer instead.
    private let quadUSDA = """
    #usda 1.0
    (
        defaultPrim = "Quad"
        metersPerUnit = 0.001
        upAxis = "Y"
    )
    def Xform "Quad" {
        double3 xformOp:translate = (1, 2, 3)
        uniform token[] xformOpOrder = ["xformOp:translate"]
        def Mesh "Face" {
            int[] faceVertexCounts = [4]
            int[] faceVertexIndices = [0, 1, 2, 3]
            point3f[] points = [(0, 0, 0), (10, 0, 0), (10, 20, 0), (0, 20, 0)]
            normal3f[] normals = [(0, 0, 1), (0, 0, 1), (0, 0, 1), (0, 0, 1)]
            texCoord2f[] primvars:st = [(0, 0), (1, 0), (1, 1), (0, 1)] (interpolation = "vertex")
        }
    }
    """

    func testUSDATextLayerImportsThroughModelIO() throws {
        try XCTSkipUnless(MDLAsset.canImportFileExtension("usda"), "Model I/O has no USD reader here")
        let parts = try MeshImportKit.parts(from: Data(quadUSDA.utf8), fileName: "quad.usda")
        XCTAssertEqual(parts.count, 1)
        let part = parts[0]
        XCTAssertEqual(part.mesh.indices.count, 6, "quad → two triangles")
        // metersPerUnit 0.001 → already millimetres; the Xform translate applies.
        XCTAssertEqual(extents(part.mesh), SIMD3(10, 20, 0), accuracy: 1e-3)
        XCTAssertEqual(part.mesh.localAABB.min, SIMD3(1, 2, 3), accuracy: 1e-3)
        XCTAssertEqual(part.mesh.texcoords?.count, 4)
        XCTAssertEqual(part.mesh.texcoords?[0], SIMD2(0, 1), "st origin bottom-left → top-left")
    }

    func testUSDZArchiveImportsThroughModelIO() throws {
        try XCTSkipUnless(MDLAsset.canImportFileExtension("usdz"), "Model I/O has no USD reader here")
        let archive = zip([("quad.usda", Data(quadUSDA.utf8), deflate: false)])
        let parts = try MeshImportKit.parts(from: archive, fileName: "quad.usdz")
        XCTAssertEqual(parts.count, 1)
        XCTAssertEqual(extents(parts[0].mesh), SIMD3(10, 20, 0), accuracy: 1e-3)
    }

    func testUSDUnitScaleReadsMetersPerUnitFromTextLayers() {
        XCTAssertEqual(USDImporter.unitScale(of: Data("#usda 1.0\n(\n  metersPerUnit = 1\n)\n".utf8), ext: "usda"), 1000, accuracy: 1e-9)
        XCTAssertEqual(USDImporter.unitScale(of: Data("#usda 1.0\n".utf8), ext: "usda"), 10, accuracy: 1e-9, "USD default is centimetres")
    }

    // MARK: Persistence

    func testMeshBlobV2RoundTripsTexcoordsAndStillReadsV1() throws {
        var mesh = RenderMesh(positions: [SIMD3(0, 0, 0), SIMD3(1, 0, 0), SIMD3(0, 1, 0)],
                              normals: [SIMD3(0, 0, 1), SIMD3(0, 0, 1), SIMD3(0, 0, 1)],
                              indices: [0, 1, 2])
        let plain = try MeshBlob.decode(MeshBlob.encode(mesh))
        XCTAssertNil(plain.texcoords)
        mesh.texcoords = [SIMD2(0, 0), SIMD2(1, 0), SIMD2(0, 1)]
        let textured = try MeshBlob.decode(MeshBlob.encode(mesh))
        XCTAssertEqual(textured.texcoords, mesh.texcoords)
        XCTAssertEqual(textured, mesh)
    }
}

private func XCTAssertEqual(_ a: SIMD3<Float>, _ b: SIMD3<Float>, accuracy: Float, _ message: String = "",
                            file: StaticString = #filePath, line: UInt = #line) {
    XCTAssertEqual(a.x, b.x, accuracy: accuracy, message, file: file, line: line)
    XCTAssertEqual(a.y, b.y, accuracy: accuracy, message, file: file, line: line)
    XCTAssertEqual(a.z, b.z, accuracy: accuracy, message, file: file, line: line)
}
