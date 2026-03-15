# slideshow.md Format Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace per-image sidecar files and `slideshow.yml` with a single `slideshow.md` markdown project file, using swift-markdown for AST-based parsing.

**Architecture:** New `SlideshowParser` reads markdown via swift-markdown AST, extracting headings (captions), images, blockquotes (source), paragraphs/lists/tables/code (notes), and opaque blobs (unrecognized content). `SlideshowWriter` serializes back to normalized markdown. Old sidecar/YAML infrastructure is deleted. The `Slide` model changes from 1:1 with an image to a document section with 0-N images.

**Tech Stack:** Swift 6, swift-markdown (AST parsing), Yams (frontmatter YAML), Swift Testing (`@Test`, `#expect`, `#require`)

**Spec:** `docs/superpowers/specs/2026-03-15-slideshow-md-format-design.md`

---

## File Structure

### New files

| File | Responsibility |
|------|---------------|
| `SlideshowKit/Sources/SlideshowKit/Models/SlideData.swift` | `SlideImage` and `SlideSection` value types |
| `SlideshowKit/Sources/SlideshowKit/Models/SlideshowDocument.swift` | `SlideshowDocument` — parsed representation of entire `slideshow.md` |
| `SlideshowKit/Sources/SlideshowKit/Services/SlideshowParser.swift` | Reads `slideshow.md` → `SlideshowDocument` |
| `SlideshowKit/Sources/SlideshowKit/Services/SlideshowWriter.swift` | Writes `SlideshowDocument` → `slideshow.md` string |
| `SlideshowKit/Tests/SlideshowKitTests/SlideDataTests.swift` | Tests for SlideImage/SlideSection |
| `SlideshowKit/Tests/SlideshowKitTests/SlideshowParserTests.swift` | Comprehensive parser tests |
| `SlideshowKit/Tests/SlideshowKitTests/SlideshowWriterTests.swift` | Writer + round-trip tests |
| `SlideshowKit/Tests/SlideshowKitTests/Fixtures/test-slideshow/slideshow.md` | Test fixture in new format |

### Modified files

| File | Changes |
|------|---------|
| `SlideshowKit/Sources/SlideshowKit/Models/Slide.swift` | Replace `fileURL`/`SidecarData` with `SlideSection`-based properties, support 0-N images |
| `SlideshowKit/Sources/SlideshowKit/Models/Slideshow.swift` | Replace sidecar/reorder operations with document-level save, add `documentURL` |
| `SlideshowKit/Sources/SlideshowKit/Models/ProjectFile.swift` | Add `format` field, change `filename` to `"slideshow.md"` |
| `SlideshowKit/Sources/SlideshowKit/Models/ScanResult.swift` | Replace `projectFile` with `document: SlideshowDocument?` |
| `SlideshowKit/Sources/SlideshowKit/Services/FolderScanner.swift` | Simplify: discover images only (no sidecar matching), parse `slideshow.md` |
| `SlideshowKit/Tests/SlideshowKitTests/SlideTests.swift` | Adapt to new Slide model |
| `SlideshowKit/Tests/SlideshowKitTests/FolderScannerTests.swift` | Adapt to new scanning behavior |
| `Slideshow/SlideshowApp.swift` | Update `openSlideshow` to handle `.md` file opening |
| `Slideshow/Views/ContentView.swift` | Remove "Create Sidecar" menu, adapt toolbar |
| `Slideshow/Views/SlideListPanel.swift` | Remove sidecar context menu items, adapt to multi-image |
| `Slideshow/Views/EditorPanel.swift` | Save triggers document write instead of sidecar write |
| `Slideshow/Views/PreviewPanel.swift` | Adapt to `slide.primaryImageURL` |
| `Slideshow/Views/FileInfoPanel.swift` | Adapt to `slide.images.first` |
| `Slideshow/Views/PresenterView.swift` | Adapt to `slide.primaryImageURL` |
| `Slideshow/Views/AudienceView.swift` | Adapt to `slide.primaryImageURL` |
| `Slideshow/Views/SlideRowView.swift` | Adapt to new display name |
| `project.yml` | No changes needed (SlideshowKit already depends on swift-markdown) |

### Deleted files

| File | Reason |
|------|--------|
| `SlideshowKit/Sources/SlideshowKit/Models/SidecarData.swift` | Replaced by `SlideData.swift` |
| `SlideshowKit/Sources/SlideshowKit/Services/SidecarParser.swift` | Replaced by `SlideshowParser.swift` |
| `SlideshowKit/Sources/SlideshowKit/Services/SidecarWriter.swift` | Replaced by `SlideshowWriter.swift` |
| `SlideshowKit/Sources/SlideshowKit/Services/ProjectFileParser.swift` | Merged into `SlideshowParser.swift` |
| `SlideshowKit/Sources/SlideshowKit/Services/ProjectFileWriter.swift` | Merged into `SlideshowWriter.swift` |
| `SlideshowKit/Sources/SlideshowKit/Services/FileReorderer.swift` | Eliminated — order is file position |
| `SlideshowKit/Tests/SlideshowKitTests/SidecarParserTests.swift` | Old format |
| `SlideshowKit/Tests/SlideshowKitTests/SidecarWriterTests.swift` | Old format |
| `SlideshowKit/Tests/SlideshowKitTests/SidecarDataTests.swift` | Old format |
| `SlideshowKit/Tests/SlideshowKitTests/ProjectFileParserTests.swift` | Old format |
| `SlideshowKit/Tests/SlideshowKitTests/ProjectFileWriterTests.swift` | Old format |
| `SlideshowKit/Tests/SlideshowKitTests/FileReordererTests.swift` | Old format |

---

## Chunk 1: Data Models + Parser

### Task 1: SlideImage and SlideSection value types

**Files:**
- Create: `SlideshowKit/Sources/SlideshowKit/Models/SlideData.swift`
- Create: `SlideshowKit/Tests/SlideshowKitTests/SlideDataTests.swift`

- [ ] **Step 1: Write failing tests for SlideImage**

```swift
// SlideDataTests.swift
import Testing
@testable import SlideshowKit

@Suite("SlideImage")
struct SlideImageTests {
    @Test func displayFilename() {
        let image = SlideImage(filename: "sunset.jpg", altText: nil)
        #expect(image.displayFilename == "sunset")
    }

    @Test func displayFilenameStripsExtension() {
        let image = SlideImage(filename: "001--golden-hour.heic", altText: nil)
        #expect(image.displayFilename == "001--golden-hour")
    }

    @Test func altTextPreserved() {
        let image = SlideImage(filename: "photo.jpg", altText: "A beautiful sunset")
        #expect(image.altText == "A beautiful sunset")
    }

    @Test func equatable() {
        let a = SlideImage(filename: "photo.jpg", altText: "alt")
        let b = SlideImage(filename: "photo.jpg", altText: "alt")
        #expect(a == b)
    }
}
```

