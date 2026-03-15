import Foundation
import Markdown
import Yams

/// Parses `slideshow.md` files into `SlideshowDocument` values.
public struct SlideshowParser: Sendable {

    public init() {}

    /// Parse a slideshow document from a string.
    public func parse(_ content: String) -> SlideshowDocument {
        let normalized = content.replacingOccurrences(of: "\r\n", with: "\n")
        let lines = normalized.components(separatedBy: "\n")

        // Step 1: Extract frontmatter
        let (frontmatter, bodyStartLine) = extractFrontmatter(lines)

        // Step 2: Parse remaining body with swift-markdown
        let bodyLines = Array(lines[bodyStartLine...])
        let body = bodyLines.joined(separator: "\n")
        let document = Document(parsing: body)

        // Step 3: Check if any ThematicBreak separators exist
        let hasAnySeparators = document.children.contains(where: { $0 is ThematicBreak })

        // Step 4: Split AST children by ThematicBreak
        // Section 0 is always the header (content before first ---).
        // Sections 1+ are slide sections. Empty slides are discarded.
        var allSections: [[any Markup]] = [[]]
        for child in document.children {
            if child is ThematicBreak {
                allSections.append([])
            } else {
                allSections[allSections.count - 1].append(child)
            }
        }

        // Step 5: Parse header and slides
        let title: String?
        let headerContent: String?
        let slides: [SlideSection]

        if !hasAnySeparators {
            // No separators: header is first H1 only, rest is single slide
            let allNodes = allSections.flatMap { $0 }
            let (parsedTitle, _, slideNodes) = parseHeaderNoSeparators(allNodes)
            title = parsedTitle
            headerContent = nil
            slides = slideNodes.isEmpty ? [] : [parseSlideSection(slideNodes)]
        } else {
            // Normal case: section 0 is header, sections 1+ are slides
            let headerNodes = allSections[0]
            let (parsedTitle, parsedHeader) = parseHeader(headerNodes)
            title = parsedTitle
            headerContent = parsedHeader

            // Discard empty slide sections (from leading/trailing ---)
            let slideSections = Array(allSections.dropFirst()).filter { section in
                section.contains { node in
                    let text = node.format().trimmingCharacters(in: .whitespacesAndNewlines)
                    return !text.isEmpty
                }
            }
            slides = slideSections.map { parseSlideSection($0) }
        }

        return SlideshowDocument(
            frontmatter: frontmatter,
            title: title,
            headerContent: headerContent,
            slides: slides
        )
    }

    /// Parse a slideshow document from a file URL.
    public func parse(url: URL) -> SlideshowDocument? {
        guard let content = try? String(contentsOf: url, encoding: .utf8) else {
            return nil
        }
        return parse(content)
    }

    /// Check if a file is a valid slideshow document.
    /// Returns true if: the file has `format:` matching our URL in frontmatter,
    /// OR the filename is "slideshow.md" (recognized by convention).
    /// Fast path: only reads frontmatter, does not parse the full document.
    public func isValidSlideshowFile(url: URL) -> Bool {
        let filename = url.deletingPathExtension().lastPathComponent
        if filename.lowercased() == SlideshowDocument.defaultStem { return true }
        guard let content = try? String(contentsOf: url, encoding: .utf8) else { return false }
        let lines = content.replacingOccurrences(of: "\r\n", with: "\n")
            .components(separatedBy: "\n")
        let (frontmatter, _) = extractFrontmatter(lines)
        return frontmatter[SlideshowDocument.formatKey] == SlideshowDocument.formatURL
    }

    // MARK: - Frontmatter

    /// Extract YAML frontmatter from the beginning of the file.
    /// Returns the parsed frontmatter dict and the line index where the body starts.
    private func extractFrontmatter(_ lines: [String]) -> ([String: String], Int) {
        guard !lines.isEmpty, lines[0].trimmingCharacters(in: .whitespaces) == "---" else {
            return ([:], 0)
        }

        // Scan for closing ---
        var closingLine: Int?
        for i in 1..<lines.count {
            if lines[i].trimmingCharacters(in: .whitespaces) == "---" {
                closingLine = i
                break
            }
        }

        guard let closing = closingLine else {
            // No closing delimiter — treat opening --- as slide separator
            return ([:], 0)
        }

        // Extract YAML content between delimiters
        let yamlLines = lines[1..<closing]
        let yamlString = yamlLines.joined(separator: "\n")

        // Parse YAML
        guard let yamlObject = try? Yams.load(yaml: yamlString),
              let dict = yamlObject as? [String: Any],
              !dict.isEmpty else {
            // Malformed or empty YAML — rewind
            return ([:], 0)
        }

        // Convert all values to strings for storage
        var frontmatter: [String: String] = [:]
        for (key, value) in dict {
            frontmatter[key] = "\(value)"
        }

        return (frontmatter, closing + 1)
    }

    // MARK: - Header

    /// Parse the header section (before first ---). Used when separators exist.
    private func parseHeader(
        _ nodes: [any Markup]
    ) -> (title: String?, headerContent: String?) {
        guard !nodes.isEmpty else { return (nil, nil) }

        var title: String?
        var contentNodes: [any Markup] = []

        for node in nodes {
            if title == nil, let heading = node as? Heading, heading.level == 1 {
                title = heading.plainText
            } else {
                contentNodes.append(node)
            }
        }

        let headerContent: String?
        if contentNodes.isEmpty {
            headerContent = nil
        } else {
            let text = contentNodes.map { $0.format() }.joined(separator: "\n\n")
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            headerContent = trimmed.isEmpty ? nil : trimmed
        }

        return (title, headerContent)
    }

