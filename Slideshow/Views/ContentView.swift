import SwiftUI
import SlideshowKit

struct ContentView: View {
    @Bindable var slideshow: Slideshow
    @State private var viewMode: ViewMode = .list
    @State private var isTextDirty = false
    @State private var saveTrigger = false
    @State private var pendingViewMode: ViewMode?
    @State private var hostWindow: NSWindow?
    @State private var previewWidth: CGFloat = 240

    enum ViewMode: String, CaseIterable {
        case list, text
    }

    var body: some View {
        mainContent
            .background(WindowAccessor(window: $hostWindow))
            .navigationTitle(slideshow.document.title ?? slideshow.name)
            .navigationSubtitle("\(slideshow.slides.count) slides")
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Picker("View Mode", selection: viewModeBinding) {
                        Image(systemName: "list.bullet")
                            .tag(ViewMode.list)
                            .accessibilityLabel("List view")
                        Image(systemName: "doc.plaintext")
                            .tag(ViewMode.text)
                            .accessibilityLabel("Text view")
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 80)
                    .accessibilityLabel("View Mode")
                }
            }
            .focusedSceneValue(\.saveAction, saveAction)
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
            ContentUnavailableView(
                "No Images",
                systemImage: "photo.on.rectangle",
                description: Text("Open a folder of images to start a slideshow.")
            )
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
    ContentView(slideshow: Slideshow())
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
    return ContentView(slideshow: slideshow)
        .frame(width: 900, height: 600)
}
