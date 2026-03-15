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

    @Test("Scans folder and finds all images")
    func findsAllImages() async throws {
        let slides = try await scanner.scan(folderURL: fixtureURL())
        #expect(slides.count == 3)
    }

    @Test("Sorts slides alphabetically by filename")
    func sortsByFilename() async throws {
        let slides = try await scanner.scan(folderURL: fixtureURL())
        let names = slides.map { $0.fileURL.lastPathComponent }
        #expect(names == ["001--intro.jpg", "002--sunset.jpg", "003--portrait.jpg"])
    }

    @Test("Matches sidecar to image")
    func matchesSidecar() async throws {
        let slides = try await scanner.scan(folderURL: fixtureURL())
        let sunset = slides.first { $0.fileURL.lastPathComponent.contains("sunset") }
        #expect(sunset?.sidecar?.caption == "Golden hour")
    }

    @Test("Images without sidecar have nil sidecar")
    func noSidecar() async throws {
        let slides = try await scanner.scan(folderURL: fixtureURL())
        let intro = slides.first { $0.fileURL.lastPathComponent.contains("intro") }
        #expect(intro?.sidecar == nil)
    }

    @Test("Ignores non-image files")
    func ignoresNonImages() async throws {
        let slides = try await scanner.scan(folderURL: fixtureURL())
        let mdSlides = slides.filter { $0.fileURL.pathExtension == "md" }
        #expect(mdSlides.isEmpty)
    }

    // MARK: - scanWithProjectFile

    @Test("scanWithProjectFile returns parsed project file")
    func scanWithProjectFileReturnsProjectFile() async throws {
        let result = try await scanner.scanWithProjectFile(folderURL: fixtureURL())
        #expect(result.projectFile?.title == "Test Slideshow")
        #expect(result.projectFile?.version == 1)
    }

    @Test("scanWithProjectFile returns nil project file when missing")
    func scanWithProjectFileReturnsNilWhenMissing() async throws {
        // Create a temp folder without slideshow.yml
        let tmpDir = FileManager.default.temporaryDirectory
            .appending(path: "scanner-no-project-\(UUID())")
        try FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tmpDir) }

        let jpeg = Data([0xFF, 0xD8, 0xFF, 0xD9])
        try jpeg.write(to: tmpDir.appending(path: "photo.jpg"))

        let result = try await scanner.scanWithProjectFile(folderURL: tmpDir)
        #expect(result.projectFile == nil)
        #expect(result.slides.count == 1)
    }

    @Test("slideshow.yml is not counted as slide or sidecar")
    func projectFileNotCountedAsSlideOrSidecar() async throws {
        let result = try await scanner.scanWithProjectFile(folderURL: fixtureURL())
        // test-slideshow has 3 images — slideshow.yml must not inflate the count
        #expect(result.slides.count == 3)
        let ymlSlides = result.slides.filter {
            $0.fileURL.lastPathComponent == ProjectFile.filename
        }
        #expect(ymlSlides.isEmpty)
    }

    @Test("Existing scan() still returns same slides")
    func existingScanStillWorks() async throws {
        let slides = try await scanner.scan(folderURL: fixtureURL())
        let result = try await scanner.scanWithProjectFile(folderURL: fixtureURL())
        #expect(slides.count == result.slides.count)
    }
}
