import Foundation
import simd

nonisolated enum RectangleType: String, CaseIterable, Sendable {
    case diagonal, center, threePoint
    var title: String {
        switch self {
        case .diagonal: "Diagonal"
        case .center: "Center"
        case .threePoint: "Three-Point"
        }
    }
}

/// Pure construction math. Rotated rectangles use four ordinary constrained
/// lines, so existing dimensions, trim, projection, persistence and profiles work.
nonisolated enum RectangleConstruction {
    static func axisAligned(from anchor: SIMD2<Double>, to corner: SIMD2<Double>,
                            centered: Bool, id: UUID = UUID()) -> SketchEntity? {
        let other = centered ? 2 * anchor - corner : anchor
        guard abs(corner.x - other.x) > 1e-3, abs(corner.y - other.y) > 1e-3 else { return nil }
        return .rect(id: id, min: simd_min(other, corner), max: simd_max(other, corner))
    }

    static func threePoint(a: SIMD2<Double>, b: SIMD2<Double>, heightPoint: SIMD2<Double>,
                           ids: [UUID]) -> [SketchEntity] {
        guard ids.count == 4 else { return [] }
        let base = b - a, length = simd_length(base)
        guard length > 1e-3 else { return [] }
        let normal = SIMD2(-base.y, base.x) / length
        let height = simd_dot(heightPoint - b, normal)
        guard abs(height) > 1e-3 else { return [] }
        let corners = [a, b, b + normal * height, a + normal * height]
        return (0..<4).map { .line(id: ids[$0], a: corners[$0], b: corners[($0 + 1) % 4]) }
    }

    /// Recognize four selected ordinary lines as one closed rectangular loop.
    /// This recovers an ordered loop and its adjacent dimension edges without storing a second
    /// shape representation or relying on UUID/order/orientation conventions.
    static func dimensionEdges(in entities: [SketchEntity]) -> [UUID]? {
        guard entities.count == 4 else { return nil }
        var lines: [(id: UUID, a: SIMD2<Double>, b: SIMD2<Double>)] = []
        for entity in entities {
            guard case let .line(id, a, b) = entity else { return nil }
            lines.append((id, a, b))
        }
        let tolerance = 1e-5
        let first = lines.removeFirst()
        var loop = [first]
        while !lines.isEmpty {
            let end = loop.last!.b
            guard let index = lines.firstIndex(where: {
                simd_distance($0.a, end) < tolerance || simd_distance($0.b, end) < tolerance
            }) else { return nil }
            let next = lines.remove(at: index)
            loop.append(simd_distance(next.a, end) < tolerance ? next : (next.id, next.b, next.a))
        }
        guard simd_distance(loop.last!.b, first.a) < tolerance else { return nil }
        let vectors = loop.map { $0.b - $0.a }
        guard vectors.allSatisfy({ simd_length($0) > 1e-3 }) else { return nil }
        for i in 0..<4 {
            guard abs(simd_dot(simd_normalize(vectors[i]),
                               simd_normalize(vectors[(i + 1) % 4]))) < tolerance else { return nil }
        }
        return loop.map(\.id)
    }

    static func constraints(for edges: [SketchEntity]) -> [SketchConstraint] {
        guard edges.count == 4 else { return [] }
        func whole(_ i: Int) -> ConstraintRef { .init(entityID: edges[i].id, role: .whole) }
        var result = [
            SketchConstraint(kind: .parallel, refs: [whole(0), whole(2)]),
            SketchConstraint(kind: .parallel, refs: [whole(1), whole(3)]),
            SketchConstraint(kind: .perpendicular, refs: [whole(0), whole(1)])
        ]
        for i in 0..<4 {
            result.append(SketchConstraint(kind: .coincident, refs: [
                .init(entityID: edges[i].id, role: .endpointB),
                .init(entityID: edges[(i + 1) % 4].id, role: .endpointA)]))
        }
        return result
    }
}
