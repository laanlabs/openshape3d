import CoreGraphics

/// Screen-space annotation only: never changes the circle or its dimension.
struct SketchDiameterDimensionLayout {
    var start: CGPoint
    var end: CGPoint
    var tail: CGPoint
    var anchor: CGPoint
    var rotation: Double
    var targetSize: CGSize

    static func make(start: CGPoint, end: CGPoint, anchor: CGPoint,
                     clearance: CGFloat, available: CGRect,
                     textWidth: CGFloat, allowVertical: Bool = true) -> Self? {
        let dx = end.x - start.x, dy = end.y - start.y
        let length = hypot(dx, dy)
        guard length > 1 else { return nil }
        var rotation = atan2(Double(dy), Double(dx))
        if rotation > .pi / 2 { rotation -= .pi }
        if rotation < -.pi / 2 { rotation += .pi }
        let ordinary = CGPoint(x: anchor.x + CGFloat(sin(rotation)) * clearance,
                               y: anchor.y - CGFloat(cos(rotation)) * clearance)
        let target = CGRect(x: ordinary.x - max(44, textWidth) / 2,
                            y: ordinary.y - 22,
                            width: max(44, textWidth), height: 44)
        if !allowVertical || available.contains(target) {
            return Self(start: start, end: end, tail: end,
                        anchor: ordinary, rotation: rotation,
                        targetSize: CGSize(width: max(44, textWidth), height: 44))
        }
        // Near side chrome, use the sampled native outside vertical leader.
        // Put the text on the inward side and choose the roomier vertical end.
        let center = CGPoint(x: (start.x + end.x) / 2, y: (start.y + end.y) / 2)
        let radius = length / 2
        let upward = center.y - available.minY >= available.maxY - center.y
        let sign: CGFloat = upward ? -1 : 1
        let near = CGPoint(x: center.x, y: center.y + sign * radius)
        let far = CGPoint(x: center.x, y: center.y - sign * radius)
        let room = upward ? near.y - available.minY : available.maxY - near.y
        let extensionLength = max(0, min(220, room))
        let tail = CGPoint(x: near.x, y: near.y + sign * extensionLength)
        func fit(_ value: CGFloat, _ low: CGFloat, _ high: CGFloat) -> CGFloat {
            high >= low ? min(max(value, low), high) : (low + high) / 2
        }
        let inward: CGFloat = center.x > available.midX ? -1 : 1
        let x = fit(center.x + inward * 24, available.minX + 22, available.maxX - 22)
        let halfText = max(44, textWidth) / 2
        let y = fit(near.y + sign * extensionLength * 0.7,
                    available.minY + halfText, available.maxY - halfText)
        return Self(start: far, end: near, tail: tail,
                    anchor: CGPoint(x: x, y: y), rotation: .pi / 2,
                    targetSize: CGSize(width: 44, height: max(44, textWidth)))
    }
}
