import SwiftUI
import SlideshowKit

struct SlideListPanel: View {
    @Bindable var slideshow: Slideshow
    var viewMode: ContentView.ViewMode = .list
    @Binding var isDirty: Bool
    @Binding var saveTrigger: Bool
    var hostWindow: NSWindow?

    var body: some View {
        Group {
            switch viewMode {
            case .list:
                listView
            case .text:
                SlideshowTextView(
                    slideshow: slideshow,
                    isDirty: $isDirty,
                    saveTrigger: $saveTrigger,
                    hostWindow: hostWindow
                )
            }
        }
    }

    private var listView: some View {
        List(selection: $slideshow.selectedSlideID) {
            ForEach(Array(slideshow.slides.enumerated()), id: \.element.id) { index, slide in
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
        .disabled(index == slideshow.slides.count - 1)

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
    return SlideListPanel(
        slideshow: slideshow,
        viewMode: .list,
        isDirty: .constant(false),
        saveTrigger: .constant(false)
    )
    .frame(width: 350, height: 400)
}
