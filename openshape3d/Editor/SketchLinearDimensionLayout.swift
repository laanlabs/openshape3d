import Foundation
import CoreGraphics

/// Screen-space leader layout from paired native standalone line references.
/// Projection noise must not change which side an axis-aligned leader uses.
enum SketchLinearDimensionLayout {
    struct Layout {
        let start: CGPoint
        let end: CGPoint
        let anchor: CGPoint
        let rotation: Double
    }

    static func make(start: CGPoint, end: CGPoint, leaderOffset: CGFloat = 60, awayFrom interior: CGPoint? = nil) -> Layout? {
        var dx = end.x - start.x, dy = end.y - start.y
        let length = hypot(dx, dy)
        guard length > 1 else { return nil }
        let nearVertical = abs(dx) < length * 0.01
        if nearVertical ? dy < 0 : dx < 0 { dx = -dx; dy = -dy }
        var nx = -dy / length, ny = dx / length
        if let interior {
            let towardMidX = (start.x + end.x) / 2 - interior.x
            let towardMidY = (start.y + end.y) / 2 - interior.y
            if towardMidX * nx + towardMidY * ny < 0 { nx = -nx; ny = -ny }
        }
        func offset(_ point: CGPoint, by distance: CGFloat) -> CGPoint {
            CGPoint(x: point.x + nx * distance, y: point.y + ny * distance)
        }
        // Vertical text reads bottom-to-top even when projected dx has noise.
        let rotation = nearVertical ? -Double.pi / 2 : atan2(Double(dy), Double(dx))
        let midpoint = CGPoint(x: (start.x + end.x) / 2, y: (start.y + end.y) / 2)
        let leaderMidpoint = offset(midpoint, by: leaderOffset)
        let textAnchor = CGPoint(x: leaderMidpoint.x + CGFloat(sin(rotation)) * 20,
                                 y: leaderMidpoint.y - CGFloat(cos(rotation)) * 20)
        return Layout(start: offset(start, by: leaderOffset), end: offset(end, by: leaderOffset),
                      anchor: textAnchor, rotation: rotation)
    }
}