    /// Parse header when no `---` separators exist.
    /// Header is limited to H1 only. Everything else becomes slide content.
    private func parseHeaderNoSeparators(
        _ nodes: [any Markup]
    ) -> (title: String?, headerContent: String?, slideNodes: [any Markup]) {
        var title: String?
        var slideNodes: [any Markup] = []

        for node in nodes {
            if title == nil, let heading = node as? Heading, heading.level == 1 {
                title = heading.plainText
            } else {
                slideNodes.append(node)
            }
        }

        return (title, nil, slideNodes)
    }

    // MARK: - Slide Section

    /// Parse a single slide section into a SlideSection.
    private func parseSlideSection(_ nodes: [any Markup]) -> SlideSection {
        var caption: String?
        var captionLevel: Int?
        var images: [SlideImage] = []
        var source: String?
        var notesParts: [String] = []
        var unrecognizedParts: [String] = []
        var inUnrecognizedBlob = false
        var foundFirstBlockquote = false

        for node in nodes {
            // Once we hit "Unrecognized content" heading, everything after is opaque
            if inUnrecognizedBlob {
                unrecognizedParts.append(node.format())
                continue
            }

            if let heading = node as? Heading {
                if heading.plainText == SlideshowDocument.unrecognizedHeading {
                    inUnrecognizedBlob = true
                    continue
                }
                if caption == nil {
                    caption = heading.plainText
                    captionLevel = heading.level
                } else {
                    unrecognizedParts.append(node.format())
                }
                continue
            }

            if let blockquote = node as? BlockQuote {
                if !foundFirstBlockquote {
                    foundFirstBlockquote = true
                    source = blockquoteText(blockquote)
                } else {
                    unrecognizedParts.append(node.format())
                }
                continue
            }

            if let paragraph = node as? Paragraph {
                let (extractedImages, remainingText) = extractImages(from: paragraph)
                images.append(contentsOf: extractedImages)
                if let text = remainingText {
                    notesParts.append(text)
                }
                continue
            }

            // Rich notes: lists, tables, code blocks
            if node is UnorderedList || node is OrderedList
                || node is Table || node is CodeBlock {
                notesParts.append(node.format())
                continue
            }

            // Everything else → unrecognized
            unrecognizedParts.append(node.format())
        }

        let notes = notesParts.joined(separator: "\n\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let unrecognized: String?
        if unrecognizedParts.isEmpty {
            unrecognized = nil
        } else {
            let text = unrecognizedParts.joined(separator: "\n\n")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            unrecognized = text.isEmpty ? nil : text
        }

        return SlideSection(
            caption: caption,
            captionLevel: captionLevel,
            images: images,
            source: source,
            notes: notes,
            unrecognizedContent: unrecognized
        )
    }

    // MARK: - Image Extraction

    /// Extract Image nodes from a Paragraph.
    /// Returns extracted SlideImages and the remaining paragraph text (nil if fully consumed).
    private func extractImages(
        from paragraph: Paragraph
    ) -> (images: [SlideImage], remainingText: String?) {
        var images: [SlideImage] = []
        var hasNonImageContent = false

        for child in paragraph.children {
            if let image = child as? Image {
                guard let source = image.source else { continue }
                // Reject paths with separators or traversal
                guard !source.contains("/"), !source.contains("\\"),
                      !source.contains("..") else { continue }
                // Strip angle brackets if present
                let filename = source.trimmingCharacters(in: CharacterSet(charactersIn: "<>"))
                let altText = image.plainText.isEmpty ? nil : image.plainText
                images.append(SlideImage(filename: filename, altText: altText))
            } else if child is SoftBreak || child is LineBreak {
                // Whitespace between images — don't count as content
                continue
            } else {
                hasNonImageContent = true
            }
        }

        if images.isEmpty {
            // No images found — entire paragraph is notes
            return ([], paragraph.format())
        }

        if hasNonImageContent {
            // Mixed paragraph — extract images, return remaining text
            let nonImageChildren = paragraph.children
                .filter { !($0 is Image) }
                .compactMap { $0 as? any InlineMarkup }
            let rebuilt = Paragraph(nonImageChildren)
            let text = rebuilt.format().trimmingCharacters(in: .whitespacesAndNewlines)
            return (images, text.isEmpty ? nil : text)
        }

        // Image-only paragraph — fully consumed
        return (images, nil)
    }

    // MARK: - Helpers

    /// Extract plain text from a blockquote (stripping `> ` prefixes).
    private func blockquoteText(_ blockquote: BlockQuote) -> String {
        blockquote.children.compactMap { child -> String? in
            if let paragraph = child as? Paragraph {
                return paragraph.plainText
            }
            return child.format()
        }.joined(separator: "\n")
    }
}

// MARK: - swift-markdown helpers

private extension Heading {
    var plainText: String {
        children.compactMap { ($0 as? any InlineMarkup)?.plainText }
            .joined()
    }
}

private extension Paragraph {
    var plainText: String {
        children.compactMap { ($0 as? any InlineMarkup)?.plainText }
            .joined()
    }
}

private extension InlineMarkup {
    var plainText: String {
        if let text = self as? Markdown.Text {
            return text.string
        }
        if self is SoftBreak || self is LineBreak {
            return " "
        }
        if let image = self as? Image {
            return image.plainText
        }
        // Recurse into children for emphasis, strong, etc.
        return children.compactMap { ($0 as? any InlineMarkup)?.plainText }
            .joined()
    }
}

private extension Image {
    var plainText: String {
        children.compactMap { child -> String? in
            if let text = child as? Markdown.Text { return text.string }
            return nil
        }.joined()
    }
}
