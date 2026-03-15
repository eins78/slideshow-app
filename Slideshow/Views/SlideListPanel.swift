import SwiftUI
import SlideshowKit

struct SlideListPanel: View {
    @Bindable var slideshow: Slideshow
    var viewMode: ContentView.ViewMode = .list
    var searchText: String = ""

    private var filteredSlides: [Slide] {
        if searchText.isEmpty { return slideshow.slides }
        return slideshow.slides.filter {
            $0.displayName.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        Group {
            if viewMode == .list {
                listView
            } else {
                gridView
            }
        }
    }

    private var listView: some View {
        List(selection: $slideshow.selectedSlideID) {
            ForEach(Array(filteredSlides.enumerated()), id: \.element.id) { index, slide in
                SlideRowView(slide: slide, index: index)
                    .tag(slide.id)
                    .contextMenu {
                        slideContextMenu(slide: slide, index: index)
                    }
            }
            .onMove { indices, newOffset in
                slideshow.slides.move(fromOffsets: indices, toOffset: newOffset)
                try? slideshow.save()
            }
        }
        .listStyle(.inset(alternatesRowBackgrounds: true))
    }

    private var gridView: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 120))], spacing: 8) {
                ForEach(filteredSlides) { slide in
                    gridItem(slide)
                        .onTapGesture { slideshow.selectedSlideID = slide.id }
                        .contextMenu {
                            if let index = filteredSlides.firstIndex(where: { $0.id == slide.id }) {
                                slideContextMenu(slide: slide, index: index)
                            }
                        }
                }
            }
            .padding(8)
        }
    }

    private func gridItem(_ slide: Slide) -> some View {
        VStack {
            Image(systemName: "photo")
                .font(.system(size: 32))
                .foregroundStyle(.secondary)
                .frame(width: 100, height: 80)
                .background(Color(nsColor: .controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .accessibilityHidden(true)

            Text(slide.section.images.first?.displayFilename ?? slide.displayName)
                .font(.caption)
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
        .padding(4)
        .background(
            slideshow.selectedSlideID == slide.id
                ? Color.accentColor.opacity(0.3)
                : Color.clear
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    @ViewBuilder
    private func slideContextMenu(slide: Slide, index: Int) -> some View {
        if let url = slide.primaryImageURL {
            Button("Reveal in Finder") {
                NSWorkspace.shared.activateFileViewerSelecting([url])
            }
        }

        Divider()

        Button("Edit Caption...") {
            slideshow.selectedSlideID = slide.id
        }

        Divider()

        Button("Move Up") {
            slideshow.moveSlide(slide, direction: -1)
        }
        .disabled(index == 0)

        Button("Move Down") {
            slideshow.moveSlide(slide, direction: 1)
        }
        .disabled(index == filteredSlides.count - 1)

        Divider()

        Button("Remove from Slideshow", role: .destructive) {
            slideshow.removeSlide(slide)
        }
    }
}

#Preview("Slide List — List Mode") {
    let slideshow = Slideshow()
    let slides = [
        Slide(section: SlideSection(caption: "Intro", images: [SlideImage(filename: "001--intro.jpg")])),
        Slide(section: SlideSection(caption: "Golden hour", images: [SlideImage(filename: "002--sunset.jpg")])),
        Slide(section: SlideSection(images: [SlideImage(filename: "003--portrait.jpg")])),
    ]
    for slide in slides { slide.fileSize = 2_000_000 }
    slideshow.slides = slides
    slideshow.selectedSlideID = slides[0].id
    return SlideListPanel(slideshow: slideshow, viewMode: .list)
        .frame(width: 350, height: 400)
}

#Preview("Slide List — Grid Mode") {
    let slideshow = Slideshow()
    let slides = (1...8).map { i in
        Slide(section: SlideSection(images: [SlideImage(filename: "\(String(format: "%03d", i))--photo-\(i).jpg")]))
    }
    slideshow.slides = slides
    return SlideListPanel(slideshow: slideshow, viewMode: .grid)
        .frame(width: 400, height: 400)
}
