//
//  IOTests.swift
//  openshape3dTests
//
//  Import/export breadth: STL import (binary + ASCII), OBJ export,
//  minimal 3MF (structural zip validation, no unzip tooling on iOS).
//

import XCTest
import simd
import Euclid
@testable import openshape3d

final class IOTests: XCTestCase {

    private func makeBox(size: Double = 2, at x: Double = 0, name: String = "Box") -> Body {
        var transform = Transform3D.identity
        transform.translation = SIMD3(x, 0, 0)
        return Body(
            name: name,
            transform: transform,
            primitive: .box(width: size, depth: size, height: size),
            euclidMesh: .primitive(.box(width: size, depth: size, height: size)),
            revision: 1
        )
    }

    // MARK: - STL import

    func testBinarySTLRoundTrip() throws {
        let data = STLExporter.binarySTL(bodies: [makeBox()])
        let mesh = try STLImporter.importSTL(data)
        XCTAssertEqual(mesh.triangleCount, 12, "Box round-trips as 12 triangles")

        let rebuilt = EuclidBridge.euclidMesh(from: mesh)
        XCTAssertTrue(rebuilt.isWatertight, "Imported box should be watertight after weld")
    }

    func testBinarySTLUnitScale() throws {
        let data = STLExporter.binarySTL(bodies: [makeBox(size: 2)])
        let mesh = try STLImporter.importSTL(data, unitScale: 0.5)
        let box = mesh.localAABB
        XCTAssertEqual(box.max.x - box.min.x, 1, accuracy: 1e-5)
        XCTAssertEqual(box.max.y - box.min.y, 1, accuracy: 1e-5)
    }

    func testASCIISTLParses() throws {
        let ascii = """
        solid tetra
          facet normal 0 0 -1
            outer loop
              vertex 0 0 0
              vertex 1 0 0
              vertex 0 1 0
            endloop
          endfacet
          facet normal 0 -1 0
            outer loop
              vertex 0 0 0
              vertex 0 0 1
              vertex 1 0 0
            endloop
          endfacet
          facet normal -1 0 0
            outer loop
              vertex 0 0 0
              vertex 0 1 0
              vertex 0 0 1
            endloop
          endfacet
          facet normal 1 1 1
            outer loop
              vertex 1 0 0
              vertex 0 0 1
              vertex 0 1 0
            endloop
          endfacet
        endsolid tetra
        """
        let mesh = try STLImporter.importSTL(Data(ascii.utf8))
        XCTAssertEqual(mesh.triangleCount, 4)
        XCTAssertTrue(EuclidBridge.euclidMesh(from: mesh).isWatertight)
    }

    func testImportedNormalsRecomputedFromWinding() throws {
        // Deliberately wrong facet normal; the importer must recompute it.
        let ascii = """
        solid one
          facet normal 1 0 0
            outer loop
              vertex 0 0 0
              vertex 1 0 0
              vertex 0 1 0
            endloop
          endfacet
        endsolid one
        """
        let mesh = try STLImporter.importSTL(Data(ascii.utf8))
        XCTAssertEqual(mesh.triangleCount, 1)
        let n = mesh.normals[0]
        XCTAssertEqual(n.x, 0, accuracy: 1e-6)
        XCTAssertEqual(n.y, 0, accuracy: 1e-6)
        XCTAssertEqual(n.z, 1, accuracy: 1e-6, "CCW winding in XY yields +Z normal")
    }

    func testMalformedSTLThrows() {
        XCTAssertThrowsError(try STLImporter.importSTL(Data([0x00, 0x01, 0x02, 0x03])))

        // Truncated binary: header claims 12 triangles but payload is missing.
        var truncated = Data(count: 80)
        withUnsafeBytes(of: UInt32(12).littleEndian) { truncated.append(contentsOf: $0) }
        truncated.append(Data(count: 30))
        XCTAssertThrowsError(try STLImporter.importSTL(truncated))

        // ASCII facet with only two vertices.
        let badASCII = """
        solid bad
          facet normal 0 0 1
            outer loop
              vertex 0 0 0
              vertex 1 0 0
            endloop
          endfacet
        endsolid bad
        """
        XCTAssertThrowsError(try STLImporter.importSTL(Data(badASCII.utf8)))
    }

