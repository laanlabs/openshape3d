//
//  ConstructionProjectFlowTests.swift
//  openshape3dTests
//
//  Plan §B7/§B8/§B9 UI wave: bulk sketch-entity commands, the construction
//  flag's effect on profile detection, and dashed tessellation.
//

import XCTest
import simd
@testable import openshape3d

final class ConstructionProjectFlowTests: XCTestCase {

    private func documentWithEmptyGroundSketch() -> (DesignDocument, SketchID) {
        var document = DesignDocument()
        let sketch = Sketch(plane: .ground)
        document.sketches.append(sketch)
        return (document, sketch.id)
    }

    // MARK: - AddSketchEntitiesCommand

    func testAddSketchEntitiesCommandApplyAndRevert() {
        var (document, sketchID) = documentWithEmptyGroundSketch()
        let entities: [SketchEntity] = [
            .line(id: UUID(), a: SIMD2(0, 0), b: SIMD2(1, 0)),
            .line(id: UUID(), a: SIMD2(1, 0), b: SIMD2(1, 1)),
            .circle(id: UUID(), center: SIMD2(3, 3), radius: 0.5),
        ]
        let command = AddSketchEntitiesCommand(
            sketchID: sketchID, entities: entities, title: "Text"
        )

        command.apply(to: &document)
        XCTAssertEqual(document.sketches[0].entities, entities,
                       "Bulk add appends all entities in order")
        XCTAssertEqual(command.title, "Text")

        command.revert(in: &document)
        XCTAssertTrue(document.sketches[0].entities.isEmpty,
                      "Revert removes exactly the added entities")
    }

    func testAddSketchEntitiesAsConstructionFlagsAndUnflags() {
        var (document, sketchID) = documentWithEmptyGroundSketch()
        let lineID = UUID()
        let command = AddSketchEntitiesCommand(
            sketchID: sketchID,
            entities: [.line(id: lineID, a: .zero, b: SIMD2(2, 0))],
            title: "Project",
            asConstruction: true
        )

        command.apply(to: &document)
        XCTAssertTrue(document.sketches[0].isConstruction(lineID),
                      "asConstruction arrivals are flagged")

        command.revert(in: &document)
        XCTAssertTrue(document.sketches[0].constructionEntityIDs.isEmpty,
                      "Revert clears the flags it set")
    }

    // MARK: - SetConstructionCommand

    func testSetConstructionCommandOnlyTouchesChangedIDs() {
        var (document, sketchID) = documentWithEmptyGroundSketch()
        let alreadyConstruction = UUID()
        let regular = UUID()
        document.sketches[0].entities = [
            .line(id: alreadyConstruction, a: .zero, b: SIMD2(1, 0)),
            .line(id: regular, a: .zero, b: SIMD2(0, 1)),
        ]
        document.sketches[0].setConstruction(true, forEntityIDs: [alreadyConstruction])

        let command = SetConstructionCommand(
            sketchID: sketchID,
            entityIDs: [alreadyConstruction, regular],
            isConstruction: true,
            sketch: document.sketches[0]
        )
        XCTAssertEqual(command.changedIDs, [regular],
                       "Entities already in the target state are not recorded")
        XCTAssertEqual(command.title, "Make Construction")

        command.apply(to: &document)
        XCTAssertEqual(document.sketches[0].constructionEntityIDs,
                       [alreadyConstruction, regular])

        command.revert(in: &document)
        XCTAssertEqual(document.sketches[0].constructionEntityIDs, [alreadyConstruction],
                       "Revert restores exactly the prior state")
    }

    func testMakeRegularCommandRoundTrip() {
        var (document, sketchID) = documentWithEmptyGroundSketch()
        let lineID = UUID()
        document.sketches[0].entities = [.line(id: lineID, a: .zero, b: SIMD2(1, 0))]
        document.sketches[0].setConstruction(true, forEntityIDs: [lineID])

        let command = SetConstructionCommand(
            sketchID: sketchID, entityIDs: [lineID],
            isConstruction: false, sketch: document.sketches[0]
        )
        XCTAssertEqual(command.title, "Make Regular")

        command.apply(to: &document)
        XCTAssertFalse(document.sketches[0].isConstruction(lineID))

        command.revert(in: &document)
        XCTAssertTrue(document.sketches[0].isConstruction(lineID))
    }

    // MARK: - Construction exclusion from profiles (spec §3.3)

