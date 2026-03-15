import SwiftUI
import SlideshowKit

struct ContentView: View {
    @Bindable var slideshow: Slideshow
    @Binding var showPresenter: Bool
    @State private var viewMode: ViewMode = .list
    @State private var searchText = ""
    @State private var showImageImporter = false
    @State private var isTextDirty = false
    @State private var saveTrigger = false
    @State private var pendingViewMode: ViewMode?
    @State private var hostWindow: NSWindow?
    @State private var previewWidth: CGFloat = 240

    enum ViewMode: String, CaseIterable {
        case list, grid, text
    }

    var body: some View {
        mainContent
            .background(WindowAccessor(window: $hostWindow))
            .navigationTitle(slideshow.name)
            .navigationSubtitle("\(slideshow.slides.count) slides")
            .searchable(text: $searchText, prompt: "Filter slides")
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Picker("View Mode", selection: viewModeBinding) {
                        Image(systemName: "list.bullet")
                            .tag(ViewMode.list)
                            .accessibilityLabel("List view")
                        Image(systemName: "square.grid.2x2")
                            .tag(ViewMode.grid)
                            .accessibilityLabel("Grid view")
                        Image(systemName: "doc.plaintext")
                            .tag(ViewMode.text)
                            .accessibilityLabel("Text view")
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 120)
                    .accessibilityLabel("View Mode")
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
            }
            .focusedSceneValue(\.saveAction, saveAction)
            .fileImporter(
                isPresented: $showImageImporter,
                allowedContentTypes: [.image],
                allowsMultipleSelection: true
            ) { result in
                if case .success(let urls) = result {
                    slideshow.addImages(from: urls)
                }
            }
            .onChange(of: isTextDirty) {
                if !isTextDirty, let pending = pendingViewMode {
                    viewMode = pending
                    pendingViewMode = nil
                }
            }
    }

    /// Binding that intercepts mode switches away from `.text` when dirty.
    private var viewModeBinding: Binding<ViewMode> {
        Binding(
            get: { viewMode },
            set: { newMode in
                if viewMode == .text && newMode != .text && isTextDirty {
                    pendingViewMode = newMode
                    saveTrigger = true
                } else {
                    viewMode = newMode
                }
            }
        )
    }

    private var saveAction: () -> Void {
        {
            if viewMode == .text {
                saveTrigger = true
            } else {
                try? slideshow.save()
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
            GeometryReader { geometry in
                HStack(spacing: 0) {
                    PreviewPanel(slideshow: slideshow)
                        .frame(width: previewWidth)

                    HorizontalDivider(
                        leftWidth: $previewWidth,
                        minLeft: 200,
                        maxLeft: geometry.size.width - 308
                    )

                    SlideListPanel(
                        slideshow: slideshow,
                        viewMode: viewMode,
                        searchText: searchText,
                        isDirty: $isTextDirty,
                        saveTrigger: $saveTrigger,
                        hostWindow: hostWindow
                    )
                    .frame(minWidth: 300)
                }
            }
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
        Slide(section: SlideSection(caption: "Golden hour", images: [SlideImage(filename: "002--sunset.jpg")], source: "\u{00A9} Photographer")),
        Slide(section: SlideSection(images: [SlideImage(filename: "003--portrait.jpg")])),
    ]
    for slide in slides { slide.fileSize = 2_500_000 }
    slideshow.slides = slides
    slideshow.selectedSlideID = slides[1].id
    return ContentView(slideshow: slideshow, showPresenter: .constant(false))
        .frame(width: 900, height: 600)
}
