# iOS Tracer Bullet — iPhone Slideshow Viewer

**Date:** 2026-03-14
**Branch:** `worktree-ios` (PR #4 → `feature/slideshowkit-core`)
**Status:** Tracer complete, working on device and simulator

## What Was Done

Built a minimal iPhone app that proves SlideshowKit works on iOS end-to-end:
open `.slideshow` bundle from Files → scan slides → display images → swipe navigate.

### Commits

1. `f2d6ea0` — add minimal iPhone app target (tracer bullet)
   - `ImageCache.swift`: added `#if canImport(UIKit)` UIImage convenience methods
   - `project.yml`: added iOS deployment target + SlideshowMobile target
   - `SlideshowMobile/SlideshowMobileApp.swift`: app entry with fileImporter
   - `SlideshowMobile/MobileContentView.swift`: TabView page-swipe + thumbnail strip
   - `SlideshowMobile/Info.plist`: UTType import + document types

2. `335f9fe` — fix iOS app: security-scoped access, launch screen, signing
   - Security-scoped access must stay alive (not defer-stopped) for ImageCache to read files
   - Added UILaunchScreen + UISupportedInterfaceOrientations
   - Added DEVELOPMENT_TEAM (X8VJSFQ9QC) and CODE_SIGN_STYLE to project.yml

## Key Decisions & Findings

- **TabView with `.page` style** for swipe navigation — simplest approach, proves the interaction model
- **Security-scoped access lifetime** was the main bug: `defer { stop }` in `openSlideshow()` killed file access before views could load images. Fix: keep access alive as `@State`, stop only when opening a new slideshow
- **Xcode 26 beta build issues**: `xcodebuild -scheme` couldn't find iOS destinations until the iOS 26 simulator runtime was installed. Workaround before that: `-target` with custom build dirs
- **Yams Bazel `build` file** conflicts with Xcode's intermediate build directory — known Xcode 26 beta issue, resolved by using custom BUILD_DIR or by the simulator runtime install fixing scheme resolution
- **Info.plist needed manual bundle keys** because `GENERATE_INFOPLIST_FILE: false` — added CFBundleIdentifier, CFBundleName, etc.

## What's NOT Built (Next Steps)

- No presenter/audience mode
- No editor panel (caption/notes editing)
- No EXIF/file info panel
- No drag reordering
- No bookmarks/persistence
- No settings
- No error handling beyond basic guards
- No "new slideshow" creation
