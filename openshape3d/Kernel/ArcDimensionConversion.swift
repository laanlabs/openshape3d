import Foundation

/// Native 360° arc edits produce a circle, not a wrapped zero-sweep arc.
nonisolated enum ArcDimensionConversion {
    nonisolated struct Result {
        let circle: SketchEntity
        let removedAngleIDs: Set<UUID>
        let updatedRadiusDimensions: [SketchDimension]
    }

    static func fullCircle(from arc: SketchEntity, dimensions: [SketchDimension]) -> Result? {
        guard case let .arc(id, center, radius, _, _) = arc else { return nil }
        let own = dimensions.filter { $0.refs.count == 1 && $0.refs[0].entityID == id }
        let radii = own.filter { $0.kind == .radius }.map { dimension in
            var diameter = dimension
            diameter.kind = .diameter
            diameter.value *= 2
            diameter.formula = dimension.formula.map { "(\($0))*2" }
            return diameter
        }
        return Result(circle: .circle(id: id, center: center, radius: radius),
                      removedAngleIDs: Set(own.filter { $0.kind == .angle }.map(\.id)),
                      updatedRadiusDimensions: radii)
    }
}
