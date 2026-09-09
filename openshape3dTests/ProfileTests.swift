//
//  ProfileTests.swift
//  openshape3dTests
//

import XCTest
import simd
import Euclid
@testable import openshape3d

final class ProfileTests: XCTestCase {

    private func makeSketch(_ entities: [SketchEntity]) -> Sketch {
        Sketch(plane: .ground, entities: entities)
    }


    // MARK: - Junctions (shared endpoints)

    /// A divider drawn across a rectangle splits it into two regions. The old
    /// walker abandoned at any node whose degree wasn't 2, so the two shared
    /// corners (degree 3) killed BOTH cells and the outer boundary at once —
    /// and because `resolveProfile` re-runs detection on every rebuild and
    /// treats nil as a hard failure, an already-built body vanished the moment
    /// its sketch gained a junction (2026-08-25 review round 3).
    func testDividerAcrossARectangleYieldsTwoRegions() {
        // 4x2 rectangle with a vertical divider at x = 1.
        let bl = SIMD2<Double>(0, 0), br = SIMD2<Double>(4, 0)
        let tr = SIMD2<Double>(4, 2), tl = SIMD2<Double>(0, 2)
        let bm = SIMD2<Double>(1, 0), tm = SIMD2<Double>(1, 2)
        let sketch = makeSketch([
            .line(id: UUID(), a: bl, b: bm),
            .line(id: UUID(), a: bm, b: br),
            .line(id: UUID(), a: br, b: tr),
            .line(id: UUID(), a: tr, b: tm),
            .line(id: UUID(), a: tm, b: tl),
            .line(id: UUID(), a: tl, b: bl),
            .line(id: UUID(), a: bm, b: tm),   // the divider
        ])
        let profiles = ProfileDetector.detectProfiles(in: sketch)
        XCTAssertEqual(profiles.count, 2, "both cells must be detected")
        let areas = profiles.map(\.area).sorted()
        XCTAssertEqual(areas[0], 2, accuracy: 1e-9, "left cell 1x2")
        XCTAssertEqual(areas[1], 6, accuracy: 1e-9, "right cell 3x2")
        for profile in profiles {
            XCTAssertGreaterThan(profile.area, 0, "interior faces are CCW")
        }
    }

    /// Two rectangles mirrored about a shared edge — the corners on that edge
    /// have degree 4.
    func testTwoRectanglesSharingAnEdgeYieldTwoRegions() {
        let a = SIMD2<Double>(0, 0), b = SIMD2<Double>(2, 0)
        let c = SIMD2<Double>(2, 2), d = SIMD2<Double>(0, 2)
        let e = SIMD2<Double>(4, 0), f = SIMD2<Double>(4, 2)
        let sketch = makeSketch([
            .line(id: UUID(), a: a, b: b),
            .line(id: UUID(), a: b, b: c),   // shared edge
            .line(id: UUID(), a: c, b: d),
            .line(id: UUID(), a: d, b: a),
            .line(id: UUID(), a: b, b: e),
            .line(id: UUID(), a: e, b: f),
            .line(id: UUID(), a: f, b: c),
        ])
        let profiles = ProfileDetector.detectProfiles(in: sketch)
        XCTAssertEqual(profiles.count, 2)
        for profile in profiles {
            XCTAssertEqual(profile.area, 4, accuracy: 1e-9, "each cell is 2x2")
        }
    }

    /// The outer boundary must NOT come back as a profile of its own — a plain
    /// rectangle stays one region, not two (interior plus outline).
    func testAPlainRectangleFromLinesIsStillExactlyOneProfile() {
        let a = SIMD2<Double>(0, 0), b = SIMD2<Double>(3, 0)
        let c = SIMD2<Double>(3, 3), d = SIMD2<Double>(0, 3)
        let sketch = makeSketch([
            .line(id: UUID(), a: a, b: b),
            .line(id: UUID(), a: b, b: c),
            .line(id: UUID(), a: c, b: d),
            .line(id: UUID(), a: d, b: a),
        ])
        let profiles = ProfileDetector.detectProfiles(in: sketch)
        XCTAssertEqual(profiles.count, 1, "the outer face is not a profile")
        XCTAssertEqual(profiles[0].area, 9, accuracy: 1e-9)
    }

