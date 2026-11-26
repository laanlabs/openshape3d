//
//  BlendImporter.swift
//  openshape3d
//
//  Reads Blender's own .blend files without Blender. A .blend is a list of
//  memory blocks dumped from the running program, described by the DNA1
//  block (struct names, field names, sizes) written alongside them — so
//  the reader parses that catalogue first and then reads every field by
//  name at the offset the catalogue gives, which is what makes one reader
//  work across versions. Supported: uncompressed and gzip files, 32/64-bit,
//  both endiannesses; mesh objects with MVert/MPoly/MLoop (2.63 … 3.4)
//  or the attribute layers that replaced them (3.5+); UVs from `mloopuv`,
//  a CD_MLOOPUV or a CD_PROP_FLOAT2 layer; materials by slot (viewport
//  colour) with a base-colour image from a 2.7x texture slot or a 2.8+
//  Image Texture node, packed in the file or beside it. Blender is Z-up
//  and metres; parts come out Y-up in millimetres.
//
//  Blender 5 files are read too: the 17-byte header ("BLENDER17-01v0502")
//  with 32-byte block headers (LargeBHead8, 64-bit lengths), meshes kept in
//  AttributeStorage, DATA addresses unique only within their ID, and object
//  matrices rebuilt from loc/rot/scale since `obmat` is no longer saved.
//

import Compression
import Foundation
import simd

