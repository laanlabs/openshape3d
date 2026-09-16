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

    func testCrossedStraightOutlineExposesTwoTriangularRegions() {
        let points: [SIMD2<Double>] = [SIMD2(0, 0), SIMD2(4, 3), SIMD2(0, 3), SIMD2(4, 0)]
        let entities = points.indices.map { i in
            SketchEntity.line(id: UUID(), a: points[i], b: points[(i + 1) % points.count])
        }
        let sketch = makeSketch(entities)
        let profiles = ProfileDetector.detectProfiles(in: sketch)
        XCTAssertEqual(profiles.count, 2)
        XCTAssertEqual(profiles.map(\.area).reduce(0, +), 6, accuracy: 1e-9)
        for point in [SIMD2<Double>(2, 0.5), SIMD2<Double>(2, 2.5)] {
            XCTAssertEqual(profiles.filter { $0.contains(point) }.count, 1)
        }
        XCTAssertEqual(sketch.entities.count, 4, "Intersection nodes belong to the temporary graph, not the editable sketch")
        XCTAssertTrue(profiles.allSatisfy { $0.sourceEntityIDs.isSubset(of: Set(entities.map(\.id))) })
    }

    func testUnsplitStraightDividerCreatesTwoRegionsWithoutChangingSketch() {
        let points: [SIMD2<Double>] = [SIMD2(0, 0), SIMD2(4, 0), SIMD2(4, 2), SIMD2(0, 2)]
        var entities = points.indices.map { i in
            SketchEntity.line(id: UUID(), a: points[i], b: points[(i + 1) % points.count])
        }
        entities.append(.line(id: UUID(), a: SIMD2(1, 0), b: SIMD2(1, 2)))
        let sketch = makeSketch(entities)
        let profiles = ProfileDetector.detectProfiles(in: sketch)
        XCTAssertEqual(profiles.count, 2)
        XCTAssertEqual(profiles.map(\.area).reduce(0, +), 8, accuracy: 1e-9)
        XCTAssertEqual(sketch.entities.count, 5)
        XCTAssertEqual(profiles.filter { $0.contains(SIMD2(0.5, 1)) }.count, 1)
        XCTAssertEqual(profiles.filter { $0.contains(SIMD2(2, 1)) }.count, 1)
    }

    func testSavedNearlyCollinearOverlapKeepsBothTouchingRegions() {
        // Live saved sketch after further constrained drawing: the partial
        // top-edge overlap differs by roughly 4e-14 mm, not a visible gap.
        let entities: [SketchEntity] = [
            .line(id: UUID(), a: SIMD2(-2.373746275901889, 3.673585865586188), b: SIMD2(-1.6294044916705066, 3.673585865586189)),
            .line(id: UUID(), a: SIMD2(-1.6294044916705066, 3.673585865586189), b: SIMD2(-1.629404491670507, 2.9292402267455695)),
            .line(id: UUID(), a: SIMD2(-1.629404491670507, 2.9292402267455695), b: SIMD2(-2.3737462759017, 2.9292402267455695)),
            .line(id: UUID(), a: SIMD2(-2.3737462759017, 2.9292402267455695), b: SIMD2(-2.373746275901889, 3.673585865586188)),
            .line(id: UUID(), a: SIMD2(-1.629404491670507, 2.9292402267455695), b: SIMD2(-1.1331766843795776, 2.9292402267455695)),
            .line(id: UUID(), a: SIMD2(-1.1331766843795776, 2.9292402267455695), b: SIMD2(-1.1331766843795776, 2.436713218688899)),
            .line(id: UUID(), a: SIMD2(-1.1331766843795776, 2.436713218688899), b: SIMD2(-1.6294044916704575, 2.436713218688899)),
            .line(id: UUID(), a: SIMD2(-1.6294044916704575, 2.436713218688899), b: SIMD2(-1.629404491670507, 2.9292402267455695)),
            .line(id: UUID(), a: SIMD2(-2.1276707562923103, 3.673585865586149), b: SIMD2(-1.6294044916705066, 3.673585865586189))
        ]
        for ordered in [entities, Array(entities.reversed())] {
            let sketch = makeSketch(ordered)
            let profiles = ProfileDetector.detectProfiles(in: sketch)
            XCTAssertEqual(profiles.count, 2)
            XCTAssertEqual(profiles.filter { $0.contains(SIMD2(-2, 3.3)) }.count, 1)
            XCTAssertEqual(profiles.filter { $0.contains(SIMD2(-1.4, 2.7)) }.count, 1)
            XCTAssertEqual(sketch.entities.count, 9)
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

final class ProfileCrossingOutlineTests: XCTestCase {

    // MARK: - Crossing outlines (2026-09-16)
    //
    // Closed shapes were never split: two overlapping circles came back as two
    // full circles, and `holes(of:)` (centroid test) took the smaller for a
    // hole of the larger. Extruding the region between them built a face whose
    // inner wire crossed its outer one: an invalid solid with the whole small
    // circle subtracted (practice sheet 18.8B, repro: 20 043.361 mm³ where the
    // region is 20 188.652).

    private func makeSketch(_ entities: [SketchEntity]) -> Sketch {
        Sketch(plane: .ground, entities: entities)
    }

    /// Area where circle (c1, r1) and circle at distance d with radius r2 overlap.
    private func lensArea(_ r1: Double, _ r2: Double, _ d: Double) -> Double {
        let a1: Double = r1 * r1 * acos((d * d + r1 * r1 - r2 * r2) / (2 * d * r1))
        let a2: Double = r2 * r2 * acos((d * d + r2 * r2 - r1 * r1) / (2 * d * r2))
        let k: Double = (-d + r1 + r2) * (d + r1 - r2) * (d - r1 + r2) * (d + r1 + r2)
        return a1 + a2 - 0.5 * sqrt(k)
    }

    private func crossingCircles() -> Sketch {
        makeSketch([
            .circle(id: UUID(), center: SIMD2(0, 0), radius: 40),
            .circle(id: UUID(), center: SIMD2(0, 24), radius: 18),
        ])
    }

    func testTwoCrossingCirclesGiveALensAndTwoCrescents() {
        let profiles = ProfileDetector.detectProfiles(in: crossingCircles())
        XCTAssertEqual(profiles.count, 3, "big crescent, lens, small outer part")
        for profile in profiles {
            if case .circle = profile.kind { XCTFail("a crossed circle must not stay a full-circle profile") }
            XCTAssertGreaterThan(profile.area, 0)
            XCTAssertFalse(profile.segments.isEmpty, "arc boundaries reach the kernel exactly")
        }
        let lens: Double = lensArea(40, 18, 24)
        let expected: [Double] = [lens, Double.pi * 18 * 18 - lens, Double.pi * 40 * 40 - lens].sorted()
        let areas = profiles.map(\.area).sorted()
        for (got, want) in zip(areas, expected) {
            XCTAssertEqual(got, want, accuracy: want * 0.01, "tessellated area within 1 %")
        }
    }

    func testTheCrescentExtrudesToTheExactRegionAndAValidSolid() throws {
        let sketch = crossingCircles()
        let outer = try XCTUnwrap(ProfileDetector.profiles(at: SIMD2(0, -20), in: sketch).first)
        let holes = ProfileDetector.holes(of: outer, among: ProfileDetector.detectProfiles(in: sketch))
        XCTAssertTrue(holes.isEmpty, "the small circle crosses the region: it is not a hole")
        let solid = try XCTUnwrap(OCCTKernel.extrudeShape(
            outerLoop: outer.loop, holes: [], zMin: 0, zMax: 5,
            origin: .zero, xAxis: SIMD3(1, 0, 0), yAxis: SIMD3(0, 1, 0), normal: SIMD3(0, 0, 1),
            outerSegments: outer.segments))
        let region: Double = Double.pi * 40 * 40 - lensArea(40, 18, 24)
        let health = OCCTKernel.healthReport(for: solid)
        XCTAssertTrue(health.isValid, "findings: \(health.findings)")
        XCTAssertEqual(OCCTKernel.volume(solid), region * 5, accuracy: 0.01,
                       "20 188.652 mm³: the crescent, not the disc minus the whole small circle")
    }

    func testALineAcrossACircleGivesTwoRegions() {
        let sketch = makeSketch([
            .circle(id: UUID(), center: .zero, radius: 10),
            .line(id: UUID(), a: SIMD2(-20, 4), b: SIMD2(20, 4)),
        ])
        let profiles = ProfileDetector.detectProfiles(in: sketch)
        XCTAssertEqual(profiles.count, 2)
        let cap: Double = 100 * acos(0.4) - 4 * sqrt(84.0)
        let expected: [Double] = [cap, Double.pi * 100 - cap].sorted()
        for (got, want) in zip(profiles.map(\.area).sorted(), expected) {
            XCTAssertEqual(got, want, accuracy: want * 0.01)
        }
    }

    func testARectCrossedByACircleGivesThreeRegions() {
        let sketch = makeSketch([
            .rect(id: UUID(), min: SIMD2(0, 0), max: SIMD2(20, 20)),
            .circle(id: UUID(), center: SIMD2(20, 10), radius: 6),
        ])
        let profiles = ProfileDetector.detectProfiles(in: sketch)
        XCTAssertEqual(profiles.count, 3, "rect minus the half disc, and the two half discs")
        let half: Double = Double.pi * 36 / 2
        let expected: [Double] = [half, half, 400 - half]
        for (got, want) in zip(profiles.map(\.area).sorted(), expected) {
            XCTAssertEqual(got, want, accuracy: want * 0.01)
        }
    }

    func testShapesThatDoNotCrossStayStandaloneAndNest() throws {
        let sketch = makeSketch([
            .rect(id: UUID(), min: SIMD2(-20, -20), max: SIMD2(20, 20)),
            .circle(id: UUID(), center: .zero, radius: 10),
        ])
        let profiles = ProfileDetector.detectProfiles(in: sketch)
        XCTAssertEqual(profiles.count, 2)
        XCTAssertEqual(profiles.filter { if case .circle = $0.kind { return true }; return false }.count, 1,
                       "an uncrossed circle stays a circle profile")
        let outer = try XCTUnwrap(ProfileDetector.profiles(at: SIMD2(15, 15), in: sketch).first)
        XCTAssertEqual(ProfileDetector.holes(of: outer, among: profiles).count, 1, "the circle is still a hole")
    }

    func testACircleTouchedAtOnePointStaysOneCircle() {
        let sketch = makeSketch([
            .circle(id: UUID(), center: .zero, radius: 10),
            .line(id: UUID(), a: SIMD2(0, 20), b: SIMD2(0, 10)),
        ])
        let profiles = ProfileDetector.detectProfiles(in: sketch)
        XCTAssertEqual(profiles.count, 1)
        if let only = profiles.first, case .circle = only.kind {} else { XCTFail("still a standalone circle") }
    }

    /// Touching isn't crossing: a hole tangent to the boundary it sits in
    /// stays a hole. At an arbitrary angle the two tessellations' chords
    /// cross and a vertex pokes out, so neither may decide it.
    func testAHoleTangentToItsBoundaryStaysAHole() throws {
        let tilt = 37 * Double.pi / 180
        let layouts: [(String, SketchEntity, SIMD2<Double>, SIMD2<Double>)] = [
            ("circle, tangent at 37°", .circle(id: UUID(), center: .zero, radius: 10),
             SIMD2(cos(tilt), sin(tilt)) * 5, SIMD2(-8, 0)),
            ("circle, tangent at 0°", .circle(id: UUID(), center: .zero, radius: 10),
             SIMD2(5, 0), SIMD2(-8, 0)),
            ("rect side", .rect(id: UUID(), min: SIMD2(-10, -10), max: SIMD2(10, 10)),
             SIMD2(5, 3.3), SIMD2(-8, 0)),
        ]
        for (name, boundary, holeCenter, pick) in layouts {
            let sketch = makeSketch([boundary, .circle(id: UUID(), center: holeCenter, radius: 5)])
            let all = ProfileDetector.detectProfiles(in: sketch)
            XCTAssertEqual(all.count, 2, "\(name): touching splits nothing")
            let outer = try XCTUnwrap(ProfileDetector.profiles(at: pick, in: sketch).first, name)
            XCTAssertEqual(ProfileDetector.holes(of: outer, among: all).count, 1, name)
        }
    }

    /// Touching at two points doesn't split either: a circle in a rect's
    /// corner, tangent to both sides, stays a hole of the rect (the corner
    /// between them is not a region of its own, as before crossings were
    /// split). See `ProfileDetector.splits(at:side:others:)` for why.
    func testACircleTouchingTwoSidesStaysAHole() throws {
        let sketch = makeSketch([
            .rect(id: UUID(), min: SIMD2(-10, -10), max: SIMD2(10, 10)),
            .circle(id: UUID(), center: SIMD2(5, 5), radius: 5),
        ])
        let all = ProfileDetector.detectProfiles(in: sketch)
        XCTAssertEqual(all.count, 2)
        let rect = try XCTUnwrap(ProfileDetector.profiles(at: SIMD2(-8, -8), in: sketch).first)
        XCTAssertEqual(ProfileDetector.holes(of: rect, among: all).count, 1)
    }

    /// A line ending on a circle is a junction, not a touch: two radii cut a
    /// quarter slice out of the disc.
    func testTwoRadiiCutASliceOutOfACircle() throws {
        let sketch = makeSketch([
            .circle(id: UUID(), center: .zero, radius: 10),
            .line(id: UUID(), a: .zero, b: SIMD2(10, 0)),
            .line(id: UUID(), a: .zero, b: SIMD2(0, 10)),
        ])
        let all = ProfileDetector.detectProfiles(in: sketch)
        XCTAssertEqual(all.count, 2, "the slice and the rest")
        let slice = try XCTUnwrap(ProfileDetector.profiles(at: SIMD2(4, 4), in: sketch).first)
        XCTAssertEqual(slice.area, Double.pi * 25, accuracy: Double.pi * 25 * 0.01)
        let rest = try XCTUnwrap(ProfileDetector.profiles(at: SIMD2(-4, -4), in: sketch).first)
        XCTAssertEqual(rest.area, Double.pi * 75, accuracy: Double.pi * 75 * 0.01)
    }

    /// Practice problem 13.9's front sketch: the hull of three R40 tubes,
    /// touching its Ø200 outer circle at three points, is a hole of the
    /// circle. Checked with the tubes as chords (the recipe) and as exact
    /// arcs.
    ///
    /// With short spokes outside the circle ending at the touch points, the
    /// points do split. The curves leave them nearly together, and ordering
    /// them by tessellation chord (a 7.5° circle chord leans further than a
    /// 5° tube chord) swapped them: the walk produced one region over the
    /// whole disc. Ordered by the exact arc, no region under a lobe point is
    /// bigger than the lobe.
    func testAHullTouchingItsOuterCircleStaysAHole() throws {
        let tubeRadius = 40.0, pitch = 60.0
        let centers = [90.0, 210.0, 330.0].map { SIMD2(cos($0 * .pi / 180), sin($0 * .pi / 180)) * pitch }
        let side: Double = pitch * 3.0.squareRoot()
        let hullArea: Double = 3.0.squareRoot() / 4 * side * side + 3 * side * tubeRadius
            + Double.pi * tubeRadius * tubeRadius
        let lobeArea: Double = (Double.pi * 100 * 100 - hullArea) / 3
        func onTube(_ i: Int, _ degrees: Double) -> SIMD2<Double> {
            centers[i] + SIMD2(cos(degrees * .pi / 180), sin(degrees * .pi / 180)) * tubeRadius
        }
        let tubeAngles = [90.0, 210.0, 330.0]
        let lobePoint = SIMD2(cos(Double.pi / 6), sin(Double.pi / 6)) * 90

        var chordHull: [SketchEntity] = []
        var arcHull: [SketchEntity] = []
        var spokes: [SketchEntity] = []
        for i in 0..<3 {
            let a = tubeAngles[i]
            let next = (i + 1) % 3
            let steps = 24
            for k in 0..<steps {
                chordHull.append(.line(id: UUID(), a: onTube(i, a - 60 + 120 * Double(k) / Double(steps)),
                                       b: onTube(i, a - 60 + 120 * Double(k + 1) / Double(steps))))
            }
            chordHull.append(.line(id: UUID(), a: onTube(i, a + 60), b: onTube(next, a + 60)))
            arcHull.append(.arc(id: UUID(), center: centers[i], radius: tubeRadius,
                                startAngle: (a - 60) * .pi / 180, endAngle: (a + 60) * .pi / 180))
            arcHull.append(.line(id: UUID(), a: onTube(i, a + 60), b: onTube(next, a + 60)))
            let outward = SIMD2(cos(a * .pi / 180), sin(a * .pi / 180))
            spokes.append(.line(id: UUID(), a: onTube(i, a), b: onTube(i, a) + outward * 5))
        }
        for (name, hull) in [("chords", chordHull), ("arcs", arcHull)] {
            let sketch = makeSketch([.circle(id: UUID(), center: .zero, radius: 100)] + hull)
            let all = ProfileDetector.detectProfiles(in: sketch)
            XCTAssertEqual(all.count, 2, "\(name): the circle and the hull")
            let circle = try XCTUnwrap(ProfileDetector.profiles(at: lobePoint, in: sketch).first, name)
            if case .circle = circle.kind {} else { XCTFail("\(name): the pick is the whole circle") }
            XCTAssertEqual(ProfileDetector.holes(of: circle, among: all).count, 1, "\(name): the hull is its hole")
        }
        let split = makeSketch([.circle(id: UUID(), center: .zero, radius: 100)] + chordHull + spokes)
        for region in ProfileDetector.profiles(at: lobePoint, in: split) {
            XCTAssertLessThan(abs(region.area), lobeArea * 1.1, "never a region over the whole disc")
        }
    }

    /// Regions of one arrangement sit side by side, so none is a hole of
    /// another, even where a C-shaped region's vertex average falls in its
    /// neighbour.
    func testNoRegionOfACrossingArrangementIsAHoleOfAnother() {
        for sketch in [crossingCircles(), makeSketch([
            .circle(id: UUID(), center: .zero, radius: 20),
            .circle(id: UUID(), center: SIMD2(0, 4), radius: 19),
        ])] {
            let all = ProfileDetector.detectProfiles(in: sketch)
            XCTAssertEqual(all.count, 3)
            for outer in all {
                XCTAssertTrue(ProfileDetector.holes(of: outer, among: all).isEmpty)
            }
        }
    }

    /// Ellipses aren't split: a circle an ellipse crosses is neither a hole of
    /// anything nor pickable, so extruding it is refused instead of wrong.
    func testAnEllipseCrossingACircleIsNeverAHoleAndIsRefused() {
        let sketch = makeSketch([
            .circle(id: UUID(), center: .zero, radius: 10),
            .ellipse(id: UUID(), center: SIMD2(0, 9), radiusX: 6, radiusY: 4, rotation: 0),
        ])
        let all = ProfileDetector.detectProfiles(in: sketch)
        for outer in all {
            XCTAssertTrue(ProfileDetector.holes(of: outer, among: all).isEmpty)
        }
        XCTAssertTrue(ProfileDetector.profiles(at: SIMD2(0, -5), in: sketch).isEmpty,
                      "the region under the point isn't the circle: refuse")
    }
}
