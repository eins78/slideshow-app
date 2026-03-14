import SwiftUI

/// A horizontal divider that can be dragged to resize panels above/below.
struct DraggableDivider: View {
    @Binding var topHeight: CGFloat
    let minTopHeight: CGFloat
    let maxTopHeight: CGFloat

    var body: some View {
        Rectangle()
            .fill(Color(nsColor: .separatorColor))
            .frame(height: 1)
            .padding(.vertical, 3)
            .frame(height: 8)
            .contentShape(Rectangle())
            .onHover { hovering in
                if hovering {
                    NSCursor.resizeUpDown.push()
                } else {
                    NSCursor.pop()
                }
            }
            .gesture(
                DragGesture()
                    .onChanged { value in
                        let newHeight = topHeight + value.translation.height
                        topHeight = min(max(newHeight, minTopHeight), maxTopHeight)
                    }
            )
    }
}
