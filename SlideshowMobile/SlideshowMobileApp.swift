import SwiftUI
import UniformTypeIdentifiers
import SlideshowKit

@main
struct SlideshowMobileApp: App {
    @State private var slideshow = Slideshow()
    @State private var showFileImporter = false
    @State private var accessingSecurityScope = false
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
        // Stop previous security-scoped access if any
        if accessingSecurityScope, let previous = slideshow.folderURL {
            previous.stopAccessingSecurityScopedResource()
        }

        // Keep security-scoped access alive for the lifetime of the slideshow
        // so ImageCache can read files on demand
        accessingSecurityScope = url.startAccessingSecurityScopedResource()

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
            if accessingSecurityScope {
                url.stopAccessingSecurityScopedResource()
                accessingSecurityScope = false
            }
        }
    }
}
