//
//  ThreeMFExporter.swift
//  openshape3d
//
//  Minimal valid 3MF: an OPC zip with [Content_Types].xml, _rels/.rels and
//  3D/3dmodel.model. No zip library is available on this target, so the file
//  also carries a minimal STORED-entry zip writer (no compression, CRC32 +
//  central directory). Transforms are baked; unit is millimeter per the
//  1 unit = 1 mm convention.
//
//  3MF is Z-up. The plain export writes the design as it is modelled (Y-up)
//  and says so in an `os3d:UpAxis` metadata entry, which `ThreeMFImporter`
//  reads so the file comes back as it left; a file already turned Z-up (the
//  slicer export, `up=z`) carries no entry and is standard 3MF.
//

import Foundation
import simd

nonisolated enum ThreeMFExporter {

    /// `yUp`: the bodies are in the design's own Y-up frame (the default);
    /// false when they were already turned to 3MF's Z-up.
    static func threeMF(bodies: [Body], yUp: Bool = true) -> Data {
        var zip = MinimalZipWriter()
        zip.addFile(path: "[Content_Types].xml", data: Data(contentTypesXML.utf8))
        zip.addFile(path: "_rels/.rels", data: Data(relsXML.utf8))
        zip.addFile(path: "3D/3dmodel.model", data: Data(modelXML(bodies: bodies, yUp: yUp).utf8))
        return zip.finish()
    }

    /// The namespace of the app's own metadata (3MF wants custom names
    /// qualified).
    static let metadataNamespace = "https://openshape3d.com/3mf/2026/11"

    private static let contentTypesXML = """
    <?xml version="1.0" encoding="UTF-8"?>
    <Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
    <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
    <Default Extension="model" ContentType="application/vnd.ms-package.3dmanufacturing-3dmodel+xml"/>
    </Types>
    """

    private static let relsXML = """
    <?xml version="1.0" encoding="UTF-8"?>
    <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
    <Relationship Id="rel0" Target="/3D/3dmodel.model" Type="http://schemas.microsoft.com/3dmanufacturing/2013/01/3dmodel"/>
    </Relationships>
    """

    /// Core-spec 3MF: one `<basematerials>` group with each distinct
    /// body or face material as a named `<base>` with its `displaycolor`;
    /// each body an `<object>` with its name, its own material as the
    /// object default (`pid`/`pindex`) and painted faces as per-triangle `p1`.
    static func modelXML(bodies: [Body], yUp: Bool = true) -> String {
        let table = ExportMaterials.table(for: bodies)
        // Objects keep ids 1…n; the material group takes the next id and is
        // written first, since a resource must be defined before it's used.
        let materialsID = bodies.count + 1
        var out = """
        <?xml version="1.0" encoding="UTF-8"?>
        <model unit="millimeter" xml:lang="en-US" xmlns="http://schemas.microsoft.com/3dmanufacturing/core/2015/02" xmlns:os3d="\(metadataNamespace)">
        <metadata name="Application">OpenShape3D</metadata>
        """
        out += "\n"
        if yUp { out += "<metadata name=\"\(ThreeMFImporter.upAxisMetadataName)\">Y</metadata>\n" }
        out += "<resources>\n"
        if !table.materials.isEmpty {
            out += "<basematerials id=\"\(materialsID)\">\n"
            for (i, spec) in table.materials.enumerated() {
                out += "<base name=\"\(escaped(table.names[i]))\" displaycolor=\"\(ExportMaterials.hex(spec))\"/>\n"
            }
            out += "</basematerials>\n"
        }
        for (index, body) in bodies.enumerated() {
            let objectID = index + 1
            let groups = table.groups[index]
            var attributes = "id=\"\(objectID)\" name=\"\(escaped(body.name))\" type=\"model\""
            var owner: [Int] = []
            if let first = groups.first {
                attributes += " pid=\"\(materialsID)\" pindex=\"\(first.material)\""
                if groups.count > 1 {
                    owner = [Int](repeating: first.material, count: body.render.triangleCount)
                    for group in groups.dropFirst() { for t in group.triangles { owner[t] = group.material } }
                }
            }
            out += "<object \(attributes)>\n<mesh>\n<vertices>\n"
            let transform = body.transform
            for p in body.render.positions {
                let w = transform.applying(to: SIMD3<Double>(p))
                out += String(format: "<vertex x=\"%.6f\" y=\"%.6f\" z=\"%.6f\"/>\n", w.x, w.y, w.z)
            }
            out += "</vertices>\n<triangles>\n"
            let indices = body.render.indices
            var i = 0
            while i + 2 < indices.count {
                out += "<triangle v1=\"\(indices[i])\" v2=\"\(indices[i + 1])\" v3=\"\(indices[i + 2])\""
                let t = i / 3
                if t < owner.count, owner[t] != groups.first?.material {
                    out += " pid=\"\(materialsID)\" p1=\"\(owner[t])\""
                }
                out += "/>\n"
                i += 3
            }
            out += "</triangles>\n</mesh>\n</object>\n"
        }
        out += "</resources>\n<build>\n"
        for index in bodies.indices {
            out += "<item objectid=\"\(index + 1)\"/>\n"
        }
        out += "</build>\n</model>\n"
        return out
    }

    /// Text for an XML attribute value.
    static func escaped(_ text: String) -> String {
        var out = ""
        for ch in text {
            switch ch {
            case "&": out += "&amp;"
            case "<": out += "&lt;"
            case ">": out += "&gt;"
            case "\"": out += "&quot;"
            case "'": out += "&apos;"
            default:
                // XML 1.0 has no control characters but tab/newline.
                if let a = ch.asciiValue, a < 0x20, ch != "\t", ch != "\n" { continue }
                out.append(ch)
            }
        }
        return out
    }
}

