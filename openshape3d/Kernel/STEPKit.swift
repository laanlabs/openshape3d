//
//  STEPKit.swift
//  openshape3d
//
//  STEP AP214 interchange (spec §12.1 / §12.2), the document-level layer on
//  top of `OCCTKernel.writeSTEP` / `readSTEP`.
//
//  STEP is the odd one out among our formats. STL/OBJ/3MF/GLB export
//  TRIANGLES — a cylinder leaves as a many-sided prism and can never come
//  back round. STEP carries the EXACT B-rep, so an analytic cylinder is still
//  a cylinder in the CAD tool that opens it, and a STEP file we import stays
//  analytic here: its solids become `Body.brep`, which is what lets fillet,
//  shell and boolean run on the OCCT path afterwards.
//
//  That exactness is also the one limit worth stating plainly: a body with no
//  `brep` (an imported STL, anything the mesh path built) has no analytic
//  geometry to write, so it is SKIPPED rather than silently triangulated into
//  a file whose whole point is that it is not triangles. Callers surface the
//  skipped names.
//
//  Units: our model unit is mm and OCCT reads/writes STEP in mm by default,
//  so no scaling happens on either side.
//

import Foundation

/// The exact-geometry interchange formats: STEP AP214 and IGES 5.3. Both
/// carry the analytic B-rep, so everything below applies to either.
nonisolated enum ExchangeFormat: String, Sendable {
    case step, iges

    var title: String { self == .step ? "STEP" : "IGES" }
    var fileExtension: String { self == .step ? "step" : "igs" }
}

/// What a STEP or IGES read found, beyond the shapes: how many solids the file
/// declared, how many were stitched closed from loose faces, how many open
/// sheets were kept, how many loose faces there were, and how many shapes
/// would not heal and were left out. A file that only ever held declared
/// solids reads as all zeros but `solids`.
nonisolated struct STEPReadSummary: Sendable, Equatable {
    var solids = 0
    var sewnSolids = 0
    var openShells = 0
    var freeFaces = 0
    var dropped = 0

    /// Wording for the import notice; empty when there is nothing to say.
    var notice: String {
        var notes: [String] = []
        if sewnSolids > 0 {
            notes.append("Stitched \(freeFaces) loose face\(freeFaces == 1 ? "" : "s") into "
                         + "\(sewnSolids) solid\(sewnSolids == 1 ? "" : "s") the file had not declared.")
        }
        if openShells > 0 {
            notes.append("\(openShells) open surface\(openShells == 1 ? "" : "s") imported as "
                         + "\(openShells == 1 ? "a sheet" : "sheets"), not \(openShells == 1 ? "a solid" : "solids") — "
                         + "booleans and STEP export need closed solids.")
        }
        if dropped > 0 {
            notes.append("\(dropped) shape\(dropped == 1 ? "" : "s") could not be healed and "
                         + "\(dropped == 1 ? "was" : "were") left out.")
        }
        return notes.joined(separator: " ")
    }
}

nonisolated enum STEPKit {

    /// What `export(bodies:)` managed to do. `skipped` names the mesh-only
    /// bodies left out, in every case, so the UI can say which ones.
    enum ExportOutcome: Equatable {
        /// At least one solid was written. `skipped` may still be non-empty —
        /// a partial export is a success with a caveat, not a failure.
        case success(Data, skipped: [String])
        /// There were bodies, but not one of them carried a B-rep.
        case nothingAnalytic(skipped: [String])
        /// OCCT refused the transfer, or the file could not be read back.
        case failed
    }

    /// Write every analytic body to a STEP file and hand back its bytes.
    ///
    /// Each body's `transform` is baked in first: a `brep` lives in the same
    /// body-local space as its render mesh, and the flat STEP we write has no
    /// per-solid placement to carry it, so a body that was moved must be
    /// written where the user actually sees it.
    static func export(bodies: [Body], format: ExchangeFormat = .step) -> ExportOutcome {
        var solids: [BRepHandle] = []
        var skipped: [String] = []
        for body in bodies {
            guard let brep = body.brep,
                  let placed = OCCTKernel.transformed(brep, by: body.transform) else {
                skipped.append(body.name)
                continue
            }
            solids.append(placed)
        }
        guard !solids.isEmpty else { return .nothingAnalytic(skipped: skipped) }

        // OCCT writes to a path, so stage a temp file and read it back.
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("os3d-\(format.rawValue)-\(UUID().uuidString)")
            .appendingPathExtension(format.fileExtension)
        defer { try? FileManager.default.removeItem(at: url) }
        let written = format == .step ? OCCTKernel.writeSTEP(solids, to: url) : OCCTKernel.writeIGES(solids, to: url)
        guard written,
              let data = try? Data(contentsOf: url) else { return .failed }
        return .success(data, skipped: skipped)
    }

    /// Solids in a STEP payload. Empty when the bytes are not a readable STEP
    /// file or carry no solid — the caller reports that as one recoverable
    /// import error either way, since neither gives us anything to place.
    static func solids(from data: Data, format: ExchangeFormat = .step) -> [BRepHandle] {
        read(from: data, format: format).solids
    }

    /// Everything importable in a STEP or IGES payload — declared solids,
    /// solids stitched closed from loose faces, and open sheets — with the
    /// summary that says which was which, for the import notice.
    static func read(from data: Data, format: ExchangeFormat = .step) -> (solids: [BRepHandle], summary: STEPReadSummary) {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("os3d-\(format.rawValue)-in-\(UUID().uuidString)")
            .appendingPathExtension(format.fileExtension)
        defer { try? FileManager.default.removeItem(at: url) }
        guard (try? data.write(to: url)) != nil else { return ([], STEPReadSummary()) }
        let read = format == .step
            ? OCCTKernel.readSTEPWithSummary(from: url)
            : OCCTKernel.readIGESWithSummary(from: url)
        return (solids: read.handles, summary: read.summary)
    }

    /// Turn one imported solid into a body. Identity transform with the solid
    /// left where the file put it, matching how the extrude/primitive paths
    /// build B-rep bodies. Nil when the solid will not tessellate — a STEP
    /// file can hold a shape OCCT reads but cannot mesh, and half a body is
    /// worse than none.
    static func body(from handle: BRepHandle, name: String, revision: UInt64) -> Body? {
        var body = Body(
            id: BodyID(), name: name, transform: .identity, primitive: nil,
            render: RenderMesh(positions: [], normals: [], indices: []),
            revision: revision)
        // A part too big to mesh at render quality in time comes in coarser
        // rather than not at all.
        guard body.adoptBRep(handle) || body.adoptBRep(handle, coarse: true) else { return nil }
        return body
    }
}