- [ ] **Step 2: Run tests — expect FAIL (types don't exist)**

```bash
cd SlideshowKit && swift test --filter SlideDataTests
```

- [ ] **Step 3: Implement SlideImage**

```swift
// SlideData.swift
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
```

- [ ] **Step 4: Run tests — expect PASS**

```bash
cd SlideshowKit && swift test --filter SlideImageTests
```

- [ ] **Step 5: Write failing tests for SlideSection**

```swift
@Suite("SlideSection")
struct SlideSectionTests {
    @Test func defaultValues() {
        let section = SlideSection()
        #expect(section.caption == nil)
        #expect(section.captionLevel == nil)
        #expect(section.images.isEmpty)
        #expect(section.source == nil)
        #expect(section.notes == "")
        #expect(section.unrecognizedContent == nil)
    }

    @Test func displayNameUsesCaption() {
        var section = SlideSection()
        section.caption = "Golden hour"
        #expect(section.displayName == "Golden hour")
    }

    @Test func displayNameFallsBackToFirstImage() {
        var section = SlideSection()
        section.images = [SlideImage(filename: "sunset.jpg")]
        #expect(section.displayName == "sunset")
    }

    @Test func displayNameFallsBackToUntitled() {
        let section = SlideSection()
        #expect(section.displayName == "Untitled Slide")
    }

    @Test func primarySource() {
        var section = SlideSection()
        section.source = "© Max 2024\nDownloaded from Lightroom"
        #expect(section.primarySource == "© Max 2024")
    }

    @Test func secondarySourceLines() {
        var section = SlideSection()
        section.source = "© Max 2024\nLine 2\nLine 3"
        #expect(section.secondarySourceLines == ["Line 2", "Line 3"])
    }

    @Test func equatable() {
        let a = SlideSection(caption: "Test", images: [SlideImage(filename: "a.jpg")])
        let b = SlideSection(caption: "Test", images: [SlideImage(filename: "a.jpg")])
        #expect(a == b)
    }
}
```

- [ ] **Step 6: Run tests — expect FAIL**

```bash
cd SlideshowKit && swift test --filter SlideSectionTests
```

- [ ] **Step 7: Implement SlideSection**

```swift
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
```

- [ ] **Step 8: Run tests — expect PASS**

```bash
cd SlideshowKit && swift test --filter SlideDataTests
```

- [ ] **Step 9: Commit**

```bash
git add SlideshowKit/Sources/SlideshowKit/Models/SlideData.swift \
       SlideshowKit/Tests/SlideshowKitTests/SlideDataTests.swift
git commit -m "add SlideImage and SlideSection value types"
```

---

### Task 2: SlideshowDocument model

**Files:**
- Create: `SlideshowKit/Sources/SlideshowKit/Models/SlideshowDocument.swift`

- [ ] **Step 1: Write SlideshowDocument**

No TDD for this — it's a plain data container with no logic beyond a format constant.

```swift
// SlideshowDocument.swift
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
```

- [ ] **Step 2: Run full test suite to verify no breakage**

```bash
cd SlideshowKit && swift test
```

- [ ] **Step 3: Commit**

```bash
git add SlideshowKit/Sources/SlideshowKit/Models/SlideshowDocument.swift
git commit -m "add SlideshowDocument model"
```

---

### Task 3: SlideshowParser — frontmatter extraction

**Files:**
- Create: `SlideshowKit/Sources/SlideshowKit/Services/SlideshowParser.swift`
- Create: `SlideshowKit/Tests/SlideshowKitTests/SlideshowParserTests.swift`

- [ ] **Step 1: Write failing tests for frontmatter parsing**

```swift
// SlideshowParserTests.swift
import Testing
@testable import SlideshowKit

@Suite("SlideshowParser")
struct SlideshowParserTests {

    let parser = SlideshowParser()

    // MARK: - Frontmatter

    @Test func parsesFrontmatter() {
        let input = """
        ---
        format: https://example.com/slideshow/v1
        theme: dark
        ---

        # My Title
        """
        let doc = parser.parse(input)
        #expect(doc.frontmatter["format"] == "https://example.com/slideshow/v1")
        #expect(doc.frontmatter["theme"] == "dark")
    }

    @Test func missingFrontmatterIsValid() {
        let input = """
        # My Title

        ---

        ### Slide 1
        """
        let doc = parser.parse(input)
        #expect(doc.frontmatter.isEmpty)
        #expect(doc.title == "My Title")
    }

    @Test func malformedFrontmatterTreatedAsSlide() {
        // If --- on line 1 but content isn't valid YAML with keys,
        // treat it as a slide separator
        let input = """
        ---

        ### Slide 1

        ---
        """
        let doc = parser.parse(input)
        #expect(doc.frontmatter.isEmpty)
        #expect(doc.slides.count >= 1)
    }

    @Test func frontmatterWithoutClosingDelimiter() {
        // No closing --- means the opening --- is a slide separator
        let input = """
        ---
        ### Slide 1
        ![](photo.jpg)
        """
        let doc = parser.parse(input)
        #expect(doc.frontmatter.isEmpty)
    }

    @Test func preservesUnknownFrontmatterKeys() {
        let input = """
        ---
        format: https://example.com/slideshow/v1
        custom_field: hello
        ---
        """
        let doc = parser.parse(input)
        #expect(doc.frontmatter["custom_field"] == "hello")
    }
}
```

- [ ] **Step 2: Run tests — expect FAIL (SlideshowParser doesn't exist)**

```bash
cd SlideshowKit && swift test --filter SlideshowParserTests
```

- [ ] **Step 3: Implement SlideshowParser scaffold with frontmatter extraction**

```swift
// SlideshowParser.swift
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
        var sections: [[any Markup]] = [[]]
        for child in document.children {
            if child is ThematicBreak {
                sections.append([])
            } else {
                sections[sections.count - 1].append(child)
            }
        }

        // Discard empty sections (leading/trailing)
        sections = sections.filter { section in
            section.contains { node in
                let text = nodeToMarkdown(node).trimmingCharacters(in: .whitespacesAndNewlines)
                return !text.isEmpty
            }
        }

        // Step 5: Parse header and slides
        let title: String?
        let headerContent: String?
        let slides: [SlideSection]

        if !hasAnySeparators {
            // No separators: header is first H1 only, rest is single slide
            let (parsedTitle, _, slideNodes) = parseHeaderNoSeparators(
                sections.isEmpty ? [] : sections[0]
            )
            title = parsedTitle
            headerContent = nil
            slides = slideNodes.isEmpty ? [] : [parseSlideSection(slideNodes)]
        } else {
            // Normal case: first section is header, rest are slides
            let (parsedTitle, parsedHeader) = parseHeader(sections.isEmpty ? [] : sections[0])
            title = parsedTitle
            headerContent = parsedHeader
            slides = sections.dropFirst().map { parseSlideSection($0) }
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
    public func isValidSlideshowFile(url: URL) -> Bool {
        let filename = url.deletingPathExtension().lastPathComponent
        if filename.lowercased() == "slideshow" { return true }
        guard let doc = parse(url: url) else { return false }
        return doc.frontmatter["format"] == SlideshowDocument.formatURL
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
            let text = contentNodes.map { nodeToMarkdown($0) }.joined(separator: "\n\n")
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
                unrecognizedParts.append(nodeToMarkdown(node))
                continue
            }

            if let heading = node as? Heading {
                if heading.plainText == "Unrecognized content" {
                    inUnrecognizedBlob = true
                    continue
                }
                if caption == nil {
                    caption = heading.plainText
                    captionLevel = heading.level
                } else {
                    unrecognizedParts.append(nodeToMarkdown(node))
                }
                continue
            }

            if let blockquote = node as? BlockQuote {
                if !foundFirstBlockquote {
                    foundFirstBlockquote = true
                    source = blockquoteText(blockquote)
                } else {
                    unrecognizedParts.append(nodeToMarkdown(node))
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
                notesParts.append(nodeToMarkdown(node))
                continue
            }

            // Everything else → unrecognized
            unrecognizedParts.append(nodeToMarkdown(node))
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
            return ([], nodeToMarkdown(paragraph))
        }

        if hasNonImageContent {
            // Mixed paragraph — extract images, return remaining text.
            // Build a new Paragraph from non-Image children to preserve whitespace.
            let nonImageChildren = paragraph.children.filter { !($0 is Image) }
            let rebuilt = Paragraph(nonImageChildren.map { $0 as! any InlineMarkup })
            let text = rebuilt.format().trimmingCharacters(in: .whitespacesAndNewlines)
            return (images, text.isEmpty ? nil : text)
        }

        // Image-only paragraph — fully consumed
        return (images, nil)
    }

    // MARK: - Helpers

    /// Render an AST node back to markdown string.
    private func nodeToMarkdown(_ node: any Markup) -> String {
        node.format()
    }

    /// Extract plain text from a blockquote (stripping `> ` prefixes).
    private func blockquoteText(_ blockquote: BlockQuote) -> String {
        // The children of a BlockQuote are typically Paragraphs
        blockquote.children.compactMap { child -> String? in
            if let paragraph = child as? Paragraph {
                return paragraph.plainText
            }
            return nodeToMarkdown(child)
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
```

**Note:** The `Heading.plainText` and `Paragraph.plainText` extensions use recursive child traversal to extract text from inline markup (handles **bold**, *italic*, etc. within headings/paragraphs).

**Implementation note on verbatim preservation:** `MarkupFormatter` may normalize whitespace slightly when re-rendering AST nodes to markdown. For notes and structured content (caption, source), minor normalization is acceptable. For the unrecognized content blob, consider using `Markup.range` (source ranges) to extract the original raw text from the input string instead of re-serializing. This provides byte-for-byte preservation. The parser should store the original input lines and use them when extracting opaque blobs. If `MarkupFormatter` round-trips prove acceptable in tests, the source-range approach can be deferred.

- [ ] **Step 4: Run tests — expect PASS**

```bash
cd SlideshowKit && swift test --filter SlideshowParserTests
```

- [ ] **Step 5: Commit**

```bash
git add SlideshowKit/Sources/SlideshowKit/Services/SlideshowParser.swift \
       SlideshowKit/Tests/SlideshowKitTests/SlideshowParserTests.swift
git commit -m "add SlideshowParser with frontmatter extraction"
```

---

### Task 4: SlideshowParser — header and slide section parsing tests

**Files:**
- Modify: `SlideshowKit/Tests/SlideshowKitTests/SlideshowParserTests.swift`

- [ ] **Step 1: Add header parsing tests**

```swift
    // MARK: - Header

    @Test func parsesTitle() {
        let input = """
        ---
        format: https://example.com/slideshow/v1
        ---

        # Paintings That Tell Secrets

        ---

        ### Slide 1
        """
        let doc = parser.parse(input)
        #expect(doc.title == "Paintings That Tell Secrets")
    }

    @Test func titleFallsBackToNil() {
        let input = """
        ---
        format: https://example.com/slideshow/v1
        ---

        ---

        ### Slide 1
        """
        let doc = parser.parse(input)
        #expect(doc.title == nil)
    }

    @Test func preservesHeaderContent() {
        let input = """
        ---
        format: https://example.com/slideshow/v1
        ---

        # My Title

        Some introductory text.

        ---

        ### Slide 1
        """
        let doc = parser.parse(input)
        #expect(doc.title == "My Title")
        #expect(doc.headerContent != nil)
        #expect(doc.headerContent?.contains("introductory text") == true)
    }
```

- [ ] **Step 2: Add slide section parsing tests**

```swift
    // MARK: - Slide sections

    @Test func parsesSlideCaption() {
        let input = """
        ---
        format: https://example.com/slideshow/v1
        ---

        ---

        ### Golden hour, Wollishofen

        ---
        """
        let doc = parser.parse(input)
        #expect(doc.slides.count == 1)
        #expect(doc.slides[0].caption == "Golden hour, Wollishofen")
        #expect(doc.slides[0].captionLevel == 3)
    }

    @Test func parsesAnyCaptionLevel() {
        let input = """
        ---
        format: https://example.com/slideshow/v1
        ---

        ---

        ## Level Two Caption

        ---

        ##### Level Five Caption

        ---
        """
        let doc = parser.parse(input)
        #expect(doc.slides[0].caption == "Level Two Caption")
        #expect(doc.slides[0].captionLevel == 2)
        #expect(doc.slides[1].caption == "Level Five Caption")
        #expect(doc.slides[1].captionLevel == 5)
    }

    @Test func parsesImages() {
        let input = """
        ---
        format: https://example.com/slideshow/v1
        ---

        ---

        ![A sunset](sunset.jpg)

        ---
        """
        let doc = parser.parse(input)
        #expect(doc.slides[0].images.count == 1)
        #expect(doc.slides[0].images[0].filename == "sunset.jpg")
        #expect(doc.slides[0].images[0].altText == "A sunset")
    }

    @Test func parsesMultipleImages() {
        let input = """
        ---
        format: https://example.com/slideshow/v1
        ---

        ---

        ![](morning.jpg)
        ![](noon.jpg)
        ![](evening.jpg)

        ---
        """
        let doc = parser.parse(input)
        #expect(doc.slides[0].images.count == 3)
        #expect(doc.slides[0].images[0].filename == "morning.jpg")
        #expect(doc.slides[0].images[1].filename == "noon.jpg")
        #expect(doc.slides[0].images[2].filename == "evening.jpg")
    }

    @Test func parsesSource() {
        let input = """
        ---
        format: https://example.com/slideshow/v1
        ---

        ---

        > © Max Albrecht 2024
        > Downloaded from Lightroom CC

        ---
        """
        let doc = parser.parse(input)
        #expect(doc.slides[0].source?.contains("Max Albrecht") == true)
        #expect(doc.slides[0].source?.contains("Lightroom") == true)
    }

    @Test func parsesNotes() {
        let input = """
        ---
        format: https://example.com/slideshow/v1
        ---

        ---

        My presenter notes here.

        Still notes with blank line above.

        ---
        """
        let doc = parser.parse(input)
        #expect(doc.slides[0].notes.contains("presenter notes"))
        #expect(doc.slides[0].notes.contains("blank line"))
    }

    @Test func parsesListsInNotes() {
        let input = """
        ---
        format: https://example.com/slideshow/v1
        ---

        ---

        Key points:

        - First point
        - Second point
        - Third point

        ---
        """
        let doc = parser.parse(input)
        #expect(doc.slides[0].notes.contains("First point"))
        #expect(doc.slides[0].notes.contains("Second point"))
    }

    @Test func zeroImagesIsValid() {
        let input = """
        ---
        format: https://example.com/slideshow/v1
        ---

        ---

        ### Title Card

        Welcome to this presentation.

        ---
        """
        let doc = parser.parse(input)
        #expect(doc.slides[0].images.isEmpty)
        #expect(doc.slides[0].caption == "Title Card")
    }

    @Test func rejectsPathTraversal() {
        let input = """
        ---
        format: https://example.com/slideshow/v1
        ---

        ---

        ![](../../../secret.jpg)
        ![](subfolder/photo.jpg)
        ![](safe.jpg)

        ---
        """
        let doc = parser.parse(input)
        // Only safe.jpg should be accepted
        #expect(doc.slides[0].images.count == 1)
        #expect(doc.slides[0].images[0].filename == "safe.jpg")
    }

    @Test func parsesUnrecognizedContent() {
        let input = """
        ---
        format: https://example.com/slideshow/v1
        ---

        ---

        ### My Caption

        Notes here.

        ### Unrecognized content

        Some unknown stuff.

        More unknown.

        ---
        """
        let doc = parser.parse(input)
        #expect(doc.slides[0].caption == "My Caption")
        #expect(doc.slides[0].notes.contains("Notes here"))
        #expect(doc.slides[0].unrecognizedContent?.contains("unknown stuff") == true)
    }

    @Test func unrecognizedContentHeadingNotCaption() {
        let input = """
        ---
        format: https://example.com/slideshow/v1
        ---

        ---

        ### Unrecognized content

        Blob text.

        ---
        """
        let doc = parser.parse(input)
        #expect(doc.slides[0].caption == nil)
        #expect(doc.slides[0].unrecognizedContent?.contains("Blob") == true)
    }

    @Test func additionalHeadingsAreUnrecognized() {
        let input = """
        ---
        format: https://example.com/slideshow/v1
        ---

        ---

        ### First Caption

        ### Second Heading

        ---
        """
        let doc = parser.parse(input)
        #expect(doc.slides[0].caption == "First Caption")
        #expect(doc.slides[0].unrecognizedContent?.contains("Second Heading") == true)
    }

    @Test func additionalBlockquotesAreUnrecognized() {
        let input = """
        ---
        format: https://example.com/slideshow/v1
        ---

        ---

        > First source

        > Second blockquote

        ---
        """
        let doc = parser.parse(input)
        #expect(doc.slides[0].source?.contains("First source") == true)
        #expect(doc.slides[0].unrecognizedContent?.contains("Second blockquote") == true)
    }

    @Test func fullExample() {
        let input = """
        ---
        format: https://example.com/slideshow/v1
        ---

        # Paintings That Tell Secrets

        ---

        ### Golden hour, Wollishofen

        ![Lakeside view](golden-hour.jpg)

        > © Max Albrecht 2024
        > Downloaded from Lightroom CC

        My presenter notes about this shot.

        ---

        ### The old bridge

        ![](bridge-sunset.jpg)

        > © Max Albrecht 2024

        ---

        ### Introduction

        Welcome to this portfolio review.

        ---
        """
        let doc = parser.parse(input)
        #expect(doc.title == "Paintings That Tell Secrets")
        #expect(doc.slides.count == 3)

        #expect(doc.slides[0].caption == "Golden hour, Wollishofen")
        #expect(doc.slides[0].images[0].filename == "golden-hour.jpg")
        #expect(doc.slides[0].images[0].altText == "Lakeside view")
        #expect(doc.slides[0].source?.contains("Max Albrecht") == true)
        #expect(doc.slides[0].notes.contains("presenter notes"))

        #expect(doc.slides[1].caption == "The old bridge")
        #expect(doc.slides[1].images[0].filename == "bridge-sunset.jpg")

        #expect(doc.slides[2].caption == "Introduction")
        #expect(doc.slides[2].images.isEmpty)
        #expect(doc.slides[2].notes.contains("portfolio review"))
    }

    @Test func emptyFileIsValid() {
        let doc = parser.parse("")
        #expect(doc.slides.isEmpty)
        #expect(doc.title == nil)
    }

    @Test func normalizeCRLF() {
        let input = "---\r\nformat: https://example.com/slideshow/v1\r\n---\r\n\r\n# Title\r\n"
        let doc = parser.parse(input)
        #expect(doc.title == "Title")
    }

    @Test func noSeparatorsIsSingleSlide() {
        let input = """
        # Title

        ### Caption

        ![](photo.jpg)

        Notes here.
        """
        let doc = parser.parse(input)
        #expect(doc.title == "Title")
        #expect(doc.slides.count == 1)
        #expect(doc.slides[0].caption == "Caption")
    }

    @Test func parsesAngleBracketFilename() {
        let input = """
        ---
        format: https://example.com/slideshow/v1
        ---

        ---

        ![](<my image (1).jpg>)

        ---
        """
        let doc = parser.parse(input)
        #expect(doc.slides[0].images.count == 1)
        #expect(doc.slides[0].images[0].filename == "my image (1).jpg")
    }

    @Test func htmlBlockIsUnrecognized() {
        let input = """
        ---
        format: https://example.com/slideshow/v1
        ---

        ---

        ### Caption

        Notes here.

        <div>Some HTML</div>

        ---
        """
        let doc = parser.parse(input)
        #expect(doc.slides[0].caption == "Caption")
        #expect(doc.slides[0].notes.contains("Notes here"))
        #expect(doc.slides[0].unrecognizedContent?.contains("HTML") == true)
    }

    @Test func imagesInsideBlockquoteNotExtracted() {
        let input = """
        ---
        format: https://example.com/slideshow/v1
        ---

        ---

        > ![](inside-quote.jpg) Credit text

        ![](normal.jpg)

        ---
        """
        let doc = parser.parse(input)
        // Only normal.jpg should be extracted as a slide image
        #expect(doc.slides[0].images.count == 1)
        #expect(doc.slides[0].images[0].filename == "normal.jpg")
        // The blockquote with image is treated as source (first blockquote)
        #expect(doc.slides[0].source != nil)
    }

    @Test func imageOnlyParagraphConsumed() {
        let input = """
        ---
        format: https://example.com/slideshow/v1
        ---

        ---

        ![](photo.jpg)

        These are notes.

        ---
        """
        let doc = parser.parse(input)
        #expect(doc.slides[0].images.count == 1)
        // The image paragraph should NOT appear in notes
        #expect(!doc.slides[0].notes.contains("photo.jpg"))
        #expect(doc.slides[0].notes.contains("notes"))
    }
```

- [ ] **Step 3: Run all parser tests**

```bash
cd SlideshowKit && swift test --filter SlideshowParserTests
```

Fix any failures. The parser implementation from Task 3 should handle most cases. Iterate until all tests pass.

- [ ] **Step 4: Commit**

```bash
git add SlideshowKit/Tests/SlideshowKitTests/SlideshowParserTests.swift
git commit -m "add comprehensive parser tests for slides, images, notes, edge cases"
```

---

## Chunk 2: Writer + Round-Trip Tests

### Task 5: SlideshowWriter

**Files:**
- Create: `SlideshowKit/Sources/SlideshowKit/Services/SlideshowWriter.swift`
- Create: `SlideshowKit/Tests/SlideshowKitTests/SlideshowWriterTests.swift`

- [ ] **Step 1: Write failing tests for basic writing**

```swift
// SlideshowWriterTests.swift
import Testing
@testable import SlideshowKit

@Suite("SlideshowWriter")
struct SlideshowWriterTests {

    let writer = SlideshowWriter()
    let parser = SlideshowParser()

    @Test func writesMinimalDocument() {
        let doc = SlideshowDocument(title: "My Title")
        let output = writer.write(doc)
        #expect(output.contains("format:"))
        #expect(output.contains("# My Title"))
        #expect(output.hasSuffix("\n"))
    }

    @Test func alwaysWritesFrontmatter() {
        let doc = SlideshowDocument()
        let output = writer.write(doc)
        #expect(output.hasPrefix("---\n"))
        #expect(output.contains("format:"))
    }

    @Test func writesSlideWithAllElements() {
        let slide = SlideSection(
            caption: "Golden hour",
            captionLevel: 3,
            images: [SlideImage(filename: "sunset.jpg", altText: "A sunset")],
            source: "© Max 2024",
            notes: "My notes here."
        )
        let doc = SlideshowDocument(title: "Test", slides: [slide])
        let output = writer.write(doc)

        #expect(output.contains("### Golden hour"))
        #expect(output.contains("![A sunset](sunset.jpg)"))
        #expect(output.contains("> © Max 2024"))
        #expect(output.contains("My notes here."))
    }

    @Test func writesMultipleImages() {
        let slide = SlideSection(
            images: [
                SlideImage(filename: "a.jpg"),
                SlideImage(filename: "b.jpg"),
                SlideImage(filename: "c.jpg"),
            ]
        )
        let doc = SlideshowDocument(slides: [slide])
        let output = writer.write(doc)
        #expect(output.contains("![](a.jpg)"))
        #expect(output.contains("![](b.jpg)"))
        #expect(output.contains("![](c.jpg)"))
    }

    @Test func writesUnrecognizedContent() {
        let slide = SlideSection(
            caption: "Test",
            unrecognizedContent: "| a | b |\n|---|---|\n| 1 | 2 |"
        )
        let doc = SlideshowDocument(slides: [slide])
        let output = writer.write(doc)
        #expect(output.contains("### Unrecognized content"))
        #expect(output.contains("| a | b |"))
    }

    @Test func omitsBlankLinesForAbsentElements() {
        // A slide with only a caption should not have extra blank lines
        let slide = SlideSection(caption: "Just a caption", captionLevel: 3)
        let doc = SlideshowDocument(slides: [slide])
        let output = writer.write(doc)
        // Should not have triple blank lines
        #expect(!output.contains("\n\n\n\n"))
    }

    @Test func escapesFilenamesWithSpaces() {
        let slide = SlideSection(
            images: [SlideImage(filename: "my image (1).jpg")]
        )
        let doc = SlideshowDocument(slides: [slide])
        let output = writer.write(doc)
        #expect(output.contains("![](<my image (1).jpg>)"))
    }

    @Test func preservesCaptionLevel() {
        let slide = SlideSection(caption: "Title", captionLevel: 2)
        let doc = SlideshowDocument(slides: [slide])
        let output = writer.write(doc)
        #expect(output.contains("## Title"))
    }

    @Test func writesMultiLineSource() {
        let slide = SlideSection(
            source: "© Max 2024\nDownloaded from Lightroom"
        )
        let doc = SlideshowDocument(slides: [slide])
        let output = writer.write(doc)
        #expect(output.contains("> © Max 2024"))
        #expect(output.contains("> Downloaded from Lightroom"))
    }

    @Test func preservesHeaderContent() {
        let doc = SlideshowDocument(
            title: "My Title",
            headerContent: "Some intro text.\n\nAnother paragraph."
        )
        let output = writer.write(doc)
        #expect(output.contains("# My Title"))
        #expect(output.contains("Some intro text."))
        #expect(output.contains("Another paragraph."))
    }

    @Test func preservesUnknownFrontmatter() {
        let doc = SlideshowDocument(
            frontmatter: ["custom": "value", "format": SlideshowDocument.formatURL]
        )
        let output = writer.write(doc)
        #expect(output.contains("custom: value"))
    }

    @Test func endsWithTrailingSeparator() {
        let doc = SlideshowDocument(slides: [SlideSection(caption: "Test")])
        let output = writer.write(doc)
        let trimmed = output.trimmingCharacters(in: .newlines)
        #expect(trimmed.hasSuffix("---"))
    }
}
```

- [ ] **Step 2: Run tests — expect FAIL**

```bash
cd SlideshowKit && swift test --filter SlideshowWriterTests
```

- [ ] **Step 3: Implement SlideshowWriter**

```swift
// SlideshowWriter.swift
import Foundation
import Yams

/// Writes `SlideshowDocument` values to markdown strings.
public struct SlideshowWriter: Sendable {

    public init() {}

    /// Write a SlideshowDocument to a markdown string.
    public func write(_ document: SlideshowDocument) -> String {
        var output = ""

        // 1. Frontmatter (always written)
        writeFrontmatter(document, to: &output)

        // 2. Title
        if let title = document.title {
            output += "\n# \(title)\n"
        }

        // 3. Header content
        if let headerContent = document.headerContent {
            output += "\n\(headerContent)\n"
        }

        // 4. Slides
        for slide in document.slides {
            output += "\n---\n"
            writeSlide(slide, to: &output)
        }

        // 5. Trailing separator
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
        if fields["format"] == nil {
            fields["format"] = SlideshowDocument.formatURL
        }

        output += "---\n"
        if let yaml = try? Yams.dump(
            object: fields as Any,
            sortedKeys: true
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
            let level = slide.captionLevel ?? 3
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
            elements.append("### Unrecognized content\n\n\(unrecognized)")
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
```

- [ ] **Step 4: Run tests — expect PASS**

```bash
cd SlideshowKit && swift test --filter SlideshowWriterTests
```

- [ ] **Step 5: Commit**

```bash
git add SlideshowKit/Sources/SlideshowKit/Services/SlideshowWriter.swift \
       SlideshowKit/Tests/SlideshowKitTests/SlideshowWriterTests.swift
git commit -m "add SlideshowWriter with frontmatter, slides, and filename escaping"
```

---

### Task 6: Round-trip tests

**Files:**
- Modify: `SlideshowKit/Tests/SlideshowKitTests/SlideshowWriterTests.swift`

- [ ] **Step 1: Add round-trip tests**

```swift
    // MARK: - Round-trip (parse → write → parse)

    @Test func roundTripFullDocument() {
        let input = """
        ---
        format: https://example.com/slideshow/v1
        ---

        # Paintings That Tell Secrets

        ---

        ### Golden hour, Wollishofen

        ![Lakeside view](golden-hour.jpg)

        > © Max Albrecht 2024
        > Downloaded from Lightroom CC

        My presenter notes about this shot.

        ---

        ### The old bridge

        ![](bridge-sunset.jpg)

        > © Max Albrecht 2024

        ---

        ### Introduction

        Welcome to this portfolio review.

        ---
        """
        let doc1 = parser.parse(input)
        let output = writer.write(doc1)
        let doc2 = parser.parse(output)

        #expect(doc1.title == doc2.title)
        #expect(doc1.slides.count == doc2.slides.count)

        for i in 0..<doc1.slides.count {
            #expect(doc1.slides[i].caption == doc2.slides[i].caption)
            #expect(doc1.slides[i].captionLevel == doc2.slides[i].captionLevel)
            #expect(doc1.slides[i].images == doc2.slides[i].images)
            #expect(doc1.slides[i].source == doc2.slides[i].source)
            // Notes may have minor whitespace differences
            #expect(doc1.slides[i].notes.trimmingCharacters(in: .whitespacesAndNewlines)
                == doc2.slides[i].notes.trimmingCharacters(in: .whitespacesAndNewlines))
        }
    }

    @Test func roundTripPreservesUnknownFrontmatter() {
        let input = """
        ---
        custom: hello
        format: https://example.com/slideshow/v1
        ---

        # Title

        ---

        ### Slide

        ---
        """
        let doc1 = parser.parse(input)
        let output = writer.write(doc1)
        let doc2 = parser.parse(output)

        #expect(doc2.frontmatter["custom"] == "hello")
    }

    @Test func roundTripPreservesUnrecognizedContent() {
        let doc1 = SlideshowDocument(
            slides: [
                SlideSection(
                    caption: "Test",
                    captionLevel: 3,
                    notes: "Some notes",
                    unrecognizedContent: "Unknown stuff here"
                )
            ]
        )
        let output = writer.write(doc1)
        let doc2 = parser.parse(output)

        #expect(doc2.slides[0].unrecognizedContent?.contains("Unknown stuff") == true)
    }

    @Test func roundTripPreservesHeaderContent() {
        let doc1 = SlideshowDocument(
            title: "Title",
            headerContent: "Intro paragraph.\n\nSecond paragraph."
        )
        let output = writer.write(doc1)
        let doc2 = parser.parse(output)

        #expect(doc2.headerContent?.contains("Intro paragraph") == true)
        #expect(doc2.headerContent?.contains("Second paragraph") == true)
    }
```

- [ ] **Step 2: Run tests**

```bash
cd SlideshowKit && swift test --filter SlideshowWriterTests
```

Fix any round-trip failures by adjusting parser or writer.

- [ ] **Step 3: Commit**

```bash
git add SlideshowKit/Tests/SlideshowKitTests/SlideshowWriterTests.swift
git commit -m "add round-trip tests for parse → write → parse cycle"
```

---

## Chunk 3: Integration — Update Models + Delete Old Code

### Task 7: Update Slide model

**Files:**
- Modify: `SlideshowKit/Sources/SlideshowKit/Models/Slide.swift`
- Modify: `SlideshowKit/Tests/SlideshowKitTests/SlideTests.swift`

The Slide model changes from file-URL-centric (1:1 with image) to section-centric (0-N images). Key changes:

- Remove `fileURL`, `sidecar`, `sidecarURL`, `hasSidecar`, `ensureSidecar()`
- Add `section: SlideSection` (the parsed data)
- Add `images: [SlideImage]` (proxy to section.images)
- Add `resolvedImageURLs: [URL]` (set by Slideshow after loading)
- Keep `exif`, `fileSize` (for primary image)
- Adapt computed properties: `displayName`, `captionText`, `sourceText`, `notesText`

- [ ] **Step 1: Write failing tests for new Slide model**

```swift
// SlideTests.swift — rewrite for new model
import Testing
@testable import SlideshowKit

@Suite("Slide")
struct SlideTests {
    @Test func displayNameUsesCaption() {
        let slide = Slide(section: SlideSection(caption: "Golden hour"))
        #expect(slide.displayName == "Golden hour")
    }

    @Test func displayNameFallsBackToFilename() {
        let slide = Slide(section: SlideSection(
            images: [SlideImage(filename: "sunset.jpg")]
        ))
        #expect(slide.displayName == "sunset")
    }

    @Test func displayNameFallsBackToUntitled() {
        let slide = Slide(section: SlideSection())
        #expect(slide.displayName == "Untitled Slide")
    }

    @Test func captionTextBinding() {
        let slide = Slide(section: SlideSection())
        slide.captionText = "New caption"
        #expect(slide.section.caption == "New caption")
    }

    @Test func captionClearsToNil() {
        let slide = Slide(section: SlideSection(caption: "Old"))
        slide.captionText = ""
        #expect(slide.section.caption == nil)
    }

    @Test func sourceTextBinding() {
        let slide = Slide(section: SlideSection())
        slide.sourceText = "© 2024"
        #expect(slide.section.source == "© 2024")
    }

    @Test func notesTextBinding() {
        let slide = Slide(section: SlideSection())
        slide.notesText = "My notes"
        #expect(slide.section.notes == "My notes")
    }

    @Test func primaryImageURL() {
        let slide = Slide(section: SlideSection(
            images: [SlideImage(filename: "photo.jpg")]
        ))
        let folder = URL(fileURLWithPath: "/tmp/test")
        slide.resolveImageURLs(relativeTo: folder)
        #expect(slide.primaryImageURL?.lastPathComponent == "photo.jpg")
    }

    @Test func multipleImageURLs() {
        let slide = Slide(section: SlideSection(
            images: [
                SlideImage(filename: "a.jpg"),
                SlideImage(filename: "b.jpg"),
            ]
        ))
        let folder = URL(fileURLWithPath: "/tmp/test")
        slide.resolveImageURLs(relativeTo: folder)
        #expect(slide.resolvedImageURLs.count == 2)
    }
}
```

- [ ] **Step 2: Run tests — expect FAIL**

```bash
cd SlideshowKit && swift test --filter SlideTests
```

- [ ] **Step 3: Rewrite Slide model**

```swift
// Slide.swift
import Foundation

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
    public func resolveImageURLs(relativeTo folderURL: URL, availableFiles: [String] = []) {
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
```

- [ ] **Step 4: Run tests — expect PASS**

```bash
cd SlideshowKit && swift test --filter SlideTests
```

- [ ] **Step 5: Commit**

```bash
git add SlideshowKit/Sources/SlideshowKit/Models/Slide.swift \
       SlideshowKit/Tests/SlideshowKitTests/SlideTests.swift
git commit -m "rewrite Slide model for slideshow.md format (section-based, 0-N images)"
```

---

### Task 8: Update Slideshow model

**Files:**
- Modify: `SlideshowKit/Sources/SlideshowKit/Models/Slideshow.swift`

Key changes:
- Add `documentURL: URL?` (path to the `.md` file)
- `folderURL` derived from `documentURL`
- Replace `projectFile` with `document: SlideshowDocument`
- Remove `createSidecar()`, `saveSidecar()`, `persistReorder()` — replaced by `save()`
- `removeSlide()` no longer deletes files — just removes from array + saves
- `moveSlide()` reorders array + saves
- `addImages()` copies files to folder + creates slide entries + saves
- `name` computed from `document.title` with fallback chain

- [ ] **Step 1: Rewrite Slideshow model**

This is a significant rewrite. The model is `@MainActor @Observable` and owns all file I/O. Write the new version based on the existing patterns but adapted for document-level saves.

Key method signatures:

```swift
@MainActor @Observable
public final class Slideshow {
    public var documentURL: URL?
    public var slides: [Slide] = []
    public var selectedSlideID: Slide.ID?
    public var document: SlideshowDocument = SlideshowDocument()

    public var folderURL: URL? { documentURL?.deletingLastPathComponent() }

    public var name: String {
        if let title = document.title, !title.isEmpty { return title }
        if let docURL = documentURL {
            let filename = docURL.deletingPathExtension().lastPathComponent
            if filename.lowercased() != "slideshow" { return filename }
        }
        return folderURL?.lastPathComponent ?? "Untitled"
    }

    public func save() throws {
        guard let url = documentURL else { return }
        // Sync slides back to document
        document.slides = slides.map(\.section)
        try SlideshowWriter().write(document, to: url)
    }

    public func removeSlide(_ slide: Slide) {
        slides.removeAll { $0.id == slide.id }
        if selectedSlideID == slide.id {
            selectedSlideID = slides.first?.id
        }
        try? save()
    }

    public func moveSlide(_ slide: Slide, direction: MoveDirection) {
        // ... same logic as before but calls save() instead of persistReorder()
    }

    public func addImages(from urls: [URL]) {
        guard let folderURL else { return }
        for url in urls {
            // Copy image to folder
            let destination = folderURL.appendingPathComponent(url.lastPathComponent)
            try? FileManager.default.copyItem(at: url, to: destination)

            // Create slide entry
            let section = SlideSection(
                images: [SlideImage(filename: url.lastPathComponent)]
            )
            let slide = Slide(section: section)
            slide.resolveImageURLs(relativeTo: folderURL)
            slides.append(slide)
        }
        try? save()
    }
}
```

- [ ] **Step 2: Verify SlideshowKit builds**

```bash
cd SlideshowKit && swift build
```

Fix compile errors from API changes. The old tests that reference removed methods will fail — that's expected at this stage.

- [ ] **Step 3: Commit**

```bash
git add SlideshowKit/Sources/SlideshowKit/Models/Slideshow.swift
git commit -m "rewrite Slideshow model for document-level save"
```

---

### Task 9: Update FolderScanner and ScanResult

**Files:**
- Modify: `SlideshowKit/Sources/SlideshowKit/Services/FolderScanner.swift`
- Modify: `SlideshowKit/Sources/SlideshowKit/Models/ScanResult.swift`
- Modify: `SlideshowKit/Tests/SlideshowKitTests/FolderScannerTests.swift`

FolderScanner simplifies:
- No longer matches sidecars to images
- Discovers images in folder (for the library/available images)
- Parses `slideshow.md` if present → returns `SlideshowDocument`
- Builds `[Slide]` from the document, resolving image URLs

- [ ] **Step 1: Update ScanResult**

```swift
// ScanResult.swift
public struct ScanResult {
    public let slides: [Slide]
    public let document: SlideshowDocument?
    public let documentURL: URL?
    public let availableImages: [URL]  // images in folder not referenced in document

    public init(
        slides: [Slide],
        document: SlideshowDocument?,
        documentURL: URL?,
        availableImages: [URL] = []
    ) {
        self.slides = slides
        self.document = document
        self.documentURL = documentURL
        self.availableImages = availableImages
    }
}
```

- [ ] **Step 2: Rewrite FolderScanner**

```swift
// Key changes:
// - scan(folderURL:) finds slideshow.md, parses it, builds Slides
// - scan(documentURL:) parses a specific .md file
// - discoverImages(in:) returns all image URLs in folder
// - No sidecar matching
```

- [ ] **Step 3: Rewrite FolderScannerTests**

```swift
// Key test changes:
// - Create slideshow.md fixture instead of sidecars
// - Test image discovery
// - Test slideshow.md parsing integration
// - Test folder without slideshow.md (image-only fallback)
```

- [ ] **Step 4: Run tests**

```bash
cd SlideshowKit && swift test --filter FolderScannerTests
```

- [ ] **Step 5: Commit**

```bash
git add SlideshowKit/Sources/SlideshowKit/Services/FolderScanner.swift \
       SlideshowKit/Sources/SlideshowKit/Models/ScanResult.swift \
       SlideshowKit/Tests/SlideshowKitTests/FolderScannerTests.swift
git commit -m "simplify FolderScanner: parse slideshow.md, no sidecar matching"
```

---

### Task 10: Delete old code

**Files:**
- Delete: `SlideshowKit/Sources/SlideshowKit/Models/SidecarData.swift`
- Delete: `SlideshowKit/Sources/SlideshowKit/Services/SidecarParser.swift`
- Delete: `SlideshowKit/Sources/SlideshowKit/Services/SidecarWriter.swift`
- Delete: `SlideshowKit/Sources/SlideshowKit/Services/ProjectFileParser.swift`
- Delete: `SlideshowKit/Sources/SlideshowKit/Services/ProjectFileWriter.swift`
- Delete: `SlideshowKit/Sources/SlideshowKit/Services/FileReorderer.swift`
- Delete: `SlideshowKit/Tests/SlideshowKitTests/SidecarParserTests.swift`
- Delete: `SlideshowKit/Tests/SlideshowKitTests/SidecarWriterTests.swift`
- Delete: `SlideshowKit/Tests/SlideshowKitTests/SidecarDataTests.swift`
- Delete: `SlideshowKit/Tests/SlideshowKitTests/ProjectFileParserTests.swift`
- Delete: `SlideshowKit/Tests/SlideshowKitTests/ProjectFileWriterTests.swift`
- Delete: `SlideshowKit/Tests/SlideshowKitTests/FileReordererTests.swift`
- Modify: `SlideshowKit/Sources/SlideshowKit/Models/ProjectFile.swift` — update or delete

- [ ] **Step 1: Delete old source files**

```bash
git rm SlideshowKit/Sources/SlideshowKit/Models/SidecarData.swift
git rm SlideshowKit/Sources/SlideshowKit/Services/SidecarParser.swift
git rm SlideshowKit/Sources/SlideshowKit/Services/SidecarWriter.swift
git rm SlideshowKit/Sources/SlideshowKit/Services/ProjectFileParser.swift
git rm SlideshowKit/Sources/SlideshowKit/Services/ProjectFileWriter.swift
git rm SlideshowKit/Sources/SlideshowKit/Services/FileReorderer.swift
```

- [ ] **Step 2: Delete old test files**

```bash
git rm SlideshowKit/Tests/SlideshowKitTests/SidecarParserTests.swift
git rm SlideshowKit/Tests/SlideshowKitTests/SidecarWriterTests.swift
git rm SlideshowKit/Tests/SlideshowKitTests/SidecarDataTests.swift
git rm SlideshowKit/Tests/SlideshowKitTests/ProjectFileParserTests.swift
git rm SlideshowKit/Tests/SlideshowKitTests/ProjectFileWriterTests.swift
git rm SlideshowKit/Tests/SlideshowKitTests/FileReordererTests.swift
```

- [ ] **Step 3: Delete or update ProjectFile.swift**

If `ProjectFile` is no longer used (its data is in `SlideshowDocument.frontmatter` and `SlideshowDocument.title`), delete it. If any code still references it, update references first.

```bash
git rm SlideshowKit/Sources/SlideshowKit/Models/ProjectFile.swift
```

- [ ] **Step 4: Update test fixtures**

Remove old sidecar fixtures, add `slideshow.md`:

```bash
# Remove old sidecar fixtures
git rm SlideshowKit/Tests/SlideshowKitTests/Fixtures/test-slideshow/002--sunset.jpg.md
git rm SlideshowKit/Tests/SlideshowKitTests/Fixtures/test-slideshow/slideshow.yml
```

Create `SlideshowKit/Tests/SlideshowKitTests/Fixtures/test-slideshow/slideshow.md`:

```markdown
---
format: https://example.com/slideshow/v1
---

# Test Slideshow

---

### Intro

![](001--intro.jpg)

---

### Golden hour

![A beautiful sunset](002--sunset.jpg)

> © Test Author 2024

Notes about the sunset.

---

![](003--portrait.jpg)

---
```

- [ ] **Step 5: Verify SlideshowKit compiles and tests pass**

```bash
cd SlideshowKit && swift test
```

Fix any remaining compile errors from removed types.

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "delete old sidecar/YAML infrastructure, add slideshow.md fixture"
```

---

## Chunk 4: App Layer

### Task 11: Update views for new Slide model

**Files:**
- Modify: `Slideshow/Views/ContentView.swift`
- Modify: `Slideshow/Views/SlideListPanel.swift`
- Modify: `Slideshow/Views/PreviewPanel.swift`
- Modify: `Slideshow/Views/EditorPanel.swift`
- Modify: `Slideshow/Views/FileInfoPanel.swift`
- Modify: `Slideshow/Views/PresenterView.swift`
- Modify: `Slideshow/Views/AudienceView.swift`
- Modify: `Slideshow/Views/SlideRowView.swift`

Key changes across all views:

| Old API | New API |
|---------|---------|
| `slide.fileURL` | `slide.primaryImageURL` |
| `slide.sidecar?.caption` | `slide.section.caption` |
| `slide.sidecar?.source` | `slide.section.source` |
| `slide.strippedFilename` | `slide.section.images.first?.displayFilename` |
| `slide.sidecarURL` | Removed |
| `slide.hasSidecar` | Removed |
| `slideshow.createSidecar(for:)` | Removed |
| `slideshow.saveSidecar(for:)` | `try? slideshow.save()` |
| `slideshow.persistReorder()` | `try? slideshow.save()` |

- [ ] **Step 1: Update each view file**

Work through each view, replacing old APIs with new ones. For each file:
1. Replace `slide.fileURL` → `slide.primaryImageURL`
2. Replace sidecar property access → section property access
3. Replace `saveSidecar` calls → `save()` calls
4. Remove "Create Sidecar" menu items
5. Remove `persistReorder()` calls — `moveSlide` now saves automatically

- [ ] **Step 2: Update EditorPanel save debounce**

The EditorPanel currently debounces sidecar saves. Change to document-level save:

```swift
// EditorPanel.swift
private func scheduleSave() {
    saveTask?.cancel()
    saveTask = Task {
        try? await Task.sleep(for: .milliseconds(500))
        try? slideshow.save()
    }
}
```

- [ ] **Step 3: Update SlideListPanel context menu**

Remove:
- "Create Sidecar File" menu item
- "Reveal in Finder" for sidecar

Keep:
- "Reveal in Finder" (for the image — use `slide.primaryImageURL`)
- "Edit Caption" (unchanged, uses binding)
- "Move Up" / "Move Down"
- "Remove from Slideshow"

- [ ] **Step 4: Build the full Xcode project**

```bash
xcodebuild -scheme Slideshow -destination 'platform=macOS' build
```

Fix all compile errors.

- [ ] **Step 5: Commit**

```bash
git add Slideshow/
git commit -m "update all views for slideshow.md format"
```

---

### Task 12: Update opening behavior

**Files:**
- Modify: `Slideshow/SlideshowApp.swift`

The app needs to:
1. Open a folder → look for `slideshow.md` → parse → populate Slideshow
2. Open a `.md` file directly → check frontmatter → parse → populate Slideshow
3. Create new slideshow → create folder + `slideshow.md`

- [ ] **Step 1: Update `openSlideshow(at:)` method**

The method must handle two entry points: opening a folder, or opening a `.md` file directly.

```swift
func openSlideshow(at url: URL) async {
    let scanner = FolderScanner()
    let parser = SlideshowParser()

    do {
        if url.pathExtension.lowercased() == "md" {
            // Opening a .md file directly — validate it
            guard parser.isValidSlideshowFile(url: url) else {
                scanError = SlideshowError.notASlideshowFile
                return
            }
            let result = try await scanner.scan(documentURL: url)
            loadScanResult(result)
        } else {
            // Opening a folder — look for slideshow.md
            let result = try await scanner.scan(folderURL: url)
            loadScanResult(result)
        }
    } catch {
        scanError = error
    }
}

private func loadScanResult(_ result: ScanResult) {
    slideshow.documentURL = result.documentURL
    slideshow.document = result.document ?? SlideshowDocument()
    slideshow.slides = result.slides

    // Resolve image URLs with case-insensitive matching
    if let folderURL = slideshow.folderURL {
        let availableFiles = (try? FileManager.default.contentsOfDirectory(
            at: folderURL, includingPropertiesForKeys: nil
        ).map(\.lastPathComponent)) ?? []

        for slide in slideshow.slides {
            slide.resolveImageURLs(relativeTo: folderURL, availableFiles: availableFiles)
        }
    }

    slideshow.selectedSlideID = slideshow.slides.first?.id
}
```

- [ ] **Step 2: Update `createNewSlideshow()` method**

When creating a new slideshow, write a minimal `slideshow.md`:

```swift
func createNewSlideshow() {
    // NSOpenPanel to select/create folder
    // Then:
    let mdURL = selectedFolder.appendingPathComponent("slideshow.md")
    let doc = SlideshowDocument(title: selectedFolder.lastPathComponent)
    try? SlideshowWriter().write(doc, to: mdURL)
    // Then open it
}
```

- [ ] **Step 3: Update `loadUITestFixtures()` method**

Update to work with new format (copy `slideshow.md` instead of sidecars).

- [ ] **Step 4: Build and verify**

```bash
xcodebuild -scheme Slideshow -destination 'platform=macOS' build
```

- [ ] **Step 5: Commit**

```bash
git add Slideshow/SlideshowApp.swift
git commit -m "update opening behavior for slideshow.md format"
```

---

### Task 13: Update examples and test fixtures

**Files:**
- Modify: `Examples/Paintings That Tell Secrets/` — replace sidecars + `slideshow.yml` with `slideshow.md`
- Modify: `Examples/My Favorite Space Pictures/` — same
- Modify: `Examples/Nature Is Really Good at Shapes/` — same
- Modify: `SlideshowUITests/SlideshowUITests.swift` — if needed

- [ ] **Step 1: Convert each example directory**

For each example:
1. Read existing `slideshow.yml` and `*.jpg.md` files
2. Create equivalent `slideshow.md`
3. Delete old `slideshow.yml` and `*.jpg.md` files
4. Remove numeric prefixes from image filenames (optional — images keep original names)

- [ ] **Step 2: Run UI tests**

```bash
xcodebuild test -scheme Slideshow -destination 'platform=macOS' -only-testing:SlideshowUITests
```

Fix any failures.

- [ ] **Step 3: Commit**

```bash
git add -A Examples/
git commit -m "convert example slideshows to slideshow.md format"
```

---

### Task 14: Update CLAUDE.md and MANIFESTO.md

**Files:**
- Modify: `CLAUDE.md` — update sidecar format docs, add slideshow.md format docs
- Modify: `MANIFESTO.md` — update principles 6 and 7 for new format

- [ ] **Step 1: Update MANIFESTO.md**

Replace:
- Principle 6 (sidecar `.md` files) → "A single `slideshow.md` file curates the presentation..."
- Principle 7 (project file stores project-level metadata) → "The project file is the single source of truth..."

- [ ] **Step 2: Update CLAUDE.md**

Replace:
- Sidecar format section → `slideshow.md` format
- Remove SidecarParser/SidecarWriter references
- Update build/test commands if needed
- Update code review context

- [ ] **Step 3: Commit**

```bash
git add CLAUDE.md MANIFESTO.md
git commit -m "update docs for slideshow.md format"
```

---

### Task 15: Final verification

- [ ] **Step 1: Run SlideshowKit tests**

```bash
cd SlideshowKit && swift test
```

All tests must pass. Zero failures.

- [ ] **Step 2: Build full Xcode project**

```bash
xcodebuild -scheme Slideshow -destination 'platform=macOS' build
```

Zero warnings.

- [ ] **Step 3: Run UI tests**

```bash
xcodebuild test -scheme Slideshow -destination 'platform=macOS' -only-testing:SlideshowUITests
```

**Deferred:** File watching for external edits (spec mentions `DispatchSource` / file coordination) is deferred to a follow-up task. Not needed for initial implementation.

- [ ] **Step 4: Run /simplify**

Review changed code for reuse, quality, and efficiency.

- [ ] **Step 5: Run /ai-review**

Get Gemini review. Fix findings. Repeat until clean.
