# Changelog

## [Unreleased]

### Features

- Title now lives in YAML frontmatter (`title:` key); `#` headings are slide captions ([#23](https://github.com/eins78/slideshow-app/pull/23))
- Live preview follows cursor position while editing in text-view mode

### Bug Fixes

- Fix wrong slide shown when cursor is positioned after trailing `---` separator
- Replace `HSplitView` with `HStack` + explicit divider to fix layout instability

### Other

- Remove "Create New" button from welcome screen
- Add CC0 1.0 Universal license
- Restore smart apostrophes in documentation and notes

---

## [0.1.0] - 2026-03-15

Initial release on TestFlight (macOS and iPhone).

### Features

- `slideshow.md` as single source of truth: YAML frontmatter, `---` slide separators, `#` headings as captions, `>` blockquotes as credits, paragraphs as presenter notes
- Plain folder support — folder without `slideshow.md` loads all images in filename order
- Text editing view with live write-back and 500 ms debounced disk saves (iCloud-safe)
- Presentation output: second display / AirPlay audience view with preloaded slides
- Slide list sidebar with thumbnails, inspector, and presenter-notes panel
- Image loading via `ImageCache` actor (1024 px preview, 512 px next-slide)
- EXIF metadata reading (camera, lens, GPS coordinates with inline MapKit view)
- Security-scoped bookmarks for reopening recent slideshows after relaunch
- macOS and iOS targets sharing the `SlideshowKit` Swift package
