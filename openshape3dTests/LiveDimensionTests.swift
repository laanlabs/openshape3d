//
//  LiveDimensionTests.swift
//  openshape3dTests
//
//  Live sketch dimensions (§1.1) — the numbers shown WHILE drawing. What
//  matters is that they read the shape the user is actually making: a
//  rectangle's two sides, a circle's diameter (not radius), and a leader that
//  sits clear of the geometry instead of on top of it.
//

import XCTest
import simd
@testable import openshape3d

final class LiveDimensionTests: XCTestCase {

    private func dims(_ entity: SketchEntity,
                      towards: SIMD2<Double>? = nil) -> [LiveDimensionKit.Dimension] {
        LiveDimensionKit.dimensions(for: entity, towards: towards)
    }

    // MARK: Rectangle — two sides, like the Shapr3D readout

    func testRectangleReportsWidthAndHeight() {
        let rect = SketchEntity.rect(id: UUID(), min: SIMD2(0, 0), max: SIMD2(480, 210))
        let out = dims(rect)
        XCTAssertEqual(out.map(\.id), ["width", "height"])
        XCTAssertEqual(out[0].value, 480, accuracy: 1e-9)
        XCTAssertEqual(out[1].value, 210, accuracy: 1e-9)
    }

    func testRectangleDimensionsSitClearOfTheShape() {
        let rect = SketchEntity.rect(id: UUID(), min: SIMD2(0, 0), max: SIMD2(480, 210))
        let out = dims(rect)
        // Width runs below the rectangle, height to its left.
        XCTAssertLessThan(out[0].lineStart.y, 0)
        XCTAssertEqual(out[0].lineStart.y, out[0].lineEnd.y, accuracy: 1e-9,
                       "the width leader stays horizontal")
        XCTAssertLessThan(out[1].lineStart.x, 0)
        XCTAssertEqual(out[1].lineStart.x, out[1].lineEnd.x, accuracy: 1e-9)
    }

    func testALineOfZeroWidthDropsThatDimensionRatherThanShowingZero() {
        let degenerate = SketchEntity.rect(id: UUID(), min: SIMD2(5, 0), max: SIMD2(5, 60))
        XCTAssertEqual(dims(degenerate).map(\.id), ["height"])
    }

    func testAFreshTapProducesNoDimensions() {
        let tap = SketchEntity.rect(id: UUID(), min: SIMD2(3, 3), max: SIMD2(3, 3))
        XCTAssertTrue(dims(tap).isEmpty, "a zero-size drag has nothing to report")
    }

    // MARK: Circle — diameter, swung to follow the drag

    func testCircleReportsDiameterNotRadius() {
        let circle = SketchEntity.circle(id: UUID(), center: .zero, radius: 330.7998)
        let out = dims(circle)
        XCTAssertEqual(out.count, 1)
        XCTAssertEqual(out[0].kind, .diameter)
        XCTAssertEqual(out[0].value, 661.5996, accuracy: 1e-9)
    }

    func testDiameterIsDrawnThroughTheCentreAlongTheDrag() {
        let circle = SketchEntity.circle(id: UUID(), center: SIMD2(10, 10), radius: 5)
        let out = dims(circle, towards: SIMD2(10, 99))   // dragging straight up
        let d = out[0]
        XCTAssertEqual(d.offset, .zero, "a diameter is drawn across the shape, not beside it")
        XCTAssertEqual(d.start, SIMD2(10, 5))
        XCTAssertEqual(d.end, SIMD2(10, 15))
        XCTAssertEqual(d.labelPoint.x, 10, accuracy: 1e-9,
                       "the label stays on the diameter line")
    }

    func testDiameterIsTickedAtTheCircleEdgesAndNotWitnessed() {
        let d = dims(.circle(id: UUID(), center: .zero, radius: 4))[0]
        XCTAssertTrue(d.kind.drawsEdgeTicks,
                      "a diameter needs a mark where it meets the circle")
        XCTAssertEqual(d.offset, .zero,
                       "…and no witness leaders, since it sits on the geometry")
        // Ticks go at the endpoints, which are ON the circle.
        XCTAssertEqual(simd_length(d.lineStart), 4, accuracy: 1e-9)
        XCTAssertEqual(simd_length(d.lineEnd), 4, accuracy: 1e-9)
    }

    func testAnOffsetDimensionIsWitnessedRatherThanTicked() {
        let d = dims(.line(id: UUID(), a: .zero, b: SIMD2(30, 40)))[0]
        XCTAssertFalse(d.kind.drawsEdgeTicks,
                       "an offset leader already registers via its witness lines")
    }

    func testTheDiameterLabelSlidesOffTheCentre() {
        // The circle's centre carries the drag origin and its own marker, so
        // parking the value there covers them.
        let d = dims(.circle(id: UUID(), center: .zero, radius: 10),
                     towards: SIMD2(10, 0))[0]
        XCTAssertGreaterThan(d.labelPoint.x, 0, "slid toward one end")
        XCTAssertLessThan(d.labelPoint.x, 10, "…but still on the line")
        XCTAssertEqual(d.labelPoint.y, 0, accuracy: 1e-9)
    }

    func testAnOffsetDimensionStillLabelsItsMidpoint() {
        let d = dims(.line(id: UUID(), a: .zero, b: SIMD2(100, 0)))[0]
        XCTAssertEqual(d.labelPoint.x, 50, accuracy: 1e-9)
    }

