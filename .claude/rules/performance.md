# Performance Rules

These rules apply when writing or modifying Swift code in this project.

Based on [swift-agents/performance-specialist](https://github.com/Techopolis/swift-agents) (MIT).

## Main thread

- No heavy computation on `@MainActor` — use `Task.detached` for EXIF, thumbnails, batch renames
- Small synchronous file ops (single rename, copy) on `@MainActor` are acceptable (project design choice)
- Image loading MUST go through `ImageCache` actor, never direct `NSImage(contentsOf:)` in views

## Images

- Always downsample to display size via `CGImageSource` `kCGImageSourceThumbnailMaxPixelSize`
- Never load full-resolution image when only thumbnail needed
- `ImageCache` actor is the single path for all image loading — do not bypass

## SwiftUI rendering

- Use `LazyVStack` / `LazyVGrid` for slide lists and grids — never plain `VStack` / `VGrid`
- Stable `Identifiable` IDs in `ForEach` — never index-based identity
- No heavy work inside `body` — compute in `.task {}` or model methods
- Prefer `.task(id:)` over `onChange` + `Task {}` for reactive async work

## Collections

- `reserveCapacity` when size is known before populating
- `Set<String>` for membership checks (e.g., `isImageFile()` extension check)
- Avoid repeated `filter`/`map` chains — compute once and store

## Caching

- `NSCache` must have `countLimit` or `totalCostLimit`
- Respond to memory pressure notifications if holding large image data
- Cache key must include relevant parameters (URL + size for thumbnails)

## Concurrency

- Preload slides with `async let` (structured), not serial `await` calls
- `FolderScanner` and `EXIFReader` must not inherit `@MainActor` isolation
- Check for unnecessary `@MainActor` annotation on compute-only methods

## Review agent

For active performance auditing during review, dispatch the `performance-reviewer` agent.
