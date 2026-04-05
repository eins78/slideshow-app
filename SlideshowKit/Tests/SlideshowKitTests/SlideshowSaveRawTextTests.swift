import Foundation
import Testing
@testable import SlideshowKit

@Suite("Slideshow.saveRawText")
struct SlideshowSaveRawTextTests {

    /// Create a temp folder with a slideshow.md and optional images.
    @MainActor
    private func makeTempSlideshow(
        content: String,
        imageNames: [String] = []
    ) throws -> (URL, Slideshow) {
        let tmpDir = FileManager.default.temporaryDirectory
            .appending(path: "saveRawText-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true)

        let mdURL = tmpDir.appending(path: "slideshow.md")
        try content.write(to: mdURL, atomically: true, encoding: .utf8)

        let jpeg = Data([0xFF, 0xD8, 0xFF, 0xD9])
        for name in imageNames {
            try jpeg.write(to: tmpDir.appending(path: name))
        }

        return (tmpDir, makeSlideshow(documentURL: mdURL, content: content))
    }

    @MainActor
    private func makeSlideshow(documentURL: URL, content: String) -> Slideshow {
        let slideshow = Slideshow()
        slideshow.documentURL = documentURL
        let parsed = SlideshowParser().parse(content)
        slideshow.document = parsed
        let folderURL = documentURL.deletingLastPathComponent()
        let availableFiles = (try? FileManager.default.contentsOfDirectory(
            at: folderURL, includingPropertiesForKeys: nil
        ))?.map(\.lastPathComponent) ?? []
        slideshow.slides = parsed.slides.map { section in
            let slide = Slide(section: section)
            slide.resolveImageURLs(relativeTo: folderURL, availableFiles: availableFiles)
            return slide
        }
        return slideshow
    }

    private func cleanup(_ dir: URL) {
        try? FileManager.default.removeItem(at: dir)
    }

    // MARK: - Tests

    @MainActor
    @Test func writesExactTextToDisk() throws {
        let original = """
        ---
        format: https://example.com/slideshow/v1
        ---

        # Test

        ---

        ### Slide one

        ![](photo.jpg)

        ---
        """
        let (dir, slideshow) = try makeTempSlideshow(
            content: original,
            imageNames: ["photo.jpg"]
        )
        defer { cleanup(dir) }

        let edited = """
        ---
        format: https://example.com/slideshow/v1
        ---

        # Test Edited

        ---

        ### Slide one edited

        ![](photo.jpg)

        Some notes here.

        ---
        """
        try slideshow.saveRawText(edited)

        let onDisk = try String(contentsOf: slideshow.documentURL ?? dir, encoding: .utf8)
        #expect(onDisk == edited)
    }

    @MainActor
    @Test func updatesModelFromParsedText() throws {
        let original = """
        ---
        format: https://example.com/slideshow/v1
        title: Original Title
        ---

        ---

        ![](a.jpg)

        ---
        """
        let (dir, slideshow) = try makeTempSlideshow(
            content: original,
            imageNames: ["a.jpg", "b.jpg"]
        )
        defer { cleanup(dir) }

        let edited = """
        ---
        format: https://example.com/slideshow/v1
        title: New Title
        ---

        ---

        # First

        ![](a.jpg)

        ---

        # Second

        ![](b.jpg)

        ---
        """
        try slideshow.saveRawText(edited)

        #expect(slideshow.document.title == "New Title")
        #expect(slideshow.slides.count == 2)
        #expect(slideshow.slides[0].section.caption == "First")
        #expect(slideshow.slides[1].section.caption == "Second")
    }

    @MainActor
    @Test func preservesSelectionByFilename() throws {
        let original = """
        ---
        format: https://example.com/slideshow/v1
        ---

        ---

        ![](a.jpg)

        ---

        ![](b.jpg)

        ---
        """
        let (dir, slideshow) = try makeTempSlideshow(
            content: original,
            imageNames: ["a.jpg", "b.jpg"]
        )
        defer { cleanup(dir) }

        // Select the second slide (b.jpg)
        slideshow.selectedSlideID = slideshow.slides[1].id

        // Save with same content — slides get rebuilt but selection should restore
        try slideshow.saveRawText(original)

        let selected = slideshow.selectedSlide
        #expect(selected?.section.images.first?.filename == "b.jpg")
    }

    @MainActor
    @Test func handlesMalformedMarkdownGracefully() throws {
        let original = """
        ---
        format: https://example.com/slideshow/v1
        ---

        ---

        ![](photo.jpg)

        ---
        """
        let (dir, slideshow) = try makeTempSlideshow(
            content: original,
            imageNames: ["photo.jpg"]
        )
        defer { cleanup(dir) }

        // Completely invalid content — no frontmatter, no structure
        let malformed = "just some random text\nwith no structure\n"
        try slideshow.saveRawText(malformed)

        // Should not crash, text should be on disk as-is
        let onDisk = try String(contentsOf: slideshow.documentURL ?? dir, encoding: .utf8)
        #expect(onDisk == malformed)
        // Parser is lenient — text without structure still produces a document
        #expect(slideshow.document.frontmatter.isEmpty)
    }

    @MainActor
    @Test func roundTripModelToTextAndBack() throws {
        let doc = SlideshowDocument(
            frontmatter: ["format": SlideshowDocument.formatURL],
            title: "Round Trip",
            slides: [
                SlideSection(
                    caption: "Slide A",
                    images: [SlideImage(filename: "a.jpg")],
                    source: "\u{00A9} Photographer",
                    notes: "Some notes"
                ),
                SlideSection(
                    caption: "Slide B",
                    images: [SlideImage(filename: "b.jpg")]
                ),
            ]
        )
        let text = SlideshowWriter().write(doc)

        let (dir, slideshow) = try makeTempSlideshow(
            content: text,
            imageNames: ["a.jpg", "b.jpg"]
        )
        defer { cleanup(dir) }

        // Save the same text back — model should match original
        try slideshow.saveRawText(text)

        #expect(slideshow.document.title == "Round Trip")
        #expect(slideshow.slides.count == 2)
        #expect(slideshow.slides[0].section.caption == "Slide A")
        #expect(slideshow.slides[0].section.source == "\u{00A9} Photographer")
        #expect(slideshow.slides[0].section.notes == "Some notes")
        #expect(slideshow.slides[1].section.caption == "Slide B")
    }

    @MainActor
    @Test func noOpWhenDocumentURLIsNil() throws {
        let slideshow = Slideshow()
        // Should not crash — just returns
        try slideshow.saveRawText("some text")
        #expect(slideshow.slides.isEmpty)
    }
}
