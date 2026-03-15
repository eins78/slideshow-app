import Foundation

/// A single image reference within a slide section.
public struct SlideImage: Equatable, Sendable {
    public var filename: String
    public var altText: String?

    public init(filename: String, altText: String? = nil) {
        self.filename = filename
        self.altText = altText
    }

    /// Filename without extension, for display purposes.
    public var displayFilename: String {
        (filename as NSString).deletingPathExtension
    }
}

/// Parsed content of one slide section (between `---` separators).
public struct SlideSection: Equatable, Sendable {
    public var caption: String?
    public var captionLevel: Int?
    public var images: [SlideImage]
    public var source: String?
    public var notes: String
    public var unrecognizedContent: String?

    public init(
        caption: String? = nil,
        captionLevel: Int? = nil,
        images: [SlideImage] = [],
        source: String? = nil,
        notes: String = "",
        unrecognizedContent: String? = nil
    ) {
        self.caption = caption
        self.captionLevel = captionLevel
        self.images = images
        self.source = source
        self.notes = notes
        self.unrecognizedContent = unrecognizedContent
    }

    public var displayName: String {
        if let caption, !caption.isEmpty { return caption }
        if let first = images.first { return first.displayFilename }
        return "Untitled Slide"
    }

    public var primarySource: String? {
        source?.components(separatedBy: "\n").first
    }

    public var secondarySourceLines: [String] {
        guard let source else { return [] }
        let lines = source.components(separatedBy: "\n")
        return lines.count > 1 ? Array(lines.dropFirst()) : []
    }
}

/// Transient state for live preview during text editing.
/// Not persisted — set by the text editor, cleared when leaving text mode.
public struct LivePreview: Equatable, Sendable {
    public var slideSection: SlideSection?
    public var slideIndex: Int?
    public var imageURL: URL?

    public init(
        slideSection: SlideSection? = nil,
        slideIndex: Int? = nil,
        imageURL: URL? = nil
    ) {
        self.slideSection = slideSection
        self.slideIndex = slideIndex
        self.imageURL = imageURL
    }
}
