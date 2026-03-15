# Text View Implementation

**Date:** 2026-03-15
**Branch:** `feature/text-view` → merged to main via PR #17
**Plan:** `docs/plans/2026-03-15-text-view.md` (Delivered)

## What was built

Replaced the inspector sidebar (EditorPanel + FileInfoPanel) with an editable text view showing the full `slideshow.md` document. TextEdit-style saving with Cmd+S, auto-save on deactivation, and dirty-state indicator in the title bar.

## Key decisions

- **Raw text to disk, not re-serialized:** `saveRawText` writes the user's exact text, then parses it for the model. Preserves user formatting.
- **`lastSeenDocument` snapshot over boolean flag:** Initially used `isUpdatingFromSave` boolean to prevent onChange loops, but Gemini review caught a timing bug — `defer` runs before async `.onChange` fires. Replaced with document snapshot comparison.
- **WindowAccessor with Coordinator pattern:** Started with `DispatchQueue.main.async` in `makeNSView`, upgraded to `viewDidMoveToWindow()` override per review, then added Coordinator to avoid stale binding capture.
- **Cmd+S via `CommandGroup(replacing: .saveItem)`:** TextEditor's NSTextView swallows Cmd+S at the responder chain level. Routed through FocusedValue at the app scene level.
- **No Combine:** Auto-save uses `NotificationCenter.default.notifications(named:)` async sequence in `.task {}`. `.onDisappear` as synchronous safety net.

## Commits (7 on feature branch)

1. `88bc476` — main implementation: text view, inspector removal, saveRawText, 6 tests
2. `bbc4e0b` — simplify: extract coordinatedWrite helper, fix error swallowing, no model mutation in view
3. `a8566cb` — review R1: onDisappear safety net, fix tautological test, a11y labels
4. `28004e2` — review R2: lastSeenDocument snapshot, viewDidMoveToWindow
5. `102b737` — review R3: Coordinator pattern for stale binding capture
6. `6711af3` — fix mobile target for new slideshow.md data model (pre-existing breakage)
7. `3358ecf` — plot: deliver text-view

## Review loop

4 rounds of Gemini review until clean APPROVE:
- R1: missing onDisappear, tautological test, missing a11y labels
- R2: isUpdatingFromSave timing bug (ERROR), unreliable window capture
- R3: stale binding capture in WindowAccessor
- R4: clean APPROVE

## Discovered issues

- Mobile target (`SlideshowMobile`) was broken by the data-format migration — still used old `Slide.fileURL`, `Slide.sidecar`, `Slideshow.folderURL` APIs. Fixed in this branch.
- Xcode LLDB attach failure unrelated to code — resolved by killing stale processes and launching from CLI build.

## Next steps

- [ ] Output window plan (`docs/plans/active/output.md`) — PRs #19, #20
- [ ] Test the text view manually with real slideshows
