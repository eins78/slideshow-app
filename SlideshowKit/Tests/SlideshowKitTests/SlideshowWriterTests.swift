import Testing
@testable import SlideshowKit

@Suite("SlideshowWriter")
struct SlideshowWriterTests {

    let writer = SlideshowWriter()
    let parser = SlideshowParser()

    // MARK: - Basic writing

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
        let slide = SlideSection(caption: "Just a caption", captionLevel: 3)
        let doc = SlideshowDocument(slides: [slide])
        let output = writer.write(doc)
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
}