/// Minimal zip writer emitting STORED (uncompressed) entries with correct
/// CRC32 values and a central directory. Sufficient for OPC consumers.
nonisolated struct MinimalZipWriter {

    private struct Entry {
        let name: [UInt8]
        let crc: UInt32
        let size: UInt32
        let offset: UInt32
    }

    private var data = Data()
    private var entries = [Entry]()

    /// `alignment`: start the file's bytes on a multiple of this many bytes
    /// from the archive's start (USDZ wants 64), by padding the local
    /// header's extra field.
    mutating func addFile(path: String, data fileData: Data, alignment: Int = 1) {
        let name = Array(path.utf8)
        let crc = Self.crc32(fileData)
        let size = UInt32(fileData.count)
        let entry = Entry(name: name, crc: crc, size: size, offset: UInt32(data.count))
        entries.append(entry)

        // An extra field is a 4-byte header (id, length) plus its data, so
        // 1–3 bytes of padding cannot be expressed: go to the next boundary.
        var extra: [UInt8] = []
        if alignment > 1 {
            var padding = (alignment - (data.count + 30 + name.count) % alignment) % alignment
            if padding > 0, padding < 4 { padding += alignment }
            if padding > 0 {
                let length = UInt16(padding - 4)
                extra = [0x86, 0x19, UInt8(length & 0xFF), UInt8(length >> 8)]   // id 0x1986, as USD's own writer pads
                    + [UInt8](repeating: 0, count: padding - 4)
            }
        }

        appendU32(0x0403_4B50)        // local file header signature
        appendU16(20)                 // version needed
        appendU16(0)                  // flags
        appendU16(0)                  // method: STORED
        appendU16(0)                  // mod time
        appendU16(0x21)               // mod date (1980-01-01)
        appendU32(crc)
        appendU32(size)               // compressed size == size (stored)
        appendU32(size)
        appendU16(UInt16(name.count))
        appendU16(UInt16(extra.count)) // extra length
        data.append(contentsOf: name)
        data.append(contentsOf: extra)
        data.append(fileData)
    }

    mutating func finish() -> Data {
        let centralOffset = UInt32(data.count)
        for entry in entries {
            appendU32(0x0201_4B50)    // central directory header signature
            appendU16(20)             // version made by
            appendU16(20)             // version needed
            appendU16(0)              // flags
            appendU16(0)              // method
            appendU16(0)              // mod time
            appendU16(0x21)           // mod date
            appendU32(entry.crc)
            appendU32(entry.size)
            appendU32(entry.size)
            appendU16(UInt16(entry.name.count))
            appendU16(0)              // extra length
            appendU16(0)              // comment length
            appendU16(0)              // disk number
            appendU16(0)              // internal attributes
            appendU32(0)              // external attributes
            appendU32(entry.offset)
            data.append(contentsOf: entry.name)
        }
        let centralSize = UInt32(data.count) - centralOffset
        appendU32(0x0605_4B50)        // end of central directory signature
        appendU16(0)                  // disk number
        appendU16(0)                  // central directory disk
        appendU16(UInt16(entries.count))
        appendU16(UInt16(entries.count))
        appendU32(centralSize)
        appendU32(centralOffset)
        appendU16(0)                  // comment length
        return data
    }

    private mutating func appendU16(_ value: UInt16) {
        withUnsafeBytes(of: value.littleEndian) { data.append(contentsOf: $0) }
    }

    private mutating func appendU32(_ value: UInt32) {
        withUnsafeBytes(of: value.littleEndian) { data.append(contentsOf: $0) }
    }

    /// Standard CRC-32 (IEEE 802.3, reflected, poly 0xEDB88320).
    static func crc32(_ data: Data) -> UInt32 {
        var crc: UInt32 = 0xFFFF_FFFF
        for byte in data {
            crc ^= UInt32(byte)
            for _ in 0..<8 {
                crc = (crc >> 1) ^ (0xEDB8_8320 & (0 &- (crc & 1)))
            }
        }
        return ~crc
    }
}
