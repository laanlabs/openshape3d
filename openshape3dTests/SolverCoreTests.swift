//
//  SolverCoreTests.swift
//  openshape3dTests
//
//  Numerical-core tests for the pure-Swift constraint solver
//  (`ConstraintSolver.solve`). These use small synthetic `ConstraintResidual`
//  structs so the core is exercised without depending on the sketch-layer
//  constraint set. Point `p` occupies variable indices (2p, 2p+1).
//

import XCTest
@testable import openshape3d

// MARK: - Synthetic residuals (point index → vars 2p, 2p+1)

private nonisolated struct TDistance: ConstraintResidual {
    let pA: Int, pB: Int, distance: Double
    var variableIndices: [Int] { [2 * pA, 2 * pA + 1, 2 * pB, 2 * pB + 1] }
    var residualCount: Int { 1 }
    func residuals(_ v: [Double]) -> [Double] {
        let dx = v[2 * pB] - v[2 * pA]
        let dy = v[2 * pB + 1] - v[2 * pA + 1]
        return [(dx * dx + dy * dy).squareRoot() - distance]
    }
}

private nonisolated struct TCoincident: ConstraintResidual {
    let pA: Int, pB: Int
    var variableIndices: [Int] { [2 * pA, 2 * pA + 1, 2 * pB, 2 * pB + 1] }
    var residualCount: Int { 2 }
    func residuals(_ v: [Double]) -> [Double] {
        [v[2 * pB] - v[2 * pA], v[2 * pB + 1] - v[2 * pA + 1]]
    }
}

private nonisolated struct THorizontal: ConstraintResidual {
    let pA: Int, pB: Int
    var variableIndices: [Int] { [2 * pA + 1, 2 * pB + 1] }
    var residualCount: Int { 1 }
    func residuals(_ v: [Double]) -> [Double] { [v[2 * pB + 1] - v[2 * pA + 1]] }
}

private nonisolated struct TVertical: ConstraintResidual {
    let pA: Int, pB: Int
    var variableIndices: [Int] { [2 * pA, 2 * pB] }
    var residualCount: Int { 1 }
    func residuals(_ v: [Double]) -> [Double] { [v[2 * pB] - v[2 * pA]] }
}

private nonisolated struct TFixedPoint: ConstraintResidual {
    let p: Int, tx: Double, ty: Double
    var variableIndices: [Int] { [2 * p, 2 * p + 1] }
    var residualCount: Int { 2 }
    func residuals(_ v: [Double]) -> [Double] { [v[2 * p] - tx, v[2 * p + 1] - ty] }
}

final class SolverCoreTests: XCTestCase {

    func testNearAxisDistanceResizeAcrossScalesAndFixedEndpoints() {
        for scale in [0.001, 1.0, 1000.0] {
            for swapped in [false, true] {
                for sign in [-1.0, 1.0] {
                    for fixedStart in [false, true] {
                        let major = 1.531371682882309 * scale
                        let minor = sign * 1.1920928955078125e-7 * scale
                        let initial = [0.0, 0.0, swapped ? minor : major, swapped ? major : minor]
                        let target = 13 * scale
                        let result = ConstraintSolver.solve(initial: initial,
                            fixed: fixedStart ? [0, 1] : [],
                            constraints: [TDistance(pA: 0, pB: 1, distance: target)])
                        XCTAssertTrue(result.variables.allSatisfy(\.isFinite))
                        XCTAssertLessThan(result.residualNorm, max(1e-8, target * 1e-8))
                        let dx = result.variables[2] - result.variables[0]
                        let dy = result.variables[3] - result.variables[1]
                        XCTAssertEqual(hypot(dx, dy), target, accuracy: max(1e-8, target * 1e-8))
                        if fixedStart {
                            XCTAssertEqual(result.variables[0], initial[0])
                            XCTAssertEqual(result.variables[1], initial[1])
                        }
                    }
                }
            }
        }
    }

    private func dist(_ v: [Double], _ pA: Int, _ pB: Int) -> Double {
        let dx = v[2 * pB] - v[2 * pA]
        let dy = v[2 * pB + 1] - v[2 * pA + 1]
        return (dx * dx + dy * dy).squareRoot()
    }

    private func assertAllFinite(_ v: [Double], _ msg: String = "") {
        for e in v { XCTAssertTrue(e.isFinite, "non-finite value \(e) \(msg)") }
    }

    // (1) A single distance constraint pulls two free points to the target
    //     length; the system is under-determined so DOF = 3.
    func testDistancePullsPointsToTargetLength() {
        let initial: [Double] = [0, 0, 1, 0]   // P0=(0,0), P1=(1,0)
        let result = ConstraintSolver.solve(
            initial: initial, fixed: [],
            constraints: [TDistance(pA: 0, pB: 1, distance: 5)])

        assertAllFinite(result.variables)
        XCTAssertTrue(result.converged)
        XCTAssertEqual(dist(result.variables, 0, 1), 5, accuracy: 1e-6)
        XCTAssertLessThan(result.residualNorm, 1e-6)
        // 4 free vars, one independent residual → 3 DOF.
        XCTAssertEqual(result.degreesOfFreedom, 3)
    }

