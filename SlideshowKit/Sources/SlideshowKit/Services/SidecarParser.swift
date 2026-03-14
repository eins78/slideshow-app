import Foundation
import Yams

/// Parses `.md` sidecar files into SidecarData.
public struct SidecarParser: Sendable {
    public init() {}

    /// Parse a sidecar file's content string into structured data.
    public func parse(_ content: String) -> SidecarData {
        // Normalize CRLF → LF to handle Windows-edited sidecars
        let normalized = content.replacingOccurrences(of: "\r\n", with: "\n")
        let trimmed = normalized.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return SidecarData()
        }

        // Try frontmatter extraction (must start with --- on line 1)
        if let (frontmatterYAML, body) = extractFrontmatter(trimmed) {
            if let data = parseFrontmatter(frontmatterYAML, body: body) {
                return data
            }
            // Malformed YAML: treat entire content as plain text
            return SidecarData(notes: trimmed)
        }

        // No frontmatter: try heading fallback
        return parseHeadingFallback(trimmed)
    }

    /// Parse a sidecar file at the given URL.
    public func parse(url: URL) -> SidecarData? {
        guard let content = try? String(contentsOf: url, encoding: .utf8) else {
            return nil
        }
        return parse(content)
    }

    // MARK: - Private

    /// Extract frontmatter between --- delimiters. Returns (yaml, body) or nil.
    private func extractFrontmatter(_ content: String) -> (String, String)? {
        let lines = content.components(separatedBy: "\n")
        guard lines.first?.trimmingCharacters(in: .whitespaces) == "---" else {
            return nil
        }

        // Find closing ---
        var closingIndex: Int?
        for i in 1..<lines.count {
            if lines[i].trimmingCharacters(in: .whitespaces) == "---" {
                closingIndex = i
                break
            }
        }

        guard let closing = closingIndex else {
            return nil
        }

        let yamlLines = lines[1..<closing]
        let bodyLines = lines[(closing + 1)...]
        let yaml = yamlLines.joined(separator: "\n")
        let body = bodyLines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)

        return (yaml, body)
    }

    /// Parse YAML frontmatter into SidecarData.
    private func parseFrontmatter(_ yaml: String, body: String) -> SidecarData? {
        guard let dict = try? Yams.load(yaml: yaml) as? [String: Any] else {
            return nil
        }

        let caption = dict["caption"] as? String
        let source = dict["source"] as? String

        // Preserve all fields as strings for round-tripping
        var rawFrontmatter: [String: String] = [:]
        for (key, value) in dict {
            rawFrontmatter[key] = "\(value)"
        }

        return SidecarData(
            caption: caption,
            source: source?.trimmingCharacters(in: .whitespacesAndNewlines),
            notes: body,
            rawFrontmatter: rawFrontmatter
        )
    }

    /// Fallback: first # heading = caption, rest = notes.
    private func parseHeadingFallback(_ content: String) -> SidecarData {
        let lines = content.components(separatedBy: "\n")

        for (i, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("# ") {
                let caption = String(trimmed.dropFirst(2))
                let remainingLines = lines[(i + 1)...]
                let notes = remainingLines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
                return SidecarData(caption: caption, notes: notes)
            }
        }

        // No heading found: everything is notes
        return SidecarData(notes: content)
    }
}
