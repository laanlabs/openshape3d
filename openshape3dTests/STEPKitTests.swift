//
//  STEPKitTests.swift
//  openshape3dTests
//
//  STEP interchange at the DOCUMENT level (spec §12.1/§12.2). `OCCTKernelTests`
//  already proves a single solid survives a STEP round trip analytically; what
//  this file covers is everything `STEPKit` adds on top of that — which bodies
//  are written, where they end up, and what an imported solid becomes.
//
//  Pure values throughout: `Body` in, `Body` out, no session or model
//  container (the house rule for geometry tests).
//

import XCTest
import simd
import Euclid
@testable import openshape3d

final class STEPKitTests: XCTestCase {

    /// A body whose geometry OCCT owns — a cylinder, so its analytic wall is
    /// the thing to look for on the far side of a round trip.
    private func cylinderBody(name: String = "Cyl", radius: Double = 5,
                              height: Double = 20,
                              transform: Transform3D = .identity) -> Body {
        let spec = PrimitiveSpec.cylinder(radius: radius, height: height)
        var body = Body(name: name, transform: transform, primitive: spec,
                        euclidMesh: .primitive(.cylinder(radius: radius, height: height)),
                        revision: 1)
        guard let handle = OCCTKernel.primitiveShape(spec, placement: .identity) else {
            XCTFail("could not build the analytic cylinder")
            return body
        }
        XCTAssertTrue(body.adoptBRep(handle))
        body.transform = transform
        return body
    }

    /// A mesh-only body: no `brep`, exactly like an imported STL.
    private func meshBody(name: String = "Mesh") -> Body {
        Body(name: name, transform: .identity,
             primitive: .box(width: 10, depth: 10, height: 10),
             euclidMesh: .primitive(.box(width: 10, depth: 10, height: 10)),
             revision: 1)
    }

    // MARK: - Export

    /// The whole point of STEP over STL: the cylinder is still ONE cylindrical
    /// surface after the round trip, not a barrel of flat facets.
    func testExportedCylinderStaysAnalyticThroughAFullRoundTrip() throws {
        let body = cylinderBody()
        guard case let .success(data, skipped) = STEPKit.export(bodies: [body]) else {
            return XCTFail("a body with a brep must export")
        }
        XCTAssertTrue(skipped.isEmpty, "nothing to skip")
        XCTAssertFalse(data.isEmpty)
        XCTAssertTrue(String(decoding: data.prefix(20), as: UTF8.self).hasPrefix("ISO-10303-21"),
                      "a STEP part-21 file must start with its ISO header")

        let solids = STEPKit.solids(from: data)
        XCTAssertEqual(solids.count, 1, "one solid out")
        let counts = OCCTKernel.faceTypeCounts(try XCTUnwrap(solids.first))
        XCTAssertEqual(counts.cylindrical, 1, "the analytic wall survives — this is not a mesh")
        XCTAssertEqual(counts.planar, 2, "both caps survive")
    }

    /// IGES carries the exact B-rep too: the cylinder comes back as one
    /// cylindrical surface and two planar caps, and two bodies as two solids.
    func testIGESRoundTripStaysAnalytic() throws {
        guard case let .success(data, skipped) = STEPKit.export(
            bodies: [cylinderBody(name: "A"), cylinderBody(name: "B", radius: 3)], format: .iges)
        else { return XCTFail("bodies with a brep must export to IGES") }
        XCTAssertTrue(skipped.isEmpty)
        XCTAssertFalse(data.isEmpty)
        let solids = STEPKit.solids(from: data, format: .iges)
        XCTAssertEqual(solids.count, 2, "one solid per body")
        let counts = OCCTKernel.faceTypeCounts(try XCTUnwrap(solids.first))
        XCTAssertEqual(counts.cylindrical, 1, "the analytic wall survives")
        XCTAssertEqual(counts.planar, 2)
        XCTAssertTrue(STEPKit.solids(from: Data("not an iges file".utf8), format: .iges).isEmpty)
    }

    /// Each solid in the file is a separate body, so a two-body design
    /// round-trips as two bodies rather than one merged compound.
    func testEveryBodyBecomesItsOwnSolid() {
        let bodies = [cylinderBody(name: "A"), cylinderBody(name: "B", radius: 3)]
        guard case let .success(data, _) = STEPKit.export(bodies: bodies) else {
            return XCTFail("both bodies carry a brep")
        }
        XCTAssertEqual(STEPKit.solids(from: data).count, 2)
    }

