//
//  BlendImportTests.swift
//  openshape3dTests
//
//  The .blend reader is driven by the file's own DNA catalogue, so the test
//  writes a tiny .blend from scratch — header, an Object, a Mesh with
//  MVert/MPoly/MLoop/MLoopUV blocks, a Material with a packed image, and a
//  DNA1 block describing exactly those structs — and checks what comes out:
//  Z-up metres → Y-up millimetres, one part per material slot, UVs flipped,
//  the packed image on the material, and the gzip path.
//

import Compression
import XCTest
import simd
@testable import openshape3d

final class BlendImportTests: XCTestCase {

    // MARK: - A .blend writer just big enough for the reader

    private struct DNA {
        struct S { let name: String; let size: Int; let fields: [(type: String, name: String)] }
        var types: [(String, Int)] = [("char", 1), ("short", 2), ("int", 4), ("float", 4), ("void", 0)]
        var structs: [S] = []
        mutating func add(_ s: S) { structs.append(s); types.append((s.name, s.size)) }
        func typeIndex(_ n: String) -> Int { types.firstIndex { $0.0 == n }! }
        func structIndex(_ n: String) -> Int { structs.firstIndex { $0.name == n }! }
    }

    private func le32(_ v: Int) -> [UInt8] { withUnsafeBytes(of: Int32(v).littleEndian) { Array($0) } }
    private func le16(_ v: Int) -> [UInt8] { withUnsafeBytes(of: Int16(v).littleEndian) { Array($0) } }
    private func le64(_ v: UInt64) -> [UInt8] { withUnsafeBytes(of: v.littleEndian) { Array($0) } }
    private func f32(_ v: Float) -> [UInt8] { withUnsafeBytes(of: v.bitPattern.littleEndian) { Array($0) } }
    private func padded(_ s: String, _ n: Int) -> [UInt8] { Array(s.utf8.prefix(n - 1)) + [UInt8](repeating: 0, count: max(n - s.utf8.count, 1)) }

    private func dnaBlock(_ dna: DNA) -> [UInt8] {
        var names: [String] = []
        for s in dna.structs { for f in s.fields where !names.contains(f.name) { names.append(f.name) } }
        var b: [UInt8] = Array("SDNA".utf8)
        func strings(_ tag: String, _ list: [String]) {
            b += Array(tag.utf8) + le32(list.count)
            for n in list { b += Array(n.utf8) + [0] }
            while b.count % 4 != 0 { b.append(0) }
        }
        strings("NAME", names)
        strings("TYPE", dna.types.map(\.0))
        b += Array("TLEN".utf8); for t in dna.types { b += le16(t.1) }
        while b.count % 4 != 0 { b.append(0) }
        b += Array("STRC".utf8) + le32(dna.structs.count)
        for s in dna.structs {
            b += le16(dna.typeIndex(s.name)) + le16(s.fields.count)
            for f in s.fields { b += le16(dna.typeIndex(f.type)) + le16(names.firstIndex(of: f.name)!) }
        }
        return b
    }

    private func block(_ code: String, _ payload: [UInt8], address: UInt64, sdna: Int, count: Int) -> [UInt8] {
        var b = Array(code.utf8) + [UInt8](repeating: 0, count: 4 - code.utf8.count)
        b += le32(payload.count) + le64(address) + le32(sdna) + le32(count) + payload
        return b
    }

