import Testing
import Foundation
@testable import SlideshowKit

@Suite("FileReorderer")
struct FileReordererTests {
    let reorderer = FileReorderer()

    @Test("Generates correct new filenames with double-hyphen prefix")
    func generatesPrefix() {
        let names = ["sunset.jpg", "portrait.jpg", "intro.jpg"]
        let result = reorderer.computeNewNames(for: names)
        #expect(result == ["001--sunset.jpg", "002--portrait.jpg", "003--intro.jpg"])
    }

    @Test("Strips existing app prefix before re-prefixing")
    func stripsExistingPrefix() {
        let names = ["003--sunset.jpg", "001--portrait.jpg", "002--intro.jpg"]
        let result = reorderer.computeNewNames(for: names)
        #expect(result == ["001--sunset.jpg", "002--portrait.jpg", "003--intro.jpg"])
    }

    @Test("Preserves non-app numeric prefixes")
    func preservesOtherPrefixes() {
        let names = ["100-meter-dash.jpg", "2024-06-sunset.jpg"]
        let result = reorderer.computeNewNames(for: names)
        #expect(result == ["001--100-meter-dash.jpg", "002--2024-06-sunset.jpg"])
    }

    @Test("Generates sidecar filenames alongside images")
    func sidecarFilenames() {
        #expect(reorderer.sidecarName(for: "001--sunset.jpg") == "001--sunset.jpg.md")
    }

    @Test("Handles collision suffix for Add Images")
    func collisionSuffix() {
        let existing = Set(["vacation.jpg", "vacation 2.jpg"])
        let result = reorderer.deconflictedName("vacation.jpg", existing: existing)
        #expect(result == "vacation 3.jpg")
    }

    @Test("Disk integration: reorder renames files and sidecars on disk")
    func diskReorder() throws {
        let tmpDir = FileManager.default.temporaryDirectory
            .appending(path: "reorder-test-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tmpDir) }

        // Create test files
        let files = ["sunset.jpg", "portrait.jpg", "intro.jpg"]
        for file in files {
            try Data([0xFF, 0xD8]).write(to: tmpDir.appending(path: file))
        }
        // Create a sidecar for sunset
        try "---\ncaption: Sunset\n---\n".write(
            to: tmpDir.appending(path: "sunset.jpg.md"), atomically: true, encoding: .utf8
        )

        // Reorder: intro, sunset, portrait
        let ordered = ["intro.jpg", "sunset.jpg", "portrait.jpg"]
        _ = try reorderer.reorder(in: tmpDir, orderedFilenames: ordered)

        // Verify files exist with new names
        let fm = FileManager.default
        #expect(fm.fileExists(atPath: tmpDir.appending(path: "001--intro.jpg").path(percentEncoded: false)))
        #expect(fm.fileExists(atPath: tmpDir.appending(path: "002--sunset.jpg").path(percentEncoded: false)))
        #expect(fm.fileExists(atPath: tmpDir.appending(path: "003--portrait.jpg").path(percentEncoded: false)))
        // Sidecar should also be renamed
        #expect(fm.fileExists(atPath: tmpDir.appending(path: "002--sunset.jpg.md").path(percentEncoded: false)))
        // Old names should be gone
        #expect(!fm.fileExists(atPath: tmpDir.appending(path: "sunset.jpg").path(percentEncoded: false)))
    }

    @Test("Skips no-op renames when source equals destination")
    func skipsNoOpRenames() throws {
        let tmpDir = FileManager.default.temporaryDirectory
            .appending(path: "noop-test-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tmpDir) }

        // Create files already in correct order
        let files = ["001--alpha.jpg", "002--beta.jpg"]
        for file in files {
            try Data([0xFF, 0xD8]).write(to: tmpDir.appending(path: file))
        }

        let result = try reorderer.reorder(in: tmpDir, orderedFilenames: files)
        // No renames should have occurred
        #expect(result.isEmpty)
    }
}
