//
//  ProfileDetector.swift
//  openshape3d
//
//  Finds closed profiles in a sketch: circles/rects/ellipses/polygons directly,
//  and simple closed loops walked from line segments and arc chains (degree-2
//  nodes only in v1 — branching arrangements are a v2 problem). Nested profiles
//  are reported so the caller can treat them as holes.
//

import Foundation
import simd

nonisolated struct Profile: Identifiable {
    enum Kind {
        case polygonal
        case circle(center: SIMD2<Double>, radius: Double)
        /// `radiusX`/`radiusY` are the semi-axes BEFORE `rotation` is applied,
        /// matching `SketchEntity.ellipsePoints` — which of them is the major
        /// axis is not fixed, so a consumer must not assume `radiusX >= radiusY`.
        case ellipse(center: SIMD2<Double>, radiusX: Double, radiusY: Double,
                     rotation: Double)
    }

    /// One boundary edge, for callers that can use an EXACT curve.
    ///
    /// `loop` is the tessellated truth every mesh-side consumer reads, and it
    /// stays that way — area, centroid, `contains` and the face signatures all
    /// keep working untouched. This is a side-channel the B-rep path consults
    /// instead, which is why a slot could become analytic without the sketch →
    /// profile → kernel chain changing representation.
    ///
    /// `mid` present = a circular arc THROUGH that point; absent = a straight
    /// line. Three points on a circle determine it uniquely and say which way
    /// round the arc goes, so no centre, radius, angle pair or winding flag is
    /// carried here — those are exactly the things that get sign-flipped on a
    /// reversed traversal.
    struct Segment: Equatable {
        var start: SIMD2<Double>
        var end: SIMD2<Double>
        var mid: SIMD2<Double>?
        /// A spline run (docs/SPLINE_PROFILE_DESIGN.md): the centripetal
        /// Catmull–Rom control points from `start` to `end` in traversal
        /// order, for which the kernel builds ONE B-spline edge — the same
        /// curve `SketchEntity.splinePoints` draws. `closed` marks a closed
        /// spline (the curve returns to its first point; `start == end`).
        /// Nil for lines and arcs.
        var controlPoints: [SIMD2<Double>]? = nil
        var closed: Bool = false

        init(start: SIMD2<Double>, end: SIMD2<Double>, mid: SIMD2<Double>? = nil,
             controlPoints: [SIMD2<Double>]? = nil, closed: Bool = false) {
            self.start = start
            self.end = end
            self.mid = mid
            self.controlPoints = controlPoints
            self.closed = closed
        }
    }

    let id = UUID()
    /// Closed CCW polygon in plane-local coordinates (circles tessellated).
    var loop: [SIMD2<Double>]
    var kind: Kind
    var sourceEntityIDs: Set<UUID>
    /// Exact boundary, in `loop` order — EMPTY when there is nothing to gain.
    ///
    /// Only populated for loops that actually contain an arc. A polygon is
    /// already exact as a polyline (OCCT builds the same wire either way), so
    /// filling this in for one would add a second description of identical
    /// geometry and a second thing to keep in step.
    var segments: [Segment] = []

    /// Which sketch entity owns each boundary edge, in order — the identity
    /// `sourceEntityIDs` throws away by being a set. `edgeEntityIDs` is
    /// parallel to `loop`'s edges (edge i spans `loop[i] → loop[i+1]`);
    /// `segmentEntityIDs` is parallel to `segments`. Both EMPTY for the
    /// single-entity profiles (circle/rect/ellipse/polygon), where the one
    /// entity in `sourceEntityIDs` owns everything. Element naming reads
    /// these through `boundaryIdentity(wireEdge:wireEdgeCount:)` — nothing
    /// else should, because which array applies depends on how the kernel
    /// built the wire.
    var edgeEntityIDs: [UUID] = []
    var segmentEntityIDs: [UUID] = []

    /// The sketch entity that owns wire edge `j` (1-based, construction
    /// order) of this profile's boundary, plus how many earlier wire edges
    /// the same entity owns (the `occurrence` disambiguator — derived from
    /// the profile arrays alone, so a dropped history row can't shift it).
    ///
    /// `wireEdgeCount` is how many wall edges the kernel actually built for
    /// this loop; it selects WHICH boundary description the wire came from —
    /// one edge per exact segment, one per polyline point, or one for a
    /// conic. Nil when no description matches: refusing to guess is the
    /// contract, because a wrong identity is worse than a missing one.
    func boundaryIdentity(wireEdge j: Int, wireEdgeCount: Int)
        -> (entity: UUID, occurrence: Int)? {
        guard j >= 1, j <= wireEdgeCount else { return nil }
        if sourceEntityIDs.count == 1, let only = sourceEntityIDs.first {
            return (only, j - 1)
        }
        func lookup(_ ids: [UUID]) -> (UUID, Int)? {
            guard j <= ids.count else { return nil }
            let entity = ids[j - 1]
            return (entity, ids[..<(j - 1)].count(where: { $0 == entity }))
        }
        if !segmentEntityIDs.isEmpty, wireEdgeCount == segmentEntityIDs.count {
            return lookup(segmentEntityIDs)
        }
        // The kernel splits an OPEN spline where its straight end spans meet
        // the curve (a crease may not sit inside one face — offsets refuse
        // it): three edges for four or more points, two for three. The wire
        // then has more edges than segments; expand the entity list the same
        // way so every piece still names its spline.
        if !segmentEntityIDs.isEmpty, segmentEntityIDs.count == segments.count {
            var expanded: [UUID] = []
            for (segment, entity) in zip(segments, segmentEntityIDs) {
                var pieces = 1
                if let points = segment.controlPoints, !segment.closed {
                    pieces = points.count >= 4 ? 3 : (points.count == 3 ? 2 : 1)
                }
                expanded.append(contentsOf: repeatElement(entity, count: pieces))
            }
            if expanded.count != segmentEntityIDs.count, wireEdgeCount == expanded.count {
                return lookup(expanded)
            }
        }
        if wireEdgeCount == loop.count, edgeEntityIDs.count == loop.count {
            return lookup(edgeEntityIDs)
        }
        return nil
    }

    /// Signed area (positive for CCW).
    var area: Double {
        Profile.signedArea(loop)
    }

    var centroid: SIMD2<Double> {
        guard !loop.isEmpty else { return .zero }
        return loop.reduce(SIMD2<Double>.zero, +) / Double(loop.count)
    }

    /// A point guaranteed to lie INSIDE the region, for seeding a later
    /// re-detection. The vertex average (`centroid`) is not one: on a ring,
    /// a C or an L it falls in the hole or outside the arm — building a
    /// counterbore whose annulus a rectangular cut had bitten into (practice
    /// problem 4.38, 2026-09-04), the recorded seed landed in the through
    /// hole, replay resolved the wrong region and the cut fell back to a
    /// mesh of half the body. Nudging an edge midpoint toward the interior
    /// (the loop is CCW, so the interior is on the left) always finds one.
    var interiorPoint: SIMD2<Double> {
        let c = centroid
        if contains(c) { return c }
        guard loop.count >= 3 else { return c }
        var lo = loop[0], hi = loop[0]
        for p in loop { lo = simd_min(lo, p); hi = simd_max(hi, p) }
        let step = max(simd_length(hi - lo) * 1e-3, 1e-6)
        for i in 0..<loop.count {
            let a = loop[i], b = loop[(i + 1) % loop.count]
            let d = b - a
            let len = simd_length(d)
            guard len > 1e-12 else { continue }
            let leftNormal = SIMD2(-d.y, d.x) / len
            let candidate = (a + b) / 2 + leftNormal * step
            if contains(candidate) { return candidate }
        }
        return c
    }

    func contains(_ p: SIMD2<Double>) -> Bool {
        // Ray casting.
        var inside = false
        var j = loop.count - 1
        for i in 0..<loop.count {
            let a = loop[i]
            let b = loop[j]
            if (a.y > p.y) != (b.y > p.y),
               p.x < (b.x - a.x) * (p.y - a.y) / (b.y - a.y) + a.x {
                inside.toggle()
            }
            j = i
        }
        return inside
    }

    static func signedArea(_ loop: [SIMD2<Double>]) -> Double {
        var sum = 0.0
        var j = loop.count - 1
        for i in 0..<loop.count {
            sum += (loop[j].x * loop[i].y) - (loop[i].x * loop[j].y)
            j = i
        }
        return sum / 2
    }
}

