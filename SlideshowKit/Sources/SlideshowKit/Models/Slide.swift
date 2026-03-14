import Foundation
import Observation

/// A single slide in a slideshow — one image with optional sidecar data.
@Observable
public final class Slide: Identifiable {
    public let id: UUID
    public var fileURL: URL
    public var sidecar: SidecarData?
    public var exif: EXIFData?

    /// File size in bytes (read from filesystem).
    public var fileSize: Int64?

    public init(fileURL: URL, sidecar: SidecarData? = nil) {
        self.id = UUID()
        self.fileURL = fileURL
        self.sidecar = sidecar
    }

    /// Display name: caption if available, otherwise filename without prefix.
    public var displayName: String {
        sidecar?.caption ?? strippedFilename
    }

    /// Filename with the app's `\d{3}--` prefix stripped.
    public var strippedFilename: String {
        let name = fileURL.lastPathComponent
        let pattern = /^\d{3}--/
        return String(name.replacing(pattern, with: ""))
    }

    /// The sidecar file URL (image filename + ".md").
    public var sidecarURL: URL {
        fileURL.appendingPathExtension("md")
    }

    /// Whether sidecar data is currently loaded for this slide.
    public var hasSidecar: Bool {
        sidecar != nil
    }

    // MARK: - Bindable computed properties for EditorPanel

    private func ensureSidecar() {
        if sidecar == nil { sidecar = SidecarData() }
    }

    /// Bindable caption text — creates sidecar on first write.
    public var captionText: String {
        get { sidecar?.caption ?? "" }
        set { ensureSidecar(); sidecar?.caption = newValue.isEmpty ? nil : newValue }
    }

    /// Bindable source text.
    public var sourceText: String {
        get { sidecar?.source ?? "" }
        set { ensureSidecar(); sidecar?.source = newValue.isEmpty ? nil : newValue }
    }

    /// Bindable notes text.
    public var notesText: String {
        get { sidecar?.notes ?? "" }
        set { ensureSidecar(); sidecar?.notes = newValue }
    }
}