    /// A dangling line attached to a corner must not break detection.
    func testASpurAttachedToARectangleDoesNotBreakIt() {
        let a = SIMD2<Double>(0, 0), b = SIMD2<Double>(3, 0)
        let c = SIMD2<Double>(3, 3), d = SIMD2<Double>(0, 3)
        let sketch = makeSketch([
            .line(id: UUID(), a: a, b: b),
            .line(id: UUID(), a: b, b: c),
            .line(id: UUID(), a: c, b: d),
            .line(id: UUID(), a: d, b: a),
            .line(id: UUID(), a: c, b: SIMD2(5, 5)),   // spur sticking out
        ])
        let profiles = ProfileDetector.detectProfiles(in: sketch)
        XCTAssertEqual(profiles.count, 1, "the rectangle is still a region")
        XCTAssertEqual(profiles[0].area, 9, accuracy: 1e-9)
    }

    func testDuplicateStraightBoundaryKeepsProfileAndOriginalEdgeIdentity() throws {
        let a = SIMD2<Double>(0, 0), b = SIMD2<Double>(3, 0)
        let c = SIMD2<Double>(3, 2), d = SIMD2<Double>(0, 2)
        let original = UUID(), duplicate = UUID()
        let boundary: [SketchEntity] = [
            .line(id: original, a: a, b: b),
            .line(id: UUID(), a: b, b: c),
            .line(id: UUID(), a: c, b: d),
            .line(id: UUID(), a: d, b: a)
        ]
        for reversed in [false, true] {
            let sketch = makeSketch(boundary + [
                .line(id: duplicate, a: reversed ? b : a, b: reversed ? a : b)
            ])
            let profiles = ProfileDetector.detectProfiles(in: sketch)
            XCTAssertEqual(profiles.count, 1)
            let profile = try XCTUnwrap(profiles.first)
            XCTAssertEqual(profile.area, 6, accuracy: 1e-9)
            XCTAssertTrue(profile.contains(SIMD2(1, 1)))
            XCTAssertTrue(profile.edgeEntityIDs.contains(original))
            XCTAssertFalse(profile.edgeEntityIDs.contains(duplicate))
            XCTAssertEqual(sketch.entities.count, 5, "Detection must not delete editable duplicate entities")
        }
    }

    func testDuplicatedDividerStillSeparatesAdjacentProfiles() {
        let a = SIMD2<Double>(0, 0), b = SIMD2<Double>(2, 0)
        let c = SIMD2<Double>(2, 2), d = SIMD2<Double>(0, 2)
        let e = SIMD2<Double>(4, 0), f = SIMD2<Double>(4, 2)
        let sketch = makeSketch([
            .line(id: UUID(), a: a, b: b), .line(id: UUID(), a: b, b: c),
            .line(id: UUID(), a: c, b: d), .line(id: UUID(), a: d, b: a),
            .line(id: UUID(), a: b, b: e), .line(id: UUID(), a: e, b: f),
            .line(id: UUID(), a: f, b: c), .line(id: UUID(), a: c, b: b)
        ])
        let profiles = ProfileDetector.detectProfiles(in: sketch)
        XCTAssertEqual(profiles.count, 2)
        XCTAssertEqual(profiles.map(\.area).reduce(0, +), 8, accuracy: 1e-9)
    }

    func testPointTouchLoopsRemainIndependentRegions() {
        let loops: [[SIMD2<Double>]] = [
            [SIMD2(0, 0), SIMD2(2, 0), SIMD2(2, 2), SIMD2(0, 2)],
            [SIMD2(2, 2), SIMD2(3, 2), SIMD2(3, 3), SIMD2(2, 3)]
        ]
        let sketch = makeSketch(loops.flatMap { points in
            points.indices.map { i in
                SketchEntity.line(id: UUID(), a: points[i], b: points[(i + 1) % points.count])
            }
        })
        let profiles = ProfileDetector.detectProfiles(in: sketch)
        XCTAssertEqual(profiles.count, 2)
        XCTAssertEqual(profiles.map(\.area).reduce(0, +), 5, accuracy: 1e-9)
        for point in [SIMD2<Double>(1, 1), SIMD2<Double>(2.5, 2.5)] {
            XCTAssertEqual(profiles.filter { $0.contains(point) }.count, 1)
        }
    }

