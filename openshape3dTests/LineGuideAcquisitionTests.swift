import XCTest
import simd
@testable import openshape3d

final class LineGuideAcquisitionTests: XCTestCase {
    func testGuideAcquisitionAndSavedAxisConstraintAreIndependentAtTwoScales() {
        for scale in [1.0, 100.0] {
            for vertical in [false, true] {
                for sign in [-1.0, 1.0] {
                    let anchor = SIMD2<Double>(10, 20) * scale
                    let delta = (vertical ? SIMD2<Double>(0.01 * sign, 1) : SIMD2<Double>(1, 0.01 * sign)) * scale
                    let target = anchor + delta
                    for auto in [false, true] {
                        for guides in [false, true] {
                            var settings = AutoConstraintSettings()
                            settings.enabled = auto
                            settings.pointSnap = false
                            settings.parallelPerpendicular = false
                            settings.tangent = false
                            let result = AutoConstraintEngine.inferLineInput(anchor: anchor,
                                current: target, existing: [], settings: settings, guideLines: guides)
                            let expected = guides
                                ? anchor + (vertical ? SIMD2(0, delta.y) : SIMD2(delta.x, 0)) : target
                            XCTAssertEqual(simd_length(result.snappedPoint - expected), 0, accuracy: 1e-8)
                            XCTAssertEqual(result.constraints.count, auto && guides ? 1 : 0)
                            if auto && guides {
                                XCTAssertEqual(result.constraints.first?.kind, vertical ? .vertical : .horizontal)
                            }
                        }
                    }
                }
            }
        }
    }

    func testGuideLinesRespectToleranceAndAxisInferenceOptOut() {
        var settings = AutoConstraintSettings()
        let target = SIMD2<Double>(100, 2) // 1.15°, outside the 1° gate
        let outside = AutoConstraintEngine.inferLineInput(anchor: .zero, current: target,
            existing: [], settings: settings, guideLines: true)
        XCTAssertEqual(outside.snappedPoint, target)
        XCTAssertTrue(outside.constraints.isEmpty)
        settings.horizontalVertical = false
        let near = AutoConstraintEngine.inferLineInput(anchor: .zero, current: SIMD2(100, 1),
            existing: [], settings: settings, guideLines: true)
        XCTAssertEqual(near.snappedPoint, SIMD2(100, 0))
        XCTAssertTrue(near.constraints.isEmpty, "Acquisition must not override the saved-relation opt-out")
    }

    func testExactAxisCanStillBeConstrainedWithoutGuideAcquisition() {
        let result = AutoConstraintEngine.inferLineInput(anchor: .zero, current: SIMD2(100, 0),
            existing: [], settings: AutoConstraintSettings(), guideLines: false)
        XCTAssertEqual(result.snappedPoint, SIMD2(100, 0))
        XCTAssertEqual(result.constraints.first?.kind, .horizontal)
    }
    func testScreenDistanceBandIsIndependentOfLengthAndZoom() {
        for scale in [0.01, 1.0] {
            for length in [100.0, 200.0, 300.0] {
                for rise in [-5.0, -4.0, 4.0, 5.0] {
                    for vertical in [false, true] {
                        for auto in [false, true] {
                            var settings = AutoConstraintSettings()
                            settings.enabled = auto
                            let delta = (vertical ? SIMD2(rise, length) : SIMD2(length, rise)) * scale
                            let result = AutoConstraintEngine.inferLineInput(anchor: .zero,
                                current: delta, existing: [], settings: settings, guideLines: true,
                                guideDistanceTolerance: 4 * scale)
                            let component = vertical ? result.snappedPoint.x : result.snappedPoint.y
                            XCTAssertEqual(component, abs(rise) <= 4 ? 0 : rise * scale, accuracy: 1e-8)
                            XCTAssertEqual(result.constraints.count, abs(rise) <= 4 && auto ? 1 : 0)
                        }
                    }
                }
            }
        }
    }

}
