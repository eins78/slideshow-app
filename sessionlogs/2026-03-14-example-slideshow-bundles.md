# Example Slideshow Bundles

**Date:** 2026-03-14
**Source:** Claude Code

## Summary

Created 3 example `.slideshow` bundles using public domain content — NASA space photos, Rijksmuseum/Wikimedia paintings, and Ernst Haeckel scientific illustrations. Each bundle has sidecar `.md` files with presenter notes written in a "very smart child" voice. Includes a reproducible `create-examples.sh` script.

## Key Accomplishments

- Researched public domain image sources (NASA, Rijksmuseum CC0, Wikimedia Commons, Smithsonian)
- Used visual companion browser tool for interactive image curation across 3 collections
- Curated 16 images total across 3 themed bundles
- Downloaded, resized (1600px), and organized all images with `\d{3}--` prefix naming
- Wrote 16 sidecar files with YAML frontmatter and enthusiastic presenter notes
- Created `create-examples.sh` for reproducible bundle generation

## Changes Made

- Created: `Examples/My Favorite Space Pictures.slideshow/` (10 images + sidecars)
- Created: `Examples/Paintings That Tell Secrets.slideshow/` (3 images + sidecars)
- Created: `Examples/Nature Is Really Good at Shapes.slideshow/` (3 images + sidecars)
- Created: `Examples/create-examples.sh`

## Decisions

- **Pivoted Botanica from Smithsonian to Haeckel:** Smithsonian API returned 403. Ernst Haeckel's "Kunstformen der Natur" (1904) plates from Wikimedia Commons are more visually striking and reliably public domain.
- **Wikimedia Commons as primary source for non-NASA images:** More stable URLs than institution APIs. Rijksmuseum IIIF used for Night Watch and Love Letter (reliable), Wikimedia for Starry Night and all Haeckel plates.
- **Space bundle expanded to 10 images:** User wanted a grid-worthy collection. Covers Hubble, JWST, Cassini, Curiosity, Perseverance/Ingenuity, New Horizons — diverse instruments and destinations.
- **"Smart child" naming and voice:** Slideshow names like "My Favorite Space Pictures" and notes like "Turtles have HEXAGONS on their shells" — enthusiastic, factual, personal.
- **1600px long edge, JPEG:** Balances visual quality with git repo size (9 MB total).
- **NASA `~large.jpg` suffix:** NASA Image API serves multiple sizes. `~large.jpg` is good quality without the massive `~orig.jpg` files.

## Image Sources

| Bundle | Source | License |
|--------|--------|---------|
| Space (10) | NASA Image and Video Library API | US Gov Public Domain |
| Dutch Masters (3) | Rijksmuseum IIIF + Wikimedia Commons | CC0 / Public Domain |
| Haeckel (3) | Wikimedia Commons | Public Domain (1904) |

## Next Steps

- [ ] Verify bundles open correctly in the Slideshow app (FolderScanner, SidecarParser, EXIFReader)
- [ ] Test grid view rendering with the 10-image space bundle
- [ ] Add `.superpowers/` to `.gitignore` if not already there

## Repository State

- Committed: `2003518` — add example slideshow bundles with public domain content
- Merged: `d0f0c30` — merge example slideshow bundles from worktree-examples
- Branch: `main` (merged from `worktree-examples`)
