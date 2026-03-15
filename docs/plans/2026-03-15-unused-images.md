# Display unused images section and slide active/inactive toggle

- **Type:** feature
- **Status:** Draft
- **Created:** 2026-03-15
- **Slug:** `unused-images`

## Problem

When curating a slideshow from a folder of images, the user has no visibility into which images exist in the folder but aren't referenced in `slideshow.md`. They must manually cross-reference filenames. There's also no way to temporarily disable a slide without deleting it from the markdown.

## Proposal

Two complementary features:

### 1. Unused images section

- In both list view and grid view, show a distinct "Unused Images" section below the active slides
- This section displays images present in the folder but not referenced in `slideshow.md`
- Dragging an unused image into the slide list adds it to the markdown document at the drop position
- The section updates live as images are added/removed from the slideshow

### 2. Slide active/inactive toggle

- Each slide has an "active" state (default: active)
- In list view, a checkbox allows toggling a slide inactive
- Inactive slides are written as HTML comments in `slideshow.md`: `<!-- ... -->`
- Inactive slides appear dimmed in the list/grid but remain visible for re-activation
- Inactive slides are excluded from presentation mode
- The toggle is non-destructive — all slide content (caption, notes, source) is preserved

## Design considerations

- **Which approach is primary?** Both features complement each other:
  - Unused images section = discovery ("what's in the folder?")
  - Active toggle = curation ("keep it in the doc but skip it for now")
- **Drag and drop** must respect slide ordering — dropped image inserts at position, not appended
- **Comment syntax:** HTML comments (`<!-- -->`) are standard markdown and survive most processors
- **FolderScanner** already tracks available images — the diff between available and referenced gives unused
- **SlideshowParser** needs to handle commented-out slide sections (parse but mark inactive)
- **SlideshowWriter** needs to wrap inactive slides in comments on write-back

## Branches

<!-- Fill in during refinement -->

- `feature/unused-images-model` — model changes: inactive flag on Slide, unused image tracking
- `feature/unused-images-parser` — parser/writer support for HTML comment toggle
- `feature/unused-images-ui` — list/grid section for unused images, checkbox toggle, drag-to-add

## Open questions

- Should inactive slides count toward the slide number/total in the status bar?
- Should the unused images section be collapsible?
- What happens when an image is both in an inactive slide AND would appear in unused? (Show only in inactive slide, not in unused section)
- Should drag-to-add create a minimal slide (just `![](filename.jpg)`) or prompt for caption?
- How does this interact with the slideshow.md format spec's `---` separators for commented-out slides?