    func testPartialStraightBoundaryOverlapKeepsRegion() throws {
        let points: [SIMD2<Double>] = [SIMD2(0, 0), SIMD2(3, 0), SIMD2(3, 2), SIMD2(0, 2)]
        let boundary = points.indices.map { i in
            SketchEntity.line(id: UUID(), a: points[i], b: points[(i + 1) % points.count])
        }
        for endX in [2.0, 3.0] {
            for reversed in [false, true] {
                let a = SIMD2<Double>(1, 0), b = SIMD2<Double>(endX, 0)
                let sketch = makeSketch(boundary + [.line(id: UUID(), a: reversed ? b : a, b: reversed ? a : b)])
                let profiles = ProfileDetector.detectProfiles(in: sketch)
                XCTAssertEqual(profiles.count, 1)
                let profile = try XCTUnwrap(profiles.first)
                XCTAssertEqual(profile.area, 6, accuracy: 1e-9)
                XCTAssertTrue(profile.contains(SIMD2(1.5, 1)))
                XCTAssertEqual(sketch.entities.count, 5)
            }
        }
    }

    // MARK: - Detection


    func testRectEntityMakesProfile() {
        let sketch = makeSketch([
            .rect(id: UUID(), min: SIMD2(0, 0), max: SIMD2(4, 3)),
        ])
        let profiles = ProfileDetector.detectProfiles(in: sketch)
        XCTAssertEqual(profiles.count, 1)
        XCTAssertEqual(profiles[0].loop.count, 4)
        XCTAssertEqual(profiles[0].area, 12, accuracy: 1e-9, "CCW rect area is positive")
    }

    func testPolylineLoopDetected() {
        // Closed triangle from three lines.
        let a = SIMD2<Double>(0, 0)
        let b = SIMD2<Double>(4, 0)
        let c = SIMD2<Double>(2, 3)
        let sketch = makeSketch([
            .line(id: UUID(), a: a, b: b),
            .line(id: UUID(), a: b, b: c),
            .line(id: UUID(), a: c, b: a),
        ])
        let profiles = ProfileDetector.detectProfiles(in: sketch)
        XCTAssertEqual(profiles.count, 1)
        XCTAssertEqual(profiles[0].loop.count, 3)
        XCTAssertEqual(profiles[0].area, 6, accuracy: 1e-9)
    }

    func testOpenChainRejected() {
        let sketch = makeSketch([
            .line(id: UUID(), a: SIMD2(0, 0), b: SIMD2(4, 0)),
            .line(id: UUID(), a: SIMD2(4, 0), b: SIMD2(4, 3)),
        ])
        XCTAssertTrue(ProfileDetector.detectProfiles(in: sketch).isEmpty)
    }

    func testCircleProfileAndContainment() {
        let sketch = makeSketch([
            .circle(id: UUID(), center: SIMD2(1, 1), radius: 2),
        ])
        let profiles = ProfileDetector.detectProfiles(in: sketch)
        XCTAssertEqual(profiles.count, 1)
        XCTAssertTrue(profiles[0].contains(SIMD2(1, 1)))
        XCTAssertFalse(profiles[0].contains(SIMD2(4, 4)))
        XCTAssertEqual(profiles[0].area, .pi * 4, accuracy: 0.05)
    }

    func testNestedProfileReportedAsHole() {
        let outer = SketchEntity.rect(id: UUID(), min: SIMD2(-5, -5), max: SIMD2(5, 5))
        let inner = SketchEntity.circle(id: UUID(), center: SIMD2(0, 0), radius: 1.5)
        let sketch = makeSketch([outer, inner])
        let profiles = ProfileDetector.detectProfiles(in: sketch)
        XCTAssertEqual(profiles.count, 2)

        let outerProfile = profiles.max { abs($0.area) < abs($1.area) }!
        let holes = ProfileDetector.holes(of: outerProfile, among: profiles)
        XCTAssertEqual(holes.count, 1)
        if case .circle = holes[0].kind {} else {
            XCTFail("The hole should be the circle")
        }
    }

