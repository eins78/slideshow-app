import Testing
@testable import SlideshowKit

@Suite("SlideImage")
struct SlideImageTests {
    @Test func displayFilename() {
        let image = SlideImage(filename: "sunset.jpg", altText: nil)
        #expect(image.displayFilename == "sunset")
    }

    @Test func displayFilenameStripsExtension() {
        let image = SlideImage(filename: "001--golden-hour.heic", altText: nil)
        #expect(image.displayFilename == "001--golden-hour")
    }

    @Test func altTextPreserved() {
        let image = SlideImage(filename: "photo.jpg", altText: "A beautiful sunset")
        #expect(image.altText == "A beautiful sunset")
    }

    @Test func equatable() {
        let a = SlideImage(filename: "photo.jpg", altText: "alt")
        let b = SlideImage(filename: "photo.jpg", altText: "alt")
        #expect(a == b)
    }
}

@Suite("SlideSection")
struct SlideSectionTests {
    @Test func defaultValues() {
        let section = SlideSection()
        #expect(section.caption == nil)
        #expect(section.captionLevel == nil)
        #expect(section.images.isEmpty)
        #expect(section.source == nil)
        #expect(section.notes == "")
        #expect(section.unrecognizedContent == nil)
    }

    @Test func displayNameUsesCaption() {
        var section = SlideSection()
        section.caption = "Golden hour"
        #expect(section.displayName == "Golden hour")
    }

    @Test func displayNameFallsBackToFirstImage() {
        var section = SlideSection()
        section.images = [SlideImage(filename: "sunset.jpg")]
        #expect(section.displayName == "sunset")
    }

    @Test func displayNameFallsBackToUntitled() {
        let section = SlideSection()
        #expect(section.displayName == "Untitled Slide")
    }

    @Test func primarySource() {
        var section = SlideSection()
        section.source = "© Max 2024\nDownloaded from Lightroom"
        #expect(section.primarySource == "© Max 2024")
    }

    @Test func secondarySourceLines() {
        var section = SlideSection()
        section.source = "© Max 2024\nLine 2\nLine 3"
        #expect(section.secondarySourceLines == ["Line 2", "Line 3"])
    }

    @Test func equatable() {
        let a = SlideSection(caption: "Test", images: [SlideImage(filename: "a.jpg")])
        let b = SlideSection(caption: "Test", images: [SlideImage(filename: "a.jpg")])
        #expect(a == b)
    }
}
