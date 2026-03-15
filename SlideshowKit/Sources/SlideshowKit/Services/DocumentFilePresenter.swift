import Foundation

/// Watches a `slideshow.md` file for external changes using `NSFilePresenter`.
///
/// Chosen over `DispatchSource` because:
/// - iCloud Drive correct (important for target users)
/// - Self-write suppression is automatic when writing via `NSFileCoordinator(filePresenter:)`
/// - Detects file moves/renames
///
/// See: https://developer.apple.com/documentation/foundation/nsfilepresenter
public final class DocumentFilePresenter: NSObject, NSFilePresenter {
    /// Debounce interval for coalescing rapid writes.
    static let debounceInterval: TimeInterval = 0.5

    public private(set) var presentedItemURL: URL?
    public let presentedItemOperationQueue: OperationQueue

    private let onChange: @Sendable () -> Void
    private let debounceQueue: DispatchQueue
    /// Accessed only on `debounceQueue` — serial access, no synchronization needed.
    private var pendingWork: DispatchWorkItem?

    public init(url: URL, onChange: @escaping @Sendable () -> Void) {
        self.presentedItemURL = url
        self.onChange = onChange
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        queue.qualityOfService = .utility
        self.presentedItemOperationQueue = queue
        self.debounceQueue = DispatchQueue(label: "is.ars.slideshow.file-presenter-debounce")
        super.init()
    }

    // MARK: - NSFilePresenter

    public func presentedItemDidChange() {
        debounceQueue.async { [self] in
            pendingWork?.cancel()
            let work = DispatchWorkItem { [onChange] in
                onChange()
            }
            pendingWork = work
            debounceQueue.asyncAfter(
                deadline: .now() + Self.debounceInterval,
                execute: work
            )
        }
    }

    public func presentedItemDidMove(to newURL: URL) {
        presentedItemURL = newURL
    }
}
