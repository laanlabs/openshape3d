//
//  OBJMaterialExportTests.swift
//  openshape3dTests
//
//  #133, the OBJ half: what an OBJ export puts on disk when a design has
//  materials (an MTL beside it, named by the OBJ), that a shape with curved
//  sides still leaves closed and in convex polygons, that both importers read
//  the pair back, and that a concave face in somebody else's OBJ is not
//  fanned across its notch.
//

import XCTest
import simd
import Euclid
@testable import openshape3d

@MainActor
final class OBJMaterialExportTests: XCTestCase {

    private func box(_ name: String, at x: Double = 0, material: BodyMaterialSpec? = nil) -> Body {
        var transform = Transform3D.identity
        transform.translation = SIMD3(x, 0, 0)
        var body = Body(name: name, transform: transform,
                        primitive: .box(width: 2, depth: 2, height: 2),
                        euclidMesh: .primitive(.box(width: 2, depth: 2, height: 2)), revision: 1)
        body.material = material
        return body
    }

    private func cylinder(_ name: String = "Pin", material: BodyMaterialSpec? = nil) -> Body {
        var body = Body(name: name, transform: .identity,
                        primitive: .cylinder(radius: 5, height: 20),
                        euclidMesh: .primitive(.cylinder(radius: 5, height: 20)), revision: 1)
        body.material = material
        return body
    }

    private let brass = BodyMaterialSpec(baseColor: SIMD4(0.8, 0.6, 0.2, 1), metallic: 1, roughness: 0.3)
    private let glass = BodyMaterialSpec(baseColor: SIMD4(0.5, 0.75, 1, 0.25), metallic: 0, roughness: 0.1)
    private let lamp = BodyMaterialSpec(baseColor: SIMD4(1, 0.5, 0, 1), metallic: 0, roughness: 0.4, emission: 0.6)

    private func text(_ files: [(fileName: String, data: Data)], _ name: String) throws -> String {
        String(decoding: try XCTUnwrap(files.first { $0.fileName == name }, "no \(name) among \(files.map(\.fileName))").data,
               as: UTF8.self)
    }

    /// The faces of an OBJ as lists of vertex indices.
    private func faces(_ obj: String) -> [[Int]] {
        obj.split(separator: "\n").filter { $0.hasPrefix("f ") }.map { line in
            line.split(separator: " ").dropFirst().compactMap { Int($0.split(separator: "/")[0]) }
        }
    }

    private func vertices(_ obj: String) -> [SIMD3<Double>] {
        obj.split(separator: "\n").filter { $0.hasPrefix("v ") }.map { line in
            let n = line.split(separator: " ").dropFirst().compactMap { Double($0) }
            return SIMD3(n[0], n[1], n[2])
        }
    }

    // MARK: - Which files

    func testAPlainDesignIsOneFileWithNoMaterialStatements() throws {
        let files = OBJExporter.files(bodies: [box("A"), box("B", at: 5)], designName: "Bracket", perBody: false)
        XCTAssertEqual(files.map(\.fileName), ["Bracket.obj"])
        let obj = try text(files, "Bracket.obj")
        XCTAssertFalse(obj.contains("mtllib"))
        XCTAssertFalse(obj.contains("usemtl"))
    }

