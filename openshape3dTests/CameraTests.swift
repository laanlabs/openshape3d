//
//  CameraTests.swift
//  openshape3dTests
//
//  A7: orthographic projection, standard-view poses, and orientation-cube
//  hit-testing.
//

import XCTest
import simd
@testable import openshape3d

@MainActor
final class CameraTests: XCTestCase {

    private let viewport = CGSize(width: 1024, height: 768)

    // MARK: - Zoom

    /// `fit` sets distance directly, so a metre-scale model fits from beyond
    /// the old 2000 mm pinch cap — and a pinch-OUT then snapped the camera IN
    /// (a 1 m wheel jumped 1.29× closer on every zoom-out).
    func testPinchOutFromAFarFitNeverMovesCloser() {
        var camera = TurntableCamera()
        camera.fit(boundsMin: SIMD3(-500, 0, -500), boundsMax: SIMD3(500, 1000, 500))
        let fitted = camera.distance
        XCTAssertGreaterThan(fitted, 2000, "the scenario: a fit beyond the old cap")

        camera.zoom(scale: 0.8)   // fingers closing = zoom out
        XCTAssertEqual(camera.distance, fitted / 0.8, accuracy: 0.01)

        camera.zoom(scale: 2)     // zoom in still works from out here
        XCTAssertEqual(camera.distance, fitted / 0.8 / 2, accuracy: 0.01)
    }

    func testZoomOutStopsAtTheCeilingWithoutJumpingIn() {
        var camera = TurntableCamera()
        camera.distance = TurntableCamera.maxZoomDistance * 0.9
        camera.zoom(scale: 0.5)
        XCTAssertEqual(camera.distance, TurntableCamera.maxZoomDistance)

        camera.distance = TurntableCamera.maxZoomDistance * 2   // a fit past the ceiling
        camera.zoom(scale: 0.5)
        XCTAssertEqual(camera.distance, TurntableCamera.maxZoomDistance * 2,
                       "zooming out past the ceiling holds; it never pulls the camera in")
    }

    // MARK: - Fit

    /// The 40 × 24 mm mounting plate with its 4.5 mm boss (Y up).
    private let plateMin = SIMD3<Float>(-20, 0, -12)
    private let plateMax = SIMD3<Float>(20, 10.5, 12)

    /// Largest |NDC| over the AABB's eight corners: ≤ 1 means all in frame.
    private func worstCornerNDC(_ camera: TurntableCamera, aspect: Float,
                                min lo: SIMD3<Float>, max hi: SIMD3<Float>) -> (x: Float, y: Float) {
        var worst = (x: Float(0), y: Float(0))
        for i in 0..<8 {
            let corner = SIMD3<Float>(i & 1 == 0 ? lo.x : hi.x,
                                      i & 2 == 0 ? lo.y : hi.y,
                                      i & 4 == 0 ? lo.z : hi.z)
            let clip = camera.viewProjection(aspect: aspect) * SIMD4(corner, 1)
            worst.x = max(worst.x, abs(clip.x / clip.w))
            worst.y = max(worst.y, abs(clip.y / clip.w))
        }
        return worst
    }

    /// Measured 2026-09-14 on the iPhone 17 Pro Max (440 × 956 pt): the
    /// vertical-only fit put the plate's corners at x = −109 and 562.
    func testFitOnAPortraitPhoneKeepsTheWholeModelInFrame() {
        let phone: Float = 440.0 / 956.0
        var before = TurntableCamera()
        before.fit(boundsMin: plateMin, boundsMax: plateMax)
        XCTAssertGreaterThan(worstCornerNDC(before, aspect: phone, min: plateMin, max: plateMax).x, 1,
                             "the scenario: a vertical-only fit overflows a portrait phone's width")

        var camera = TurntableCamera()
        camera.fit(boundsMin: plateMin, boundsMax: plateMax, aspect: phone)
        let worst = worstCornerNDC(camera, aspect: phone, min: plateMin, max: plateMax)
        XCTAssertLessThan(worst.x, 1)
        XCTAssertLessThan(worst.y, 1)
    }

    func testFitOnALandscapeViewportIsUnchanged() {
        var vertical = TurntableCamera()
        vertical.fit(boundsMin: plateMin, boundsMax: plateMax)
        for aspect: Float in [1, 4.0 / 3.0, 16.0 / 10.0] {
            var camera = TurntableCamera()
            camera.fit(boundsMin: plateMin, boundsMax: plateMax, aspect: aspect)
            XCTAssertEqual(camera.distance, vertical.distance, accuracy: 1e-4,
                           "aspect \(aspect): the vertical FOV already binds")
        }
        var unknown = TurntableCamera()
        unknown.fit(boundsMin: plateMin, boundsMax: plateMax, aspect: nil)
        XCTAssertEqual(unknown.distance, vertical.distance, "no laid-out viewport keeps the vertical fit")
    }

