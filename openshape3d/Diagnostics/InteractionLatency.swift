//
//  InteractionLatency.swift
//  openshape3d
//
//  Off by default; nothing below runs until it is switched on (launch with
//  OS3D_DIAGNOSTICS=1, or POST /v1/diagnostics/latency {"enabled": true}).
//  Then it feeds `InteractionLatencyLog` from four places:
//  - a passive gesture recognizer on every window (never recognizes, never
//    cancels or delays a touch) for presses, drags, releases and keys;
//  - a main run-loop observer that runs last before the loop sleeps, i.e.
//    after Core Animation has committed what the input changed;
//  - `Renderer.draw(in:)`, which reports each viewport frame it starts and
//    the drawable's `presentedTime`;
//  - a display link: a callback that arrives late means the main thread was
//    busy (a hitch the person feels as a stutter or a frozen screen).
//

import Foundation
import QuartzCore
import Metal
import UIKit

final class InteractionLatency {
    static let shared = InteractionLatency()

    /// Read by the renderer on every frame; false costs one load.
    private(set) static var isEnabled = false

    private(set) var log = InteractionLatencyLog()
    private var observer: CFRunLoopObserver?
    private var link: CADisplayLink?
    private var lastLinkTime: CFTimeInterval = 0
    private var probes: [ObjectIdentifier: InputProbeRecognizer] = [:]

    /// The launch switch, checked once when the viewport attaches.
    func enableFromEnvironmentIfAsked() {
        if !Self.isEnabled, ProcessInfo.processInfo.environment["OS3D_DIAGNOSTICS"] == "1" { setEnabled(true) }
    }

