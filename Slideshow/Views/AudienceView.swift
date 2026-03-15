import SwiftUI
import SlideshowKit

/// Full-bleed image on black — shown on the audience display.
struct AudienceView: View {
    let slide: Slide?
    @Environment(\.imageCache) private var imageCache
    @State private var displayImage: NSImage?
    @State private var imageLoaded = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let displayImage {
                Image(nsImage: displayImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else if imageLoaded, slide != nil {
                // Load completed but returned nil — show placeholder
                Image(systemName: "photo")
                    .font(.system(size: 48))
                    .foregroundStyle(.secondary)
            } else if slide != nil {
                ProgressView()
                    .tint(.white)
            }
        }
        .task(id: slide?.id) {
            imageLoaded = false
            displayImage = nil
            guard let slide else {
                imageLoaded = true
                return
            }
            guard let url = slide.primaryImageURL else {
                imageLoaded = true
                return
            }
            // imageCache is an actor — awaiting directly is sufficient,
            // no Task.detached needed (actor executor handles isolation)
            let image = await imageCache.fullNSImage(for: url)
            displayImage = image
            imageLoaded = true
        }
    }
}
