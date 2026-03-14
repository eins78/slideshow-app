import Foundation
import Observation

/// Manages security-scoped bookmarks for persistent folder access across app launches.
/// Properly balances startAccessingSecurityScopedResource / stopAccessingSecurityScopedResource.
/// See: https://developer.apple.com/documentation/foundation/url/1779698-startaccessingsecurityscopedreso
@Observable
@MainActor
final class BookmarkManager {
    private let bookmarksKey = "savedBookmarks"
    private let defaults: UserDefaults
    /// Currently active security-scoped URL (must be stopped before switching).
    var activeSecurityScopedURL: URL?

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    /// Save a security-scoped bookmark for a URL.
    func saveBookmark(for url: URL) {
        guard let data = try? url.bookmarkData(
            options: .withSecurityScope,
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        ) else { return }

        var bookmarks = defaults.dictionary(forKey: bookmarksKey) as? [String: Data] ?? [:]
        bookmarks[url.path(percentEncoded: false)] = data
        defaults.set(bookmarks, forKey: bookmarksKey)
    }

    /// Resolve a previously saved bookmark and start accessing the security-scoped resource.
    func resolveBookmark(for path: String) -> URL? {
        guard let bookmarks = defaults.dictionary(forKey: bookmarksKey) as? [String: Data],
              let data = bookmarks[path] else { return nil }

        var isStale = false
        guard let url = try? URL(
            resolvingBookmarkData: data,
            options: .withSecurityScope,
            bookmarkDataIsStale: &isStale
        ) else { return nil }

        if isStale { saveBookmark(for: url) }

        stopAccessingActiveResource()

        guard url.startAccessingSecurityScopedResource() else { return nil }
        activeSecurityScopedURL = url
        return url
    }

    /// Stop accessing the currently active security-scoped resource.
    func stopAccessingActiveResource() {
        activeSecurityScopedURL?.stopAccessingSecurityScopedResource()
        activeSecurityScopedURL = nil
    }

    /// Get all saved bookmark paths (for recent files list).
    func recentPaths() -> [String] {
        let bookmarks = defaults.dictionary(forKey: bookmarksKey) as? [String: Data] ?? [:]
        return Array(bookmarks.keys)
    }
}
