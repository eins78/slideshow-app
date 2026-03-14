import Foundation
#if canImport(AppKit)
import AppKit
#endif
#if canImport(UIKit)
import UIKit
#endif

/// Thread-safe image cache with thumbnail and full-resolution tiers.
/// Shared across views via SwiftUI environment to prevent duplicate loads.
/// See: https://developer.apple.com/documentation/swift/actor
///
/// I/O runs on detached tasks to avoid blocking the cooperative thread pool.
/// The actor serializes cache reads/writes only (near-instant).
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
    /// I/O runs on a detached task to avoid blocking the cooperative thread pool.
    /// Falls back to NSImage when CGImageSource fails (e.g., unsupported formats).
    public func thumbnail(for url: URL) async -> CGImage? {
        let key = url as NSURL
        if let cached = thumbnailCache.object(forKey: key) { return cached }
        let generator = thumbnailGenerator
        let image: CGImage? = await Task.detached {
            if let cg = generator.generateThumbnail(from: url) { return cg }
            #if canImport(AppKit)
            guard let nsImage = NSImage(contentsOf: url),
                  let cg = nsImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
                return nil
            }
            return cg
            #else
            return nil
            #endif
        }.value
        if let image {
            thumbnailCache.setObject(image, forKey: key)
        }
        return image
    }

    /// Get full-resolution image (cached LRU, limited count).
    /// I/O runs on a detached task to avoid blocking the cooperative thread pool.
    /// Falls back to NSImage when CGImageSource fails (e.g., unsupported formats).
    public func fullImage(for url: URL) async -> CGImage? {
        let key = url as NSURL
        if let cached = fullImageCache.object(forKey: key) { return cached }
        let image: CGImage? = await Task.detached {
            if let source = CGImageSourceCreateWithURL(url as CFURL, nil),
               let cg = CGImageSourceCreateImageAtIndex(source, 0, nil) {
                return cg
            }
            #if canImport(AppKit)
            guard let nsImage = NSImage(contentsOf: url),
                  let cg = nsImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
                return nil
            }
            return cg
            #else
            return nil
            #endif
        }.value
        if let image {
            fullImageCache.setObject(image, forKey: key)
        }
        return image
    }

    #if canImport(AppKit)
    /// Convenience: thumbnail as NSImage.
    public func thumbnailNSImage(for url: URL) async -> NSImage? {
        guard let cg = await thumbnail(for: url) else { return nil }
        return NSImage(cgImage: cg, size: .zero)
    }

    /// Convenience: full-resolution as NSImage.
    public func fullNSImage(for url: URL) async -> NSImage? {
        guard let cg = await fullImage(for: url) else { return nil }
        return NSImage(cgImage: cg, size: .zero)
    }
    #endif

    #if canImport(UIKit)
    /// Convenience: thumbnail as UIImage.
    public func thumbnailUIImage(for url: URL) async -> UIImage? {
        guard let cg = await thumbnail(for: url) else { return nil }
        return UIImage(cgImage: cg)
    }

    /// Convenience: full-resolution as UIImage.
    public func fullUIImage(for url: URL) async -> UIImage? {
        guard let cg = await fullImage(for: url) else { return nil }
        return UIImage(cgImage: cg)
    }
    #endif

    /// Preload thumbnails for upcoming slides (call from presentation mode).
    /// Loads concurrently via TaskGroup for better throughput.
    public func preloadThumbnails(for urls: [URL]) async {
        await withTaskGroup(of: Void.self) { group in
            for url in urls {
                group.addTask { _ = await self.thumbnail(for: url) }
            }
        }
    }
}
