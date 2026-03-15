import Foundation

/// Parsed representation of an entire `slideshow.md` file.
public struct SlideshowDocument: Equatable, Sendable {
    /// Known format URL for identification.
    public static let formatURL = "https://example.com/slideshow/v1"

    /// Default filename when creating a new slideshow.
    public static let defaultFilename = "slideshow.md"

    /// YAML frontmatter fields. Always includes `format` key on write.
    public var frontmatter: [String: String]

    /// Presentation title (from first H1 heading).
    public var title: String?

    /// Opaque markdown blob from the header area (between H1 and first ---).
    /// Preserved verbatim on round-trip. Nil if no header content beyond the title.
    public var headerContent: String?

    /// Ordered slide sections.
    public var slides: [SlideSection]

    public init(
        frontmatter: [String: String] = [:],
        title: String? = nil,
        headerContent: String? = nil,
        slides: [SlideSection] = []
    ) {
        self.frontmatter = frontmatter
        self.title = title
        self.headerContent = headerContent
        self.slides = slides
    }
}