    func testInnermostProfileAtPoint() {
        let outer = SketchEntity.rect(id: UUID(), min: SIMD2(-5, -5), max: SIMD2(5, 5))
        let inner = SketchEntity.rect(id: UUID(), min: SIMD2(-1, -1), max: SIMD2(1, 1))
        let sketch = makeSketch([outer, inner])
        let hits = ProfileDetector.profiles(at: SIMD2(0, 0), in: sketch)
        XCTAssertEqual(hits.count, 2)
        XCTAssertEqual(abs(hits[0].area), 4, accuracy: 1e-9, "Innermost (smallest) first")
    }

    // MARK: - Extrusion

    func testExtrudeRectMakesBoxOnPlane() {
        let sketch = makeSketch([
            .rect(id: UUID(), min: SIMD2(0, 0), max: SIMD2(4, 3)),
        ])
        let profile = ProfileDetector.detectProfiles(in: sketch)[0]
        let mesh = KernelOps.extrude(profile: profile, in: .ground, distance: 5)

        XCTAssertTrue(mesh.isWatertight)
        let render = EuclidBridge.renderMesh(from: mesh)
        let aabb = render.localAABB
        // Ground plane: sketch x → world x, sketch y → world -z, normal +y.
        XCTAssertEqual(aabb.min.y, 0, accuracy: 1e-4, "Base sits on the sketch plane")
        XCTAssertEqual(aabb.max.y, 5, accuracy: 1e-4, "Pulled up by the distance")
        XCTAssertEqual(aabb.min.x, 0, accuracy: 1e-4)
        XCTAssertEqual(aabb.max.x, 4, accuracy: 1e-4)
        XCTAssertEqual(aabb.min.z, -3, accuracy: 1e-4)
        XCTAssertEqual(aabb.max.z, 0, accuracy: 1e-4)
    }

    func testExtrudeSymmetricCentersOnPlaneWithDoubleDepth() {
        let sketch = makeSketch([
            .rect(id: UUID(), min: SIMD2(0, 0), max: SIMD2(4, 3)),
        ])
        let profile = ProfileDetector.detectProfiles(in: sketch)[0]
        let mesh = KernelOps.extrude(profile: profile, in: .ground, distance: 5, symmetric: true)

        XCTAssertTrue(mesh.isWatertight)
        let aabb = EuclidBridge.renderMesh(from: mesh).localAABB
        // Spec §4.1: symmetric uses per-side values — 5 each way, 10 total,
        // centered on the sketch plane.
        XCTAssertEqual(aabb.min.y, -5, accuracy: 1e-4)
        XCTAssertEqual(aabb.max.y, 5, accuracy: 1e-4)
        XCTAssertEqual(aabb.min.x, 0, accuracy: 1e-4)
        XCTAssertEqual(aabb.max.x, 4, accuracy: 1e-4)
    }

    func testExtrudeNegativeDistanceGoesDown() {
        let sketch = makeSketch([
            .rect(id: UUID(), min: SIMD2(0, 0), max: SIMD2(2, 2)),
        ])
        let profile = ProfileDetector.detectProfiles(in: sketch)[0]
        let mesh = KernelOps.extrude(profile: profile, in: .ground, distance: -3)
        let aabb = EuclidBridge.renderMesh(from: mesh).localAABB
        XCTAssertEqual(aabb.max.y, 0, accuracy: 1e-4)
        XCTAssertEqual(aabb.min.y, -3, accuracy: 1e-4)
    }

    func testExtrudeCircleMakesCylinder() {
        let sketch = makeSketch([
            .circle(id: UUID(), center: SIMD2(0, 0), radius: 2),
        ])
        let profile = ProfileDetector.detectProfiles(in: sketch)[0]
        let mesh = KernelOps.extrude(profile: profile, in: .ground, distance: 4)
        XCTAssertTrue(mesh.isWatertight)
        let aabb = EuclidBridge.renderMesh(from: mesh).localAABB
        XCTAssertEqual(aabb.min.x, -2, accuracy: 0.01)
        XCTAssertEqual(aabb.max.y, 4, accuracy: 1e-4)
    }