    /// A single-object scene: a 1 m × 2 m rectangle (two triangles, one quad)
    /// standing in Blender's XY plane at z = 0.5 m, with UVs, one material
    /// (red) carrying a packed 1×1 PNG, and the object moved +3 m in x.
    private func makeBlend(gzip: Bool = false) -> Data {
        var dna = DNA()
        dna.add(.init(name: "ID", size: 66 + 2, fields: [("char", "name[66]"), ("char", "pad[2]")]))
        dna.add(.init(name: "MVert", size: 12, fields: [("float", "co[3]")]))
        dna.add(.init(name: "MPoly", size: 12, fields: [("int", "loopstart"), ("int", "totloop"), ("short", "mat_nr"), ("short", "pad")]))
        dna.add(.init(name: "MLoop", size: 8, fields: [("int", "v"), ("int", "e")]))
        dna.add(.init(name: "MLoopUV", size: 12, fields: [("float", "uv[2]"), ("int", "flag")]))
        dna.add(.init(name: "PackedFile", size: 16, fields: [("int", "size"), ("int", "seek"), ("void", "*data")]))
        dna.add(.init(name: "Image", size: 68 + 8 + 1024, fields: [("ID", "id"), ("PackedFile", "*packedfile"), ("char", "name[1024]")]))
        dna.add(.init(name: "Tex", size: 68 + 2 + 2 + 4 + 8, fields: [("ID", "id"), ("short", "type"), ("short", "pad2"), ("int", "pad3"), ("Image", "*ima")]))
        dna.add(.init(name: "MTex", size: 2 + 2 + 4 + 8, fields: [("short", "texco"), ("short", "mapto"), ("int", "pad4"), ("Tex", "*tex")]))
        dna.add(.init(name: "Material", size: 68 + 16 + 8 * 18, fields: [("ID", "id"), ("float", "r"), ("float", "g"), ("float", "b"), ("float", "alpha"), ("MTex", "*mtex[18]")]))
        dna.add(.init(name: "Mesh", size: 68 + 8 * 5 + 16 + 4, fields: [("ID", "id"), ("Material", "**mat"), ("MVert", "*mvert"), ("MPoly", "*mpoly"), ("MLoop", "*mloop"), ("MLoopUV", "*mloopuv"), ("int", "totvert"), ("int", "totpoly"), ("int", "totloop"), ("short", "totcol"), ("short", "pad5"), ("int", "pad6")]))
        dna.add(.init(name: "Object", size: 68 + 2 + 2 + 4 + 64 + 8, fields: [("ID", "id"), ("short", "type"), ("short", "pad7"), ("int", "pad8"), ("float", "obmat[4][4]"), ("void", "*data")]))

        let png = Data(base64Encoded: "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8DwHwAFBQIAX8jx0gAAAABJRU5ErkJggg==")!
        let A: [String: UInt64] = ["ob": 0x1000, "me": 0x2000, "mv": 0x3000, "mp": 0x4000, "ml": 0x5000, "uv": 0x6000,
                                   "matarr": 0x7000, "ma": 0x8000, "mtex": 0x9000, "tex": 0xA000, "ima": 0xB000, "pf": 0xC000, "pfdata": 0xD000]
        var file: [UInt8] = Array("BLENDER-v278".utf8)
        // Object
        var ob = padded("OBPlate", 66) + [0, 0] + le16(1) + le16(0) + le32(0)
        let obmat: [Float] = [1, 0, 0, 0,  0, 1, 0, 0,  0, 0, 1, 0,  3, 0, 0, 1]
        for v in obmat { ob += f32(v) }
        ob += le64(A["me"]!)
        file += block("OB", ob, address: A["ob"]!, sdna: dna.structIndex("Object"), count: 1)
        // Mesh
        var me = padded("MEPlate", 66) + [0, 0] + le64(A["matarr"]!) + le64(A["mv"]!) + le64(A["mp"]!) + le64(A["ml"]!) + le64(A["uv"]!)
        me += le32(4) + le32(1) + le32(4) + le16(1) + le16(0) + le32(0)
        file += block("ME", me, address: A["me"]!, sdna: dna.structIndex("Mesh"), count: 1)
        var mv: [UInt8] = []
        for p in [(0, 0, 0.5), (1, 0, 0.5), (1, 2, 0.5), (0, 2, 0.5)] as [(Float, Float, Float)] { mv += f32(p.0) + f32(p.1) + f32(p.2) }
        file += block("DATA", mv, address: A["mv"]!, sdna: dna.structIndex("MVert"), count: 4)
        file += block("DATA", le32(0) + le32(4) + le16(0) + le16(0), address: A["mp"]!, sdna: dna.structIndex("MPoly"), count: 1)
        var ml: [UInt8] = []
        for v in [0, 1, 2, 3] { ml += le32(v) + le32(0) }
        file += block("DATA", ml, address: A["ml"]!, sdna: dna.structIndex("MLoop"), count: 4)
        var uv: [UInt8] = []
        for t in [(0, 0), (1, 0), (1, 1), (0, 1)] as [(Float, Float)] { uv += f32(t.0) + f32(t.1) + le32(0) }
        file += block("DATA", uv, address: A["uv"]!, sdna: dna.structIndex("MLoopUV"), count: 4)
        file += block("DATA", le64(A["ma"]!), address: A["matarr"]!, sdna: 0, count: 1)
        // Material → MTex → Tex → Image → PackedFile → bytes
        var ma = padded("MARed", 66) + [0, 0] + f32(1) + f32(0) + f32(0) + f32(1)
        ma += le64(A["mtex"]!) + [UInt8](repeating: 0, count: 8 * 17)
        file += block("MA", ma, address: A["ma"]!, sdna: dna.structIndex("Material"), count: 1)
        file += block("DATA", le16(0) + le16(1) + le32(0) + le64(A["tex"]!), address: A["mtex"]!, sdna: dna.structIndex("MTex"), count: 1)
        file += block("TE", padded("TEpaint", 66) + [0, 0] + le16(8) + le16(0) + le32(0) + le64(A["ima"]!), address: A["tex"]!, sdna: dna.structIndex("Tex"), count: 1)
        file += block("IM", padded("IMpaint.png", 66) + [0, 0] + le64(A["pf"]!) + padded("//textures/paint.png", 1024), address: A["ima"]!, sdna: dna.structIndex("Image"), count: 1)
        file += block("DATA", le32(png.count) + le32(0) + le64(A["pfdata"]!), address: A["pf"]!, sdna: dna.structIndex("PackedFile"), count: 1)
        file += block("DATA", [UInt8](png), address: A["pfdata"]!, sdna: 0, count: 1)
        file += block("DNA1", dnaBlock(dna), address: 0xE000, sdna: 0, count: 1)
        file += block("ENDB", [], address: 0, sdna: 0, count: 0)
        let raw = Data(file)
        guard gzip else { return raw }
        var buf = Data(count: raw.count + 128)
        let n = buf.withUnsafeMutableBytes { dst in
            raw.withUnsafeBytes { src in
                compression_encode_buffer(dst.bindMemory(to: UInt8.self).baseAddress!, raw.count + 128,
                                          src.bindMemory(to: UInt8.self).baseAddress!, raw.count, nil, COMPRESSION_ZLIB)
            }
        }
        buf.count = n
        var gz = Data([0x1f, 0x8b, 0x08, 0x00, 0, 0, 0, 0, 0x00, 0x03])
        gz.append(buf)
        gz.append(contentsOf: [0, 0, 0, 0])                       // CRC (ignored by the reader)
        gz.append(contentsOf: le32(raw.count))                     // ISIZE
        return gz
    }