    /// A moved body must be written WHERE THE USER SEES IT. The brep lives in
    /// body-local space, so if the transform were not baked in, a part dragged
    /// 100 mm away would export back at the origin — silently wrong, and only
    /// visible once the file is opened somewhere else.
    func testBodyTransformIsBakedIntoTheExportedSolid() throws {
        var moved = Transform3D.identity
        moved.translation = SIMD3<Double>(100, 0, 0)
        guard case let .success(data, _) = STEPKit.export(bodies: [cylinderBody(transform: moved)])
        else { return XCTFail("export must succeed") }

        let solid = try XCTUnwrap(STEPKit.solids(from: data).first)
        let mesh = OCCTKernel.renderMesh(from: solid)
        XCTAssertFalse(mesh.positions.isEmpty)
        let xs = mesh.positions.map(\.x)
        let centerX = (xs.min()! + xs.max()!) / 2
        XCTAssertEqual(centerX, 100, accuracy: 0.5,
                       "the exported solid sits at the body's world position, not the origin")
    }

    /// Mesh-only bodies have no analytic geometry to write. They are named,
    /// not silently dropped — and not triangulated into a format whose whole
    /// value is that it is not triangles.
    func testMeshOnlyBodiesAreSkippedByNameAlongsideAnalyticOnes() {
        guard case let .success(data, skipped) =
                STEPKit.export(bodies: [cylinderBody(name: "Cyl"), meshBody(name: "FromSTL")])
        else { return XCTFail("the analytic body must still export") }
        XCTAssertEqual(skipped, ["FromSTL"], "the mesh body is reported by name")
        XCTAssertEqual(STEPKit.solids(from: data).count, 1, "only the analytic body is written")
    }

    func testAllMeshBodiesExportNothingAndSayWhich() {
        let outcome = STEPKit.export(bodies: [meshBody(name: "One"), meshBody(name: "Two")])
        XCTAssertEqual(outcome, .nothingAnalytic(skipped: ["One", "Two"]))
    }

    func testEmptyDocumentExportsNothing() {
        XCTAssertEqual(STEPKit.export(bodies: []), .nothingAnalytic(skipped: []))
    }

    // MARK: - Import

    /// Garbage in must be a recoverable "no solids", never a crash or a body
    /// made of nothing.
    func testUnreadableDataYieldsNoSolids() {
        XCTAssertTrue(STEPKit.solids(from: Data("not a step file".utf8)).isEmpty)
        XCTAssertTrue(STEPKit.solids(from: Data()).isEmpty)
    }

    /// An imported solid becomes a fully-formed body: named, meshed for the
    /// renderer, and — the part that matters — still carrying its `brep`, so
    /// fillet/shell/boolean stay on the OCCT path afterwards.
    func testImportedSolidBecomesAnAnalyticBody() throws {
        guard case let .success(data, _) = STEPKit.export(bodies: [cylinderBody()]) else {
            return XCTFail("export must succeed")
        }
        let solid = try XCTUnwrap(STEPKit.solids(from: data).first)
        let body = try XCTUnwrap(STEPKit.body(from: solid, name: "Part", revision: 7))

        XCTAssertEqual(body.name, "Part")
        XCTAssertEqual(body.meshRevision, 7)
        XCTAssertEqual(body.transform, .identity, "the solid is left where the file put it")
        XCTAssertNotNil(body.brep, "an imported body must stay analytic")
        XCTAssertGreaterThan(body.render.triangleCount, 0, "it renders")
        XCTAssertGreaterThan(body.edges.segmentCount, 0, "feature edges are extracted, so it is "
                             + "selectable and blendable like any modelled body")
        XCTAssertFalse(body.euclidMesh().polygons.isEmpty, "CSG mesh is derived too")
    }

    /// Round-trip through a body, not just a handle: the imported body's size
    /// matches what went in.
    func testImportedBodyKeepsTheOriginalDimensions() throws {
        guard case let .success(data, _) =
                STEPKit.export(bodies: [cylinderBody(radius: 4, height: 12)])
        else { return XCTFail("export must succeed") }
        let solid = try XCTUnwrap(STEPKit.solids(from: data).first)
        let body = try XCTUnwrap(STEPKit.body(from: solid, name: "P", revision: 1))

        let aabb = body.render.localAABB
        let size = aabb.max - aabb.min
        // A cylinder r=4 h=12 spans 8 across both round axes and 12 along its own.
        let extents = [size.x, size.y, size.z].sorted()
        XCTAssertEqual(Double(extents[0]), 8, accuracy: 0.2)
        XCTAssertEqual(Double(extents[1]), 8, accuracy: 0.2)
        XCTAssertEqual(Double(extents[2]), 12, accuracy: 0.2)
    }
}
