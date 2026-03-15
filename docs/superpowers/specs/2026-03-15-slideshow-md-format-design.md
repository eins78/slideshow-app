# Design: `slideshow.md` project file format

> Replace per-image sidecar files and `slideshow.yml` with a single human-readable markdown file that defines a curated image slideshow.

## Context

The app presents image-heavy slideshows — photography portfolios, art critiques, visual essays. A slideshow project is a folder of images. The user curates a subset, orders them, and adds captions, credits, and presenter notes.

The previous format used per-image `.md` sidecar files (`photo.jpg.md`) and a separate `slideshow.yml` for project metadata. This design replaces both with a single `slideshow.md` file per presentation.

### Design goals

1. **Human-readable and editable** — a non-technical user can open it in any text editor and understand what they see
2. **Valid markdown** — renders meaningfully in any markdown viewer (GitHub, VS Code, iA Writer, etc.)
3. **Forgiving parser** — unknown content is preserved, not discarded; malformed input degrades gracefully
4. **Multiple presentations per folder** — the same images can appear in different `.md` files with different orderings and metadata
5. **No image modification** — the app never renames, converts, or moves image files

### Comparison with iA Presenter

iA Presenter serves writers whose workflow begins with text, then splits into slides. This app serves visual storytellers whose workflow begins with collecting and curating images, then adding text to support them. The format reflects this: images are the primary element, text is optional enhancement.

## Format specification

### File structure

```
My Portfolio/
├── slideshow.md              (the presentation)
├── client-review.md          (another presentation of the same images)
├── golden-hour.jpg
├── bridge-sunset.jpg
├── bridge-morning.jpg
└── README.md                 (optional, can link to slideshow.md)
```

### Full example

```markdown
---
format: https://example.com/slideshow/v1
---

# Paintings That Tell Secrets

---

### Golden hour, Wollishofen

![Lakeside view at sunset](golden-hour.jpg)

> © Max Albrecht 2024
> Downloaded from Lightroom CC

My presenter notes about this shot.
The light was perfect at 6pm.

Still notes — blank lines are fine within notes.

---

### The old bridge at sunset

![](bridge-sunset.jpg)

> © Max Albrecht 2024

---

### Introduction

Welcome to this portfolio review.

---

### The bridge evolves

![](bridge-morning.jpg)
![](bridge-noon.jpg)
![](bridge-sunset.jpg)

> © Max Albrecht 2024

Three moments, one structure.

---
```

### Elements

#### Project header

The file begins with optional YAML frontmatter followed by an optional H1 title.

```markdown
---
format: https://example.com/slideshow/v1
---

# My Presentation Title
```

- **Frontmatter** — optional. Contains machine-readable fields. Unknown keys are preserved on round-trip.
  - `format` — URL pointing to format documentation. Acts as a format identifier.
  - Future fields (e.g., `theme`, `aspect-ratio`) can be added without breaking older parsers.
- **H1 heading** — optional. The presentation title. Falls back to the filename (without `.md`), then the folder name, then "Untitled."
- Content between the H1 and the first `---` separator is project-level presenter notes (displayed on the title slide or as a preamble).

#### Slide separator

```markdown
---
```

A horizontal rule (`---`) on its own line separates slides. This is the universal convention across all markdown presentation tools (Deckset, Marp, Slidev, reveal.js, remark.js, HedgeDoc, iA Presenter).

- Must be exactly `---` on its own line (not `***` or `___`)
- The first `---` after the header begins the first slide
- The last `---` in the file closes the last slide (optional but recommended)

#### Caption

```markdown
### Golden hour, Wollishofen
```

An H3 heading (`###`) within a slide section. Displayed as the slide's caption/title.

- At most one caption per slide (first H3 wins; additional H3s are treated as unknown content)
- Optional — slides without a caption are valid
- Position within the slide section does not matter (parser extracts it regardless of where it appears)

#### Image reference

```markdown
![Alt text for accessibility](filename.jpg)
```

Standard markdown image syntax. References an image file in the same folder as the `.md` file.

- **Filename only** — no paths, no URLs. The image must be in the same directory as the project file.
- **Filename escaping** — filenames with spaces or special characters (parentheses, etc.) must be valid CommonMark. The writer uses angle bracket syntax for such filenames: `![](<my image (1).jpg>)`. The parser accepts both plain and angle-bracketed filenames.
- **Alt text** — optional. Used as the accessibility description (VoiceOver). If empty (`![](file.jpg)`), the app falls back to the caption, then the image's own filename (per-image, not per-slide).
- **Multiple images per slide** — 0 to N images allowed. Each `![](...)` on its own line is a separate image in the slide.
- **Zero images** — valid. Creates a text-only slide (title card, section divider, placeholder for future image, cue to switch to another app).
- **Only images referenced in the file are in the show.** Images in the folder but not mentioned in any `![](...)` reference are not part of the presentation. The folder is the library; the file is the curated selection.

