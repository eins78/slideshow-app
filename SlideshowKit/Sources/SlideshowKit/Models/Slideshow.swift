import Foundation
import Observation

/// The top-level document model: a folder of slides.
/// @MainActor: created and mutated by views, owns file I/O operations.
/// See: https://developer.apple.com/documentation/swiftui/model-data
@MainActor
@Observable
public final class Slideshow {
    /// The folder URL of the .slideshow bundle.
    public var folderURL: URL?
    /// Ordered list of slides.
    public var slides: [Slide] = []
    /// Currently selected slide ID.
    public var selectedSlideID: Slide.ID?

    public init(folderURL: URL? = nil) {
        self.folderURL = folderURL
    }

    /// Display name derived from the bundle name.
    public var name: String {
        folderURL?.deletingPathExtension().lastPathComponent ?? "Untitled"
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

    // MARK: - Slide operations
    // Design: file I/O lives on the model, not in views. Synchronous on @MainActor
    // by design — operations are fast (rename/copy single files, not batch processing).
    // Async would add complexity without measurable benefit for typical slideshow sizes.
    // See: https://developer.apple.com/documentation/swiftui/model-data

    /// Create an empty sidecar file for a slide.
    public func createSidecar(for slide: Slide) throws {
        let writer = SidecarWriter()
        let data = SidecarData(notes: "")
        try writer.write(data, to: slide.sidecarURL)
        slide.sidecar = data
    }

    /// Remove a slide from the slideshow and delete its files from disk.
    /// Uses try? intentionally — orphaned files are acceptable vs. blocking the user.
    public func removeSlide(_ slide: Slide) {
        let wasSelected = slide.id == selectedSlideID
        let removedIndex = slides.firstIndex { $0.id == slide.id }

        slides.removeAll { $0.id == slide.id }
        try? FileManager.default.removeItem(at: slide.fileURL)
        if FileManager.default.fileExists(atPath: slide.sidecarURL.path(percentEncoded: false)) {
            try? FileManager.default.removeItem(at: slide.sidecarURL)
        }

        if wasSelected {
            if let idx = removedIndex {
                let newIdx = min(idx, slides.count - 1)
                selectedSlideID = newIdx >= 0 ? slides[newIdx].id : nil
            } else {
                selectedSlideID = nil
            }
        }
    }

    /// Add images from external URLs into the slideshow folder.
    /// Incremental — no full re-scan, preserves loaded EXIF and selection.
    public func addImages(from urls: [URL]) {
        guard let folderURL else { return }
        let reorderer = FileReorderer()
        let parser = SidecarParser()
        let fm = FileManager.default
        var existingNames = Set(slides.map { $0.fileURL.lastPathComponent })

        for url in urls {
            guard url.startAccessingSecurityScopedResource() else { continue }
            defer { url.stopAccessingSecurityScopedResource() }

            let name = reorderer.deconflictedName(url.lastPathComponent, existing: existingNames)
            let dest = folderURL.appending(path: name)
            guard (try? fm.copyItem(at: url, to: dest)) != nil else { continue }

            let slide = Slide(fileURL: dest)
            if let rv = try? dest.resourceValues(forKeys: [.fileSizeKey]),
               let size = rv.fileSize {
                slide.fileSize = Int64(size)
            }
            let sidecarURL = dest.appendingPathExtension("md")
            if fm.fileExists(atPath: sidecarURL.path(percentEncoded: false)) {
                slide.sidecar = parser.parse(url: sidecarURL)
            }
            slides.append(slide)
            existingNames.insert(name)
        }
    }

    /// Write a slide's sidecar data to disk.
    public func saveSidecar(for slide: Slide) {
        guard let sidecar = slide.sidecar else { return }
        let writer = SidecarWriter()
        try? writer.write(sidecar, to: slide.sidecarURL)
    }

    /// Move a slide up or down by one position.
    public func moveSlide(_ slide: Slide, direction: Int) {
        guard let idx = slides.firstIndex(where: { $0.id == slide.id }) else { return }
        let newIdx = idx + direction
        guard newIdx >= 0, newIdx < slides.count else { return }
        slides.swapAt(idx, newIdx)
    }

    /// Persist current slide order to disk by renaming files with `\d{3}--` prefixes.
    /// Uses FileReorderer's two-pass rename to avoid collisions.
    public func persistReorder() {
        guard let folderURL else { return }
        let reorderer = FileReorderer()
        let filenames = slides.map { $0.fileURL.lastPathComponent }
        guard let renames = try? reorderer.reorder(in: folderURL, orderedFilenames: filenames) else { return }
        for (oldURL, newURL) in renames {
            if let slide = slides.first(where: { $0.fileURL == oldURL }) {
                slide.fileURL = newURL
            }
        }
    }
}
