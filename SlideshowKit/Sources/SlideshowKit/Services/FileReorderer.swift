import Foundation

/// Handles file renaming for slide reordering and collision avoidance.
public struct FileReorderer: Sendable {
    public init() {}

    /// Strip the app's `\d{3}--` prefix from a filename, if present.
    public func stripPrefix(_ filename: String) -> String {
        String(filename.replacing(/^\d{3}--/, with: ""))
    }

    /// Compute new filenames for a list of filenames in their desired order.
    /// Input: filenames in new order. Output: filenames with `001--` prefixes.
    public func computeNewNames(for filenames: [String]) -> [String] {
        filenames.enumerated().map { index, name in
            let stripped = stripPrefix(name)
            let prefix = String(format: "%03d--", index + 1)
            return prefix + stripped
        }
    }

    /// Get the sidecar filename for a given image filename.
    public func sidecarName(for imageFilename: String) -> String {
        imageFilename + ".md"
    }

    /// Generate a non-colliding filename given existing names in the folder.
    public func deconflictedName(_ filename: String, existing: Set<String>) -> String {
        if !existing.contains(filename) { return filename }

        let stem = (filename as NSString).deletingPathExtension
        let ext = (filename as NSString).pathExtension

        var counter = 2
        while true {
            let candidate = "\(stem) \(counter).\(ext)"
            if !existing.contains(candidate) { return candidate }
            counter += 1
        }
    }

    /// Perform the two-pass rename on disk.
    /// - Parameters:
    ///   - folderURL: The folder containing the files.
    ///   - orderedFilenames: Current filenames in desired new order.
    /// - Returns: Array of (oldURL, newURL) pairs that were renamed.
    public func reorder(in folderURL: URL, orderedFilenames: [String]) throws -> [(old: URL, new: URL)] {
        let fm = FileManager.default
        let newNames = computeNewNames(for: orderedFilenames)

        // Build rename plan: (currentURL, tempURL, finalURL)
        // Skip files that don't need renaming
        var plan: [(current: URL, temp: URL, final: URL)] = []

        for (i, currentName) in orderedFilenames.enumerated() {
            guard currentName != newNames[i] else { continue } // Skip no-op renames
            let currentURL = folderURL.appending(path: currentName)
            let tempName = "__reorder_\(UUID().uuidString)_\(currentName)"
            let tempURL = folderURL.appending(path: tempName)
            let finalURL = folderURL.appending(path: newNames[i])
            plan.append((currentURL, tempURL, finalURL))

            // Also handle sidecar if it exists
            let sidecarCurrent = folderURL.appending(path: sidecarName(for: currentName))
            if fm.fileExists(atPath: sidecarCurrent.path(percentEncoded: false)) {
                let sidecarTemp = folderURL.appending(path: "__reorder_\(UUID().uuidString)_\(sidecarName(for: currentName))")
                let sidecarFinal = folderURL.appending(path: sidecarName(for: newNames[i]))
                plan.append((sidecarCurrent, sidecarTemp, sidecarFinal))
            }
        }

        // Phase 1: rename all to temp names
        for item in plan {
            try fm.moveItem(at: item.current, to: item.temp)
        }

        // Phase 2: rename from temp to final names
        var results: [(old: URL, new: URL)] = []
        for item in plan {
            try fm.moveItem(at: item.temp, to: item.final)
            results.append((item.current, item.final))
        }

        return results
    }
}
