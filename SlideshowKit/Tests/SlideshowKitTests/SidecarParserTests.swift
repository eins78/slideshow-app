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

    @Test("Falls back to heading as caption when no frontmatter")
    func fallbackToHeading() {
        let content = """
        # Sunset Caption

        These are the presenter notes.
        """
        let result = parser.parse(content)
        #expect(result.caption == "Sunset Caption")
        #expect(result.notes.contains("presenter notes"))
        #expect(!result.notes.contains("# Sunset Caption"))
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
        // Malformed YAML: entire file treated as plain text
        #expect(result.caption == nil)
        #expect(result.notes.contains("---"))
    }

    @Test("Handles empty file")
    func emptyFile() {
        let result = parser.parse("")
        #expect(result.caption == nil)
        #expect(result.notes.isEmpty)
    }

    @Test("Plain text without heading or frontmatter")
    func plainTextOnly() {
        let content = "Just some plain text notes."
        let result = parser.parse(content)
        #expect(result.caption == nil)
        #expect(result.notes == "Just some plain text notes.")
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
        caption: Should not parse
        ---
        """
        let result = parser.parse(content)
        #expect(result.caption == nil)
    }

    @Test("Normalizes CRLF line endings")
    func normalizeCRLF() {
        let content = "---\r\ncaption: Test\r\n---\r\n\r\nNotes here."
        let result = parser.parse(content)
        #expect(result.caption == "Test")
        #expect(result.notes == "Notes here.")
    }
}
