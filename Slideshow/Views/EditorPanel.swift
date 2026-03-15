import SwiftUI
import SlideshowKit

// Binds directly to Slide computed properties (no double-state).
// Debounces disk writes at 500ms — critical for iCloud Drive.
struct EditorPanel: View {
    var slideshow: Slideshow
    @Bindable var slide: Slide
    @State private var saveTask: Task<Void, Never>?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Caption")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .accessibilityAddTraits(.isHeader)
                    TextField("Slide caption", text: $slide.captionText)
                        .textFieldStyle(.roundedBorder)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Source")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .accessibilityAddTraits(.isHeader)
                    TextField("Copyright / provenance", text: $slide.sourceText, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(3...6)
                }

                Divider()

                VStack(alignment: .leading, spacing: 4) {
                    Text("Presenter Notes")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .accessibilityAddTraits(.isHeader)
                    TextEditor(text: $slide.notesText)
                        .font(.system(.body, design: .monospaced))
                        .frame(minHeight: 150)
                        .scrollContentBackground(.hidden)
                        .padding(4)
                        .background(Color(nsColor: .textBackgroundColor))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
            }
            .padding(12)
        }
        .onChange(of: slide.section) { scheduleSave() }
    }

    private func scheduleSave() {
        saveTask?.cancel()
        saveTask = Task {
            try? await Task.sleep(for: .milliseconds(500))
            guard !Task.isCancelled else { return }
            try? slideshow.save()
        }
    }
}

#Preview("Editor Panel") {
    let slideshow = Slideshow()
    let slide = Slide(section: SlideSection(
        caption: "Golden hour",
        images: [SlideImage(filename: "sunset.jpg")],
        source: "© Photographer 2024",
        notes: "Beautiful sunset over the lake.\n\n**Key points:**\n- Warm tones\n- Reflection"
    ))
    return EditorPanel(slideshow: slideshow, slide: slide)
        .frame(width: 280, height: 500)
}