    // MARK: - Tests

    func testSyntheticBlendImportsAsAYUpMillimetrePartWithTexture() throws {
        let parts = try MeshImportKit.parts(from: makeBlend(), fileName: "plate.blend")
        XCTAssertEqual(parts.count, 1)
        let part = parts[0]
        XCTAssertEqual(part.name, "Plate")
        XCTAssertEqual(part.mesh.indices.count, 6, "one quad → two triangles")
        // Blender (x, y, z) m → app (x, z, −y) mm: the 1 × 2 m plate at z = 0.5,
        // moved +3 in x, spans x 3000…4000, y = 500, z −2000…0.
        let aabb = part.mesh.localAABB
        XCTAssertEqual(aabb.min.x, 3000, accuracy: 1e-2); XCTAssertEqual(aabb.max.x, 4000, accuracy: 1e-2)
        XCTAssertEqual(aabb.min.y, 500, accuracy: 1e-2); XCTAssertEqual(aabb.max.y, 500, accuracy: 1e-2)
        XCTAssertEqual(aabb.min.z, -2000, accuracy: 1e-2); XCTAssertEqual(aabb.max.z, 0, accuracy: 1e-2)
        // Winding survives the rotation: +Z (Blender) faces become +Y (app).
        XCTAssertEqual(part.mesh.normals[0].y, 1, accuracy: 1e-5)
        XCTAssertEqual(part.mesh.texcoords?.count, 4)
        XCTAssertEqual(part.mesh.texcoords?[0], SIMD2(0, 1), "Blender UV origin is bottom-left")
        XCTAssertEqual(part.material?.baseColor.x ?? 0, 1, accuracy: 1e-9)
        XCTAssertEqual(part.material?.baseColor.y ?? 1, 0, accuracy: 1e-9)
        XCTAssertNotNil(part.material?.baseColorTexture, "the packed PNG rides on the material")
        XCTAssertEqual(part.material?.baseColorTexture?.prefix(4), Data([0x89, 0x50, 0x4E, 0x47]))
    }

