# Flexible panel layout system

> Position the preview on any edge (left/right/top/bottom), support multiple panels, and adapt intelligently to iPhone and external displays.

## Status

- **Phase:** Draft
- **Type:** feature

## Changelog

- Configurable preview position: left, right, top, bottom
- iPhone-adaptive layout: preview on top half, editor on bottom (no output connected); preview on output, editor on phone (output connected)
- Scalable panel system designed for future panels (file explorer, Apple Photos import, presenter notes)

## Motivation

The current layout is fixed: editor list on the left, preview on the right. This works for the desktop MVP but breaks down in several scenarios:

1. **Portrait-oriented images** — preview on the right wastes horizontal space; preview on top/bottom would be better
2. **iPhone** — the fixed side-by-side layout doesn't work on a narrow screen. Preview should stack above the editor list, or live on the external display
3. **Future panels** — we'll likely add a file explorer (showing unused images in the working directory), an Apple Photos browser for importing, and possibly presenter notes. The current layout has no room for additional panels
4. **User preference** — some users prefer source on the right, preview on the left (like Keynote's navigator)

This warrants a **research dossier first** to evaluate the state of the art in SwiftUI panel/split-view systems before committing to an implementation approach.

### Goals

1. **Preview position** — user chooses left/right/top/bottom via menu or keyboard shortcut
2. **iPhone layout** — sensible defaults for compact size class, adapting when external display is connected
3. **Panel architecture** — a system that can accommodate 2-4 panels without a rewrite each time
4. **Nice UX** — resizable dividers, draggable panel edges, smooth transitions, state persistence

### Non-goals (future work)

- Detachable/floating panels (like Xcode's inspectors)
- Tab groups within panels
- User-defined panel arrangements beyond position presets
- Panel plugins / third-party panel API

## Prior Art & Research

**Needs a research dossier.** Key questions:

1. What's the state of the art for multi-panel layouts in SwiftUI? (`NavigationSplitView` limitations, custom solutions, third-party libraries)
2. How do professional creative apps handle this? (Lightroom, Capture One, Figma, Final Cut Pro panel systems)
3. What's the best approach for resizable dividers that feel native on macOS?
4. How should panel state be persisted? (per-slideshow? global preference? both?)
5. What does `HSplitView`/`VSplitView` actually support in macOS 26?
6. How do iPad/iPhone apps handle panel collapse in compact width?

### Approaches to evaluate

**A: NavigationSplitView + custom panels.** Use Apple's built-in split view for the primary split, custom views for additional panels. Limited flexibility — NavigationSplitView is opinionated about column behavior.

**B: Custom split view system.** Build a generic `PanelLayout` container that manages N panels with configurable positions and resizable dividers. More work upfront, full control.

**C: Hybrid — NavigationSplitView for the primary editor/preview split, custom container for additional panels.** Pragmatic middle ground.

**D: Use an existing open-source panel library.** Evaluate what's available in the SwiftUI ecosystem.

## Design

_Pending research dossier. Below is the conceptual model._

### Panel types (planned)

| Panel | Priority | Description |
|-------|----------|-------------|
| Editor list | Core | Slide list with reorder, edit, delete |
| Preview | Core | Image preview with mini-navigation |
| File explorer | Future | Shows unused images in working directory |
| Apple Photos | Future | Browse and import from Photos library |
| Presenter notes | Future | Rich text notes for the current slide |
| EXIF inspector | Future | Metadata panel for the selected image |

### Layout presets

```
Desktop (default):        Desktop (preview top):
┌──────┬──────────┐      ┌────────────────────┐
│ List │ Preview  │      │     Preview        │
│      │          │      ├────────────────────┤
│      │          │      │     List           │
└──────┴──────────┘      └────────────────────┘

iPhone (no output):       iPhone (with output):
┌────────────────────┐   Output display:
│     Preview        │   ┌────────────────────┐
├────────────────────┤   │     Preview        │
│     List           │   └────────────────────┘
└────────────────────┘   Phone:
                         ┌────────────────────┐
                         │     List           │
                         └────────────────────┘
```

### State model

- `panelPosition: PanelPosition` enum (`.leading`, `.trailing`, `.top`, `.bottom`)
- `panelSizes: [PanelID: CGFloat]` — persisted divider positions
- Per-slideshow or global? — needs research

## Branches

_To be defined after research dossier and approval._

## Notes

- **Research first:** this plan is intentionally light on implementation details because the right approach depends on evaluating SwiftUI's current capabilities and the ecosystem. A research dossier should precede approval.
- **Incremental delivery:** even after the architecture is chosen, implementation should be incremental — start with preview position toggle (4 positions), then add resizable dividers, then panel extensibility
- **iPhone target:** the app currently targets macOS only. iPhone layout planning is forward-looking but should inform the panel architecture now so we don't paint ourselves into a corner
- **Dependency:** the preview-navigation plan (mini-nav overlay) should work regardless of which edge the preview is on — the overlay design should be position-agnostic
