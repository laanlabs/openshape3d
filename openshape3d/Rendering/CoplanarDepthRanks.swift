//
//  CoplanarDepthRanks.swift
//  openshape3d
//
//  #141: two bodies whose faces lie in one plane and overlap (a copy dragged
//  half across its original, parts about to be unioned) wrote the same depth
//  there, so the shared face flickered between both bodies' colours in a
//  staircase that moved with the camera.
//
//  The fix is a stable tie-break: every opaque body gets a small rank, and
//  the renderer pushes its faces back by a depth bias proportional to it, so
//  on a shared plane the lowest rank wins everywhere. Bodies that cannot
//  touch (their boxes are apart) share rank 0, which keeps the bias at a few
//  depth steps however many bodies the design has. Selected bodies rank
//  first, then the newest, so what is being worked on is what shows.
//

import Foundation
import simd

nonisolated enum CoplanarDepthRanks {

    /// A world-space bounding box.
    struct Box: Equatable, Sendable {
        var min: SIMD3<Float>
        var max: SIMD3<Float>

        /// The box of a mesh-local box placed by `matrix`.
        init(local: (min: SIMD3<Float>, max: SIMD3<Float>), transformedBy matrix: simd_float4x4) {
            var lo = SIMD3<Float>(repeating: .greatestFiniteMagnitude)
            var hi = SIMD3<Float>(repeating: -.greatestFiniteMagnitude)
            for corner in 0..<8 {
                let p = SIMD4<Float>(corner & 1 == 0 ? local.min.x : local.max.x,
                                     corner & 2 == 0 ? local.min.y : local.max.y,
                                     corner & 4 == 0 ? local.min.z : local.max.z, 1)
                let w = matrix * p
                let v = SIMD3<Float>(w.x, w.y, w.z)
                lo = simd_min(lo, v)
                hi = simd_max(hi, v)
            }
            min = lo
            max = hi
        }

        init(min: SIMD3<Float>, max: SIMD3<Float>) {
            self.min = min
            self.max = max
        }

        /// Touching counts: coplanar faces meet exactly at the boxes' sides.
        func touches(_ other: Box, slack: Float) -> Bool {
            min.x <= other.max.x + slack && other.min.x <= max.x + slack
                && min.y <= other.max.y + slack && other.min.y <= max.y + slack
                && min.z <= other.max.z + slack && other.min.z <= max.z + slack
        }
    }

    /// Highest rank handed out. More than this many mutually overlapping
    /// bodies share the last rank (and may fight among themselves) rather
    /// than push faces far enough back to hide a thin feature in front.
    static let maxRank = 6

    /// Beyond this many bodies the pairwise pass is skipped (all rank 0).
    static let bodyLimit = 1500

    /// A rank per box, in the order given (draw order: oldest first).
    /// Rank 0 is drawn as it is and wins a shared plane; each further rank
    /// sits one bias step behind. Two boxes that touch never share a rank
    /// below `maxRank`. `preferred` marks the bodies to favour (selected).
    static func ranks(boxes: [Box], preferred: [Bool] = []) -> [Int] {
        let count = boxes.count
        var ranks = [Int](repeating: 0, count: count)
        guard count > 1, count <= bodyLimit else { return ranks }

        // Winners pick first: selected bodies, then the newest.
        let order = (0..<count).sorted { a, b in
            let pa = a < preferred.count && preferred[a], pb = b < preferred.count && preferred[b]
            return pa != pb ? pa : a > b
        }
        var assigned: [Int] = []
        assigned.reserveCapacity(count)
        for i in order {
            let box = boxes[i]
            let size = simd_reduce_max(box.max - box.min)
            var taken = 0   // bit r set: a touching body already holds rank r
            for j in assigned {
                let other = boxes[j]
                let slack = 1e-4 * Swift.max(size, simd_reduce_max(other.max - other.min)) + 1e-6
                if box.touches(other, slack: slack) { taken |= 1 << ranks[j] }
            }
            var rank = 0
            while rank < maxRank, taken & (1 << rank) != 0 { rank += 1 }
            ranks[i] = rank
            assigned.append(i)
        }
        return ranks
    }
}
