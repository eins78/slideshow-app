import SwiftUI
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
struct SlideshowApp: App {
    @State private var slideshow = Slideshow()
    @State private var showFileImporter = false
    private let imageCache = ImageCache()

    var body: some Scene {
        WindowGroup {
            Group {
                if slideshow.folderURL != nil {
                    ContentView(slideshow: slideshow)
                } else {
                    WelcomeView(
                        onOpen: { showFileImporter = true },
                        onNew: { /* TODO: Task 14 */ }
                    )
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
            .frame(minWidth: 600, minHeight: 400)
        }
        .defaultSize(width: 1200, height: 800)
        .windowToolbarStyle(.unified)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Open Slideshow...") { showFileImporter = true }
                    .keyboardShortcut("o")
            }
        }

        Settings {
            Text("Settings placeholder")
                .frame(width: 400, height: 300)
        }
    }

    private func openSlideshow(at url: URL) async {
        // Security-scoped access required for sandboxed app
        guard url.startAccessingSecurityScopedResource() else { return }
        defer { url.stopAccessingSecurityScopedResource() }

        let scanner = FolderScanner()
        do {
            let slides = try await scanner.scan(folderURL: url)
            slideshow.folderURL = url
            slideshow.slides = slides
            if let first = slides.first {
                slideshow.selectedSlideID = first.id
            }
        } catch {
            print("Failed to scan folder: \(error)")
        }
    }
}
