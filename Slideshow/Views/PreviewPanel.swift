import SwiftUI
import SlideshowKit

struct PreviewPanel: View {
    var slideshow: Slideshow
    @Environment(\.imageCache) private var imageCache
    @State private var topHeight: CGFloat = 300
    @State private var previewImage: NSImage?
    @State private var imageLoaded = false

    /// The image URL to load — live preview takes priority over selected slide.
    private var imageURLToLoad: URL? {
        if let live = slideshow.livePreview, live.slideSection != nil {
            return live.imageURL
        }
        return slideshow.selectedSlide?.primaryImageURL
    }

    /// The slide section to display (caption, notes, source).
    private var displaySection: SlideSection? {
        if let live = slideshow.livePreview, let section = live.slideSection {
            return section
        }
        return slideshow.selectedSlide?.section
    }

    /// Display name for accessibility.
    private var displayName: String {
        displaySection?.displayName ?? "No slide selected"
    }

    var body: some View {
        VStack(spacing: 0) {
            imagePreview
                .frame(height: topHeight)

            DraggableDivider(
                topHeight: $topHeight,
                minTopHeight: 100,
                maxTopHeight: 500
            )

            notesPreview
        }
        .background(.black)
        .task(id: imageURLToLoad) {
            await loadImage()
        }
    }

    @ViewBuilder
    private var imagePreview: some View {
        if displaySection != nil {
            VStack(spacing: 4) {
                if let image = previewImage {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .accessibilityLabel(displayName)
                } else if imageLoaded {
                    Image(systemName: "photo")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }

                if let caption = displaySection?.caption {
                    Text(caption)
                        .font(.title3)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.bottom, 4)
                }
            }
        } else {
            Color.black
        }
    }

    private func loadImage() async {
        imageLoaded = false
        previewImage = nil
        guard let url = imageURLToLoad else {
            imageLoaded = true
            return
        }
        let image = await imageCache.thumbnailNSImage(for: url)
        previewImage = image
        imageLoaded = true
    }

    @ViewBuilder
    private var notesPreview: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                if let section = displaySection {
                    if section.source != nil {
                        SourceTextView(section: section)
                    }
                    if !section.notes.isEmpty {
                        MarkdownRenderedView(markdown: section.notes)
                    }
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color(nsColor: .controlBackgroundColor))
    }
}

#Preview("Preview Panel") {
    let slideshow = Slideshow()
    let slide = Slide(section: SlideSection(
        caption: "Golden hour",
        images: [SlideImage(filename: "sunset.jpg")],
        source: "© Photographer 2024\nLightroom CC",
        notes: "Beautiful sunset over the lake.\n\n**Discuss:** composition and light"
    ))
    slideshow.slides = [slide]
    slideshow.selectedSlideID = slide.id
    return PreviewPanel(slideshow: slideshow)
        .frame(width: 240, height: 600)
}
