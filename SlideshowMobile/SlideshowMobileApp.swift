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
    private let imageCache = ImageCache()

    var body: some Scene {
        WindowGroup {
            Group {
                if slideshow.folderURL != nil {
                    MobileContentView(slideshow: slideshow)
                } else {
                    ContentUnavailableView(
                        "Open a Slideshow",
                        systemImage: "photo.on.rectangle.angled",
                        description: Text("Open a .slideshow folder from Files to get started.")
                    )
                    .onTapGesture { showFileImporter = true }
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
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Open", systemImage: "folder") {
                        showFileImporter = true
                    }
                }
            }
        }
    }

    private func openSlideshow(at url: URL) async {
        let accessing = url.startAccessingSecurityScopedResource()
        defer { if accessing { url.stopAccessingSecurityScopedResource() } }

        let scanner = FolderScanner()
        do {
            let slides = try await scanner.scan(folderURL: url)
            slideshow.folderURL = url
            slideshow.slides = slides
            if let first = slides.first {
                slideshow.selectedSlideID = first.id
            }
        } catch {
            print("[slideshow-mobile] failed to scan folder: \(error)")
        }
    }
}
