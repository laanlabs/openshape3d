//
//  AutoConstraintEngineTests.swift
//  openshape3dTests
//
//  Coverage for A1 live auto-constraint inference: horizontal / vertical axis
//  detection, point-coincident snapping (entity + role), parallel /
//  perpendicular against a reference line, equal-length, tangent, the master
//  `enabled` gate, and the point-snap-only behavior of the non-line tools.
//

import XCTest
import simd
@testable import openshape3d

final class AutoConstraintEngineTests: XCTestCase {

    private typealias Result = AutoConstraintEngine.Result
    private typealias Inferred = AutoConstraintEngine.Inferred
    private typealias Guide = AutoConstraintEngine.Guide

    private func infer(
        _ tool: SketchTool,
        from anchor: SIMD2<Double>,
        to current: SIMD2<Double>,
        existing: [SketchEntity] = [],
        settings: AutoConstraintSettings = AutoConstraintSettings()
    ) -> Result {
        AutoConstraintEngine.infer(
            tool: tool, anchor: anchor, current: current, existing: existing, settings: settings)
    }

    private func constraint(_ r: Result, _ kind: SketchConstraintKind) -> Inferred? {
        r.constraints.first { $0.kind == kind }
    }

    private func hasGuide(_ r: Result, _ kind: Guide.Kind) -> Bool {
        r.guides.contains { $0.kind == kind }
    }

    // MARK: - Horizontal / vertical

    func testHorizontalDetectedWithinTolerance() {
        // ~0.57° off horizontal — inside the 1° default, and the angle
        // Shapr3D was measured snapping flat.
        let r = infer(.line, from: SIMD2(0, 0), to: SIMD2(5, 0.05))
        let c = constraint(r, .horizontal)
        XCTAssertNotNil(c)
        XCTAssertEqual(c?.selfRole, .whole)
        XCTAssertNil(c?.targetEntityID)
        XCTAssertNil(c?.targetRole)
        // Endpoint y is snapped onto the anchor's y; x is left alone.
        XCTAssertEqual(r.snappedPoint.x, 5, accuracy: 1e-12)
        XCTAssertEqual(r.snappedPoint.y, 0, accuracy: 1e-12)
        XCTAssertTrue(hasGuide(r, .horizontal))
        XCTAssertNil(constraint(r, .vertical))
    }

    func testHorizontalRejectedOutsideTolerance() {
        // ~11.3° off horizontal (and ~78.7° off vertical): no axis constraint.
        let r = infer(.line, from: SIMD2(0, 0), to: SIMD2(5, 1))
        XCTAssertNil(constraint(r, .horizontal))
        XCTAssertNil(constraint(r, .vertical))
        XCTAssertTrue(r.constraints.isEmpty)
        XCTAssertTrue(r.guides.isEmpty)
        XCTAssertEqual(r.snappedPoint, SIMD2(5, 1))
    }

    func testVerticalDetectedWithinTolerance() {
        let r = infer(.line, from: SIMD2(0, 0), to: SIMD2(0.05, 5))
        let c = constraint(r, .vertical)
        XCTAssertNotNil(c)
        XCTAssertEqual(c?.selfRole, .whole)
        XCTAssertNil(c?.targetEntityID)
        XCTAssertEqual(r.snappedPoint.x, 0, accuracy: 1e-12)
        XCTAssertEqual(r.snappedPoint.y, 5, accuracy: 1e-12)
        XCTAssertTrue(hasGuide(r, .vertical))
        XCTAssertNil(constraint(r, .horizontal))
    }

    func testHorizontalVerticalGateSuppressesAxisInference() {
        var settings = AutoConstraintSettings()
        settings.horizontalVertical = false
        let r = infer(.line, from: SIMD2(0, 0), to: SIMD2(5, 0.1), settings: settings)
        XCTAssertNil(constraint(r, .horizontal))
        XCTAssertEqual(r.snappedPoint, SIMD2(5, 0.1))
    }

    // MARK: - Point coincident (entity + role)

