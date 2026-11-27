//
//  LatencyRecorderUITests.swift
//  openshape3dUITests
//
//  The input-latency recorder in the running app: with it on, taps and a
//  drag are counted and timed, and the app still answers them (its
//  recognizer must take no part in anything). Read back over the developer
//  channel, the way a person measuring would.
//

import XCTest

final class LatencyRecorderUITests: XCTestCase {

    private let port = 8791

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func latency() throws -> [String: Any] {
        let url = try XCTUnwrap(URL(string: "http://127.0.0.1:\(port)/v1/latency"))
        var result: [String: Any]?
        let done = expectation(description: "latency")
        URLSession.shared.dataTask(with: url) { data, _, _ in
            result = data.flatMap { try? JSONSerialization.jsonObject(with: $0) as? [String: Any] }
            done.fulfill()
        }.resume()
        wait(for: [done], timeout: 10)
        return try XCTUnwrap(result, "the app did not answer /v1/latency")
    }

    func testTouchesAreTimedAndStillWork() throws {
        let app = XCUIApplication()
        app.launchEnvironment["OS3D_FRESH"] = "1"
        app.launchEnvironment["OS3D_AGENT"] = "1"
        app.launchEnvironment["OS3D_AGENT_PORT"] = String(port)
        app.launchEnvironment["OS3D_LATENCY"] = "1"
        app.launch()
        let settings = app.buttons["SettingsButton"]
        XCTAssertTrue(settings.waitForExistence(timeout: 20))
        sleep(2)                                         // the recorder starts a second after launch

        let before = try latency()
        XCTAssertEqual(before["recording"] as? Bool, true)

        // A drag across the viewport, then a control: both must still work.
        let window = app.windows.firstMatch
        window.coordinate(withNormalizedOffset: CGVector(dx: 0.45, dy: 0.55))
            .press(forDuration: 0.1, thenDragTo: window.coordinate(withNormalizedOffset: CGVector(dx: 0.6, dy: 0.6)))
        settings.tap()
        let done = app.buttons["SettingsDone"]
        XCTAssertTrue(done.waitForExistence(timeout: 5), "a tap still opens Settings while recording")
        done.tap()
        XCTAssertTrue(done.waitForNonExistence(timeout: 5))

        let after = try latency()
        let inputs = after["inputs"] as? Int ?? 0
        XCTAssertGreaterThan(inputs, (before["inputs"] as? Int ?? 0) + 4, "a drag and two taps are many touch events")
        let idle = try XCTUnwrap(after["inputToIdle"] as? [String: Any])
        XCTAssertGreaterThan(idle["count"] as? Int ?? 0, 2, "each was timed until the main thread was idle")
        XCTAssertGreaterThan(idle["maxMS"] as? Double ?? 0, 0)
        XCTAssertLessThan(idle["medianMS"] as? Double ?? .infinity, 2000, "a time, not a clock reading")
        XCTAssertNotNil(after["hitches"])
        XCTAssertNotNil(after["inputToScreen"])
        print("LATENCY \(after)")
    }
}
