# Testing Conventions

These rules apply when writing or modifying test files in `SlideshowKit/Tests/`.

## Framework

- Use Swift Testing (`import Testing`), NOT XCTest
- Test functions use `@Test` attribute with descriptive names — no "test" prefix needed:
  - GOOD: `@Test func parsesYAMLFrontmatter()`
  - GOOD: `@Test func roundTripsUnknownFrontmatterKeys()`
  - BAD: `func testParsesYAMLFrontmatter()`
- Use `@Suite` for grouping related tests

## Assertions

- Use `#expect()` instead of `XCTAssertEqual` / `XCTAssertTrue`
- Use `#require()` for preconditions that should abort the test if they fail (replaces `XCTUnwrap`)
- NEVER use force unwraps (`!`) in tests — use `#require(optionalValue)` or `try #require(expression)`

## Async tests

- Swift Testing natively supports `async` test functions — just mark them `async`:
  ```swift
  @Test func loadsEXIFFromJPEG() async {
      // ...
  }
  ```

## Test fixtures

- Test images are generated programmatically using Python's `struct` module to create minimal valid JPEG/PNG/TIFF byte sequences
- Do NOT depend on Pillow, ImageMagick, or any external image library for fixture generation
- Sidecar test fixtures are plain text `.md` files checked into `SlideshowKit/Tests/SlideshowKitTests/Fixtures/`

## Required test coverage

These areas MUST have tests before their implementation is considered complete:

- **SlideshowParser**: frontmatter parsing, malformed YAML fallback, header extraction, slide section parsing (caption, images, source, notes, unrecognized content), path traversal rejection, CRLF normalization, no-separator edge case, angle-bracket filenames
- **SlideshowWriter**: round-trip with SlideshowParser — parse then write then parse must produce semantically identical output, filename escaping, frontmatter always written
- **FolderScanner**: slideshow.md discovery, image-only fallback, available images tracking, case-insensitive filename matching
- **EXIFReader**: extraction from JPEG with EXIF data, graceful handling of images without EXIF

## UI testing

- UI tests live in `SlideshowUITests/` (Xcode target, not SPM)
- Framework: XCTest (NOT Swift Testing) — XCUITest requires XCTestCase
- See `.claude/rules/ui-testing.md` for detailed conventions
- See `.claude/skills/testing-playbook.md` for the full testing reference
- Run: `xcodebuild test -scheme Slideshow -destination 'platform=macOS' -only-testing:SlideshowUITests`
