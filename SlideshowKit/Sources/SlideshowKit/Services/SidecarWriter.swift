import Foundation
import Yams

/// Writes SidecarData back to a `.md` file atomically.
public struct SidecarWriter: Sendable {
    public init() {}

    /// Write sidecar data to a file URL. Creates the file if it doesn't exist.
    public func write(_ data: SidecarData, to url: URL) throws {
        var output = ""

        // Build frontmatter if we have structured fields
        if data.caption != nil || data.source != nil || !data.rawFrontmatter.isEmpty {
            // Start from rawFrontmatter (preserves unknown keys), then overwrite
            // known fields — named properties take precedence over raw dict values.
            var frontmatter = data.rawFrontmatter
            if let caption = data.caption { frontmatter["caption"] = caption }
            if let source = data.source { frontmatter["source"] = source }

            let yaml = try Yams.dump(object: frontmatter, allowUnicode: true, sortKeys: true)
            output += "---\n\(yaml)---"
            if !data.notes.isEmpty {
                output += "\n\n"
            }
        }

        // Append notes
        if !data.notes.isEmpty {
            output += data.notes
            if !output.hasSuffix("\n") {
                output += "\n"
            }
        }

        try output.write(to: url, atomically: true, encoding: .utf8)
    }
}
