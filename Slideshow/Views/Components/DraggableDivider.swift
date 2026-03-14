import SwiftUI

/// A horizontal divider that can be dragged to resize panels above/below.
struct DraggableDivider: View {
    @Binding var topHeight: CGFloat
    let minTopHeight: CGFloat
    let maxTopHeight: CGFloat
    @State private var dragStartHeight: CGFloat = 0
    @State private var isHovering = false

    var body: some View {
        Rectangle()
            .fill(Color(nsColor: .separatorColor))
            .frame(height: 1)
            .padding(.vertical, 3)
            .frame(height: 8)
            .contentShape(Rectangle())
            .onHover { hovering in
                guard hovering != isHovering else { return }
                isHovering = hovering
                if hovering {
                    NSCursor.resizeUpDown.push()
                } else {
                    NSCursor.pop()
                }
            }
            .onDisappear {
                if isHovering {
                    NSCursor.pop()
                    isHovering = false
                }
            }
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if dragStartHeight == 0 { dragStartHeight = topHeight }
                        let newHeight = dragStartHeight + value.translation.height
                        topHeight = min(max(newHeight, minTopHeight), maxTopHeight)
                    }
                    .onEnded { _ in
                        dragStartHeight = 0
                    }
            )
    }
}
