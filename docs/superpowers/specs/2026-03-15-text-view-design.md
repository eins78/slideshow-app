# Text View & Inspector Removal — Design Spec

> Replace the inspector sidebar with an editable text view of the full `slideshow.md` document, with TextEdit-style saving.

## Context

The data-format branch (PR #10) replaces per-image `.md` sidecars with a single `slideshow.md` file per slideshow. This markdown document contains YAML frontmatter, an H1 title, and `---`-separated slide sections with captions, images, source attribution, and presenter notes.

With the document as the canonical format, editing it directly is more natural than filling in separate fields in an inspector panel. This change removes the inspector and adds an editable text view as the primary editing interface.

## Motivation

UI overhaul after the data-format change. The inspector's EditorPanel (caption, source, notes fields) and FileInfoPanel (EXIF metadata) add complexity without proportional value for MVP. List and grid modes remain important for visual reordering; everything else is more ergonomic in plain text.

## Design

### Layout

Remove the inspector sidebar entirely. The layout becomes two panes:

```
PreviewPanel (left)  |  SlideListPanel (right: list / grid / text)
```

The toolbar picker gains a third segment for text mode (SF Symbol `doc.plaintext`).

### SlideshowTextView

New view at `Slideshow/Views/SlideshowTextView.swift`.

**Responsibilities:**
- Display the full `slideshow.md` content in an editable `TextEditor` with monospaced system font
- Track dirty state (text modified since last load/save)
- Save on Cmd+S, auto-save on app deactivation
- Parse edited text back into the model on save

**State management:**

```swift
struct SlideshowTextView: View {
    var slideshow: Slideshow
    @State private var text: String = ""
    @State private var lastSavedText: String = ""

    private var isDirty: Bool { text != lastSavedText }
}
```

The `text` buffer is the source of truth while editing. The model is not updated on every keystroke — only on save. This avoids cursor jumps, expensive mid-edit re-parsing, and observation feedback loops.

**Entering text mode:** Serialize the current model via `SlideshowWriter.write(document)` into the text buffer. Set `lastSavedText` to the same value.

**Save flow:**
1. Parse `text` via `SlideshowParser.parse(_:)` → `SlideshowDocument`
2. Update `slideshow.document` and rebuild `slideshow.slides` from parsed sections
3. Write to disk via `SlideshowWriter.write(document, to: url)`
4. Set `lastSavedText = text`
5. Set `NSWindow.isDocumentEdited = false`

**Leaving text mode:** If dirty, save first, then switch. List/grid views observe the freshly updated model.

### Saving Behavior

Modeled after TextEdit.app without adopting `NSDocument`:

| Trigger | Mechanism |
|---------|-----------|
| Cmd+S | `CommandGroup(replacing: .saveItems)` in the app's `.commands` block, routed via `@FocusedValue` to the active text view. Using `.keyboardShortcut("s")` on a local button won't work reliably because `TextEditor` swallows keyboard events while it holds first responder. |
| App deactivation | `NotificationCenter` → `NSApplication.willResignActiveNotification` |
| Window close | `NSWindow.willCloseNotification` on the hosting window. Window close does **not** trigger `willResignActiveNotification` if the app remains active (e.g., other windows open). Must be an explicit, separate trigger. |
| View disappear | `.onDisappear` as a safety net — saves if dirty when the view is removed from the hierarchy |
| View mode switch | Check dirty state before switching from `.text` to `.list`/`.grid` |

**Accessing the hosting window:**

Do **not** use `NSApp.keyWindow` — it is unreliable in SwiftUI (popovers, alerts, and multiple windows shift key window status). Instead, use a small `NSViewRepresentable` to capture the view's actual `NSView.window` reference:

```swift
struct WindowAccessor: NSViewRepresentable {
    @Binding var window: NSWindow?
    func makeNSView(context: Context) -> NSView { NSView() }
    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async { window = nsView.window }
    }
}
```

This gives a reliable window reference for setting `isDocumentEdited`.

Dirty state drives:
- **Title bar dot:** `window?.isDocumentEdited` via the captured hosting window reference
- **Save-on-deactivation / window close:** Only saves if dirty
- **View mode switch:** Only parses if dirty

### Parse Error Handling

`SlideshowParser` is lenient by design:
- Any text between `---` separators becomes a slide section
- Unrecognized content is preserved in `SlideSection.unrecognizedContent`
- Malformed YAML frontmatter → treated as plain text

The raw text is always written to disk as-is — it's valid markdown regardless of how well it round-trips through the parser. If parsing produces unexpected slide structure, the user sees the effect when switching to list/grid view and can correct it in the text.

### External Model Changes

If the model is updated externally while the text view is active (e.g., future file watcher from PR #14, or a structural operation triggered from another view), the text buffer becomes stale:

- **If not dirty:** silently refresh the text buffer from the model via `.onChange(of:)` watching a model generation counter or the slides array
- **If dirty:** conflict — for MVP, prefer the user's in-progress edits (don't overwrite). A future enhancement could show a conflict banner.

### Structural Operations

Reorder, add, and remove in list/grid mode continue to modify the model directly and call `slideshow.save()`. When the user switches to text mode, the text buffer is regenerated from the current model state. No conflict because text mode always starts fresh.

### Accessibility

- `TextEditor` supports VoiceOver natively
- Monospaced system font respects Dynamic Type via `.system(.body, design: .monospaced)`
- Toolbar picker segments need `accessibilityLabel`s: "List view", "Grid view", "Text view"
- Cmd+S save action needs an accessible label

### What Gets Deleted

| File | Reason |
|------|--------|
| `EditorPanel.swift` | Replaced by direct text editing |
| `FileInfoPanel.swift` | EXIF display deferred past MVP |

From `ContentView.swift`:
- `.inspector(isPresented:)` modifier and its content
- `.inspectorColumnWidth()` modifier
- `showInspector` state variable
- Inspector toggle toolbar button with Cmd+Opt+I shortcut

### What Stays

- `PreviewPanel` — image preview + rendered notes (left pane)
- `SlideListPanel` list/grid modes — visual reordering
- `Slide.captionText`, `.sourceText`, `.notesText` computed properties — clean API, future use
- `MarkdownRenderedView`, `SourceTextView` — used by PreviewPanel
- `DraggableDivider` — used by PreviewPanel
- All of SlideshowKit — no changes needed

## Dependencies

- Requires data-format branch (PR #10) merged first: `SlideshowDocument`, `SlideshowParser`, `SlideshowWriter`, `Slideshow.document`

## Testing

- **Unit tests (SlideshowKit):** Not needed — parser/writer already tested on data-format branch
- **SwiftUI preview:** Add preview with sample slideshow content in the text editor
- **UI test:** Switch to text mode, verify document text appears, edit text, verify dirty state
- **Accessibility audit:** `testAccessibilityAudit()` covering the text view
- **Round-trip test:** Edit text → save → switch to list → verify slides reflect changes → switch to text → verify text matches
