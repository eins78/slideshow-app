import SwiftUI
import SlideshowKit

/// Full-bleed image on black — shown on the audience display.
struct AudienceView: View {
    let slide: Slide?
    @Environment(\.imageCache) private var imageCache
    @State private var displayImage: NSImage?

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let displayImage {
                Image(nsImage: displayImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else if slide != nil {
                ProgressView()
                    .tint(.white)
            }
        }
        .task(id: slide?.id) {
            guard let slide else { displayImage = nil; return }
            let url = slide.fileURL
            // imageCache is an actor — awaiting directly is sufficient,
            // no Task.detached needed (actor executor handles isolation)
            let image = await imageCache.fullNSImage(for: url)
            displayImage = image
        }
    }
}
