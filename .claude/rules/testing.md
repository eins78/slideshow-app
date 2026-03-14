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

- **SidecarParser**: frontmatter parsing, no-frontmatter fallback (heading = caption), malformed YAML fallback, CRLF normalization, unknown key preservation
- **SidecarWriter**: round-trip with SidecarParser — parse then write must produce semantically identical output
- **FileReorderer**: no-op skip (source == destination), collision-free rename via temp UUIDs, correct `\d{3}--` prefix numbering
- **FolderScanner**: image↔sidecar matching, case-insensitive matching, ignoring orphan `.md` files, sorting by filename
- **EXIFReader**: extraction from JPEG with EXIF data, graceful handling of images without EXIF
