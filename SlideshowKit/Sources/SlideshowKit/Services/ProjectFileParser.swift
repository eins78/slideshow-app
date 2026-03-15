import Foundation
import Yams

/// Parses `slideshow.yml` project files into ProjectFile.
public struct ProjectFileParser: Sendable {
    public init() {}

    /// Parse a project file's content string into structured data.
    /// Malformed YAML or empty content returns a default ProjectFile.
    public func parse(_ content: String) -> ProjectFile {
        // Normalize CRLF → LF for cross-platform consistency (same as SidecarParser)
        let normalized = content.replacingOccurrences(of: "\r\n", with: "\n")
        let trimmed = normalized.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return ProjectFile()
        }

        guard let dict = try? Yams.load(yaml: trimmed) as? [String: Any] else {
            return ProjectFile()
        }

        // Defensive version parsing: try Int, then String→Int, default 1
        let version: Int
        if let intValue = dict["version"] as? Int {
            version = intValue
        } else if let stringValue = dict["version"] as? String, let parsed = Int(stringValue) {
            version = parsed
        } else {
            version = 1
        }

        let title = dict["title"] as? String

        // Preserve all fields as strings for round-tripping.
        // Lossy for complex YAML types — acceptable because
        // project file YAML is flat key-value pairs by design.
        var rawFields: [String: String] = [:]
        for (key, value) in dict {
            rawFields[key] = "\(value)"
        }

        return ProjectFile(
            version: version,
            title: title,
            rawFields: rawFields
        )
    }

    /// Parse a project file at the given URL.
    public func parse(url: URL) -> ProjectFile? {
        guard let content = try? String(contentsOf: url, encoding: .utf8) else {
            return nil
        }
        return parse(content)
    }
}
