//
//  SnapKindTests.swift
//  openshape3dTests
//
//  Named snaps. Shapr3D tells you WHICH snap caught the pointer while you
//  draw, so the tests pin the two things that makes possible: the snap knows
//  what it latched onto, and when several are in range the one a user would
//  expect wins.
//

import XCTest
import simd
@testable import openshape3d

final class SnapKindTests: XCTestCase {

    private func sketch(_ entities: [SketchEntity]) -> Sketch {
        Sketch(plane: .ground, entities: entities)
    }

    private let line = SketchEntity.line(
        id: UUID(), a: SIMD2(0, 0), b: SIMD2(10, 0))

    func testAcquisitionRadiusIsStableAcrossZoomAndGuidepointCategories() {
        for scale in [0.001, 0.01, 0.1, 1.0] {
            let endpoint = SIMD2<Double>(0, 0)
            let entity = SketchEntity.line(id: UUID(), a: endpoint, b: SIMD2(100 * scale, 0))
            let options = SnapOptions(grid: false, sketchGuidepoints: true, faceGuidepoints: false)
            let tolerance = SnapEngine.screenPointTolerance(worldUnitsPerPoint: scale)
            XCTAssertEqual(SnapEngine.snap(SIMD2(0, 5 * scale), in: sketch([entity]),
                options: options, tolerance: tolerance).kind, .endpoint)
            XCTAssertEqual(SnapEngine.snap(SIMD2(0, 20 * scale), in: sketch([entity]),
                options: options, tolerance: tolerance).kind, .free)
            XCTAssertEqual(SnapEngine.snap(SIMD2(50 * scale, 5 * scale), in: sketch([entity]),
                options: options, tolerance: tolerance).kind, .midpoint)
            let off = SnapOptions(grid: false, sketchGuidepoints: false, faceGuidepoints: false)
            XCTAssertEqual(SnapEngine.snap(SIMD2(0, 5 * scale), in: sketch([entity]),
                options: off, tolerance: tolerance).point, SIMD2(0, 5 * scale))
        }
    }

    // MARK: What the snap latched onto

    func testAnEndpointSnapIsNamedAsOne() {
        let result = SnapEngine.snap(SIMD2(10.05, 0.05), in: sketch([line]))
        XCTAssertEqual(result.kind, .endpoint)
        XCTAssertEqual(result.point, SIMD2(10, 0))
        XCTAssertTrue(result.snappedToPoint)
    }

    func testAMidpointSnapIsNamedAsOne() {
        let result = SnapEngine.snap(SIMD2(5.05, 0.05), in: sketch([line]))
        XCTAssertEqual(result.kind, .midpoint)
        XCTAssertEqual(result.point, SIMD2(5, 0))
    }

    func testACircleCentreSnapIsNamedAsOne() {
        let circle = SketchEntity.circle(id: UUID(), center: SIMD2(3, 4), radius: 2)
        let result = SnapEngine.snap(SIMD2(3.05, 4.05), in: sketch([circle]))
        XCTAssertEqual(result.kind, .center)
        XCTAssertEqual(result.point, SIMD2(3, 4))
    }

    func testFallingBackToTheGridIsNotAPointSnap() {
        let result = SnapEngine.snap(SIMD2(7.3, 9.1), in: sketch([line]))
        XCTAssertEqual(result.kind, .grid)
        XCTAssertFalse(result.snappedToPoint)
    }

    // MARK: Priority when several are in range

    func testAnEndpointBeatsAMidpointInRange() {
        // A very short line: its midpoint and endpoint are both within the
        // tolerance of the same probe. The endpoint is the harder commitment.
        let short = SketchEntity.line(id: UUID(), a: SIMD2(0, 0), b: SIMD2(0.4, 0))
        let result = SnapEngine.snap(SIMD2(0.12, 0), in: sketch([short]))
        XCTAssertEqual(result.kind, .endpoint)
        XCTAssertEqual(result.point, SIMD2(0, 0))
    }

