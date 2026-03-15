import Foundation

/// Result of scanning a folder: slides and an optional project file.
/// Not Sendable: contains [Slide] which is an @Observable class.
public struct ScanResult {
    /// Ordered list of slides found in the folder.
    public let slides: [Slide]
    /// Parsed project file, if `slideshow.yml` was found.
    public let projectFile: ProjectFile?

    public init(slides: [Slide], projectFile: ProjectFile? = nil) {
        self.slides = slides
        self.projectFile = projectFile
    }
}
