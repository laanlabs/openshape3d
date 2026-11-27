//
//  DismissibleSheet.swift
//  openshape3d
//
//  `.sheet` that also closes on the Mac (#117).
//
//  On the Mac (Catalyst, macOS 26.2) SwiftUI does not take a sheet down when
//  all three of these hold:
//
//    * the sheet's content has a toolbar with a button in it (Done, Cancel);
//    * the sheet is attached to the page a `NavigationStack` is showing;
//    * that stack has a `navigationDestination` (ours does: the gallery opens
//      a design through one).
//
//  The button takes the click and its action runs, `isPresented` turns
//  false, and the sheet stays up; only Esc closed it, because Esc is UIKit's
//  own dismissal. A ten-line screen reproduces it (2026-11-26), so it is the
//  system's fault, not something in these views. iPhone and iPad are not
//  affected.
//
//  So on the Mac these modifiers watch the binding, and when it turns false
//  and the sheet is still up a moment later, they dismiss it through UIKit.
//  Where SwiftUI did its job the sheet is already on its way out and nothing
//  more happens. Everywhere else they are plain `.sheet`. A
//  `.fullScreenCover` is not affected and needs no wrapper.
//
//  **Use these, not `.sheet`, for anything presented from the gallery or the
//  editor.** `DismissibleSheetSourceTests` fails the build's tests when a
//  bare `.sheet(` appears in the app.
//

import SwiftUI

extension View {

    func dismissibleSheet<Content: View>(isPresented: Binding<Bool>, onDismiss: (() -> Void)? = nil,
                                         @ViewBuilder content: @escaping () -> Content) -> some View {
        #if targetEnvironment(macCatalyst)
        modifier(MacDismissibleSheet(isPresented: isPresented, onDismiss: onDismiss, sheet: content))
        #else
        sheet(isPresented: isPresented, onDismiss: onDismiss, content: content)
        #endif
    }

    func dismissibleSheet<Item: Identifiable, Content: View>(item: Binding<Item?>, onDismiss: (() -> Void)? = nil,
                                                             @ViewBuilder content: @escaping (Item) -> Content) -> some View {
        #if targetEnvironment(macCatalyst)
        modifier(MacDismissibleItemSheet(item: item, onDismiss: onDismiss, sheet: content))
        #else
        sheet(item: item, onDismiss: onDismiss, content: content)
        #endif
    }
}

#if targetEnvironment(macCatalyst)

private struct MacDismissibleSheet<Sheet: View>: ViewModifier {
    @Binding var isPresented: Bool
    let onDismiss: (() -> Void)?
    let sheet: () -> Sheet
    @State private var anchor = MacSheetAnchor.Box()

    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $isPresented, onDismiss: onDismiss) {
                sheet().background(MacSheetAnchor(box: anchor))
            }
            .onChange(of: isPresented) { _, shown in
                if !shown { anchor.closeIfStillUp() }
            }
    }
}

private struct MacDismissibleItemSheet<Item: Identifiable, Sheet: View>: ViewModifier {
    @Binding var item: Item?
    let onDismiss: (() -> Void)?
    let sheet: (Item) -> Sheet
    @State private var anchor = MacSheetAnchor.Box()

    func body(content: Content) -> some View {
        content
            .sheet(item: $item, onDismiss: onDismiss) { value in
                sheet(value).background(MacSheetAnchor(box: anchor))
            }
            .onChange(of: item == nil) { _, gone in
                if gone { anchor.closeIfStillUp() }
            }
    }
}

/// An invisible view inside the sheet, so the sheet's own view controller can
/// be found from the outside.
private struct MacSheetAnchor: UIViewRepresentable {

    final class Box {
        weak var view: UIView?

        /// Dismiss the sheet this anchor sits in, unless it is already going.
        /// One turn of the run loop later: where SwiftUI dismisses the sheet
        /// itself it has started by then.
        func closeIfStillUp() {
            DispatchQueue.main.async { [weak self] in
                guard let presented = self?.view?.presentedController,
                      !presented.isBeingDismissed,
                      let presenter = presented.presentingViewController else { return }
                presenter.dismiss(animated: true)
            }
        }
    }

    let box: Box

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.isUserInteractionEnabled = false
        view.isHidden = true
        box.view = view
        return view
    }

    func updateUIView(_ view: UIView, context: Context) { box.view = view }
}

private extension UIView {
    /// The presented view controller this view is inside: the sheet itself.
    var presentedController: UIViewController? {
        var responder: UIResponder? = self
        while let next = responder, !(next is UIViewController) { responder = next.next }
        var controller = responder as? UIViewController
        while let current = controller {
            if let presenter = current.presentingViewController, presenter.presentedViewController === current {
                return current
            }
            controller = current.parent
        }
        return nil
    }
}

#endif