    func testPointCoincidentPicksLineEndpointBRole() {
        let lineID = UUID()
        // Reference line's endpointA (10,0), endpointB (13,1). We snap near A.
        let line = SketchEntity.line(id: lineID, a: SIMD2(10, 0), b: SIMD2(13, 1))
        let r = infer(.line, from: SIMD2(0, 10), to: SIMD2(10.1, 0.05), existing: [line])
        let c = constraint(r, .coincident)
        XCTAssertNotNil(c)
        XCTAssertEqual(c?.selfRole, .endpointB)          // the new line's own end
        XCTAssertEqual(c?.targetEntityID, lineID)
        XCTAssertEqual(c?.targetRole, .endpointA)         // the point it landed on
        XCTAssertEqual(r.snappedPoint.x, 10, accuracy: 1e-12)
        XCTAssertEqual(r.snappedPoint.y, 0, accuracy: 1e-12)
        XCTAssertTrue(hasGuide(r, .pointOn))
        // Point snap wins the endpoint, so no axis constraint fights it.
        XCTAssertNil(constraint(r, .horizontal))
        XCTAssertNil(constraint(r, .vertical))
    }

    func testPointCoincidentPicksCircleCenterRole() {
        let circleID = UUID()
        let circle = SketchEntity.circle(id: circleID, center: SIMD2(8, 9), radius: 2)
        let r = infer(.line, from: SIMD2(0, 0), to: SIMD2(8.1, 9.05), existing: [circle])
        let c = constraint(r, .coincident)
        XCTAssertNotNil(c)
        XCTAssertEqual(c?.selfRole, .endpointB)
        XCTAssertEqual(c?.targetEntityID, circleID)
        XCTAssertEqual(c?.targetRole, .center)
        XCTAssertEqual(r.snappedPoint.x, 8, accuracy: 1e-12)
        XCTAssertEqual(r.snappedPoint.y, 9, accuracy: 1e-12)
    }

    func testRectCornersAreNotRoleCandidates() {
        // Rect corners have no PointRole, so they must not produce a coincident.
        let rect = SketchEntity.rect(id: UUID(), min: SIMD2(0, 0), max: SIMD2(4, 3))
        let r = infer(.line, from: SIMD2(0, 10), to: SIMD2(4.05, 3.02), existing: [rect])
        XCTAssertNil(constraint(r, .coincident))
        XCTAssertEqual(r.snappedPoint, SIMD2(4.05, 3.02))
    }

    func testPointSnapGateSuppressesCoincident() {
        var settings = AutoConstraintSettings()
        settings.pointSnap = false
        let line = SketchEntity.line(id: UUID(), a: SIMD2(10, 0), b: SIMD2(13, 1))
        let r = infer(
            .line, from: SIMD2(0, 10), to: SIMD2(10.1, 0.05), existing: [line], settings: settings)
        XCTAssertNil(constraint(r, .coincident))
    }

    // MARK: - Parallel / perpendicular

    func testParallelDetectedAndAngleSnapped() {
        let refID = UUID()
        // Reference along 45° (non-axis-aligned so h/v does not steal it).
        let ref = SketchEntity.line(id: refID, a: SIMD2(0, 0), b: SIMD2(2, 2))
        let r = infer(.line, from: SIMD2(0, 5), to: SIMD2(4, 9.1), existing: [ref])
        let c = constraint(r, .parallel)
        XCTAssertNotNil(c)
        XCTAssertEqual(c?.selfRole, .whole)
        XCTAssertEqual(c?.targetEntityID, refID)
        XCTAssertEqual(c?.targetRole, .whole)
        XCTAssertTrue(hasGuide(r, .parallel))
        XCTAssertNil(constraint(r, .perpendicular))
        // Nothing higher-priority fired, so the endpoint is snapped to exact
        // parallel: displacement from the anchor lies along (1,1).
        let dx = r.snappedPoint.x - 0
        let dy = r.snappedPoint.y - 5
        XCTAssertEqual(dx, dy, accuracy: 1e-9)
    }

