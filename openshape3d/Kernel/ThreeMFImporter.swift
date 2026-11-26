//
//  ThreeMFImporter.swift
//  openshape3d
//
//  3MF import (#137): the format the app itself exports, and what slicers
//  save. A 3MF file is a zip; the model is XML at `3D/3dmodel.model`:
//
//    <model unit="millimeter">
//      <resources>
//        <basematerials id="5"><base name="Red" displaycolor="#FF0000"/></basematerials>
//        <object id="1" name="Lid" pid="5" pindex="0">
//          <mesh><vertices><vertex x y z/>…</vertices>
//                <triangles><triangle v1 v2 v3 [pid p1]/>…</triangles></mesh>
//        </object>
//        <object id="2"><components><component objectid="1" transform="…"/></components></object>
//      </resources>
//      <build><item objectid="2" transform="…"/></build>
//    </model>
//
//  Read here: mesh objects, components (assemblies, also across model files
//  — the Production extension's `p:path`, which Bambu and Prusa projects
//  use), build-item and component transforms, the declared unit, object
//  names, and colours from `<basematerials>` and the Materials extension's
//  `<m:colorgroup>`, per object or per triangle. One part per build item and
//  colour, as the .blend reader splits by material. Textures, multi-
//  properties and beam lattices are ignored.
//
//  3MF is Z-up; parts come out Y-up like every other importer's. The app's
//  own plain export writes the design as modelled (Y-up) and says so in a
//  metadata entry, so that file comes back exactly as it left.
//
//  The XML is scanned by hand: Foundation's XMLParser is not available to
//  the WebAssembly build that shares this file, and a model is nothing but
//  flat elements with attributes.
//

import Foundation
import simd

