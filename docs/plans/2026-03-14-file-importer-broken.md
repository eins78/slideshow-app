# Fix file importer not appearing when clicking Add Images

> Clicking "Add Images" button (toolbar or empty-state) does nothing — NSOpenPanel never appears.

## Status

- **Phase:** Draft
- **Type:** bug

## Changelog

- Fix "Add Images" file picker not opening in both toolbar and empty-state views

## Motivation

Users cannot add images to slideshows. The "Add Images" button sets `showImageImporter = true` but the SwiftUI `.fileImporter` modifier never presents the system file picker. This blocks the core workflow of building slideshows from scratch.

Reproduces in both:
- Toolbar "Add Images" button (when slides are loaded)
- Empty-state "Add Images..." button (new/empty slideshow)

## Design

### Symptoms

- Button click fires (verified: `showImageImporter` state changes)
- No NSOpenPanel appears
- No console errors
- Happens for both existing and newly created slideshows

### Likely Causes (investigate in order)

1. **Two competing `.fileImporter` modifiers in the view hierarchy.** `SlideshowDocumentView` has a `.fileImporter` for opening slideshows, and `ContentView` has another `.fileImporter` for adding images. SwiftUI may suppress one when both are in the same window's view tree. Known SwiftUI limitation — only one `fileImporter` per scene may be active.

2. **`.fileImporter` placement inside `HSplitView` + `.inspector`.** The add-images `fileImporter` is attached to `mainContent` which is inside conditional branches (`ContentUnavailableView` vs `HSplitView`). SwiftUI may lose the modifier when the view branch changes.

3. **Sandbox entitlements.** The app may be missing the `com.apple.security.files.user-selected.read-only` entitlement needed for NSOpenPanel to appear. Check `Slideshow.entitlements`.

4. **`allowedContentTypes: [.image]` scope.** Verify this UTType is properly registered and not causing the picker to fail silently.

### Approach

- **Diagnosis first:** Add `print`/breakpoint to confirm `showImageImporter` is toggled. Check console for sandbox or entitlement errors. Test with Xcode debugger attached.
- **Fix option A:** Consolidate both `.fileImporter` modifiers into `SlideshowDocumentView` with a mode enum (`openSlideshow` vs `addImages`) so only one `.fileImporter` exists.
- **Fix option B:** Replace the add-images `.fileImporter` with a direct `NSOpenPanel` call (like `createNewSlideshow()` already does with `NSSavePanel`).
- **Fix option C:** Move the add-images `.fileImporter` to a sheet or overlay that's not competing with the open-slideshow one.

### Open Questions

- [ ] Is `showImageImporter` actually being set to `true`? (Confirm with debugger)
- [ ] Does the console show any sandbox/entitlement warnings?
- [ ] Does removing the open-slideshow `.fileImporter` make the add-images one work? (Confirms cause #1)
- [ ] Does the add-images picker work when launched via `NSOpenPanel` directly? (Confirms it's a SwiftUI issue)

## Branches

- `bug/file-importer-broken` — diagnose and fix file picker not appearing

## Notes

- Found during E2E testing session on 2026-03-14
- The `addImages(from:)` method itself works (verified via `--ui-test-add-images` fixture mode)
- Security-scope handling in `addImages` was fixed in commit ba2d23d
- The bug is specifically about the UI layer — the file picker never appears
