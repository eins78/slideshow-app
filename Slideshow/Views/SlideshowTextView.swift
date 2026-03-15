import SwiftUI
import SlideshowKit

/// Editable text view showing the full `slideshow.md` document.
/// Text buffer is the source of truth while editing; model updated only on save.
struct SlideshowTextView: View {
    @Bindable var slideshow: Slideshow
    @Binding var isDirty: Bool
    @Binding var saveTrigger: Bool
    var hostWindow: NSWindow?

    @State private var text = ""
    @State private var lastSavedText = ""
    @State private var isUpdatingFromSave = false

    var body: some View {
        TextEditor(text: $text)
            .font(.system(.body, design: .monospaced))
            .accessibilityLabel("Slideshow document")
            .accessibilityIdentifier("slideshowTextEditor")
            .task {
                loadTextFromModel()
            }
            .onChange(of: text) {
                let dirty = text != lastSavedText
                isDirty = dirty
                hostWindow?.isDocumentEdited = dirty
            }
            .onChange(of: saveTrigger) {
                guard saveTrigger else { return }
                saveTextToModel()
                saveTrigger = false
            }
            .onChange(of: slideshow.document) {
                guard !isUpdatingFromSave, !isDirty else { return }
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
            }
    }

    private func loadTextFromModel() {
        var doc = slideshow.document
        doc.slides = slideshow.slides.map(\.section)
        let serialized = SlideshowWriter().write(doc)
        text = serialized
        lastSavedText = serialized
        isDirty = false
        hostWindow?.isDocumentEdited = false
    }

    private func saveTextToModel() {
        isUpdatingFromSave = true
        defer { isUpdatingFromSave = false }
        do {
            try slideshow.saveRawText(text)
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
