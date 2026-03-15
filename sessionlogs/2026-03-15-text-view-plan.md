# Text View Plan & Design

**Date:** 2026-03-15
**Source:** Claude Code

## Summary

Created, refined, and approved a plan for an editable text view that replaces the inspector sidebar. Evolved from a read-only text display to the app's primary editing interface with TextEdit-style saving.

## Key Accomplishments

- Brainstormed and designed the text view feature through collaborative Q&A
- Created plan file: `docs/plans/2026-03-15-text-view.md`
- Created design spec: `docs/superpowers/specs/2026-03-15-text-view-design.md`
- Plan PR #15 merged, implementation branch `feature/text-view` created with PR #17 (draft)
- Merged remove-inspector plan (PR #18) into text-view — single plan for both changes
- Closed obsoleted panel-layout-fixes plan (PR #1) — inspector bugs moot if inspector is deleted
- Ran Gemini review — addressed all 4 findings (window lifecycle, Cmd+S routing, NSApp.keyWindow, external changes)

## Design Evolution

The plan evolved significantly during brainstorming:

1. **Started as read-only** — simple `Text` view showing serialized document
2. **User clarified: editable** — like TextEdit.app plain text mode
3. **User clarified: full document** — all slides, not single-slide view
4. **Merged with inspector removal** — the text view replaces the inspector entirely
5. **Saving design** — TextEdit-style: Cmd+S, auto-save on deactivation/window close, dirty dot

## Decisions

- **Editable raw markdown** in `TextEditor` with monospaced font
- **Full document, not per-slide:** continuous document view (matches `slideshow.md` format)
- **Third ViewMode option:** `.text` alongside `.list`/`.grid` with `doc.plaintext` SF Symbol
- **Text buffer is source of truth while editing:** model updated only on save, not per-keystroke
- **Inspector deleted entirely:** EditorPanel + FileInfoPanel removed, not hidden
- **Save-on-mutate for structural ops** (existing pattern), **parse-on-save for text edits** (new)
- **Cmd+S via `CommandGroup(replacing: .saveItems)`** — `TextEditor` swallows local `.keyboardShortcut`
- **`NSViewRepresentable` for window access** — `NSApp.keyWindow` unreliable in SwiftUI
- **Window close trigger** — explicit `willCloseNotification`, not relying on deactivation
- **External model changes** — refresh text if clean, preserve edits if dirty

## Superseded Plans

- PR #18 (remove-inspector) — merged into text-view plan, closed
- PR #1 (panel-layout-fixes) — inspector bugs obsoleted, closed

## Dependencies

- Requires data-format branch (PR #10) to be merged first

## Next Steps

- [ ] Merge data-format branch (PR #10)
- [ ] Implement text view on `feature/text-view` branch (PR #17)
- [ ] Run `/plot-deliver text-view` when done

## Repository State

- Committed: `05ae34d` - fix review findings: window lifecycle, Cmd+S routing, external changes
- Branch: `feature/text-view`
- PR: #17 (draft)