#### Source / credit

```markdown
> © Max Albrecht 2024
> Downloaded from Lightroom CC
```

Markdown blockquote (`>` prefix). Used for attribution, copyright, provenance.

- Multi-line: each line prefixed with `>`. A blockquote is contiguous as long as there is no blank line between `>` lines. A blank line between `>` lines starts a new blockquote.
- First line is the primary credit (displayed on slide); subsequent lines are secondary (shown in detail view)
- Optional — slides without source are valid
- At most one blockquote block per slide (first contiguous blockquote wins; additional blockquotes are treated as unrecognized content)

#### Presenter notes

```markdown
My notes about this shot.
The light was perfect at 6pm.

Blank lines within notes are fine.
They remain part of the notes.
```

Paragraph nodes — text blocks that swift-markdown parses as `Paragraph` elements. This is the presenter-only content, not shown on the audience display. Non-paragraph block elements (tables, code blocks, ordered/unordered lists, HTML blocks) are NOT notes — they become unrecognized content.

- Can contain blank lines between paragraphs (blank lines do NOT end the notes section)
- Can contain inline markdown formatting (bold, italic, links) — preserved as-is
- Extends until the next `---` separator or `### Unrecognized content` heading

#### Unrecognized content

```markdown
### Unrecognized content

| some | table |
|------|-------|
| the  | app   |
| didn't | understand |
```

When the app writes back a slide that contained markdown elements it didn't parse into known fields (tables, code blocks, lists, HTML, nested headings other than H3, etc.), those elements are collected under a `### Unrecognized content` heading at the end of the slide section.

- Only appears on write-back — the app creates this section, the user doesn't need to
- Content is preserved verbatim — nothing is lost
- If the user manually edits this section (moves content out, deletes it), the app respects the change
- On subsequent reads, the `### Unrecognized content` section is parsed as opaque text and stored alongside the slide
- Purpose: make misunderstood content visible and actionable, rather than silently hiding it

### Parse rules

#### Reading

1. **Normalize** — CRLF → LF.
2. **Detect frontmatter** — if the file starts with `---` on line 1, scan forward for a closing `---` on its own line. If no closing delimiter is found, treat the initial `---` as a slide separator (do not invoke the YAML parser). If a closing delimiter exists, attempt to parse the enclosed text as YAML. If the YAML is valid and contains at least one key, consume both `---` delimiters (they are NOT slide separators). If the YAML is malformed or empty (e.g., the opening `---` was actually a slide separator), do NOT consume it — rewind and treat the initial `---` as the first slide separator. Missing frontmatter → valid file, just no project metadata.
3. **Parse header** — everything between the frontmatter (or start of file) and the first remaining `---` is the header. Extract and remove the first H1 as title. The remaining header content (all AST nodes after H1 removal) is preserved verbatim as an opaque blob — this ensures no content is lost (tables, lists, code blocks, etc. in the header are preserved just like slide-level unrecognized content). The H1 is NOT included in the blob to prevent duplication on write-back.
4. **Split remainder on `---`** — divide into slide sections. A trailing `---` followed by only whitespace does not create an empty slide.
5. **For each slide section**, extract:
   - If a `### Unrecognized content` heading (exact text) is found, everything from that heading to the end of the slide section is stored as an opaque blob (raw markdown string, excluding the heading itself). No further extraction is performed on nodes within the blob. This heading is NEVER treated as a caption.
   - First other `### Heading` → caption
   - **Image extraction** — only from top-level `Paragraph` nodes: if a paragraph contains one or more `Image` inline nodes, extract them as image references (ordered by appearance). A paragraph that contains ONLY image nodes (and whitespace) is consumed entirely (not included in notes). A paragraph that mixes images with other text: extract the images, keep the remaining text as notes. Images inside non-paragraph blocks (tables, lists, blockquotes, code blocks) are NOT extracted — they remain in the unrecognized content blob.
   - First contiguous `> blockquote` → source/credit. Additional blockquotes → unrecognized content.
   - Remaining `Paragraph` nodes (those not fully consumed by image extraction) → presenter notes (concatenated in order, preserving blank lines between them)
   - All other block elements (tables, code blocks, lists, HTML blocks, non-H3 headings) → unrecognized content
6. **Empty file or whitespace-only file** → valid, zero slides.
7. **Image filename matching** — case-insensitive. `![](Photo.JPG)` matches `photo.jpg` on disk.

