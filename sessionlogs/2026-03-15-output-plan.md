# Session: Presentation Output Plan

**Date:** 2026-03-15
**Branch:** `idea/output` (merged), `feature/output-display-menu` (#19), `feature/output-window-polish` (#20)
**Plan PR:** #16 (merged)

## What happened

Planned the presentation output feature — how the app sends slides to external displays. Started with research, went through brainstorming, chose an approach, got Gemini review, and approved the plan.

### Sequence

1. Created `idea/output` branch with initial plan covering three approaches (auto-detect, manual menu, hybrid).
2. Simplified the existing `PresenterView` — replaced complex split-pane layout (current/next/notes/counter) with clean full-bleed image + caption overlay. Net -44 lines.
3. Added `preloadFullImages` to `ImageCache` actor for smooth slide transitions.
4. Brainstormed three approaches:
   - **A:** Just a window (no display awareness) — too basic
   - **B:** Smart display routing (Keynote-style auto-detect) — ~400-500 lines, large edge case surface
   - **C:** Output window + "Move to Display" menu — ~100-150 lines, user stays in control
5. **Chose Approach C** — manual display targeting via right-click context menu. Rationale: primary use case is a photographer setting up deliberately, not a conference speaker who needs instant auto-detection. C upgrades cleanly to B later.
6. Design decisions made:
   - Window chrome: minimal titlebar (transparent, buttons on hover) — not a toolbar overlay
   - Context menu: "Move to Display ▸" submenu + "Full Screen" + slide counter
   - Keyboard: F (full-screen), D (cycle displays), plus existing arrows/space/escape
   - Cursor auto-hide via `NSCursor.setHiddenUntilMouseMoves`
   - Frame persistence via `CGDisplayCreateUUIDFromDisplayID` (persistent across reboots)
7. Gemini review caught three issues:
   - `toggleFullScreen` is async — need `NSWindowDelegate.windowDidExitFullScreen` before `setFrame`
   - `NSApp.keyWindow` is brittle in multi-window — inject window via `EnvironmentKey` instead
   - `CGDirectDisplayID` changes across reboots for Thunderbolt docks — use `CGDisplayCreateUUIDFromDisplayID`
8. Fixed all findings, re-review passed clean.
9. Ran `/plot-approve output` — merged plan to main, created two implementation branches.

### Key decisions

| Decision | Choice | Why |
|----------|--------|-----|
| Display routing | Manual (Approach C) | Photographer sets up deliberately; 3-4x less complexity than auto-detect |
| Window chrome | Minimal titlebar | Standard macOS, already implemented, context menu covers all actions |
| Display persistence | `CGDisplayCreateUUIDFromDisplayID` | Survives reboots unlike `CGDirectDisplayID` |
| Window reference | Injected via EnvironmentKey | `NSApp.keyWindow` is brittle in multi-window apps |
| Full-screen + move | NSWindowDelegate callback | `toggleFullScreen` is async, can't call `setFrame` immediately |
| iOS/AirPlay | Deferred | No iOS target yet, clean upgrade path from C to B |

### What's deferred

- iOS / AirPlay / external display via scene roles
- Auto-detection (Approach B) — can layer on top of C later
- Presenter controls view (current + next + notes on primary screen)
- Auto-hiding toolbar overlay (QuickTime-style)
- Delete `AudienceView` (duplicates PresenterView) — first task in implementation

## Commits

On `idea/output` (merged to main via PR #16):
- `9eaf890` — plot: presentation output — AirPlay, second display, and floating window
- `ada0952` — simplify presenter window to full-bleed image + caption
- `8615fce` — refine output plan: choose approach C (manual display targeting)
- `58d6c5d` — fix review findings in output plan

On main:
- `e9a2899` — plot: link implementation PRs for output

## Next steps

- [ ] Implement `feature/output-display-menu` (#19) — context menu, F/D keys, cursor hide, delete AudienceView
- [ ] Implement `feature/output-window-polish` (#20) — frame/display persistence via UserDefaults
- [ ] Run `/plot-deliver output` when both branches are done
