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
        #expect(doc.slides[0].images.count == 1)
        #expect(doc.slides[0].images[0].filename == "normal.jpg")
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
        #expect(!doc.slides[0].notes.contains("photo.jpg"))
        #expect(doc.slides[0].notes.contains("notes"))
    }
}