#### Writing

1. **Frontmatter** — ALWAYS write frontmatter with at least the `format` key. This ensures the file never starts with a bare `---` that could be misinterpreted as a slide separator on re-read. Unknown keys preserved. `Yams.dump(sortedKeys: true)`.
2. **Title** — write as `# Title` if present.
3. **Header content** — write back the header content blob verbatim if present (preserved from parse, includes any project-level notes, images, blockquotes, or other content).
4. **For each slide**, write in order:
   - `---` separator
   - Blank line
   - `### Caption` (if present)
   - Blank line
   - `![alt](filename)` for each image (if any)
   - Blank line
   - `> source` lines (if present)
   - Blank line
   - Presenter notes (if present)
   - `### Unrecognized content` heading + blob (if any). The blob is stored WITHOUT the heading — the writer adds the heading on output.
   - Blank line
5. **Trailing `---`** after last slide.
6. **Trailing newline** at end of file.
7. **Atomic writes** — write to temp file, then rename.

**Note on element ordering:** The writer emits elements in a fixed order (caption, images, source, notes, unrecognized). If the user wrote elements in a different order, saving will normalize the order. This is a deliberate design choice — consistent formatting makes the file easier to scan and edit.

### Opening behavior

The app can open:

1. **A `.md` file directly** — any name. The file is treated as a slideshow if it has `format:` in its YAML frontmatter matching the known format URL. Files without matching frontmatter are not opened as slideshows (the app shows an error). Images are resolved relative to the `.md` file's directory.
2. **A folder** — looks for `slideshow.md` in the folder. If found, opens it. If not found, falls back to scanning for images (backward compatibility with folders that have no project file yet).

### Data model mapping

| Format element | Current model field | Notes |
|----------------|-------------------|-------|
| Frontmatter `format` | `ProjectFile.format` | New field |
| Frontmatter (unknown keys) | `ProjectFile.rawFields` | Preserved on round-trip |
| `# Title` | `ProjectFile.title` | Was in `slideshow.yml` |
| `### Caption` | `SidecarData.caption` → `SlideData.caption` | Was in sidecar frontmatter |
| `![alt](file)` | `SlideData.images: [SlideImage]` | Array of `(filename: String, altText: String?)`. Was single `Slide.fileURL` |
| `> blockquote` | `SlideData.source` | Was in sidecar frontmatter |
| Plain text | `SlideData.notes` | Was in sidecar body |
| `### Unrecognized content` | `SlideData.unrecognizedContent` | New field |

### What this replaces

| Old | New | Migration |
|-----|-----|-----------|
| `slideshow.yml` | Frontmatter in `slideshow.md` | Delete old code, no data migration (app unpublished) |
| `*.jpg.md` sidecar files | Slide sections in `slideshow.md` | Delete old code |
| `SidecarParser` / `SidecarWriter` | `SlideshowParser` / `SlideshowWriter` | New implementation |
| `ProjectFileParser` / `ProjectFileWriter` | Merged into `SlideshowParser` / `SlideshowWriter` | New implementation |
| `FileReorderer` | Eliminated | Order is file position, no filesystem renaming |
| `FolderScanner` (sidecar matching) | `FolderScanner` (image discovery only) | Simplified |

### What stays the same

- `ImageCache` actor — unchanged, still loads images by URL
- `EXIFReader` — unchanged, reads from image files
- `Slide` model — adapted but same concept
- `Slideshow` model — adapted, file operations simplified
- Folder-based projects — still just folders of images
- Security-scoped bookmarks — still needed for folder access

## Edge cases

### Image referenced but missing from folder

The slide exists in the presentation with its metadata (caption, source, notes) but the image cannot be displayed. The app shows a placeholder with the filename. The reference is preserved on write-back — the image might be added later.

### Duplicate image references

The same image can appear in multiple slides (e.g., a before/after comparison across the presentation). Each reference is an independent slide.

### No `---` separators in file

The entire file (after header) is treated as a single slide section.

### File with only frontmatter and title

Valid presentation with zero slides.

### Concurrent edits

If the user edits `slideshow.md` externally while the app is open, the app should detect the change (via `DispatchSource` / file coordination) and reload. Conflict resolution: last writer wins (the file is the source of truth).

## Non-goals

- **HTML/web export** — not in this spec. A future feature, not a format concern.
- **Nested folders / subdirectories** — images must be in the same directory as the `.md` file.
- **Remote image URLs** — not supported. Images are local files.
- **Video or non-image media** — out of scope. The format only references image files.
- **Slide transitions / animations** — not in the format. Presentation behavior is app-level.
- **Theme / styling** — not in the format for now. Future frontmatter field if needed.
