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

    /// Recover an isolated rectangular line component after selecting one
    /// edge (including save/reload), retaining document order. Branching or
    /// larger connected components are deliberately not guessed as rectangles.
    static func dimensionEdges(containing id: UUID, in entities: [SketchEntity]) -> [UUID]? {
        let lines = entities.filter { if case .line = $0 { return true }; return false }
        guard let seed = lines.first(where: { $0.id == id }) else { return nil }
        var connected = [seed]
        var ids: Set<UUID> = [id]
        var changed = true
        func touches(_ lhs: SketchEntity, _ rhs: SketchEntity) -> Bool {
            guard case let .line(_, a, b) = lhs, case let .line(_, c, d) = rhs else { return false }
            return [simd_distance(a, c), simd_distance(a, d),
                    simd_distance(b, c), simd_distance(b, d)].min()! < 1e-5
        }
        while changed {
            changed = false
            for line in lines where !ids.contains(line.id) {
                if connected.contains(where: { touches(line, $0) }) {
                    connected.append(line); ids.insert(line.id); changed = true
                    if ids.count > 4 { return nil }
                }
            }
        }
        return dimensionEdges(in: lines.filter { ids.contains($0.id) })
    }

    /// Baseline sizing preserves the lower adjacent side in sketch coordinates,
    /// independent of construction direction. Horizontal ties keep the left side.
    /// This is a transient solve preference, never a saved fixed constraint.
    static func baselineAnchor(containing id: UUID, in entities: [SketchEntity]) -> UUID? {
        guard let loop = dimensionEdges(containing: id, in: entities),
              id == loop[0] || id == loop[2] else { return nil }
        let sides = [loop[1], loop[3]].compactMap { sideID -> (UUID, SIMD2<Double>)? in
            guard let entity = entities.first(where: { $0.id == sideID }),
                  case let .line(_, a, b) = entity else { return nil }
            return (sideID, (a + b) / 2)
        }
        return sides.min {
            abs($0.1.y - $1.1.y) > 1e-7 ? $0.1.y < $1.1.y : $0.1.x < $1.1.x
        }?.0
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
