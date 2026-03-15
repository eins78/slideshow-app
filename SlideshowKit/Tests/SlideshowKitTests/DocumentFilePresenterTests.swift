import Testing
import Foundation
import os
@testable import SlideshowKit

@Suite("DocumentFilePresenter")
struct DocumentFilePresenterTests {

    private func makeTempDir() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appending(path: "presenter-test-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    private func writeSlideshowMD(
        in dir: URL,
        slides slideCount: Int = 1
    ) throws -> URL {
        let mdURL = dir.appending(path: "slideshow.md")
        var content = """
        ---
        format: https://example.com/slideshow/v1
        ---

        """
        for i in 1...slideCount {
            content += """

            ---

            ### Slide \(i)

            ![](image\(i).jpg)

            """
        }
        content += "\n---\n"
        try content.write(to: mdURL, atomically: true, encoding: .utf8)
        return mdURL
    }

    private func writeImages(in dir: URL, count: Int) throws {
        let jpeg = Data([0xFF, 0xD8, 0xFF, 0xD9])
        for i in 1...count {
            try jpeg.write(to: dir.appending(path: "image\(i).jpg"))
        }
    }

    // MARK: - Presenter tests

    @Test func presentedItemDidChangeTriggersCallback() async throws {
        let dir = try makeTempDir()
        defer { try? FileManager.default.removeItem(at: dir) }

        let mdURL = try writeSlideshowMD(in: dir)
        let callbackFired = OSAllocatedUnfairLock(initialState: false)

        let presenter = DocumentFilePresenter(url: mdURL) {
            callbackFired.withLock { $0 = true }
        }

        // Simulate the notification that NSFileCoordinator sends on external change.
        // Direct call is deterministic; coordinator integration relies on run loop
        // infrastructure not available in `swift test`.
        presenter.presentedItemDidChange()

        // Wait for debounce (500ms) + margin
        try await Task.sleep(for: .seconds(1))

        let fired = callbackFired.withLock { $0 }
        #expect(fired)
    }

    @Test func rapidWritesDebounceToSingleCallback() async throws {
        let dir = try makeTempDir()
        defer { try? FileManager.default.removeItem(at: dir) }

        let mdURL = try writeSlideshowMD(in: dir)
        let callCount = OSAllocatedUnfairLock(initialState: 0)

        let presenter = DocumentFilePresenter(url: mdURL) {
            callCount.withLock { $0 += 1 }
        }

        // Call presentedItemDidChange() directly to test debounce deterministically.
        // Coordinated writes have too much overhead for reliable sub-500ms timing.
        for _ in 0..<5 {
            presenter.presentedItemDidChange()
        }

        // Wait for debounce (500ms) + margin
        try await Task.sleep(for: .seconds(1))

        let count = callCount.withLock { $0 }
        #expect(count == 1)
    }

    @Test func selfWriteViaCordinatorSuppressesCallback() async throws {
        let dir = try makeTempDir()
        defer { try? FileManager.default.removeItem(at: dir) }

        let mdURL = try writeSlideshowMD(in: dir)
        let callbackFired = OSAllocatedUnfairLock(initialState: false)

        let presenter = DocumentFilePresenter(url: mdURL) {
            callbackFired.withLock { $0 = true }
        }
        NSFileCoordinator.addFilePresenter(presenter)
        defer { NSFileCoordinator.removeFilePresenter(presenter) }

        // Self-write via coordinator that knows about the presenter.
        // NSFileCoordinator suppresses presentedItemDidChange() for the
        // presenter that initiated the write.
        var error: NSError?
        let coordinator = NSFileCoordinator(filePresenter: presenter)
        coordinator.coordinate(
            writingItemAt: mdURL,
            options: .forReplacing,
            error: &error
        ) { url in
            try? "self change".write(to: url, atomically: true, encoding: .utf8)
        }

        // Wait to confirm no callback fires
        try await Task.sleep(for: .seconds(1))

        let fired = callbackFired.withLock { $0 }
        #expect(!fired)
    }

    @Test func presentedItemDidMoveUpdatesURL() {
        let originalURL = URL(fileURLWithPath: "/tmp/test/slideshow.md")
        let newURL = URL(fileURLWithPath: "/tmp/test/renamed.md")

        let presenter = DocumentFilePresenter(url: originalURL) { }
        presenter.presentedItemDidMove(to: newURL)

        #expect(presenter.presentedItemURL == newURL)
    }
}

// MARK: - Slideshow reload tests

@Suite("Slideshow reload")
@MainActor
struct SlideshowReloadTests {

    private func makeTempDir() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appending(path: "reload-test-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    private func writeImages(in dir: URL, names: [String]) throws {
        let jpeg = Data([0xFF, 0xD8, 0xFF, 0xD9])
        for name in names {
            try jpeg.write(to: dir.appending(path: name))
        }
    }

    private func writeMD(at url: URL, content: String) throws {
        try content.write(to: url, atomically: true, encoding: .utf8)
    }

    private func loadSlideshow(mdURL: URL) async throws -> Slideshow {
        let slideshow = Slideshow()
        let scanner = FolderScanner()
        let result = try await scanner.scan(documentURL: mdURL)
        slideshow.documentURL = mdURL
        slideshow.document = result.document ?? SlideshowDocument()
        slideshow.slides = result.slides
        if let first = result.slides.first {
            slideshow.selectedSlideID = first.id
        }
        return slideshow
    }