    func testEmptySTLThrows() {
        var empty = Data(count: 80)
        withUnsafeBytes(of: UInt32(0).littleEndian) { empty.append(contentsOf: $0) }
        XCTAssertThrowsError(try STLImporter.importSTL(empty))
    }

    // MARK: - OBJ export

    func testOBJLineFormat() {
        let body = makeBox(at: 10)
        let obj = OBJExporter.obj(bodies: [body])
        let lines = obj.split(separator: "\n")

        let vLines = lines.filter { $0.hasPrefix("v ") }
        let vnLines = lines.filter { $0.hasPrefix("vn ") }
        let fLines = lines.filter { $0.hasPrefix("f ") }
        let oLines = lines.filter { $0.hasPrefix("o ") }

        XCTAssertEqual(oLines.count, 1)
        XCTAssertEqual(vLines.count, body.render.positions.count)
        XCTAssertEqual(vnLines.count, body.render.normals.count)
        XCTAssertEqual(fLines.count, body.render.triangleCount)

        // Faces are v//vn with 1-based indices within [1, vertexCount].
        var seenIndices = Set<Int>()
        for line in fLines {
            let refs = line.dropFirst(2).split(separator: " ")
            XCTAssertEqual(refs.count, 3)
            for ref in refs {
                let parts = ref.components(separatedBy: "//")
                XCTAssertEqual(parts.count, 2)
                guard let v = Int(parts[0]), let n = Int(parts[1]) else {
                    return XCTFail("Non-integer face reference: \(ref)")
                }
                XCTAssertEqual(v, n, "Welded arrays share indices")
                XCTAssertGreaterThanOrEqual(v, 1)
                XCTAssertLessThanOrEqual(v, body.render.positions.count)
                seenIndices.insert(v)
            }
        }
        XCTAssertEqual(seenIndices.count, body.render.positions.count)

        // Transform is baked: translated box vertices sit near x=10.
        let firstV = vLines[0].split(separator: " ")
        XCTAssertGreaterThan(abs(Double(firstV[1])!), 8, "x=10 translation baked into v lines")
    }

    func testOBJMergedOffsetsAndPerBody() {
        let a = makeBox(name: "A")
        let b = makeBox(at: 5, name: "B")
        let merged = OBJExporter.obj(bodies: [a, b])
        let fLines = merged.split(separator: "\n").filter { $0.hasPrefix("f ") }
        XCTAssertEqual(fLines.count, a.render.triangleCount + b.render.triangleCount)

        // Second body's face indices start past the first body's vertices.
        let maxIndex = fLines
            .flatMap { $0.dropFirst(2).split(separator: " ") }
            .compactMap { Int($0.components(separatedBy: "//")[0]) }
            .max()
        XCTAssertEqual(maxIndex, a.render.positions.count + b.render.positions.count)

        let perBody = OBJExporter.objPerBody(bodies: [a, b])
        XCTAssertEqual(perBody.count, 2)
        XCTAssertEqual(perBody[0].name, "A")
        XCTAssertTrue(perBody[1].obj.contains("o B"))
    }

    // MARK: - 3MF

    private struct ZipEntry {
        let name: String
        let crc: UInt32
        let data: Data
    }

