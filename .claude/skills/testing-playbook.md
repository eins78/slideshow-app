---
name: testing-playbook
description: Use when testing the slideshow app end-to-end, writing new tests, debugging test failures, running accessibility audits, or probing runtime behavior. Covers unit tests, UI tests, preview rendering, ExecuteSnippet probing, fixture strategies, security-scoped URL patterns, and common testing mistakes.
---

# Testing Playbook

Empirically verified reference for testing a macOS SwiftUI slideshow app with an AI coding agent. Every technique documented here was tested and confirmed working.

## Test Pyramid

1. **Unit tests** (SlideshowKit): `cd SlideshowKit && swift test` -- 63 tests, 8 suites, Swift Testing framework
2. **Runtime probes** (ExecuteSnippet): test models/services in Xcode's playground context
3. **UI tests** (XCUITest): `xcodebuild test -scheme Slideshow -destination 'platform=macOS' -only-testing:SlideshowUITests` -- 6 tests
4. **Preview rendering** (RenderPreview): visual verification of SwiftUI views
5. **Per-file diagnostics** (XcodeRefreshCodeIssuesInFile): compiler diagnostics without rebuild
6. **Accessibility audits** (`performAccessibilityAudit()`): automated a11y compliance

## Tool Reference Table

| Tool | Use For | Command/MCP |
|------|---------|-------------|
| `swift test` | SlideshowKit unit tests | `cd SlideshowKit && swift test` |
| `xcodebuild test` | UI tests (XCUITest) | `xcodebuild test -scheme Slideshow -destination 'platform=macOS'` |
| `xcodebuild build` | Full app build | `xcodebuild -scheme Slideshow -destination 'platform=macOS' build` |
| `BuildProject` | Xcode build via MCP | Requires `tabIdentifier` |
| `RunAllTests`/`RunSomeTests` | Tests via MCP | Note: scheme must include test targets |
| `RenderPreview` | SwiftUI preview snapshots | Returns PNG path |
| `ExecuteSnippet` | Runtime probing | Runs in file context, needs `sourceFilePath` |
| `XcodeRefreshCodeIssuesInFile` | Per-file diagnostics | Pass relative path like `Slideshow/Views/ContentView.swift` |
| `XcodeListNavigatorIssues` | All project issues | Severity filter: `remark`, `warning`, `error` |
| `GetBuildLog` | Build log with filters | Severity + pattern/glob filters |
| `GetTestList` | Discover test IDs | Note: only finds tests in Xcode scheme test plan |

## What Works

- XCUITest from CLI -- launches app automatically, no accessibility permission needed
- `--ui-test-fixtures` launch argument -- loads Examples slideshow, bypasses file picker
- `ExecuteSnippet` -- can test any code in context of any source file (use `Slideshow/SlideshowApp.swift` for access to SlideshowKit types)
- `RenderPreview` -- renders #Preview macros as PNGs (10/12 previews render)
- `performAccessibilityAudit()` -- catches real issues (20 found in first run)
- `XcodeRefreshCodeIssuesInFile` -- zero-build diagnostics on individual files

## What Doesn't Work

- **Can't drive running app UI** without Accessibility permission (System Settings > Privacy & Security > Accessibility for Terminal.app)
- **`RunAllTests`/`RunSomeTests` via MCP** can't find SlideshowKit package tests -- they're not in the Xcode scheme's test plan. Use CLI `swift test` instead.
- **XCUITest can't interact with system file dialogs** (NSOpenPanel/NSSavePanel) -- `.fileImporter()` uses NSOpenPanel internally. Test file handling logic via unit tests.
- **Minimal JPEG fixtures** (22-79 bytes) not decodable by CGImageSource -- ImageCache/ThumbnailGenerator return nil. Production images work fine.
- **Preview crashes** for views using `List(selection:)` with `@Bindable` -- Xcode 26 beta sandbox initialization failure in `libsystem_secinit.dylib`. Not a code bug.
- **`screencapture`** needs display context -- may not work in all terminal sessions

## Fixture Strategy

- **Unit test fixtures**: Programmatic minimal JPEG/PNG via Python `struct` module (79 bytes). In `SlideshowKit/Tests/SlideshowKitTests/Fixtures/`
- **UI test fixtures**: Real images from `Examples/` folder. Loaded via `--ui-test-fixtures` launch argument in `SlideshowDocumentView.loadUITestFixtures()`. Copies "Paintings That Tell Secrets.slideshow" to temp dir.
- **ExecuteSnippet fixtures**: Create temp dirs with `FileManager.default.temporaryDirectory`, clean up with `try? fm.removeItem(at:)`

## Security-Scope Gotcha (Critical Bug Pattern)

`startAccessingSecurityScopedResource()` returns `false` for non-scoped URLs (temp dirs, some file-importer URLs). **This does NOT mean the file is inaccessible.** The URL may still be readable via sandbox entitlements.

**Wrong pattern (causes silent failures):**
```swift
guard url.startAccessingSecurityScopedResource() else { return } // SKIPS accessible files!
defer { url.stopAccessingSecurityScopedResource() }
```

**Correct pattern:**
```swift
let didStartAccessing = url.startAccessingSecurityScopedResource()
defer { if didStartAccessing { url.stopAccessingSecurityScopedResource() } }
```

This was the root cause of the "Add Images" file picker not working.

## Accessibility Audit Workflow

1. Add `performAccessibilityAudit()` to UI tests
2. Use closure form to log all issues: `try app.performAccessibilityAudit { issue in ... }`
3. Audit types found: missing descriptions (rawValue 8), contrast failures (rawValue 1), inaccessible text (rawValue 2), parent/child mismatch
4. Fix issues, re-run audit, repeat

## Bug Investigation Workflow (ExecuteSnippet)

1. Identify the model/service to probe
2. Write a snippet that exercises the code path in question
3. Use `sourceFilePath: "Slideshow/SlideshowApp.swift"` for full access to SlideshowKit types
4. Print results -- output appears in `executionResults` field
5. For async code, use `await` directly (snippets support async)
6. For throwing code, use `try` (snippets run in a playground-like context that handles errors)

## Running the Full Test Suite

```bash
# Unit tests (SlideshowKit)
cd SlideshowKit && swift test

# UI tests (XCUITest) -- all
xcodebuild test -scheme Slideshow -destination 'platform=macOS' -only-testing:SlideshowUITests

# UI tests -- single test
xcodebuild test -scheme Slideshow -destination 'platform=macOS' \
  -only-testing:SlideshowUITests/SlideshowUITests/testFixtureModeLoadsSlides

# Full app build (zero-warning check)
xcodebuild -scheme Slideshow -destination 'platform=macOS' build
```

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Using `guard url.startAccessingSecurityScopedResource() else { return }` | Use `let didStartAccessing = ...` pattern -- false does not mean inaccessible |
| Expecting `RunAllTests` MCP to find SlideshowKit tests | Use CLI `swift test` -- Xcode scheme doesn't include package tests |
| Creating minimal JPEGs for thumbnail/cache testing | Use real images from `Examples/` folder |
| Using `app.buttons["id"]` for toolbar buttons | Use `app.buttons["id"].firstMatch` -- toolbar buttons may have multiple AX representations |
| Testing file picker interaction with XCUITest | Can't -- test file handling logic in unit tests instead |
| Forgetting `waitForExistence(timeout:)` | XCUITest elements need time to appear -- always wait |
