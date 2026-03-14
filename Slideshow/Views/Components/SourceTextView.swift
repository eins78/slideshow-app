import SwiftUI
import SlideshowKit

/// Renders the source field with primary + muted line styling.
struct SourceTextView: View {
    let sidecar: SidecarData

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            if let primary = sidecar.primarySource {
                Text(primary)
                    .font(.callout)
                    .foregroundStyle(.primary)
            }
            ForEach(sidecar.secondarySourceLines, id: \.self) { line in
                Text(line)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
    }
}