    func testPerpendicularDetected() {
        let refID = UUID()
        let ref = SketchEntity.line(id: refID, a: SIMD2(0, 0), b: SIMD2(2, 2))
        let r = infer(.line, from: SIMD2(5, 0), to: SIMD2(1, 4.1), existing: [ref])
        let c = constraint(r, .perpendicular)
        XCTAssertNotNil(c)
        XCTAssertEqual(c?.selfRole, .whole)
        XCTAssertEqual(c?.targetEntityID, refID)
        XCTAssertEqual(c?.targetRole, .whole)
        XCTAssertTrue(hasGuide(r, .perpendicular))
        XCTAssertNil(constraint(r, .parallel))
    }

    func testParallelPerpendicularGateSuppressesBoth() {
        var settings = AutoConstraintSettings()
        settings.parallelPerpendicular = false
        let ref = SketchEntity.line(id: UUID(), a: SIMD2(0, 0), b: SIMD2(2, 2))
        let r = infer(.line, from: SIMD2(0, 5), to: SIMD2(4, 9.1), existing: [ref], settings: settings)
        XCTAssertNil(constraint(r, .parallel))
        XCTAssertNil(constraint(r, .perpendicular))
    }

    // MARK: - Equal length

    func testEqualLengthDetectedWithinTolerance() {
        let refID = UUID()
        // Reference length 4 (horizontal). Draw a 45° segment of length ~4 so
        // it matches on length but not on axis / parallel / perpendicular.
        let ref = SketchEntity.line(id: refID, a: SIMD2(0, 0), b: SIMD2(4, 0))
        let r = infer(.line, from: SIMD2(0, 10), to: SIMD2(2.83, 12.83), existing: [ref], settings: AutoConstraintSettings(equal: true))
        let c = constraint(r, .equalLength)
        XCTAssertNotNil(c)
        XCTAssertEqual(c?.selfRole, .whole)
        XCTAssertEqual(c?.targetEntityID, refID)
        XCTAssertEqual(c?.targetRole, .whole)
        XCTAssertTrue(hasGuide(r, .equalLength))
        // Equal length never moves the endpoint.
        XCTAssertEqual(r.snappedPoint, SIMD2(2.83, 12.83))
    }

    func testEqualLengthRejectedOutsideTolerance() {
        let ref = SketchEntity.line(id: UUID(), a: SIMD2(0, 0), b: SIMD2(4, 0))
        // Length ~5.66 vs 4 → ~41% off, well past the 3% window.
        let r = infer(.line, from: SIMD2(0, 10), to: SIMD2(4, 14), existing: [ref], settings: AutoConstraintSettings(equal: true))
        XCTAssertNil(constraint(r, .equalLength))
    }

    /// The 3 % window is capped at the snap tolerance in absolute terms: on a
    /// part-sized profile a 98 mm segment beside a 96 mm one was inferred
    /// equal and the solve pulled the whole polyline off its grid. Lengths a
    /// snap step apart still match.
    func testEqualLengthIsCappedAtTheSnapToleranceOnLongLines() {
        let ref = SketchEntity.line(id: UUID(), a: SIMD2(0, 0), b: SIMD2(96, 0))
        let far = infer(.line, from: SIMD2(0, 10), to: SIMD2(0, 108), existing: [ref], settings: AutoConstraintSettings(equal: true))
        XCTAssertNil(constraint(far, .equalLength), "98 vs 96 is 2 % but 2 mm — placed on purpose")
        let near = infer(.line, from: SIMD2(0, 10), to: SIMD2(0, 106.2), existing: [ref], settings: AutoConstraintSettings(equal: true))
        XCTAssertNotNil(constraint(near, .equalLength), "0.2 mm is within a snap step")
    }

    func testDefaultNearEqualLinesStayIndependentAndSavedOptInSurvives() throws {
        let ref = SketchEntity.line(id: UUID(), a: SIMD2(0, 0), b: SIMD2(3.306, 0))
        let result = infer(.line, from: SIMD2(0, 2), to: SIMD2(3.38865, 2), existing: [ref])
        XCTAssertNil(constraint(result, .equalLength))
        XCTAssertFalse(hasGuide(result, .equalLength))
        XCTAssertEqual(result.snappedPoint, SIMD2(3.38865, 2))
        XCTAssertNotNil(constraint(result, .horizontal), "Independent axis inference remains enabled")
        let saved = try JSONEncoder().encode(AutoConstraintSettings(equal: true))
        let restored = try JSONDecoder().decode(AutoConstraintSettings.self, from: saved)
        XCTAssertTrue(restored.equal, "Do not overwrite a stored preference")
        let optedIn = infer(.line, from: SIMD2(0, 2), to: SIMD2(3.38865, 2),
                            existing: [ref], settings: restored)
        XCTAssertNotNil(constraint(optedIn, .equalLength))
    }

