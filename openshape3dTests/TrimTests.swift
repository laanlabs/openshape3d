//
//  TrimTests.swift
//  openshape3dTests
//
//  Split math for the sketch Trim tool (A3): spans are deleted between the
//  nearest intersections — lines split exactly, arcs by angle, circles into
//  arcs, rects explode into lines.
//

import XCTest
import simd
@testable import openshape3d

final class TrimTests: XCTestCase {

    private func makeSketch(_ entities: [SketchEntity]) -> Sketch {
        Sketch(plane: .ground, entities: entities)
    }

    // MARK: - Lines

    func testLineCrossedByTwoLinesRemovesMiddleSpan() {
        let target = SketchEntity.line(id: UUID(), a: SIMD2(0, 0), b: SIMD2(10, 0))
        let sketch = makeSketch([
            target,
            .line(id: UUID(), a: SIMD2(3, -1), b: SIMD2(3, 1)),
            .line(id: UUID(), a: SIMD2(7, -1), b: SIMD2(7, 1)),
        ])
        let fragments = SketchTrimmer.trim(entity: target, at: SIMD2(5, 0), in: sketch)
        XCTAssertNotNil(fragments)
        XCTAssertEqual(fragments?.count, 2)

        guard case let .line(_, a0, b0)? = fragments?.first,
              case let .line(_, a1, b1)? = fragments?.last
        else { return XCTFail("Fragments should be lines") }
        XCTAssertEqual(simd_length(a0 - SIMD2(0, 0)), 0, accuracy: 1e-9)
        XCTAssertEqual(simd_length(b0 - SIMD2(3, 0)), 0, accuracy: 1e-9)
        XCTAssertEqual(simd_length(a1 - SIMD2(7, 0)), 0, accuracy: 1e-9)
        XCTAssertEqual(simd_length(b1 - SIMD2(10, 0)), 0, accuracy: 1e-9)
    }

    func testLineTapBeyondLastIntersectionTrimsToEnd() {
        // Overbuild-then-trim: the span from the single crossing to the far
        // endpoint goes away.
        let target = SketchEntity.line(id: UUID(), a: SIMD2(0, 0), b: SIMD2(10, 0))
        let sketch = makeSketch([
            target,
            .line(id: UUID(), a: SIMD2(4, -1), b: SIMD2(4, 1)),
        ])
        let fragments = SketchTrimmer.trim(entity: target, at: SIMD2(7, 0), in: sketch)
        XCTAssertEqual(fragments?.count, 1)
        guard case let .line(_, a, b)? = fragments?.first else {
            return XCTFail("Fragment should be a line")
        }
        XCTAssertEqual(simd_length(a - SIMD2(0, 0)), 0, accuracy: 1e-9)
        XCTAssertEqual(simd_length(b - SIMD2(4, 0)), 0, accuracy: 1e-9)
    }

    func testLineWithoutIntersectionsIsRemovedEntirely() {
        let target = SketchEntity.line(id: UUID(), a: SIMD2(0, 0), b: SIMD2(10, 0))
        let sketch = makeSketch([target])
        let fragments = SketchTrimmer.trim(entity: target, at: SIMD2(5, 0), in: sketch)
        XCTAssertEqual(fragments?.count, 0)
    }

    // MARK: - Circles

    func testCircleCrossedByLineLeavesArc() {
        // Line through the center cuts at angles 0 and π; tapping the top
        // removes the upper semicircle — the lower one remains as an arc.
        let target = SketchEntity.circle(id: UUID(), center: SIMD2(0, 0), radius: 2)
        let sketch = makeSketch([
            target,
            .line(id: UUID(), a: SIMD2(-3, 0), b: SIMD2(3, 0)),
        ])
        let fragments = SketchTrimmer.trim(entity: target, at: SIMD2(0, 2), in: sketch)
        XCTAssertEqual(fragments?.count, 1)
        guard case let .arc(_, center, radius, startAngle, endAngle)? = fragments?.first else {
            return XCTFail("Fragment should be an arc")
        }
        XCTAssertEqual(simd_length(center - SIMD2(0, 0)), 0, accuracy: 1e-6)
        XCTAssertEqual(radius, 2, accuracy: 1e-6)
        let sweep = SketchEntity.arcSweep(startAngle: startAngle, endAngle: endAngle)
        XCTAssertEqual(sweep, .pi, accuracy: 1e-3)
        // The remaining arc passes through the bottom of the circle.
        let mid = SketchEntity.arcPoint(
            center: center, radius: radius, angle: startAngle + sweep / 2
        )
        XCTAssertEqual(mid.y, -2, accuracy: 1e-3)
    }

    func testUncrossedCircleIsRemovedEntirely() {
        let target = SketchEntity.circle(id: UUID(), center: SIMD2(0, 0), radius: 2)
        let sketch = makeSketch([target])
        XCTAssertEqual(SketchTrimmer.trim(entity: target, at: SIMD2(0, 2), in: sketch)?.count, 0)
    }

    // MARK: - Arcs

