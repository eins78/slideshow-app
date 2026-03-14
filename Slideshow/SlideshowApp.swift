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
struct SlideshowApp: App {
    @State private var slideshow = Slideshow()
    @State private var showFileImporter = false
    @State private var bookmarkManager = BookmarkManager()
    private let imageCache = ImageCache()

    var body: some Scene {
        WindowGroup {
            Group {
                if slideshow.folderURL != nil {
                    ContentView(slideshow: slideshow)
                } else {
                    WelcomeView(
                        onOpen: { showFileImporter = true },
                        onNew: { createNewSlideshow() }
                    )
                }
            }
            .environment(\.imageCache, imageCache)
            .environment(bookmarkManager)
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
                Button("New Slideshow...") { createNewSlideshow() }
                    .keyboardShortcut("n")
                Button("Open Slideshow...") { showFileImporter = true }
                    .keyboardShortcut("o")
            }
        }

        Window("Presenter", id: "presenter") {
            PresenterView(slideshow: slideshow)
                .environment(\.imageCache, imageCache)
        }
        .windowStyle(.hiddenTitleBar)

        Settings {
            SettingsView()
        }
    }

    private func createNewSlideshow() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [UTType("is.kte.slideshow") ?? .folder]
        panel.nameFieldStringValue = "Untitled.slideshow"
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
            Task { await openSlideshow(at: url) }
        }
    }

    private func openSlideshow(at url: URL) async {
        // Security-scoped access required for sandboxed app
        guard url.startAccessingSecurityScopedResource() else { return }

        // Stop accessing the previous slideshow's security-scoped resource
        // before switching. Must balance start/stop calls.
        // See: https://developer.apple.com/documentation/foundation/url/1779698-startaccessingsecurityscopedreso
        if let oldURL = slideshow.folderURL, oldURL != url {
            oldURL.stopAccessingSecurityScopedResource()
        }

        bookmarkManager.saveBookmark(for: url)
        NSDocumentController.shared.noteNewRecentDocumentURL(url)

        let scanner = FolderScanner()
        do {
            let slides = try await scanner.scan(folderURL: url)
            slideshow.folderURL = url
            slideshow.slides = slides
            if let first = slides.first {
                slideshow.selectedSlideID = first.id
            }
        } catch {
            url.stopAccessingSecurityScopedResource()
            print("Failed to scan folder: \(error)")
        }
    }
}
