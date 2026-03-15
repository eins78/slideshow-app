import Foundation
import Yams

/// Writes ProjectFile back to a `slideshow.yml` file atomically.
public struct ProjectFileWriter: Sendable {
    public init() {}

    /// Write project file data to a file URL. Creates the file if it doesn't exist.
    public func write(_ projectFile: ProjectFile, to url: URL) throws {
        // Start from rawFields (preserves unknown keys), then overwrite
        // known fields — named properties take precedence over raw dict values.
        var fields = projectFile.rawFields
        fields["version"] = "\(projectFile.version)"

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
