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

        // Faces are v//vn with 1-based indices into their own tables.
        var seenVertices = Set<Int>()
        var seenNormals = Set<Int>()
        for line in fLines {
            let refs = line.dropFirst(2).split(separator: " ")
            XCTAssertGreaterThanOrEqual(refs.count, 3)
            for ref in refs {
                let parts = ref.components(separatedBy: "//")
                XCTAssertEqual(parts.count, 2)
                guard let v = Int(parts[0]), let n = Int(parts[1]) else {
                    return XCTFail("Non-integer face reference: \(ref)")
                }
                XCTAssertTrue((1...vLines.count).contains(v))
                XCTAssertTrue((1...vnLines.count).contains(n))
                seenVertices.insert(v)
                seenNormals.insert(n)
            }
        }
        XCTAssertEqual(seenVertices.count, vLines.count, "every v is referenced")
        XCTAssertEqual(seenNormals.count, vnLines.count, "every vn is referenced")

        // Transform is baked: translated box vertices sit near x=10.
        let firstV = vLines[0].split(separator: " ")
        XCTAssertGreaterThan(abs(Double(firstV[1])!), 8, "x=10 translation baked into v lines")
    }

    func testOBJMergedOffsetsAndPerBody() {
        let a = makeBox(name: "A")
        let b = makeBox(at: 5, name: "B")
        let merged = OBJExporter.obj(bodies: [a, b])
        let lines = merged.split(separator: "\n")
        let fLines = lines.filter { $0.hasPrefix("f ") }
        XCTAssertEqual(fLines.count, 12, "two boxes, six quads each")

        // Second body's indices continue past the first body's tables.
        let refs = fLines.flatMap { $0.dropFirst(2).split(separator: " ") }
            .map { $0.components(separatedBy: "//").compactMap { Int($0) } }
        XCTAssertEqual(refs.map { $0[0] }.max(), lines.filter { $0.hasPrefix("v ") }.count)
        XCTAssertEqual(refs.map { $0[0] }.max(), 16)
        XCTAssertEqual(refs.map { $0[1] }.max(), lines.filter { $0.hasPrefix("vn ") }.count)
        XCTAssertEqual(Set(fLines.suffix(6).flatMap { $0.dropFirst(2).split(separator: " ") }
            .compactMap { Int($0.components(separatedBy: "//")[0]) }).min(), 9)

        let perBody = OBJExporter.objPerBody(bodies: [a, b])
        XCTAssertEqual(perBody.count, 2)
        XCTAssertEqual(perBody[0].name, "A")
        XCTAssertTrue(perBody[1].obj.contains("o B"))
    }

    // MARK: - OBJ clean topology

    private struct ParsedOBJ {
        var vertices: [SIMD3<Double>] = []
        var normals: [SIMD3<Double>] = []
        var faces: [[Int]] = []   // 0-based position indices
        var faceNormals: [[Int]] = []   // 0-based normal indices, per corner
    }

    private func parseOBJ(_ text: String) -> ParsedOBJ {
        var parsed = ParsedOBJ()
        for line in text.split(separator: "\n") {
            let fields = line.split(separator: " ")
            if fields.first == "v" {
                let c = fields.dropFirst().compactMap { Double($0) }
                parsed.vertices.append(SIMD3(c[0], c[1], c[2]))
            } else if fields.first == "vn" {
                let c = fields.dropFirst().compactMap { Double($0) }
                parsed.normals.append(SIMD3(c[0], c[1], c[2]))
            } else if fields.first == "f" {
                parsed.faces.append(fields.dropFirst().compactMap {
                    Int($0.components(separatedBy: "/")[0]).map { $0 - 1 }
                })
                parsed.faceNormals.append(fields.dropFirst().compactMap {
                    Int($0.components(separatedBy: "/").last ?? "").map { $0 - 1 }
                })
            }
        }
        return parsed
    }

    /// Closed, consistently wound, no duplicated positions, no face that
    /// revisits a vertex.
    private func assertCleanClosedSurface(_ parsed: ParsedOBJ,
                                          file: StaticString = #filePath, line: UInt = #line) {
        let keys = parsed.vertices.map { v in
            "\((v.x * 1e4).rounded()) \((v.y * 1e4).rounded()) \((v.z * 1e4).rounded())"
        }
        XCTAssertEqual(Set(keys).count, keys.count, "no duplicated vertex positions",
                       file: file, line: line)
        var directed: [String: Int] = [:]
        for face in parsed.faces {
            XCTAssertGreaterThanOrEqual(face.count, 3, file: file, line: line)
            XCTAssertEqual(Set(face).count, face.count, "face repeats a vertex: \(face)",
                           file: file, line: line)
            for k in face.indices {
                directed["\(face[k])>\(face[(k + 1) % face.count])", default: 0] += 1
            }
        }
        for (edge, count) in directed {
            XCTAssertEqual(count, 1, "directed edge \(edge) used \(count)×", file: file, line: line)
            let parts = edge.split(separator: ">")
            XCTAssertEqual(directed["\(parts[1])>\(parts[0])"], 1,
                           "edge \(edge) must be shared by exactly two faces",
                           file: file, line: line)
        }
    }

    func testOBJBoxExportsEightVerticesAndSixQuads() {
        let parsed = parseOBJ(OBJExporter.obj(bodies: [makeBox()]))
        XCTAssertEqual(parsed.vertices.count, 8)
        XCTAssertEqual(parsed.faces.count, 6)
        XCTAssertTrue(parsed.faces.allSatisfy { $0.count == 4 }, "every face is a quad")
        assertCleanClosedSurface(parsed)
    }

    @MainActor
    func testOBJBoxWithSquareThroughHoleStaysClosed() {
        let slab = makeBox(size: 10)
        let punch = Body(
            name: "Punch", transform: .identity,
            primitive: .box(width: 4, depth: 4, height: 20),
            euclidMesh: .primitive(.box(width: 4, depth: 4, height: 20)),
            revision: 1
        )
        let result = KernelOps.boolean(.subtract, target: slab, tool: punch)
        let body = Body(name: "Holed", euclidMesh: result, revision: 2)
        let parsed = parseOBJ(OBJExporter.obj(bodies: [body]))

        // Welded: exactly the distinct positions of the render mesh (the
        // boolean may add points along edges; none are added or lost here).
        let distinct = Set(body.render.positions.map {
            "\(($0.x * 1e4).rounded()) \(($0.y * 1e4).rounded()) \(($0.z * 1e4).rounded())"
        })
        XCTAssertEqual(parsed.vertices.count, distinct.count)
        assertCleanClosedSurface(parsed)
        // 10 planar faces: 4 outer sides + 4 hole walls (one polygon each)
        // and 2 holed faces (≥ 2 polygons each).
        XCTAssertGreaterThanOrEqual(parsed.faces.count, 12)
        XCTAssertLessThanOrEqual(parsed.faces.count, 16)
        XCTAssertLessThan(parsed.faces.count, body.render.triangleCount,
                          "coplanar triangles are merged")
    }

    @MainActor
    func testOBJBoxWithRoundThroughHoleStaysClosed() {
        let slab = makeBox(size: 10)
        let punch = Body(
            name: "Punch", transform: .identity,
            primitive: .cylinder(radius: 2, height: 20),
            euclidMesh: .primitive(.cylinder(radius: 2, height: 20)),
            revision: 1
        )
        let result = KernelOps.boolean(.subtract, target: slab, tool: punch)
        let body = Body(name: "Holed", euclidMesh: result, revision: 2)
        let parsed = parseOBJ(OBJExporter.obj(bodies: [body]))
        assertCleanClosedSurface(parsed)

        // Re-import keeps the volume (concave polygons triangulate correctly).
        let mesh = try? OBJImporter.importSingleMesh(Data(OBJExporter.obj(bodies: [body]).utf8))
        XCTAssertNotNil(mesh)
        if let mesh {
            XCTAssertEqual(MeasureKit.bodyVolume(mesh, scale: 1),
                           MeasureKit.bodyVolume(body.render, scale: 1), accuracy: 1e-2)
        }
    }

    /// A body exactly as the app builds it through OCCT: smooth render
    /// normals plus the per-triangle kernel face channel.
    private func occtBody(_ handle: BRepHandle, name: String) -> Body {
        let buffers = OCCTKernel.renderMesh(from: handle)
        var render = RenderMesh(positions: buffers.positions, normals: buffers.normals,
                                indices: buffers.indices)
        render.faceRegions = OCCTKernel.renderMeshFaceChannel(from: handle)
        return Body(id: BodyID(), name: name, transform: .identity, primitive: nil,
                    render: render, revision: 1)
    }

    func testOBJFilletedBoxKeepsSmoothNormalsOnTheFillet() throws {
        let box = try XCTUnwrap(OCCTKernel.primitiveShape(
            .box(width: 140, depth: 190, height: 22), placement: .identity))
        let plain = OCCTKernel.renderMesh(from: box).positions
        let lo = plain.reduce(plain[0]) { simd_min($0, $1) }
        let hi = plain.reduce(plain[0]) { simd_max($0, $1) }
        let mid = (lo + hi) / 2
        let topEdges: [SIMD3<Double>] = [
            SIMD3(Double(mid.x), Double(hi.y), Double(lo.z)),
            SIMD3(Double(mid.x), Double(hi.y), Double(hi.z)),
            SIMD3(Double(lo.x), Double(hi.y), Double(mid.z)),
            SIMD3(Double(hi.x), Double(hi.y), Double(mid.z)),
        ]
        let filleted = try XCTUnwrap(OCCTKernel.fillet(box, at: topEdges, radius: 6,
                                                       tolerance: 0.5))
        let body = occtBody(filleted, name: "Mattress")
        let parsed = parseOBJ(OBJExporter.obj(bodies: [body]))
        assertCleanClosedSurface(parsed)

        // Flat faces: top, bottom and 4 sides, one polygon each, flat normal.
        func isAxisAligned(_ n: SIMD3<Double>) -> Bool {
            max(abs(n.x), abs(n.y), abs(n.z)) > 0.99999
        }
        var flatFaces = 0
        var filletFaces = 0
        for corners in parsed.faceNormals {
            let distinct = Set(corners)
            if distinct.count == 1, isAxisAligned(parsed.normals[corners[0]]) {
                flatFaces += 1
            } else {
                filletFaces += 1
                XCTAssertGreaterThan(distinct.count, 1,
                                     "a fillet facet must not be shaded with one flat normal")
            }
        }
        XCTAssertEqual(flatFaces, 6)
        XCTAssertGreaterThan(filletFaces, 0)
        XCTAssertLessThan(parsed.faces.count, body.render.triangleCount)
    }

    private func filletedSlab() throws -> BRepHandle {
        let box = try XCTUnwrap(OCCTKernel.primitiveShape(
            .box(width: 140, depth: 190, height: 22), placement: .identity))
        let plain = OCCTKernel.renderMesh(from: box).positions
        let lo = plain.reduce(plain[0]) { simd_min($0, $1) }
        let hi = plain.reduce(plain[0]) { simd_max($0, $1) }
        let mid = (lo + hi) / 2
        var edges: [SIMD3<Double>] = []
        for y in [lo.y, hi.y] {
            edges += [SIMD3(Double(mid.x), Double(y), Double(lo.z)),
                      SIMD3(Double(mid.x), Double(y), Double(hi.z)),
                      SIMD3(Double(lo.x), Double(y), Double(mid.z)),
                      SIMD3(Double(hi.x), Double(y), Double(mid.z))]
        }
        for x in [lo.x, hi.x] {
            for z in [lo.z, hi.z] { edges.append(SIMD3(Double(x), Double(mid.y), Double(z))) }
        }
        return try XCTUnwrap(OCCTKernel.fillet(box, at: edges, radius: 6, tolerance: 0.5))
    }

    func testOBJExportRemeshesBRepBodiesAtExportQuality() throws {
        let handle = try filletedSlab()
        var body = Body(name: "Slab", euclidMesh: .primitive(.box(width: 1, depth: 1, height: 1)),
                        revision: 1)
        XCTAssertTrue(body.adoptBRep(handle))
        let renderTriangles = body.render.triangleCount

        let asRendered = parseOBJ(OBJExporter.obj(bodies: [body], tessellation: nil))
        let exported = parseOBJ(OBJExporter.obj(bodies: [body]))
        assertCleanClosedSurface(exported)
        XCTAssertLessThan(exported.vertices.count * 2, asRendered.vertices.count,
                          "export quality is much lighter than the viewport mesh")

        // Same solid: volume and bounds hold.
        let mesh = try OBJImporter.importSingleMesh(Data(OBJExporter.obj(bodies: [body]).utf8))
        let exact = MeasureKit.bodyVolume(body.render, scale: 1)
        XCTAssertEqual(MeasureKit.bodyVolume(mesh, scale: 1), exact, accuracy: exact * 5e-4)
        XCTAssertEqual(simd_length(mesh.localAABB.max - body.render.localAABB.max), 0, accuracy: 1e-3)

        // The viewport's own triangulation is untouched by the export mesh.
        XCTAssertEqual(OCCTKernel.renderMesh(from: handle).indices.count / 3, renderTriangles)
    }

    func testOBJCylinderSideIsQuadsWithSmoothNormals() throws {
        let cylinder = try XCTUnwrap(OCCTKernel.primitiveShape(
            .cylinder(radius: 5, height: 20), placement: .identity))
        let body = occtBody(cylinder, name: "Leg")
        let parsed = parseOBJ(OBJExporter.obj(bodies: [body]))
        assertCleanClosedSurface(parsed)

        let segments = parsed.vertices.count / 2
        XCTAssertGreaterThan(segments, 8)
        XCTAssertEqual(parsed.vertices.count, 2 * segments, "two rims, nothing else")
        let quads = parsed.faces.indices.filter { parsed.faces[$0].count == 4 }
        XCTAssertEqual(quads.count, segments, "one quad per side strip")
        XCTAssertEqual(parsed.faces.filter { $0.count == segments }.count, 2, "two caps")
        XCTAssertEqual(parsed.faces.count, segments + 2)
        for q in quads {
            XCTAssertEqual(Set(parsed.faceNormals[q]).count, 2,
                           "side quads carry the two generatrix normals (smooth)")
        }
    }

    func testOBJConcaveFaceIsOneNGonAndReimports() throws {
        // An L-shaped prism: its two caps are concave hexagons.
        let profile = Euclid.Path([
            .point(0, 0), .point(4, 0), .point(4, 1), .point(1, 1), .point(1, 3), .point(0, 3), .point(0, 0),
        ])
        let mesh = Euclid.Mesh.extrude(profile, depth: 2)
        let body = Body(name: "L", euclidMesh: mesh, revision: 1)
        let text = OBJExporter.obj(bodies: [body])
        let parsed = parseOBJ(text)
        XCTAssertEqual(parsed.vertices.count, 12)
        XCTAssertEqual(parsed.faces.count, 8, "2 hexagon caps + 6 side quads")
        XCTAssertEqual(parsed.faces.filter { $0.count == 6 }.count, 2)
        assertCleanClosedSurface(parsed)

        let reimported = try OBJImporter.importSingleMesh(Data(text.utf8))
        XCTAssertEqual(MeasureKit.bodyVolume(reimported, scale: 1), 12, accuracy: 1e-4)  // area 6 × depth 2
        XCTAssertEqual(reimported.triangleCount, 2 * 4 + 6 * 2,
                       "ear clipping, no overlapping fan triangles")
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
