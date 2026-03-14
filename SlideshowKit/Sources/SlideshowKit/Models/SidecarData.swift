import Foundation

/// Parsed content of a sidecar `.md` file.
/// Value type — immutable snapshot of parsed sidecar content.
public struct SidecarData: Equatable, Sendable {
    /// Short description shown in file list and below preview.
    public var caption: String?
    /// Provenance/copyright. First line = primary credit, rest = secondary.
    public var source: String?
    /// Presenter notes as raw markdown string.
    public var notes: String
    /// All frontmatter key-value pairs (preserved on write, unknown keys ignored on read).
    public var rawFrontmatter: [String: String]

    public init(caption: String? = nil, source: String? = nil, notes: String = "", rawFrontmatter: [String: String] = [:]) {
        self.caption = caption
        self.source = source
        self.notes = notes
        self.rawFrontmatter = rawFrontmatter
    }

    /// Primary source line (first line of source field).
    public var primarySource: String? {
        source?.components(separatedBy: "\n").first
    }

    /// Secondary source lines (all lines after the first).
    public var secondarySourceLines: [String] {
        guard let source else { return [] }
        let lines = source.components(separatedBy: "\n")
        return lines.count > 1 ? Array(lines.dropFirst()) : []
    }
}
