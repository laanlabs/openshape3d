//
//  CoplanarDepthRanksTests.swift
//  openshape3dTests
//
//  #141: the tie-break that stops coplanar faces of overlapping bodies
//  from z-fighting.
//

import XCTest
import simd
@testable import openshape3d

@MainActor
final class CoplanarDepthRanksTests: XCTestCase {

    private func box(_ x: Float, _ y: Float = 0, _ z: Float = 0, size: Float = 10) -> CoplanarDepthRanks.Box {
        .init(min: SIMD3(x, y, z), max: SIMD3(x + size, y + size, z + size))
    }

    func testBodiesApartAllStayAtRankZero() {
        let ranks = CoplanarDepthRanks.ranks(boxes: (0..<40).map { box(Float($0) * 25) })
        XCTAssertEqual(ranks, [Int](repeating: 0, count: 40), "no bias unless bodies can share a face")
    }

    func testOverlappingCopyGetsItsOwnRankAndTheNewestWins() {
        // A box and its copy dragged half across it at the same height (#141).
        let ranks = CoplanarDepthRanks.ranks(boxes: [box(0), box(5)])
        XCTAssertEqual(ranks, [1, 0], "the copy (drawn last) shows on the shared face")
    }

    func testSelectedBodyWinsOverANewerOne() {
        let ranks = CoplanarDepthRanks.ranks(boxes: [box(0), box(5)], preferred: [true, false])
        XCTAssertEqual(ranks, [0, 1])
    }

    func testBoxesThatOnlyTouchStillDiffer() {
        // Side by side: the touching sides are coplanar.
        let ranks = CoplanarDepthRanks.ranks(boxes: [box(0), box(10)])
        XCTAssertNotEqual(ranks[0], ranks[1])
    }

    func testAChainNeedsOnlyTwoRanks() {
        // 0–10, 5–15, 10–20, …: each overlaps its neighbours only… and the
        // one after (they touch at a side), so three ranks at most.
        let ranks = CoplanarDepthRanks.ranks(boxes: (0..<30).map { box(Float($0) * 5) })
        XCTAssertLessThanOrEqual(ranks.max() ?? 0, 2)
        for i in 0..<29 { XCTAssertNotEqual(ranks[i], ranks[i + 1]) }
    }

    func testManyMutuallyOverlappingBodiesStopAtTheCap() {
        let ranks = CoplanarDepthRanks.ranks(boxes: (0..<20).map { box(Float($0) * 0.1) })
        XCTAssertEqual(ranks.max(), CoplanarDepthRanks.maxRank)
        XCTAssertEqual(Set(ranks.filter { $0 < CoplanarDepthRanks.maxRank }).count, CoplanarDepthRanks.maxRank,
                       "every rank below the cap is used once")
    }

    func testTransformedBoxCoversTheRotatedMesh() {
        // A unit cube turned 45° about Y spans ±√2/2 in X and Z.
        let turn = simd_float4x4(simd_quatf(angle: .pi / 4, axis: SIMD3(0, 1, 0)))
        let b = CoplanarDepthRanks.Box(local: (SIMD3(repeating: -0.5), SIMD3(repeating: 0.5)), transformedBy: turn)
        XCTAssertEqual(b.max.x, Float(2).squareRoot() / 2, accuracy: 1e-5)
        XCTAssertEqual(b.min.z, -Float(2).squareRoot() / 2, accuracy: 1e-5)
        XCTAssertEqual(b.max.y, 0.5, accuracy: 1e-6)
    }

    func testPastTheBodyLimitNothingIsRanked() {
        let ranks = CoplanarDepthRanks.ranks(boxes: (0...CoplanarDepthRanks.bodyLimit).map { _ in box(0) })
        XCTAssertEqual(ranks.max(), 0)
    }
}