    @Test func reloadUpdatesSlides() async throws {
        let dir = try makeTempDir()
        defer { try? FileManager.default.removeItem(at: dir) }

        try writeImages(in: dir, names: ["image1.jpg", "image2.jpg"])
        let mdURL = dir.appending(path: "slideshow.md")
        try writeMD(at: mdURL, content: """
        ---
        format: https://example.com/slideshow/v1
        ---

        ---

        ![](image1.jpg)

        ---
        """)

        let slideshow = try await loadSlideshow(mdURL: mdURL)
        #expect(slideshow.slides.count == 1)

        // External edit adds a second slide
        try writeMD(at: mdURL, content: """
        ---
        format: https://example.com/slideshow/v1
        ---

        ---

        ![](image1.jpg)

        ---

        ![](image2.jpg)

        ---
        """)

        await slideshow.reload()
        #expect(slideshow.slides.count == 2)
    }

    @Test func selectionPreservedByFilename() async throws {
        let dir = try makeTempDir()
        defer { try? FileManager.default.removeItem(at: dir) }

        try writeImages(in: dir, names: ["alpha.jpg", "beta.jpg"])
        let mdURL = dir.appending(path: "slideshow.md")
        try writeMD(at: mdURL, content: """
        ---
        format: https://example.com/slideshow/v1
        ---

        ---

        ![](alpha.jpg)

        ---

        ![](beta.jpg)

        ---
        """)

        let slideshow = try await loadSlideshow(mdURL: mdURL)
        // Select the second slide (beta.jpg)
        slideshow.selectedSlideID = slideshow.slides[1].id
        #expect(slideshow.selectedSlide?.section.images.first?.filename == "beta.jpg")

        // Reorder: beta first, alpha second
        try writeMD(at: mdURL, content: """
        ---
        format: https://example.com/slideshow/v1
        ---

        ---

        ![](beta.jpg)

        ---

        ![](alpha.jpg)

        ---
        """)

        await slideshow.reload()
        // Selection should follow beta.jpg to index 0
        #expect(slideshow.selectedSlide?.section.images.first?.filename == "beta.jpg")
        #expect(slideshow.selectedIndex == 0)
    }

    @Test func selectionPreservedByCaption() async throws {
        let dir = try makeTempDir()
        defer { try? FileManager.default.removeItem(at: dir) }

        let mdURL = dir.appending(path: "slideshow.md")
        try writeMD(at: mdURL, content: """
        ---
        format: https://example.com/slideshow/v1
        ---

        ---

        ### First

        ---

        ### Second

        ---
        """)

        let slideshow = try await loadSlideshow(mdURL: mdURL)
        slideshow.selectedSlideID = slideshow.slides[1].id
        #expect(slideshow.selectedSlide?.section.caption == "Second")

        // Reorder captions
        try writeMD(at: mdURL, content: """
        ---
        format: https://example.com/slideshow/v1
        ---

        ---

        ### Second

        ---

        ### First

        ---
        """)

        await slideshow.reload()
        #expect(slideshow.selectedSlide?.section.caption == "Second")
        #expect(slideshow.selectedIndex == 0)
    }

    @Test func selectionClampsWhenSlideRemoved() async throws {
        let dir = try makeTempDir()
        defer { try? FileManager.default.removeItem(at: dir) }

        try writeImages(in: dir, names: ["a.jpg", "b.jpg", "c.jpg"])
        let mdURL = dir.appending(path: "slideshow.md")
        try writeMD(at: mdURL, content: """
        ---
        format: https://example.com/slideshow/v1
        ---

        ---

        ![](a.jpg)

        ---

        ![](b.jpg)

        ---

        ![](c.jpg)

        ---
        """)

        let slideshow = try await loadSlideshow(mdURL: mdURL)
        // Select last slide (index 2)
        slideshow.selectedSlideID = slideshow.slides[2].id

        // Remove last two slides, only a.jpg remains
        try writeMD(at: mdURL, content: """
        ---
        format: https://example.com/slideshow/v1
        ---

        ---

        ![](a.jpg)

        ---
        """)

        await slideshow.reload()
        // Selection should clamp to last available index (0)
        #expect(slideshow.slides.count == 1)
        #expect(slideshow.selectedIndex == 0)
    }

    @Test func noopReloadWhenUnchanged() async throws {
        let dir = try makeTempDir()
        defer { try? FileManager.default.removeItem(at: dir) }

        try writeImages(in: dir, names: ["image1.jpg"])
        let mdURL = dir.appending(path: "slideshow.md")
        try writeMD(at: mdURL, content: """
        ---
        format: https://example.com/slideshow/v1
        ---

        ---

        ![](image1.jpg)

        ---
        """)

        let slideshow = try await loadSlideshow(mdURL: mdURL)
        let originalSlideID = slideshow.slides.first?.id

        // Reload without changing file — slides should keep same IDs
        await slideshow.reload()
        #expect(slideshow.slides.first?.id == originalSlideID)
    }
}
