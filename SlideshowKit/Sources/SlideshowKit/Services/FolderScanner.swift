import Foundation
import UniformTypeIdentifiers

/// Scans a folder for image files and matches them with sidecar `.md` files.
public struct FolderScanner: Sendable {
    private let sidecarParser = SidecarParser()
    private let projectFileParser = ProjectFileParser()

    public init() {}

    /// Scan a folder URL and return an ordered list of Slides.
    public func scan(folderURL: URL) async throws -> [Slide] {
        try await scanWithProjectFile(folderURL: folderURL).slides
    }

    /// Scan a folder URL and return slides with an optional project file.
    public func scanWithProjectFile(folderURL: URL) async throws -> ScanResult {
        let fileManager = FileManager.default
        let contents = try fileManager.contentsOfDirectory(
            at: folderURL,
            includingPropertiesForKeys: [.fileSizeKey, .contentTypeKey],
            options: [.skipsHiddenFiles]
        )

        // Separate images, sidecars, and project file
        var imageURLs: [URL] = []
        var sidecarURLs: [String: URL] = [:] // lowercased image filename -> sidecar URL
        var projectFile: ProjectFile?

        for url in contents {
            let filename = url.lastPathComponent

            // Skip project file from image/sidecar classification
            if filename == ProjectFile.filename {
                projectFile = projectFileParser.parse(url: url)
                continue
            }

            let ext = url.pathExtension.lowercased()
            if ext == "md" {
                // Sidecar: strip .md to get the image filename
                let imageFilename = url.deletingPathExtension().lastPathComponent.lowercased()
                sidecarURLs[imageFilename] = url
            } else if isImageFile(url) {
                imageURLs.append(url)
            }
        }

        // Sort images alphabetically
        imageURLs.sort { $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending }

        // Build slides
        var slides: [Slide] = []
        for imageURL in imageURLs {
            let lowercasedName = imageURL.lastPathComponent.lowercased()
            let sidecar: SidecarData?
            if let sidecarURL = sidecarURLs[lowercasedName] {
                sidecar = sidecarParser.parse(url: sidecarURL)
            } else {
                sidecar = nil
            }

            let slide = Slide(fileURL: imageURL, sidecar: sidecar)

            // Read file size
            if let resourceValues = try? imageURL.resourceValues(forKeys: [.fileSizeKey]),
               let size = resourceValues.fileSize {
                slide.fileSize = Int64(size)
            }

            slides.append(slide)
        }

        return ScanResult(slides: slides, projectFile: projectFile)
    }

    // Fast-path on extension set, fallback to UTType for rare extensions
    private static let imageExtensions: Set<String> = [
        "jpg", "jpeg", "png", "heic", "heif", "tiff", "tif",
        "raw", "dng", "cr2", "cr3", "nef", "arw", "orf", "rw2", "webp"
    ]

    /// Check if a URL points to a supported image file.
    private func isImageFile(_ url: URL) -> Bool {
        let ext = url.pathExtension.lowercased()
        if Self.imageExtensions.contains(ext) { return true }
        // Fallback for uncommon extensions — uses prefetched contentType
        guard let type = try? url.resourceValues(forKeys: [.contentTypeKey]).contentType else {
            return false
        }
        return type.conforms(to: .image)
    }
}
