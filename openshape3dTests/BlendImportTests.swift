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

    /// Blender 5 writes a 17-byte header and 32-byte `LargeBHead8` block headers.
    private var blender5 = false

    private func block(_ code: String, _ payload: [UInt8], address: UInt64, sdna: Int, count: Int) -> [UInt8] {
        var b = Array(code.utf8) + [UInt8](repeating: 0, count: 4 - code.utf8.count)
        if blender5 {
            // LargeBHead8 { int code; int SDNAnr; uint64 old; int64 len; int64 nr; }
            b += le32(sdna) + le64(address) + le64(UInt64(payload.count)) + le64(UInt64(count)) + payload
        } else {
            b += le32(payload.count) + le64(address) + le32(sdna) + le32(count) + payload
        }
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
        var file: [UInt8] = Array((blender5 ? "BLENDER17-01v0502" : "BLENDER-v278").utf8)
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

    /// The same plate as `makeBlend()`, written the way Blender 5 does: a
    /// 17-byte header, LargeBHead8 blocks, and the mesh's positions, corners,
    /// material indices (one shared value) and UVs in `Mesh.attribute_storage`
    /// (DNA_attribute_types.h) instead of MVert/MPoly/MLoop or CustomData.
    private func makeBlend5WithAttributeStorage(secondPlateScaledBy second: Float? = nil) -> Data {
        blender5 = true
        defer { blender5 = false }
        var dna = DNA()
        dna.types += [("int8_t", 1), ("int64_t", 8)]
        dna.add(.init(name: "ID", size: 66 + 2, fields: [("char", "name[66]"), ("char", "pad[2]")]))
        dna.add(.init(name: "PackedFile", size: 16, fields: [("int", "size"), ("int", "seek"), ("void", "*data")]))
        dna.add(.init(name: "Image", size: 68 + 8 + 1024, fields: [("ID", "id"), ("PackedFile", "*packedfile"), ("char", "name[1024]")]))
        dna.add(.init(name: "Tex", size: 68 + 2 + 2 + 4 + 8, fields: [("ID", "id"), ("short", "type"), ("short", "pad2"), ("int", "pad3"), ("Image", "*ima")]))
        dna.add(.init(name: "MTex", size: 2 + 2 + 4 + 8, fields: [("short", "texco"), ("short", "mapto"), ("int", "pad4"), ("Tex", "*tex")]))
        dna.add(.init(name: "Material", size: 68 + 16 + 8 * 18, fields: [("ID", "id"), ("float", "r"), ("float", "g"), ("float", "b"), ("float", "alpha"), ("MTex", "*mtex[18]")]))
        dna.add(.init(name: "AttributeArray", size: 32, fields: [("void", "*data"), ("void", "*sharing_info"), ("int64_t", "size"), ("int8_t", "is_single"), ("char", "_pad[7]")]))
        dna.add(.init(name: "AttributeSingle", size: 16, fields: [("void", "*data"), ("void", "*sharing_info")]))
        dna.add(.init(name: "Attribute", size: 24, fields: [("char", "*name"), ("short", "data_type"), ("int8_t", "domain"), ("int8_t", "storage_type"), ("char", "_pad[4]"), ("void", "*data")]))
        dna.add(.init(name: "AttributeStorage", size: 24, fields: [("Attribute", "*dna_attributes"), ("int", "dna_attributes_num"), ("char", "_pad[4]"), ("void", "*runtime")]))
        dna.add(.init(name: "Mesh", size: 68 + 8 + 16 + 8 + 24 + 8, fields: [
            ("ID", "id"), ("Material", "**mat"), ("int", "totvert"), ("int", "totpoly"), ("int", "totloop"), ("int", "pad1"),
            ("int", "*poly_offset_indices"), ("AttributeStorage", "attribute_storage"), ("short", "totcol"), ("short", "pad5"), ("int", "pad6")]))
        // Blender 5 saves no obmat: only the transform channels (DNA_object_types.h).
        dna.add(.init(name: "Object", size: 296, fields: [
            ("ID", "id"), ("short", "type"), ("short", "pad7"), ("int", "pad8"),
            ("float", "loc[3]"), ("float", "dloc[3]"), ("float", "size[3]"), ("float", "dscale[3]"),
            ("float", "rot[3]"), ("float", "drot[3]"), ("float", "quat[4]"), ("float", "dquat[4]"),
            ("float", "rotAxis[3]"), ("float", "drotAxis[3]"), ("float", "rotAngle"), ("float", "drotAngle"),
            ("short", "rotmode"), ("short", "pad9"), ("float", "parentinv[4][4]"), ("Object", "*parent"), ("void", "*data")]))

        let png = Data(base64Encoded: "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8DwHwAFBQIAX8jx0gAAAABJRU5ErkJggg==")!
        var file: [UInt8] = Array("BLENDER17-01v0502".utf8)
        // One object + mesh. Blender 5 keeps DATA addresses unique only within
        // their ID, so a second mesh may reuse every DATA address of the first.
        func addPlate(object: UInt64, mesh: UInt64, name: String, scale: Float, turnZ: Float = 0) {
            var ob = padded("OB" + name, 66) + [0, 0] + le16(1) + le16(0) + le32(0)
            let channels: [Float] = [3, 0, 0,  0, 0, 0,  1, 1, 1,  1, 1, 1,      // loc, dloc, size, dscale
                                     0, 0, turnZ,  0, 0, 0,                        // rot (XYZ euler), drot
                                     1, 0, 0, 0,  1, 0, 0, 0,                      // quat, dquat
                                     0, 1, 0,  0, 1, 0,  0, 0]                     // rotAxis, drotAxis, angles
            for v in channels { ob += f32(v) }
            ob += le16(1) + le16(0)                                                // rotmode XYZ
            for v in [1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1] as [Float] { ob += f32(v) }   // parentinv
            ob += le64(0) + le64(mesh)                                             // parent, data
            file += block("OB", ob, address: object, sdna: dna.structIndex("Object"), count: 1)
            var me = padded("ME" + name, 66) + [0, 0] + le64(0x7000) + le32(4) + le32(1) + le32(4) + le32(0) + le64(0x3000)
            me += le64(0x4000) + le32(4) + le32(0) + le64(0)                   // attribute_storage: 4 attributes
            me += le16(1) + le16(0) + le32(0)
            file += block("ME", me, address: mesh, sdna: dna.structIndex("Mesh"), count: 1)
            file += block("DATA", le32(0) + le32(4), address: 0x3000, sdna: 0, count: 2)   // face offsets
            let corners: [(Float, Float, Float)] = [(0, 0, 0.5), (1, 0, 0.5), (1, 2, 0.5), (0, 2, 0.5)]
            // name, data type, domain, storage (0 array / 1 single), holder, values, count
            let attrs: [(String, Int, Int, Int, UInt64, UInt64, [UInt8], Int)] = [
                ("position", 7, 0, 0, 0x4100, 0x4200, corners.flatMap { f32($0.0 * scale) + f32($0.1 * scale) + f32($0.2) }, 4),
                (".corner_vert", 3, 3, 0, 0x4300, 0x4400, [0, 1, 2, 3].flatMap { le32($0) }, 4),
                ("material_index", 3, 2, 1, 0x4500, 0x4600, le32(0), 1),
                ("UVMap", 6, 3, 0, 0x4700, 0x4800, [(0, 0), (1, 0), (1, 1), (0, 1)].flatMap { (t: (Float, Float)) in f32(t.0) + f32(t.1) }, 4),
            ]
            var list: [UInt8] = []
            for (i, a) in attrs.enumerated() {
                let nameAddress = UInt64(0x5000 + 0x100 * i)
                list += le64(nameAddress) + le16(a.1) + [UInt8(a.2), UInt8(a.3)] + [0, 0, 0, 0] + le64(a.4)
                file += block("DATA", Array(a.0.utf8) + [0], address: nameAddress, sdna: 0, count: 1)
                if a.3 == 1 {
                    file += block("DATA", le64(a.5) + le64(0), address: a.4, sdna: dna.structIndex("AttributeSingle"), count: 1)
                } else {
                    file += block("DATA", le64(a.5) + le64(0) + le64(UInt64(a.7)) + [0] + [UInt8](repeating: 0, count: 7),
                                  address: a.4, sdna: dna.structIndex("AttributeArray"), count: 1)
                }
                file += block("DATA", a.6, address: a.5, sdna: 0, count: 1)
            }
            file += block("DATA", list, address: 0x4000, sdna: dna.structIndex("Attribute"), count: attrs.count)
            file += block("DATA", le64(0x8000), address: 0x7000, sdna: 0, count: 1)
        }
        addPlate(object: 0x1000, mesh: 0x2000, name: "Plate", scale: 1)
        if let second { addPlate(object: 0x1100, mesh: 0x2100, name: "Big", scale: second, turnZ: .pi / 2) }
        var ma = padded("MARed", 66) + [0, 0] + f32(1) + f32(0) + f32(0) + f32(1)
        ma += le64(0x9000) + [UInt8](repeating: 0, count: 8 * 17)
        file += block("MA", ma, address: 0x8000, sdna: dna.structIndex("Material"), count: 1)
        file += block("DATA", le16(0) + le16(1) + le32(0) + le64(0xA000), address: 0x9000, sdna: dna.structIndex("MTex"), count: 1)
        file += block("TE", padded("TEpaint", 66) + [0, 0] + le16(8) + le16(0) + le32(0) + le64(0xB000), address: 0xA000, sdna: dna.structIndex("Tex"), count: 1)
        file += block("IM", padded("IMpaint.png", 66) + [0, 0] + le64(0xC000) + padded("//textures/paint.png", 1024), address: 0xB000, sdna: dna.structIndex("Image"), count: 1)
        file += block("DATA", le32(png.count) + le32(0) + le64(0xD000), address: 0xC000, sdna: dna.structIndex("PackedFile"), count: 1)
        file += block("DATA", [UInt8](png), address: 0xD000, sdna: 0, count: 1)
        file += block("DNA1", dnaBlock(dna), address: 0xE000, sdna: 0, count: 1)
        file += block("ENDB", [], address: 0, sdna: 0, count: 0)
        return Data(file)
    }

    // MARK: - Tests

    /// Blender 5 meshes keep positions, corners, material indices and UVs in
    /// AttributeStorage; the plate read from there is the plate read from MVert.
    /// Blender 5 reuses DATA addresses across IDs: two meshes whose attribute
    /// blocks share every address must each get their own geometry, not the
    /// first one's (the wheels of a real car vanished that way).
    func testBlender5ReusedDataAddressesResolveWithinTheirOwnMesh() throws {
        let parts = try MeshImportKit.parts(from: makeBlend5WithAttributeStorage(secondPlateScaledBy: 2), fileName: "two.blend")
        XCTAssertEqual(parts.map(\.name).sorted(), ["Big", "Plate"])
        let plate = try XCTUnwrap(parts.first { $0.name == "Plate" }).mesh.localAABB
        let big = try XCTUnwrap(parts.first { $0.name == "Big" }).mesh.localAABB
        XCTAssertEqual(plate.max.x - plate.min.x, 1000, accuracy: 1e-2)
        // Its own positions (2 × 4 m), turned 90° about Blender Z by the object's
        // euler rotation (no obmat in a Blender 5 file): 4 m along app X, 2 m along Z.
        XCTAssertEqual(big.max.x - big.min.x, 4000, accuracy: 1e-2, "the second mesh read its own positions, rotated")
        XCTAssertEqual(big.max.z - big.min.z, 2000, accuracy: 1e-2)
        // loc (3, 0, 0) m → x = 3000 mm: the rotated plate spans x −1000…3000.
        XCTAssertEqual(big.max.x, 3000, accuracy: 1e-2)
    }

    func testBlender5AttributeStorageMeshReadsTheSame() throws {
        let legacy = try MeshImportKit.parts(from: makeBlend(), fileName: "plate.blend")
        let parts = try MeshImportKit.parts(from: makeBlend5WithAttributeStorage(), fileName: "plate.blend")
        XCTAssertEqual(parts.count, 1)
        XCTAssertEqual(parts[0].name, legacy[0].name)
        XCTAssertEqual(parts[0].mesh, legacy[0].mesh)
        XCTAssertEqual(parts[0].material?.baseColorTexture, legacy[0].material?.baseColorTexture)
    }

    /// Blender 5 changed the container: a 17-byte header and 32-byte block
    /// headers with 64-bit lengths, fields reordered. The same scene written
    /// that way must import exactly as the 4.x layout does.
    func testBlender5FileFormatReadsTheSame() throws {
        let legacy = try MeshImportKit.parts(from: makeBlend(), fileName: "plate.blend")
        blender5 = true
        defer { blender5 = false }
        let data = makeBlend()
        XCTAssertEqual(String(decoding: data.prefix(17), as: UTF8.self), "BLENDER17-01v0502")
        let parts = try MeshImportKit.parts(from: data, fileName: "plate.blend")
        XCTAssertEqual(parts.count, 1)
        XCTAssertEqual(parts[0].name, legacy[0].name)
        XCTAssertEqual(parts[0].mesh, legacy[0].mesh)
        XCTAssertEqual(parts[0].material?.baseColorTexture, legacy[0].material?.baseColorTexture)
    }

    /// A header from a format this reader doesn't know says so, instead of
    /// misreading it as the old layout ("truncated block v050").
    func testUnknownFutureHeaderIsRefusedWithAClearMessage() {
        var data = Data("BLENDER17-02v0600".utf8)
        data.append(Data(count: 64))
        XCTAssertThrowsError(try MeshImportKit.parts(from: data, fileName: "x.blend")) { error in
            guard case MeshImportError.malformed(let why) = error else { return XCTFail("\(error)") }
            XCTAssertTrue(why.contains("newer Blender"), why)
            XCTAssertFalse(why.contains("truncated"), why)
        }
    }

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
