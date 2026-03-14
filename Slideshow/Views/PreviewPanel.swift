import SwiftUI
import SlideshowKit

struct PreviewPanel: View {
    var slideshow: Slideshow
    @Environment(\.imageCache) private var imageCache
    @State private var topHeight: CGFloat = 300
    @State private var previewImage: NSImage?
    @State private var imageLoaded = false

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
        .task(id: slideshow.selectedSlideID) {
            await loadImage()
        }
    }

    @ViewBuilder
    private var imagePreview: some View {
        if let slide = slideshow.selectedSlide {
            VStack(spacing: 4) {
                if let image = previewImage {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if imageLoaded {
                    // Load completed but returned nil — show placeholder
                    Image(systemName: "photo")
                        .font(.system(size: 48))
                        .foregroundStyle(.gray)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }

                if let caption = slide.sidecar?.caption {
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
        guard let slide = slideshow.selectedSlide else {
            imageLoaded = true
            return
        }
        let url = slide.fileURL
        let image = await imageCache.thumbnailNSImage(for: url)
        previewImage = image
        imageLoaded = true
    }

    @ViewBuilder
    private var notesPreview: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                if let sidecar = slideshow.selectedSlide?.sidecar {
                    if sidecar.source != nil {
                        SourceTextView(sidecar: sidecar)
                    }
                    if !sidecar.notes.isEmpty {
                        MarkdownRenderedView(markdown: sidecar.notes)
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
    let slideshow = Slideshow(folderURL: URL(fileURLWithPath: "/tmp/demo.slideshow"))
    let slide = Slide(
        fileURL: URL(fileURLWithPath: "/tmp/demo.slideshow/sunset.jpg"),
        sidecar: SidecarData(
            caption: "Golden hour",
            source: "© Photographer 2024\nLightroom CC",
            notes: "Beautiful sunset over the lake.\n\n**Discuss:** composition and light"
        )
    )
    slideshow.slides = [slide]
    slideshow.selectedSlideID = slide.id
    return PreviewPanel(slideshow: slideshow)
        .frame(width: 240, height: 600)
}
