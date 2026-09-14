//
//  MacWindowTitle.swift
//  openshape3d
//
//  On the Mac (Catalyst) the title bar mirrors whatever navigation title was
//  shown last, so a sheet's — "Settings", "Constraints", "Report a Bug" —
//  stayed in the title bar after the sheet closed (seen 2026-09-14). The
//  gallery and the editor say what the window should be called, and every
//  sheet puts that back as it disappears. No-op on iPhone and iPad.
//

import SwiftUI

enum MacWindowTitle {
    nonisolated(unsafe) private static var wanted: String?

    /// The title the window should show: the gallery's, or the open design's.
    static func want(_ title: String) {
        wanted = title
        apply(title)
    }

    /// A sheet closed: put the wanted title back.
    static func restore() {
        guard let wanted else { return }
        apply(wanted)
    }

    private static func apply(_ title: String) {
        #if targetEnvironment(macCatalyst)
        DispatchQueue.main.async {
            for case let scene as UIWindowScene in UIApplication.shared.connectedScenes {
                scene.title = title
            }
        }
        #endif
    }
}