    func setEnabled(_ on: Bool) {
        guard on != Self.isEnabled else { return }
        Self.isEnabled = on
        if on {
            log.reset(at: CACurrentMediaTime())
            installEverywhere()
            let obs = CFRunLoopObserverCreateWithHandler(nil, CFRunLoopActivity.beforeWaiting.rawValue, true, CFIndex.max) { _, _ in
                MainActor.assumeIsolated { InteractionLatency.shared.log.mainThreadIdle(at: CACurrentMediaTime()) }
            }
            CFRunLoopAddObserver(CFRunLoopGetMain(), obs, .commonModes)
            observer = obs
            let l = CADisplayLink(target: self, selector: #selector(tick(_:)))
            l.add(to: .main, forMode: .common)
            link = l; lastLinkTime = 0
        } else {
            if let observer { CFRunLoopRemoveObserver(CFRunLoopGetMain(), observer, .commonModes) }
            observer = nil
            link?.invalidate(); link = nil
            for probe in probes.values { probe.view?.removeGestureRecognizer(probe) }
            probes.removeAll()
        }
    }

    func reset() { log.reset(at: CACurrentMediaTime()) }

    /// Puts the probe on every window of every connected scene; called on
    /// enable and whenever a viewport attaches (a new window may exist).
    func installEverywhere() {
        guard Self.isEnabled else { return }
        for case let scene as UIWindowScene in UIApplication.shared.connectedScenes {
            for window in scene.windows where probes[ObjectIdentifier(window)] == nil {
                let probe = InputProbeRecognizer()
                window.addGestureRecognizer(probe)
                probes[ObjectIdentifier(window)] = probe
            }
        }
    }

    // MARK: - Feeds

    fileprivate func record(_ phase: InteractionLatencyLog.Phase, at t: TimeInterval, location: CGPoint) {
        log.input(phase, at: t, x: Double(location.x), y: Double(location.y))
    }

    /// Called by the renderer when it starts a frame; pass the drawable it
    /// will present so its on-screen time is recorded.
    func frameStarted(drawable: MTLDrawable?) {
        let frame = log.frameStarted(at: CACurrentMediaTime())
        #if targetEnvironment(simulator)
        _ = (frame, drawable)   // the simulator has no presented handler: "handled" only
        #else
        drawable?.addPresentedHandler { d in
            let t = d.presentedTime
            DispatchQueue.main.async { InteractionLatency.shared.log.framePresented(frame, at: t) }
        }
        #endif
    }

    @objc private func tick(_ link: CADisplayLink) {
        let now = link.timestamp
        if lastLinkTime > 0 {
            let expected = max(link.duration, 1.0 / 120)
            let gap = now - lastLinkTime
            if gap > expected * 2.5 { log.hitch(at: now, ms: (gap - expected) * 1000) }
        }
        lastLinkTime = now
    }

    // MARK: - Report

    func report(events: Int) -> [String: Any] {
        let now = CACurrentMediaTime()
        func ms(_ s: InteractionLatencyLog.Stats?) -> Any {
            guard let s else { return NSNull() }
            return ["n": s.count, "p50": round1(s.p50), "p95": round1(s.p95), "max": round1(s.max)]
        }
        var phases: [String: Any] = [:]
        for p in InteractionLatencyLog.Phase.allCases {
            let n = log.inputs.filter { $0.phase == p }.count
            guard n > 0 else { continue }
            phases[p.rawValue] = ["inputs": n,
                                  "handledMS": ms(InteractionLatencyLog.stats(log.handledMS(p))),
                                  "presentedMS": ms(InteractionLatencyLog.stats(log.presentedMS(p)))]
        }
        let hitchMS = log.hitches.map(\.ms)
        let recent = log.inputs.suffix(max(0, events)).map { i -> [String: Any] in
            var e: [String: Any] = ["tMS": round1((i.t - log.started) * 1000), "phase": i.phase.rawValue,
                                    "x": Int(i.x), "y": Int(i.y)]
            e["handledMS"] = i.handled.map { round1(($0 - i.t) * 1000) } ?? NSNull()
            e["presentedMS"] = i.presented.map { round1(($0 - i.t) * 1000) } ?? NSNull()
            return e
        }
        return [
            "enabled": Self.isEnabled,
            "recordingSeconds": round1(now - log.started),
            "framesDrawn": log.framesDrawn, "framesPresented": log.framesPresented,
            "phases": phases,
            "gapBetweenActionsMS": ms(InteractionLatencyLog.stats(log.gapsBetweenActionsMS())),
            "hitches": ["count": hitchMS.count, "totalMS": round1(hitchMS.reduce(0, +)), "worst": ms(InteractionLatencyLog.stats(hitchMS)),
                        "recent": log.hitches.suffix(200).map { ["tMS": round1(($0.t - log.started) * 1000), "ms": round1($0.ms)] }],
            "events": recent,
        ]
    }

    private func round1(_ v: Double) -> Double { (v * 10).rounded() / 10 }
}

/// Watches touches, clicks and keys on its window without taking part:
/// it never leaves `.possible` while a touch is down, recognizes alongside
/// everything, and cancels or delays nothing.
private final class InputProbeRecognizer: UIGestureRecognizer, UIGestureRecognizerDelegate {
    init() {
        super.init(target: nil, action: nil)
        cancelsTouchesInView = false
        delaysTouchesBegan = false
        delaysTouchesEnded = false
        delegate = self
    }

    private func note(_ phase: InteractionLatencyLog.Phase, _ touches: Set<UITouch>, _ event: UIEvent) {
        guard let touch = touches.first else { return }
        InteractionLatency.shared.record(phase, at: event.timestamp, location: touch.location(in: view))
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) { note(.press, touches, event) }
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) { note(.drag, touches, event) }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        note(.release, touches, event)
        if event.allTouches?.allSatisfy({ $0.phase == .ended || $0.phase == .cancelled }) ?? true { state = .failed }
    }
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) { state = .failed }
    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent) {
        InteractionLatency.shared.record(.key, at: event.timestamp, location: .zero)
        super.pressesBegan(presses, with: event)
    }

    func gestureRecognizer(_ g: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool { true }
}
