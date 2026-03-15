import SwiftUI

/// Captures the hosting `NSWindow` via an `NSViewRepresentable` background view.
/// Prefer this over `NSApp.keyWindow` — it returns the specific window hosting the view,
/// which is reliable in multi-window apps.
struct WindowAccessor: NSViewRepresentable {
    @Binding var window: NSWindow?

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            self.window = view.window
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            self.window = nsView.window
        }
    }
}
