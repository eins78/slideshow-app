import Testing
import Foundation
@testable import SlideshowKit

@Suite("SidecarWriter")
struct SidecarWriterTests {
    let parser = SidecarParser()
    let writer = SidecarWriter()

    @Test("Round-trip: parse → write → parse produces equal data")
    func roundTrip() throws {
        let original = SidecarData(
            caption: "Golden hour, Wollishofen",
            source: "© Max F. Albrecht 2024\nDownloaded from Lightroom CC",
            notes: "Talk about the golden hour timing.\n\nMultiple paragraphs."
        )

        let tmpURL = FileManager.default.temporaryDirectory
            .appending(path: "sidecar-roundtrip-\(UUID().uuidString).md")
        defer { try? FileManager.default.removeItem(at: tmpURL) }

        try writer.write(original, to: tmpURL)
        let reparsed = parser.parse(try String(contentsOf: tmpURL, encoding: .utf8))

        #expect(reparsed.caption == original.caption)
        #expect(reparsed.source == original.source)
        #expect(reparsed.notes == original.notes)
    }

    @Test("Round-trip preserves unknown frontmatter keys")
    func roundTripUnknownKeys() throws {
        // Only unknown keys in rawFrontmatter — known keys come from named properties
        let original = SidecarData(
            caption: "Test",
            notes: "Notes.",
            rawFrontmatter: ["custom_key": "custom_value", "another": "field"]
        )

        let tmpURL = FileManager.default.temporaryDirectory
            .appending(path: "sidecar-unknown-\(UUID().uuidString).md")
        defer { try? FileManager.default.removeItem(at: tmpURL) }

        try writer.write(original, to: tmpURL)
        let reparsed = parser.parse(try String(contentsOf: tmpURL, encoding: .utf8))

        #expect(reparsed.caption == "Test")
        #expect(reparsed.rawFrontmatter["custom_key"] == "custom_value")
        #expect(reparsed.rawFrontmatter["another"] == "field")
    }

    @Test("Write notes-only sidecar (no frontmatter)")
    func notesOnly() throws {
        let data = SidecarData(notes: "Just some notes.")

        let tmpURL = FileManager.default.temporaryDirectory
            .appending(path: "sidecar-notes-\(UUID().uuidString).md")
        defer { try? FileManager.default.removeItem(at: tmpURL) }

        try writer.write(data, to: tmpURL)
        let content = try String(contentsOf: tmpURL, encoding: .utf8)

        #expect(!content.contains("---"))
        #expect(content.contains("Just some notes."))
    }

    @Test("Write empty sidecar produces empty file")
    func emptySidecar() throws {
        let data = SidecarData(notes: "")

        let tmpURL = FileManager.default.temporaryDirectory
            .appending(path: "sidecar-empty-\(UUID().uuidString).md")
        defer { try? FileManager.default.removeItem(at: tmpURL) }

        try writer.write(data, to: tmpURL)
        let content = try String(contentsOf: tmpURL, encoding: .utf8)

        #expect(content.isEmpty)
    }

    @Test("YAML keys are sorted for stable git diffs")
    func sortedKeys() throws {
        let data = SidecarData(
            caption: "Test",
            source: "Source",
            notes: "",
            rawFrontmatter: ["zebra": "last"]
        )

        let tmpURL = FileManager.default.temporaryDirectory
            .appending(path: "sidecar-sorted-\(UUID().uuidString).md")
        defer { try? FileManager.default.removeItem(at: tmpURL) }

        try writer.write(data, to: tmpURL)
        let content = try String(contentsOf: tmpURL, encoding: .utf8)
        let lines = content.components(separatedBy: "\n")

        // Keys should be in alphabetical order: caption, source, zebra
        let captionIdx = lines.firstIndex { $0.hasPrefix("caption:") }
        let sourceIdx = lines.firstIndex { $0.hasPrefix("source:") }
        let zebraIdx = lines.firstIndex { $0.hasPrefix("zebra:") }

        let ci = try #require(captionIdx)
        let si = try #require(sourceIdx)
        let zi = try #require(zebraIdx)
        #expect(ci < si)
        #expect(si < zi)
    }
}
