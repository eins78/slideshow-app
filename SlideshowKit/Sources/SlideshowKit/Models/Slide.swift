import Foundation
import Observation

/// A single slide in a slideshow — a section with 0-N images plus metadata.
/// Not @MainActor: created in background by FolderScanner, observed by views.
/// See: https://developer.apple.com/documentation/observation/observable()#Discussion
@Observable
public final class Slide: Identifiable {
    public let id: UUID
    public var section: SlideSection
    public var exif: EXIFData?
    public var fileSize: Int64?

    /// Resolved image URLs (set by Slideshow after loading).
    public var resolvedImageURLs: [URL] = []

    public init(id: UUID = UUID(), section: SlideSection = SlideSection()) {
        self.id = id
        self.section = section
    }

    // MARK: - Convenience

    public var displayName: String { section.displayName }

    public var primaryImageURL: URL? { resolvedImageURLs.first }

    /// Resolve image filenames to full URLs relative to a folder.
    /// Uses case-insensitive matching against actual files on disk.
    public func resolveImageURLs(
        relativeTo folderURL: URL,
        availableFiles: [String] = []
    ) {
        resolvedImageURLs = section.images.map { image in
            // Try case-insensitive match against available files
            if !availableFiles.isEmpty,
               let match = availableFiles.first(where: {
                   $0.caseInsensitiveCompare(image.filename) == .orderedSame
               }) {
                return folderURL.appendingPathComponent(match)
            }
            // Fallback to direct path (macOS is case-insensitive anyway)
            return folderURL.appendingPathComponent(image.filename)
        }
    }

    // MARK: - Editor bindings

    public var captionText: String {
        get { section.caption ?? "" }
        set { section.caption = newValue.isEmpty ? nil : newValue }
    }

    public var sourceText: String {
        get { section.source ?? "" }
        set { section.source = newValue.isEmpty ? nil : newValue }
    }

    public var notesText: String {
        get { section.notes }
        set { section.notes = newValue }
    }
}
