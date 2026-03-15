import Testing
import Foundation
@testable import SlideshowKit

@Suite("FolderScanner")
struct FolderScannerTests {
    let scanner = FolderScanner()

    func fixtureURL() throws -> URL {
        let url = Bundle.module.resourceURL
        let fixtureURL = try #require(url).appending(path: "Fixtures/test-slideshow")
        return fixtureURL
    }

    // MARK: - Folder with slideshow.md

    @Test func scansFixtureFolder() async throws {
        let result = try await scanner.scan(folderURL: fixtureURL())
        // slideshow.md references 3 slides
        #expect(result.slides.count == 3)
        #expect(result.document != nil)
        #expect(result.documentURL != nil)
    }

    @Test func parsesDocumentTitle() async throws {
        let result = try await scanner.scan(folderURL: fixtureURL())
        #expect(result.document?.title == "Test Slideshow")
    }

    @Test func slideHasCaption() async throws {
        let result = try await scanner.scan(folderURL: fixtureURL())
        let sunset = result.slides.first { $0.section.caption == "Golden hour" }
        #expect(sunset != nil)
    }

    @Test func slideHasResolvedImageURL() async throws {
        let result = try await scanner.scan(folderURL: fixtureURL())
        let firstSlide = try #require(result.slides.first)
        #expect(firstSlide.primaryImageURL != nil)
    }

    @Test func slideMdNotCountedAsSlide() async throws {
        let result = try await scanner.scan(folderURL: fixtureURL())
        let mdSlides = result.slides.filter {
            $0.section.images.first?.filename.hasSuffix(".md") == true
        }
        #expect(mdSlides.isEmpty)
    }

    // MARK: - Folder without slideshow.md

    @Test func folderWithoutSlideshowMDFallsBack() async throws {
        let tmpDir = FileManager.default.temporaryDirectory
            .appending(path: "scanner-no-md-\(UUID())")
        try FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tmpDir) }

        // Create minimal JPEG files
        let jpeg = Data([0xFF, 0xD8, 0xFF, 0xD9])
        try jpeg.write(to: tmpDir.appending(path: "alpha.jpg"))
        try jpeg.write(to: tmpDir.appending(path: "beta.jpg"))

        let result = try await scanner.scan(folderURL: tmpDir)
        #expect(result.slides.count == 2)
        #expect(result.document == nil)
        #expect(result.documentURL == nil)
    }

    @Test func fallbackSortsByFilename() async throws {
        let tmpDir = FileManager.default.temporaryDirectory
            .appending(path: "scanner-sort-\(UUID())")
        try FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tmpDir) }

        let jpeg = Data([0xFF, 0xD8, 0xFF, 0xD9])
        try jpeg.write(to: tmpDir.appending(path: "charlie.jpg"))
        try jpeg.write(to: tmpDir.appending(path: "alpha.jpg"))
        try jpeg.write(to: tmpDir.appending(path: "bravo.jpg"))

        let result = try await scanner.scan(folderURL: tmpDir)
        let names = result.slides.compactMap { $0.section.images.first?.filename }
        #expect(names == ["alpha.jpg", "bravo.jpg", "charlie.jpg"])
    }

    // MARK: - Direct document URL

    @Test func scanFromDocumentURL() async throws {
        let mdURL = try fixtureURL().appending(path: "slideshow.md")
        let result = try await scanner.scan(documentURL: mdURL)
        #expect(result.slides.count == 3)
        #expect(result.documentURL == mdURL)
    }

    // MARK: - Available images

    @Test func tracksUnreferencedImages() async throws {
        let tmpDir = FileManager.default.temporaryDirectory
            .appending(path: "scanner-available-\(UUID())")
        try FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tmpDir) }

        let jpeg = Data([0xFF, 0xD8, 0xFF, 0xD9])
        try jpeg.write(to: tmpDir.appending(path: "used.jpg"))
        try jpeg.write(to: tmpDir.appending(path: "unused.jpg"))

        let md = """
        ---
        format: https://example.com/slideshow/v1
        ---

        ---

        ![](used.jpg)

        ---
        """
        try md.write(to: tmpDir.appending(path: "slideshow.md"), atomically: true, encoding: .utf8)

        let result = try await scanner.scan(folderURL: tmpDir)
        #expect(result.slides.count == 1)
        #expect(result.availableImages.count == 1)
        #expect(result.availableImages[0].lastPathComponent == "unused.jpg")
    }
}
