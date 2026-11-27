//
//  InteractionLatencyLogTests.swift
//  openshape3dTests
//
//  The arithmetic of the input-latency recorder: what counts as one wait,
//  what counts as a hitch, which frame answers which input.
//

import XCTest
@testable import openshape3d

final class InteractionLatencyLogTests: XCTestCase {

    func testAnInputIsTimedUntilTheMainThreadComesUpForAir() {
        var log = InteractionLatencyLog()
        log.input(at: 10.000)
        log.mainThreadBusy(from: 10.002, to: 10.030)
        XCTAssertEqual(log.handling.count, 1)
        XCTAssertEqual(log.handling[0], 0.030, accuracy: 1e-9, "from the input, not from when the thread woke")
        XCTAssertTrue(log.hitches.isEmpty, "28 ms of work is not a hitch")
        // The next pass has no input to answer.
        log.mainThreadBusy(from: 10.040, to: 10.045)
        XCTAssertEqual(log.handling.count, 1)
    }

    func testSeveralInputsInOnePassAreOneWaitFromTheFirst() {
        var log = InteractionLatencyLog()
        log.input(at: 5.00)
        log.input(at: 5.01)
        log.input(at: 5.02)
        log.mainThreadBusy(from: 4.99, to: 5.20)
        XCTAssertEqual(log.inputCount, 3)
        XCTAssertEqual(log.handling.count, 1)
        XCTAssertEqual(log.handling[0], 0.20, accuracy: 1e-9)
        XCTAssertEqual(log.hitches.count, 1, "and the 210 ms pass is a hitch")
        XCTAssertEqual(log.hitches[0], 0.21, accuracy: 1e-9)
    }

    func testAHitchNeedsNoInput() {
        var log = InteractionLatencyLog()
        log.hitchThreshold = 0.0625                     // a sixteenth: exact in binary
        log.mainThreadBusy(from: 1.0, to: 1.049)
        XCTAssertTrue(log.hitches.isEmpty)
        log.mainThreadBusy(from: 2.0, to: 2.0625)
        XCTAssertEqual(log.hitches.count, 1, "at the threshold counts")
        XCTAssertTrue(log.handling.isEmpty)
        // Nonsense spans are dropped.
        log.mainThreadBusy(from: 3.0, to: 2.0)
        log.mainThreadBusy(from: .nan, to: 4.0)
        XCTAssertEqual(log.hitches.count, 1)
    }

    func testTheFirstFrameAfterAnInputIsItsFrame() {
        var log = InteractionLatencyLog()
        log.framePresented(at: 7.0)
        XCTAssertTrue(log.display.isEmpty, "a frame with no input before it answers nothing")
        log.input(at: 8.000)
        log.input(at: 8.010)
        log.framePresented(at: 7.990)
        XCTAssertTrue(log.display.isEmpty, "a frame from before the input was already on its way")
        log.framePresented(at: 8.040)
        XCTAssertEqual(log.display.count, 1)
        XCTAssertEqual(log.display[0], 0.040, accuracy: 1e-9, "from the first of the two inputs")
        log.framePresented(at: 8.056)
        XCTAssertEqual(log.display.count, 1, "the next frame is nobody's")
        // The simulator reports no presented time.
        log.input(at: 9.0)
        log.framePresented(at: 0)
        XCTAssertEqual(log.display.count, 1)
    }

    func testSummaryIsMedianNinetyFifthAndWorstInMilliseconds() {
        let samples = (1...100).map { Double($0) / 1000 }          // 1 … 100 ms
        let summary = InteractionLatencyLog.summary(of: samples.shuffled())
        XCTAssertEqual(summary.count, 100)
        XCTAssertEqual(summary.medianMS, 51, accuracy: 1e-9)
        XCTAssertEqual(summary.p95MS, 95, accuracy: 1e-9)
        XCTAssertEqual(summary.maxMS, 100, accuracy: 1e-9)
        XCTAssertEqual(InteractionLatencyLog.summary(of: []), InteractionLatencyLog.Summary())
        XCTAssertEqual(InteractionLatencyLog.summary(of: [0.012]).p95MS, 12, accuracy: 1e-9)
    }

    func testOnlyTheNewestSamplesAreKept() {
        var log = InteractionLatencyLog()
        log.capacity = 3
        for i in 0..<10 {
            log.input(at: Double(i))
            log.mainThreadBusy(from: Double(i), to: Double(i) + 0.001 * Double(i + 1))
        }
        XCTAssertEqual(log.handling.count, 3)
        XCTAssertEqual(log.handling.last ?? 0, 0.010, accuracy: 1e-9)
        XCTAssertEqual(log.inputCount, 10)
    }

    func testReportAndReset() throws {
        var log = InteractionLatencyLog()
        log.input(at: 1.0)
        log.mainThreadBusy(from: 1.0, to: 1.120)
        log.framePresented(at: 1.133)
        let report = log.report(recording: true)
        XCTAssertTrue(JSONSerialization.isValidJSONObject(report))
        XCTAssertEqual(report["recording"] as? Bool, true)
        XCTAssertEqual(report["inputs"] as? Int, 1)
        let idle = try XCTUnwrap(report["inputToIdle"] as? [String: Any])
        XCTAssertEqual(idle["count"] as? Int, 1)
        XCTAssertEqual(idle["medianMS"] as? Double ?? 0, 120, accuracy: 0.05)
        let screen = try XCTUnwrap(report["inputToScreen"] as? [String: Any])
        XCTAssertEqual(screen["maxMS"] as? Double ?? 0, 133, accuracy: 0.05)
        let hitches = try XCTUnwrap(report["hitches"] as? [String: Any])
        XCTAssertEqual(hitches["count"] as? Int, 1)
        XCTAssertEqual(hitches["totalMS"] as? Double ?? 0, 120, accuracy: 0.05)
        XCTAssertEqual(hitches["thresholdMS"] as? Double, 50)

        log.reset()
        XCTAssertEqual(log.inputCount, 0)
        XCTAssertTrue(log.handling.isEmpty && log.display.isEmpty && log.hitches.isEmpty)
        // An input from before the reset is not waited for after it.
        log.mainThreadBusy(from: 2.0, to: 2.01)
        XCTAssertTrue(log.handling.isEmpty)
    }
}
