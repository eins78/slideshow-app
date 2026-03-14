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
        List(filteredSlides, selection: $slideshow.selectedSlideID) { slide in
            Text(slide.displayName)
        }
    }
}
