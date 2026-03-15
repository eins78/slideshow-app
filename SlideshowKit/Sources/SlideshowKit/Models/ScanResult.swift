import Foundation

/// Result of scanning a folder: slides and an optional slideshow document.
/// Not Sendable: contains [Slide] which is an @Observable class.
public struct ScanResult {
    /// Ordered list of slides from the document (or one per image if no document).
    public let slides: [Slide]
    /// Parsed slideshow document, if a `.md` file was found and parsed.
    public let document: SlideshowDocument?
    /// URL of the `.md` file that was parsed.
    public let documentURL: URL?
    /// Images in the folder not referenced in any slide.
    public let availableImages: [URL]

    public init(
        slides: [Slide],
        document: SlideshowDocument? = nil,
        documentURL: URL? = nil,
        availableImages: [URL] = []
    ) {
        self.slides = slides
        self.document = document
        self.documentURL = documentURL
        self.availableImages = availableImages
    }
}
