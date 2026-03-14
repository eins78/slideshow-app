import SwiftUI
import SlideshowKit

struct MobileContentView: View {
    @Bindable var slideshow: Slideshow
    @Environment(\.imageCache) private var imageCache

    var body: some View {
        VStack(spacing: 0) {
            slideImagePager
            thumbnailStrip
        }
        .navigationTitle(slideshow.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Image pager (swipe left/right)

    private var slideImagePager: some View {
        TabView(selection: $slideshow.selectedSlideID) {
            ForEach(slideshow.slides) { slide in
                SlideImageView(slide: slide, imageCache: imageCache)
                    .tag(slide.id as Slide.ID?)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
    }

    // MARK: - Thumbnail strip

    private var thumbnailStrip: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 4) {
                    ForEach(slideshow.slides) { slide in
                        ThumbnailView(
                            slide: slide,
                            isSelected: slide.id == slideshow.selectedSlideID,
                            imageCache: imageCache
                        )
                        .id(slide.id)
                        .onTapGesture { slideshow.selectedSlideID = slide.id }
                    }
                }
                .padding(.horizontal, 8)
            }
            .frame(height: 80)
            .background(.bar)
            .onChange(of: slideshow.selectedSlideID) { _, newID in
                guard let newID else { return }
                withAnimation { proxy.scrollTo(newID, anchor: .center) }
            }
        }
    }
}

// MARK: - Slide image (full size)

private struct SlideImageView: View {
    let slide: Slide
    let imageCache: ImageCache
    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .accessibilityLabel(slide.displayName)
                    .accessibilityAddTraits(.isImage)
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .task(id: slide.id) {
            image = await imageCache.fullUIImage(for: slide.fileURL)
        }
        .overlay(alignment: .bottom) {
            if let caption = slide.sidecar?.caption, !caption.isEmpty {
                Text(caption)
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial, in: .capsule)
                    .padding(.bottom, 8)
                    .accessibilityHidden(true)
            }
        }
    }
}

// MARK: - Thumbnail cell

private struct ThumbnailView: View {
    let slide: Slide
    let isSelected: Bool
    let imageCache: ImageCache
    @State private var thumbnail: UIImage?

    var body: some View {
        Group {
            if let thumbnail {
                Image(uiImage: thumbnail)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Color.secondary.opacity(0.2)
                    .accessibilityHidden(true)
            }
        }
        .frame(width: 60, height: 60)
        .clipShape(.rect(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(isSelected ? Color.accentColor : .clear, lineWidth: 2)
        )
        .accessibilityLabel(slide.displayName)
        .accessibilityAddTraits([.isImage, .isButton])
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .task(id: slide.id) {
            thumbnail = await imageCache.thumbnailUIImage(for: slide.fileURL)
        }
    }
}
