# TestFlight readiness

> Prove the TestFlight distribution pipeline for macOS and iPhone — ship what we have.

## Status

- **Phase:** Draft
- **Type:** infra
- **Sprint:** <!-- optional, filled when plan is added to a sprint -->

## Changelog

- App is available on TestFlight for macOS and iPhone

## Motivation

We need to prove the distribution pipeline end-to-end before investing in the
real iOS MVP. Ship the current macOS app and the existing iOS tracer-bullet code
via TestFlight. This validates: icon, metadata, signing, archive, upload, and
internal tester install — on both platforms. The iOS tracer bullet is not a
polished product, but it's enough to prove the infra works.

A separate plan (`ios-target`) will handle the real iOS MVP with proper views,
editing, and accessibility.

## Design

### Current state

| Item | Status | Notes |
|------|--------|-------|
| App sandbox + entitlements | Done | Sandbox, user-selected r/w, app-scope bookmarks |
| SlideshowKit iOS support | Done | `Package.swift` declares `.iOS(.v26)` |
| iOS tracer-bullet code | Done | PR #4 — entry point, file picker, page-swipe browsing |
| ImageCache UIImage methods | Done | `#if canImport(UIKit)` already in SlideshowKit |
| App icon artwork | Done | `AppIcon-final.png` (1024x1024) exists at repo root |
| App icon in asset catalog | Missing | Standalone PNG, not in `Assets.xcassets` |
| Version / build number | Missing | No `MARKETING_VERSION` or `CURRENT_PROJECT_VERSION` |
| Info.plist metadata | Incomplete | Only has UTType export; missing display name, copyright |
| Privacy manifest | Missing | No `PrivacyInfo.xcprivacy` — required for App Store |
| Code signing team | Missing | No `DEVELOPMENT_TEAM` in `project.yml` |
| iOS target in project.yml | Missing | Tracer code exists in git history, not yet on main |

### Approach

Single branch, both platforms. The goal is proving the pipeline, not polishing UX.

#### Step 1: Shared infra (both platforms)

1. **App icon** — Add `AppIcon-final.png` to `Assets.xcassets/AppIcon.appiconset`
   with proper `Contents.json` (single 1024x1024 PNG, Xcode generates all sizes)
2. **Version metadata** — Set `MARKETING_VERSION: "0.1.0"` and
   `CURRENT_PROJECT_VERSION: "1"` in `project.yml`, add `CFBundleShortVersionString`
   and `CFBundleVersion` to Info.plist
3. **Info.plist** — Add `CFBundleDisplayName`, `NSHumanReadableCopyright`
4. **Privacy manifest** — Create `PrivacyInfo.xcprivacy` declaring:
   - `NSPrivacyAccessedAPICategoryFileTimestamp` (file modification dates for ordering)
   - No tracking, no collected data types for this MVP
5. **Code signing** — Add `DEVELOPMENT_TEAM` to `project.yml` (team ID: `X8VJSFQ9QC`)

#### Step 2: Restore iOS tracer-bullet target

1. **Cherry-pick tracer code** from PR #4 (commits `f2d6ea0..e707194`):
   - `SlideshowMobile/SlideshowMobileApp.swift` (~80 LOC) — entry point + `.fileImporter`
   - `SlideshowMobile/MobileContentView.swift` (~120 LOC) — page-swipe + thumbnail strip
   - iOS target in `project.yml` with deployment target iOS 26+
   - iOS `Info.plist` with UTType registration for `is.kte.slideshow`
   - iOS entitlements (sandbox not required on iOS, but app-scope bookmarks needed)
2. **Verify build** — Both targets must compile cleanly
3. **Share icon + metadata** — iOS target uses same `Assets.xcassets`

#### Step 3: Archive & upload

1. **macOS archive** — `xcodebuild archive -scheme Slideshow -destination 'platform=macOS'`
2. **iOS archive** — `xcodebuild archive -scheme SlideshowMobile -destination 'generic/platform=iOS'`
3. **Validate** both archives with `xcrun altool --validate-app` or Xcode Organizer
4. **Upload** to App Store Connect
5. **App Store Connect** — Create app record (universal), configure internal TestFlight group
6. **Verify install** — Install on Mac and iPhone from TestFlight

### Decisions

- [x] **Icon format:** Traditional `AppIcon.appiconset` with single 1024x1024 PNG. Liquid Glass `.icon` deferred to a future design pass.
- [x] **App name:** "Slideshow" (working title, can change display name in App Store Connect later)
- [x] **TestFlight group:** Internal only (up to 100 testers, no App Review required)
- [x] **Bundle ID strategy:** Universal app — single `is.kte.slideshow` for both macOS and iPhone
- [x] **iOS scope:** Ship tracer-bullet code as-is (page-swipe browser, no editing). Real iOS MVP is a separate plan.

### Out of scope (deferred to `ios-target` plan)

- iOS-adapted EditorPanel, FileInfoPanel, SettingsView
- Presenter mode on iPhone
- Creating new slideshows on iPhone
- Drag-to-reorder on iPhone
- iOS accessibility audit (tracer code is functional, not polished)
- iOS UI tests

## Branches

- `feature/testflight` — All infra work: icon, metadata, signing, iOS target restore, archive

## Notes

- Team ID `X8VJSFQ9QC` was used successfully in the iOS tracer-bullet branch (PR #4)
- iOS tracer commits: `f2d6ea0`, `46e1a23`, `e707194` — cherry-pick or restore from history
- `docs/app-icon.md` has detailed research on Icon Composer format (for future Liquid Glass pass)
- SlideshowKit's `Package.swift` already declares `.iOS(.v26)` — no package changes needed
- Steps 3 (archive & upload) may require manual Xcode interaction — not fully automatable via CLI
