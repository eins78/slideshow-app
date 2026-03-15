import SwiftUI
import SlideshowKit

/// Editable text view showing the full `slideshow.md` document.
/// Text buffer is the source of truth while editing; model updated only on save.
/// Provides debounced live preview and cursor-following slide selection.
struct SlideshowTextView: View {
    @Bindable var slideshow: Slideshow
    @Binding var isDirty: Bool
    @Binding var saveTrigger: Bool
    var hostWindow: NSWindow?

    @State private var text = ""
    @State private var lastSavedText = ""
    /// Tracks the last document state we know about (from load or save).
    /// Used to distinguish self-writes from external file changes in onChange.
    @State private var lastSeenDocument: SlideshowDocument?

    /// Cursor character offset reported by MarkdownTextEditor.
    @State private var cursorPosition: Int = 0
    /// Cached parse result for cursor-move preview (avoids re-parsing on cursor movement).
    @State private var parsedPreviewDoc: SlideshowDocument?
    /// Debounce task for live preview parsing.
    @State private var debounceTask: Task<Void, Never>?

    private let mapper = CursorSlideMapper()

    var body: some View {
        MarkdownTextEditor(
            text: $text,
            onCursorPositionChange: { position in
                cursorPosition = position
                updatePreviewForCursor(position: position)
            }
        )
        .accessibilityLabel("Slideshow document")
        .accessibilityIdentifier("slideshowTextEditor")
        .task {
            lastSeenDocument = slideshow.document
            loadTextFromModel()
        }
        .onChange(of: text) {
            let dirty = text != lastSavedText
            isDirty = dirty
            hostWindow?.isDocumentEdited = dirty
            scheduleLivePreviewUpdate()
        }
        .onChange(of: saveTrigger) {
            guard saveTrigger else { return }
            saveTextToModel()
            saveTrigger = false
        }
        .onChange(of: slideshow.document) {
            // Skip if this is our own save (document matches what we just wrote)
            guard slideshow.document != lastSeenDocument else { return }
            lastSeenDocument = slideshow.document
            guard !isDirty else { return }
            loadTextFromModel()
        }
        .task {
            for await _ in NotificationCenter.default.notifications(
                named: NSApplication.willResignActiveNotification
            ) {
                if isDirty {
                    saveTextToModel()
                }
            }
        }
        .task(id: hostWindow) {
            guard let window = hostWindow else { return }
            for await _ in NotificationCenter.default.notifications(
                named: NSWindow.willCloseNotification,
                object: window
            ) {
                if isDirty {
                    saveTextToModel()
                }
            }
        }
        .onDisappear {
            if isDirty {
                saveTextToModel()
            }
            debounceTask?.cancel()
            slideshow.livePreview = nil
        }
    }

    // MARK: - Live preview

    /// Schedule a debounced parse for live preview (300ms after last keystroke).
    private func scheduleLivePreviewUpdate() {
        debounceTask?.cancel()
        let currentText = text
        let currentCursor = cursorPosition
        debounceTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            let parser = SlideshowParser()
            let doc = parser.parse(currentText)
            parsedPreviewDoc = doc
            updatePreviewForCursor(
                doc: doc,
                text: currentText,
                position: currentCursor
            )
        }
    }

    /// Update the live preview based on cursor position using cached parse result.
    /// Called immediately on cursor movement (no debounce — just line counting).
    private func updatePreviewForCursor(position: Int) {
        guard let doc = parsedPreviewDoc else { return }
        updatePreviewForCursor(doc: doc, text: text, position: position)
    }

    /// Update the live preview for a specific parse result and cursor position.
    private func updatePreviewForCursor(
        doc: SlideshowDocument,
        text: String,
        position: Int
    ) {
        guard let index = mapper.slideIndex(forCursorPosition: position, in: text),
              index < doc.slides.count else {
            slideshow.livePreview = LivePreview()
            return
        }
        let section = doc.slides[index]
        let imageURL: URL?
        if let folderURL = slideshow.folderURL,
           let filename = section.images.first?.filename {
            imageURL = folderURL.appending(path: filename)
        } else {
            imageURL = nil
        }
        slideshow.livePreview = LivePreview(
            slideSection: section,
            slideIndex: index,
            imageURL: imageURL
        )
    }

    // MARK: - Model sync

    private func loadTextFromModel() {
        var doc = slideshow.document
        doc.slides = slideshow.slides.map(\.section)
        let serialized = SlideshowWriter().write(doc)
        text = serialized
        lastSavedText = serialized
        isDirty = false
        hostWindow?.isDocumentEdited = false

        // Initialize live preview from loaded text
        let parser = SlideshowParser()
        parsedPreviewDoc = parser.parse(serialized)
        updatePreviewForCursor(position: cursorPosition)
    }

    private func saveTextToModel() {
        do {
            try slideshow.saveRawText(text)
            lastSeenDocument = slideshow.document
            lastSavedText = text
            isDirty = false
            hostWindow?.isDocumentEdited = false
        } catch {
            // Leave dirty state unchanged — user still sees unsaved indicator
        }
    }
}

#Preview("Text View") {
    let slideshow = Slideshow()
    let doc = SlideshowDocument(
        frontmatter: ["format": SlideshowDocument.formatURL],
        title: "My Slideshow",
        slides: [
            SlideSection(
                caption: "Welcome",
                images: [SlideImage(filename: "intro.jpg")],
                notes: "Opening remarks"
            ),
            SlideSection(
                caption: "Golden hour",
                images: [SlideImage(filename: "sunset.jpg")],
                source: "\u{00A9} Photographer"
            ),
        ]
    )
    slideshow.document = doc
    slideshow.slides = doc.slides.map { Slide(section: $0) }
    return SlideshowTextView(
        slideshow: slideshow,
        isDirty: .constant(false),
        saveTrigger: .constant(false)
    )
    .frame(width: 400, height: 500)
}