    func testArcCrossedByLineSplitsByAngle() {
        // Semicircle 0→π; a vertical line cuts it at π/2. Tapping near π/4
        // removes [0, π/2]; the [π/2, π] quarter remains.
        let target = SketchEntity.arc(
            id: UUID(), center: SIMD2(0, 0), radius: 2, startAngle: 0, endAngle: .pi
        )
        let tap = SketchEntity.arcPoint(center: SIMD2(0, 0), radius: 2, angle: .pi / 4)
        let sketch = makeSketch([
            target,
            .line(id: UUID(), a: SIMD2(0, 1), b: SIMD2(0, 3)),
        ])
        let fragments = SketchTrimmer.trim(entity: target, at: tap, in: sketch)
        XCTAssertEqual(fragments?.count, 1)
        guard case let .arc(_, _, radius, startAngle, endAngle)? = fragments?.first else {
            return XCTFail("Fragment should be an arc")
        }
        XCTAssertEqual(radius, 2, accuracy: 1e-6)
        XCTAssertEqual(startAngle, .pi / 2, accuracy: 1e-3)
        XCTAssertEqual(
            SketchEntity.arcSweep(startAngle: startAngle, endAngle: endAngle),
            .pi / 2, accuracy: 1e-3
        )
    }

    func testUncrossedArcIsRemovedEntirely() {
        let target = SketchEntity.arc(
            id: UUID(), center: SIMD2(0, 0), radius: 2,
            startAngle: 0, endAngle: .pi
        )
        let sketch = makeSketch([target])
        let tap = SketchEntity.arcPoint(center: SIMD2(0, 0), radius: 2,
                                        angle: .pi / 2)
        XCTAssertEqual(SketchTrimmer.trim(entity: target, at: tap, in: sketch)?.count, 0)
    }

    // MARK: - Polygon boundaries

    func testPolygonEdgeTrimRemovesOnlyTheChosenBoundaryAndUndoes() throws {
        // Polygons are stored as ordinary connected lines. An uncrossed edge
        // is therefore the whole trimmable entity; deleting it must leave the
        // other boundaries intact and Undo must restore the exact closed loop.
        let points = (0..<5).map { i -> SIMD2<Double> in
            let a = Double(i) * 2 * .pi / 5 + .pi / 2
            return SIMD2(cos(a), sin(a)) * 4
        }
        let edges = (0..<5).map { i in
            SketchEntity.line(id: UUID(), a: points[i], b: points[(i + 1) % 5])
        }
        let sketch = makeSketch(edges)
        let target = edges[2]
        let tap = (points[2] + points[3]) / 2
        let fragments = try XCTUnwrap(SketchTrimmer.trim(entity: target, at: tap, in: sketch))
        XCTAssertTrue(fragments.isEmpty)

        var document = DesignDocument()
        document.sketches = [sketch]
        let command = TrimCommand(sketch: sketch, index: 2, removed: target,
                                  fragments: fragments)
        command.apply(to: &document)
        XCTAssertEqual(document.sketches[0].entities.count, 4)
        XCTAssertFalse(document.sketches[0].entities.contains { $0.id == target.id })
        XCTAssertEqual(document.sketches[0].entities.map(\.id),
                       edges.enumerated().filter { $0.offset != 2 }.map { $0.element.id })

        command.revert(in: &document)
        XCTAssertEqual(document.sketches[0], sketch)
    }

    // MARK: - Rects (explode into lines, then trim)

    func testTrimmedRectExplodesIntoLines() {
        // A vertical line crosses the bottom edge at (2, 0); tapping that
        // edge left of the crossing keeps the right half plus 3 whole edges.
        let target = SketchEntity.rect(id: UUID(), min: SIMD2(0, 0), max: SIMD2(4, 4))
        let sketch = makeSketch([
            target,
            .line(id: UUID(), a: SIMD2(2, -1), b: SIMD2(2, 1)),
        ])
        let fragments = SketchTrimmer.trim(entity: target, at: SIMD2(1, 0), in: sketch)
        XCTAssertEqual(fragments?.count, 4)
        for fragment in fragments ?? [] {
            guard case .line = fragment else {
                return XCTFail("Exploded rect fragments should all be lines")
            }
        }
        // The trimmed edge keeps only the span right of the crossing.
        let bottomFragments = (fragments ?? []).filter {
            guard case let .line(_, a, b) = $0 else { return false }
            return a.y == 0 && b.y == 0
        }
        XCTAssertEqual(bottomFragments.count, 1)
        guard case let .line(_, a, b)? = bottomFragments.first else { return }
        XCTAssertEqual(min(a.x, b.x), 2, accuracy: 1e-9)
        XCTAssertEqual(max(a.x, b.x), 4, accuracy: 1e-9)
    }

    // MARK: - Command round trip

    func testTrimCommandAppliesAndReverts() {
        let target = SketchEntity.line(id: UUID(), a: SIMD2(0, 0), b: SIMD2(10, 0))
        let crosser = SketchEntity.line(id: UUID(), a: SIMD2(5, -1), b: SIMD2(5, 1))
        let sketch = makeSketch([target, crosser])
        var document = DesignDocument()
        document.sketches = [sketch]

        let fragments = SketchTrimmer.trim(entity: target, at: SIMD2(7, 0), in: sketch)!
        let command = TrimCommand(sketchID: sketch.id, index: 0, removed: target, fragments: fragments)

        command.apply(to: &document)
        XCTAssertEqual(document.sketches[0].entities.count, 2)
        XCTAssertFalse(document.sketches[0].entities.contains { $0.id == target.id })

        command.revert(in: &document)
        XCTAssertEqual(document.sketches[0].entities, [target, crosser])
    }
}
