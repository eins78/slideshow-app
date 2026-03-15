# Session: QuickLook Preview Plan

**Date:** 2026-03-15
**Branch:** `idea/quicklook-preview`
**PR:** #9 (draft)

## What happened

Researched macOS QuickLook APIs and created a plan for adding spacebar/click-to-preview on slides.

## QuickLook API Research

Three APIs exist for QuickLook on macOS:

| API | Type | Fit for this project |
|-----|------|---------------------|
| `.quickLookPreview()` | SwiftUI modifier, modal window | Best fit — minimal code, built-in slide navigation via `in:` parameter |
| `QLPreviewPanel` | AppKit singleton, Finder-style floating panel | Non-modal but requires responder chain bridging — overkill |
| `QLPreviewView` | Embeddable NSView | Single item only, no navigation — wrong tool |

**Decision:** Use `.quickLookPreview($url, in: urls)` — one modifier + one `@State` binding. Modal behavior matches Finder convention.

**Key gotcha:** If an NSTextView has focus when triggered, it can intercept the QuickLook panel. Mitigation: ensure grid/list has focus.

## Distinction clarified

QuickLook is for **browsing** (peek at full-res from grid). NOT for the player windows:
- AudienceView needs full-bleed, no chrome, external screen — QuickLook can't do this
- PresenterView needs multi-pane layout, notes, keyboard control — QuickLook can't do this

## Plan status

Created and refined on `idea/quicklook-preview`. Two triggers: click on thumbnail + spacebar on selected slide. PR #9 is still draft — needs `gh pr ready 9` before `/plot-approve`.

## Next steps

- [ ] Mark PR ready: `gh pr ready 9`
- [ ] Approve: `/plot-approve quicklook-preview`
- [ ] Implement on `feature/quicklook-preview`
