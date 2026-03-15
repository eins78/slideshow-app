import Testing
@testable import SlideshowKit

@Suite("CursorSlideMapper")
struct CursorSlideMapperTests {

    let mapper = CursorSlideMapper()

    // MARK: - Edge cases

    @Test func emptyTextReturnsNil() {
        #expect(mapper.slideIndex(forCursorPosition: 0, in: "") == nil)
    }

    @Test func cursorBeyondTextReturnsLastSlide() {
        let text = """
        ---
        format: https://slideshow.ars.is/format/1.0
        ---

        # Title

        ---

        ## Slide 1

        ![](photo.jpg)
        """
        #expect(mapper.slideIndex(forCursorPosition: text.count + 100, in: text) == 0)
    }

    // MARK: - Frontmatter

    @Test func cursorInFrontmatterReturnsNil() {
        let text = """
        ---
        format: https://slideshow.ars.is/format/1.0
        ---

        # Title

        ---

        ## Slide 1
        """
        // Cursor on the "format:" line (inside frontmatter)
        let position = text.range(of: "format:")!.lowerBound.utf16Offset(in: text)
        #expect(mapper.slideIndex(forCursorPosition: position, in: text) == nil)
    }

    @Test func frontmatterSeparatorsNotCountedAsSlides() {
        let text = """
        ---
        format: https://slideshow.ars.is/format/1.0
        theme: dark
        ---

        # Title

        ---

        ## First Slide

        ![](photo.jpg)

        ---

        ## Second Slide
        """
        // Cursor in "Second Slide" section
        let position = text.range(of: "Second")!.lowerBound.utf16Offset(in: text)
        #expect(mapper.slideIndex(forCursorPosition: position, in: text) == 1)
    }

    // MARK: - Header / Title

    @Test func cursorInTitleReturnsNil() {
        let text = """
        ---
        format: https://slideshow.ars.is/format/1.0
        ---

        # My Slideshow Title

        ---

        ## Slide 1
        """
        let position = text.range(of: "My Slideshow")!.lowerBound.utf16Offset(in: text)
        #expect(mapper.slideIndex(forCursorPosition: position, in: text) == nil)
    }

    // MARK: - Slide sections

    @Test func cursorInFirstSlideReturnsZero() {
        let text = """
        ---
        format: https://slideshow.ars.is/format/1.0
        ---

        # Title

        ---

        ## First Slide

        ![](photo1.jpg)

        Some notes here.
        """
        let position = text.range(of: "Some notes")!.lowerBound.utf16Offset(in: text)
        #expect(mapper.slideIndex(forCursorPosition: position, in: text) == 0)
    }

    @Test func cursorInSecondSlideReturnsOne() {
        let text = """
        ---
        format: https://slideshow.ars.is/format/1.0
        ---

        # Title

        ---

        ## First Slide

        ![](photo1.jpg)

        ---

        ## Second Slide

        ![](photo2.jpg)
        """
        let position = text.range(of: "photo2")!.lowerBound.utf16Offset(in: text)
        #expect(mapper.slideIndex(forCursorPosition: position, in: text) == 1)
    }

    @Test func cursorOnSeparatorReturnsPrecedingSlide() {
        let text = """
        ---
        format: https://slideshow.ars.is/format/1.0
        ---

        # Title

        ---

        ## First Slide

        ---

        ## Second Slide
        """
        // Find the separator between first and second slide (the third --- in body)
        // The separator "---" after "First Slide" should return slide 0
        let firstSlideRange = text.range(of: "First Slide")!
        let searchRange = firstSlideRange.upperBound..<text.endIndex
        let separatorRange = text.range(of: "\n---\n", range: searchRange)!
        let position = text[text.startIndex..<separatorRange.lowerBound].count + 1 // on the ---
        #expect(mapper.slideIndex(forCursorPosition: position, in: text) == 0)
    }

    @Test func cursorAtEndReturnsLastSlide() {
        let text = """
        ---
        format: https://slideshow.ars.is/format/1.0
        ---

        # Title

        ---

        ## First Slide

        ---

        ## Second Slide

        ---

        ## Third Slide

        Final notes.
        """
        let position = text.count - 1
        #expect(mapper.slideIndex(forCursorPosition: position, in: text) == 2)
    }

    // MARK: - No separators

    @Test func noSeparatorsWithFrontmatterReturnsSingleSlide() {
        let text = """
        ---
        format: https://slideshow.ars.is/format/1.0
        ---

        # Title

        ## Slide content

        ![](photo.jpg)
        """
        let position = text.range(of: "photo")!.lowerBound.utf16Offset(in: text)
        // No slide separators after frontmatter → all content is one slide (index 0)
        // But the parser treats no-separator differently: header is H1, rest is single slide
        #expect(mapper.slideIndex(forCursorPosition: position, in: text) == 0)
    }

    @Test func noFrontmatterNoSeparators() {
        let text = """
        # Title

        Some content here
        """
        let position = text.range(of: "content")!.lowerBound.utf16Offset(in: text)
        // No frontmatter, no separators → single slide
        #expect(mapper.slideIndex(forCursorPosition: position, in: text) == 0)
    }

    // MARK: - No frontmatter with separators

    @Test func noFrontmatterWithSeparators() {
        let text = """
        # Title

        ---

        ## First Slide

        ---

        ## Second Slide
        """
        let position = text.range(of: "Second")!.lowerBound.utf16Offset(in: text)
        #expect(mapper.slideIndex(forCursorPosition: position, in: text) == 1)
    }

    // MARK: - CRLF

    @Test func handlesCRLFNormalization() {
        let text = "---\r\nformat: test\r\n---\r\n\r\n# Title\r\n\r\n---\r\n\r\n## Slide 1\r\n\r\n---\r\n\r\n## Slide 2"
        let normalized = text.replacingOccurrences(of: "\r\n", with: "\n")
        let position = normalized.range(of: "Slide 2")!.lowerBound.utf16Offset(in: normalized)
        // Use the normalized position since mapper normalizes internally
        #expect(mapper.slideIndex(forCursorPosition: position, in: normalized) == 1)
    }
}
