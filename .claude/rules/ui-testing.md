# UI Testing Conventions

These rules apply when writing or modifying test files in `SlideshowUITests/`.

## Framework

- Use XCTest (`import XCTest`), NOT Swift Testing — XCUITest requires XCTestCase
- Test functions use `func test` prefix (XCTest convention): `func testFixtureModeLoadsSlides()`
- Use `XCTAssertTrue`, `XCTAssertFalse`, `XCTAssertEqual` — NOT `#expect` / `#require`

## Element queries

- Prefer `accessibilityIdentifier` over label text matching for stability
- Use `.firstMatch` for toolbar buttons — they may have multiple AX representations
- Always use `waitForExistence(timeout:)` — never assume elements are immediately present
- Standard timeout: 5s for UI elements, 10s for data loading

## Test fixture mode

- Use `app.launchArguments = ["--ui-test-fixtures"]` to load example slideshow
- Fixtures come from `Examples/Paintings That Tell Secrets.slideshow`
- Bypasses file picker — loads slides directly via `loadUITestFixtures()`

## Accessibility audits

- Every UI test suite MUST include a `testAccessibilityAudit()` test
- Use closure form to log all issues before failing
- Fix audit findings in the view code, not by suppressing audit types

## System dialogs

- XCUITest CANNOT interact with NSOpenPanel/NSSavePanel (system dialogs)
- Do NOT attempt to test file picker flows via UI tests
- Test file handling logic (addImages, openSlideshow) via SlideshowKit unit tests

## Test structure

- `setUp`: create `XCUIApplication()`, set `continueAfterFailure = false`
- Group tests by feature: Welcome Screen, Fixture Mode, Accessibility, Keyboard Navigation
- Each test should be independent — no shared state between tests

## Running

```bash
# All UI tests
xcodebuild test -scheme Slideshow -destination 'platform=macOS' -only-testing:SlideshowUITests

# Single test
xcodebuild test -scheme Slideshow -destination 'platform=macOS' \
  -only-testing:SlideshowUITests/SlideshowUITests/testFixtureModeLoadsSlides
```
