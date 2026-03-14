import Testing
@testable import SlideshowKit

@Suite("SidecarData")
struct SidecarDataTests {
    @Test("primarySource returns first line of source")
    func primarySource() {
        let data = SidecarData(source: "© Author 2024\nDownloaded from Lightroom")
        #expect(data.primarySource == "© Author 2024")
    }

    @Test("primarySource returns single-line source unchanged")
    func singleLineSource() {
        let data = SidecarData(source: "© Author 2024")
        #expect(data.primarySource == "© Author 2024")
    }

    @Test("primarySource returns nil when source is nil")
    func nilSource() {
        let data = SidecarData()
        #expect(data.primarySource == nil)
    }

    @Test("secondarySourceLines returns lines after first")
    func secondaryLines() {
        let data = SidecarData(source: "Line 1\nLine 2\nLine 3")
        #expect(data.secondarySourceLines == ["Line 2", "Line 3"])
    }

    @Test("secondarySourceLines returns empty for single-line source")
    func noSecondaryLines() {
        let data = SidecarData(source: "Only line")
        #expect(data.secondarySourceLines.isEmpty)
    }

    @Test("secondarySourceLines returns empty when source is nil")
    func nilSecondaryLines() {
        let data = SidecarData()
        #expect(data.secondarySourceLines.isEmpty)
    }

    @Test("Equatable compares all fields")
    func equatable() {
        let a = SidecarData(caption: "A", source: "S", notes: "N", rawFrontmatter: ["k": "v"])
        let b = SidecarData(caption: "A", source: "S", notes: "N", rawFrontmatter: ["k": "v"])
        let c = SidecarData(caption: "B", notes: "N")
        #expect(a == b)
        #expect(a != c)
    }
}