    func testWithoutADragHintTheDiameterIsHorizontal() {
        let out = dims(.circle(id: UUID(), center: .zero, radius: 4))
        XCTAssertEqual(out[0].start, SIMD2(-4, 0))
        XCTAssertEqual(out[0].end, SIMD2(4, 0))
    }

    func testACollapsedCircleReportsNothing() {
        XCTAssertTrue(dims(.circle(id: UUID(), center: .zero, radius: 0)).isEmpty)
    }

    // MARK: Line

    func testLineReportsItsLengthOffsetToOneSide() {
        let line = SketchEntity.line(id: UUID(), a: SIMD2(0, 0), b: SIMD2(30, 40))
        let out = dims(line)
        XCTAssertEqual(out.count, 1)
        XCTAssertEqual(out[0].value, 50, accuracy: 1e-9)
        // The leader is parallel to the line but not on it.
        XCTAssertEqual(simd_length(out[0].lineEnd - out[0].lineStart), 50, accuracy: 1e-9)
        XCTAssertGreaterThan(simd_length(out[0].offset), 1)
        XCTAssertEqual(simd_dot(out[0].offset, SIMD2(30, 40)), 0, accuracy: 1e-9,
                       "the offset is perpendicular, so the leader stays parallel")
    }

    func testTheOffsetScalesWithTheDrawing() {
        // The annotation must look the same at 5 mm and 5 m, so the offset is a
        // fraction of the span rather than a fixed distance.
        let small = dims(.line(id: UUID(), a: .zero, b: SIMD2(5, 0)))[0]
        let large = dims(.line(id: UUID(), a: .zero, b: SIMD2(5000, 0)))[0]
        XCTAssertEqual(simd_length(large.offset) / simd_length(small.offset), 1000,
                       accuracy: 1e-6)
    }

    // MARK: Other entities

    func testPolygonReportsItsCircumscribedDiameter() {
        let hex = SketchEntity.polygon(id: UUID(), center: .zero, radius: 12,
                                       sides: 6, rotation: 0)
        let out = dims(hex)
        XCTAssertEqual(out[0].kind, .diameter)
        XCTAssertEqual(out[0].value, 24, accuracy: 1e-9,
                       "polygons are drawn from their circumscribed circle")
    }

    func testEllipseReportsBothAxes() {
        let ellipse = SketchEntity.ellipse(id: UUID(), center: .zero,
                                           radiusX: 20, radiusY: 8, rotation: 0)
        let out = dims(ellipse)
        XCTAssertEqual(out.map(\.value), [40, 16])
        XCTAssertEqual(simd_dot(out[0].end - out[0].start, out[1].end - out[1].start),
                       0, accuracy: 1e-9, "the two axes are perpendicular")
    }

    func testArcReportsRadiusToItsSecondEndpointAndItsSweep() {
        let arc = SketchEntity.arc(id: UUID(), center: .zero, radius: 10,
                                   startAngle: 0, endAngle: .pi / 2)
        let out = dims(arc)
        XCTAssertEqual(out.map(\.kind), [.radius, .angle])
        XCTAssertEqual(out[0].value, 10, accuracy: 1e-9)
        XCTAssertEqual(out[0].start, .zero, "the leader starts at the centre")
        XCTAssertEqual(out[0].end.x, 0, accuracy: 1e-9)
        XCTAssertEqual(out[0].end.y, 10, accuracy: 1e-9)
        XCTAssertEqual(out[1].value, 90, accuracy: 1e-9)
        XCTAssertEqual(out[1].arcCenter, .zero)
        XCTAssertGreaterThan(out[1].arcPoints.count, 8)
    }

    func testSplineHasNoLiveDimension() {
        let spline = SketchEntity.spline(
            id: UUID(), points: [SIMD2(0, 0), SIMD2(5, 9), SIMD2(12, 2)], closed: false)
        XCTAssertTrue(dims(spline).isEmpty,
                      "no single number defines a fit spline, so none is implied")
    }

    // MARK: Labels

    func testDiameterLabelsCarryTheOSymbol() {
        let circle = SketchEntity.circle(id: UUID(), center: .zero, radius: 330.7998)
        let text = LiveDimensionKit.label(dims(circle)[0], unit: .millimeters)
        XCTAssertEqual(text, "Ø661.60 mm")
    }

    func testLabelsFollowTheDisplayUnitSetting() {
        let line = SketchEntity.line(id: UUID(), a: .zero, b: SIMD2(25.4, 0))
        let dimension = dims(line)[0]
        XCTAssertEqual(LiveDimensionKit.label(dimension, unit: .inches), "1.000 in")
        XCTAssertEqual(LiveDimensionKit.label(dimension, unit: .centimeters), "2.54 cm")
    }

    func testRadiusLabelsAreMarkedR() {
        let arc = SketchEntity.arc(id: UUID(), center: .zero, radius: 10,
                                   startAngle: 0, endAngle: .pi)
        XCTAssertEqual(LiveDimensionKit.label(dims(arc)[0], unit: .millimeters),
                       "R10.00 mm")
        XCTAssertEqual(LiveDimensionKit.label(dims(arc)[1], unit: .millimeters), "180°")
    }
}
