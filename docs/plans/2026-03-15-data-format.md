# Define the .slideshow data format specification

> Formalize the data format for `.slideshow` bundles so it works well with and without the app.

## Status

- **Phase:** Draft
- **Type:** feature

## Changelog

- Define a stable, documented data format for `.slideshow` bundles

## Motivation

The data format is currently defined ad-hoc based on MVP needs. Before solidifying it, we should intentionally design how slideshows are stored on disk — especially since a goal is that the format is useful even without the app (just a folder of images you can browse in Finder or edit in a text editor).

Key tension: **per-slide sidecar files** vs. **single manifest file** for text content (captions, presenter notes).

### Current approach (sidecar files)

- Each image can have a companion `.md` file: `001--hello.jpg.md`
- Pros: simple, editable in any text editor, each file is self-contained
- Cons: many small files, no single overview of all slide text

### Alternative (single file)

- One `presentation.txt` or `slideshow.yml` with all text keyed by filename
- Pros: single place for overview, easier to reorder text
- Cons: merge conflicts, harder to edit per-slide, couples text to a specific file

### Hybrid considerations

- Could support both: sidecar files as source of truth, with an optional generated overview file
- The app could convert between formats automatically

## Design

### Approach

<!-- To be refined — this plan captures the decision space -->

### Open Questions

- [ ] Sidecar `.md` per image vs. single manifest file vs. hybrid?
- [ ] Should the format include a `slideshow.yml` project-level config? (already explored in `idea/folders`)
- [ ] What metadata belongs in frontmatter vs. derived from EXIF?
- [ ] Should ordering be filename-based (`\d{3}--` prefix) or declared in a manifest?
- [ ] How to handle the case where images are added/removed outside the app?
- [ ] Is `.slideshow` (macOS package UTType) the only supported container, or also plain folders?
- [ ] File encoding: always UTF-8? BOM handling?
- [ ] Should the format be versioned?

## Branches

- `feature/data-format` — implement the agreed-upon format specification

## Notes

- User's original framing: "i envision a simple data format where u can use it also without the app. as in, its just a bunch of pictures"
- Easy to prototype both approaches and convert between them ("kann man auch einfach mal ausprobieren wie sich was anfühlt")
- Related: `idea/folders` already explored `slideshow.yml` for project-level config