    func testAColouredDesignIsAnOBJAndTheMTLItNames() throws {
        let files = OBJExporter.files(bodies: [box("Lid", material: brass), box("Window", at: 5, material: glass), box("Base", at: 10)],
                                      designName: "My Lamp v2", perBody: false)
        XCTAssertEqual(files.map(\.fileName), ["My_Lamp_v2.obj", "My_Lamp_v2.mtl"], "a name with spaces would end the mtllib line early")
        let obj = try text(files, "My_Lamp_v2.obj")
        XCTAssertTrue(obj.contains("mtllib My_Lamp_v2.mtl\n"))
        let used = obj.split(separator: "\n").filter { $0.hasPrefix("usemtl ") }.map { String($0.dropFirst(7)) }
        XCTAssertEqual(used.count, 3, "one statement per body here")
        XCTAssertEqual(used.last, "Default", "the body nobody coloured must not inherit the glass before it")

        let mtl = try text(files, "My_Lamp_v2.mtl")
        let declared = mtl.split(separator: "\n").filter { $0.hasPrefix("newmtl ") }.map { String($0.dropFirst(7)) }
        XCTAssertEqual(Set(declared), Set(used), "every material the OBJ uses is in the library, and nothing else")
        XCTAssertTrue(mtl.contains("Kd 0.800000 0.600000 0.200000"), "brass colour")
        XCTAssertTrue(mtl.contains("Pm 1.000000"), "brass is a metal")
        XCTAssertTrue(mtl.contains("Pr 0.300000"))
        XCTAssertTrue(mtl.contains("d 0.250000"), "the glass is a quarter opaque")
        XCTAssertFalse(mtl.contains("Ke "), "nothing glows")
    }

    func testAGlowIsWrittenAsEmission() throws {
        let files = OBJExporter.files(bodies: [box("Bulb", material: lamp)], designName: "Bulb", perBody: false)
        XCTAssertTrue(try text(files, "Bulb.mtl").contains("Ke 0.600000 0.300000 0.000000"))
    }

    func testPerBodyFilesShareOneLibraryAndNeverOverwriteEachOther() throws {
        let files = OBJExporter.files(bodies: [box("Leg", material: brass), box("Leg", at: 5, material: brass), box("Top Plate", at: 10)],
                                      designName: "Table", perBody: true)
        XCTAssertEqual(files.map(\.fileName), ["Leg.obj", "Leg_2.obj", "Top_Plate.obj", "Table.mtl"])
        for name in ["Leg.obj", "Leg_2.obj", "Top_Plate.obj"] {
            XCTAssertTrue(try text(files, name).contains("mtllib Table.mtl\n"), name)
        }
        XCTAssertTrue(try text(files, "Top_Plate.obj").contains("usemtl Default"))
        // Without materials a per-body export is the OBJs alone.
        XCTAssertEqual(OBJExporter.files(bodies: [box("A"), box("B", at: 5)], designName: "T", perBody: true).map(\.fileName),
                       ["A.obj", "B.obj"])
    }

    // MARK: - A shape that is not a box

    func testACylinderLeavesClosedAndInConvexPolygons() throws {
        let body = cylinder()
        let obj = OBJExporter.obj(bodies: [body])
        let rings = faces(obj), points = vertices(obj)
        XCTAssertFalse(rings.isEmpty)

        // Closed: every edge has exactly two faces on it, one each way.
        var uses: [String: Int] = [:]
        var directed = Set<String>()
        for ring in rings {
            for (i, a) in ring.enumerated() {
                let b = ring[(i + 1) % ring.count]
                uses["\(min(a, b))-\(max(a, b))", default: 0] += 1
                XCTAssertTrue(directed.insert("\(a)>\(b)").inserted, "edge \(a)→\(b) is walked the same way twice")
            }
        }
        XCTAssertEqual(uses.values.filter { $0 != 2 }.count, 0, "an edge with one face is a hole")

        // Two caps as polygons, the wall as quads: far fewer faces than triangles.
        XCTAssertEqual(rings.filter { $0.count > 4 }.count, 2, "the two caps are one polygon each")
        XCTAssertEqual(rings.filter { $0.count == 4 }.count, rings.count - 2, "the wall is strips")
        XCTAssertLessThan(rings.count, body.render.triangleCount / 2)
        XCTAssertEqual(points.count, 2 * (rings.count - 2), "a ring of corners top and bottom, each written once")

        // Convex: a fan from any corner stays inside, so every reader gets the same face.
        for ring in rings {
            let corners = ring.map { points[$0 - 1] }
            var normal = SIMD3<Double>.zero
            for i in corners.indices {
                let a = corners[i], b = corners[(i + 1) % corners.count]
                normal += simd_cross(a, b)
            }
            for i in corners.indices {
                let a = corners[i], b = corners[(i + 1) % corners.count], c = corners[(i + 2) % corners.count]
                XCTAssertGreaterThanOrEqual(simd_dot(simd_cross(b - a, c - b), normal), -1e-9, "a reflex corner")
            }
        }
    }

