import Foundation
import Observation

/// The slideshow document model.
/// @MainActor: created and mutated by views, owns file I/O operations.
/// See: https://developer.apple.com/documentation/swiftui/model-data
@MainActor
@Observable
public final class Slideshow {
    /// URL of the `slideshow.md` file.
    public var documentURL: URL?
    /// Ordered list of slides.
    public var slides: [Slide] = []
    /// Currently selected slide ID.
    public var selectedSlideID: Slide.ID?
    /// The parsed document (frontmatter, title, header content).
    /// Note: `document.slides` is only synced on `save()` — read `slides` for live data.
    public var document: SlideshowDocument = SlideshowDocument()

    /// File presenter for detecting external changes to `slideshow.md`.
    private var filePresenter: DocumentFilePresenter?

    public init(documentURL: URL? = nil) {
        self.documentURL = documentURL
    }

    /// Folder containing the slideshow.md and images.
    public var folderURL: URL? { documentURL?.deletingLastPathComponent() }

    /// Display name: document title, then filename (if not "slideshow"), then folder name.
    public var name: String {
        if let title = document.title, !title.isEmpty { return title }
        if let docURL = documentURL {
            let filename = docURL.deletingPathExtension().lastPathComponent
            if filename.lowercased() != SlideshowDocument.defaultStem { return filename }
        }
        return folderURL?.lastPathComponent ?? "Untitled"
    }

    /// Currently selected slide.
    public var selectedSlide: Slide? {
        slides.first { $0.id == selectedSlideID }
    }

    /// Index of the currently selected slide.
    public var selectedIndex: Int? {
        slides.firstIndex { $0.id == selectedSlideID }
    }

    /// Select the next slide. Returns false if already at end.
    @discardableResult
    public func selectNext() -> Bool {
        guard let idx = selectedIndex, idx + 1 < slides.count else { return false }
        selectedSlideID = slides[idx + 1].id
        return true
    }

    /// Select the previous slide. Returns false if already at start.
    @discardableResult
    public func selectPrevious() -> Bool {
        guard let idx = selectedIndex, idx > 0 else { return false }
        selectedSlideID = slides[idx - 1].id
        return true
    }

    // MARK: - Document persistence

    /// Save the current slideshow to disk via `NSFileCoordinator`.
    /// Uses the file presenter so the presenter is NOT notified of self-writes.
    /// When no presenter is active, `NSFileCoordinator(filePresenter: nil)` still works.
    public func save() throws {
        guard let url = documentURL else { return }
        document.slides = slides.map(\.section)
        let content = SlideshowWriter().write(document)

        var coordinatorError: NSError?
        var writeError: Error?
        let coordinator = NSFileCoordinator(filePresenter: filePresenter)
        coordinator.coordinate(
            writingItemAt: url,
            options: .forReplacing,
            error: &coordinatorError
        ) { writeURL in
            do {
                try content.write(to: writeURL, atomically: true, encoding: .utf8)
            } catch {
                writeError = error
            }
        }
        if let error = writeError ?? coordinatorError { throw error }
    }

    /// Save raw text to disk (preserving user's exact formatting), then parse to update the model.
    /// Used by the text view — writes the user's text as-is, then syncs the in-memory model.
    public func saveRawText(_ text: String) throws {
        guard let url = documentURL else { return }

        var coordinatorError: NSError?
        var writeError: Error?
        let coordinator = NSFileCoordinator(filePresenter: filePresenter)
        coordinator.coordinate(
            writingItemAt: url,
            options: .forReplacing,
            error: &coordinatorError
        ) { writeURL in
            do {
                try text.write(to: writeURL, atomically: true, encoding: .utf8)
            } catch {
                writeError = error
            }
        }
        if let error = writeError ?? coordinatorError { throw error }

        let parsed = SlideshowParser().parse(text)

        let prevFilename = selectedSlide?.section.images.first?.filename
        let prevCaption = selectedSlide?.section.caption
        let prevIndex = selectedIndex

        document = parsed
        let folderURL = url.deletingLastPathComponent()
        let availableFiles = (try? FileManager.default.contentsOfDirectory(
            at: folderURL, includingPropertiesForKeys: nil
        ))?.map(\.lastPathComponent) ?? []

        slides = parsed.slides.map { section in
            let slide = Slide(section: section)
            slide.resolveImageURLs(relativeTo: folderURL, availableFiles: availableFiles)
            return slide
        }

        restoreSelection(
            prevFilename: prevFilename,
            prevCaption: prevCaption,
            prevIndex: prevIndex
        )
    }

    // MARK: - File watching

