import SwiftUI

/// Captures the hosting `NSWindow` via `viewDidMoveToWindow()` override.
/// Uses a Coordinator to avoid stale binding capture in the NSView subclass.
struct WindowAccessor: NSViewRepresentable {
    @Binding var window: NSWindow?

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> WindowTrackingView {
        let view = WindowTrackingView()
        view.coordinator = context.coordinator
        return view
    }

    func updateNSView(_ nsView: WindowTrackingView, context: Context) {
        // Coordinator always holds the latest binding via static func update
        context.coordinator.onWindowChange = { [self] newWindow in
            if self.window !== newWindow {
                self.window = newWindow
            }
        }
    }

    final class Coordinator {
        var onWindowChange: ((NSWindow?) -> Void)?
    }

    final class WindowTrackingView: NSView {
        weak var coordinator: Coordinator?

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            coordinator?.onWindowChange?(window)
        }
    }
}
