# Plan: Add QuickLook preview for spacebar peek on slides

- **Status:** Draft
- **Type:** feature
- **Created:** 2026-03-15
- **Slug:** `quicklook-preview`

## Problem

There is no way to quickly peek at a full-resolution slide without entering presentation mode. Users browsing the slide grid/list should be able to hit spacebar (or click) to get a Finder-style QuickLook preview — the standard macOS pattern for previewing files.

## Solution

Use SwiftUI's built-in `.quickLookPreview(_:in:)` modifier to add spacebar-triggered previews of slides. This is a single modifier + a `@State` binding — minimal code, standard platform behavior.

## Design

### API

```swift
import QuickLook

// On the view that contains the slide grid/list:
@State private var quickLookURL: URL?

// In body:
.quickLookPreview($quickLookURL, in: slideshow.slides.map(\.fileURL))
```

### Trigger

- **Spacebar** on selected slide in the editor grid/list (when not in presentation mode)
- Optionally: click/tap on thumbnail in preview panel

### Behavior

- Setting `quickLookURL` to non-nil opens the QuickLook modal window
- The `in:` parameter provides the full list of slide URLs, enabling arrow-key navigation between slides within the preview
- User dismisses by pressing spacebar again, escape, or clicking the close button
- SwiftUI resets the binding to `nil` on dismiss automatically

### Scope

- Add `.quickLookPreview()` modifier to the main editor view (slide grid/list)
- Wire spacebar key press to toggle the preview for the selected slide
- No changes to `AudienceView` or `PresenterView` — those are presentation concerns, not browsing

### What this is NOT

- Not a replacement for the audience/presenter windows
- Not a custom preview implementation — uses the system QuickLook panel
- The preview is **modal** on macOS (blocks app interaction while open) — this is expected system behavior

## Branches

- `feature/quicklook-preview` — implementation

## Risks

- **Low:** The `.quickLookPreview()` modal blocks interaction with the main window. This matches Finder behavior and is acceptable for a peek action.
- **Low:** Console warnings about `QLPreviewPanel` delegate/dataSource are cosmetic noise from SwiftUI's internal bridging — not actionable.
- **Low:** If an `NSTextView` has focus when triggered, it can intercept the QuickLook panel. Mitigation: ensure the grid/list view has focus, not a text field.

## Checklist

- [ ] Add `import QuickLook` to the editor view
- [ ] Add `@State private var quickLookURL: URL?` binding
- [ ] Add `.quickLookPreview($quickLookURL, in:)` modifier
- [ ] Wire spacebar `.onKeyPress(.space)` to set the binding (only when not in presentation mode)
- [ ] Test: spacebar opens preview, arrow keys navigate, dismiss resets binding
- [ ] Accessibility: verify QuickLook window is accessible (system-provided, should be by default)
