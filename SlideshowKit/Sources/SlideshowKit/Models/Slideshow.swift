import Foundation
import Observation

/// The top-level document model: a folder of slides.
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

    /// Remove a slide from the slideshow and delete its files from disk.
    public func removeSlide(_ slide: Slide) {
        slides.removeAll { $0.id == slide.id }
        try? FileManager.default.removeItem(at: slide.fileURL)
        if FileManager.default.fileExists(atPath: slide.sidecarURL.path(percentEncoded: false)) {
            try? FileManager.default.removeItem(at: slide.sidecarURL)
        }
    }

    /// Move a slide up or down by one position.
    public func moveSlide(_ slide: Slide, direction: Int) {
        guard let idx = slides.firstIndex(where: { $0.id == slide.id }) else { return }
        let newIdx = idx + direction
        guard newIdx >= 0, newIdx < slides.count else { return }
        slides.swapAt(idx, newIdx)
    }
}
