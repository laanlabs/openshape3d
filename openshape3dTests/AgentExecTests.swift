//
//  AgentExecTests.swift
//  openshape3dTests
//
//  The parsing half of `/v1/exec`. Pure statics only — no `EditorViewModel`
//  (STATUS_AND_NEXT_STEPS gotcha 1), which is exactly why `AgentExec` decides
//  everything it can before the main-actor hop.
//
//  What these tests are really defending: an agent cannot see a dialog or a
//  disabled button, so every way a request can be wrong has to come back as a
//  DISTINCT, named code. A single "bad_request" for all of them would make the
//  endpoint unusable in a loop — the agent would have no idea which knob to
//  turn — so most of what follows asserts on the code, not just on failure.
//

import XCTest
import simd
@testable import openshape3d

final class AgentExecTests: XCTestCase {

    // MARK: Sweep

    func testSweepParsesSpineAndRejectsShortOnes() throws {
        let id = UUID().uuidString
        let parsed = op(#"{"op":"feature.sweep","args":{"sketchID":"\#(id)","seedPoint":[1,2],"spine":[[0,0,0],[10,0,0],[10,5,0]]}}"#)
        guard case let .sweep(_, seed, spine, boolean, targets, _)? = parsed else {
            return XCTFail("expected .sweep, got \(String(describing: parsed))")
        }
        XCTAssertEqual(seed, SIMD2(1, 2))
        XCTAssertEqual(spine.count, 3)
        XCTAssertEqual(spine[1], SIMD3(10, 0, 0))
        XCTAssertEqual(boolean, .newBody)
        XCTAssertTrue(targets.isEmpty)
        XCTAssertEqual(code(#"{"op":"feature.sweep","args":{"sketchID":"\#(id)","seedPoint":[0,0],"spine":[[0,0,0]]}}"#),
                       "missing_spine", "a one-point spine is no path")
    }

    /// A `helix` stands in for the spine: the exec samples the render
    /// polyline from the spec (36 chords per turn) in the kernel's frame —
    /// right-handed about the axis, angle 0 along the reference direction.
    func testSweepAcceptsAHelixAndSamplesItsSpineInTheKernelFrame() throws {
        let id = UUID().uuidString
        let parsed = op(#"{"op":"feature.sweep","args":{"sketchID":"\#(id)","seedPoint":[0,0],"helix":{"axisPoint":[0,0,0],"axisDirection":[0,1,0],"referenceDirection":[1,0,0],"radius":10,"pitch":4,"turns":2}}}"#)
        guard case let .sweep(_, _, spine, _, _, helix)? = parsed else {
            return XCTFail("expected .sweep, got \(String(describing: parsed))")
        }
        let h = try XCTUnwrap(helix)
        XCTAssertEqual(h.radius, 10)
        XCTAssertEqual(h.turns, 2)
        XCTAssertEqual(spine.count, 73, "36 chords per turn x 2 turns, plus the start")
        XCTAssertEqual(simd_length(spine[0] - SIMD3(10, 0, 0)), 0, accuracy: 1e-9)
        // a quarter turn in (9 of the 36 chords per turn): +X has rotated toward n x x = -Z, a quarter pitch up
        XCTAssertEqual(spine[9].x, 0, accuracy: 1e-9, "quarter turn: \(spine[9])")
        XCTAssertEqual(spine[9].y, 1, accuracy: 1e-9, "quarter pitch up: \(spine[9])")
        XCTAssertEqual(spine[9].z, -10, accuracy: 1e-9, "toward n x ref = -Z: \(spine[9])")
        XCTAssertEqual(simd_length(spine[72] - h.point(at: 4 * .pi)), 0, accuracy: 1e-9)
        XCTAssertEqual(code(#"{"op":"feature.sweep","args":{"sketchID":"\#(id)","seedPoint":[0,0],"helix":{"axisPoint":[0,0,0],"axisDirection":[0,1,0],"radius":0,"pitch":4,"turns":2}}}"#),
                       "bad_helix", "a zero radius is no helix")
        XCTAssertEqual(code(#"{"op":"feature.sweep","args":{"sketchID":"\#(id)","seedPoint":[0,0]}}"#),
                       "missing_spine", "neither a spine nor a helix")
    }

    func testLoftParsesSectionsAndRejectsFewerThanTwo() throws {
        let a = UUID().uuidString, b = UUID().uuidString
        let parsed = op(#"{"op":"feature.loft","args":{"sections":[{"sketchID":"\#(a)","seedPoint":[0,0]},{"sketchID":"\#(b)","seedPoint":[1,1]}]}}"#)
        guard case let .loft(sections, boolean, targets)? = parsed else {
            return XCTFail("expected .loft, got \(String(describing: parsed))")
        }
        XCTAssertEqual(sections.count, 2)
        XCTAssertEqual(sections[0].sketch.raw.uuidString, a)
        XCTAssertEqual(sections[1].seed, SIMD2(1, 1))
        XCTAssertEqual(boolean, .newBody)
        XCTAssertTrue(targets.isEmpty)
        // One section is not a loft; a bad seed is named by section index.
        XCTAssertEqual(code(#"{"op":"feature.loft","args":{"sections":[{"sketchID":"\#(a)","seedPoint":[0,0]}]}}"#),
                       "missing_sections")
        XCTAssertEqual(code(#"{"op":"feature.loft","args":{"sections":[{"sketchID":"\#(a)","seedPoint":[0,0]},{"sketchID":"\#(b)"}]}}"#),
                       "missing_seedPoint")
    }

    func testPushPullParsesFaceDistanceAndMode() throws {
        let id = UUID().uuidString
        guard case let .pushPull(_, face, distance, radial)? = op(#"{"op":"feature.pushPull","args":{"bodyID":"\#(id)","face":[3],"distance":-4,"mode":"cylinderRadial"}}"#) else {
            return XCTFail("expected .pushPull")
        }
        XCTAssertEqual(face, 3)
        XCTAssertEqual(distance, -4, "negative distance pushes in")
        XCTAssertTrue(radial)
        // mode defaults to planar-axial
        guard case let .pushPull(_, _, _, r2)? = op(#"{"op":"feature.pushPull","args":{"bodyID":"\#(id)","face":[1],"distance":2}}"#) else {
            return XCTFail("expected .pushPull default mode")
        }
        XCTAssertFalse(r2)
        XCTAssertEqual(code(#"{"op":"feature.pushPull","args":{"bodyID":"\#(id)","face":[1],"distance":0}}"#), "zero_distance")
        XCTAssertEqual(code(#"{"op":"feature.pushPull","args":{"bodyID":"\#(id)","face":[1,2],"distance":2}}"#), "one_face_only")
        XCTAssertEqual(code(#"{"op":"feature.pushPull","args":{"bodyID":"\#(id)","face":[1],"distance":2,"mode":"wat"}}"#), "bad_mode")
    }

    func testFaceTransformOpsParseAndValidate() throws {
        let id = UUID().uuidString
        guard case let .moveFace(_, f, delta)? = op(#"{"op":"feature.moveFace","args":{"bodyID":"\#(id)","face":[2],"delta":[0,0,5]}}"#) else {
            return XCTFail("expected .moveFace")
        }
        XCTAssertEqual(f, 2); XCTAssertEqual(delta, SIMD3(0, 0, 5))
        guard case let .scaleFace(_, _, factor)? = op(#"{"op":"feature.scaleFace","args":{"bodyID":"\#(id)","face":[2],"factor":0.5}}"#) else {
            return XCTFail("expected .scaleFace")
        }
        XCTAssertEqual(factor, 0.5)
        guard case let .rotateFace(_, _, deg, axis)? = op(#"{"op":"feature.rotateFace","args":{"bodyID":"\#(id)","face":[2],"angleDegrees":15}}"#) else {
            return XCTFail("expected .rotateFace")
        }
        XCTAssertEqual(deg, 15)
        XCTAssertEqual(axis, SIMD3(0, 0, 1), "axis defaults to the face normal (n)")
        // refusals
        XCTAssertEqual(code(#"{"op":"feature.moveFace","args":{"bodyID":"\#(id)","face":[1]}}"#), "missing_delta")
        XCTAssertEqual(code(#"{"op":"feature.moveFace","args":{"bodyID":"\#(id)","face":[1],"delta":[0,0,0]}}"#), "zero_delta")
        XCTAssertEqual(code(#"{"op":"feature.scaleFace","args":{"bodyID":"\#(id)","face":[1],"factor":0}}"#), "bad_factor")
        XCTAssertEqual(code(#"{"op":"feature.rotateFace","args":{"bodyID":"\#(id)","face":[1]}}"#), "missing_angleDegrees")
        XCTAssertEqual(code(#"{"op":"feature.rotateFace","args":{"bodyID":"\#(id)","face":[1,2],"angleDegrees":10}}"#), "one_face_only")
    }

    // MARK: Delete/replace face

    func testDeleteFaceParsesAndRejectsEmpty() throws {
        let id = UUID().uuidString
        let parsed = op(#"{"op":"feature.deleteFace","args":{"bodyID":"\#(id)","faces":[3,4]}}"#)
        guard case let .deleteFace(_, faces)? = parsed else {
            return XCTFail("expected .deleteFace")
        }
        XCTAssertEqual(faces, [3, 4])
        XCTAssertEqual(code(#"{"op":"feature.deleteFace","args":{"bodyID":"\#(id)","faces":[]}}"#),
                       "missing_faces")
    }

    func testSetMaterialTakesAPresetOrAColor() throws {
        let id = UUID().uuidString
        guard case let .setMaterial(bodies, brass)? = op(#"{"op":"body.setMaterial","args":{"bodyIDs":["\#(id)"],"preset":"brass","roughness":0.5}}"#) else {
            return XCTFail("expected .setMaterial")
        }
        XCTAssertEqual(bodies.map { $0.raw.uuidString }, [id])
        let preset = try XCTUnwrap(MaterialPreset.library.first { $0.name == "Brass" })
        XCTAssertEqual(brass.baseColor, preset.spec.baseColor, "preset names match case-insensitively")
        XCTAssertEqual(brass.metallic, 1)
        XCTAssertEqual(brass.roughness, 0.5, "an explicit factor overrides the preset's")

        guard case let .setMaterial(_, orange)? = op(#"{"op":"body.setMaterial","args":{"bodyIDs":["\#(id)"],"color":[1,0.5,0]}}"#) else {
            return XCTFail("expected .setMaterial")
        }
        XCTAssertEqual(orange.baseColor, SIMD4(1, 0.5, 0, 1), "an RGB color gets alpha 1")
        XCTAssertEqual(orange.metallic, 0)

        XCTAssertEqual(code(#"{"op":"body.setMaterial","args":{"bodyIDs":["\#(id)"],"preset":"Unobtainium"}}"#), "unknown_preset")
        XCTAssertEqual(code(#"{"op":"body.setMaterial","args":{"bodyIDs":["\#(id)"]}}"#), "missing_material")
        XCTAssertEqual(code(#"{"op":"body.setMaterial","args":{"bodyIDs":["\#(id)"],"color":[2,0,0]}}"#), "bad_color")
        XCTAssertEqual(code(#"{"op":"body.setMaterial","args":{"bodyIDs":["\#(id)"],"preset":"Steel","metallic":3}}"#), "bad_metallic")
        XCTAssertEqual(code(#"{"op":"body.setMaterial","args":{"bodyIDs":[],"preset":"Steel"}}"#), "missing_bodyIDs")
    }

    func testSetHiddenTakesIdsOrEverySketch() throws {
        let id = UUID()
        guard case let .setHidden(ids, allSketches, hidden)? = op(#"{"op":"item.setHidden","args":{"ids":["\#(id.uuidString)"]}}"#) else {
            return XCTFail("expected .setHidden")
        }
        XCTAssertEqual(ids, [id])
        XCTAssertFalse(allSketches)
        XCTAssertTrue(hidden, "hides unless told otherwise")

        guard case let .setHidden(none, every, shown)? = op(#"{"op":"item.setHidden","args":{"allSketches":true,"hidden":false}}"#) else {
            return XCTFail("expected .setHidden")
        }
        XCTAssertTrue(none.isEmpty)
        XCTAssertTrue(every)
        XCTAssertFalse(shown)

        XCTAssertEqual(code(#"{"op":"item.setHidden","args":{}}"#), "missing_ids", "nothing to act on")
        XCTAssertEqual(code(#"{"op":"item.setHidden","args":{"ids":["nope"]}}"#), "bad_uuid")
    }

    func testReplaceFaceParsesPlaneAndRejectsDegenerateNormal() throws {
        let id = UUID().uuidString
        let parsed = op(#"{"op":"feature.replaceFace","args":{"bodyID":"\#(id)","face":[2],"targetOrigin":[0,5,0],"targetNormal":[0,2,0],"flip":true}}"#)
        guard case let .replaceFace(_, face, origin, normal, flip)? = parsed else {
            return XCTFail("expected .replaceFace")
        }
        XCTAssertEqual(face, 2)
        XCTAssertEqual(origin, SIMD3(0, 5, 0))
        XCTAssertEqual(normal, SIMD3(0, 1, 0), "normal comes back normalized")
        XCTAssertTrue(flip)
        XCTAssertEqual(code(#"{"op":"feature.replaceFace","args":{"bodyID":"\#(id)","face":[2],"targetOrigin":[0,5,0],"targetNormal":[0,0,0]}}"#),
                       "missing_targetNormal")
        XCTAssertEqual(code(#"{"op":"feature.replaceFace","args":{"bodyID":"\#(id)","face":[2,3],"targetOrigin":[0,5,0],"targetNormal":[0,1,0]}}"#),
                       "bad_face", "exactly one face")
    }

    // MARK: Blends + shell (identity-addressed, step 4b/5 wiring)

    func testFilletParsesEdgesAndRadius() throws {
        let id = UUID().uuidString
        let parsed = op(#"{"op":"feature.fillet","args":{"bodyID":"\#(id)","radius":1.5,"edges":[3,7]}}"#)
        guard case let .blend(body, isFillet, amount, edges)? = parsed else {
            return XCTFail("expected .blend, got \(String(describing: parsed))")
        }
        XCTAssertEqual(body.raw.uuidString, id)
        XCTAssertTrue(isFillet)
        XCTAssertEqual(amount, 1.5)
        XCTAssertEqual(edges, [3, 7])
    }

    func testChamferUsesSetbackAndFilletUsesRadius() {
        let id = UUID().uuidString
        XCTAssertEqual(code(#"{"op":"feature.chamfer","args":{"bodyID":"\#(id)","radius":1,"edges":[1]}}"#),
                       "missing_setback", "chamfer must not accept radius")
        XCTAssertEqual(code(#"{"op":"feature.fillet","args":{"bodyID":"\#(id)","setback":1,"edges":[1]}}"#),
                       "missing_radius")
    }

    func testBlendRefusesEmptyZeroOrNegativeIndices() {
        let id = UUID().uuidString
        XCTAssertEqual(code(#"{"op":"feature.fillet","args":{"bodyID":"\#(id)","radius":1,"edges":[]}}"#),
                       "missing_edges")
        XCTAssertEqual(code(#"{"op":"feature.fillet","args":{"bodyID":"\#(id)","radius":1,"edges":[0]}}"#),
                       "bad_index", "indices are 1-based; 0 is a typo")
        XCTAssertEqual(code(#"{"op":"feature.fillet","args":{"bodyID":"\#(id)","radius":-2,"edges":[1]}}"#),
                       "bad_radius")
    }

    func testShellParsesAndAllowsAClosedHollow() throws {
        let id = UUID().uuidString
        let open = op(#"{"op":"feature.shell","args":{"bodyID":"\#(id)","thickness":0.5,"openFaces":[2]}}"#)
        guard case let .shell(_, thickness, faces)? = open else {
            return XCTFail("expected .shell")
        }
        XCTAssertEqual(thickness, 0.5)
        XCTAssertEqual(faces, [2])
        // Absent openFaces = fully-enclosed hollow, not an error.
        let closed = op(#"{"op":"feature.shell","args":{"bodyID":"\#(id)","thickness":0.5}}"#)
        guard case let .shell(_, _, none)? = closed else {
            return XCTFail("expected .shell")
        }
        XCTAssertTrue(none.isEmpty)
        XCTAssertEqual(code(#"{"op":"feature.shell","args":{"bodyID":"\#(id)","thickness":0}}"#),
                       "bad_thickness")
    }

    // MARK: Helpers

    private func parse(_ json: String) -> Result<AgentExecOp, AgentExecError> {
        let object = try! JSONSerialization.jsonObject(with: Data(json.utf8)) as! [String: Any]
        return AgentExec.parse(object)
    }

    private func code(_ json: String, _ file: StaticString = #filePath, _ line: UInt = #line) -> String {
        switch parse(json) {
        case .success(let op):
            XCTFail("expected a failure, got \(op)", file: file, line: line)
            return ""
        case .failure(let error):
            return error.code
        }
    }

    private func op(_ json: String, _ file: StaticString = #filePath, _ line: UInt = #line) -> AgentExecOp? {
        switch parse(json) {
        case .success(let op): return op
        case .failure(let error):
            XCTFail("expected success, got \(error.code): \(error.message)", file: file, line: line)
            return nil
        }
    }

    private let sketchUUID = "3F2504E0-4F89-11D3-9A0C-0305E82C3301"
    private let bodyUUID   = "3F2504E0-4F89-11D3-9A0C-0305E82C3302"

    // MARK: Dispatch

    func testUnknownOpNamesTheAlternatives() {
        switch parse(#"{"op":"feature.bevel"}"#) {
        case .success: XCTFail("unknown op should not parse")
        case .failure(let error):
            XCTAssertEqual(error.code, "unknown_op")
            // The list is the whole point: an agent that guessed wrong needs to
            // see what it could have said instead.
            XCTAssertTrue(error.message.contains("feature.extrude"), error.message)
        }
    }

    func testMissingOpAndMissingBodyAreDistinct() {
        XCTAssertEqual(code(#"{"args":{}}"#), "missing_op")
        switch AgentExec.parse(nil) {
        case .failure(let e): XCTAssertEqual(e.code, "missing_body")
        case .success: XCTFail("nil body should not parse")
        }
    }

    // MARK: sketch.create

    func testCreateSketchDefaultsToGround() {
        guard case let .createSketch(name, plane)? = op(#"{"op":"sketch.create"}"#) else { return }
        XCTAssertEqual(name, "Sketch")
        XCTAssertEqual(plane, .ground)
    }

    func testCreateSketchNormalizesAxes() {
        // Deliberately non-unit input: a caller working in metres or reading
        // axes off another tool should not have to normalize first.
        guard case let .createSketch(_, plane)? = op("""
        {"op":"sketch.create","args":{"name":"Side","origin":[1,2,3],
         "xAxis":[5,0,0],"yAxis":[0,9,0]}}
        """) else { return }
        XCTAssertEqual(plane.origin, SIMD3(1, 2, 3))
        XCTAssertEqual(simd_length(plane.xAxis), 1, accuracy: 1e-12)
        XCTAssertEqual(simd_length(plane.yAxis), 1, accuracy: 1e-12)
    }

    func testParallelAxesAreRejected() {
        XCTAssertEqual(code("""
        {"op":"sketch.create","args":{"xAxis":[1,0,0],"yAxis":[2,0,0]}}
        """), "degenerate_plane")
    }

    // MARK: sketch.addEntities

    func testEntityKindsThatTheShaprFormatUses() {
        guard case let .addEntities(_, entities, _)? = op("""
        {"op":"sketch.addEntities","args":{"sketchID":"\(sketchUUID)","entities":[
          {"kind":"line","a":[0,0],"b":[10,0]},
          {"kind":"circle","center":[5,5],"radius":2.5},
          {"kind":"arc","center":[0,0],"radius":4,"startAngle":0,"endAngle":1.57},
          {"kind":"spline","points":[[0,0],[1,2],[3,1]],"closed":false}
        ]}}
        """) else { return }
        XCTAssertEqual(entities.count, 4)
        guard case .line = entities[0] else { return XCTFail("0 should be a line") }
        guard case .circle = entities[1] else { return XCTFail("1 should be a circle") }
        guard case .arc = entities[2] else { return XCTFail("2 should be an arc") }
        guard case .spline = entities[3] else { return XCTFail("3 should be a spline") }
    }

    func testClosedPrimitiveEntitiesParse() {
        guard case let .addEntities(_, entities, _)? = op("""
        {"op":"sketch.addEntities","args":{"sketchID":"\(sketchUUID)","entities":[
          {"kind":"rect","min":[10,8],"max":[0,0]},
          {"kind":"polygon","center":[0,0],"radius":13.856,"sides":6},
          {"kind":"ellipse","center":[1,2],"radiusX":5,"radiusY":3}
        ]}}
        """) else { return }
        XCTAssertEqual(entities.count, 3)
        // rect normalizes corners so min is the lower-left regardless of order.
        guard case let .rect(_, mn, mx) = entities[0] else { return XCTFail("0 rect") }
        XCTAssertEqual(mn, SIMD2(0, 0))
        XCTAssertEqual(mx, SIMD2(10, 8))
        guard case let .polygon(_, _, r, sides, rot) = entities[1] else { return XCTFail("1 polygon") }
        XCTAssertEqual(sides, 6)
        XCTAssertEqual(r, 13.856, accuracy: 1e-9)
        XCTAssertEqual(rot, 0, "rotation defaults to 0")
        guard case let .ellipse(_, _, rx, ry, _) = entities[2] else { return XCTFail("2 ellipse") }
        XCTAssertEqual(rx, 5); XCTAssertEqual(ry, 3)
    }

    func testClosedPrimitivesRejectDegenerateArgs() {
        let head = #"{"op":"sketch.addEntities","args":{"sketchID":"\#(sketchUUID)","entities":["#
        XCTAssertEqual(code(head + #"{"kind":"rect","min":[0,0],"max":[0,5]}]}}"#), "degenerate_rect")
        XCTAssertEqual(code(head + #"{"kind":"polygon","center":[0,0],"radius":2,"sides":10001}]}}"#),
                       "bad_sides", "The exec path shares the keypad's 10,000-side ceiling")
        XCTAssertEqual(code(head + #"{"kind":"polygon","center":[0,0],"radius":2,"sides":2}]}}"#), "bad_sides")
        XCTAssertEqual(code(head + #"{"kind":"polygon","center":[0,0],"radius":2,"sides":5.5}]}}"#), "bad_sides")
        XCTAssertEqual(code(head + #"{"kind":"ellipse","center":[0,0],"radiusX":0,"radiusY":3}]}}"#), "bad_radius")
    }

    func testConstructionIndicesAreKeptAndBoundsChecked() {
        guard case let .addEntities(_, entities, construction)? = op("""
        {"op":"sketch.addEntities","args":{"sketchID":"\(sketchUUID)",
         "entities":[{"kind":"line","a":[0,0],"b":[1,0]}],
         "construction":[0, 7, -1]}}
        """) else { return }
        XCTAssertEqual(entities.count, 1)
        // 7 and -1 index nothing; keeping them would crash the applier later.
        XCTAssertEqual(construction, [0])
    }

    func testBadEntitiesAreNamedByIndex() {
        switch parse("""
        {"op":"sketch.addEntities","args":{"sketchID":"\(sketchUUID)","entities":[
          {"kind":"line","a":[0,0],"b":[1,1]},
          {"kind":"trapezoid"}
        ]}}
        """) {
        case .success: XCTFail("unknown entity kind should not parse")
        case .failure(let error):
            XCTAssertEqual(error.code, "unknown_entity_kind")
            // Which one is wrong matters when a sketch has forty of them.
            XCTAssertTrue(error.message.contains("entities[1]"), error.message)
        }
    }

    func testDegenerateGeometryIsRejected() {
        let head = #"{"op":"sketch.addEntities","args":{"sketchID":"\#(sketchUUID)","entities":["#
        XCTAssertEqual(code(head + #"{"kind":"line","a":[2,2],"b":[2,2]}]}}"#), "degenerate_line")
        XCTAssertEqual(code(head + #"{"kind":"circle","center":[0,0],"radius":0}]}}"#), "bad_radius")
        XCTAssertEqual(code(head + #"{"kind":"spline","points":[[0,0]]}]}}"#), "bad_spline")
    }

    // MARK: feature.extrude

    /// "end": throughAll / upToNext stands in for the distance (only its
    /// sign is read); a bad name is refused by name, and a taper cannot
    /// combine with an end condition.
    func testExtrudeEndConditionReplacesTheDistance() {
        guard case let .extrude(_, _, distance, _, _, _, _, end)?
            = op("""
            {"op":"feature.extrude","args":{"sketchID":"\(sketchUUID)",
             "seedPoint":[3,4],"end":"throughAll","boolean":"subtract",
             "booleanTargets":["\(bodyUUID)"]}}
            """) else { return }
        XCTAssertEqual(end, .throughAll)
        XCTAssertEqual(distance, 1, "no distance given → +1 placeholder carries the direction sign")
        guard case let .extrude(_, _, signed, _, _, _, _, end2)?
            = op("""
            {"op":"feature.extrude","args":{"sketchID":"\(sketchUUID)",
             "seedPoint":[3,4],"end":"upToNext","distance":-5}}
            """) else { return }
        XCTAssertEqual(end2, .upToNext)
        XCTAssertEqual(signed, -5, "a given distance keeps its sign for the direction")
        XCTAssertEqual(code("""
            {"op":"feature.extrude","args":{"sketchID":"\(sketchUUID)","seedPoint":[3,4],"end":"upToSurface"}}
            """), "unknown_end")
        XCTAssertEqual(code("""
            {"op":"feature.extrude","args":{"sketchID":"\(sketchUUID)","seedPoint":[3,4],"end":"throughAll","taperDegrees":5}}
            """), "end_with_taper")
    }

    func testExtrudeCarriesSeedAndDistance() {
        guard case let .extrude(sketch, seed, distance, symmetric, taper, boolean, targets, _)?
            = op("""
            {"op":"feature.extrude","args":{"sketchID":"\(sketchUUID)",
             "seedPoint":[3,4],"distance":12,"symmetric":true}}
            """) else { return }
        XCTAssertEqual(sketch.raw.uuidString, sketchUUID)
        XCTAssertEqual(seed, SIMD2(3, 4))
        XCTAssertEqual(distance, 12)
        XCTAssertTrue(symmetric)
        XCTAssertEqual(taper, 0, "no taper by default → a straight prism")
        XCTAssertEqual(boolean, .newBody)
        XCTAssertTrue(targets.isEmpty)
    }

    func testTaperDegreesMakesADraftExtrude() {
        guard case let .extrude(_, _, _, _, taper, _, _, _)? = op("""
        {"op":"feature.extrude","args":{"sketchID":"\(sketchUUID)","seedPoint":[0,0],
         "distance":20,"taperDegrees":10}}
        """) else { return XCTFail("expected .extrude with taper") }
        XCTAssertEqual(taper, 10)
        XCTAssertEqual(code("""
        {"op":"feature.extrude","args":{"sketchID":"\(sketchUUID)","seedPoint":[0,0],
         "distance":20,"taperDegrees":90}}
        """), "bad_taper", "a 90° taper has no far section")
    }

    func testZeroDistanceExtrudeIsRefusedRatherThanSilentlyDoingNothing() {
        XCTAssertEqual(code("""
        {"op":"feature.extrude","args":{"sketchID":"\(sketchUUID)","seedPoint":[0,0],"distance":0}}
        """), "zero_distance")
    }

    func testBooleanExtrudeWithoutTargetsIsRefused() {
        // The trap this guards: `subtract` with no targets is a perfectly
        // well-formed request that quietly produces a NEW BODY instead of
        // cutting anything — the agent would see "ok" and a wrong model.
        XCTAssertEqual(code("""
        {"op":"feature.extrude","args":{"sketchID":"\(sketchUUID)","seedPoint":[0,0],
         "distance":5,"boolean":"subtract"}}
        """), "missing_boolean_targets")
    }

    func testBooleanExtrudeWithTargetsParses() {
        guard case let .extrude(_, _, _, _, _, boolean, targets, _)? = op("""
        {"op":"feature.extrude","args":{"sketchID":"\(sketchUUID)","seedPoint":[0,0],
         "distance":5,"boolean":"subtract","booleanTargets":["\(bodyUUID)"]}}
        """) else { return }
        XCTAssertEqual(boolean, .subtract)
        XCTAssertEqual(targets.map(\.raw.uuidString), [bodyUUID])
    }

    func testBooleanAsAnObjectIsRefusedNotSilentlyANewBody() {
        // The FreeCAD-tutorial footgun: writing the op as a nested object
        // {"boolean":{"kind":"subtract"}} used to fail the string cast and
        // fall to the newBody default — a cut that silently became a stray
        // solid. It must be a typed refusal now, distinct from a bad op name.
        XCTAssertEqual(code("""
        {"op":"feature.extrude","args":{"sketchID":"\(sketchUUID)","seedPoint":[0,0],
         "distance":5,"boolean":{"kind":"subtract"},"booleanTargets":["\(bodyUUID)"]}}
        """), "bad_boolean_type")
        // A number is equally wrong-typed.
        XCTAssertEqual(code("""
        {"op":"feature.extrude","args":{"sketchID":"\(sketchUUID)","seedPoint":[0,0],
         "distance":5,"boolean":1}}
        """), "bad_boolean_type")
        // A bad STRING op stays its own distinct error (not conflated).
        XCTAssertEqual(code("""
        {"op":"feature.extrude","args":{"sketchID":"\(sketchUUID)","seedPoint":[0,0],
         "distance":5,"boolean":"nope"}}
        """), "unknown_boolean_op")
    }

    // MARK: feature.revolve

    func testRevolveKeepsDegreesAndNormalizesTheAxis() {
        guard case let .revolve(_, _, axis, angle, _, _)? = op("""
        {"op":"feature.revolve","args":{"sketchID":"\(sketchUUID)","seedPoint":[1,1],
         "axisPoint":[0,0],"axisDirection":[0,4],"angleDegrees":90}}
        """) else { return }
        // The graph's revolve Expr is in DEGREES — FeatureGraph converts once
        // at the OCCT boundary. Converting here as well produced a 6.28-degree
        // revolve that looked like a real solid and was silently wrong.
        XCTAssertEqual(angle, 90, accuracy: 1e-12)
        XCTAssertEqual(simd_length(axis.direction), 1, accuracy: 1e-12)
    }

    func testRevolveDefaultsToAFullTurn() {
        guard case let .revolve(_, _, _, angle, _, _)? = op("""
        {"op":"feature.revolve","args":{"sketchID":"\(sketchUUID)","seedPoint":[1,1],
         "axisPoint":[0,0],"axisDirection":[0,1]}}
        """) else { return }
        XCTAssertEqual(angle, 360, accuracy: 1e-12)
    }

    func testAbsurdAngleIsRefused() {
        XCTAssertEqual(code("""
        {"op":"feature.revolve","args":{"sketchID":"\(sketchUUID)","seedPoint":[1,1],
         "axisPoint":[0,0],"axisDirection":[0,1],"angleDegrees":3600}}
        """), "angle_out_of_range")
    }

    func testZeroLengthRevolveAxisIsRefused() {
        XCTAssertEqual(code("""
        {"op":"feature.revolve","args":{"sketchID":"\(sketchUUID)","seedPoint":[1,1],
         "axisPoint":[0,0],"axisDirection":[0,0]}}
        """), "degenerate_axis")
    }

    // MARK: feature.pattern / mirror / boolean

    func testCircularPatternCountIsTotalIncludingTheOriginal() {
        guard case let .pattern(_, spec)? = op("""
        {"op":"feature.pattern","args":{"bodyID":"\(bodyUUID)","kind":"circular",
         "axis":[0,2,0],"center":[0,0,0],"count":5,"totalAngleDegrees":360}}
        """) else { return }
        XCTAssertEqual(spec.kind, .circular)
        XCTAssertEqual(spec.count, 5)
        XCTAssertEqual(spec.totalAngle, 2 * .pi, accuracy: 1e-12)
        XCTAssertEqual(simd_length(spec.axis), 1, accuracy: 1e-12)
    }

    func testPatternCountBelowOneIsRefused() {
        XCTAssertEqual(code("""
        {"op":"feature.pattern","args":{"bodyID":"\(bodyUUID)","count":0}}
        """), "bad_count")
    }

    func testMirrorBuildsAPlaneWhoseNormalIsTheOneAsked() {
        guard case let .mirror(_, plane, keepOriginal)? = op("""
        {"op":"feature.mirror","args":{"bodyID":"\(bodyUUID)",
         "planeOrigin":[0,0,0],"planeNormal":[0,0,3]}}
        """) else { return }
        XCTAssertTrue(keepOriginal, "keepOriginal should default to true")
        // The two in-plane axes are arbitrary, but the normal they span is not.
        let n = simd_normalize(plane.normal)
        XCTAssertEqual(abs(simd_dot(n, SIMD3(0, 0, 1))), 1, accuracy: 1e-12)
    }

    /// A rotation about a centre is folded into the delta as T(c)·R·T(−c), then
    /// the translation is added: for 90° about z at (10,0,0) plus (1,2,3) the
    /// delta's translation is (10,0,0) − R(10,0,0) + (1,2,3) = (11, −8, 3).
    func testTransformFoldsRotationAboutACentreIntoTheDelta() throws {
        guard case let .transform(_, delta)? = op("""
        {"op":"feature.transform","args":{"bodyID":"\(bodyUUID)","translation":[1,2,3],
         "rotationAxis":[0,0,2],"rotationDegrees":90,"rotationCenter":[10,0,0]}}
        """) else { return XCTFail("expected .transform") }
        XCTAssertEqual(delta.translation.x, 11, accuracy: 1e-9)
        XCTAssertEqual(delta.translation.y, -8, accuracy: 1e-9)
        XCTAssertEqual(delta.translation.z, 3, accuracy: 1e-9)
        XCTAssertEqual(delta.rotation.angle, .pi / 2, accuracy: 1e-9)
        XCTAssertEqual(abs(delta.rotation.axis.z), 1, accuracy: 1e-9)
        XCTAssertEqual(delta.scale, 1)
    }

    /// A scale about a centre folds in like a rotation: ×2 about (10, 0, 0)
    /// leaves that point fixed — translation = c − 2c = (−10, 0, 0).
    func testTransformScaleAboutACentreKeepsThatPointFixed() throws {
        guard case let .transform(_, delta)? = op("""
        {"op":"feature.transform","args":{"bodyID":"\(bodyUUID)","scale":2,"rotationCenter":[10,0,0]}}
        """) else { return XCTFail("expected .transform") }
        XCTAssertEqual(delta.scale, 2)
        XCTAssertEqual(delta.translation.x, -10, accuracy: 1e-9)
        XCTAssertEqual(simd_distance(delta.applying(to: SIMD3(10, 0, 0)), SIMD3(10, 0, 0)), 0, accuracy: 1e-9)
        XCTAssertEqual(code("""
        {"op":"feature.transform","args":{"bodyID":"\(bodyUUID)","scale":0}}
        """), "bad_scale")
    }

    func testIdentityTransformIsRefusedAndAZeroAxisToo() {
        XCTAssertEqual(code("""
        {"op":"feature.transform","args":{"bodyID":"\(bodyUUID)"}}
        """), "identity_transform", "a move that moves nothing is a script bug")
        XCTAssertEqual(code("""
        {"op":"feature.transform","args":{"bodyID":"\(bodyUUID)","rotationDegrees":45,"rotationAxis":[0,0,0]}}
        """), "degenerate_axis")
    }

    func testBodyCannotBeItsOwnBooleanTool() {
        XCTAssertEqual(code("""
        {"op":"feature.boolean","args":{"kind":"subtract",
         "targetBodyID":"\(bodyUUID)","toolBodyIDs":["\(bodyUUID)"]}}
        """), "self_boolean")
    }

    func testUnknownBooleanKindIsRefused() {
        XCTAssertEqual(code("""
        {"op":"feature.boolean","args":{"kind":"merge",
         "targetBodyID":"\(bodyUUID)","toolBodyIDs":["\(sketchUUID)"]}}
        """), "unknown_boolean_kind")
    }

    // MARK: Decoding hygiene

    func testMalformedIdentifiersAndNumbersAreNamed() {
        XCTAssertEqual(code(#"{"op":"feature.pattern","args":{"bodyID":"not-a-uuid","count":2}}"#),
                       "bad_uuid")
        XCTAssertEqual(code(#"{"op":"feature.extrude","args":{"seedPoint":[0,0],"distance":1}}"#),
                       "missing_sketchID")
        XCTAssertEqual(code("""
        {"op":"feature.extrude","args":{"sketchID":"\(sketchUUID)","distance":1}}
        """), "missing_seedPoint")
    }
}
