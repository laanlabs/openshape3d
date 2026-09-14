//
//  HeavyMeshGuardTests.swift
//  openshape3dTests
//
//  The three fixes from the LiDAR room-scan bug (2026-09-05): OBJ files
//  under 10 units read as metres, plane-picker tiles scale with the scene,
//  and heavy mesh-only bodies never enter a boolean.
//

import XCTest
@testable import openshape3d

final class HeavyMeshGuardTests: XCTestCase {

    // MARK: OBJ metres heuristic

    private func cubeOBJ(size: Double) -> Data {
        let s = size
        let text = """
        v 0 0 0
        v \(s) 0 0
        v \(s) \(s) 0
        v 0 \(s) 0
        v 0 0 \(s)
        v \(s) 0 \(s)
        v \(s) \(s) \(s)
        v 0 \(s) \(s)
        f 1 4 3 2
        f 5 6 7 8
        f 1 2 6 5
        f 2 3 7 6
        f 3 4 8 7
        f 4 1 5 8
        """
        return Data(text.utf8)
    }

    private func extent(_ mesh: RenderMesh) -> Float {
        let aabb = mesh.localAABB
        return max(aabb.max.x - aabb.min.x, aabb.max.y - aabb.min.y, aabb.max.z - aabb.min.z)
    }

    func testOBJUnderTenUnitsReadsAsMetres() throws {
        // A 4.7 m room scan: was 4.7 mm before the threshold moved from 2 to 10.
        let scan = try MeshImportKit.parts(from: cubeOBJ(size: 4.7), fileName: "scan.obj")
        XCTAssertEqual(extent(scan[0].mesh), 4700, accuracy: 0.01)
        // A 25-unit model stays 1:1 (millimetres).
        let part = try MeshImportKit.parts(from: cubeOBJ(size: 25), fileName: "part.obj")
        XCTAssertEqual(extent(part[0].mesh), 25, accuracy: 1e-4)
        // An explicit unit scale always wins.
        let forced = try MeshImportKit.parts(from: cubeOBJ(size: 4.7), fileName: "scan.obj", unitScale: 1)
        XCTAssertEqual(extent(forced[0].mesh), 4.7, accuracy: 1e-4)
    }

    // MARK: Plane picker tiles scale with the scene

    /// Origin plane pickers keep a constant on-screen size: as fractions of
    /// the outer edge they span 13 %…100 %, resolved at the camera's
    /// world-per-gizmo-unit (iPad, 2026-09-14: zoomed way out they were a
    /// speck, zoomed in a wall). Without a camera the 2.3 mm default holds.
    func testOriginPlaneTilesScaleWithTheGizmoUnitNotTheScene() {
        let unit = PlanePicking.originTiles
        XCTAssertEqual(unit.count, 3)
        XCTAssertTrue(unit.allSatisfy(\.screenProportional))
        XCTAssertEqual(unit[0].localMax.x, 1, accuracy: 1e-9)
        XCTAssertEqual(unit[0].localMin.x, PlanePicking.worldTileMin / PlanePicking.worldTileMax, accuracy: 1e-9)
        let cameraless = PlanePicking.worldTiles
        XCTAssertEqual(cameraless[0].localMax.x, PlanePicking.worldTileMax, accuracy: 1e-9)
        XCTAssertEqual(cameraless[0].localMin.x, PlanePicking.worldTileMin, accuracy: 1e-9)
        // Zoomed out on a metre-scale scan (gizmo unit 400 mm) a tile is
        // 600 mm; zoomed into a 3 mm part (gizmo unit 1 mm) it is 1.5 mm —
        // the same size on screen both times.
        XCTAssertEqual(PlanePicking.originTileScale(gizmoUnit: 400), 600, accuracy: 1e-9)
        XCTAssertEqual(unit[0].scaled(by: PlanePicking.originTileScale(gizmoUnit: 1)).localMax.x, 1.5, accuracy: 1e-9)
        XCTAssertEqual(unit[0].scaled(by: PlanePicking.originTileScale(gizmoUnit: 1)).localMin.x, 1.5 * PlanePicking.worldTileMin / PlanePicking.worldTileMax, accuracy: 1e-9)
    }

    // MARK: Heavy meshes stay out of booleans

    private func meshBody(triangles: Int, name: String = "Scan") -> Body {
        let positions: [SIMD3<Float>] = [SIMD3(0, 0, 0), SIMD3(1, 0, 0), SIMD3(0, 1, 0)]
        let normals: [SIMD3<Float>] = Array(repeating: SIMD3(0, 0, 1), count: 3)
        let indices = [UInt32](repeating: 0, count: triangles * 3)
        let render = RenderMesh(positions: positions, normals: normals, indices: indices)
        return Body(id: BodyID(raw: UUID()), name: name, transform: .identity,
                    primitive: nil, render: render, revision: 1)
    }

    func testHeavyMeshBodiesAreNotBooleanCandidates() {
        let light = meshBody(triangles: 12, name: "Cube")
        let atCap = meshBody(triangles: BooleanCandidacy.meshTriangleCap)
        let heavy = meshBody(triangles: 102_749, name: "Untitled_Scan")
        XCTAssertTrue(BooleanCandidacy.allows(light))
        XCTAssertTrue(BooleanCandidacy.allows(atCap), "the cap is inclusive")
        XCTAssertFalse(BooleanCandidacy.allows(heavy))
        XCTAssertEqual(BooleanCandidacy.heavyBodies(in: [light, heavy, atCap]).map(\.name),
                       ["Untitled_Scan"])
        let message = BooleanCandidacy.refusalMessage(for: heavy)
        XCTAssertTrue(message.contains("Untitled_Scan"))
        XCTAssertTrue(message.contains("102,749") || message.contains("102 749") || message.contains("102.749"),
                      "the message names the triangle count: \(message)")
        XCTAssertTrue(message.contains("New Body"))
    }
}