    func testExtrudeWithHole() {
        let outerEntity = SketchEntity.rect(id: UUID(), min: SIMD2(-4, -4), max: SIMD2(4, 4))
        let holeEntity = SketchEntity.circle(id: UUID(), center: SIMD2(0, 0), radius: 1.5)
        let sketch = makeSketch([outerEntity, holeEntity])
        let profiles = ProfileDetector.detectProfiles(in: sketch)
        let outer = profiles.max { abs($0.area) < abs($1.area) }!
        let holes = ProfileDetector.holes(of: outer, among: profiles)

        let solid = KernelOps.extrude(profile: outer, holes: holes, in: .ground, distance: 2)
        let plain = KernelOps.extrude(profile: outer, in: .ground, distance: 2)

        // The holed solid must lose the cylinder's volume worth of geometry:
        // compare via polygon counts (hole adds an inner wall) and a ray probe.
        XCTAssertGreaterThan(solid.polygons.count, plain.polygons.count)

        let render = EuclidBridge.renderMesh(from: solid)
        let downRay = Ray(origin: SIMD3<Float>(0, 10, 0), direction: SIMD3(0, -1, 0))
        var hit = false
        let mesh = render
        var triangle = 0
        while triangle < mesh.triangleCount {
            let i0 = Int(mesh.indices[triangle * 3])
            let i1 = Int(mesh.indices[triangle * 3 + 1])
            let i2 = Int(mesh.indices[triangle * 3 + 2])
            triangle += 1
            if HitTester.intersectTriangle(
                ray: downRay,
                v0: mesh.positions[i0], v1: mesh.positions[i1], v2: mesh.positions[i2]
            ) != nil {
                hit = true
                break
            }
        }
        XCTAssertFalse(hit, "A ray straight down through the hole center must pass through")
    }
}

/// Endpoints that agree to a few microns but not to the node quantum still
/// close a loop — practice sheet 7.2's spherical cap (2026-09-05): the arc's
/// angles were derived from a line endpoint rounded to 1e-3, so the arc
/// started 2e-5 mm off the line and the loop was "unresolved".
final class ProfileEndpointWeldTests: XCTestCase {
    func testLineArcLoopWithMicronGapIsOneProfile() {
        let sketch = Sketch(plane: .ground, entities: [
            .line(id: UUID(), a: SIMD2(-105, 4), b: SIMD2(-94.802, 4)),
            .line(id: UUID(), a: SIMD2(-94.802, 4), b: SIMD2(-94.802, 5)),
            .arc(id: UUID(), center: SIMD2(-105, -6), radius: 15,
                 startAngle: 0.8232138851249898, endAngle: .pi / 2),
            .line(id: UUID(), a: SIMD2(-105, 9), b: SIMD2(-105, 4)),
        ])
        let profiles = ProfileDetector.detectProfiles(in: sketch)
        XCTAssertEqual(profiles.count, 1, "the line/step/arc/line loop closes")
        let area = abs(Profile.signedArea(profiles.first?.loop ?? []))
        // 10.198 wide, from y = 4 up to an arc running 5 → 9: ≈ 38 mm².
        // A sanity band, not a pin.
        XCTAssertGreaterThan(area, 30)
        XCTAssertLessThan(area, 45)
    }

    func testARealGapStillDoesNotClose() {
        let sketch = Sketch(plane: .ground, entities: [
            .line(id: UUID(), a: SIMD2(0, 0), b: SIMD2(10, 0)),
            .line(id: UUID(), a: SIMD2(10, 0), b: SIMD2(10, 5)),
            .line(id: UUID(), a: SIMD2(10, 5), b: SIMD2(0, 5)),
            .line(id: UUID(), a: SIMD2(0, 5), b: SIMD2(0, 0.05)),   // 50 µm short
        ])
        XCTAssertTrue(ProfileDetector.detectProfiles(in: sketch).isEmpty)
    }
}
