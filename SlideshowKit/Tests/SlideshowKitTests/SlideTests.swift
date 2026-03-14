import Testing
import Foundation
@testable import SlideshowKit

@Suite("Slide")
struct SlideTests {
    @Test("strippedFilename removes app prefix")
    func stripsAppPrefix() {
        let slide = Slide(fileURL: URL(fileURLWithPath: "/tmp/003--sunset.jpg"))
        #expect(slide.strippedFilename == "sunset.jpg")
    }

    @Test("strippedFilename preserves filename without prefix")
    func preservesNoPrefix() {
        let slide = Slide(fileURL: URL(fileURLWithPath: "/tmp/beach.jpg"))
        #expect(slide.strippedFilename == "beach.jpg")
    }

    @Test("strippedFilename preserves non-app numeric patterns")
    func preservesNonAppNumeric() {
        let slide = Slide(fileURL: URL(fileURLWithPath: "/tmp/2024-photo.jpg"))
        #expect(slide.strippedFilename == "2024-photo.jpg")
    }

    @Test("strippedFilename preserves single-hyphen numeric prefix")
    func preservesSingleHyphen() {
        let slide = Slide(fileURL: URL(fileURLWithPath: "/tmp/123-photo.jpg"))
        #expect(slide.strippedFilename == "123-photo.jpg")
    }

    @Test("displayName falls back to strippedFilename when no sidecar")
    func displayNameFallback() {
        let slide = Slide(fileURL: URL(fileURLWithPath: "/tmp/003--sunset.jpg"))
        #expect(slide.displayName == "sunset.jpg")
    }

    @Test("displayName uses caption when sidecar present")
    func displayNameWithCaption() {
        let slide = Slide(
            fileURL: URL(fileURLWithPath: "/tmp/sunset.jpg"),
            sidecar: SidecarData(caption: "Golden hour")
        )
        #expect(slide.displayName == "Golden hour")
    }

    @Test("sidecarURL appends .md to file URL")
    func sidecarURL() {
        let slide = Slide(fileURL: URL(fileURLWithPath: "/tmp/003--sunset.jpg"))
        #expect(slide.sidecarURL.lastPathComponent == "003--sunset.jpg.md")
    }

    @Test("hasSidecar reflects sidecar presence")
    func hasSidecar() {
        let withoutSidecar = Slide(fileURL: URL(fileURLWithPath: "/tmp/a.jpg"))
        #expect(!withoutSidecar.hasSidecar)

        let withSidecar = Slide(
            fileURL: URL(fileURLWithPath: "/tmp/a.jpg"),
            sidecar: SidecarData(caption: "Test")
        )
        #expect(withSidecar.hasSidecar)
    }

    @Test("captionText setter creates sidecar lazily")
    func lazySidecarCreation() {
        let slide = Slide(fileURL: URL(fileURLWithPath: "/tmp/a.jpg"))
        #expect(!slide.hasSidecar)

        slide.captionText = "New caption"
        #expect(slide.hasSidecar)
        #expect(slide.captionText == "New caption")
    }

    @Test("captionText setter clears to nil on empty string")
    func captionClearsToNil() {
        let slide = Slide(
            fileURL: URL(fileURLWithPath: "/tmp/a.jpg"),
            sidecar: SidecarData(caption: "Test")
        )
        slide.captionText = ""
        #expect(slide.sidecar?.caption == nil)
    }

    @Test("sourceText and notesText bind correctly")
    func sourceAndNotesBindings() {
        let slide = Slide(fileURL: URL(fileURLWithPath: "/tmp/a.jpg"))
        slide.sourceText = "© Author"
        slide.notesText = "Some notes"
        #expect(slide.sourceText == "© Author")
        #expect(slide.notesText == "Some notes")
    }
}
