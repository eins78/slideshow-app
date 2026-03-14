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
        List(selection: $slideshow.selectedSlideID) {
            ForEach(Array(filteredSlides.enumerated()), id: \.element.id) { index, slide in
                SlideRowView(slide: slide, index: index)
                    .tag(slide.id)
                    .contextMenu {
                        Button("Quick Look") {
                            NSWorkspace.shared.activateFileViewerSelecting([slide.fileURL])
                        }

                        Divider()

                        Button("Edit Caption...") {
                            slideshow.selectedSlideID = slide.id
                        }

                        if slide.sidecar == nil {
                            Button("Create Sidecar File") {
                                try? slideshow.createSidecar(for: slide)
                            }
                        }

                        Divider()

                        Button("Move Up") {
                            slideshow.moveSlide(slide, direction: -1)
                        }
                        .disabled(slideshow.slides.first?.id == slide.id)

                        Button("Move Down") {
                            slideshow.moveSlide(slide, direction: 1)
                        }
                        .disabled(slideshow.slides.last?.id == slide.id)

                        Divider()

                        Button("Reveal in Finder") {
                            NSWorkspace.shared.activateFileViewerSelecting([slide.fileURL])
                        }

                        Divider()

                        Button("Remove from Slideshow", role: .destructive) {
                            slideshow.removeSlide(slide)
                        }
                    }
            }
            .onMove { indices, newOffset in
                slideshow.slides.move(fromOffsets: indices, toOffset: newOffset)
            }
        }
        .listStyle(.inset(alternatesRowBackgrounds: true))
    }
}
