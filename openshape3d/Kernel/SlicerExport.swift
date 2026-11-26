//
//  SlicerExport.swift
//  openshape3d
//
//  File ▸ Export to Slicer (spec §12): the design as a 3MF a slicer can
//  print straight away. The app's world is Y-up; printers are Z-up, so the
//  bodies turn a quarter turn about X, (x, y, z) → (x, −z, y), then drop
//  onto the bed — lowest point on z = 0, centred on the origin in x and y.
//  The design itself is not touched.
//

import Foundation
import simd

nonisolated enum SlicerExport {

    /// Copies of `bodies` placed for a print bed (see the file comment).
    static func placedOnBed(_ bodies: [Body]) -> [Body] {
        var upright = Transform3D()
        upright.rotation = simd_quatd(angle: .pi / 2, axis: SIMD3(1, 0, 0))
        var turned = bodies.map { body -> Body in
            var copy = body
            copy.transform = upright.composed(onto: body.transform)
            return copy
        }
        guard let bounds = worldBounds(turned) else { return turned }
        let shift = SIMD3(-(bounds.min.x + bounds.max.x) / 2,
                          -(bounds.min.y + bounds.max.y) / 2,
                          -bounds.min.z)
        for i in turned.indices { turned[i].transform.translation += shift }
        return turned
    }

    /// The 3MF a slicer opens.
    static func threeMF(bodies: [Body]) -> Data {
        ThreeMFExporter.threeMF(bodies: placedOnBed(bodies))
    }

    /// File name for the export: the design's name, made safe for a path.
    static func fileName(for designName: String) -> String {
        let cleaned = designName.map { "/\\:".contains($0) ? "-" : $0 }
        let base = String(cleaned).trimmingCharacters(in: .whitespaces)
        return (base.isEmpty ? "Design" : base) + ".3mf"
    }

    static func worldBounds(_ bodies: [Body]) -> (min: SIMD3<Double>, max: SIMD3<Double>)? {
        var lo = SIMD3<Double>(repeating: .infinity), hi = -lo
        for body in bodies {
            for p in body.render.positions {
                let w = body.transform.applying(to: SIMD3<Double>(p))
                lo = simd_min(lo, w)
                hi = simd_max(hi, w)
            }
        }
        return lo.x.isFinite ? (lo, hi) : nil
    }
}
