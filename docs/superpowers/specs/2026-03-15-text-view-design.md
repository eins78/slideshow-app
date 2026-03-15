# Text View — Design Spec

> Add a `.text` view mode to the middle column that shows the full `slideshow.md` document as read-only plain text.

## Context

The data-format branch (`idea/data-format`, PR #10) replaces per-image `.md` sidecars with a single `slideshow.md` file per slideshow. This is the canonical document — all slide content lives in one markdown file with YAML frontmatter, an H1 title, and `---`-separated slide sections.

The text view is the first UI change after this data-format migration. It gives users direct visibility into the underlying document, complementing the visual list/grid modes.

## Motivation

First step of the UI overhaul following the data-format change. Users working with `slideshow.md` as a document (editing in external editors, reviewing in version control, sharing as text) need to see the full document content inside the app. The list and grid modes show slides as discrete items — the text view shows them as a continuous document.

## Design

### ViewMode Extension

Add `.text` to the existing `ContentView.ViewMode` enum:

```swift
enum ViewMode: String, CaseIterable {
    case list, grid, text
}
```

Add a third segment to the toolbar picker with SF Symbol `doc.plaintext`.

Update the picker frame width to accommodate three segments (~120pt from current ~80pt).

### SlideListPanel Branch

Add a `.text` case to the view mode switch in `SlideListPanel.body`:

```swift
switch viewMode {
case .list: listView
case .grid: gridView
case .text: SlideshowTextView(slideshow: slideshow)
}
```

### SlideshowTextView (New File)

A new SwiftUI view at `Slideshow/Views/SlideshowTextView.swift`.

**Responsibilities:**
- Serialize the current in-memory `SlideshowDocument` to markdown text using `SlideshowWriter`
- Display the result as read-only monospaced text in a `ScrollView`
- Update when the document changes (Observation handles this — `slideshow.document` and `slideshow.slides` are `@Observable` properties)

**Implementation outline:**

```swift
struct SlideshowTextView: View {
    var slideshow: Slideshow

    private var documentText: String {
        var doc = slideshow.document
        doc.slides = slideshow.slides.map(\.section)
        return SlideshowWriter().write(doc)
    }

    var body: some View {
        ScrollView {
            Text(documentText)
                .font(.system(.body, design: .monospaced))
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
        }
        .accessibilityLabel("Slideshow document text")
    }
}
```

**Key decisions:**

1. **In-memory serialization, not disk read.** Uses `SlideshowWriter.write(document)` to generate text from the current model state. This means the text view always reflects unsaved edits, staying consistent with what list/grid show. Reading the file from disk would show stale state between saves.

2. **Computed property, not cached.** `documentText` is a computed property that re-evaluates when Observation detects changes to `slideshow.document` or `slideshow.slides`. For typical slideshow sizes (10-100 slides), serialization is trivially fast. No caching needed.

3. **Read-only.** No editing, no `TextEditor`. Users edit via the EditorPanel (inspector) or an external editor. The text view is for reading/reviewing.

4. **No slide selection sync.** Clicking in the text view does not select a slide. No scroll-to-current-slide. These are future enhancements, not v1.

5. **Text selection enabled.** Users can select and copy text from the view — useful for sharing snippets.

### Accessibility

- `accessibilityLabel` on the ScrollView container
- Monospaced system font respects Dynamic Type via `.system(.body, design: .monospaced)`
- Text selection is VoiceOver-compatible
- The toolbar picker segments already need `accessibilityLabel`s — add "List view", "Grid view", "Text view" labels to each segment's `Image`

### Searchability

The existing `searchText` filtering in `SlideListPanel` applies to list/grid modes (filters by slide display name). In text mode, search filtering does not apply — the full document is always shown. The search field remains visible but has no effect in text mode. This is acceptable for v1; a future enhancement could highlight matches in the text.

## What This Does Not Include

- Syntax highlighting or markdown rendering
- Editing in the text view
- Click-to-select-slide (tapping a slide section to select it)
- Scroll-to-current-slide (auto-scrolling to the selected slide's section)
- Line numbers
- Find-in-text (beyond macOS standard Cmd+F, which SwiftUI `Text` does not support natively)

Each of these could be a follow-up feature. The v1 goal is simply: see the document.

## Files Changed

| File | Change |
|------|--------|
| `Slideshow/Views/ContentView.swift` | Add `.text` to `ViewMode`, add picker segment, widen picker |
| `Slideshow/Views/SlideListPanel.swift` | Add `.text` switch branch |
| `Slideshow/Views/SlideshowTextView.swift` | **New file** — read-only document text view |

## Dependencies

- Requires `data-format` branch to be merged first (PR #10) — `SlideshowDocument`, `SlideshowWriter`, and the new `Slideshow.document` property are all introduced there.

## Testing

- **Unit test (SlideshowKit):** Not needed — `SlideshowWriter` is already tested on the data-format branch. The text view is a pure display of its output.
- **SwiftUI preview:** Add preview with sample `Slideshow` containing a few slides with captions and notes.
- **UI test:** Add a test that switches to text view mode and verifies the document text is displayed (checks for presence of the slideshow title text in the view).
- **Accessibility audit:** Include `testAccessibilityAudit()` covering the text view.
