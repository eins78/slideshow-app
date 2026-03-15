import SwiftUI
import SlideshowKit

/// Renders the source field with primary + muted line styling.
struct SourceTextView: View {
    let section: SlideSection

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            if let primary = section.primarySource {
                Text(primary)
                    .font(.callout)
                    .foregroundStyle(.primary)
            }
            ForEach(section.secondarySourceLines, id: \.self) { line in
                Text(line)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
    }
}