    func testOrthographicFitOnAPortraitPhoneKeepsTheModelInFrame() {
        let phone: Float = 440.0 / 956.0
        var camera = TurntableCamera()
        camera.projection = .orthographic
        camera.fit(boundsMin: plateMin, boundsMax: plateMax, aspect: phone)
        let worst = worstCornerNDC(camera, aspect: phone, min: plateMin, max: plateMax)
        XCTAssertLessThan(worst.x, 1)
        XCTAssertLessThan(worst.y, 1)
    }

    // MARK: - Orthographic projection

    func testOrthographicRaysAreParallel() {
        var camera = TurntableCamera()
        camera.projection = .orthographic

        let a = camera.ray(through: CGPoint(x: 100, y: 100), viewportSize: viewport)
        let b = camera.ray(through: CGPoint(x: 900, y: 700), viewportSize: viewport)

        // Parallel directions, distinct origins (rays slide on the near plane).
        XCTAssertGreaterThan(simd_dot(a.direction, b.direction), 0.9999)
        XCTAssertGreaterThan(simd_length(a.origin - b.origin), 0.1)
    }

    func testPerspectiveRaysDiverge() {
        let camera = TurntableCamera()
        let a = camera.ray(through: CGPoint(x: 100, y: 100), viewportSize: viewport)
        let b = camera.ray(through: CGPoint(x: 900, y: 700), viewportSize: viewport)
        XCTAssertLessThan(simd_dot(a.direction, b.direction), 0.999)
    }

    func testOrthographicCenterRayHitsTarget() {
        var camera = TurntableCamera()
        camera.target = SIMD3(1, 2, 3)
        camera.projection = .orthographic

        let center = CGPoint(x: viewport.width / 2, y: viewport.height / 2)
        let ray = camera.ray(through: center, viewportSize: viewport)
        // The central ray runs down the view axis through the target.
        let toTarget = camera.target - ray.origin
        let along = simd_dot(toTarget, ray.direction)
        let miss = simd_length(toTarget - ray.direction * along)
        XCTAssertLessThan(miss, 1e-2)
        XCTAssertGreaterThan(along, 0)
    }

    func testOrthographicMatchesPerspectiveScaleAtTarget() {
        var camera = TurntableCamera()
        camera.elevation = 0
        camera.projection = .orthographic
        let aspect = Float(viewport.width / viewport.height)
        let projection = camera.projectionMatrix(aspect: aspect)
        // A point at the target depth, one frustum-half-height up, lands at
        // NDC y = 1 — same as the perspective frustum at that depth.
        let halfHeight = camera.distance * tan(camera.fovY * 0.5)
        let view = camera.viewMatrix
        let world = camera.target + SIMD3(0, halfHeight, 0)
        let eye = view * SIMD4(world, 1)
        var clip = projection * eye
        clip /= clip.w
        XCTAssertEqual(clip.y, 1, accuracy: 1e-3)
    }

    // MARK: - Standard views

    func testStandardViewPoses() {
        let camera = TurntableCamera()

        let front = StandardView.front.applied(to: camera)
        XCTAssertEqual(front.azimuth, 0, accuracy: 1e-6)
        XCTAssertEqual(front.elevation, 0, accuracy: 1e-6)

        let right = StandardView.right.applied(to: camera)
        XCTAssertEqual(right.azimuth, .pi / 2, accuracy: 1e-6)

        // Top/bottom stop at the ±89° clamp (1° off a true plan view) and
        // square the azimuth to the nearest quadrant (the default 36° → 0).
        let top = StandardView.top.applied(to: camera)
        XCTAssertEqual(top.elevation, TurntableCamera.elevationLimit, accuracy: 1e-6)
        XCTAssertEqual(top.azimuth, StandardView.nearestQuadrant(camera.azimuth), accuracy: 1e-6)
        let bottom = StandardView.bottom.applied(to: camera)
        XCTAssertEqual(bottom.elevation, -TurntableCamera.elevationLimit, accuracy: 1e-6)

        let iso = StandardView.isometric.applied(to: camera)
        XCTAssertEqual(iso.azimuth, .pi / 5, accuracy: 1e-6)
        XCTAssertEqual(iso.elevation, .pi / 7, accuracy: 1e-6)

        // Pose keeps target/distance/projection.
        XCTAssertEqual(front.target, camera.target)
        XCTAssertEqual(front.distance, camera.distance)
        XCTAssertEqual(front.projection, camera.projection)
    }

