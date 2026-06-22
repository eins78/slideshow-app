# Slide active/inactive toggle with auto-import

- **Type:** feature
- **Status:** Draft
- **Created:** 2026-03-15
- **Slug:** `unused-images`

## Problem

When curating a slideshow from a folder of images, the user has no visibility into which images exist in the folder but aren't referenced in `slideshow.md`. They must manually cross-reference filenames. There's also no way to temporarily disable a slide without deleting it from the markdown.

## Proposal

**One unified mechanism:** every image in the folder is always represented as a slide in `slideshow.md`. New/unmatched images are auto-added as commented-out (inactive) slides. A checkbox toggle activates or deactivates any slide.

### How it works

1. **Auto-import:** When a slideshow is opened/rescanned, any image in the folder not already referenced in the document is appended as a new commented-out slide section
2. **Toggle:** Each slide has an `isActive` flag. In list/grid view, a checkbox toggles it
3. **Persistence:** Inactive slides are wrapped in HTML comments in `slideshow.md`:
   ```markdown
   ---
   <!-- ## Sunset over lake

   ![](sunset.jpg)

   > Photo by Jane

   Taken during golden hour -->
   ```
4. **Display:** Inactive slides appear dimmed in the list/grid but remain visible and reorderable
5. **Presentation:** Only active slides are shown in presentation mode
6. **EXIF enrichment:** Auto-imported slides read EXIF data — prefer the "caption" field written by Apple Photos.app, fall back to date taken, camera info, GPS

### Status bar

Shows active and total count: `5 of 12 slides` (not "hidden" — they're simply not selected).

### No separate unused section

Since every folder image gets a slide entry (active or commented-out), there's no concept of "unused images" as a separate UI section. The slide list IS the complete inventory. Users discover new images by seeing new inactive slides appear at the bottom after adding files to the folder.

## Design

### Model changes (`Slide`)

- Add `isActive: Bool` property (default `true`)
- Inactive slides still have full `SlideSection` content (caption, images, source, notes)

### Parser changes (`SlideshowParser`)

- Detect `<!-- ... -->` HTML comment blocks between `---` separators
- Parse the content inside the comment as a normal slide section
- Mark resulting slide as `isActive = false`
- Must handle: comment spanning entire slide section, nested markdown inside comment

### Writer changes (`SlideshowWriter`)

- Inactive slides: wrap entire slide content in `<!-- ... -->`
- Active slides: write normally (no change)
- Round-trip: parse commented slide → write → parse must preserve all content and inactive state

### Scanner changes (`FolderScanner`)

- After parsing document, compute unreferenced images (already done via `availableImages`)
- For each unreferenced image: create a new inactive `SlideSection` with EXIF-enriched content
- Append these new sections to the document's slide list
- On save, these become commented-out entries in the `.md` file

### EXIF enrichment for auto-imported slides

Priority for caption:
1. IPTC/XMP "Caption" or "Description" field (written by Apple Photos.app, Lightroom, etc.)
2. IPTC/XMP "Title" field
3. Filename without extension (fallback)

Additional metadata for notes:
- Date taken
- Camera model
- GPS coordinates (if present)

### UI changes

- **SlideRowView:** Add checkbox (leading position) to toggle `isActive`
- **SlideRowView:** Dimmed opacity + strikethrough or muted style when inactive
- **SlideGridItem:** Visual indicator for inactive state (dimmed thumbnail, badge, or overlay)
- **ContentView status bar:** Show `"N of M slides"` where N = active, M = total
- **Presentation mode:** Filter to `slides.filter(\.isActive)` — inactive slides skipped entirely
- **DisclosureGroup:** Inactive slides grouped in a collapsible section (defaults open)

## Branches

- `feature/unused-images-model` — `isActive` on Slide, EXIF caption reading, parser/writer HTML comment support, round-trip tests
- `feature/unused-images-scanner` — FolderScanner auto-import of unreferenced images as inactive slides
- `feature/unused-images-ui` — checkbox toggle, dimmed styling, status bar count, presentation filter, collapsible inactive section

## Decisions made

- **One mechanism, not two:** every image is in the document. Toggle is the only way to include/exclude. No separate "unused images" panel.
- **HTML comments for persistence:** `<!-- ... -->` wrapping. Standard markdown, invisible to renderers, content fully preserved.
- **Status bar terminology:** "N of M slides" — not "hidden", just "not selected"
- **EXIF caption source:** Prefer Apple Photos.app caption field for auto-imported slides
- **Collapsible inactive section:** DisclosureGroup, defaults open
- **Overlap resolved:** No overlap possible — every image is either in an active slide or an inactive slide, never in a separate "unused" bucket
