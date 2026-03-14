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
        #expect(names == names.sorted())
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
}