nonisolated enum BlendImporter {

    // MARK: - Entry

    static func parts(from raw: Data, siblings: [String: Data], unitScale: Double) throws -> [ImportedPart] {
        var data = raw
        if data.count >= 2, data[data.startIndex] == 0x1f, data[data.startIndex + 1] == 0x8b {
            data = try gunzip(data)
        } else if data.count >= 4, data[data.startIndex] == 0x28, data[data.startIndex + 1] == 0xb5,
                  data[data.startIndex + 2] == 0x2f, data[data.startIndex + 3] == 0xfd {
            throw MeshImportError.malformed("blend: this file is zstd-compressed (Blender 3.0+ \"Compress\" save); "
                                            + "save it without compression or export glTF")
        }
        let file = try BlendFile(data)
        return try extract(file, siblings: siblings, unitScale: unitScale)
    }

    // MARK: - gzip

    private static func gunzip(_ data: Data) throws -> Data {
        // RFC 1952 header: ID1 ID2 CM FLG MTIME(4) XFL OS, then optional
        // fields by FLG; the payload is a raw deflate stream.
        let bytes = [UInt8](data)
        guard bytes.count > 18, bytes[2] == 8 else { throw MeshImportError.malformed("blend: bad gzip header") }
        let flags = bytes[3]
        var p = 10
        if flags & 0x04 != 0 { let xlen = Int(bytes[p]) | Int(bytes[p + 1]) << 8; p += 2 + xlen }
        if flags & 0x08 != 0 { while p < bytes.count, bytes[p] != 0 { p += 1 }; p += 1 }
        if flags & 0x10 != 0 { while p < bytes.count, bytes[p] != 0 { p += 1 }; p += 1 }
        if flags & 0x02 != 0 { p += 2 }
        guard p < bytes.count - 8 else { throw MeshImportError.malformed("blend: truncated gzip") }
        // ISIZE (mod 2^32) in the trailer gives the size for anything under 4 GB.
        let isize = Int(bytes[bytes.count - 4]) | Int(bytes[bytes.count - 3]) << 8
            | Int(bytes[bytes.count - 2]) << 16 | Int(bytes[bytes.count - 1]) << 24
        let capacity = max(isize, 1 << 16)
        var out = Data(count: capacity)
        let produced = out.withUnsafeMutableBytes { dst -> Int in
            data.withUnsafeBytes { src -> Int in
                compression_decode_buffer(
                    dst.bindMemory(to: UInt8.self).baseAddress!, capacity,
                    src.bindMemory(to: UInt8.self).baseAddress! + p, bytes.count - p - 8,
                    nil, COMPRESSION_ZLIB)
            }
        }
        guard produced > 0 else { throw MeshImportError.malformed("blend: gzip inflate failed") }
        out.count = produced
        return out
    }

    // MARK: - File structure

    struct Block {
        let code: String          // "OB", "ME", "MA", "IM", "DATA", …
        let size: Int
        let oldAddress: UInt64    // the pointer value other blocks use to reach this one
        let sdnaIndex: Int
        let count: Int
        let dataOffset: Int
        /// Index of the ID block this block belongs to: itself for an ID
        /// ("OB", "ME", …), else the last ID before it (−1 before any).
        /// Blender 5 keeps DATA addresses unique only within their ID.
        var owner: Int = -1
    }

    struct Field {
        let typeName: String
        let name: String          // as written: "*mvert", "co[3]", "obmat[4][4]"
        let offset: Int
        let size: Int
        var isPointer: Bool { name.hasPrefix("*") || name.hasPrefix("(*") }
        var arrayCount: Int {
            var n = 1, s = Substring(name)
            while let a = s.firstIndex(of: "["), let b = s.firstIndex(of: "]"), a < b {
                n *= Int(s[s.index(after: a)..<b]) ?? 1
                s = s[s.index(after: b)...]
            }
            return n
        }
        var baseName: String {
            var s = name
            while s.hasPrefix("*") { s.removeFirst() }
            if s.hasPrefix("(") { s.removeFirst() }
            if let b = s.firstIndex(of: "[") { s = String(s[..<b]) }
            if let b = s.firstIndex(of: ")") { s = String(s[..<b]) }
            return s
        }
    }

    struct StructDef {
        let name: String
        let size: Int
        let fields: [Field]
        var byName: [String: Field]
    }

    final class BlendFile {
        let bytes: [UInt8]
        let pointerSize: Int
        let littleEndian: Bool
        let version: Int
        /// 12 for "BLENDER-v405"; 17 for Blender 5's "BLENDER17-01v0502".
        let headerSize: Int
        /// Blender 5 (file format 1) writes `LargeBHead8` block headers:
        /// code, SDNA index, old address, then 64-bit length and count.
        let largeBlockHeaders: Bool
        var blocks: [Block] = []
        var byAddress: [UInt64: Block] = [:]
        /// Every block per address, for the addresses several IDs reuse.
        var allByAddress: [UInt64: [Block]] = [:]
        var structs: [StructDef] = []
        var structIndex: [String: Int] = [:]
        var typeSizes: [String: Int] = [:]

        init(_ data: Data) throws {
            bytes = [UInt8](data)
            guard bytes.count > 12, String(decoding: bytes[0..<7], as: UTF8.self) == "BLENDER" else {
                throw MeshImportError.malformed("blend: not a Blender file")
            }
            if Self.isDigit(bytes[7]) {
                // Blender 5.0+ (blo_core_blend_header.cc): header size "17",
                // '-', file-format version "01", 'v' (little-endian only),
                // then the four-digit Blender version. Always 64-bit.
                let raw = bytes
                let text = { (r: Range<Int>) in String(decoding: raw[r], as: UTF8.self) }
                guard raw.count > 17, text(7..<9) == "17", raw[9] == UInt8(ascii: "-"),
                      text(10..<12) == "01", raw[12] == UInt8(ascii: "v"),
                      raw[13..<17].allSatisfy(Self.isDigit), let v = Int(text(13..<17)) else {
                    let header = String(decoding: raw.prefix(17).map { $0 >= 32 && $0 < 127 ? $0 : 0x3F }, as: UTF8.self)
                    throw MeshImportError.malformed("blend: saved by a newer Blender in a file format this importer "
                                                    + "doesn't read yet (\"\(header)\"); export glTF from Blender instead")
                }
                pointerSize = 8
                littleEndian = true
                version = v
                headerSize = 17
                largeBlockHeaders = true
            } else {
                pointerSize = bytes[7] == UInt8(ascii: "-") ? 8 : 4
                littleEndian = bytes[8] == UInt8(ascii: "v")
                version = Int(String(decoding: bytes[9..<12], as: UTF8.self)) ?? 0
                headerSize = 12
                largeBlockHeaders = false
            }
            try readBlocks()
            try readDNA()
        }

        private static func isDigit(_ b: UInt8) -> Bool { b >= UInt8(ascii: "0") && b <= UInt8(ascii: "9") }

        // Scalars at absolute offsets, honouring the file's endianness.
        func u8(_ at: Int) -> UInt8 { at < bytes.count ? bytes[at] : 0 }
        func u16(_ at: Int) -> UInt16 {
            guard at + 2 <= bytes.count else { return 0 }
            let a = UInt16(bytes[at]), b = UInt16(bytes[at + 1])
            return littleEndian ? a | b << 8 : b | a << 8
        }
        func i16(_ at: Int) -> Int16 { Int16(bitPattern: u16(at)) }
        func u32(_ at: Int) -> UInt32 {
            guard at + 4 <= bytes.count else { return 0 }
            var v: UInt32 = 0
            for k in 0..<4 { v |= UInt32(bytes[at + k]) << (littleEndian ? 8 * k : 8 * (3 - k)) }
            return v
        }
        func i32(_ at: Int) -> Int32 { Int32(bitPattern: u32(at)) }
        func u64(_ at: Int) -> UInt64 {
            guard at + 8 <= bytes.count else { return 0 }
            var v: UInt64 = 0
            for k in 0..<8 { v |= UInt64(bytes[at + k]) << (littleEndian ? 8 * k : 8 * (7 - k)) }
            return v
        }
        func i64(_ at: Int) -> Int64 { Int64(bitPattern: u64(at)) }
        func f32(_ at: Int) -> Float { Float(bitPattern: u32(at)) }
        func pointer(_ at: Int) -> UInt64 { pointerSize == 8 ? u64(at) : UInt64(u32(at)) }
        func cString(_ at: Int, max: Int) -> String {
            var end = at
            while end < min(at + max, bytes.count), bytes[end] != 0 { end += 1 }
            return String(decoding: bytes[at..<end], as: UTF8.self)
        }

        private func readBlocks() throws {
            var offset = headerSize
            var currentID = -1
            let header = largeBlockHeaders ? 32 : 16 + pointerSize
            while offset + header <= bytes.count {
                let code = String(decoding: bytes[offset..<offset + 4].prefix { $0 != 0 }, as: UTF8.self)
                let size, sdna, count: Int
                let old: UInt64
                if largeBlockHeaders {
                    // LargeBHead8 { int code; int SDNAnr; uint64 old; int64 len; int64 nr; }
                    sdna = Int(i32(offset + 4))
                    old = u64(offset + 8)
                    size = Int(clamping: i64(offset + 16))
                    count = Int(clamping: i64(offset + 24))
                } else {
                    // BHead4 / SmallBHead8 { int code; int len; void *old; int SDNAnr; int nr; }
                    size = Int(i32(offset + 4))
                    old = pointer(offset + 8)
                    sdna = Int(i32(offset + 8 + pointerSize))
                    count = Int(i32(offset + 12 + pointerSize))
                }
                var block = Block(code: code, size: size, oldAddress: old, sdnaIndex: sdna, count: count,
                                  dataOffset: offset + header)
                // ID blocks have two-letter codes (blo_bhead_is_id); DATA and the
                // file-level blocks (REND, TEST, GLOB, DNA1, ENDB) don't.
                if code.utf8.count <= 2 { currentID = blocks.count }
                block.owner = currentID
                blocks.append(block)
                if code == "ENDB" { break }
                guard size >= 0, block.dataOffset + size <= bytes.count else {
                    throw MeshImportError.malformed("blend: truncated block \(code)")
                }
                if byAddress[old] == nil { byAddress[old] = block }
                allByAddress[old, default: []].append(block)
                offset = block.dataOffset + size
            }
        }

        private func readDNA() throws {
            guard let dna = blocks.first(where: { $0.code == "DNA1" }) else {
                throw MeshImportError.malformed("blend: no DNA1 block")
            }
            var p = dna.dataOffset
            func expect(_ tag: String) throws {
                guard String(decoding: bytes[p..<p + 4], as: UTF8.self) == tag else {
                    throw MeshImportError.malformed("blend: DNA missing \(tag)")
                }
                p += 4
            }
            // Padding inside the DNA block is relative to the block's own
            // start, which need not be 4-aligned in the file.
            func align4() { p = dna.dataOffset + ((p - dna.dataOffset + 3) & ~3) }
            func readStrings() -> [String] {
                let n = Int(i32(p)); p += 4
                var out: [String] = []; out.reserveCapacity(n)
                for _ in 0..<n {
                    var end = p
                    while end < bytes.count, bytes[end] != 0 { end += 1 }
                    out.append(String(decoding: bytes[p..<end], as: UTF8.self)); p = end + 1
                }
                return out
            }
            try expect("SDNA")
            try expect("NAME"); let names = readStrings(); align4()
            try expect("TYPE"); let types = readStrings(); align4()
            try expect("TLEN")
            var lengths: [Int] = []
            for _ in types.indices { lengths.append(Int(i16(p))); p += 2 }
            align4()
            try expect("STRC")
            let structCount = Int(i32(p)); p += 4
            for (t, name) in types.enumerated() { typeSizes[name] = lengths[t] }
            for _ in 0..<structCount {
                let typeIndex = Int(i16(p)), fieldCount = Int(i16(p + 2)); p += 4
                var fields: [Field] = []
                var offset = 0
                for _ in 0..<fieldCount {
                    let ft = Int(i16(p)), fn = Int(i16(p + 2)); p += 4
                    let typeName = types[ft], fieldName = names[fn]
                    let field0 = Field(typeName: typeName, name: fieldName, offset: offset, size: 0)
                    let unit = field0.isPointer ? pointerSize : lengths[ft]
                    let size = unit * field0.arrayCount
                    fields.append(Field(typeName: typeName, name: fieldName, offset: offset, size: size))
                    offset += size
                }
                var byName: [String: Field] = [:]
                for f in fields { byName[f.baseName] = f }
                structIndex[types[typeIndex]] = structs.count
                structs.append(StructDef(name: types[typeIndex], size: lengths[typeIndex], fields: fields, byName: byName))
            }
        }

        // MARK: Field access

        func structDef(_ name: String) -> StructDef? { structIndex[name].map { structs[$0] } }
        func structName(of block: Block) -> String {
            block.sdnaIndex < structs.count ? structs[block.sdnaIndex].name : "?"
        }
        /// Absolute offset of `field` in the `index`-th struct of `block`.
        func fieldOffset(_ block: Block, _ structName: String, _ field: String, index: Int = 0) -> Int? {
            guard let def = structDef(structName), let f = def.byName[field] else { return nil }
            return block.dataOffset + index * def.size + f.offset
        }
        func int(_ block: Block, _ s: String, _ field: String, index: Int = 0) -> Int? {
            guard let def = structDef(s), let f = def.byName[field],
                  let at = fieldOffset(block, s, field, index: index) else { return nil }
            switch f.typeName {
            case "short": return Int(i16(at))
            case "ushort": return Int(u16(at))
            case "char", "int8_t": return Int(Int8(bitPattern: u8(at)))
            case "uchar", "uint8_t": return Int(u8(at))
            case "int16_t": return Int(i16(at))
            case "uint16_t": return Int(u16(at))
            case "int64_t": return Int(Int64(bitPattern: u64(at)))
            case "uint64_t": return Int(u64(at))
            default: return Int(i32(at))
            }
        }
        func ptr(_ block: Block, _ s: String, _ field: String, index: Int = 0) -> UInt64? {
            fieldOffset(block, s, field, index: index).map { pointer($0) }
        }
        func floats(_ block: Block, _ s: String, _ field: String, index: Int = 0) -> [Float]? {
            guard let def = structDef(s), let f = def.byName[field],
                  let at = fieldOffset(block, s, field, index: index) else { return nil }
            return (0..<f.arrayCount).map { f32(at + 4 * $0) }
        }
        func string(_ block: Block, _ s: String, _ field: String, index: Int = 0) -> String? {
            guard let def = structDef(s), let f = def.byName[field],
                  let at = fieldOffset(block, s, field, index: index) else { return nil }
            return cString(at, max: f.arrayCount)
        }
        /// The ID name with its two-letter type prefix stripped ("OBCube" → "Cube").
        func idName(_ block: Block, _ s: String) -> String {
            guard let def = structDef(s), let idField = def.byName["id"], let idDef = structDef("ID"),
                  let nameField = idDef.byName["name"] else { return "" }
            let raw = cString(block.dataOffset + idField.offset + nameField.offset, max: nameField.arrayCount)
            return raw.count > 2 ? String(raw.dropFirst(2)) : raw
        }
        /// The block a pointer read from `holder` points at. Up to Blender 4.x
        /// every address is unique; Blender 5 reuses DATA addresses across
        /// IDs, so a repeated address resolves to the candidate in the same ID.
        func deref(_ address: UInt64?, from holder: Block? = nil) -> Block? {
            guard let address, address != 0 else { return nil }
            if let holder, let candidates = allByAddress[address], candidates.count > 1,
               let sameID = candidates.first(where: { $0.owner == holder.owner }) {
                return sameID
            }
            return byAddress[address]
        }
        /// Pointers stored in a pointer-array block (e.g. Mesh.mat → Material**).
        func pointerArray(_ block: Block, count: Int) -> [UInt64] {
            (0..<max(count, 0)).compactMap { i in
                let at = block.dataOffset + i * pointerSize
                return at + pointerSize <= block.dataOffset + block.size ? pointer(at) : nil
            }
        }
        /// Blender 5+: the attributes of the `AttributeStorage` embedded in
        /// `block` at `field` — where meshes keep positions, corners, material
        /// indices and UVs once the CustomData layers are empty.
        func attributes(_ block: Block, _ s: String, _ field: String) -> [StoredAttribute] {
            guard let def = structDef(s), let f = def.byName[field], let storage = structDef("AttributeStorage"),
                  let listField = storage.byName["dna_attributes"], let numField = storage.byName["dna_attributes_num"],
                  structDef("Attribute") != nil else { return [] }
            let base = block.dataOffset + f.offset
            let total = Int(i32(base + numField.offset))
            guard total > 0, let list = deref(pointer(base + listField.offset), from: block) else { return [] }
            return (0..<total).map { i in
                let single = int(list, "Attribute", "storage_type", index: i) == 1
                let holder = deref(ptr(list, "Attribute", "data", index: i), from: list)
                return StoredAttribute(
                    name: deref(ptr(list, "Attribute", "name", index: i), from: list).map { cString($0.dataOffset, max: $0.size) } ?? "",
                    type: int(list, "Attribute", "data_type", index: i) ?? -1,
                    domain: int(list, "Attribute", "domain", index: i) ?? -1,
                    values: holder.flatMap { deref(ptr($0, single ? "AttributeSingle" : "AttributeArray", "data"), from: $0) },
                    single: single)
            }
        }

        /// Custom-data layers of a CustomData embedded in `block` at `field`.
        func layers(_ block: Block, _ s: String, _ field: String) -> [(type: Int, name: String, data: Block?)] {
            guard let def = structDef(s), let f = def.byName[field], let cd = structDef("CustomData"),
                  let layersField = cd.byName["layers"], let totField = cd.byName["totlayer"] else { return [] }
            let base = block.dataOffset + f.offset
            let total = Int(i32(base + totField.offset))
            guard let layerBlock = deref(pointer(base + layersField.offset), from: block) else { return [] }
            return (0..<max(total, 0)).map { i in
                (int(layerBlock, "CustomDataLayer", "type", index: i) ?? -1,
                 string(layerBlock, "CustomDataLayer", "name", index: i) ?? "",
                 deref(ptr(layerBlock, "CustomDataLayer", "data", index: i), from: layerBlock))
            }
        }
    }

    // MARK: - Blender 5 attribute storage

    /// One generic attribute from a Blender 5+ `AttributeStorage`
    /// (DNA_attribute_types.h): `Attribute { char *name; short data_type;
    /// int8 domain; int8 storage_type; void *data }`, where `data` points to an
    /// `AttributeArray { void *data; …; int64 size }` (array storage) or an
    /// `AttributeSingle { void *data; … }` (one value shared by every element).
    struct StoredAttribute {
        let name: String
        let type: Int       // bke::AttrType
        let domain: Int     // bke::AttrDomain
        let values: Block?
        let single: Bool
    }

    // MARK: - Extraction

    private static let objectTypeMesh = 1
    private static let cdMLoopUV = 16, cdPropFloat2 = 49, cdPropFloat3 = 48, cdPropInt32 = 11
    /// bke::AttrType and bke::AttrDomain values used by Blender 5's AttributeStorage.
    private static let attrInt32 = 3, attrFloat2 = 6, attrFloat3 = 7
    private static let domainPoint = 0, domainFace = 2, domainCorner = 3

    private struct RawMaterial {
        var name: String
        var color: SIMD4<Double>
        var texture: Data?
    }

    private static func extract(_ file: BlendFile, siblings: [String: Data], unitScale: Double) throws -> [ImportedPart] {
        guard file.structDef("Object") != nil, file.structDef("Mesh") != nil else {
            throw MeshImportError.malformed("blend: no Object/Mesh structs in DNA")
        }
        var parts: [ImportedPart] = []
        var materialCache: [UInt64: RawMaterial] = [:]

        for ob in file.blocks where ob.code == "OB" && file.structName(of: ob) == "Object" {
            guard file.int(ob, "Object", "type") == objectTypeMesh,
                  let me = file.deref(file.ptr(ob, "Object", "data"), from: ob), file.structName(of: me) == "Mesh"
            else { continue }
            let name = file.idName(ob, "Object")
            let world = worldMatrix(of: ob, in: file)
            let mirrored = simd_double3x3(
                SIMD3(world.columns.0.x, world.columns.0.y, world.columns.0.z),
                SIMD3(world.columns.1.x, world.columns.1.y, world.columns.1.z),
                SIMD3(world.columns.2.x, world.columns.2.y, world.columns.2.z)).determinant < 0

            guard let geometry = geometry(of: me, in: file) else { continue }
            let (positionsLocal, polygons, uvs) = geometry
            guard !polygons.isEmpty else { continue }

            // World, then Z-up → Y-up, then metres → mm.
            let positions: [SIMD3<Float>] = positionsLocal.map { p in
                let w = world * SIMD4(Double(p.x), Double(p.y), Double(p.z), 1)
                return SIMD3<Float>(Float(w.x * unitScale), Float(w.z * unitScale), Float(-w.y * unitScale))
            }

            // Materials by slot: the mesh's own list, else the object's.
            let totcol = file.int(me, "Mesh", "totcol") ?? 0
            var slotMaterials: [RawMaterial?] = []
            if totcol > 0, let matBlock = file.deref(file.ptr(me, "Mesh", "mat"), from: me) {
                for address in file.pointerArray(matBlock, count: totcol) {
                    if let cached = materialCache[address] { slotMaterials.append(cached); continue }
                    let raw = file.deref(address, from: matBlock).map { material($0, in: file, siblings: siblings) }
                    if let raw { materialCache[address] = raw }
                    slotMaterials.append(raw)
                }
            }

            // One part per material slot actually used, like glTF primitives.
            var bySlot: [Int: [(Int, Int, Int)]] = [:]     // slot → corner triples (loop indices)
            for poly in polygons.polys {
                let loops = poly.loops
                guard loops.count >= 3 else { continue }
                for k in 1..<(loops.count - 1) {
                    bySlot[poly.materialSlot, default: []].append((loops[0], loops[k], loops[k + 1]))
                }
            }
            let usedSlots = bySlot.keys.sorted()
            for slot in usedSlots {
                let triangles = bySlot[slot]!
                // Split vertices by (vertex, uv) so a UV seam is a real seam.
                var indexOf: [Int64: UInt32] = [:]
                var outPositions: [SIMD3<Float>] = [], outUVs: [SIMD2<Float>] = [], outIndices: [UInt32] = []
                func corner(_ loop: Int) -> UInt32? {
                    guard loop < polygons.loopVertex.count else { return nil }
                    let v = polygons.loopVertex[loop]
                    guard v < positions.count else { return nil }
                    let uv = uvs.map { $0[loop] }
                    let key: Int64
                    if let uv {
                        // Quantise the UV to a hashable key: 1e-5 is finer than any texel.
                        key = Int64(v) << 40 ^ Int64(Int32((uv.x * 1e5).rounded())) << 20 ^ Int64(Int32((uv.y * 1e5).rounded())) & 0xFFFFF
                    } else {
                        key = Int64(v)
                    }
                    if let existing = indexOf[key] { return existing }
                    let idx = UInt32(outPositions.count)
                    indexOf[key] = idx
                    outPositions.append(positions[v])
                    if let uv { outUVs.append(SIMD2(uv.x, 1 - uv.y)) }   // Blender's UV origin is bottom-left
                    return idx
                }
                for (a, b, c) in triangles {
                    guard let ia = corner(a), let ib = corner(b), let ic = corner(c) else { continue }
                    if mirrored { outIndices += [ia, ic, ib] } else { outIndices += [ia, ib, ic] }
                }
                guard outIndices.count >= 3 else { continue }
                var mesh = RenderMesh(positions: outPositions,
                                      normals: MeshImportKit.computedNormals(positions: outPositions, indices: outIndices),
                                      indices: outIndices)
                if uvs != nil, outUVs.count == outPositions.count { mesh.texcoords = outUVs }
                var spec: BodyMaterialSpec?
                if slot < slotMaterials.count, let raw = slotMaterials[slot] {
                    spec = BodyMaterialSpec(baseColor: raw.color, metallic: 0, roughness: 0.5)
                    if mesh.texcoords != nil { spec?.baseColorTexture = raw.texture }
                }
                let partName = usedSlots.count > 1
                    ? "\(name) (\(slotMaterials.indices.contains(slot) ? (slotMaterials[slot]?.name ?? "slot \(slot + 1)") : "slot \(slot + 1)"))"
                    : name
                parts.append(ImportedPart(name: partName, mesh: mesh, material: spec))
            }
        }
        guard !parts.isEmpty else { throw MeshImportError.empty }
        return parts
    }

    private struct Polygons {
        struct Poly { let loops: [Int]; let materialSlot: Int }
        var polys: [Poly] = []
        var loopVertex: [Int] = []
        var isEmpty: Bool { polys.isEmpty }
    }

    // MARK: - Object transform

    /// Object → world. Up to 4.x the file carries `obmat[4][4]` (obmat[i] is
    /// column i). Blender 5 keeps that matrix at runtime only, so it's rebuilt
    /// from the saved channels the way BKE_object_where_is_calc does:
    /// (loc + dloc) · rotation (delta first, by rotmode) · (size × dscale),
    /// under the parent: parent world · parentinv · local.
    private static func worldMatrix(of ob: Block, in file: BlendFile, depth: Int = 0) -> simd_double4x4 {
        func matrix(_ m: [Float]) -> simd_double4x4 {
            simd_double4x4(columns: (
                SIMD4(Double(m[0]), Double(m[1]), Double(m[2]), Double(m[3])),
                SIMD4(Double(m[4]), Double(m[5]), Double(m[6]), Double(m[7])),
                SIMD4(Double(m[8]), Double(m[9]), Double(m[10]), Double(m[11])),
                SIMD4(Double(m[12]), Double(m[13]), Double(m[14]), Double(m[15]))))
        }
        if let m = file.floats(ob, "Object", "obmat"), m.count == 16 { return matrix(m) }
        guard file.structDef("Object")?.byName["loc"] != nil else { return matrix_identity_double4x4 }

        func vec(_ field: String, _ fallback: SIMD3<Double>) -> SIMD3<Double> {
            guard let v = file.floats(ob, "Object", field), v.count >= 3 else { return fallback }
            return SIMD3(Double(v[0]), Double(v[1]), Double(v[2]))
        }
        func scalar(_ field: String) -> Double { Double(file.floats(ob, "Object", field)?.first ?? 0) }
        let one = SIMD3<Double>(repeating: 1)
        let location = vec("loc", .zero) + vec("dloc", .zero)
        let scale = vec("size", one) * vec("dscale", one)
        let rotmode = file.int(ob, "Object", "rotmode") ?? 1
        let rotation: simd_double3x3
        if rotmode > 0 {
            rotation = eulerMatrix(vec("drot", .zero), mode: rotmode) * eulerMatrix(vec("rot", .zero), mode: rotmode)
        } else if rotmode == -1 {
            rotation = axisAngleMatrix(vec("drotAxis", SIMD3(0, 1, 0)), scalar("drotAngle"))
                * axisAngleMatrix(vec("rotAxis", SIMD3(0, 1, 0)), scalar("rotAngle"))
        } else {
            func quat(_ field: String) -> simd_quatd {
                guard let q = file.floats(ob, "Object", field), q.count >= 4 else { return simd_quatd(ix: 0, iy: 0, iz: 0, r: 1) }
                let raw = simd_quatd(ix: Double(q[1]), iy: Double(q[2]), iz: Double(q[3]), r: Double(q[0]))
                return simd_length(raw.vector) > 0 ? simd_normalize(raw) : simd_quatd(ix: 0, iy: 0, iz: 0, r: 1)
            }
            rotation = simd_double3x3(quat("dquat") * quat("quat"))
        }
        let linear = rotation * simd_double3x3(diagonal: scale)
        var local = matrix_identity_double4x4
        local.columns.0 = SIMD4(linear.columns.0, 0)
        local.columns.1 = SIMD4(linear.columns.1, 0)
        local.columns.2 = SIMD4(linear.columns.2, 0)
        local.columns.3 = SIMD4(location, 1)

        guard depth < 32, let parent = file.deref(file.ptr(ob, "Object", "parent"), from: ob),
              file.structName(of: parent) == "Object" else { return local }
        let parentInverse = file.floats(ob, "Object", "parentinv").flatMap { $0.count == 16 ? matrix($0) : nil }
            ?? matrix_identity_double4x4
        return worldMatrix(of: parent, in: file, depth: depth + 1) * parentInverse * local
    }

    /// Blender's eulO_to_mat3: rotmode 1…6 = XYZ, XZY, YXZ, YZX, ZXY, ZYX,
    /// the first axis applied first.
    private static func eulerMatrix(_ angles: SIMD3<Double>, mode: Int) -> simd_double3x3 {
        func axis(_ i: Int, _ a: Double) -> simd_double3x3 {
            let c = cos(a), s = sin(a)
            switch i {
            case 0: return simd_double3x3(rows: [SIMD3(1, 0, 0), SIMD3(0, c, -s), SIMD3(0, s, c)])
            case 1: return simd_double3x3(rows: [SIMD3(c, 0, s), SIMD3(0, 1, 0), SIMD3(-s, 0, c)])
            default: return simd_double3x3(rows: [SIMD3(c, -s, 0), SIMD3(s, c, 0), SIMD3(0, 0, 1)])
            }
        }
        let orders = [[0, 1, 2], [0, 2, 1], [1, 0, 2], [1, 2, 0], [2, 0, 1], [2, 1, 0]]
        let order = orders[min(max(mode, 1), 6) - 1]
        return axis(order[2], angles[order[2]]) * axis(order[1], angles[order[1]]) * axis(order[0], angles[order[0]])
    }

    private static func axisAngleMatrix(_ axis: SIMD3<Double>, _ angle: Double) -> simd_double3x3 {
        guard simd_length(axis) > 0, angle != 0 else { return matrix_identity_double3x3 }
        return simd_double3x3(simd_quatd(angle: angle, axis: simd_normalize(axis)))
    }

    /// Vertex positions (local), polygons with their corner loops, and per-loop
    /// UVs if the mesh has any — from whichever storage the file's version uses.
    private static func geometry(of me: Block, in file: BlendFile)
        -> (positions: [SIMD3<Float>], polygons: Polygons, uvs: [SIMD2<Float>]?)? {
        let totvert = file.int(me, "Mesh", "totvert") ?? 0
        let totpoly = file.int(me, "Mesh", "totpoly") ?? 0
        let totloop = file.int(me, "Mesh", "totloop") ?? 0
        guard totvert > 0, totpoly > 0, totloop > 0 else { return nil }
        // Blender 5+: generic attributes moved from CustomData to AttributeStorage.
        let stored = file.attributes(me, "Mesh", "attribute_storage")

        // Positions: MVert.co (≤ 3.4) or the "position" float3 vertex layer (3.5+).
        var positions: [SIMD3<Float>] = []
        if let mv = file.deref(file.ptr(me, "Mesh", "mvert"), from: me), file.structDef("MVert")?.byName["co"] != nil {
            positions.reserveCapacity(totvert)
            for i in 0..<totvert {
                guard let co = file.floats(mv, "MVert", "co", index: i), co.count >= 3 else { break }
                positions.append(SIMD3(co[0], co[1], co[2]))
            }
        } else if let data = file.layers(me, "Mesh", "vdata").first(where: { $0.type == cdPropFloat3 && $0.name == "position" })?.data
                    ?? stored.first(where: { $0.type == attrFloat3 && $0.domain == domainPoint && $0.name == "position" && !$0.single })?.values,
                  data.size >= 12 * totvert {
            positions = (0..<totvert).map { i in
                SIMD3(file.f32(data.dataOffset + 12 * i), file.f32(data.dataOffset + 12 * i + 4), file.f32(data.dataOffset + 12 * i + 8))
            }
        }
        guard positions.count == totvert else { return nil }

        // Corner → vertex: MLoop.v (≤ 3.5) or the ".corner_vert" int layer (3.6+).
        var loopVertex: [Int] = []
        if let ml = file.deref(file.ptr(me, "Mesh", "mloop"), from: me), file.structDef("MLoop")?.byName["v"] != nil {
            loopVertex = (0..<totloop).map { file.int(ml, "MLoop", "v", index: $0) ?? 0 }
        } else if let data = file.layers(me, "Mesh", "ldata").first(where: { $0.type == cdPropInt32 && $0.name == ".corner_vert" })?.data
                    ?? stored.first(where: { $0.type == attrInt32 && $0.domain == domainCorner && $0.name == ".corner_vert" && !$0.single })?.values,
                  data.size >= 4 * totloop {
            loopVertex = (0..<totloop).map { Int(file.i32(data.dataOffset + 4 * $0)) }
        }
        guard loopVertex.count == totloop else { return nil }

        // Polygons: MPoly (loopstart/totloop/mat_nr, ≤ 3.5) or poly_offset_indices
        // (3.6+) with the "material_index" int face layer.
        var polygons = Polygons()
        polygons.loopVertex = loopVertex
        if let mp = file.deref(file.ptr(me, "Mesh", "mpoly"), from: me), file.structDef("MPoly")?.byName["loopstart"] != nil {
            for i in 0..<totpoly {
                let start = file.int(mp, "MPoly", "loopstart", index: i) ?? 0
                let count = file.int(mp, "MPoly", "totloop", index: i) ?? 0
                let slot = file.int(mp, "MPoly", "mat_nr", index: i) ?? 0
                guard start >= 0, count >= 3, start + count <= totloop else { continue }
                polygons.polys.append(.init(loops: Array(start..<start + count), materialSlot: max(slot, 0)))
            }
        } else if let offsets = file.deref(file.ptr(me, "Mesh", "poly_offset_indices"), from: me) {
            let layerSlots = file.layers(me, "Mesh", "pdata").first(where: { $0.type == cdPropInt32 && $0.name == "material_index" })?.data
            let storedSlots = stored.first(where: { $0.type == attrInt32 && $0.domain == domainFace && $0.name == "material_index" })
            for i in 0..<totpoly {
                let start = Int(file.i32(offsets.dataOffset + 4 * i))
                let end = Int(file.i32(offsets.dataOffset + 4 * (i + 1)))
                let slot: Int
                if let layerSlots {
                    slot = Int(file.i32(layerSlots.dataOffset + 4 * i))
                } else if let storedSlots, let values = storedSlots.values {
                    slot = Int(file.i32(values.dataOffset + (storedSlots.single ? 0 : 4 * i)))
                } else {
                    slot = 0
                }
                guard start >= 0, end - start >= 3, end <= totloop else { continue }
                polygons.polys.append(.init(loops: Array(start..<end), materialSlot: max(slot, 0)))
            }
        }
        guard !polygons.isEmpty else { return nil }

        // UVs per corner: Mesh.mloopuv, a CD_MLOOPUV layer, or a float2 layer.
        var uvs: [SIMD2<Float>]?
        if let muv = file.deref(file.ptr(me, "Mesh", "mloopuv"), from: me), file.structDef("MLoopUV")?.byName["uv"] != nil {
            uvs = (0..<totloop).map { i in
                let uv = file.floats(muv, "MLoopUV", "uv", index: i) ?? [0, 0]
                return SIMD2(uv[0], uv.count > 1 ? uv[1] : 0)
            }
        } else {
            let layers = file.layers(me, "Mesh", "ldata")
            if let layer = layers.first(where: { $0.type == cdMLoopUV }), let data = layer.data,
               let stride = file.structDef("MLoopUV")?.size, stride >= 8 {
                uvs = (0..<totloop).map { SIMD2(file.f32(data.dataOffset + stride * $0), file.f32(data.dataOffset + stride * $0 + 4)) }
            } else if let data = layers.first(where: { $0.type == cdPropFloat2 && !$0.name.hasPrefix(".") })?.data
                        ?? stored.first(where: { $0.type == attrFloat2 && $0.domain == domainCorner && !$0.name.hasPrefix(".") && !$0.single })?.values,
                      data.size >= 8 * totloop {
                uvs = (0..<totloop).map { SIMD2(file.f32(data.dataOffset + 8 * $0), file.f32(data.dataOffset + 8 * $0 + 4)) }
            }
        }
        return (positions, polygons, uvs)
    }

    /// Slot colour and base-colour image for a Material block.
    private static func material(_ ma: Block, in file: BlendFile, siblings: [String: Data]) -> RawMaterial {
        let name = file.idName(ma, "Material")
        let r = Double(file.floats(ma, "Material", "r")?.first ?? 0.8)
        let g = Double(file.floats(ma, "Material", "g")?.first ?? 0.8)
        let b = Double(file.floats(ma, "Material", "b")?.first ?? 0.8)
        let alpha = Double(file.floats(ma, "Material", "alpha")?.first ?? 1)
        var raw = RawMaterial(name: name, color: SIMD4(r, g, b, alpha > 0 ? alpha : 1), texture: nil)

        var image: Block?
        // 2.7x: texture slots — the first colour-mapped image texture.
        if let mtexField = file.structDef("Material")?.byName["mtex"], mtexField.isPointer {
            let base = ma.dataOffset + mtexField.offset
            for i in 0..<mtexField.arrayCount where image == nil {
                guard let mtex = file.deref(file.pointer(base + i * file.pointerSize), from: ma),
                      let tex = file.deref(file.ptr(mtex, "MTex", "tex"), from: mtex),
                      (file.int(mtex, "MTex", "mapto") ?? 1) & 1 != 0,
                      file.int(tex, "Tex", "type") == 8,                // TEX_IMAGE
                      let ima = file.deref(file.ptr(tex, "Tex", "ima"), from: tex) else { continue }
                image = ima
            }
        }
        // 2.8+: the node tree's first Image Texture node.
        if image == nil, let tree = file.deref(file.ptr(ma, "Material", "nodetree"), from: ma),
           let nodesField = file.structDef("bNodeTree")?.byName["nodes"], let listBase = file.structDef("ListBase"),
           let firstField = listBase.byName["first"], let nodeDef = file.structDef("bNode"),
           nodeDef.byName["next"] != nil {
            var node = file.deref(file.pointer(tree.dataOffset + nodesField.offset + firstField.offset), from: tree)
            var guardCount = 0
            while let current = node, guardCount < 512, image == nil {
                guardCount += 1
                let idname = file.string(current, "bNode", "idname") ?? ""
                if idname == "ShaderNodeTexImage", let ima = file.deref(file.ptr(current, "bNode", "id"), from: current),
                   file.structName(of: ima) == "Image" {
                    image = ima
                }
                node = file.deref(file.ptr(current, "bNode", "next"), from: current)
            }
        }
        if let image {
            raw.texture = imageData(image, in: file, siblings: siblings)
        }
        return raw
    }

    /// The image's bytes: packed inside the .blend, or a file that came along.
    private static func imageData(_ ima: Block, in file: BlendFile, siblings: [String: Data]) -> Data? {
        if let packed = file.deref(file.ptr(ima, "Image", "packedfile"), from: ima),
           let size = file.int(packed, "PackedFile", "size"), size > 0,
           let data = file.deref(file.ptr(packed, "PackedFile", "data"), from: packed), data.size >= size {
            return Data(file.bytes[data.dataOffset..<data.dataOffset + size])
        }
        // 2.8+ keeps a list of packed files (tiles / views); take the first.
        if let listField = file.structDef("Image")?.byName["packedfiles"], let listBase = file.structDef("ListBase"),
           let firstField = listBase.byName["first"],
           let entry = file.deref(file.pointer(ima.dataOffset + listField.offset + firstField.offset), from: ima),
           let packed = file.deref(file.ptr(entry, "ImagePackedFile", "packedfile"), from: entry),
           let size = file.int(packed, "PackedFile", "size"), size > 0,
           let data = file.deref(file.ptr(packed, "PackedFile", "data"), from: packed), data.size >= size {
            return Data(file.bytes[data.dataOffset..<data.dataOffset + size])
        }
        let path = (file.string(ima, "Image", "filepath") ?? file.string(ima, "Image", "name") ?? "")
            .replacingOccurrences(of: "\\", with: "/")
        let trimmed = path.hasPrefix("//") ? String(path.dropFirst(2)) : path
        return trimmed.isEmpty ? nil : MeshImportKit.sibling(trimmed, in: siblings)
    }
}
