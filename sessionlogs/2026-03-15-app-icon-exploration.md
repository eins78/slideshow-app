# App Icon Exploration & Icon Composer Research

**Date:** 2026-03-15
**Branch:** `worktree-branding`
**Session type:** Research & experimentation

## What happened

Explored drawing an app icon entirely in code and investigated Apple's new Icon Composer `.icon` file format.

## Icon generation

- Drew 1024×1024 app icons using `CGContext` + Core Graphics via Xcode's `ExecuteSnippet` MCP tool
- Generated multiple variants (v1, v2/final) with different levels of detail
- **v1 selected** as preferred direction — simpler mountain silhouettes read better as the letter "M"
- Also generated three separate transparent-background layer PNGs (background, foreground, front) for future Icon Composer import

### Icon concept

A framed sunset landscape with mountain silhouettes forming "M" for **"Mappe"** (working title). Five slideshow navigation dots below the frame. Deep teal-to-navy background gradient.

## Icon Composer `.icon` format research

Reverse-engineered Apple's undocumented `.icon` package format:

- **Structure:** macOS package with `icon.json` manifest + `assets/` directory
- **Framework:** `IconComposerFoundation.framework` (private, symbols not exported for dlsym)
- **Key types:** `IconComposition` → `Group` → `Layer`, with `SpecializableProperty<T>` for light/dark/tinted variants
- **JSON keys:** kebab-case confirmed (`image-name` works, `imageName` doesn't)
- **Compilation:** `xcrun actool` can compile `.icon` → `.icns`/`.car` when inside an `.xcassets` catalog
- **Blocker:** exact `icon.json` schema undocumented; asset lookup uses NSFileWrapper internals, not filesystem paths — couldn't produce a fully valid `.icon` file programmatically

### Approaches tried

1. `ExecuteSnippet` to draw icon — **worked** (sandbox writes to app container)
2. AppleScript to control Icon Composer — **blocked** (no assistive access)
3. `dlsym` to call `IconComposerFoundation` Swift APIs — **blocked** (symbols not in export trie)
4. Manual `.icon` construction + `actool` compilation — **partial** (JSON parsed, assets not found)
5. Web research for schema docs — **no public documentation exists**

## Decisions

- Working title: **"Mappe"**
- Icon v1 preferred over v2 (simpler mountains, cleaner "M" read)
- Mountains-as-M is the core visual concept to refine

## Files created

- `AppIcon-v1.png` — preferred icon variant (1024×1024)
- `AppIcon-final.png` — alternative with more detail (sun, water shimmer)
- `docs/app-icon.md` — full icon documentation with concept, palette, and format research

## Next steps

- [ ] Refine mountain peaks for a cleaner "M" silhouette
- [ ] Test icon with macOS rounded-rect mask applied
- [ ] Try importing layers into Icon Composer GUI for Liquid Glass treatment
- [ ] Create `AppIcon.appiconset` or `.icon` file for the Xcode project
- [ ] Decide on final app name (Mappe vs alternatives)
