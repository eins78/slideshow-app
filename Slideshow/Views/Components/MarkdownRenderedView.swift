import SwiftUI

/// Renders a markdown string as styled Text using AttributedString.
struct MarkdownRenderedView: View {
    let markdown: String

    var body: some View {
        if let attributed = try? AttributedString(markdown: markdown) {
            Text(attributed)
                .font(.body)
                .textSelection(.enabled)
        } else {
            Text(markdown)
                .font(.body)
        }
    }
}
