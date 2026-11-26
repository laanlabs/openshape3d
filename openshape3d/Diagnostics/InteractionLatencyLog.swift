//
//  InteractionLatencyLog.swift
//  openshape3d
//
//  How long the app takes to answer a person's input, measured from inside:
//  each touch / click / key is matched to the moment the main thread was done
//  with it (the run loop about to sleep, after Core Animation committed —
//  "handled") and to the first viewport frame that started drawing after it
//  and its real on-screen time (`MTLDrawable.presentedTime` — "presented").
//  Plus main-thread hitches seen by a display link. Pure bookkeeping: the
//  hooks that feed it live in `InteractionLatency`. All times are seconds on
//  the `CACurrentMediaTime` clock, which `UIEvent.timestamp` and
//  `presentedTime` share.
//

import Foundation

nonisolated struct InteractionLatencyLog: Sendable {

    enum Phase: String, Sendable, CaseIterable {
        /// Finger/mouse down: where a drag or a tap starts.
        case press
        /// Finger/mouse moved while down: each step of a drag.
        case drag
        /// Finger/mouse up: when a button or a tap acts.
        case release
        /// A hardware key.
        case key
    }

    struct Input: Sendable, Equatable {
        var id: Int
        var t: Double
        var phase: Phase
        var x: Double
        var y: Double
        /// The main thread went idle after this input (all its work and the
        /// Core Animation commit done).
        var handled: Double? = nil
        /// The first viewport frame that started after this input.
        var frame: Int? = nil
        /// That frame's on-screen time; nil until known, or if never shown.
        var presented: Double? = nil
    }

    struct Hitch: Sendable, Equatable {
        /// When the late display-link callback arrived.
        var t: Double
        /// How much longer than one refresh the main thread was away.
        var ms: Double
    }

    /// A frame drawn more than this long after an input is not that input's
    /// answer (the viewport only draws on demand, so an unrelated later frame
    /// would otherwise be blamed on a tap that changed nothing in it).
    static let frameWindow = 1.0

    let capacity: Int
    private(set) var inputs: [Input] = []
    private(set) var hitches: [Hitch] = []
    private(set) var framesDrawn = 0
    private(set) var framesPresented = 0
    private(set) var started: Double
    private var nextID = 0

    init(capacity: Int = 5000, started: Double = 0) {
        self.capacity = capacity
        self.started = started
    }

    mutating func reset(at t: Double) { self = InteractionLatencyLog(capacity: capacity, started: t) }

    mutating func input(_ phase: Phase, at t: Double, x: Double = 0, y: Double = 0) {
        inputs.append(Input(id: nextID, t: t, phase: phase, x: x, y: y)); nextID += 1
        if inputs.count > capacity { inputs.removeFirst(inputs.count - capacity) }
    }

    /// The main run loop is about to sleep: everything that came in before
    /// `t` has been handled.
    mutating func mainThreadIdle(at t: Double) {
        for i in inputs.indices.reversed() {
            if inputs[i].handled != nil { break }
            if inputs[i].t <= t { inputs[i].handled = t }
        }
    }

    /// A viewport frame starts drawing at `t`; returns its number so the
    /// presented time can be filled in later.
    mutating func frameStarted(at t: Double) -> Int {
        let frame = framesDrawn; framesDrawn += 1
        for i in inputs.indices.reversed() {
            if inputs[i].frame != nil { break }
            if inputs[i].t <= t, t - inputs[i].t <= Self.frameWindow { inputs[i].frame = frame }
        }
        return frame
    }

    /// Frame `frame` reached the screen at `t` (0 or less: it never did).
    mutating func framePresented(_ frame: Int, at t: Double) {
        guard t > 0 else { return }
        framesPresented += 1
        for i in inputs.indices.reversed() where inputs[i].frame == frame { inputs[i].presented = t }
    }

    mutating func hitch(at t: Double, ms: Double) {
        hitches.append(Hitch(t: t, ms: ms))
        if hitches.count > capacity { hitches.removeFirst(hitches.count - capacity) }
    }

    // MARK: - Report

    struct Stats: Sendable, Equatable {
        var count: Int
        var p50: Double
        var p95: Double
        var max: Double
    }

    static func stats(_ values: [Double]) -> Stats? {
        guard !values.isEmpty else { return nil }
        let v = values.sorted()
        func pct(_ p: Double) -> Double { v[min(v.count - 1, Int((p * Double(v.count - 1)).rounded()))] }
        return Stats(count: v.count, p50: pct(0.5), p95: pct(0.95), max: v[v.count - 1])
    }

    /// Milliseconds from each input of `phase` to it being handled / shown.
    func handledMS(_ phase: Phase) -> [Double] {
        inputs.filter { $0.phase == phase }.compactMap { i in i.handled.map { ($0 - i.t) * 1000 } }
    }

    func presentedMS(_ phase: Phase) -> [Double] {
        inputs.filter { $0.phase == phase }.compactMap { i in i.presented.map { ($0 - i.t) * 1000 } }
    }

    /// Gaps between consecutive presses/keys (a person's pace), in ms.
    func gapsBetweenActionsMS() -> [Double] {
        let starts = inputs.filter { $0.phase == .press || $0.phase == .key }.map(\.t)
        return zip(starts.dropFirst(), starts).map { ($0 - $1) * 1000 }
    }
}
