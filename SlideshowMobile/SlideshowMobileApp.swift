import SwiftUI
import UniformTypeIdentifiers
import SlideshowKit

private struct ImageCacheKey: EnvironmentKey {
    static let defaultValue = ImageCache()
}

extension EnvironmentValues {
    var imageCache: ImageCache {
        get { self[ImageCacheKey.self] }
        set { self[ImageCacheKey.self] = newValue }
    }
}

@main
struct SlideshowMobileApp: App {
    @State private var slideshow = Slideshow()
    @State private var showFileImporter = false

    @State private var imageCache = ImageCache(thumbnailPixelSize: 256)

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                Group {
                    if slideshow.folderURL != nil {
                        MobileContentView(slideshow: slideshow)
                    } else {
                        ContentUnavailableView {
                            Label("Open a Slideshow", systemImage: "photo.on.rectangle.angled")
                        } description: {
                            Text("Open a folder of images to get started.")
                        } actions: {
                            Button("Open Slideshow") { showFileImporter = true }
                                .accessibilityLabel("Open slideshow folder")
                        }
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button("Open", systemImage: "folder") {
                            showFileImporter = true
                        }
                        .accessibilityLabel("Open slideshow folder")
                    }
                }
            }
            .environment(\.imageCache, imageCache)
            .fileImporter(
                isPresented: $showFileImporter,
                allowedContentTypes: [.folder],
                allowsMultipleSelection: false
            ) { result in
                if case .success(let urls) = result, let url = urls.first {
                    Task { await openSlideshow(at: url) }
                }
            }
        }
    }

    private func openSlideshow(at url: URL) async {
        let didStartAccessing = url.startAccessingSecurityScopedResource()

        let scanner = FolderScanner()
        do {
            let slides = try await scanner.scan(folderURL: url)
            // Revoke previous access only after successful scan
            let previous = slideshow.folderURL
            slideshow.folderURL = url
            slideshow.slides = slides
            if let first = slides.first {
                slideshow.selectedSlideID = first.id
            }
            previous?.stopAccessingSecurityScopedResource()
        } catch {
            print("[slideshow-mobile] failed to scan folder: \(error)")
            if didStartAccessing {
                url.stopAccessingSecurityScopedResource()
            }
        }
    }
}
