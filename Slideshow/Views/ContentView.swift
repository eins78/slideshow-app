import SwiftUI
import SlideshowKit

struct ContentView: View {
    @Bindable var slideshow: Slideshow
    @State private var showInspector = true
    @State private var viewMode: ViewMode = .list
    @State private var searchText = ""
    @State private var showImageImporter = false

    enum ViewMode: String, CaseIterable {
        case list, grid
    }

    var body: some View {
        Group {
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
                            EditorPanel(slide: slide)
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
                Button("Add Images", systemImage: "plus") {
                    showImageImporter = true
                }
                .keyboardShortcut("i", modifiers: [.command, .shift])
            }

            ToolbarItem(placement: .automatic) {
                Button("Inspector", systemImage: "sidebar.trailing") {
                    showInspector.toggle()
                }
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
}
