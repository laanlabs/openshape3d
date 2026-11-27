//
//  InteractionLatencyRecorder.swift
//  openshape3d
//
//  Feeds `InteractionLatencyLog` from the running app. Off until asked for:
//  nothing is installed and the one check in the draw loop is a `Bool`.
//
//  Switch it on with `POST /v1/latency {"record": true}` over the developer
//  channel, or launch a Debug build with `OS3D_LATENCY=1`; read it with
//  `GET /v1/latency`. Three taps into the app while it records:
//
//    • inputs: a gesture recognizer on every window that never recognizes
//      anything, only reads each touch's (or click's) event time;
//    • the main thread: a run-loop observer, from waking to about to wait;
//    • frames: `Renderer` asks each drawable when it was shown.
//
//  Not seen: the scroll wheel, a hovering pointer and the keyboard, which do
//  not arrive as touches. On the simulator a drawable has no presented time,
//  so `inputToScreen` stays empty there; the other two are real.
//

import QuartzCore
import UIKit

@MainActor
final class InteractionLatencyRecorder {

    static let shared = InteractionLatencyRecorder()

    /// Read from the draw loop on every frame.
    nonisolated(unsafe) private(set) static var isOn = false

    private var log = InteractionLatencyLog()
    private var observer: CFRunLoopObserver?
    private var wokeAt: Double?
    private var taps: [(window: UIWindow, recognizer: UIGestureRecognizer)] = []

    private init() {}

    var isRecording: Bool { Self.isOn }

    func report() -> [String: Any] { log.report(recording: Self.isOn) }

    func reset() { log.reset() }

    func setRecording(_ on: Bool) {
        guard on != Self.isOn else { return }
        Self.isOn = on
        if on { install() } else { remove() }
    }

    /// `Renderer` hands over each frame's shown time (0 when the system does
    /// not say, as on the simulator).
    func framePresented(at time: Double) {
        guard Self.isOn else { return }
        log.framePresented(at: time)
    }

    fileprivate func input(at time: Double) {
        guard Self.isOn else { return }
        log.input(at: time)
    }

    private func install() {
        wokeAt = CACurrentMediaTime()
        let activities = CFRunLoopActivity.afterWaiting.rawValue | CFRunLoopActivity.beforeWaiting.rawValue
        // The observer is on the main run loop, so its block runs on the
        // main thread; the hop is only for the compiler.
        let observer = CFRunLoopObserverCreateWithHandler(nil, activities, true, 0) { _, activity in
            let now = CACurrentMediaTime()
            MainActor.assumeIsolated {
                let recorder = InteractionLatencyRecorder.shared
                if activity == .afterWaiting {
                    recorder.wokeAt = now
                } else if let woke = recorder.wokeAt {
                    recorder.log.mainThreadBusy(from: woke, to: now)
                    recorder.wokeAt = nil
                }
            }
        }
        CFRunLoopAddObserver(CFRunLoopGetMain(), observer, .commonModes)
        self.observer = observer

        for case let scene as UIWindowScene in UIApplication.shared.connectedScenes {
            for window in scene.windows {
                let recognizer = InputTimeRecognizer(target: nil, action: nil)
                window.addGestureRecognizer(recognizer)
                taps.append((window, recognizer))
            }
        }
    }

    private func remove() {
        if let observer { CFRunLoopRemoveObserver(CFRunLoopGetMain(), observer, .commonModes) }
        observer = nil
        wokeAt = nil
        for tap in taps { tap.window.removeGestureRecognizer(tap.recognizer) }
        taps = []
    }
}

/// Reads the event time of every touch in its window and takes no part in
/// anything: it never begins, cancels or delays a touch, and every other
/// recognizer runs alongside it.
private final class InputTimeRecognizer: UIGestureRecognizer, UIGestureRecognizerDelegate {

    override init(target: Any?, action: Selector?) {
        super.init(target: target, action: action)
        cancelsTouchesInView = false
        delaysTouchesBegan = false
        delaysTouchesEnded = false
        delegate = self
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        InteractionLatencyRecorder.shared.input(at: event.timestamp)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        InteractionLatencyRecorder.shared.input(at: event.timestamp)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        InteractionLatencyRecorder.shared.input(at: event.timestamp)
        state = .failed
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
        state = .failed
    }

    override func canPrevent(_ preventedGestureRecognizer: UIGestureRecognizer) -> Bool { false }

    override func canBePrevented(by preventingGestureRecognizer: UIGestureRecognizer) -> Bool { false }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool { true }
}