    func testEqualLengthGateSuppresses() {
        var settings = AutoConstraintSettings()
        settings.equal = false
        let ref = SketchEntity.line(id: UUID(), a: SIMD2(0, 0), b: SIMD2(4, 0))
        let r = infer(.line, from: SIMD2(0, 10), to: SIMD2(2.83, 12.83), existing: [ref], settings: settings)
        XCTAssertNil(constraint(r, .equalLength))
    }

    // MARK: - Tangent (best-effort, gated)

    func testTangentDetectedWhenEndpointOnCircleAndDirectionTangent() {
        let circleID = UUID()
        let radius = 5.0
        let a = Double.pi / 4
        let tangentPoint = SIMD2(radius * cos(a), radius * sin(a))
        let tangentDir = SIMD2(-sin(a), cos(a))
        // Anchor placed 4 units back along the tangent line from the touch point.
        let anchor = tangentPoint - tangentDir * 4
        let circle = SketchEntity.circle(id: circleID, center: SIMD2(0, 0), radius: radius)
        let r = infer(.line, from: anchor, to: tangentPoint, existing: [circle])
        let c = constraint(r, .tangent)
        XCTAssertNotNil(c)
        XCTAssertEqual(c?.selfRole, .whole)
        XCTAssertEqual(c?.targetEntityID, circleID)
        XCTAssertEqual(c?.targetRole, .whole)
        XCTAssertTrue(hasGuide(r, .tangent))
    }

    func testTangentGateSuppresses() {
        var settings = AutoConstraintSettings()
        settings.tangent = false
        let radius = 5.0
        let a = Double.pi / 4
        let tangentPoint = SIMD2(radius * cos(a), radius * sin(a))
        let tangentDir = SIMD2(-sin(a), cos(a))
        let anchor = tangentPoint - tangentDir * 4
        let circle = SketchEntity.circle(id: UUID(), center: SIMD2(0, 0), radius: radius)
        let r = infer(.line, from: anchor, to: tangentPoint, existing: [circle], settings: settings)
        XCTAssertNil(constraint(r, .tangent))
    }

    func testTangentSkippedWhenEndpointFarFromBoundary() {
        // Endpoint well inside the circle → never emit a (wrong) tangent.
        let circle = SketchEntity.circle(id: UUID(), center: SIMD2(0, 0), radius: 5)
        let r = infer(.line, from: SIMD2(-3, -3), to: SIMD2(1, 0.9), existing: [circle])
        XCTAssertNil(constraint(r, .tangent))
    }

    func testArcTangentDetectedOnlyAtConnectedLineEndpoint() {
        let lineID = UUID()
        let line = SketchEntity.line(id: lineID, a: SIMD2(0, 0), b: SIMD2(4, 0))
        let arc = SketchEntity.arc(id: UUID(), center: SIMD2(4, 4), radius: 4,
                                   startAngle: -.pi / 2, endAngle: 0)

        let result = AutoConstraintEngine.inferArcTangencies(
            arc: arc, existing: [line], settings: AutoConstraintSettings())

        XCTAssertEqual(result, [.init(kind: .tangent, selfRole: .whole,
                                      targetEntityID: lineID, targetRole: .whole)])
    }

    func testArcTangentRejectsConnectedButObliqueLine() {
        let line = SketchEntity.line(id: UUID(), a: SIMD2(0, 1), b: SIMD2(4, 0))
        let arc = SketchEntity.arc(id: UUID(), center: SIMD2(4, 4), radius: 4,
                                   startAngle: -.pi / 2, endAngle: 0)

        XCTAssertTrue(AutoConstraintEngine.inferArcTangencies(
            arc: arc, existing: [line], settings: AutoConstraintSettings()).isEmpty)
    }

