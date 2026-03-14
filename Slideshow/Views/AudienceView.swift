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
            let image = await Task.detached {
                await imageCache.fullNSImage(for: url)
            }.value
            displayImage = image
        }
    }
}
