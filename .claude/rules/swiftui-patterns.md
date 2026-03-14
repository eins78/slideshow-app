# SwiftUI Patterns

These rules apply when writing or modifying any SwiftUI view file.

## State management

- `@State` is ONLY for:
  1. View-local primitive state (booleans, strings, selection indices)
  2. The owning view that CREATES an `@Observable` instance (e.g., `@State private var slideshow = Slideshow()`)
- `@Bindable` for views that RECEIVE an `@Observable` object and need bindings to its properties
- `@Environment` for injecting `@Observable` objects through the view hierarchy
- FORBIDDEN: `@ObservedObject`, `@EnvironmentObject`, `@StateObject` — these are legacy `ObservableObject` patterns

## Image loading

- NEVER use `AsyncImage` — it has no caching, no control over decoding, and no NSImage support
- All image loading goes through `ImageCache` actor → returns `NSImage`
- Views display images via `Image(nsImage:)` after loading from the cache
- Thumbnail sizes: 1024px for preview panel, 512px for presenter next-slide

## View responsibilities

- Views MUST NOT perform file system operations directly
- Views MUST NOT import Foundation file APIs (`FileManager`, direct `URL` file operations)
- All file operations are methods on the `Slideshow` model (which is `@MainActor @Observable`)
- Views call model methods; model methods perform I/O

## Async work in views

- Use `.task { }` modifier for async work triggered by view appearance — not `onAppear` with `Task { }`
- Use `.task(id:)` when async work should restart on value change (e.g., loading a new slide's image)
- Prefer `ViewThatFits` and adaptive layouts over hardcoded dimensions
