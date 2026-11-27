//
//  InteractionLatencyLog.swift
//  openshape3d
//
//  How long the app takes to answer a touch or a click, as numbers.
//
//  "It feels slow on my iPad" cannot be acted on, and timing an operation
//  from outside (`/v1/exec` does) is not what a person feels: that is the
//  time from the input until the result is on the screen, and the moments
//  the interface stops. Inside the app three moments sit on one clock
//  (seconds since boot, the clock of `UIEvent.timestamp`,
//  `CACurrentMediaTime()` and `MTLDrawable.presentedTime`):
//
//    • the input arrived;
//    • the main thread finished with it (the run loop is about to wait);
//    • the next frame reached the screen.
//
//  This file is the arithmetic on those moments, as a plain value, so it is
//  tested without a device. `InteractionLatencyRecorder` feeds it.
//

import Foundation

nonisolated struct InteractionLatencyLog: Sendable {

    /// A main-thread pass at least this long counts as a hitch: three
    /// frames at 60 Hz, long enough to see.
    var hitchThreshold = 0.050
    /// The newest this many of each kind are kept.
    var capacity = 5000

    /// Input → main thread idle, seconds.
    private(set) var handling: [Double] = []
    /// Input → frame on screen, seconds.
    private(set) var display: [Double] = []
    /// Main-thread passes at or over `hitchThreshold`, seconds.
    private(set) var hitches: [Double] = []
    private(set) var inputCount = 0

    /// The first input the main thread has not finished with yet.
    private var unhandled: Double?
    /// The first input whose frame has not been shown yet.
    private var unshown: Double?

    /// An input arrived at `time`. Several before the main thread comes up
    /// for air are one wait, counted from the first.
    mutating func input(at time: Double) {
        inputCount += 1
        if unhandled == nil { unhandled = time }
        if unshown == nil { unshown = time }
    }

    /// The main thread worked from `start` until `end` without pausing: one
    /// pass of the run loop.
    mutating func mainThreadBusy(from start: Double, to end: Double) {
        let span = end - start
        guard span.isFinite, span >= 0 else { return }
        if span >= hitchThreshold { hitches = kept(hitches, adding: span) }
        if let input = unhandled, input <= end {
            handling = kept(handling, adding: max(0, end - input))
            unhandled = nil
        }
    }

    /// A frame reached the screen at `time`. The first one after an input is
    /// that input's frame: the viewport draws when something changed.
    mutating func framePresented(at time: Double) {
        guard time.isFinite, time > 0, let input = unshown, time >= input else { return }
        display = kept(display, adding: time - input)
        unshown = nil
    }

    mutating func reset() {
        handling = []; display = []; hitches = []
        inputCount = 0
        unhandled = nil; unshown = nil
    }

    private func kept(_ list: [Double], adding value: Double) -> [Double] {
        var list = list
        list.append(value)
        if list.count > capacity { list.removeFirst(list.count - capacity) }
        return list
    }

    // MARK: - Reading it

    struct Summary: Equatable, Sendable {
        var count = 0
        var medianMS = 0.0
        var p95MS = 0.0
        var maxMS = 0.0
    }

    /// Count, median, 95th percentile and worst of `seconds`, in milliseconds.
    static func summary(of seconds: [Double]) -> Summary {
        guard !seconds.isEmpty else { return Summary() }
        let sorted = seconds.sorted()
        func at(_ fraction: Double) -> Double {
            sorted[min(sorted.count - 1, Int((Double(sorted.count - 1) * fraction).rounded()))] * 1000
        }
        return Summary(count: sorted.count, medianMS: at(0.5), p95MS: at(0.95), maxMS: sorted[sorted.count - 1] * 1000)
    }

    /// Everything, as JSON-ready values. Times in milliseconds, one decimal.
    func report(recording: Bool) -> [String: Any] {
        func row(_ summary: Summary) -> [String: Any] {
            func round1(_ v: Double) -> Double { (v * 10).rounded() / 10 }
            return ["count": summary.count, "medianMS": round1(summary.medianMS),
                    "p95MS": round1(summary.p95MS), "maxMS": round1(summary.maxMS)]
        }
        var hitchRow = row(Self.summary(of: hitches))
        hitchRow["totalMS"] = ((hitches.reduce(0, +) * 1000) * 10).rounded() / 10
        hitchRow["thresholdMS"] = hitchThreshold * 1000
        return [
            "recording": recording,
            "inputs": inputCount,
            "inputToIdle": row(Self.summary(of: handling)),
            "inputToScreen": row(Self.summary(of: display)),
            "hitches": hitchRow,
        ]
    }
}
