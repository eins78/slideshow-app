import Foundation
#if canImport(AppKit)
import AppKit
#endif

/// Thread-safe image cache with thumbnail and full-resolution tiers.
/// Shared across views via SwiftUI environment to prevent duplicate loads.
/// See: https://developer.apple.com/documentation/swift/actor
///
/// Known limitation: I/O is synchronous inside the actor, which serializes loads.
/// Acceptable for MVP (~200 slides, <10ms per embedded thumb). For large libraries,
/// move I/O to Task.detached and use actor only for cache storage.
public actor ImageCache {
    private let thumbnailCache = NSCache<NSURL, CGImage>()
    private let fullImageCache = NSCache<NSURL, CGImage>()
    private let thumbnailGenerator: ThumbnailGenerator

    public init(thumbnailPixelSize: Int = 1024, fullCacheCountLimit: Int = 10) {
        self.thumbnailGenerator = ThumbnailGenerator(maxPixelSize: thumbnailPixelSize)
        fullImageCache.countLimit = fullCacheCountLimit
        thumbnailCache.countLimit = 200
    }

    /// Get a thumbnail (fast, cached, max 1024px).
    /// Falls back to NSImage when CGImageSource fails (e.g., unsupported formats).
    public func thumbnail(for url: URL) -> CGImage? {
        let key = url as NSURL
        if let cached = thumbnailCache.object(forKey: key) { return cached }
        if let image = thumbnailGenerator.generateThumbnail(from: url) {
            thumbnailCache.setObject(image, forKey: key)
            return image
        }
        #if canImport(AppKit)
        // Fallback: NSImage supports additional formats beyond CGImageSource
        guard let nsImage = NSImage(contentsOf: url),
              let cg = nsImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return nil
        }
        thumbnailCache.setObject(cg, forKey: key)
        return cg
        #else
        return nil
        #endif
    }

    /// Get full-resolution image (cached LRU, limited count).
    /// Falls back to NSImage when CGImageSource fails (e.g., unsupported formats).
    public func fullImage(for url: URL) -> CGImage? {
        let key = url as NSURL
        if let cached = fullImageCache.object(forKey: key) { return cached }
        if let source = CGImageSourceCreateWithURL(url as CFURL, nil),
           let image = CGImageSourceCreateImageAtIndex(source, 0, nil) {
            fullImageCache.setObject(image, forKey: key)
            return image
        }
        #if canImport(AppKit)
        // Fallback: NSImage supports additional formats beyond CGImageSource
        guard let nsImage = NSImage(contentsOf: url),
              let cg = nsImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return nil
        }
        fullImageCache.setObject(cg, forKey: key)
        return cg
        #else
        return nil
        #endif
    }

    #if canImport(AppKit)
    /// Convenience: thumbnail as NSImage.
    public func thumbnailNSImage(for url: URL) -> NSImage? {
        guard let cg = thumbnail(for: url) else { return nil }
        return NSImage(cgImage: cg, size: .zero)
    }

    /// Convenience: full-resolution as NSImage.
    public func fullNSImage(for url: URL) -> NSImage? {
        guard let cg = fullImage(for: url) else { return nil }
        return NSImage(cgImage: cg, size: .zero)
    }
    #endif

    /// Preload thumbnails for upcoming slides (call from presentation mode).
    public func preloadThumbnails(for urls: [URL]) {
        for url in urls { _ = thumbnail(for: url) }
    }
}