    // (2) An over-determined, REDUNDANT (but consistent) system converges
    //     without blow-up and reports DOF 0.
    func testRedundantSystemConvergesDOFZero() {
        // vars: P0(0,1), P1(2,3), all free.
        let initial: [Double] = [0.1, -0.1, 1, 0.2]
        let constraints: [any ConstraintResidual] = [
            TFixedPoint(p: 0, tx: 0, ty: 0),
            THorizontal(pA: 0, pB: 1),
            TDistance(pA: 0, pB: 1, distance: 4),
            THorizontal(pA: 0, pB: 1),   // redundant duplicate
        ]
        let result = ConstraintSolver.solve(initial: initial, fixed: [], constraints: constraints)

        assertAllFinite(result.variables)
        XCTAssertTrue(result.converged)
        XCTAssertLessThan(result.residualNorm, 1e-6)
        XCTAssertEqual(result.variables[0], 0, accuracy: 1e-6)
        XCTAssertEqual(result.variables[1], 0, accuracy: 1e-6)
        XCTAssertEqual(dist(result.variables, 0, 1), 4, accuracy: 1e-6)
        // Redundant duplicate adds no rank → fully constrained.
        XCTAssertEqual(result.degreesOfFreedom, 0)
    }

    // (3) A conflicting system stays finite (best fit) and never NaNs.
    func testConflictingSystemStaysFinite() {
        // Two contradictory distances on the same pair → best fit d = 3.
        let initial: [Double] = [0, 0, 2, 0]
        let constraints: [any ConstraintResidual] = [
            TDistance(pA: 0, pB: 1, distance: 1),
            TDistance(pA: 0, pB: 1, distance: 5),
        ]
        let result = ConstraintSolver.solve(initial: initial, fixed: [], constraints: constraints)

        assertAllFinite(result.variables)
        XCTAssertTrue(result.residualNorm.isFinite)
        XCTAssertFalse(result.residualNorm.isNaN)
        // Least-squares midpoint of the two targets.
        XCTAssertEqual(dist(result.variables, 0, 1), 3, accuracy: 1e-5)
    }

    // (4) A 4-point square from H/V/coincident/distance residuals solves to a
    //     square and DOF matches the hand calculation (0).
    func testSquareSolvesAndDOFMatches() {
        let L = 2.0
        // P0 pinned via the `fixed` set at (0,0); P1..P3 corners; P4 coincident
        // with P2 to exercise the coincident residual without changing DOF.
        var v = [Double](repeating: 0, count: 10)
        v[0] = 0;   v[1] = 0        // P0 (fixed)
        v[2] = 1.8; v[3] = 0.2      // P1 ~ (L,0)
        v[4] = 2.2; v[5] = 1.9      // P2 ~ (L,L)
        v[6] = 0.1; v[7] = 1.8      // P3 ~ (0,L)
        v[8] = 2.1; v[9] = 2.05     // P4 ~ P2

        let constraints: [any ConstraintResidual] = [
            THorizontal(pA: 0, pB: 1),          // bottom edge horizontal
            TVertical(pA: 0, pB: 3),            // left edge vertical
            TDistance(pA: 0, pB: 1, distance: L),
            TDistance(pA: 0, pB: 3, distance: L),
            THorizontal(pA: 3, pB: 2),          // top edge horizontal
            TVertical(pA: 1, pB: 2),            // right edge vertical
            TCoincident(pA: 4, pB: 2),          // P4 rides on P2
        ]
        let result = ConstraintSolver.solve(initial: v, fixed: [0, 1], constraints: constraints)
        let s = result.variables

        assertAllFinite(s)
        XCTAssertTrue(result.converged)
        XCTAssertLessThan(result.residualNorm, 1e-6)
        // Corners.
        XCTAssertEqual(s[2], L, accuracy: 1e-5); XCTAssertEqual(s[3], 0, accuracy: 1e-5)  // P1
        XCTAssertEqual(s[4], L, accuracy: 1e-5); XCTAssertEqual(s[5], L, accuracy: 1e-5)  // P2
        XCTAssertEqual(s[6], 0, accuracy: 1e-5); XCTAssertEqual(s[7], L, accuracy: 1e-5)  // P3
        XCTAssertEqual(s[8], L, accuracy: 1e-5); XCTAssertEqual(s[9], L, accuracy: 1e-5)  // P4 == P2
        // All four sides equal L.
        XCTAssertEqual(dist(s, 0, 1), L, accuracy: 1e-5)
        XCTAssertEqual(dist(s, 1, 2), L, accuracy: 1e-5)
        XCTAssertEqual(dist(s, 2, 3), L, accuracy: 1e-5)
        XCTAssertEqual(dist(s, 3, 0), L, accuracy: 1e-5)
        // Fully constrained.
        XCTAssertEqual(result.degreesOfFreedom, 0)
    }

    // (5) Fixed variables never move; the remaining free point solves and DOF
    //     reflects only the free variables.
    func testFixedVariablesStayPut() {
        let initial: [Double] = [5, 7, 6, 7]   // P0=(5,7) fixed, P1 free
        let result = ConstraintSolver.solve(
            initial: initial, fixed: [0, 1],
            constraints: [TDistance(pA: 0, pB: 1, distance: 3)])

        assertAllFinite(result.variables)
        // Fixed vars are bit-identical — never written.
        XCTAssertEqual(result.variables[0], 5)
        XCTAssertEqual(result.variables[1], 7)
        XCTAssertEqual(dist(result.variables, 0, 1), 3, accuracy: 1e-6)
        // 2 free vars, 1 residual → 1 DOF.
        XCTAssertEqual(result.degreesOfFreedom, 1)
    }

    // Extra guard: an empty constraint set is a no-op that reports all DOF.
    func testNoConstraintsReportsAllDOF() {
        let initial: [Double] = [1, 2, 3, 4]
        let result = ConstraintSolver.solve(initial: initial, fixed: [1], constraints: [])
        XCTAssertEqual(result.variables, initial)
        XCTAssertTrue(result.converged)
        XCTAssertEqual(result.degreesOfFreedom, 3)  // 4 vars − 1 fixed
        XCTAssertEqual(result.residualNorm, 0)
    }
}
