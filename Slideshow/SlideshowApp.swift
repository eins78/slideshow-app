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

/// FocusedValue for triggering "New Slideshow" from the App menu.
/// The App sets this to true; the focused DocumentView observes and acts.
/// See: https://developer.apple.com/documentation/swiftui/focusedvaluekey
struct CreateNewSlideshowKey: FocusedValueKey {
    typealias Value = Binding<Bool>
}

extension FocusedValues {
    var createNewSlideshow: Binding<Bool>? {
        get { self[CreateNewSlideshowKey.self] }
        set { self[CreateNewSlideshowKey.self] = newValue }
    }
}

@main
struct SlideshowApp: App {
    private let imageCache = ImageCache()
    @FocusedValue(\.createNewSlideshow) private var createNewSlideshow

    var body: some Scene {
        WindowGroup {
            SlideshowDocumentView()
                .environment(\.imageCache, imageCache)
        }
        .defaultSize(width: 1200, height: 800)
        .windowToolbarStyle(.unified)
        .commands {
            CommandGroup(after: .newItem) {
                Button("New Project...") {
                    createNewSlideshow?.wrappedValue = true
                }
                .keyboardShortcut("n")
            }
        }

        Settings {
            SettingsView()
        }
    }
}

/// Per-window document root that owns its own slideshow state.
/// Each window gets independent slideshow, bookmark manager, and file importer state.
struct SlideshowDocumentView: View {
    @State private var slideshow = Slideshow()
    @State private var showFileImporter = false
    @State private var showNewSlideshowPanel = false
    @State private var showPresenter = false
    @State private var presenterWindow: NSWindow?
    @State private var bookmarkManager = BookmarkManager()
    @State private var scanError: Error?
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
        .focusedSceneValue(\.createNewSlideshow, $showNewSlideshowPanel)
        .onChange(of: showNewSlideshowPanel) {
            if showNewSlideshowPanel {
                showNewSlideshowPanel = false
                createNewSlideshow()
            }
        }
        .task {
            if CommandLine.arguments.contains("--ui-test-fixtures") {
                await loadUITestFixtures()
            } else if CommandLine.arguments.contains("--ui-test-add-images") {
                await loadUITestAddImages()
            }
        }
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [.folder],
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
        .alert("Could not open slideshow", isPresented: Binding(
            get: { scanError != nil },
            set: { if !$0 { scanError = nil } }
        )) {
            Button("OK", role: .cancel) { }
        } message: {
            if let scanError {
                Text(scanError.localizedDescription)
            }
        }
        .frame(minWidth: 600, minHeight: 400)
    }

    private func createNewSlideshow() {
        let panel = NSOpenPanel()
        panel.canCreateDirectories = true
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.prompt = "Create"
        panel.message = "Choose or create a folder for your slideshow"
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            Task {
                // openSlideshow auto-creates slideshow.md if missing
                await openSlideshow(at: url)
            }
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

    /// Load test fixtures for UI testing — copies an example slideshow to a temp dir.
    /// Activated by launch argument `--ui-test-fixtures`.
    private func loadUITestFixtures() async {
        let fm = FileManager.default
        let tmpDir = fm.temporaryDirectory
            .appending(path: "slideshow-ui-test-\(ProcessInfo.processInfo.processIdentifier)")
        try? fm.removeItem(at: tmpDir)

        // Use Examples from the source tree (resolved via #filePath)
        let sourceExample = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
            .appending(path: "Examples/Paintings That Tell Secrets")

        if fm.fileExists(atPath: sourceExample.path(percentEncoded: false)) {
            try? fm.copyItem(at: sourceExample, to: tmpDir)
        } else {
            // Fallback: minimal fixtures when Examples dir not present
            try? fm.createDirectory(at: tmpDir, withIntermediateDirectories: true)
            let jpeg = Data([0xFF, 0xD8, 0xFF, 0xD9])
            for name in ["001--photo.jpg", "002--photo.jpg", "003--photo.jpg"] {
                try? jpeg.write(to: tmpDir.appending(path: name))
            }
            let md = """
            ---
            format: https://example.com/slideshow/v1
            ---

            # Test Slideshow

            ---

            ![](001--photo.jpg)

            ---

            ### Test slide

            ![](002--photo.jpg)

            Notes

            ---

            ![](003--photo.jpg)

            ---
            """
            try? md.write(to: tmpDir.appending(path: "slideshow.md"),
                          atomically: true, encoding: .utf8)
        }

        await openSlideshow(at: tmpDir)
    }

    /// Create an empty slideshow and add images programmatically.
    /// Tests the addImages(from:) security-scope fix end-to-end.
    /// Activated by launch argument `--ui-test-add-images`.
    private func loadUITestAddImages() async {
        let fm = FileManager.default
        let tmpDir = fm.temporaryDirectory
            .appending(path: "slideshow-ui-test-add-\(ProcessInfo.processInfo.processIdentifier)")
        try? fm.removeItem(at: tmpDir)
        try? fm.createDirectory(at: tmpDir, withIntermediateDirectories: true)

        // Open the empty slideshow first
        await openSlideshow(at: tmpDir)

        // Find example images from the source tree
        let examplesDir = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
            .appending(path: "Examples/Paintings That Tell Secrets")

        let imageExtensions = FolderScanner.imageExtensions
        let contents = (try? fm.contentsOfDirectory(
            at: examplesDir,
            includingPropertiesForKeys: nil
        )) ?? []
        let imageURLs = contents.filter { imageExtensions.contains($0.pathExtension.lowercased()) }
        if !imageURLs.isEmpty {
            slideshow.addImages(from: imageURLs)
        }
    }

    private func openSlideshow(at url: URL) async {
        // Stop accessing the previous slideshow's security-scoped resource
        // before starting the new one. Must balance start/stop calls.
        // See: https://developer.apple.com/documentation/foundation/url/1779698-startaccessingsecurityscopedreso
        if let oldURL = slideshow.folderURL {
            oldURL.stopAccessingSecurityScopedResource()
        }

        // startAccessingSecurityScopedResource returns false for non-scoped URLs
        // (e.g., temp dirs, some file-importer URLs). The URL may still be accessible
        // via sandbox entitlements — only call stop if start succeeded.
        // See: https://developer.apple.com/documentation/foundation/url/1779698-startaccessingsecurityscopedreso
        let didStartAccessing = url.startAccessingSecurityScopedResource()

        bookmarkManager.saveBookmark(for: url)
        NSDocumentController.shared.noteNewRecentDocumentURL(url)

        let scanner = FolderScanner()
        let parser = SlideshowParser()

        do {
            let result: ScanResult

            if url.pathExtension.lowercased() == "md" {
                // Opening a .md file directly — validate it
                guard parser.isValidSlideshowFile(url: url) else {
                    if didStartAccessing { url.stopAccessingSecurityScopedResource() }
                    scanError = NSError(
                        domain: "is.ars.slideshow",
                        code: 1,
                        userInfo: [NSLocalizedDescriptionKey: "This file is not a slideshow. Expected slideshow.md or a file with format frontmatter."]
                    )
                    return
                }
                result = try await scanner.scan(documentURL: url)
            } else {
                // Opening a folder
                result = try await scanner.scan(folderURL: url)
            }

            // If we opened a folder with no slideshow.md, create one
            var docURL = result.documentURL
            var doc = result.document ?? SlideshowDocument()
            if docURL == nil, !url.pathExtension.lowercased().hasSuffix("md") {
                let mdURL = url.appendingPathComponent(SlideshowDocument.defaultFilename)
                doc.title = url.lastPathComponent
                doc.slides = result.slides.map(\.section)
                try? SlideshowWriter().write(doc, to: mdURL)
                docURL = mdURL
            }

            slideshow.documentURL = docURL
            slideshow.document = doc
            slideshow.slides = result.slides
            if let first = result.slides.first {
                slideshow.selectedSlideID = first.id
            }
        } catch {
            if didStartAccessing { url.stopAccessingSecurityScopedResource() }
            scanError = error
        }
    }
}
