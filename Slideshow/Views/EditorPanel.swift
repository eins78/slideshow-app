import SwiftUI
import SlideshowKit

// Binds directly to Slide computed properties (no double-state).
// Debounces disk writes at 500ms — critical for iCloud Drive.
struct EditorPanel: View {
    @Bindable var slide: Slide
    @State private var saveTask: Task<Void, Never>?

    private let sidecarWriter = SidecarWriter()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Caption")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("Slide caption", text: $slide.captionText)
                        .textFieldStyle(.roundedBorder)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Source")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("Copyright / provenance", text: $slide.sourceText, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(3...6)
                }

                Divider()

                VStack(alignment: .leading, spacing: 4) {
                    Text("Presenter Notes")
                        .font(.caption)
                        .foregroundStyle(.secondary)
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
        .onChange(of: slide.sidecar) { scheduleSave() }
    }

    private func scheduleSave() {
        saveTask?.cancel()
        saveTask = Task {
            try? await Task.sleep(for: .milliseconds(500))
            guard !Task.isCancelled else { return }
            guard let sidecar = slide.sidecar else { return }
            try? sidecarWriter.write(sidecar, to: slide.sidecarURL)
        }
    }
}
