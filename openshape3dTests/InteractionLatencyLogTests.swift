//
//  InteractionLatencyLogTests.swift
//  openshape3dTests
//
//  The matching behind the latency diagnostics: an input is "handled" when
//  the main thread next goes idle, and "presented" when the first viewport
//  frame started after it reaches the screen — never a frame from more than
//  a second later, which the on-demand viewport would draw for something else.
//

import XCTest
@testable import openshape3d

final class InteractionLatencyLogTests: XCTestCase {

    func testATapIsHandledAtTheNextIdleAndShownByTheNextFrame() {
        var log = InteractionLatencyLog(started: 10)
        log.input(.press, at: 10.000)
        log.mainThreadIdle(at: 10.004)
        let f = log.frameStarted(at: 10.006)
        log.input(.release, at: 10.080)
        log.framePresented(f, at: 10.022)
        log.mainThreadIdle(at: 10.095)
        let g = log.frameStarted(at: 10.097)
        log.framePresented(g, at: 10.113)
        XCTAssertEqual(log.handledMS(.press)[0], 4, accuracy: 1e-6)
        XCTAssertEqual(log.presentedMS(.press)[0], 22, accuracy: 1e-6)
        XCTAssertEqual(log.handledMS(.release)[0], 15, accuracy: 1e-6)
        XCTAssertEqual(log.presentedMS(.release)[0], 33, accuracy: 1e-6)
        XCTAssertEqual(log.framesDrawn, 2); XCTAssertEqual(log.framesPresented, 2)
    }

    func testSeveralDragStepsBeforeOneFrameAllMapToIt() {
        var log = InteractionLatencyLog()
        for k in 0..<4 { log.input(.drag, at: 1 + Double(k) * 0.004) }
        let f = log.frameStarted(at: 1.020)
        log.framePresented(f, at: 1.030)
        XCTAssertEqual(log.presentedMS(.drag).map { ($0 * 1000).rounded() / 1000 }, [30, 26, 22, 18])
    }

    func testAFrameMoreThanASecondLaterIsNotBlamedOnTheInput() {
        var log = InteractionLatencyLog()
        log.input(.release, at: 5)              // e.g. a toolbar button: no viewport change
        let f = log.frameStarted(at: 6.5)       // something else redraws much later
        log.framePresented(f, at: 6.52)
        XCTAssertTrue(log.presentedMS(.release).isEmpty)
        XCTAssertNil(log.inputs[0].frame)
    }

    func testAFrameThatNeverReachedTheScreenLeavesPresentedEmpty() {
        var log = InteractionLatencyLog()
        log.input(.press, at: 1)
        let f = log.frameStarted(at: 1.01)
        log.framePresented(f, at: 0)
        XCTAssertNil(log.inputs[0].presented)
        XCTAssertEqual(log.framesPresented, 0)
    }

    func testAnIdleBeforeTheInputDoesNotHandleIt() {
        var log = InteractionLatencyLog()
        log.mainThreadIdle(at: 1)
        log.input(.key, at: 2)
        XCTAssertNil(log.inputs[0].handled)
        log.mainThreadIdle(at: 2.5)
        XCTAssertEqual(log.handledMS(.key)[0], 500, accuracy: 1e-6)
    }

    func testCapacityKeepsTheNewestInputs() {
        var log = InteractionLatencyLog(capacity: 3)
        for k in 0..<5 { log.input(.press, at: Double(k)) }
        XCTAssertEqual(log.inputs.map(\.t), [2, 3, 4])
    }

    func testStatsAndGapsBetweenActions() {
        let s = InteractionLatencyLog.stats([5, 1, 3, 2, 4])
        XCTAssertEqual(s, InteractionLatencyLog.Stats(count: 5, p50: 3, p95: 5, max: 5))
        XCTAssertNil(InteractionLatencyLog.stats([]))
        var log = InteractionLatencyLog()
        log.input(.press, at: 1); log.input(.release, at: 1.1); log.input(.press, at: 2.5); log.input(.key, at: 3)
        XCTAssertEqual(log.gapsBetweenActionsMS().map { $0.rounded() }, [1500, 500])
    }

    func testResetStartsOver() {
        var log = InteractionLatencyLog()
        log.input(.press, at: 1); _ = log.frameStarted(at: 1.1); log.hitch(at: 1.2, ms: 80)
        log.reset(at: 9)
        XCTAssertTrue(log.inputs.isEmpty); XCTAssertTrue(log.hitches.isEmpty)
        XCTAssertEqual(log.framesDrawn, 0); XCTAssertEqual(log.started, 9)
    }

    // MARK: - Agent routes

    private func route(_ method: String, _ target: String, _ body: String = "") -> AgentRoute {
        var r = AgentRequest(method: method, path: target)
        if let q = target.split(separator: "?").dropFirst().first {
            r.path = String(target.split(separator: "?")[0])
            for kv in q.split(separator: "&") { let p = kv.split(separator: "="); r.query[String(p[0])] = String(p[1]) }
        }
        r.body = Data(body.utf8)
        return AgentRouter.route(r)
    }

    func testRoutes() {
        XCTAssertEqual(route("GET", "/v1/diagnostics/latency"), .latencyReport(events: 50))
        XCTAssertEqual(route("GET", "/v1/diagnostics/latency?events=7"), .latencyReport(events: 7))
        XCTAssertEqual(route("POST", "/v1/diagnostics/latency", #"{"enabled":true,"reset":true}"#),
                       .latencyControl(enabled: true, reset: true))
        XCTAssertEqual(route("POST", "/v1/diagnostics/latency", #"{"reset":true}"#),
                       .latencyControl(enabled: nil, reset: true))
        guard case .reply(400, "bad_latency_control", _) = route("POST", "/v1/diagnostics/latency", "{}") else {
            return XCTFail("an empty control body is refused")
        }
    }
}
