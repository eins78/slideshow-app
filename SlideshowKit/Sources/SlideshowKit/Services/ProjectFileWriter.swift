import Foundation
import Yams

/// Writes ProjectFile back to a `slideshow.yml` file atomically.
public struct ProjectFileWriter: Sendable {
    public init() {}

    /// Write project file data to a file URL. Creates the file if it doesn't exist.
    public func write(_ projectFile: ProjectFile, to url: URL) throws {
        // Start from rawFields (preserves unknown keys), then overwrite
        // known fields — named properties take precedence over raw dict values.
        // Note: rawFields is [String: String] — lossy for complex YAML types.
        // This is acceptable for v1 (flat key-value). Future layouts (arrays/dicts)
        // will require rawFields to use a richer type (e.g. Yams.Node).
        var fields: [String: Any] = projectFile.rawFields
        fields["version"] = projectFile.version // Int, not String — avoids YAML quoting

        if let title = projectFile.title {
            fields["title"] = title
        } else {
            // Explicitly remove stale title from rawFields to prevent ghost data
            fields.removeValue(forKey: "title")
        }

        let yaml = try Yams.dump(object: fields, allowUnicode: true, sortKeys: true)
        try yaml.write(to: url, atomically: true, encoding: .utf8)
    }
}