nonisolated enum ThreeMFImporter {

    /// The metadata entry the app's own exporter writes when the mesh is in
    /// the design's Y-up frame instead of 3MF's Z-up.
    static let upAxisMetadataName = "os3d:UpAxis"

    /// Parts in the FILE's units, and millimetres per file unit.
    static func parts(from data: Data, fileName: String = "") throws -> (parts: [ImportedPart], millimetresPerUnit: Double) {
        let entries: [String: Data]
        do { entries = try ZipReader.entries(in: data) } catch {
            throw MeshImportError.malformed("3mf: not a zip archive")
        }
        // Paths compare without a leading slash, case-insensitively.
        var models: [String: Data] = [:]
        for (path, bytes) in entries where (path as NSString).pathExtension.lowercased() == "model" {
            models[normalized(path)] = bytes
        }
        guard let rootPath = models.keys.first(where: { $0 == "3d/3dmodel.model" })
            ?? models.keys.sorted().first(where: { !$0.contains("/objects/") })
            ?? models.keys.sorted().first else {
            throw MeshImportError.malformed("3mf: no 3D model part in the archive")
        }

        var parsed: [String: Model] = [:]
        func model(_ path: String) -> Model? {
            if let done = parsed[path] { return done }
            guard let bytes = models[path] else { return nil }
            let m = parse([UInt8](bytes))
            parsed[path] = m
            return m
        }
        guard let root = model(rootPath) else { throw MeshImportError.malformed("3mf: unreadable model part") }

        // What to build: the build items, or every mesh object when a file
        // has no <build> (not valid 3MF, but harmless to accept).
        var items = root.build
        if items.isEmpty {
            items = root.objects.keys.sorted().map { Reference(path: nil, id: $0, transform: matrix_identity_double4x4) }
        }

        // 3MF is Z-up, right-handed: (x, y, z) → (x, z, −y) is Y-up.
        let toYUp = root.yUp ? matrix_identity_double4x4 : simd_double4x4(columns: (
            SIMD4(1, 0, 0, 0), SIMD4(0, 0, -1, 0), SIMD4(0, 1, 0, 0), SIMD4(0, 0, 0, 1)))

        let stem = ((fileName as NSString).lastPathComponent as NSString).deletingPathExtension
        var parts: [ImportedPart] = []
        var usedNames: [String: Int] = [:]
        for (index, item) in items.enumerated() {
            var groups: [MaterialKey: Group] = [:]
            var order: [MaterialKey] = []
            var name: String?
            var budget = 4096   // components visited, against cyclic or exploding references
            collect(item, in: rootPath, world: toYUp * item.transform, model: model, depth: 0,
                    budget: &budget, name: &name, groups: &groups, order: &order)
            let base = name ?? (items.count == 1 && !stem.isEmpty ? stem : "Part \(index + 1)")
            for key in order {
                guard let group = groups[key], let mesh = weldedMesh(corners: group.corners) else { continue }
                var partName = base
                if order.count > 1, let materialName = key.name, !materialName.isEmpty { partName += " " + materialName }
                usedNames[partName, default: 0] += 1
                if let n = usedNames[partName], n > 1 { partName += " \(n)" }
                parts.append(ImportedPart(
                    name: partName, mesh: mesh,
                    material: key.color.map { BodyMaterialSpec(baseColor: $0, metallic: 0, roughness: 0.5) }))
            }
        }
        guard !parts.isEmpty else { throw MeshImportError.empty }
        return (parts, root.millimetresPerUnit)
    }

    // MARK: - Model

    private struct Reference {
        var path: String?
        var id: Int
        var transform: simd_double4x4
    }

    private struct Object {
        var name: String?
        var pid: Int?
        var pindex: Int?
        var vertices: [SIMD3<Double>] = []
        var triangles: [SIMD3<Int32>] = []
        /// Per triangle: its own property group and index, −1 for "the object's".
        var trianglePID: [Int32] = []
        var triangleP1: [Int32] = []
        var components: [Reference] = []
    }

    private struct Property {
        var color: SIMD4<Double>
        var name: String?
    }

    private struct Model {
        var millimetresPerUnit = 1.0
        var yUp = false
        /// Property groups (<basematerials>, <m:colorgroup>) by resource id.
        var properties: [Int: [Property]] = [:]
        var objects: [Int: Object] = [:]
        var build: [Reference] = []
    }

    private struct MaterialKey: Hashable {
        var color: SIMD4<Double>?
        var name: String?
    }

    private struct Group {
        var corners: [SIMD3<Double>] = []
    }

    // MARK: - Flattening

    private static func collect(_ reference: Reference, in currentPath: String, world: simd_double4x4,
                                model: (String) -> Model?, depth: Int, budget: inout Int, name: inout String?,
                                groups: inout [MaterialKey: Group], order: inout [MaterialKey]) {
        let path = reference.path.map(normalized) ?? currentPath
        guard depth < 16, budget > 0, let source = model(path), let object = source.objects[reference.id] else { return }
        budget -= 1
        if name == nil, let own = object.name, !own.isEmpty { name = own }

        if !object.triangles.isEmpty {
            // A mirrored placement turns the triangles inside out.
            let linear = simd_double3x3(
                SIMD3(world.columns.0.x, world.columns.0.y, world.columns.0.z),
                SIMD3(world.columns.1.x, world.columns.1.y, world.columns.1.z),
                SIMD3(world.columns.2.x, world.columns.2.y, world.columns.2.z))
            let flipped = simd_determinant(linear) < 0
            let placed = object.vertices.map { v -> SIMD3<Double> in
                let w = world * SIMD4(v.x, v.y, v.z, 1)
                return SIMD3(w.x, w.y, w.z)
            }
            func key(pid: Int?, index: Int?) -> MaterialKey {
                guard let pid, let index, let group = source.properties[pid], group.indices.contains(index) else {
                    return MaterialKey(color: nil, name: nil)
                }
                return MaterialKey(color: group[index].color, name: group[index].name)
            }
            let objectKey = key(pid: object.pid, index: object.pindex)
            var lastPID: Int32 = -2, lastP1: Int32 = -2
            var lastKey = objectKey
            for (t, tri) in object.triangles.enumerated() {
                let a = Int(tri.x), b = Int(tri.y), c = Int(tri.z)
                guard a >= 0, b >= 0, c >= 0, a < placed.count, b < placed.count, c < placed.count else { continue }
                let pid = object.trianglePID[t], p1 = object.triangleP1[t]
                if pid != lastPID || p1 != lastP1 {
                    lastPID = pid; lastP1 = p1
                    // A triangle's `p1` without `pid` indexes the object's group.
                    lastKey = p1 < 0 ? objectKey : key(pid: pid >= 0 ? Int(pid) : object.pid, index: Int(p1))
                }
                if groups[lastKey] == nil { groups[lastKey] = Group(); order.append(lastKey) }
                groups[lastKey]!.corners.append(contentsOf: flipped ? [placed[a], placed[c], placed[b]]
                                                                     : [placed[a], placed[b], placed[c]])
            }
        }
        for component in object.components {
            collect(component, in: path, world: world * component.transform, model: model, depth: depth + 1,
                    budget: &budget, name: &name, groups: &groups, order: &order)
        }
    }

    /// One vertex per position-and-face-normal, so flat faces stay flat and a
    /// cube's corners are not smoothed — as the OBJ and STL readers weld.
    private static func weldedMesh(corners: [SIMD3<Double>]) -> RenderMesh? {
        struct Key: Hashable { var p: SIMD3<Int64>; var n: SIMD3<Int32> }
        var positions: [SIMD3<Float>] = []
        var normals: [SIMD3<Float>] = []
        var indices: [UInt32] = []
        var lookup: [Key: UInt32] = [:]
        var i = 0
        while i + 2 < corners.count {
            let a = corners[i], b = corners[i + 1], c = corners[i + 2]
            i += 3
            let cross = simd_cross(b - a, c - a)
            let lengthSquared = simd_length_squared(cross)
            guard lengthSquared > 1e-24, lengthSquared.isFinite else { continue }
            let normal = cross / lengthSquared.squareRoot()
            let n = SIMD3<Int32>(Int32((normal.x * 1000).rounded()), Int32((normal.y * 1000).rounded()),
                                 Int32((normal.z * 1000).rounded()))
            for corner in [a, b, c] {
                guard abs(corner.x) < 1e12, abs(corner.y) < 1e12, abs(corner.z) < 1e12 else { return nil }
                let key = Key(p: SIMD3(Int64((corner.x * 1e5).rounded()), Int64((corner.y * 1e5).rounded()),
                                       Int64((corner.z * 1e5).rounded())), n: n)
                if let existing = lookup[key] {
                    indices.append(existing)
                } else {
                    let index = UInt32(positions.count)
                    lookup[key] = index
                    positions.append(SIMD3<Float>(corner))
                    normals.append(SIMD3<Float>(normal))
                    indices.append(index)
                }
            }
        }
        guard !indices.isEmpty else { return nil }
        return RenderMesh(positions: positions, normals: normals, indices: indices)
    }

    // MARK: - Parsing

    private static func normalized(_ path: String) -> String {
        var p = path.replacingOccurrences(of: "\\", with: "/").lowercased()
        while p.hasPrefix("/") { p.removeFirst() }
        return p
    }

    private static func parse(_ bytes: [UInt8]) -> Model {
        var model = Model()
        var object: Object?
        var objectID: Int?
        var group: Int?
        var scanner = XMLScanner(bytes)
        while let tag = scanner.next() {
            switch tag.name {
            case "model" where !tag.closing:
                model.millimetresPerUnit = millimetres(perUnit: tag["unit"])
            case "metadata" where !tag.closing:
                if tag["name"] == upAxisMetadataName, !tag.selfClosing {
                    model.yUp = scanner.text().trimmingCharacters(in: .whitespacesAndNewlines).uppercased() == "Y"
                }
            case "basematerials", "colorgroup":
                group = tag.closing ? nil : tag["id"].flatMap { Int($0) }
                if let group, !tag.closing { model.properties[group] = [] }
            case "base" where !tag.closing:
                if let group, let color = color(tag["displaycolor"]) {
                    model.properties[group]?.append(Property(color: color, name: tag["name"]))
                }
            case "color" where !tag.closing:
                if let group, let color = color(tag["color"]) {
                    model.properties[group]?.append(Property(color: color, name: nil))
                }
            case "object":
                if tag.closing || tag.selfClosing {
                    if let id = objectID, let finished = object { model.objects[id] = finished }
                    object = nil; objectID = nil
                }
                if !tag.closing {
                    objectID = tag["id"].flatMap { Int($0) }
                    var fresh = Object()
                    fresh.name = tag["name"]
                    fresh.pid = tag["pid"].flatMap { Int($0) }
                    fresh.pindex = tag["pindex"].flatMap { Int($0) }
                    if tag.selfClosing {
                        if let id = objectID { model.objects[id] = fresh }
                        objectID = nil
                    } else {
                        object = fresh
                    }
                }
            case "vertex" where !tag.closing:
                object?.vertices.append(SIMD3(tag.double("x"), tag.double("y"), tag.double("z")))
            case "triangle" where !tag.closing:
                guard object != nil else { break }
                object!.triangles.append(SIMD3(tag.int32("v1"), tag.int32("v2"), tag.int32("v3")))
                object!.trianglePID.append(tag["pid"] == nil ? -1 : tag.int32("pid"))
                object!.triangleP1.append(tag["p1"] == nil ? -1 : tag.int32("p1"))
            case "component" where !tag.closing:
                if let id = tag["objectid"].flatMap({ Int($0) }) {
                    object?.components.append(Reference(path: tag["path"], id: id, transform: transform(tag["transform"])))
                }
            case "item" where !tag.closing:
                if let id = tag["objectid"].flatMap({ Int($0) }) {
                    model.build.append(Reference(path: tag["path"], id: id, transform: transform(tag["transform"])))
                }
            default:
                break
            }
        }
        return model
    }

    private static func millimetres(perUnit unit: String?) -> Double {
        switch (unit ?? "millimeter").lowercased() {
        case "micron": return 0.001
        case "centimeter": return 10
        case "inch": return 25.4
        case "foot": return 304.8
        case "meter": return 1000
        default: return 1
        }
    }

    /// `#RRGGBB` or `#RRGGBBAA`, as the app's exporter writes its colours.
    static func color(_ text: String?) -> SIMD4<Double>? {
        guard let text, text.hasPrefix("#") else { return nil }
        let hex = Array(text.dropFirst().utf8)
        guard hex.count == 6 || hex.count == 8 else { return nil }
        func nibble(_ c: UInt8) -> Int? {
            switch c {
            case UInt8(ascii: "0")...UInt8(ascii: "9"): return Int(c - UInt8(ascii: "0"))
            case UInt8(ascii: "a")...UInt8(ascii: "f"): return Int(c - UInt8(ascii: "a")) + 10
            case UInt8(ascii: "A")...UInt8(ascii: "F"): return Int(c - UInt8(ascii: "A")) + 10
            default: return nil
            }
        }
        var channels: [Double] = []
        var i = 0
        while i + 1 < hex.count {
            guard let hi = nibble(hex[i]), let lo = nibble(hex[i + 1]) else { return nil }
            channels.append(Double(hi * 16 + lo) / 255)
            i += 2
        }
        return SIMD4(channels[0], channels[1], channels[2], channels.count == 4 ? channels[3] : 1)
    }

    /// A 3MF matrix: twelve numbers, row-major 4×3, applied to ROW vectors
    /// (x′ = x·m00 + y·m10 + z·m20 + m30). Returned for column vectors.
    static func transform(_ text: String?) -> simd_double4x4 {
        guard let text else { return matrix_identity_double4x4 }
        let m = text.split(whereSeparator: { $0 == " " || $0 == "\t" || $0 == "\n" || $0 == "\r" }).compactMap { Double($0) }
        guard m.count == 12, m.allSatisfy(\.isFinite) else { return matrix_identity_double4x4 }
        return simd_double4x4(columns: (
            SIMD4(m[0], m[1], m[2], 0), SIMD4(m[3], m[4], m[5], 0),
            SIMD4(m[6], m[7], m[8], 0), SIMD4(m[9], m[10], m[11], 1)))
    }
}

