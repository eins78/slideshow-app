# Remove the right sidebar (inspector panel) for MVP simplification

> Strip the EditorPanel and FileInfoPanel inspector from the main layout — the text view makes them redundant for MVP.

## Status

- **Phase:** Draft
- **Type:** feature
- **Sprint:** <!-- optional, filled when plan is added to a sprint -->

## Changelog

- Remove the inspector sidebar (editor + file info panels) from the main layout

## Motivation

Second part of the UI overhaul after the data-format change. With `slideshow.md` as the canonical document and the new text view (plan: text-view, PR #17), editing is more ergonomic in the plain text view or an external editor. The inspector's EditorPanel (caption, source, notes fields) and FileInfoPanel (EXIF metadata) add UI complexity without proportional value for MVP. The list and grid modes remain important for reordering; everything else the inspector does is covered by the text view.

## Design

### Approach

<!-- How will this be implemented? Key architectural decisions. -->

### Open Questions

- [ ] ...

## Branches

- `feature/remove-inspector` — remove inspector panel from ContentView

## Notes

- Depends on text-view plan (PR #17) being implemented first
- Related plans: text-view (PR #17), data-format (PR #10)
- The inspector code (EditorPanel, FileInfoPanel) should be deleted, not hidden — MVP simplification, not feature flagging
