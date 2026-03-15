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
    /// The parsed document (frontmatter, title, header, slides).
    public var document: SlideshowDocument = SlideshowDocument()

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
            if filename.lowercased() != "slideshow" { return filename }
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

    /// Save the current slideshow to disk (atomic write).
    /// Syncs slide sections back to the document before writing.
    public func save() throws {
        guard let url = documentURL else { return }
        document.slides = slides.map(\.section)
        try SlideshowWriter().write(document, to: url)
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
