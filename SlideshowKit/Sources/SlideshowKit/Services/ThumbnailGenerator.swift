import Foundation
import ImageIO
#if canImport(AppKit)
import AppKit
#endif

/// Generates thumbnails from image files via CGImageSource.
public struct ThumbnailGenerator: Sendable {
    public let maxPixelSize: Int

    public init(maxPixelSize: Int = 256) {
        self.maxPixelSize = maxPixelSize
    }

    /// Generate a thumbnail CGImage from a file URL.
    public func generateThumbnail(from url: URL) -> CGImage? {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else {
            return nil
        }

        let options: [CFString: Any] = [
            // IfAbsent: uses embedded JPEG thumbnail when available, only decodes
            // full image as fallback. Much faster for camera JPEGs with embedded thumbs.
            // https://developer.apple.com/documentation/imageio/kcgimagesourcecreatethumbnailfromimageifsent
            kCGImageSourceCreateThumbnailFromImageIfAbsent: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize,
            kCGImageSourceCreateThumbnailWithTransform: true,
        ]

        return CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary)
    }

    #if canImport(AppKit)
    /// Generate a thumbnail as NSImage (macOS convenience).
    public func generateNSImage(from url: URL) -> NSImage? {
        guard let cgImage = generateThumbnail(from: url) else { return nil }
        // .zero lets AppKit infer point size from pixel dimensions and backing scale,
        // avoiding Retina sizing bugs where pixels are treated as points.
        return NSImage(cgImage: cgImage, size: .zero)
    }
    #endif
}
