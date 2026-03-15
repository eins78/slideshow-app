import Foundation

/// Parsed content of a `slideshow.yml` project file.
/// Value type — immutable snapshot of project-level metadata.
public struct ProjectFile: Equatable, Sendable {
    /// Well-known filename for the project file.
    public static let filename = "slideshow.yml"

    /// Schema version. Defaults to 1.
    public var version: Int

    /// Project title. Falls back to folder name when nil.
    public var title: String?

    /// All YAML key-value pairs (preserved on write, unknown keys ignored on read).
    public var rawFields: [String: String]

    public init(version: Int = 1, title: String? = nil, rawFields: [String: String] = [:]) {
        self.version = version
        self.title = title
        self.rawFields = rawFields
    }
}