    /// Start watching `documentURL` for external changes.
    /// Creates an `NSFilePresenter` and registers it with `NSFileCoordinator`.
    public func startWatching() {
        guard let docURL = documentURL else { return }
        stopWatching()
        let presenter = DocumentFilePresenter(url: docURL) { [weak self] in
            Task { @MainActor [weak self] in
                await self?.reload()
            }
        }
        NSFileCoordinator.addFilePresenter(presenter)
        filePresenter = presenter
    }

    /// Stop watching for external changes.
    public func stopWatching() {
        guard let presenter = filePresenter else { return }
        NSFileCoordinator.removeFilePresenter(presenter)
        filePresenter = nil
    }

    /// Reload the slideshow from disk, preserving the current selection.
    /// Skips reload if the parsed document is unchanged.
    public func reload() async {
        guard let docURL = documentURL else { return }
        let scanner = FolderScanner()
        guard let result = try? await scanner.scan(documentURL: docURL) else { return }
        guard let newDoc = result.document, newDoc != document else { return }

        let prevFilename = selectedSlide?.section.images.first?.filename
        let prevCaption = selectedSlide?.section.caption
        let prevIndex = selectedIndex

        document = newDoc
        slides = result.slides

        restoreSelection(
            prevFilename: prevFilename,
            prevCaption: prevCaption,
            prevIndex: prevIndex
        )
    }

    /// Restore selection after reload, using best-match strategy.
    /// Priority: filename match → caption match → same index → first slide.
    private func restoreSelection(
        prevFilename: String?,
        prevCaption: String?,
        prevIndex: Int?
    ) {
        if let filename = prevFilename,
           let match = slides.first(where: {
               $0.section.images.first?.filename == filename
           }) {
            selectedSlideID = match.id
            return
        }
        if let caption = prevCaption,
           let match = slides.first(where: { $0.section.caption == caption }) {
            selectedSlideID = match.id
            return
        }
        if let idx = prevIndex, !slides.isEmpty {
            let clampedIdx = min(idx, slides.count - 1)
            selectedSlideID = slides[clampedIdx].id
            return
        }
        selectedSlideID = slides.first?.id
    }

    // MARK: - Slide operations

    /// Remove a slide from the slideshow. Does NOT delete image files.
    /// The slide is removed from the presentation; the image stays in the folder.
    public func removeSlide(_ slide: Slide) {
        let wasSelected = slide.id == selectedSlideID
        let removedIndex = slides.firstIndex { $0.id == slide.id }

        slides.removeAll { $0.id == slide.id }

        if wasSelected {
            if let idx = removedIndex {
                let newIdx = min(idx, slides.count - 1)
                selectedSlideID = newIdx >= 0 ? slides[newIdx].id : nil
            } else {
                selectedSlideID = nil
            }
        }

        try? save()
    }

    /// Add images from external URLs into the slideshow folder.
    /// Copies files to the folder, creates slide entries, and saves.
    public func addImages(from urls: [URL]) {
        guard let folderURL else { return }
        let fm = FileManager.default
        var existingNames = Set(
            (try? fm.contentsOfDirectory(at: folderURL, includingPropertiesForKeys: nil))?
                .map(\.lastPathComponent) ?? []
        )

        for url in urls {
            let didStartAccessing = url.startAccessingSecurityScopedResource()
            defer { if didStartAccessing { url.stopAccessingSecurityScopedResource() } }

            let name = deconflictedName(url.lastPathComponent, existing: existingNames)
            let dest = folderURL.appending(path: name)
            guard (try? fm.copyItem(at: url, to: dest)) != nil else { continue }

            let section = SlideSection(
                images: [SlideImage(filename: name)]
            )
            let slide = Slide(section: section)
            slide.resolveImageURLs(relativeTo: folderURL)

            if let rv = try? dest.resourceValues(forKeys: [.fileSizeKey]),
               let size = rv.fileSize {
                slide.fileSize = Int64(size)
            }

            slides.append(slide)
            existingNames.insert(name)
        }

        try? save()
    }

    /// Move a slide up or down by one position. Saves automatically.
    public func moveSlide(_ slide: Slide, direction: Int) {
        guard let idx = slides.firstIndex(where: { $0.id == slide.id }) else { return }
        let newIdx = idx + direction
        guard newIdx >= 0, newIdx < slides.count else { return }
        slides.swapAt(idx, newIdx)
        try? save()
    }

    // MARK: - Helpers

    /// Generate a unique filename by appending " 2", " 3", etc. if needed.
    private func deconflictedName(
        _ filename: String,
        existing: Set<String>
    ) -> String {
        guard existing.contains(filename) else { return filename }
        let name = (filename as NSString).deletingPathExtension
        let ext = (filename as NSString).pathExtension
        var counter = 2
        while true {
            let candidate = ext.isEmpty ? "\(name) \(counter)" : "\(name) \(counter).\(ext)"
            if !existing.contains(candidate) { return candidate }
            counter += 1
        }
    }
}
