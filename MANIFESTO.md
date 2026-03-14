# Manifesto

Design authority for all conceptual decisions. When in doubt, the manifesto wins.

## Core Principles

1. **Projects are just folders.** No proprietary format, no special bundle, no database. A slideshow is a folder of images with optional metadata files.

2. **Simple format, usable without the app.** Browse the pictures in order, read the `.md` files. A human with a file manager can understand and use a slideshow project with zero tooling.

3. **File order = slide order.** Filename sorting determines presentation order. The `003--` prefix convention makes order explicit and portable.

4. **The project file is optional progressive enhancement.** `slideshow.yml` adds title and future layout metadata. Without it, everything works — folder name becomes the title, each image becomes its own slide.

5. **Images are sacred.** Never converted, re-encoded, embedded, or moved without explicit user action. The app presents images; it does not own them.

6. **Sidecar `.md` files are per-image metadata.** Caption, source, presenter notes — all in a human-readable markdown file next to the image. Unknown frontmatter keys survive round-trips.

7. **The project file stores project-level metadata.** Title, version, and future multi-image layout definitions live in `slideshow.yml` — not distributed across sidecars.

8. **Everything degrades gracefully.** Missing project file = folder name as title. Missing sidecar = image-only slide. Malformed YAML = plain text fallback. The app never refuses to open a valid folder of images.

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
