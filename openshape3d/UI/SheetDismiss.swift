//
//  SheetDismiss.swift
//  openshape3d
//
//  #117: on the Mac (Catalyst) a sheet's own buttons could not close it.
//  The button's action runs and calls SwiftUI's `dismiss()`, but the sheet
//  stays up; only Esc (UIKit's own dismissal) closes it. Setting the
//  presenter's `isPresented` state to false does not close it either, while
//  UIKit's `dismiss(animated:)` on the presenting controller does. Seen with
//  and without `presentationDetents`, on iPadOS it works.
//
//  `SheetDismiss` is a drop-in for `@Environment(\.dismiss)`:
//
//      @Environment(\.dismiss) private var swiftUIDismiss
//      private var dismiss: SheetDismiss { SheetDismiss(swiftUIDismiss) }
//
//  It calls SwiftUI's dismiss first. On the Mac only, it remembers the sheet
//  that was on top and, if that same controller is still presented on the
//  next runloop turn, dismisses it through UIKit. When SwiftUI's dismiss works
//  the fallback finds nothing to do, so it never closes a different sheet.
//  Alerts shown over the sheet (e.g. "Report sent" ▸ OK) are skipped, so the
//  sheet under them is the one closed. iPhone and iPad run SwiftUI's dismiss
//  unchanged.
//
import SwiftUI
import UIKit

struct SheetDismiss {
    let swiftUI: DismissAction

    init(_ swiftUI: DismissAction) { self.swiftUI = swiftUI }

    @MainActor
    func callAsFunction() {
        #if targetEnvironment(macCatalyst)
        let sheet = Self.topSheet()
        swiftUI()
        guard let sheet else { return }
        DispatchQueue.main.async {
            guard let presenter = sheet.presentingViewController, !sheet.isBeingDismissed else { return }
            presenter.dismiss(animated: true)
        }
        #else
        swiftUI()
        #endif
    }

    #if targetEnvironment(macCatalyst)
    /// The topmost presented controller that is a sheet: not an alert, not
    /// already on its way out.
    @MainActor
    private static func topSheet() -> UIViewController? {
        let windows = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
        guard let window = windows.first(where: \.isKeyWindow) ?? windows.first,
              var top = window.rootViewController?.presentedViewController
        else { return nil }
        while let next = top.presentedViewController,
              !(next is UIAlertController), !next.isBeingDismissed {
            top = next
        }
        return top is UIAlertController ? nil : top
    }
    #endif
}
