import Foundation
import Testing
@testable import SlideshowKit

@Suite("ProjectFileWriter")
struct ProjectFileWriterTests {
    let parser = ProjectFileParser()
    let writer = ProjectFileWriter()

    @Test func roundTripsProjectFile() throws {
        let original = ProjectFile(version: 1, title: "Round Trip Test")
        let url = FileManager.default.temporaryDirectory
            .appending(path: "roundtrip-\(UUID()).yml")
        defer { try? FileManager.default.removeItem(at: url) }

        try writer.write(original, to: url)
        let parsed = try #require(parser.parse(url: url))
        #expect(parsed.version == original.version)
        #expect(parsed.title == original.title)
    }

    @Test func roundTripsUnknownFields() throws {
        let original = ProjectFile(
            version: 1,
            title: "With Extras",
            rawFields: ["custom": "value", "another": "field"]
        )
        let url = FileManager.default.temporaryDirectory
            .appending(path: "roundtrip-unknown-\(UUID()).yml")
        defer { try? FileManager.default.removeItem(at: url) }

        try writer.write(original, to: url)
        let parsed = try #require(parser.parse(url: url))
        #expect(parsed.rawFields["custom"] == "value")
        #expect(parsed.rawFields["another"] == "field")
        #expect(parsed.title == "With Extras")
    }

    @Test func writesWithSortedKeys() throws {
        let file = ProjectFile(
            version: 1,
            title: "Sorted",
            rawFields: ["zebra": "last", "alpha": "first"]
        )
        let url = FileManager.default.temporaryDirectory
            .appending(path: "sorted-\(UUID()).yml")
        defer { try? FileManager.default.removeItem(at: url) }

        try writer.write(file, to: url)
        let content = try String(contentsOf: url, encoding: .utf8)
        let lines = content.components(separatedBy: "\n").filter { !$0.isEmpty }

        // Keys should be alphabetically sorted
        let keys = lines.compactMap { line -> String? in
            let parts = line.components(separatedBy: ": ")
            return parts.first
        }
        #expect(keys == keys.sorted())
    }

    @Test func writesDefaultProjectFile() throws {
        let file = ProjectFile()
        let url = FileManager.default.temporaryDirectory
            .appending(path: "default-\(UUID()).yml")
        defer { try? FileManager.default.removeItem(at: url) }

        try writer.write(file, to: url)
        let parsed = try #require(parser.parse(url: url))
        #expect(parsed.version == 1)
        #expect(parsed.title == nil)
    }

    @Test func removesNilTitleFromRawFields() throws {
        // If rawFields has a stale "title" but the model's title is nil,
        // the writer must remove it to avoid ghost data.
        let file = ProjectFile(
            version: 1,
            title: nil,
            rawFields: ["title": "Stale Title"]
        )
        let url = FileManager.default.temporaryDirectory
            .appending(path: "nil-title-\(UUID()).yml")
        defer { try? FileManager.default.removeItem(at: url) }

        try writer.write(file, to: url)
        let parsed = try #require(parser.parse(url: url))
        #expect(parsed.title == nil)
    }
}