    // MARK: - Reading the pair back

    func testMaterialsSurviveExportAndImport() throws {
        let files = OBJExporter.files(bodies: [box("Lid", material: brass), box("Window", at: 5, material: glass),
                                               cylinder("Bulb", material: lamp)],
                                      designName: "Lamp", perBody: false)
        let obj = try XCTUnwrap(files.first { $0.fileName == "Lamp.obj" }).data
        let mtl = try XCTUnwrap(files.first { $0.fileName == "Lamp.mtl" }).data
        let parts = try OBJTexturedImporter.parts(from: obj, siblings: ["Lamp.mtl": mtl], unitScale: 1)
        XCTAssertEqual(parts.map(\.name), ["Lid", "Window", "Bulb"])
        for (part, want) in zip(parts, [brass, glass, lamp]) {
            let got = try XCTUnwrap(part.material, part.name)
            XCTAssertEqual(simd_length(got.baseColor - want.baseColor), 0, accuracy: 1e-5, part.name)
            XCTAssertEqual(got.metallic, want.metallic, accuracy: 1e-5, part.name)
            XCTAssertEqual(got.roughness, want.roughness, accuracy: 1e-5, part.name)
            XCTAssertEqual(got.emission, want.emission, accuracy: 1e-5, part.name)
        }
        XCTAssertEqual(MeasureKit.bodyVolume(parts[2].mesh, scale: 1),
                       MeasureKit.bodyVolume(cylinder().render, scale: 1), accuracy: 1e-2,
                       "the polygons triangulate back to the same solid")
    }

    // MARK: - Somebody else's concave face

    /// An L in the XY plane as ONE six-cornered face, starting at a corner a
    /// fan cannot be drawn from: fanned, its triangles cover 4 units of area
    /// and one of them faces backwards; the L is 3.
    private let concaveOBJ = """
    o L
    v 2 0 0
    v 2 1 0
    v 1 1 0
    v 1 2 0
    v 0 2 0
    v 0 0 0
    f 1 2 3 4 5 6
    """

    private func area(_ mesh: RenderMesh) -> (total: Double, backwards: Int) {
        var total = 0.0, backwards = 0
        for t in stride(from: 0, to: mesh.indices.count, by: 3) {
            let a = SIMD3<Double>(mesh.positions[Int(mesh.indices[t])])
            let b = SIMD3<Double>(mesh.positions[Int(mesh.indices[t + 1])])
            let c = SIMD3<Double>(mesh.positions[Int(mesh.indices[t + 2])])
            let cross = simd_cross(b - a, c - a)
            total += simd_length(cross) / 2
            if cross.z < 0 { backwards += 1 }
        }
        return (total, backwards)
    }

    func testAConcaveFaceIsNotFannedAcrossItsNotch() throws {
        let plain = try OBJImporter.importOBJ(Data(concaveOBJ.utf8))
        XCTAssertEqual(plain.count, 1)
        XCTAssertEqual(area(plain[0].mesh).total, 3, accuracy: 1e-6, "geometry-only importer")
        XCTAssertEqual(area(plain[0].mesh).backwards, 0)
        XCTAssertEqual(plain[0].mesh.indices.count, 12, "six corners are four triangles")

        let textured = try OBJTexturedImporter.parts(from: Data(concaveOBJ.utf8), siblings: [:], unitScale: 1)
        XCTAssertEqual(textured.count, 1)
        XCTAssertEqual(area(textured[0].mesh).total, 3, accuracy: 1e-6, "importer with materials")
        XCTAssertEqual(area(textured[0].mesh).backwards, 0)
    }
}
