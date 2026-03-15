import Foundation

/// Maps a cursor character offset to the corresponding slide index in slideshow.md text.
/// Uses line-based scanning (not AST parsing) for speed — just counts `---` separators.
public struct CursorSlideMapper: Sendable {

    public init() {}

    /// Returns the 0-based slide index for a cursor position in slideshow.md text.
    /// Returns `nil` if the cursor is in frontmatter or header (before the first slide).
    /// - Parameters:
    ///   - position: Character offset (UTF-16, matching NSTextView's selectedRange)
    ///   - text: The full slideshow.md content
    /// - Returns: Slide index (0-based), or `nil` if not in a slide section
    public func slideIndex(forCursorPosition position: Int, in text: String) -> Int? {
        guard !text.isEmpty else { return nil }

        let normalized = text.replacingOccurrences(of: "\r\n", with: "\n")
        let lines = normalized.components(separatedBy: "\n")

        // Build cumulative character offsets for each line start
        var lineStarts: [Int] = []
        lineStarts.reserveCapacity(lines.count)
        var offset = 0
        for line in lines {
            lineStarts.append(offset)
            offset += line.count + 1 // +1 for the \n
        }

        let clampedPosition = min(position, max(0, offset - 1))

        // Find which line the cursor is on
        let cursorLine = findLine(for: clampedPosition, lineStarts: lineStarts)

        // Step 1: Skip frontmatter
        let bodyStartLine = skipFrontmatter(lines: lines)

        if cursorLine < bodyStartLine {
            return nil // cursor is in frontmatter
        }

        // Step 2: Find slide separator lines (--- only, trimmed) in the body
        var separatorLines: [Int] = []
        for i in bodyStartLine..<lines.count {
            if lines[i].trimmingCharacters(in: .whitespaces) == "---" {
                separatorLines.append(i)
            }
        }

        // No separators → everything after frontmatter is header + single slide
        guard !separatorLines.isEmpty else {
            // If there's any content, treat it as slide 0
            // (matches SlideshowParser no-separator behavior: H1 is header, rest is single slide)
            return cursorLine >= bodyStartLine ? 0 : nil
        }

        // Step 3: Cursor before the first separator = header area → nil
        if cursorLine < separatorLines[0] {
            return nil
        }

        // Step 4: Cursor on the first separator (header → slide 0) → show slide 0
        if cursorLine == separatorLines[0] {
            return 0
        }

        // Step 5: Count how many separators the cursor has strictly passed.
        // Cursor ON a separator returns the preceding slide (not yet in the next one).
        var slideIndex = 0
        for i in 1..<separatorLines.count {
            if cursorLine > separatorLines[i] {
                slideIndex += 1
            }
        }

        return slideIndex
    }

    // MARK: - Private helpers

    /// Find which line index contains the given character offset.
    private func findLine(for position: Int, lineStarts: [Int]) -> Int {
        // Binary search for the last line whose start <= position
        var lo = 0
        var hi = lineStarts.count - 1
        while lo < hi {
            let mid = (lo + hi + 1) / 2
            if lineStarts[mid] <= position {
                lo = mid
            } else {
                hi = mid - 1
            }
        }
        return lo
    }

    /// Skip YAML frontmatter at the start of the file.
    /// Returns the line index where the body starts (after closing ---).
    /// Replicates SlideshowParser.extractFrontmatter logic.
    private func skipFrontmatter(lines: [String]) -> Int {
        guard !lines.isEmpty,
              lines[0].trimmingCharacters(in: .whitespaces) == "---" else {
            return 0
        }

        // Look for closing ---
        for i in 1..<lines.count {
            if lines[i].trimmingCharacters(in: .whitespaces) == "---" {
                return i + 1
            }
        }

        // No closing --- found → treat opening --- as a slide separator, not frontmatter
        return 0
    }
}
