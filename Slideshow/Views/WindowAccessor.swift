import SwiftUI

/// Captures the hosting `NSWindow` via `viewDidMoveToWindow()` override.
/// Prefer this over `NSApp.keyWindow` — it returns the specific window hosting the view,
/// which is reliable in multi-window apps. Uses a subclassed NSView to fire reliably
/// when the view is inserted into the window hierarchy.
struct WindowAccessor: NSViewRepresentable {
    @Binding var window: NSWindow?

    final class WindowTrackingView: NSView {
        var onWindowChange: ((NSWindow?) -> Void)?

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            onWindowChange?(window)
        }
    }

    func makeNSView(context: Context) -> WindowTrackingView {
        let view = WindowTrackingView()
        view.onWindowChange = { [self] newWindow in
            if self.window !== newWindow {
                self.window = newWindow
            }
        }
        return view
    }

    func updateNSView(_ nsView: WindowTrackingView, context: Context) {}
}