    // MARK: - Orientation cube

    func testCubeTapOutsideRectMisses() {
        let camera = TurntableCamera()
        XCTAssertNil(OrientationCube.hitPose(
            at: CGPoint(x: 10, y: 10), camera: camera, viewSize: viewport
        ))
    }

    func testCubeCenterTapFromFrontHitsFrontFace() {
        var camera = TurntableCamera()
        camera.azimuth = 0
        camera.elevation = 0

        let rect = OrientationCube.rect(in: viewport)
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let pose = OrientationCube.hitPose(at: center, camera: camera, viewSize: viewport)
        XCTAssertNotNil(pose)
        // Head-on already: the +Z face keeps the pose.
        XCTAssertEqual(pose?.azimuth ?? -1, 0, accuracy: 1e-4)
        XCTAssertEqual(pose?.elevation ?? -1, 0, accuracy: 1e-4)
    }

    func testCubeCornerTapSnapsToCornerView() {
        var camera = TurntableCamera()
        camera.azimuth = 0
        camera.elevation = 0

        // From the front view the top-right cube corner (+1,+1,+1) projects
        // toward the rect's top-right; probe a diagonal offset inside the
        // corner zone (|x|,|y| ≈ 0.8 of the half extent on the +Z face).
        let rect = OrientationCube.rect(in: viewport)
        let point = CGPoint(
            x: rect.midX + rect.width * 0.23,
            y: rect.midY - rect.height * 0.23
        )
        guard let pose = OrientationCube.hitPose(at: point, camera: camera, viewSize: viewport) else {
            return XCTFail("Corner tap should hit the cube")
        }
        let cornerElevation = asin(1 / sqrt(3.0))
        XCTAssertEqual(Double(pose.elevation), cornerElevation, accuracy: 1e-3)
        XCTAssertEqual(pose.azimuth, .pi / 4, accuracy: 1e-3)
    }

    func testCubeHitPoseIsIdempotent() {
        // Snapping to a face, then tapping the cube center again, returns the
        // same pose (the face is now head-on).
        var camera = TurntableCamera() // default iso-ish pose
        let rect = OrientationCube.rect(in: viewport)
        let center = CGPoint(x: rect.midX, y: rect.midY)
        guard let first = OrientationCube.hitPose(at: center, camera: camera, viewSize: viewport) else {
            return XCTFail("Center tap should hit the cube")
        }
        camera = first
        guard let second = OrientationCube.hitPose(at: center, camera: camera, viewSize: viewport) else {
            return XCTFail("Center tap should hit the cube after snapping")
        }
        XCTAssertEqual(second.azimuth, first.azimuth, accuracy: 1e-3)
        XCTAssertEqual(second.elevation, first.elevation, accuracy: 1e-3)
    }

    func testCubeSlabIntersection() {
        // Straight-on hit.
        let hit = OrientationCube.intersectCube(
            origin: SIMD3(0, 0, 4), direction: SIMD3(0, 0, -1)
        )
        XCTAssertEqual(hit?.z ?? 0, OrientationCube.halfExtent, accuracy: 1e-5)
        // Miss outside the slab.
        XCTAssertNil(OrientationCube.intersectCube(
            origin: SIMD3(3, 0, 4), direction: SIMD3(0, 0, -1)
        ))
    }

    // MARK: - Plan views end upright

    func testTopViewSquaresTheAzimuthToTheNearestQuadrant() {
        var cam = TurntableCamera()
        cam.azimuth = 36 * .pi / 180          // a stray orbit left the view rolled
        let top = StandardView.top.applied(to: cam)
        XCTAssertEqual(top.azimuth, 0, accuracy: 1e-6)
        XCTAssertEqual(top.elevation, TurntableCamera.elevationLimit, accuracy: 1e-6)
        cam.azimuth = 130 * .pi / 180
        XCTAssertEqual(StandardView.bottom.applied(to: cam).azimuth, .pi / 2, accuracy: 1e-6)
        cam.azimuth = -100 * .pi / 180
        XCTAssertEqual(StandardView.top.applied(to: cam).azimuth, -.pi / 2, accuracy: 1e-6)
    }
}
