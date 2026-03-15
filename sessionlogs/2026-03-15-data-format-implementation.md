# Data Format: slideshow.md Implementation

**Date:** 2026-03-15
**Branch:** `data-format` → merged to `main`
**Scope:** Replace per-slide YAML sidecars with single `slideshow.md` file

## What Happened

### Phase 1: Research & Design (pre-compaction)
- Researched prior art: Deckset, Marp, Slidev, iA Presenter, Fountain
- Created research doc at `docs/research/2026-03-15-data-format-research.md`
- Interactive design session with user produced key decisions:
  - Markdown-first format (not YAML, not Fountain)
  - Headings for captions, blockquotes for credit, plain text for notes
  - **No filesystem renaming** — slide order = position in file (pivotal)
  - Multiple presentations per folder supported
  - `### Unrecognized content` heading for unknown elements on write-back
- Added "For Visual Storytellers" distinction in MANIFESTO.md (vs iA Presenter)

### Phase 2: Spec (6+ Gemini review rounds)
- Full spec at `docs/superpowers/specs/2026-03-15-slideshow-md-format-design.md`
- Reviews caught real edge cases: frontmatter/separator ambiguity, path traversal, ghost slides, H3 data loss — all fixed

### Phase 3: Implementation (15 tasks, 4 chunks)
- `SlideImage`, `SlideSection`, `SlideshowDocument` value types
- `SlideshowParser` (AST-based via swift-markdown) + `SlideshowWriter` with round-trip
- `FolderScanner` rewrite for document-based scanning
- `Slide` model rewrite (section-based, 0-N images per slide)
- `Slideshow` model rewrite (document-level save)
- All views updated for new data model
- Deleted old infrastructure: `SidecarParser`, `SidecarWriter`, `FileReorderer`, `ProjectFileParser`, `ProjectFileWriter`
- Example slideshows converted (removed number prefixes from filenames)

### Phase 4: File Watching (this conversation's main work)
- `DocumentFilePresenter` — NSFilePresenter with 500ms debounce
- `Slideshow.reload()` with selection preservation (filename → caption → index → first)
- `Slideshow.save()` via `NSFileCoordinator(filePresenter:)` for self-write suppression
- `startWatching()`/`stopWatching()` lifecycle wired in app
- Full test suite (100 tests total, all passing)
- User manually verified: external edits in text editor reflected in app

## Key Commits (file watching)
- `113e028` add file watching for slideshow.md via NSFilePresenter
- `801d568` fix simplify findings: deduplicate test helpers
- `77e0dc8` fix gemini review: add #require guards and coordinator error check
- `867068d` fix typo: Cordinator → Coordinator in test name
- `3902c18` merge data-format into main (resolved PresenterView conflict)

## Decisions Worth Remembering
- NSFilePresenter chosen over DispatchSource for iCloud Drive compatibility
- NSFilePresenter tests call `presentedItemDidChange()` directly — coordinator integration is flaky in `swift test` (no app run loop)
- `NSObject` provides `@unchecked Sendable` inheritance, so `DocumentFilePresenter` doesn't need explicit Sendable conformance
- Selection restoration uses filename as primary anchor (most stable across edits)

## Status
- All 100 unit tests pass
- Xcode build: zero warnings
- Gemini review: APPROVE
- Merged to main
- `data-format` branch can be deleted