    func testArcTangentRespectsDisabledSetting() {
        let line = SketchEntity.line(id: UUID(), a: SIMD2(0, 0), b: SIMD2(4, 0))
        let arc = SketchEntity.arc(id: UUID(), center: SIMD2(4, 4), radius: 4,
                                   startAngle: -.pi / 2, endAngle: 0)
        var settings = AutoConstraintSettings()
        settings.tangent = false

        XCTAssertTrue(AutoConstraintEngine.inferArcTangencies(
            arc: arc, existing: [line], settings: settings).isEmpty)
    }

    // MARK: - Master enable gate

    func testDisabledYieldsEmptyResult() {
        var settings = AutoConstraintSettings()
        settings.enabled = false
        let line = SketchEntity.line(id: UUID(), a: SIMD2(10, 0), b: SIMD2(13, 1))
        // Geometry that would otherwise point-snap AND read as horizontal.
        let r = infer(
            .line, from: SIMD2(0, 0), to: SIMD2(10.1, 0.05), existing: [line], settings: settings)
        XCTAssertEqual(r.snappedPoint, SIMD2(10.1, 0.05))
        XCTAssertTrue(r.guides.isEmpty)
        XCTAssertTrue(r.constraints.isEmpty)
    }

    // MARK: - Non-line tools only point-snap

    func testNonLineToolSnapsToPointWithoutGuidesOrConstraints() {
        let circleID = UUID()
        let circle = SketchEntity.circle(id: circleID, center: SIMD2(5, 5), radius: 2)
        for tool in [SketchTool.rect, .circle, .arc, .ellipse, .polygon] {
            let r = infer(tool, from: SIMD2(0, 0), to: SIMD2(5.1, 4.95), existing: [circle])
            // The drawn point snaps positionally to the nearby centre...
            XCTAssertEqual(r.snappedPoint.x, 5, accuracy: 1e-12, "\(tool)")
            XCTAssertEqual(r.snappedPoint.y, 5, accuracy: 1e-12, "\(tool)")
            XCTAssertTrue(r.guides.isEmpty, "\(tool) emits no guides")
            // ...but emits NO constraint: the drawn point's role is ambiguous
            // (rect corners re-sort at commit) or absent (round entities expose
            // only .center), so a coincident here would weld the wrong point or
            // dangle. Positional snap only.
            XCTAssertTrue(r.constraints.isEmpty, "\(tool) emits no constraint")
        }
    }

    func testNonLineToolDoesNotInferAxisOrParallel() {
        // A ~horizontal rect drag next to a reference line must NOT emit
        // horizontal / parallel — non-line tools do point-snap only.
        let ref = SketchEntity.line(id: UUID(), a: SIMD2(0, 0), b: SIMD2(4, 0))
        let r = infer(.rect, from: SIMD2(0, 5), to: SIMD2(5, 5.02), existing: [ref])
        XCTAssertTrue(r.constraints.isEmpty)
        XCTAssertTrue(r.guides.isEmpty)
        XCTAssertEqual(r.snappedPoint, SIMD2(5, 5.02))
    }

    func testNonLineToolWithNoNearbyPointReturnsInputUnchanged() {
        let r = infer(.circle, from: SIMD2(0, 0), to: SIMD2(20, 20))
        XCTAssertEqual(r.snappedPoint, SIMD2(20, 20))
        XCTAssertTrue(r.constraints.isEmpty)
        XCTAssertTrue(r.guides.isEmpty)
    }

    /// The tolerance is not arbitrary: Shapr3D was driven at known angles and
    /// snapped flat at 0.57° but left 1.15° and 1.6° alone. A line drawn at a
    /// deliberate slight angle must survive.
    func testALineJustOutsideToleranceIsLeftAlone() {
        let r = infer(.line, from: SIMD2(0, 0), to: SIMD2(5, 0.1))  // ~1.15°
        XCTAssertNil(constraint(r, .horizontal),
                     "1.15° is outside the measured Shapr3D snap")
        XCTAssertEqual(r.snappedPoint, SIMD2(5, 0.1), "and the geometry is untouched")
    }
}