// MARK: - A minimal XML tag scanner

/// Walks the tags of an XML document: names without their namespace prefix,
/// attributes (prefix dropped too, entities decoded), and on request the
/// text after a tag. Comments, processing instructions, DOCTYPE and CDATA
/// are skipped. Enough for 3MF model parts; not a general XML parser.
nonisolated struct XMLScanner {
    struct Tag {
        var name: String
        var closing: Bool
        var selfClosing: Bool
        var attributes: [(name: String, value: String)]

        subscript(_ name: String) -> String? { attributes.first(where: { $0.name == name })?.value }
        func double(_ name: String) -> Double { self[name].flatMap { Double($0) } ?? 0 }
        func int32(_ name: String) -> Int32 { self[name].flatMap { Int32($0) } ?? -1 }
    }

    private let bytes: [UInt8]
    private var at = 0

    init(_ bytes: [UInt8]) { self.bytes = bytes }

    /// The text from here to the next tag, entities decoded.
    mutating func text() -> String {
        let start = at
        while at < bytes.count, bytes[at] != UInt8(ascii: "<") { at += 1 }
        return Self.decoded(bytes[start..<at])
    }

    mutating func next() -> Tag? {
        while at < bytes.count {
            guard bytes[at] == UInt8(ascii: "<") else { at += 1; continue }
            at += 1
            guard at < bytes.count else { return nil }
            if bytes[at] == UInt8(ascii: "?") { skip(past: [UInt8(ascii: "?"), UInt8(ascii: ">")]); continue }
            if bytes[at] == UInt8(ascii: "!") {
                if matches("!--") { skip(past: Array("-->".utf8)) }
                else if matches("![CDATA[") { skip(past: Array("]]>".utf8)) }
                else { skip(past: [UInt8(ascii: ">")]) }
                continue
            }
            var closing = false
            if bytes[at] == UInt8(ascii: "/") { closing = true; at += 1 }
            let name = localName(until: { $0 == UInt8(ascii: ">") || $0 == UInt8(ascii: "/") || Self.isSpace($0) })
            var attributes: [(name: String, value: String)] = []
            var selfClosing = false
            while at < bytes.count {
                while at < bytes.count, Self.isSpace(bytes[at]) { at += 1 }
                guard at < bytes.count else { break }
                if bytes[at] == UInt8(ascii: ">") { at += 1; break }
                if bytes[at] == UInt8(ascii: "/") { selfClosing = true; at += 1; continue }
                let attribute = localName(until: { $0 == UInt8(ascii: "=") || $0 == UInt8(ascii: ">") || Self.isSpace($0) })
                while at < bytes.count, Self.isSpace(bytes[at]) { at += 1 }
                guard at < bytes.count, bytes[at] == UInt8(ascii: "=") else { continue }
                at += 1
                while at < bytes.count, Self.isSpace(bytes[at]) { at += 1 }
                guard at < bytes.count, bytes[at] == UInt8(ascii: "\"") || bytes[at] == UInt8(ascii: "'") else { continue }
                let quote = bytes[at]
                at += 1
                let start = at
                while at < bytes.count, bytes[at] != quote { at += 1 }
                attributes.append((attribute, Self.decoded(bytes[start..<at])))
                if at < bytes.count { at += 1 }
            }
            return Tag(name: name, closing: closing, selfClosing: selfClosing, attributes: attributes)
        }
        return nil
    }

    private mutating func localName(until stop: (UInt8) -> Bool) -> String {
        var start = at
        while at < bytes.count, !stop(bytes[at]) {
            if bytes[at] == UInt8(ascii: ":") { start = at + 1 }
            at += 1
        }
        return String(decoding: bytes[start..<at], as: UTF8.self)
    }

    private func matches(_ text: String) -> Bool {
        let wanted = Array(text.utf8)
        return at + wanted.count <= bytes.count && Array(bytes[at..<at + wanted.count]) == wanted
    }

    private mutating func skip(past marker: [UInt8]) {
        while at < bytes.count {
            if bytes[at] == marker[0], at + marker.count <= bytes.count,
               Array(bytes[at..<at + marker.count]) == marker {
                at += marker.count
                return
            }
            at += 1
        }
    }

    private static func isSpace(_ b: UInt8) -> Bool { b == 0x20 || b == 0x09 || b == 0x0A || b == 0x0D }

    private static func decoded(_ slice: ArraySlice<UInt8>) -> String {
        let raw = String(decoding: slice, as: UTF8.self)
        guard raw.contains("&") else { return raw }
        var out = ""
        var rest = Substring(raw)
        while let amp = rest.firstIndex(of: "&") {
            out += rest[..<amp]
            let after = rest[rest.index(after: amp)...]
            guard let semi = after.firstIndex(of: ";"), after.distance(from: after.startIndex, to: semi) <= 10 else {
                out += "&"; rest = after; continue
            }
            let entity = after[..<semi]
            switch entity {
            case "amp": out += "&"
            case "lt": out += "<"
            case "gt": out += ">"
            case "quot": out += "\""
            case "apos": out += "'"
            default:
                var scalar: UInt32?
                if entity.hasPrefix("#x") || entity.hasPrefix("#X") { scalar = UInt32(entity.dropFirst(2), radix: 16) }
                else if entity.hasPrefix("#") { scalar = UInt32(entity.dropFirst()) }
                if let scalar, let unicode = Unicode.Scalar(scalar) { out.unicodeScalars.append(unicode) }
                else { out += "&" + entity + ";" }
            }
            rest = after[after.index(after: semi)...]
        }
        return out + rest
    }
}
