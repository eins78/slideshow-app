import SwiftUI
import SlideshowKit

/// Presenter screen: current slide + next preview + notes + slide counter.
struct PresenterView: View {
    @Bindable var slideshow: Slideshow
    @Environment(\.dismiss) private var dismiss
    @Environment(\.imageCache) private var imageCache
    @State private var showNotes = true
    @State private var currentImage: NSImage?
    @State private var nextImage: NSImage?
    @State private var imageLoaded = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    // Current slide (large)
                    VStack(spacing: 4) {
                        Text("CURRENT")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        if let currentImage {
                            Image(nsImage: currentImage)
                                .resizable().aspectRatio(contentMode: .fit)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .border(Color.accentColor, width: 1)
                        } else if imageLoaded, slideshow.selectedSlide != nil {
                            // Load completed but returned nil — show placeholder
                            Image(systemName: "photo")
                                .font(.system(size: 48))
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else if slideshow.selectedSlide != nil {
                            ProgressView()
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                    }
                    .frame(maxWidth: .infinity)

                    // Next slide (small)
                    VStack(spacing: 4) {
                        Text("NEXT")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        if let nextImage {
                            Image(nsImage: nextImage)
                                .resizable().aspectRatio(contentMode: .fit)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else if nextSlide == nil {
                            Text("End")
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                    }
                    .frame(maxWidth: 200)
                }
                .padding(12)
                .frame(maxHeight: .infinity)

                if showNotes {
                    Divider().background(.secondary)
                    HStack {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 4) {
                                if let notes = slideshow.selectedSlide?.sidecar?.notes, !notes.isEmpty {
                                    MarkdownRenderedView(markdown: notes)
                                        .foregroundStyle(.white)
                                }
                            }
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(maxHeight: 200)

                        if let idx = slideshow.selectedIndex {
                            Text("\(idx + 1) / \(slideshow.slides.count)")
                                .font(.largeTitle.monospacedDigit())
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 20)
                        }
                    }
                }
            }
        }
        .onKeyPress(.rightArrow) { slideshow.selectNext(); return .handled }
        .onKeyPress(.leftArrow) { slideshow.selectPrevious(); return .handled }
        .onKeyPress(.space) { slideshow.selectNext(); return .handled }
        .onKeyPress(.escape) { dismiss(); return .handled }
        .onKeyPress("n") { showNotes.toggle(); return .handled }
        .focusable()
        .task(id: slideshow.selectedSlideID) {
            await loadImages()
        }
    }

    // Concurrent loading via async let
    private func loadImages() async {
        imageLoaded = false
        currentImage = nil
        nextImage = nil

        let currentURL = slideshow.selectedSlide?.fileURL
        let nextURL = nextSlide?.fileURL
        let cache = imageCache

        async let current: NSImage? = {
            guard let url = currentURL else { return nil }
            return await cache.fullNSImage(for: url)
        }()
        async let next: NSImage? = {
            guard let url = nextURL else { return nil }
            return await cache.thumbnailNSImage(for: url)
        }()

        let (c, n) = await (current, next)
        currentImage = c
        nextImage = n
        imageLoaded = true

        // Preload 2 slides ahead for zero-latency transitions
        if let idx = slideshow.selectedIndex {
            var urls: [URL] = []
            for offset in 2...3 {
                let futureIdx = idx + offset
                guard futureIdx < slideshow.slides.count else { break }
                urls.append(slideshow.slides[futureIdx].fileURL)
            }
            if !urls.isEmpty {
                await imageCache.preloadThumbnails(for: urls)
            }
        }
    }

    private var nextSlide: Slide? {
        guard let idx = slideshow.selectedIndex, idx + 1 < slideshow.slides.count else { return nil }
        return slideshow.slides[idx + 1]
    }
}
