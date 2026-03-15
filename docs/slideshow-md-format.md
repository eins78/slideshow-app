# `slideshow.md` format reference

> Living specification — updated as the format evolves.

## Overview

A `slideshow.md` file curates a folder of images into a presentation. It defines which images appear, in what order, with optional captions, credits, and presenter notes. The format is valid markdown that renders meaningfully in any viewer.

## File structure

```
My Portfolio/
├── slideshow.md              (the presentation)
├── client-review.md          (another presentation of the same images)
├── golden-hour.jpg
├── bridge-sunset.jpg
└── bridge-morning.jpg
```

## Full example

```markdown
---
format: https://example.com/slideshow/v1
title: Paintings That Tell Secrets
---

---

# Golden hour, Wollishofen

![Lakeside view at sunset](golden-hour.jpg)

> © Max Albrecht 2024
> Downloaded from Lightroom CC

My presenter notes about this shot.
The light was perfect at 6pm.

Still notes — blank lines are fine within notes.

---

# The old bridge at sunset

![](bridge-sunset.jpg)

> © Max Albrecht 2024

---

# Introduction

Welcome to this portfolio review.

---

# The bridge evolves

![](bridge-morning.jpg)
![](bridge-noon.jpg)
![](bridge-sunset.jpg)

> © Max Albrecht 2024

Three moments, one structure.

---
```

## Elements

### Frontmatter

```markdown
---
format: https://example.com/slideshow/v1
title: My Presentation Title
---
```

YAML frontmatter at the top of the file. Optional but recommended.

- `format` — URL identifying the format. Acts as a format identifier for the app.
- `title` — the presentation title. Fallback chain: filename (without `.md`) → folder name → "Untitled".
- Unknown keys are preserved on round-trip. Future fields (e.g., `theme`, `aspect-ratio`) can be added without breaking older parsers.

### Slide separator

```markdown
---
```

A horizontal rule (`---`) on its own line separates slides. This is the universal convention across markdown presentation tools (Deckset, Marp, Slidev, reveal.js, iA Presenter).

- Must be exactly `---` on its own line (not `***` or `___`)
- The first `---` after the frontmatter begins the first slide
- The last `---` closes the last slide (optional but recommended)

### Caption

```markdown
# Golden hour, Wollishofen
```

Any heading (`#` through `######`) within a slide section. Displayed as the slide's caption/title. The heading level is preserved on round-trip but does not affect semantics — all levels are treated equally.

- At most one caption per slide (first heading wins; additional headings become unrecognized content)
- Optional — slides without a caption are valid
- Recommended: use `#` (H1) by convention, but the parser accepts any level

### Image reference

```markdown
![Alt text for accessibility](filename.jpg)
```

Standard markdown image syntax. References an image file in the same directory as the `.md` file.

- **Filename only** — no paths, no URLs. References containing `/`, `\`, or `..` are rejected.
- **Filename escaping** — filenames with spaces or special characters use angle brackets: `![](<my image (1).jpg>)`
- **Alt text** — optional. Used for VoiceOver. Falls back to caption, then filename.
- **Multiple images per slide** — 0 to N images allowed. Each `![](...)` is a separate image.
- **Zero images** — valid. Creates a text-only slide (title card, section divider).
- Only referenced images are in the show. Unreferenced images in the folder are ignored.

### Source / credit

```markdown
> © Max Albrecht 2024
> Downloaded from Lightroom CC
```

Markdown blockquote. Used for attribution, copyright, provenance.

- First line is primary credit (shown on slide); subsequent lines are secondary (detail view)
- At most one blockquote per slide (first wins; additional become unrecognized content)

### Presenter notes

```markdown
My notes about this shot.
The light was perfect at 6pm.

Blank lines within notes are fine.
```

Rich markdown — paragraphs, lists, tables, code blocks. Shown only to the presenter, not on the audience display. HTML blocks and extra headings are NOT notes — they become unrecognized content.

### Unrecognized content

```markdown
### Unrecognized content

| some | table |
|------|-------|
| the  | app   |
| didn't | understand |
```

When the app writes back content it didn't parse into known fields, those elements are collected under a `### Unrecognized content` heading. Nothing is lost — the content is preserved verbatim.

## Parse rules

### Reading

1. **Normalize** — CRLF → LF.
2. **Detect frontmatter** — `---` on line 1, closing `---` on its own line. Valid YAML with at least one key → consumed. Otherwise treat as slide separator.
3. **Extract title** — from the `title` frontmatter key. Everything between frontmatter and first `---` is header content (preserved as opaque blob).
4. **Split on `---`** — divide into slide sections. Empty sections discarded.
5. **Per slide section**, extract:
   - `### Unrecognized content` heading → opaque blob to end of section
   - First heading (any level) → caption
   - Top-level `Paragraph` images → image references (path traversal rejected)
   - First contiguous blockquote → source/credit
   - Remaining paragraphs, lists, tables, code blocks → notes
   - Everything else → unrecognized content
6. **No separators** — all content becomes a single slide. Title from frontmatter only.
7. **Image matching** — case-insensitive. `![](Photo.JPG)` matches `photo.jpg`.

### Writing

1. **Frontmatter** — always written with `format` and `title` keys. Unknown keys preserved. `Yams.dump(sortKeys: true)`.
2. **Header content** — written verbatim after frontmatter if present.
3. **Per slide** — caption → images → source → notes → unrecognized content, separated by blank lines.
4. **Trailing `---`** after last slide.
5. **Trailing newline** at end of file.
6. **Atomic writes** — write to temp file, then rename.

Element order is normalized on write (caption, images, source, notes, unrecognized).

## Opening behavior

1. **A `.md` file directly** — recognized if frontmatter `format:` matches the known URL, or if filename is `slideshow.md`.
2. **A folder** — looks for `slideshow.md`. If not found, falls back to image scan.
