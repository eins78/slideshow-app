# Plan: Fix inspector panel resize, border overlap, and panel width defaults

- **Type:** bug
- **Slug:** `panel-layout-fixes`
- **Status:** Draft

## Problem

Three layout issues in the 3-panel ContentView (preview | slide list | inspector):

1. **Inspector panel can't be resized** — `.inspector()` with `.inspectorColumnWidth()` should allow drag-resize but doesn't respond
2. **Inspector border overlaps toolbar** — the inspector's left border/edge visually crosses into the toolbar area, behind the search field
3. **Left panel (PreviewPanel) too wide by default** — `idealWidth: 240` takes too much space; should be narrower to give more room to the slide list

## Evidence

Screenshots show:
- Before: PreviewPanel at ~480px (wider than ideal), inspector at ~240px
- After: PreviewPanel narrower (~350px), giving the slide list more breathing room
- Inspector border visually bleeds into the unified toolbar area

## Current code

`Slideshow/Views/ContentView.swift` lines 76-94:
```swift
HSplitView {
    PreviewPanel(slideshow: slideshow)
        .frame(minWidth: 200, idealWidth: 240)
    SlideListPanel(slideshow: slideshow, viewMode: viewMode, searchText: searchText)
        .frame(minWidth: 300)
}
.inspector(isPresented: $showInspector) { ... }
.inspectorColumnWidth(min: 220, ideal: 280, max: 400)
```

## Design

### Fix 1: Reduce PreviewPanel default width
- Change `idealWidth: 240` → `idealWidth: 180` (or remove idealWidth and let minWidth control it)
- Keep `minWidth: 200` for drag-resize minimum (or reduce to 150)

### Fix 2: Inspector resize and border
- The `.inspector()` modifier should be resizable by default on macOS. If it isn't responding, check if `HSplitView` is interfering
- The border overlap is likely a `safeAreaInset` or toolbar z-order issue — may need `.ignoresSafeArea` adjustments or moving the inspector to a different attachment point
- Consider whether `NavigationSplitView` would be more appropriate than `HSplitView` + `.inspector()`

### Fix 3: Inspector width defaults
- Increase `ideal: 280` → `ideal: 300` to match the user's expectation that it should be "same as left sidebar"

## Branches

- `bug/panel-layout-fixes` — single implementation branch from this plan

## Verification

- [ ] PreviewPanel renders narrower by default
- [ ] Inspector panel can be dragged to resize
- [ ] Inspector border does not overlap the toolbar/search field
- [ ] All three panels visible at default window size (1200x800)
- [ ] `xcodebuild build` — zero warnings
- [ ] UI tests pass: `xcodebuild test -scheme Slideshow -destination 'platform=macOS' -only-testing:SlideshowUITests`
