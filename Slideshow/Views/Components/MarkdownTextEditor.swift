import SwiftUI

/// NSTextView wrapper that exposes cursor position for live preview tracking.
/// Replaces SwiftUI's TextEditor which doesn't provide selectedRange access.
struct MarkdownTextEditor: NSViewRepresentable {
    @Binding var text: String
    var onCursorPositionChange: (Int) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        guard let textView = scrollView.documentView as? NSTextView else {
            return scrollView
        }

        textView.font = .monospacedSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
        textView.isEditable = true
        textView.isSelectable = true
        textView.allowsUndo = true
        textView.isRichText = false
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.usesFindBar = true
        textView.isIncrementalSearchingEnabled = true

        // Fill width, wrap text
        textView.isHorizontallyResizable = false
        textView.isVerticallyResizable = true
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.containerSize = NSSize(
            width: 0, // will track text view width
            height: CGFloat.greatestFiniteMagnitude
        )

        textView.delegate = context.coordinator
        textView.string = text

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }

        // Update callbacks to capture current bindings
        context.coordinator.parent = self

        // Only sync text when it genuinely differs (prevents cursor jumps)
        guard textView.string != text else { return }
        context.coordinator.isUpdating = true
        let selectedRanges = textView.selectedRanges
        textView.string = text
        textView.selectedRanges = selectedRanges
        context.coordinator.isUpdating = false
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: MarkdownTextEditor
        var isUpdating = false

        init(parent: MarkdownTextEditor) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            guard !isUpdating,
                  let textView = notification.object as? NSTextView else { return }
            parent.text = textView.string
        }

        func textViewDidChangeSelection(_ notification: Notification) {
            guard !isUpdating,
                  let textView = notification.object as? NSTextView else { return }
            let position = textView.selectedRange().location
            parent.onCursorPositionChange(position)
        }
    }
}