    func testAMidpointBeatsACentreInRange() {
        // Rect edge midpoint at (5, 0) and… place a circle centre just inside
        // tolerance of the same probe.
        let rect = SketchEntity.rect(id: UUID(), min: SIMD2(0, 0), max: SIMD2(10, 6))
        let circle = SketchEntity.circle(id: UUID(), center: SIMD2(5.2, 0), radius: 1)
        let result = SnapEngine.snap(SIMD2(5.1, 0), in: sketch([rect, circle]))
        XCTAssertEqual(result.kind, .midpoint,
                       "a midpoint is a stronger intent than a centre")
    }

    func testTheNearerOfTwoEqualRankSnapsWins() {
        let a = SketchEntity.line(id: UUID(), a: SIMD2(0, 0), b: SIMD2(10, 0))
        let b = SketchEntity.line(id: UUID(), a: SIMD2(0.3, 0), b: SIMD2(10, 5))
        let result = SnapEngine.snap(SIMD2(0.05, 0), in: sketch([a, b]))
        XCTAssertEqual(result.point, SIMD2(0, 0))
    }

    // MARK: Rectangle gains edge midpoints (Shapr3D snaps to them)

    func testRectangleEdgeMidpointsAreSnappable() {
        let rect = SketchEntity.rect(id: UUID(), min: SIMD2(0, 0), max: SIMD2(10, 6))
        let bottom = SnapEngine.snap(SIMD2(5.05, 0.02), in: sketch([rect]))
        XCTAssertEqual(bottom.kind, .midpoint)
        XCTAssertEqual(bottom.point, SIMD2(5, 0))

        let left = SnapEngine.snap(SIMD2(0.02, 3.05), in: sketch([rect]))
        XCTAssertEqual(left.kind, .midpoint)
        XCTAssertEqual(left.point, SIMD2(0, 3))
    }

    func testRectangleCornersAreEndpoints() {
        let rect = SketchEntity.rect(id: UUID(), min: SIMD2(0, 0), max: SIMD2(10, 6))
        for corner in [SIMD2<Double>(0, 0), SIMD2(10, 0), SIMD2(10, 6), SIMD2(0, 6)] {
            let result = SnapEngine.snap(corner + SIMD2(0.02, 0.02), in: sketch([rect]))
            XCTAssertEqual(result.kind, .endpoint, "corner \(corner)")
            XCTAssertEqual(result.point, corner)
        }
    }

    func testRectangleCentreIsSnappable() {
        let rect = SketchEntity.rect(id: UUID(), min: SIMD2(0, 0), max: SIMD2(10, 6))
        let result = SnapEngine.snap(SIMD2(5.02, 3.02), in: sketch([rect]))
        XCTAssertEqual(result.kind, .center)
        XCTAssertEqual(result.point, SIMD2(5, 3))
    }

    func testArcMidpointIsSnappable() {
        let arc = SketchEntity.arc(id: UUID(), center: .zero, radius: 10,
                                   startAngle: 0, endAngle: .pi / 2)
        let mid = SIMD2(10 * cos(Double.pi / 4), 10 * sin(Double.pi / 4))
        let result = SnapEngine.snap(mid + SIMD2(0.02, 0.02), in: sketch([arc]))
        XCTAssertEqual(result.kind, .midpoint)
    }

    // MARK: Labels

    func testOnlyMeaningfulSnapsAreNamed() {
        XCTAssertEqual(SnapKind.endpoint.label, "Endpoint")
        XCTAssertEqual(SnapKind.midpoint.label, "Midpoint")
        XCTAssertEqual(SnapKind.center.label, "Center")
        XCTAssertNil(SnapKind.grid.label, "the grid is always on — naming it is noise")
        XCTAssertNil(SnapKind.free.label)
    }

    func testEveryNamedKindIsAPointSnap() {
        for kind in SnapKind.allCases where kind.label != nil {
            XCTAssertTrue(SnapResult(point: .zero, kind: kind).snappedToPoint,
                          "\(kind) is named, so it must count as a point snap")
        }
    }
}
