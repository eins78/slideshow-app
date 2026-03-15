import Foundation
import os

/// Watches a `slideshow.md` file for external changes using `NSFilePresenter`.
///
/// Chosen over `DispatchSource` because:
/// - iCloud Drive correct (important for target users)
/// - Self-write suppression is automatic when writing via `NSFileCoordinator(filePresenter:)`
/// - Detects file moves/renames
///
/// `Sendable` because all mutable state is protected by `OSAllocatedUnfairLock`.
/// See: https://developer.apple.com/documentation/foundation/nsfilepresenter
public final class DocumentFilePresenter: NSObject, NSFilePresenter, Sendable {
    /// Debounce interval for coalescing rapid writes.
    static let debounceInterval: TimeInterval = 0.5

    /// Protected by lock — written by `presentedItemDidMove(to:)` on the operation queue.
    /// See: https://developer.apple.com/documentation/os/osallocatedunfairlock
    private let _presentedItemURL: OSAllocatedUnfairLock<URL?>
    public var presentedItemURL: URL? { _presentedItemURL.withLock { $0 } }
    public let presentedItemOperationQueue: OperationQueue

    private let onChange: @Sendable () -> Void
    private let debounceQueue: DispatchQueue
    /// Monotonic counter for debounce cancellation. Each `presentedItemDidChange` increments
    /// the counter; the delayed closure only fires if its snapshot still matches.
    private let _generation: OSAllocatedUnfairLock<UInt64>

    public init(url: URL, onChange: @escaping @Sendable () -> Void) {
        self._presentedItemURL = OSAllocatedUnfairLock(initialState: url)
        self.onChange = onChange
        self._generation = OSAllocatedUnfairLock(initialState: 0)
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        queue.qualityOfService = .utility
        self.presentedItemOperationQueue = queue
        self.debounceQueue = DispatchQueue(label: "is.ars.slideshow.file-presenter-debounce")
        super.init()
    }

    // MARK: - NSFilePresenter

    public func presentedItemDidChange() {
        let onChange = onChange
        let generation = _generation
        let snapshot = generation.withLock { value -> UInt64 in
            value &+= 1
            return value
        }
        debounceQueue.asyncAfter(deadline: .now() + Self.debounceInterval) {
            guard generation.withLock({ $0 }) == snapshot else { return }
            onChange()
        }
    }

    public func presentedItemDidMove(to newURL: URL) {
        _presentedItemURL.withLock { $0 = newURL }
    }
}