nonisolated enum ProfileDetector {
    static let circleSegments = 48
    private static let quantum: Double = 1e-6
    /// Chain endpoints closer than this are one junction (see `lineLoops`).
    static let endpointWeldTolerance: Double = 1e-3

    static func detectProfiles(in sketch: Sketch) -> [Profile] {
        var profiles: [Profile] = []
        // Construction (reference) geometry never bounds a profile (spec §3.3).
        let entities = sketch.regularEntities

        // Circles are always closed profiles.
        for entity in entities {
            if case let .circle(id, center, radius) = entity, radius > 1e-6 {
                let loop = (0..<circleSegments).map { i -> SIMD2<Double> in
                    let angle = Double(i) / Double(circleSegments) * 2 * .pi
                    return center + SIMD2(cos(angle), sin(angle)) * radius
                }
                profiles.append(Profile(
                    loop: loop, // CCW by construction
                    kind: .circle(center: center, radius: radius),
                    sourceEntityIDs: [id]
                ))
            }
        }

        // Closed splines are closed profiles too, carried as ONE exact segment
        // holding the control points, so the kernel builds a single B-spline
        // edge and the wall it sweeps is one face (docs/SPLINE_PROFILE_DESIGN.md).
        // Reversing the control points reverses the curve, so a CW spline is
        // normalised by re-sampling them reversed — loop and segment agree.
        for entity in entities {
            if case let .spline(id, points, closed) = entity, closed, points.count >= 3 {
                var control = points
                var loop = SketchEntity.splinePoints(control, closed: true)
                if Profile.signedArea(loop) < 0 {
                    control.reverse()
                    loop = SketchEntity.splinePoints(control, closed: true)
                }
                guard Profile.signedArea(loop) > 1e-9, !isSelfIntersecting(loop) else { continue }
                profiles.append(Profile(
                    loop: loop, kind: .polygonal, sourceEntityIDs: [id],
                    segments: [Profile.Segment(start: control[0], end: control[0],
                                               controlPoints: control, closed: true)],
                    segmentEntityIDs: [id]))
            }
        }

        // Rects are closed by definition; emit directly (CCW).
        for entity in entities {
            if case let .rect(id, lo, hi) = entity {
                let loop = [
                    lo, SIMD2(hi.x, lo.y), hi, SIMD2(lo.x, hi.y),
                ]
                profiles.append(Profile(loop: loop, kind: .polygonal, sourceEntityIDs: [id]))
            }
        }

        // Ellipses and polygons are closed profiles too (loops CCW by construction).
        for entity in entities {
            switch entity {
            case let .ellipse(id, center, radiusX, radiusY, rotation)
                where radiusX > 1e-6 && radiusY > 1e-6:
                let loop = SketchEntity.ellipsePoints(
                    center: center, radiusX: radiusX, radiusY: radiusY,
                    rotation: rotation, segments: circleSegments
                )
                profiles.append(Profile(
                    loop: loop,
                    kind: .ellipse(center: center, radiusX: radiusX,
                                   radiusY: radiusY, rotation: rotation),
                    sourceEntityIDs: [id]))
            case let .polygon(id, center, radius, sides, rotation)
                where radius > 1e-6 && sides >= 3:
                let loop = SketchEntity.polygonPoints(
                    center: center, radius: radius, sides: sides, rotation: rotation
                )
                profiles.append(Profile(loop: loop, kind: .polygonal, sourceEntityIDs: [id]))
            default:
                break
            }
        }

        // Walk loops from line segments and arc chains.
        profiles.append(contentsOf: lineLoops(in: sketch))
        return profiles
    }

    /// Profiles fully containing `point`, smallest area first (innermost region).
    static func profiles(at point: SIMD2<Double>, in sketch: Sketch) -> [Profile] {
        detectProfiles(in: sketch)
            .filter { $0.contains(point) }
            .sorted { abs($0.area) < abs($1.area) }
    }

    /// Profiles from `all` strictly nested inside `outer` (used as holes).
    static func holes(of outer: Profile, among all: [Profile]) -> [Profile] {
        all.filter { candidate in
            candidate.id != outer.id
                && abs(candidate.area) < abs(outer.area)
                && outer.contains(candidate.centroid)
        }
    }

    // MARK: - Loop walking over line segments

    private struct NodeKey: Hashable {
        let x, y: Int64
        init(_ p: SIMD2<Double>) {
            x = MeshQuantize.key64(p.x, quantum: ProfileDetector.quantum)
            y = MeshQuantize.key64(p.y, quantum: ProfileDetector.quantum)
        }
    }

    private static func lineLoops(in sketch: Sketch) -> [Profile] {
        // A chain is one entity exploded to a polyline. Only its two ENDPOINTS
        // enter the node graph — tessellated interior points (arcs) are never
        // junction candidates; they are spliced into the loop when walked.
        struct Chain {
            let entityID: UUID
            let points: [SIMD2<Double>]
            /// True when `points` is a TESSELLATION of a real curve, so the
            /// analytic boundary should describe it as an arc rather than as
            /// the polyline standing in for it.
            let isArc: Bool
            /// An OPEN spline's control points, in the order of `points`, so a
            /// loop can carry it as one exact segment (one B-spline edge).
            var spline: [SIMD2<Double>]? = nil
        }

        var chains: [Chain] = []
        for entity in sketch.regularEntities {
            switch entity {
            case let .line(id, a, b) where simd_length(b - a) > 1e-9:
                chains.append(Chain(entityID: id, points: [a, b], isArc: false))
            case let .arc(id, center, radius, startAngle, endAngle):
                let points = SketchEntity.arcPoints(
                    center: center, radius: radius,
                    startAngle: startAngle, endAngle: endAngle,
                    segmentsPerTurn: circleSegments
                )
                if points.count >= 2 {
                    chains.append(Chain(entityID: id, points: points, isArc: true))
                }
            case let .spline(id, points, closed) where !closed && points.count >= 2:
                // An open spline joins loops like any chain: its endpoints are
                // the junction candidates, its samples the polyline, and its
                // control points ride along for the exact edge.
                let samples = SketchEntity.splinePoints(points, closed: false)
                if samples.count >= 2, simd_length(samples.last! - samples.first!) > 1e-9 {
                    chains.append(Chain(entityID: id, points: samples, isArc: false, spline: points))
                }
            default:
                break
            }
        }
        guard chains.count >= 2 else { return [] }

        // Weld near-coincident chain ENDPOINTS before they become nodes. The
        // node key quantises to 1e-6 mm, which is exact-arithmetic territory:
        // an arc whose angles were derived from a line's rounded endpoint
        // lands 2e-5 mm away from it, and a perfectly good line/arc/line loop
        // (practice sheet 7.2's spherical cap) came back "profile unresolved".
        // Anything within a micron is the same junction; a real gap is orders
        // of magnitude larger than that.
        do {
            var representatives: [SIMD2<Double>] = []
            func weld(_ p: SIMD2<Double>) -> SIMD2<Double> {
                for r in representatives where simd_length(r - p) <= endpointWeldTolerance { return r }
                representatives.append(p)
                return p
            }
            for i in chains.indices {
                var points = chains[i].points
                points[0] = weld(points[0])
                points[points.count - 1] = weld(points[points.count - 1])
                chains[i] = Chain(entityID: chains[i].entityID, points: points,
                                  isArc: chains[i].isArc, spline: chains[i].spline)
            }
        }

        // A repeated straight stroke is still an editable entity, but it is
        // only one geometric boundary. Parallel coincident half-edges create
        // zero-area cycles and can swallow an otherwise closed face. Keep the
        // first entity as the stable boundary owner; do not mutate the sketch.
        // Only straight chains qualify: arcs/splines with the same endpoints
        // may enclose a real region and must remain distinct.
        var straightBoundaries = Set<Set<NodeKey>>()
        chains = chains.filter { chain in
            guard !chain.isArc, chain.spline == nil, chain.points.count == 2 else { return true }
            return straightBoundaries.insert(Set(chain.points.map(NodeKey.init))).inserted
        }

        // Planar FACE TRAVERSAL over half-edges.
        //
        // The previous walker followed a chain and gave up at any node whose
        // degree wasn't 2, so a single shared endpoint made every loop through
        // it undetectable — draw a divider across a rectangle, or mirror one
        // about a shared edge, and BOTH cells and the outer boundary vanished
        // at once. That is not merely "no new profile": `resolveProfile`
        // re-runs detection on every rebuild and treats nil as a hard failure,
        // so an already-built body disappeared the moment its sketch gained a
        // junction (2026-08-25 review round 3, finding R3-B).
        //
        // Face traversal handles junctions of any degree: at each arrival node
        // take the outgoing half-edge one step CLOCKWISE from the twin, which
        // traces every interior face counter-clockwise (positive area) and the
        // outer face clockwise (negative — discarded by the area test).
        struct HalfEdge {
            let chain: Int
            let forward: Bool
            let to: NodeKey
            /// Direction leaving the tail, using the polyline's own first
            /// segment so an arc sorts by its true tangent, not its chord.
            let outAngle: Double
        }

        var halfEdges: [HalfEdge] = []
        var outgoing: [NodeKey: [Int]] = [:]
        for (index, chain) in chains.enumerated() {
            let pts = chain.points
            let ka = NodeKey(pts.first!)
            let kb = NodeKey(pts.last!)
            guard ka != kb else { continue }
            let n = pts.count
            let aOut = atan2(pts[1].y - pts[0].y, pts[1].x - pts[0].x)
            let bOut = atan2(pts[n - 2].y - pts[n - 1].y, pts[n - 2].x - pts[n - 1].x)
            // Appended in pairs, so a half-edge's twin is always `index ^ 1`.
            outgoing[ka, default: []].append(halfEdges.count)
            halfEdges.append(HalfEdge(chain: index, forward: true, to: kb, outAngle: aOut))
            outgoing[kb, default: []].append(halfEdges.count)
            halfEdges.append(HalfEdge(chain: index, forward: false, to: ka, outAngle: bOut))
        }
        guard !halfEdges.isEmpty else { return [] }
        for (node, ring) in outgoing {
            outgoing[node] = ring.sorted { halfEdges[$0].outAngle < halfEdges[$1].outAngle }
        }

        var visited = Set<Int>()
        var profiles: [Profile] = []

        // Start from each half-edge in index order, so output order depends on
        // entity order alone — never on hash order.
        for start in halfEdges.indices where !visited.contains(start) {
            var cycle: [Int] = []
            var edge = start
            while !visited.contains(edge) {
                visited.insert(edge)
                cycle.append(edge)
                let twin = edge ^ 1
                guard let ring = outgoing[halfEdges[edge].to],
                      let position = ring.firstIndex(of: twin)
                else { break }
                // One step clockwise from the twin.
                edge = ring[(position + ring.count - 1) % ring.count]
                if cycle.count > halfEdges.count { break }
            }
            // A clean face returns to the half-edge it started from.
            guard edge == start, cycle.count >= 2 else { continue }

            var loop: [SIMD2<Double>] = []
            var chainIDs: [Int] = []
            var segments: [Profile.Segment] = []
            var edgeEntityIDs: [UUID] = []
            var segmentEntityIDs: [UUID] = []
            var sawCurve = false   // an arc or a spline: an exact boundary worth carrying
            var spur = false
            for index in cycle {
                let half = halfEdges[index]
                if chainIDs.contains(half.chain) { spur = true; break }
                chainIDs.append(half.chain)
                let chain = chains[half.chain]
                let pts = half.forward ? chain.points : Array(chain.points.reversed())
                loop.append(contentsOf: pts.dropLast())
                // Each appended point starts one loop edge, so the chain owns
                // the next pts.count-1 edges — identity in traversal order,
                // which the set below cannot carry.
                edgeEntityIDs.append(contentsOf: Array(
                    repeating: chain.entityID, count: max(0, pts.count - 1)))
                segmentEntityIDs.append(chain.entityID)
                // The chain occupies one contiguous run of `loop`, so its
                // exact boundary is one segment spanning the same ground.
                // An interior SAMPLE serves as the arc's third point: it is on
                // the true arc by construction, whichever way the face
                // traversal happened to walk this chain.
                if let control = chain.spline {
                    // The control points in THIS traversal's order: a reversed
                    // Catmull–Rom is the same curve walked backwards.
                    sawCurve = true
                    segments.append(Profile.Segment(
                        start: pts[0], end: pts[pts.count - 1],
                        controlPoints: half.forward ? control : control.reversed()))
                } else if chain.isArc, pts.count >= 3 {
                    sawCurve = true
                    segments.append(Profile.Segment(
                        start: pts[0], end: pts[pts.count - 1], mid: pts[pts.count / 2]))
                } else if let first = pts.first, let last = pts.last {
                    segments.append(Profile.Segment(start: first, end: last))
                }
            }
            // A dangling edge is walked out and back inside the same face,
            // producing a zero-width slit. Legal as a region, but the mesh
            // extruder wants simple polygons — skip, as the old walker did.
            guard !spur, loop.count >= 3 else { continue }

            // Interior faces come out CCW; the single outer face is CW and is
            // dropped here, which is what keeps a plain rectangle to ONE
            // profile rather than two.
            guard Profile.signedArea(loop) > 1e-9 else { continue }
            guard !isSelfIntersecting(loop) else { continue }

            profiles.append(Profile(
                loop: loop,
                kind: .polygonal,
                sourceEntityIDs: Set(chainIDs.map { chains[$0].entityID }),
                // Nothing to gain on an all-straight loop; see `segments`.
                segments: sawCurve ? segments : [],
                edgeEntityIDs: edgeEntityIDs,
                // Parallel to `segments`, so it follows the same emptiness.
                segmentEntityIDs: sawCurve ? segmentEntityIDs : []
            ))
        }
        return profiles
    }

    private static func isSelfIntersecting(_ loop: [SIMD2<Double>]) -> Bool {
        let n = loop.count
        guard n > 3 else { return false }
        for i in 0..<n {
            let a1 = loop[i]
            let a2 = loop[(i + 1) % n]
            for j in (i + 1)..<n {
                // Skip adjacent segments (shared endpoints).
                if j == i || (j + 1) % n == i || (i + 1) % n == j { continue }
                let b1 = loop[j]
                let b2 = loop[(j + 1) % n]
                if segmentsIntersect(a1, a2, b1, b2) {
                    return true
                }
            }
        }
        return false
    }

    private static func segmentsIntersect(
        _ p1: SIMD2<Double>, _ p2: SIMD2<Double>,
        _ p3: SIMD2<Double>, _ p4: SIMD2<Double>
    ) -> Bool {
        func orientation(_ a: SIMD2<Double>, _ b: SIMD2<Double>, _ c: SIMD2<Double>) -> Double {
            (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x)
        }
        let d1 = orientation(p3, p4, p1)
        let d2 = orientation(p3, p4, p2)
        let d3 = orientation(p1, p2, p3)
        let d4 = orientation(p1, p2, p4)
        return ((d1 > 0 && d2 < 0) || (d1 < 0 && d2 > 0))
            && ((d3 > 0 && d4 < 0) || (d3 < 0 && d4 > 0))
    }
}
