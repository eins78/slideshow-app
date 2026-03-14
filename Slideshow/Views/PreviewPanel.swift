import SwiftUI
import SlideshowKit

struct PreviewPanel: View {
    @Bindable var slideshow: Slideshow

    var body: some View {
        VStack {
            if let slide = slideshow.selectedSlide {
                Text(slide.displayName)
                    .font(.title3)
                    .foregroundStyle(.white)
            } else {
                Text("No slide selected")
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.black)
    }
}
