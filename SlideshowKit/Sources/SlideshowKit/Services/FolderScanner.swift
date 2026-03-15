import Foundation
import UniformTypeIdentifiers

/// Scans a folder for images and parses `slideshow.md` if present.
public struct FolderScanner: Sendable {
    private let slideshowParser = SlideshowParser()

    public init() {}

    /// Scan a folder URL. Looks for `slideshow.md`, parses it, builds slides.
    /// If no `slideshow.md` found, falls back to one slide per image.
    public func scan(folderURL: URL) async throws -> ScanResult {
        let fm = FileManager.default
        let contents = try fm.contentsOfDirectory(
            at: folderURL,
            includingPropertiesForKeys: [.fileSizeKey, .contentTypeKey],
            options: [.skipsHiddenFiles]
        )

        // Discover all images in the folder
        let imageURLs = contents
            .filter { isImageFile($0) }
            .sorted { $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending }

        let imageFilenames = imageURLs.map(\.lastPathComponent)

        // Look for slideshow.md (case-insensitive)
        let slideshowMD = contents.first {
            $0.lastPathComponent.lowercased() == SlideshowDocument.defaultFilename.lowercased()
        }

        if let mdURL = slideshowMD {
            return try buildFromDocument(
                mdURL: mdURL,
                folderURL: folderURL,
                imageURLs: imageURLs,
                imageFilenames: imageFilenames
            )
        }

        // No slideshow.md — fallback: one slide per image
        return buildFromImages(
            folderURL: folderURL,
            imageURLs: imageURLs
        )
    }

    /// Scan from a specific `.md` file URL.
    public func scan(documentURL: URL) async throws -> ScanResult {
        let folderURL = documentURL.deletingLastPathComponent()
        let fm = FileManager.default
        let contents = try fm.contentsOfDirectory(
            at: folderURL,
            includingPropertiesForKeys: [.fileSizeKey, .contentTypeKey],
            options: [.skipsHiddenFiles]
        )

        let imageURLs = contents
            .filter { isImageFile($0) }
            .sorted { $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending }

        let imageFilenames = imageURLs.map(\.lastPathComponent)

        return try buildFromDocument(
            mdURL: documentURL,
            folderURL: folderURL,
            imageURLs: imageURLs,
            imageFilenames: imageFilenames
        )
    }

    // MARK: - Private

    private func buildFromDocument(
        mdURL: URL,
        folderURL: URL,
        imageURLs: [URL],
        imageFilenames: [String]
    ) throws -> ScanResult {
        guard let doc = slideshowParser.parse(url: mdURL) else {
            // Unreadable .md — fall back to image-only
            return buildFromImages(folderURL: folderURL, imageURLs: imageURLs)
        }

        // Build slides from document sections
        var slides: [Slide] = []
        var referencedFilenames: Set<String> = []

        for section in doc.slides {
            let slide = Slide(section: section)
            slide.resolveImageURLs(
                relativeTo: folderURL,
                availableFiles: imageFilenames
            )

            // Read file size from primary image
            if let primaryURL = slide.primaryImageURL,
               let rv = try? primaryURL.resourceValues(forKeys: [.fileSizeKey]),
               let size = rv.fileSize {
                slide.fileSize = Int64(size)
            }

            slides.append(slide)

            for image in section.images {
                referencedFilenames.insert(image.filename.lowercased())
            }
        }

        // Find images not referenced in the document
        let availableImages = imageURLs.filter { url in
            !referencedFilenames.contains(url.lastPathComponent.lowercased())
        }

        return ScanResult(
            slides: slides,
            document: doc,
            documentURL: mdURL,
            availableImages: availableImages
        )
    }

    private func buildFromImages(
        folderURL: URL,
        imageURLs: [URL]
    ) -> ScanResult {
        let slides = imageURLs.map { imageURL -> Slide in
            let section = SlideSection(
                images: [SlideImage(filename: imageURL.lastPathComponent)]
            )
            let slide = Slide(section: section)
            slide.resolveImageURLs(relativeTo: folderURL)

            if let rv = try? imageURL.resourceValues(forKeys: [.fileSizeKey]),
               let size = rv.fileSize {
                slide.fileSize = Int64(size)
            }

            return slide
        }

        return ScanResult(slides: slides)
    }

    // MARK: - Image detection

    private static let imageExtensions: Set<String> = [
        "jpg", "jpeg", "png", "heic", "heif", "tiff", "tif",
        "raw", "dng", "cr2", "cr3", "nef", "arw", "orf", "rw2", "webp"
    ]

    private func isImageFile(_ url: URL) -> Bool {
        let ext = url.pathExtension.lowercased()
        if Self.imageExtensions.contains(ext) { return true }
        guard let type = try? url.resourceValues(forKeys: [.contentTypeKey]).contentType else {
            return false
        }
        return type.conforms(to: .image)
    }
}
