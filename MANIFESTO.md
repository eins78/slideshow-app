# Manifesto

Design authority for all conceptual decisions. When in doubt, the manifesto wins.

## Core Principles

1. **Projects are just folders.** No proprietary format, no special bundle, no database. A slideshow is a folder of images with optional metadata files.

2. **Simple format, usable without the app.** Browse the pictures in order, read the `.md` files. A human with a file manager can understand and use a slideshow project with zero tooling.

3. **Slide order = file position.** The order slides appear in `slideshow.md` determines presentation order. No filesystem renaming — the file is the source of truth.

4. **A single `slideshow.md` curates the presentation.** Title, slide order, captions, credits, and notes — all in one human-readable markdown file. Without it, each image in the folder becomes its own slide.

5. **Images are sacred.** Never converted, re-encoded, embedded, or moved without explicit user action. The app presents images; it does not own them.

6. **Only referenced images are in the show.** The folder is the library; the `.md` file is the curated selection. Multiple `.md` files can curate different presentations from the same images.

7. **Unknown content is preserved, never discarded.** Markdown elements the app doesn't understand are collected under an "Unrecognized content" heading and round-tripped unchanged.

8. **Everything degrades gracefully.** Missing `slideshow.md` = each image becomes a slide. Malformed YAML = no frontmatter. Unknown markdown = preserved as-is. The app never refuses to open a valid folder of images.

## For Visual Storytellers

This app is for **visual storytellers** — photographers, curators, art critics. The user's story begins with a collection of images, trimmed down to a curated sub-selection in a specific order. Text (captions, notes) is added to support the images, not the other way around.

Compare with iA Presenter: it serves writers and storytellers whose workflow begins with writing text, then splitting it into slides. Our workflow begins with images, then adds structure and narrative around them.

## The Checklist

Every design decision must pass all eight questions. If it fails any, reconsider.

1. Does it keep projects as plain folders, or introduce a proprietary format?
2. Can a human use this without the app — just browse pictures in order and read the `.md` files?
3. Does it fail gracefully when optional files (project file, sidecars) are missing or malformed?
4. Is the format simple enough to create and edit by hand in a text editor?
5. Does it preserve the user's original images untouched (no conversion, no embedding)?
6. Would removing this feature simplify without losing something essential?
7. Does it work alongside standard macOS tools (Finder, Quick Look, Preview)?
8. Does it stay focused on presentation, or creep into photo management?
