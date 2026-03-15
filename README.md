# Slideshow

A native macOS app for presenting image-heavy slideshows. Point it at any folder of images (with optional markdown sidecar files and `slideshow.yml` project file) and present.

Built for photography portfolio reviews and art critiques.

## Features

- Dual-screen presentation (audience display + presenter view with notes)
- Markdown sidecar files for captions and presenter notes
- EXIF metadata display with GPS map
- Drag-to-reorder slides (persisted via filesystem rename)
- Security-scoped bookmarks for recent documents
- Multiple windows (one per project)

## Tech Stack

Swift 6, SwiftUI, macOS 26+, Xcode 26.

## Building

```bash
xcodegen generate
open Slideshow.xcodeproj
```

Or from the command line:

```bash
xcodebuild -scheme Slideshow -destination 'platform=macOS' build
```

## Testing

```bash
cd SlideshowKit && swift test
```

## License

All rights reserved.