    func testProfileDetectorExcludesConstructionEntities() {
        let circleID = UUID()
        var sketch = Sketch(
            plane: .ground,
            entities: [.circle(id: circleID, center: .zero, radius: 2)]
        )
        XCTAssertEqual(ProfileDetector.detectProfiles(in: sketch).count, 1)

        sketch.setConstruction(true, forEntityIDs: [circleID])
        XCTAssertTrue(ProfileDetector.detectProfiles(in: sketch).isEmpty,
                      "Construction geometry never bounds a profile")
    }

    func testConstructionLineDoesNotCloseLoop() {
        // A triangle whose hypotenuse is construction: no closed profile.
        let a = SIMD2(0.0, 0.0)
        let b = SIMD2(4.0, 0.0)
        let c = SIMD2(0.0, 3.0)
        let hypotenuseID = UUID()
        var sketch = Sketch(plane: .ground, entities: [
            .line(id: UUID(), a: a, b: b),
            .line(id: UUID(), a: c, b: a),
            .line(id: hypotenuseID, a: b, b: c),
        ])
        XCTAssertEqual(ProfileDetector.detectProfiles(in: sketch).count, 1)

        sketch.setConstruction(true, forEntityIDs: [hypotenuseID])
        XCTAssertTrue(ProfileDetector.detectProfiles(in: sketch).isEmpty,
                      "Removing one side from profile detection opens the loop")
    }

    // MARK: - Dashed tessellation (spec §3.3)

    func testDashedSegmentsSubdivideWithGaps() {
        let entity = SketchEntity.line(id: UUID(), a: .zero, b: SIMD2(10, 0))
        let solid = SketchTessellator.segments(for: [entity], on: .ground)
        let dashed = SketchTessellator.dashedSegments(for: [entity], on: .ground)

        XCTAssertEqual(solid.count, 2, "A line is one solid segment")
        XCTAssertGreaterThan(dashed.count, solid.count,
                             "Dashing splits the segment into multiple pieces")
        XCTAssertEqual(dashed.count % 2, 0, "Point pairs")

        func totalLength(_ points: [SIMD3<Float>]) -> Float {
            var sum: Float = 0
            var i = 0
            while i + 1 < points.count {
                sum += simd_length(points[i + 1] - points[i])
                i += 2
            }
            return sum
        }
        XCTAssertLessThan(totalLength(dashed), totalLength(solid),
                          "Gaps remove coverage")
        XCTAssertGreaterThan(totalLength(dashed), totalLength(solid) * 0.4,
                             "But most of the line is still drawn")

        // Every dash lies on the source segment (y = z = 0 on the ground
        // plane maps to world y = 0, z = 0 ... x in [0, 10]).
        for p in dashed {
            XCTAssertEqual(p.y, 0, accuracy: 1e-5)
            XCTAssertEqual(p.z, 0, accuracy: 1e-5)
            XCTAssertGreaterThanOrEqual(p.x, -1e-5)
            XCTAssertLessThanOrEqual(p.x, 10 + 1e-5)
        }
    }

    func testConstructionDashesKeepScreenSizeAcrossModelScales() {
        for scale in [0.001, 0.01, 1.0, 100.0] {
            let entity = SketchEntity.line(id: UUID(), a: .zero, b: SIMD2(100 * scale, 0))
            let points = SketchTessellator.dashedSegments(
                for: [entity], on: .ground, worldUnitsPerPoint: scale)
            XCTAssertGreaterThan(points.count, 10, "A visible construction line must not become one solid stroke")
            for index in stride(from: 0, to: points.count, by: 2) {
                let length = Double(simd_distance(points[index], points[index + 1])) / scale
                XCTAssertLessThanOrEqual(length, 8.001, "Dash length is bounded in screen points")
            }
            XCTAssertEqual(Double(simd_distance(points[1], points[2])) / scale, 4, accuracy: 0.001)
            XCTAssertEqual(Double(points.last!.x) / scale, 100, accuracy: 0.001)
        }
    }

    func testDashedShortSegmentKeepsDutyCycle() {
        // Shorter than one dash+gap period: the leading fraction is drawn.
        let dash: Float = 0.5
        let gap: Float = 0.3
        let short: [SIMD3<Float>] = [SIMD3(0, 0, 0), SIMD3(0.4, 0, 0)]
        let dashed = SketchTessellator.dashed(short, dash: dash, gap: gap)
        XCTAssertEqual(dashed.count, 2)
        let length = simd_length(dashed[1] - dashed[0])
        XCTAssertEqual(length, 0.4 * dash / (dash + gap), accuracy: 1e-5,
                       "Short pieces keep the dash duty cycle")
    }
}
