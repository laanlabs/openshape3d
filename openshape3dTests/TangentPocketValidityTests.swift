//
//  TangentPocketValidityTests.swift
//  openshape3dTests
//

import XCTest
import simd
@testable import openshape3d

final class TangentPocketValidityTests: XCTestCase {

    private let xAxis = SIMD3<Double>(1, 0, 0)
    private let yAxis = SIMD3<Double>(0, 1, 0)
    private let normal = SIMD3<Double>(0, 0, 1)

    private func prism(_ entities: [SketchEntity], seed: SIMD2<Double>,
                       height: Double, zMin: Double, zMax: Double) throws -> BRepHandle {
        let sketch = Sketch(plane: .ground, entities: entities)
        let outer = try XCTUnwrap(ProfileDetector.profiles(at: seed, in: sketch).first)
        let holes = ProfileDetector.holes(of: outer, among: ProfileDetector.detectProfiles(in: sketch))
        return try XCTUnwrap(OCCTKernel.extrudeSolid(
            outer: outer, holes: holes, extras: [], zMin: zMin, zMax: zMax,
            origin: SIMD3(0, 0, height), xAxis: xAxis, yAxis: yAxis, normal: normal))
    }

    /// A sketch fillet of radius r at corner p1: (tangent on p0-p1, tangent on p1-p2, centre).
    private func corner(_ p0: SIMD2<Double>, _ p1: SIMD2<Double>, _ p2: SIMD2<Double>,
                        _ r: Double) -> (SIMD2<Double>, SIMD2<Double>, SIMD2<Double>) {
        let a = simd_normalize(p0 - p1), b = simd_normalize(p2 - p1)
        let theta = acos(max(-1, min(1, simd_dot(a, b))))
        let d = r / tan(theta / 2)
        let centre = p1 + simd_normalize(a + b) * (r / sin(theta / 2))
        return (p1 + a * d, p1 + b * d, centre)
    }

    /// The short arc of radius r about c from p to q.
    private func arcShort(_ c: SIMD2<Double>, _ r: Double,
                          _ p: SIMD2<Double>, _ q: SIMD2<Double>) -> SketchEntity {
        var a0 = atan2(p.y - c.y, p.x - c.x)
        let a1 = atan2(q.y - c.y, q.x - c.x)
        var sweep = (a1 - a0).truncatingRemainder(dividingBy: 2 * .pi)
        if sweep < 0 { sweep += 2 * .pi }
        if sweep > .pi { a0 = a1; sweep = 2 * .pi - sweep }
        return .arc(id: UUID(), center: c, radius: r, startAngle: a0, endAngle: a0 + sweep)
    }

    /// Round 6's bug 2 repro, from practice problem 18.19's window pocket:
    /// sides x = ±4, top y = 11, R1 corners, and a bottom that follows the
    /// Ø13 boss, joined to the sides by R1 fillets tangent to it.
    private func pocketEntities() -> [SketchEntity] {
        let tl = SIMD2<Double>(-4, 11), tr = SIMD2<Double>(4, 11)
        let topLeft = corner(SIMD2(-4, 5), tl, tr, 1)
        let topRight = corner(tl, tr, SIMD2(4, 5), 1)
        let cy = (7.5 * 7.5 - 9).squareRoot()
        let cL = SIMD2<Double>(-3, cy), cR = SIMD2<Double>(3, cy)
        let blLine = SIMD2<Double>(-4, cy), brLine = SIMD2<Double>(4, cy)
        let blC = cL * (6.5 / 7.5), brC = cR * (6.5 / 7.5)
        return [
            .line(id: UUID(), a: topLeft.1, b: topRight.0),
            arcShort(topRight.2, 1, topRight.0, topRight.1),
            .line(id: UUID(), a: topRight.1, b: brLine),
            arcShort(cR, 1, brLine, brC),
            arcShort(.zero, 6.5, brC, blC),
            arcShort(cL, 1, blC, blLine),
            .line(id: UUID(), a: blLine, b: topLeft.0),
            arcShort(topLeft.2, 1, topLeft.0, topLeft.1),
        ]
    }

    /// Plate + boss, then the pocket cut, each result meshed for display as
    /// `adoptBRep` does (the render mesh is written into the shape).
    private func pocketedBody() throws -> (before: BRepHandle, after: BRepHandle) {
        let plate = try prism([.rect(id: UUID(), min: SIMD2(-15, -10), max: SIMD2(15, 15))],
                              seed: SIMD2(0, 12), height: 0, zMin: 0, zMax: 7)
        let boss = try prism([.circle(id: UUID(), center: .zero, radius: 6.5)],
                             seed: .zero, height: 0, zMin: 0, zMax: 9)
        let body = try XCTUnwrap(OCCTKernel.boolean(plate, boss, op: 0))
        _ = OCCTKernel.renderMesh(from: body)
        let pocket = try prism(pocketEntities(), seed: SIMD2(0, 9), height: 7, zMin: -5, zMax: 0)
        let cut = try XCTUnwrap(OCCTKernel.boolean(body, pocket, op: 1))
        _ = OCCTKernel.renderMesh(from: cut)
        return (body, cut)
    }

    /// The render mesh on the result used to fail `BRepCheck`
    /// (Edge21: invalidPolygonOnTriangulation) though the solid was exact.
    func testTheMeshedPocketChecksValidWithTheExactVolume() throws {
        let (before, after) = try pocketedBody()
        let health = OCCTKernel.healthReport(for: after)
        XCTAssertTrue(health.isValid, health.findingsSummary)
        // The pocket region integrated by hand: 37.7972 mm² × 5 deep.
        XCTAssertEqual(OCCTKernel.volume(before) - OCCTKernel.volume(after), 188.986, accuracy: 0.001)
    }

    /// And the next boolean used to refuse it: "the target solid is invalid".
    func testTheNextBooleanAcceptsTheMeshedPocketedBody() throws {
        let (_, after) = try pocketedBody()
        let hole = try prism([.circle(id: UUID(), center: SIMD2(10, -5), radius: 2)],
                             seed: SIMD2(10, -5), height: 0, zMin: -1, zMax: 8)
        switch OCCTKernel.booleanResult(after, hole, op: 1) {
        case let .success(outcome):
            XCTAssertEqual(OCCTKernel.volume(after) - OCCTKernel.volume(outcome.handle),
                           Double.pi * 4 * 7, accuracy: 0.01)
        case let .failure(error):
            XCTFail("refused: \(error.message)")
        }
    }
}
