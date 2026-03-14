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

/// FocusedValue for the per-window "open slideshow" action.
/// Allows App-level menu commands to trigger document-level navigation.
/// See: https://developer.apple.com/documentation/swiftui/focusedvaluekey
struct OpenSlideshowURLKey: FocusedValueKey {
    typealias Value = (URL) -> Void
}

extension FocusedValues {
    var openSlideshowURL: ((URL) -> Void)? {
        get { self[OpenSlideshowURLKey.self] }
        set { self[OpenSlideshowURLKey.self] = newValue }
    }
}

@main
struct SlideshowApp: App {
    private let imageCache = ImageCache()
    @FocusedValue(\.openSlideshowURL) private var openSlideshowURL

    var body: some Scene {
        WindowGroup {
            SlideshowDocumentView()
                .environment(\.imageCache, imageCache)
        }
        .defaultSize(width: 1200, height: 800)
        .windowToolbarStyle(.unified)
        .commands {
            CommandGroup(after: .newItem) {
                Button("New Slideshow...") {
                    createNewSlideshow()
                }
                .keyboardShortcut("n")
            }
        }

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
            NSDocumentController.shared.noteNewRecentDocumentURL(url)
            self.openSlideshowURL?(url)
        }
    }
}

/// Per-window document root that owns its own slideshow state.
/// Each window gets independent slideshow, bookmark manager, and file importer state.
struct SlideshowDocumentView: View {
    @State private var slideshow = Slideshow()
    @State private var showFileImporter = false
    @State private var showPresenter = false
    @State private var presenterWindow: NSWindow?
    @State private var bookmarkManager = BookmarkManager()
    @Environment(\.imageCache) private var imageCache

    var body: some View {
        Group {
            if slideshow.folderURL != nil {
                ContentView(slideshow: slideshow, showPresenter: $showPresenter)
            } else {
                WelcomeView(
                    onOpen: { showFileImporter = true },
                    onNew: { createNewSlideshow() }
                )
            }
        }
        .environment(bookmarkManager)
        .focusedSceneValue(\.openSlideshowURL) { [self] url in
            Task { await openSlideshow(at: url) }
        }
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [.folder, UTType("is.kte.slideshow") ?? .folder],
            allowsMultipleSelection: false
        ) { result in
            if case .success(let urls) = result, let url = urls.first {
                Task { await openSlideshow(at: url) }
            }
        }
        .onChange(of: showPresenter) {
            if showPresenter {
                openPresenterWindow()
            }
        }
        .frame(minWidth: 600, minHeight: 400)
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

    private func openPresenterWindow() {
        // Close existing presenter window if open
        presenterWindow?.close()

        let presenterView = PresenterView(slideshow: slideshow)
            .environment(\.imageCache, imageCache)

        let hostingView = NSHostingView(rootView: presenterView)
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 900, height: 600),
            styleMask: [.titled, .closable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.contentView = hostingView
        window.title = "Presenter — \(slideshow.name)"
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.backgroundColor = .black
        window.center()
        window.makeKeyAndOrderFront(nil)

        // Reset showPresenter when window closes.
        // Queue is .main so the closure runs on the main thread;
        // MainActor.assumeIsolated is safe here.
        // See: https://developer.apple.com/documentation/swift/mainactor/assumeisolated(_:file:line:)-swift.type.method
        NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: window,
            queue: .main
        ) { _ in
            MainActor.assumeIsolated {
                showPresenter = false
                presenterWindow = nil
            }
        }

        presenterWindow = window
    }

    private func openSlideshow(at url: URL) async {
        // Stop accessing the previous slideshow's security-scoped resource
        // before starting the new one. Must balance start/stop calls.
        // See: https://developer.apple.com/documentation/foundation/url/1779698-startaccessingsecurityscopedreso
        if let oldURL = slideshow.folderURL {
            oldURL.stopAccessingSecurityScopedResource()
        }

        guard url.startAccessingSecurityScopedResource() else { return }

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