    func testGzippedBlendReadsTheSame() throws {
        let plain = try MeshImportKit.parts(from: makeBlend(), fileName: "plate.blend")
        let zipped = try MeshImportKit.parts(from: makeBlend(gzip: true), fileName: "plate.blend")
        XCTAssertEqual(zipped.count, 1)
        XCTAssertEqual(zipped[0].mesh, plain[0].mesh)
    }

    func testZstdBlendIsRefusedWithAClearMessage() {
        let zstd = Data([0x28, 0xb5, 0x2f, 0xfd, 0, 0, 0, 0, 0, 0, 0, 0])
        XCTAssertThrowsError(try MeshImportKit.parts(from: zstd, fileName: "x.blend")) { error in
            guard case MeshImportError.malformed(let why) = error else { return XCTFail("\(error)") }
            XCTAssertTrue(why.contains("zstd"))
        }
    }

    func testZipContainingOnlyABlendIsAccepted() throws {
        // Stored zip with the .blend inside a source/ folder, the way Sketchfab packs them.
        let blend = makeBlend()
        var out = Data(), central = Data()
        func u16(_ v: Int, _ d: inout Data) { withUnsafeBytes(of: UInt16(v).littleEndian) { d.append(contentsOf: $0) } }
        func u32(_ v: Int, _ d: inout Data) { withUnsafeBytes(of: UInt32(v).littleEndian) { d.append(contentsOf: $0) } }
        let name = Data("source/plate.blend".utf8)
        u32(0x04034b50, &out); u16(20, &out); u16(0, &out); u16(0, &out); u16(0, &out); u16(0, &out); u32(0, &out)
        u32(blend.count, &out); u32(blend.count, &out); u16(name.count, &out); u16(0, &out); out.append(name); out.append(blend)
        u32(0x02014b50, &central); u16(20, &central); u16(20, &central); u16(0, &central); u16(0, &central); u16(0, &central); u16(0, &central); u32(0, &central)
        u32(blend.count, &central); u32(blend.count, &central); u16(name.count, &central); u16(0, &central); u16(0, &central); u16(0, &central); u16(0, &central); u32(0, &central); u32(0, &central); central.append(name)
        let centralOffset = out.count
        out.append(central)
        u32(0x06054b50, &out); u16(0, &out); u16(0, &out); u16(1, &out); u16(1, &out); u32(central.count, &out); u32(centralOffset, &out); u16(0, &out)
        let parts = try MeshImportKit.parts(from: out, fileName: "download.zip")
        XCTAssertEqual(parts.count, 1)
        XCTAssertEqual(parts[0].mesh.indices.count, 6)
    }
}
