import SwiftUI
import SlideshowKit

/// Full-screen presentation: image + caption on black.
struct PresenterView: View {
    @Bindable var slideshow: Slideshow
    @Environment(\.dismiss) private var dismiss
    @Environment(\.imageCache) private var imageCache
    @State private var currentImage: NSImage?
    @State private var imageLoaded = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let currentImage {
                Image(nsImage: currentImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .accessibilityLabel(
                        slideshow.selectedSlide?.sidecar?.caption
                            ?? slideshow.selectedSlide?.fileURL.lastPathComponent
                            ?? "Slide"
                    )
            } else if imageLoaded, slideshow.selectedSlide != nil {
                Image(systemName: "photo")
                    .font(.system(size: 48))
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
            } else if slideshow.selectedSlide != nil {
                ProgressView()
                    .tint(.white)
            }

            // Caption overlay at bottom
            if let caption = slideshow.selectedSlide?.sidecar?.caption, !caption.isEmpty {
                VStack {
                    Spacer()
                    Text(caption)
                        .font(.title2)
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.8), radius: 4, y: 2)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            LinearGradient(
                                colors: [.clear, .black.opacity(0.6)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }
            }
        }
        .onKeyPress(.rightArrow) { slideshow.selectNext(); return .handled }
        .onKeyPress(.leftArrow) { slideshow.selectPrevious(); return .handled }
        .onKeyPress(.space) { slideshow.selectNext(); return .handled }
        .onKeyPress(.escape) { dismiss(); return .handled }
        .focusable()
        .task(id: slideshow.selectedSlideID) {
            await loadImage()
        }
    }

    private func loadImage() async {
        imageLoaded = false
        currentImage = nil

        guard let url = slideshow.selectedSlide?.fileURL else {
            imageLoaded = true
            return
        }

        let image = await imageCache.fullNSImage(for: url)
        currentImage = image
        imageLoaded = true

        // Preload next slides for zero-latency transitions
        if let idx = slideshow.selectedIndex {
            var urls: [URL] = []
            for offset in 1...3 {
                let futureIdx = idx + offset
                guard futureIdx < slideshow.slides.count else { break }
                urls.append(slideshow.slides[futureIdx].fileURL)
            }
            if !urls.isEmpty {
                await imageCache.preloadFullImages(for: urls)
            }
        }
    }
}
