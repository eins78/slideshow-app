import SwiftUI
import SlideshowKit

struct ContentView: View {
    @Bindable var slideshow: Slideshow
    @Binding var showPresenter: Bool
    @State private var showInspector = true
    @State private var viewMode: ViewMode = .list
    @State private var searchText = ""
    @State private var showImageImporter = false

    enum ViewMode: String, CaseIterable {
        case list, grid
    }

    var body: some View {
        mainContent
            .navigationTitle(slideshow.name)
            .navigationSubtitle("\(slideshow.slides.count) slides")
            .searchable(text: $searchText, prompt: "Filter slides")
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Picker("View Mode", selection: $viewMode) {
                        Image(systemName: "list.bullet").tag(ViewMode.list)
                        Image(systemName: "square.grid.2x2").tag(ViewMode.grid)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 80)
                }

                ToolbarItem(placement: .automatic) {
                    Button("Present", systemImage: "play.fill") {
                        showPresenter = true
                    }
                    .accessibilityIdentifier("presentButton")
                    .keyboardShortcut("p", modifiers: [.command, .shift])
                    .disabled(slideshow.slides.isEmpty)
                }

                ToolbarItem(placement: .automatic) {
                    Button("Add Images", systemImage: "plus") {
                        showImageImporter = true
                    }
                    .accessibilityIdentifier("addImagesButton")
                    .keyboardShortcut("i", modifiers: [.command, .shift])
                }

                ToolbarItem(placement: .automatic) {
                    Button("Inspector", systemImage: "sidebar.trailing") {
                        showInspector.toggle()
                    }
                    .accessibilityLabel("Toggle Inspector")
                    .keyboardShortcut("i", modifiers: [.command, .option])
                }
            }
            .fileImporter(
                isPresented: $showImageImporter,
                allowedContentTypes: [.image],
                allowsMultipleSelection: true
            ) { result in
                if case .success(let urls) = result {
                    slideshow.addImages(from: urls)
                }
            }
    }

    @ViewBuilder
    private var mainContent: some View {
        if slideshow.slides.isEmpty {
            ContentUnavailableView {
                Label("No Images", systemImage: "photo.on.rectangle")
            } description: {
                Text("Add images to start building your slideshow.")
            } actions: {
                Button("Add Images...") { showImageImporter = true }
                    .buttonStyle(.borderedProminent)
            }
        } else {
            HSplitView {
                PreviewPanel(slideshow: slideshow)
                    .frame(minWidth: 200, idealWidth: 240)

                SlideListPanel(slideshow: slideshow, viewMode: viewMode, searchText: searchText)
                    .frame(minWidth: 300)
            }
            .inspector(isPresented: $showInspector) {
                if let slide = slideshow.selectedSlide {
                    VStack(spacing: 0) {
                        EditorPanel(slideshow: slideshow, slide: slide)
                        Divider()
                        FileInfoPanel(slide: slide)
                    }
                } else {
                    ContentUnavailableView("No Slide Selected", systemImage: "photo")
                }
            }
            .inspectorColumnWidth(min: 220, ideal: 280, max: 400)
        }
    }
}

#Preview("Content — Empty") {
    ContentView(slideshow: Slideshow(), showPresenter: .constant(false))
        .frame(width: 900, height: 600)
}

#Preview("Content — With Slides") {
    let slideshow = Slideshow()
    let slides = [
        Slide(section: SlideSection(caption: "Welcome slide", images: [SlideImage(filename: "001--intro.jpg")], notes: "Opening remarks")),
        Slide(section: SlideSection(caption: "Golden hour", images: [SlideImage(filename: "002--sunset.jpg")], source: "© Photographer")),
        Slide(section: SlideSection(images: [SlideImage(filename: "003--portrait.jpg")])),
    ]
    for slide in slides { slide.fileSize = 2_500_000 }
    slideshow.slides = slides
    slideshow.selectedSlideID = slides[1].id
    return ContentView(slideshow: slideshow, showPresenter: .constant(false))
        .frame(width: 900, height: 600)
}