    /// Structural zip parse: EOCD -> central directory -> local headers.
    private func parseZip(_ data: Data) throws -> [ZipEntry] {
        func u16(_ offset: Int) -> Int {
            Int(data.withUnsafeBytes {
                UInt16(littleEndian: $0.loadUnaligned(fromByteOffset: offset, as: UInt16.self))
            })
        }
        func u32(_ offset: Int) -> UInt32 {
            data.withUnsafeBytes {
                UInt32(littleEndian: $0.loadUnaligned(fromByteOffset: offset, as: UInt32.self))
            }
        }

        // No archive comment is written, so EOCD is the trailing 22 bytes.
        let eocd = data.count - 22
        XCTAssertGreaterThanOrEqual(eocd, 0)
        XCTAssertEqual(u32(eocd), 0x0605_4B50, "EOCD signature")
        let entryCount = u16(eocd + 10)
        var offset = Int(u32(eocd + 16))

        var entries = [ZipEntry]()
        for _ in 0..<entryCount {
            XCTAssertEqual(u32(offset), 0x0201_4B50, "Central directory signature")
            let crc = u32(offset + 16)
            let size = Int(u32(offset + 24))
            let nameLength = u16(offset + 28)
            let extraLength = u16(offset + 30)
            let commentLength = u16(offset + 32)
            let localOffset = Int(u32(offset + 42))
            let name = String(
                decoding: data.subdata(in: (offset + 46)..<(offset + 46 + nameLength)),
                as: UTF8.self
            )

            // Local header must agree with the central directory record.
            XCTAssertEqual(u32(localOffset), 0x0403_4B50, "Local header signature")
            XCTAssertEqual(u16(localOffset + 8), 0, "Method is STORED")
            XCTAssertEqual(u32(localOffset + 14), crc)
            XCTAssertEqual(Int(u32(localOffset + 22)), size)
            let localNameLength = u16(localOffset + 26)
            let localExtraLength = u16(localOffset + 28)
            XCTAssertEqual(localNameLength, nameLength)
            let payloadStart = localOffset + 30 + localNameLength + localExtraLength
            let payload = data.subdata(in: payloadStart..<(payloadStart + size))
            entries.append(ZipEntry(name: name, crc: crc, data: payload))

            offset += 46 + nameLength + extraLength + commentLength
        }
        return entries
    }

    func testThreeMFStructureAndModelXML() throws {
        let body = makeBox()
        let archive = ThreeMFExporter.threeMF(bodies: [body])
        let entries = try parseZip(archive)

        XCTAssertEqual(
            entries.map(\.name),
            ["[Content_Types].xml", "_rels/.rels", "3D/3dmodel.model"]
        )
        for entry in entries {
            XCTAssertEqual(MinimalZipWriter.crc32(entry.data), entry.crc, "\(entry.name) CRC")
        }

        let model = String(decoding: entries[2].data, as: UTF8.self)
        XCTAssertTrue(model.contains("<model unit=\"millimeter\""))
        let vertexCount = model.components(separatedBy: "<vertex ").count - 1
        let triangleCount = model.components(separatedBy: "<triangle ").count - 1
        XCTAssertEqual(vertexCount, body.render.positions.count)
        XCTAssertEqual(triangleCount, body.render.triangleCount)
        XCTAssertTrue(model.contains("<item objectid=\"1\"/>"))

        let contentTypes = String(decoding: entries[0].data, as: UTF8.self)
        XCTAssertTrue(contentTypes.contains("3dmanufacturing-3dmodel+xml"))
        let rels = String(decoding: entries[1].data, as: UTF8.self)
        XCTAssertTrue(rels.contains("/3D/3dmodel.model"))
    }

    func testThreeMFMultipleBodies() throws {
        let archive = ThreeMFExporter.threeMF(bodies: [makeBox(name: "A"), makeBox(at: 5, name: "B")])
        let entries = try parseZip(archive)
        let model = String(decoding: entries[2].data, as: UTF8.self)
        XCTAssertTrue(model.contains("<object id=\"1\""))
        XCTAssertTrue(model.contains("<object id=\"2\""))
        XCTAssertTrue(model.contains("<item objectid=\"2\"/>"))
    }
}
