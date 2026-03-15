import Foundation
import Testing
@testable import SlideshowKit

@Suite("ProjectFileParser")
struct ProjectFileParserTests {
    let parser = ProjectFileParser()

    @Test func parsesValidYAML() {
        let content = """
        version: 1
        title: Paintings That Tell Secrets
        """
        let result = parser.parse(content)
        #expect(result.version == 1)
        #expect(result.title == "Paintings That Tell Secrets")
    }

    @Test func defaultsVersionTo1WhenMissing() {
        let content = "title: My Portfolio"
        let result = parser.parse(content)
        #expect(result.version == 1)
        #expect(result.title == "My Portfolio")
    }

    @Test func defaultsTitleToNilWhenMissing() {
        let content = "version: 1"
        let result = parser.parse(content)
        #expect(result.version == 1)
        #expect(result.title == nil)
    }

    @Test func parsesQuotedVersion() {
        let content = """
        version: "2"
        title: Quoted Version
        """
        let result = parser.parse(content)
        #expect(result.version == 2)
    }

    @Test func preservesUnknownFields() {
        let content = """
        version: 1
        title: My Project
        custom_key: custom_value
        another: data
        """
        let result = parser.parse(content)
        #expect(result.rawFields["custom_key"] == "custom_value")
        #expect(result.rawFields["another"] == "data")
    }

    @Test func handlesMalformedYAML() {
        let content = ": : : not valid yaml ["
        let result = parser.parse(content)
        #expect(result.version == 1)
        #expect(result.title == nil)
    }

    @Test func handlesEmptyContent() {
        let result = parser.parse("")
        #expect(result.version == 1)
        #expect(result.title == nil)
        #expect(result.rawFields.isEmpty)
    }

    @Test func parsesFromURL() throws {
        let fixtureURL = try #require(
            Bundle.module.url(forResource: "slideshow", withExtension: "yml", subdirectory: "Fixtures")
        )
        let result = try #require(parser.parse(url: fixtureURL))
        #expect(result.version == 1)
        #expect(result.title == "Test Project")
    }

    @Test func returnsNilForMissingFile() {
        let bogusURL = URL(fileURLWithPath: "/nonexistent/slideshow.yml")
        #expect(parser.parse(url: bogusURL) == nil)
    }
}
