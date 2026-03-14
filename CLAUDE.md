# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

A native macOS SwiftUI app for presenting image-heavy slideshows. Users point it at a folder of images (`.slideshow` bundle — a folder with a custom UTType conforming to `com.apple.package`) with optional markdown sidecar files for captions and presenter notes. **Not a slide editor — a viewer/presenter for curated image collections.**

Primary use case: photography portfolio reviews and art critiques.

## Architecture

Two-target structure:

- **SlideshowKit** — Swift Package (models + services). Platform-independent, testable via `swift test`. No UI dependencies.
- **Slideshow** — macOS app target (SwiftUI views + AppKit interop for dual-screen presentation). Consumes SlideshowKit as a local package dependency.

Data flow uses `@Observable` (Observation framework). No Combine.

## Tech Stack

- Swift 6 (strict concurrency)
- SwiftUI, macOS 26+ / iOS 26+
- [swift-markdown](https://github.com/swiftlang/swift-markdown) (Apple SPM) — parsing presenter notes
- [Yams](https://github.com/jpsim/Yams) — YAML frontmatter parsing
- ImageIO / CGImageSource — EXIF reading, thumbnail generation
- MapKit — inline GPS coordinate display
- AppKit interop — `NSWindow` + `NSHostingView` for audience display on external screen

## Build & Test Commands

```bash
# Resolve SlideshowKit package dependencies
cd SlideshowKit && swift package resolve

# Run SlideshowKit tests (the primary testable target)
cd SlideshowKit && swift test

# Run a single test
cd SlideshowKit && swift test --filter SlideshowKitTests.SidecarParserTests/testFrontmatterParsing

# Generate Xcode project (must run after changing project.yml or adding files)
xcodegen generate

# Build the full Xcode project (from project root)
xcodebuild -scheme Slideshow -destination 'platform=macOS' build
```

### Xcode MCP Bridge

When Xcode is open with the project, the Xcode MCP bridge (`.mcp.json`) provides tools for building, running tests, rendering SwiftUI previews, executing code snippets, and inspecting issues — all without GUI interaction. Requires Xcode > Settings > Intelligence > MCP > Xcode Tools: ON. See `.claude/skills/macos-development.md` for full tool reference.

## Xcode Project

The `.xcodeproj` is generated from `project.yml` via [xcodegen](https://github.com/yonaskolb/XcodeGen) and is gitignored. Run `xcodegen generate` after adding new source files or changing project settings. To open in Xcode: `open Slideshow.xcodeproj`.

This git repo (`/Users/mfa/CODE/slideshow-app`) is the working directory. The Xcode project references SlideshowKit as a local Swift Package.

## Key Design Decisions

### File/Folder Architecture
A `.slideshow` file is a macOS document package (folder presented as single file by Finder). Contains flat images + sidecar `.md` files. The app manages file I/O directly — **not** using `DocumentGroup`/`ReferenceFileDocument` (autosave conflicts with direct file writes, `FileWrapper` overhead prohibitive for large image bundles).

### Sidecar Format
Sidecar files use the naming pattern `photo.jpg.md` (image filename + `.md`). Format:
```markdown
---
caption: Golden hour, Wollishofen
source: |
  © Max F. Albrecht 2024
  Downloaded from Lightroom CC
---
Presenter notes in markdown here.
```

Parsing rules:
- Frontmatter recognized only when `---` appears on line 1, ends at next `---` on its own line
- No frontmatter fallback: first line = caption, blank line, then presenter notes
- Unknown frontmatter fields are preserved on write, ignored on read
- Malformed YAML → entire file treated as plain text notes
- Images without sidecar are valid slides; `.md` files without matching image are ignored
- CRLF normalized on parse

### Slide Ordering
Filesystem order (alphabetical). App renames files with `\d{3}--` prefix on drag reorder (e.g., `003--sunset.jpg`). Two-pass rename via temp UUIDs to avoid collisions.

### Image Loading
- No `AsyncImage` — uses `NSImage`-based loading
- `ImageCache` actor handles thumbnail + full-res caching with `NSCache`
- Presentation mode preloads 2 slides ahead with `async let` for concurrency
- `ThumbnailGenerator` via `CGImageSource`: 1024px for preview panel, 512px for presenter next-slide

### Sandbox & Bookmarks
Security-scoped bookmarks via `BookmarkManager` (`@Observable` class) for reopening slideshows after relaunch. Must balance `start/stopAccessingSecurityScopedResource` calls. Requires `com.apple.security.files.bookmarks.app-scope` entitlement.

## Development Rules

### Definition of Done

A task is NOT done until ALL of these are satisfied:

1. `cd SlideshowKit && swift test` — zero failures
2. `xcodebuild -scheme Slideshow -destination 'platform=macOS' build` — zero warnings
3. No `!` force unwraps — use `guard let`, `if let`, or `??`
4. No `as!` force casts — use `as?` with handling
5. No `@unchecked Sendable`, no `nonisolated(unsafe)`
6. No `import Combine`
7. Sidecar round-trip: unknown frontmatter keys must survive parse → write unchanged
8. Tests written before or alongside implementation, never after
9. One logical change per commit; imperative mood, lowercase, no trailing period
10. **Simplify:** after committing, run `/simplify` to review changed code for reuse, quality, and efficiency — fix any issues found before proceeding
11. **Gemini review loop:** after simplify, run `/ai-review` for Gemini review. If issues are found: fix them, commit the fixes, and run `/ai-review` again. Repeat until the review comes back clean (max 10 iterations — if still failing after 10, stop and ask the human for help). NEVER skip reviews. Work in PR-sized batches — commit when a task is logically complete, then enter the review loop

### Git History Rules

- **Always commit before** running `/simplify` or `/ai-review` — the review input must be a committed state
- **Never amend** review/simplify fix commits into the original — each fix is its own commit with rationale
- **Preserve full history** — the commit log must tell the story: what was built, what the review found, and why fixes were made
- Commit messages for fixes should reference what triggered them (e.g., "fix review findings in X" with bullet points explaining each change)

### Handling Repeated Review Findings

When a review repeatedly flags a deliberate design choice that we won't change, add a brief comment in the code explaining **why** with a **link to the relevant documentation or spec** (Apple docs, Swift Evolution proposal, design spec, etc.). This prevents the same false positive from wasting review cycles. Do not write "this is correct" — cite the source.

### Code Conventions

- `Yams.dump` with `sortedKeys: true` for deterministic output
- `DateFormatter` instances are `static` (avoid repeated allocation)
- `isImageFile()` uses fast-path `Set<String>` of extensions, not runtime UTType resolution
- `FileReorderer` skips no-op renames (source == destination)
- EXIF reading wrapped in `Task.detached` to avoid main actor
- EditorPanel disk writes debounced (500ms) — critical for iCloud Drive
- File operations (createSidecar, removeSlide, moveSlide, addImages) live on the `Slideshow` model, not in views
- `addImages()` is incremental (no full re-scan)
- Bundle identifier: `is.kte.slideshow`

### Detailed Rules

Domain-specific rules in `.claude/rules/`:
- `swift-concurrency.md` — Swift 6 strict concurrency patterns
- `swiftui-patterns.md` — SwiftUI state management and view rules
- `testing.md` — Swift Testing framework conventions
- `git-and-workflow.md` — git conventions, review workflow, plot readiness
- `accessibility.md` — VoiceOver, keyboard nav, Dynamic Type, click targets
- `performance.md` — main thread, image optimization, caching, SwiftUI rendering

Review agents in `.claude/agents/` (from [swift-agents](https://github.com/Techopolis/swift-agents)):
- 16 specialist agents auto-routed via `swift-lead` on every prompt (`UserPromptSubmit` hook)
- Key specialists: `mobile-a11y-specialist`, `performance-specialist`, `concurrency-specialist`, `swiftui-specialist`, `testing-specialist`
- Also invocable manually: `/mobile-a11y-specialist review the slide list views`

### Skills

- `.claude/skills/macos-development.md` — Xcode MCP bridge, CLI build/test, accessibility auditing, independent testing workflow

## Code Review Context

Context for external reviewers (Gemini, OpenAI) who lack access to the full codebase:

- **Stack:** Swift 6 strict concurrency, SwiftUI, macOS 26+ / iOS 26+ (Xcode 26 beta). `.v26` platform targets are correct and intentional.
- **`CLLocationCoordinate2D`** is `Sendable` in the macOS 26 SDK — no wrapper needed.
- **File operations on `Slideshow` model** (removeSlide, moveSlide, createSidecar, addImages) are synchronous by design. This is a deliberate architecture choice — views call model methods, model owns I/O. Do not flag as "should be async" or "should be in a service."
- **`@Observable` without `@MainActor`** on `Slide`: intentional. Slides are created in background (FolderScanner) and observed by views. `@MainActor` is added at the view-model level (`Slideshow`), not per-entity.
- **`try?` in file deletion:** acceptable for MVP — orphaned files on disk are a minor issue vs. blocking the user with error dialogs.
- **`rawFrontmatter` as `[String: String]`:** sidecar YAML is flat key-value pairs. Lossy conversion of complex types is acceptable — we don't support nested YAML.
- **No `AsyncImage`** — all image loading via `ImageCache` actor + `NSImage`.
- **Review focus:** Logic errors, concurrency bugs, missing edge cases, API misuse. Not: architecture redesigns, hypothetical performance, or "should use a different pattern."

## Specs & Plans

- Design spec: `~/OPS/home-workspace/docs/superpowers/specs/2026-03-14-slideshow-app-design.md`
- Implementation plan: `~/OPS/home-workspace/docs/superpowers/specs/2026-03-14-slideshow-implementation-plan.md`
