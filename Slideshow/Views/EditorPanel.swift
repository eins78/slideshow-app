import SwiftUI
import SlideshowKit

struct EditorPanel: View {
    @Bindable var slide: Slide

    var body: some View {
        Text("Editor: \(slide.displayName)")
            .padding()
    }
}
