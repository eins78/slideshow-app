import Testing
@testable import SlideshowKit

@Suite("SidecarParser")
struct SidecarParserTests {
    let parser = SidecarParser()

    @Test("Parses frontmatter with caption and source")
    func parseFrontmatter() throws {
        let content = """
        ---
        caption: Golden hour, Wollishofen
        source: |
          © Max F. Albrecht 2024
          Downloaded from Lightroom CC
        ---

        Talk about the golden hour timing.
        """
        let result = parser.parse(content)
        #expect(result.caption == "Golden hour, Wollishofen")
        #expect(result.primarySource == "© Max F. Albrecht 2024")
        #expect(result.secondarySourceLines.count == 1)
        #expect(result.notes.contains("golden hour"))
    }

    @Test("No frontmatter: first line is caption, rest is notes")
    func plainTextCaptionAndNotes() {
        let content = """
        Sunset at the lake

        These are the presenter notes.

        With multiple paragraphs.
        """
        let result = parser.parse(content)
        #expect(result.caption == "Sunset at the lake")
        #expect(result.notes.contains("presenter notes"))
        #expect(result.notes.contains("multiple paragraphs"))
    }

    @Test("No frontmatter: single line becomes caption only")
    func singleLineCaption() {
        let content = "Just a caption"
        let result = parser.parse(content)
        #expect(result.caption == "Just a caption")
        #expect(result.notes.isEmpty)
    }

    @Test("No frontmatter: caption with immediate notes (no blank line)")
    func captionWithImmediateNotes() {
        let content = """
        My Caption
        Some notes right after.
        More notes.
        """
        let result = parser.parse(content)
        #expect(result.caption == "My Caption")
        #expect(result.notes.contains("Some notes right after."))
        #expect(result.notes.contains("More notes."))
    }

    @Test("Treats malformed frontmatter as plain text")
    func malformedFrontmatter() {
        let content = """
        ---
        caption: Missing closing delimiter
        this is not valid yaml: [
        ---

        Some notes here.
        """
        let result = parser.parse(content)
        // Malformed YAML: entire file treated as plain text notes
        #expect(result.caption == nil)
        #expect(result.notes.contains("---"))
    }

    @Test("Handles empty file")
    func emptyFile() {
        let result = parser.parse("")
        #expect(result.caption == nil)
        #expect(result.notes.isEmpty)
    }

    @Test("Preserves unknown frontmatter fields")
    func unknownFields() {
        let content = """
        ---
        caption: Test
        custom_field: some value
        ---

        Notes.
        """
        let result = parser.parse(content)
        #expect(result.caption == "Test")
        #expect(result.rawFrontmatter["custom_field"] == "some value")
    }

    @Test("Frontmatter requires --- on line 1")
    func frontmatterOnlyOnLine1() {
        let content = """
        Some text before.
        ---
        caption: Should not parse as frontmatter
        ---
        """
        let result = parser.parse(content)
        // First line becomes caption via plain text fallback
        #expect(result.caption == "Some text before.")
        // The --- lines end up in notes
        #expect(result.notes.contains("---"))
    }

    @Test("Normalizes CRLF line endings")
    func normalizeCRLF() {
        let content = "---\r\ncaption: Test\r\n---\r\n\r\nNotes here."
        let result = parser.parse(content)
        #expect(result.caption == "Test")
        #expect(result.notes == "Notes here.")
    }

    @Test("CRLF normalization in plain text mode")
    func normalizeCRLFPlainText() {
        let content = "My Caption\r\n\r\nSome notes."
        let result = parser.parse(content)
        #expect(result.caption == "My Caption")
        #expect(result.notes == "Some notes.")
    }
}
