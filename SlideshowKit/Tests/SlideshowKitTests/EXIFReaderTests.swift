import Testing
import Foundation
@testable import SlideshowKit

@Suite("EXIFReader")
struct EXIFReaderTests {
    let reader = EXIFReader()

    func fixtureImageURL() throws -> URL {
        try #require(Bundle.module.resourceURL)
            .appending(path: "Fixtures/test-slideshow/intro.jpg")
    }

    @Test("Returns EXIFData with nil fields for minimal JPEG without EXIF")
    func noExif() throws {
        let data = reader.read(from: try fixtureImageURL())
        #expect(data != nil)
        #expect(data?.cameraMake == nil)
        #expect(data?.iso == nil)
        #expect(data?.exposureTime == nil)
        #expect(data?.coordinate == nil)
    }

    @Test("Returns nil for non-existent file")
    func nonExistent() {
        let url = URL(fileURLWithPath: "/nonexistent.jpg")
        let data = reader.read(from: url)
        #expect(data == nil)
    }
}
