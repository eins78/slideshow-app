import SwiftUI

/// A vertical-line divider that can be dragged to resize panels left/right.
struct HorizontalDivider: View {
    @Binding var leftWidth: CGFloat
    let minLeft: CGFloat
    let maxLeft: CGFloat
    @State private var dragStartWidth: CGFloat?
    @State private var isHovering = false

    var body: some View {
        Rectangle()
            .fill(Color(nsColor: .separatorColor))
            .frame(width: 1)
            .padding(.horizontal, 3)
            .frame(width: 8)
            .contentShape(Rectangle())
            .accessibilityHidden(true)
            .onHover { hovering in
                guard hovering != isHovering else { return }
                isHovering = hovering
                if hovering {
                    NSCursor.resizeLeftRight.push()
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
                DragGesture(coordinateSpace: .global)
                    .onChanged { value in
                        if dragStartWidth == nil { dragStartWidth = leftWidth }
                        guard let startWidth = dragStartWidth else { return }
                        let newWidth = startWidth + value.translation.width
                        leftWidth = min(max(newWidth, minLeft), maxLeft)
                    }
                    .onEnded { _ in
                        dragStartWidth = nil
                    }
            )
    }
}
