import Foundation
import Yams

/// Writes `SlideshowDocument` values to markdown strings.
public struct SlideshowWriter: Sendable {

    public init() {}

    /// Write a SlideshowDocument to a markdown string.
    public func write(_ document: SlideshowDocument) -> String {
        var output = ""

        // 1. Frontmatter (always written, includes title)
        writeFrontmatter(document, to: &output)

        // 2. Header content
        if let headerContent = document.headerContent {
            output += "\n\(headerContent)\n"
        }

        // 4. Separator after header (needed even with 0 slides to preserve header
        //    content on round-trip — without it, header content becomes a slide)
        if !document.slides.isEmpty || document.headerContent != nil {
            output += "\n---\n"
        }

        // 5. Slides
        for (index, slide) in document.slides.enumerated() {
            if index > 0 {
                output += "\n---\n"
            }
            writeSlide(slide, to: &output)
        }

        // 6. Trailing separator
        if !document.slides.isEmpty {
            output += "\n---\n"
        }

        return output
    }

    /// Write a SlideshowDocument to a file URL (atomic).
    public func write(_ document: SlideshowDocument, to url: URL) throws {
        let content = write(document)
        try content.write(to: url, atomically: true, encoding: .utf8)
    }

    // MARK: - Frontmatter

    private func writeFrontmatter(
        _ document: SlideshowDocument,
        to output: inout String
    ) {
        var fields = document.frontmatter
        // Always include format key
        if fields[SlideshowDocument.formatKey] == nil {
            fields[SlideshowDocument.formatKey] = SlideshowDocument.formatURL
        }
        // Sync title into frontmatter
        if let title = document.title {
            fields[SlideshowDocument.titleKey] = title
        } else {
            fields.removeValue(forKey: SlideshowDocument.titleKey)
        }

        output += "---\n"
        if let yaml = try? Yams.dump(
            object: fields as Any,
            allowUnicode: true,
            sortKeys: true
        ) {
            output += yaml
        }
        output += "---\n"
    }

    // MARK: - Slide

    private func writeSlide(_ slide: SlideSection, to output: inout String) {
        var elements: [String] = []

        // Caption
        if let caption = slide.caption {
            let level = slide.captionLevel ?? 1
            let prefix = String(repeating: "#", count: level)
            elements.append("\(prefix) \(caption)")
        }

        // Images
        if !slide.images.isEmpty {
            let imageLines = slide.images.map { image in
                let filename = escapedFilename(image.filename)
                let alt = image.altText ?? ""
                return "![\(alt)](\(filename))"
            }
            elements.append(imageLines.joined(separator: "\n"))
        }

        // Source
        if let source = slide.source {
            let lines = source.components(separatedBy: "\n")
            let quoted = lines.map { "> \($0)" }.joined(separator: "\n")
            elements.append(quoted)
        }

        // Notes
        if !slide.notes.isEmpty {
            elements.append(slide.notes)
        }

        // Unrecognized content
        if let unrecognized = slide.unrecognizedContent {
            elements.append("### \(SlideshowDocument.unrecognizedHeading)\n\n\(unrecognized)")
        }

        // Join with single blank line between present elements
        output += "\n"
        output += elements.joined(separator: "\n\n")
        output += "\n"
    }

    // MARK: - Helpers

    /// Escape filenames that need angle brackets for CommonMark compatibility.
    private func escapedFilename(_ filename: String) -> String {
        let needsEscaping = filename.contains(" ")
            || filename.contains("(")
            || filename.contains(")")
        return needsEscaping ? "<\(filename)>" : filename
    }
}
