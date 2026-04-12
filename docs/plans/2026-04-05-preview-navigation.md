# Preview panel mini-navigation

> Hovering the preview panel reveals navigation controls — back/forward buttons and a "follow editor cursor" toggle — giving a mini version of the output experience inside the editor.

## Status

- **Phase:** Draft
- **Type:** feature

## Changelog

- Mini-navigation overlay in preview panel with back/forward slide controls
- "Follow editor cursor" toggle — when on, preview tracks the selected slide in the editor list; when off, preview has independent navigation
- Navigation controls appear on hover, disappear on idle (like QuickTime transport controls)

## Motivation

The preview panel currently shows whatever slide is selected in the editor list. There's no way to quickly flip through slides from the preview itself — you must click in the list. For reviewing flow and transitions, a mini-navigation overlay (like a stripped-down version of the output window controls) would let users scrub through slides without leaving the preview.

The "follow editor cursor" concept is key: by default, preview tracks the editor selection. But toggling it off decouples preview from the list, letting you browse slides in the preview while keeping your place in the editor. This is the same pattern as "scroll lock" in terminals or "follow tail" in log viewers.

### Goals

1. **Hover-to-reveal navigation** in the preview panel (back/forward buttons, slide counter)
2. **Follow-cursor toggle** — coupled by default, decoupleable for independent browsing
3. **Consistent with output window** — the mini-nav should feel like a compact version of the output window's navigation, reusing the same model layer

### Non-goals (future work)

- Full presenter controls in preview (notes, timer)
- Keyboard shortcuts specific to the preview panel (preview is not focusable independently yet)
- Thumbnail filmstrip / scrubber bar
- Animation/transition preview between slides

## Prior Art & Research

- **QuickTime Player** — transport controls appear on hover, fade on idle. Good precedent for the interaction pattern.
- **Keynote slide navigator** — small preview with click-to-advance. Similar but always visible.
- **VS Code minimap** — hover-to-reveal overlay on a panel. Closest UX analogy.
- **iA Presenter** — preview follows cursor, no independent navigation in preview.

## Design

_To be refined during planning._

### Follow-cursor behavior

- **Default: ON** — preview shows whatever slide is selected in the editor list
- **When OFF:** preview maintains its own `previewIndex` independent of `selectedSlideIndex`
- **Re-enabling:** snaps preview back to the editor selection
- **Visual indicator:** a small icon (e.g., link/unlink chain icon) in the navigation overlay

### Navigation overlay

Appears on hover over the preview panel:

```
         [<]  3 / 24  [>]  [🔗]
```

- `[<]` / `[>]` — previous/next slide (in preview only when decoupled)
- `3 / 24` — slide counter
- `[chain icon]` — follow-cursor toggle (linked = following, broken = independent)

### Model layer

The `Slideshow` model already has `selectedSlideIndex`. Preview navigation would add:
- `previewIndex: Int?` — nil means "follow selectedSlideIndex", non-nil means independent
- Toggle sets/clears `previewIndex`

## Branches

_To be defined after approval._

## Notes

- This feature depends on the preview panel existing — currently implemented as the image view in the main editor layout
- The "follow cursor" pattern will likely be reused if we add a presenter notes panel or other synchronized views
- Consider whether the output window should also have a "follow cursor" toggle (currently it always follows)
