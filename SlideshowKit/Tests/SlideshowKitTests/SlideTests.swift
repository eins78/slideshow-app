import Testing
import Foundation
@testable import SlideshowKit

@Suite("Slide")
struct SlideTests {
    @Test func displayNameUsesCaption() {
        let slide = Slide(section: SlideSection(caption: "Golden hour"))
        #expect(slide.displayName == "Golden hour")
    }

    @Test func displayNameFallsBackToFilename() {
        let slide = Slide(section: SlideSection(
            images: [SlideImage(filename: "sunset.jpg")]
        ))
        #expect(slide.displayName == "sunset")
    }

    @Test func displayNameFallsBackToUntitled() {
        let slide = Slide(section: SlideSection())
        #expect(slide.displayName == "Untitled Slide")
    }

    @Test func captionTextBinding() {
        let slide = Slide(section: SlideSection())
        slide.captionText = "New caption"
        #expect(slide.section.caption == "New caption")
    }

    @Test func captionClearsToNil() {
        let slide = Slide(section: SlideSection(caption: "Old"))
        slide.captionText = ""
        #expect(slide.section.caption == nil)
    }

    @Test func sourceTextBinding() {
        let slide = Slide(section: SlideSection())
        slide.sourceText = "© 2024"
        #expect(slide.section.source == "© 2024")
    }

    @Test func sourceClearsToNil() {
        let slide = Slide(section: SlideSection(source: "© Author"))
        slide.sourceText = ""
        #expect(slide.section.source == nil)
    }

    @Test func notesTextBinding() {
        let slide = Slide(section: SlideSection())
        slide.notesText = "My notes"
        #expect(slide.section.notes == "My notes")
    }

    @Test func notesPreservesEmpty() {
        let slide = Slide(section: SlideSection(notes: "Some notes"))
        slide.notesText = ""
        #expect(slide.section.notes == "")
    }

    @Test func primaryImageURL() {
        let slide = Slide(section: SlideSection(
            images: [SlideImage(filename: "photo.jpg")]
        ))
        let folder = URL(fileURLWithPath: "/tmp/test")
        slide.resolveImageURLs(relativeTo: folder)
        #expect(slide.primaryImageURL?.lastPathComponent == "photo.jpg")
    }

    @Test func multipleImageURLs() {
        let slide = Slide(section: SlideSection(
            images: [
                SlideImage(filename: "a.jpg"),
                SlideImage(filename: "b.jpg"),
            ]
        ))
        let folder = URL(fileURLWithPath: "/tmp/test")
        slide.resolveImageURLs(relativeTo: folder)
        #expect(slide.resolvedImageURLs.count == 2)
    }

    @Test func noImageURLs() {
        let slide = Slide(section: SlideSection())
        #expect(slide.primaryImageURL == nil)
        #expect(slide.resolvedImageURLs.isEmpty)
    }
}
