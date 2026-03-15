# TestFlight readiness

> Prove the TestFlight distribution pipeline for macOS and iPhone — ship what we have.

## Status

- **Phase:** Delivered
- **Delivered:** 2026-03-15
- **Type:** infra
- **Sprint:** <!-- optional, filled when plan is added to a sprint -->

## Approval

- **Approved:** 2026-03-15T13:00:16Z
- **Approved by:** eins78
- **Assignee:** eins78

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
| Privacy manifest | Missing | No `PrivacyInfo.xcprivacy` — required for ALL uploads (ITMS-91053) |
| Export compliance | Missing | Need `ITSAppUsesNonExemptEncryption = NO` in Info.plist |
| Bundle ID registration | Missing | Must register `is.ars.slideshow` in Apple Developer portal |
| Code signing team | Missing | No `DEVELOPMENT_TEAM` in `project.yml` |
| iOS target in project.yml | Missing | Tracer code exists in git history, not yet on main |

### Approach

Single branch, both platforms. The goal is proving the pipeline, not polishing UX.

#### Step 1: Shared infra (both platforms)

1. **Bundle ID registration** — Register `is.ars.slideshow` in
   [Certificates, Identifiers & Profiles](https://developer.apple.com/account/resources/identifiers/list)
   on the Apple Developer portal. Must exist before creating the app record.
2. **App icon** — Add `AppIcon-final.png` to `Assets.xcassets/AppIcon.appiconset`
   with proper `Contents.json`. Single 1024x1024 works for iOS; for macOS 26 with
   squircle unification, test whether single-size works or if all sizes are still needed.
3. **Version metadata** — Set `MARKETING_VERSION: "0.1.0"` and
   `CURRENT_PROJECT_VERSION: "1"` in `project.yml`, add `CFBundleShortVersionString`
   and `CFBundleVersion` to Info.plist
4. **Info.plist** — Add:
   - `CFBundleDisplayName` — "Slideshow"
   - `NSHumanReadableCopyright` — e.g. "Copyright © 2026 ars.is"
   - `ITSAppUsesNonExemptEncryption` = `NO` (no custom encryption, skip export
     compliance dialog on every upload)
5. **Privacy manifest** — Create `PrivacyInfo.xcprivacy` declaring:
   - `NSPrivacyAccessedAPICategoryFileTimestamp` reason `3B52.1` (user-granted file access)
   - `NSPrivacyAccessedAPICategoryUserDefaults` reason `CA92.1` (app uses `@AppStorage`)
   - `NSPrivacyTracking` = `false`, no collected data types
   - Required for ALL uploads including internal TestFlight (ITMS-91053 rejection otherwise)
6. **Code signing** — Add `DEVELOPMENT_TEAM` to `project.yml` (team ID: `X8VJSFQ9QC`).
   Automatic signing handles provisioning profiles for TestFlight.

#### Step 2: Restore iOS tracer-bullet target

1. **Cherry-pick tracer code** from PR #4 (commits `f2d6ea0..e707194`):
   - `SlideshowMobile/SlideshowMobileApp.swift` (~80 LOC) — entry point + `.fileImporter`
   - `SlideshowMobile/MobileContentView.swift` (~120 LOC) — page-swipe + thumbnail strip
   - iOS target in `project.yml` with deployment target iOS 26+
   - iOS `Info.plist` with UTType registration for `is.ars.slideshow`
   - iOS entitlements (sandbox not required on iOS, but app-scope bookmarks needed)
2. **Verify build** — Both targets must compile cleanly
3. **Share icon + metadata** — iOS target uses same `Assets.xcassets`

#### Step 3: App Store Connect setup

1. **Create app record** — App Store Connect > Apps > New App:
   - Platforms: iOS + macOS (or add macOS via "Add Platform" after)
   - Name: "Slideshow"
   - Bundle ID: `is.ars.slideshow` (from dropdown, must be pre-registered)
   - SKU: `slideshow` (permanent, internal-only identifier)
   - Primary language: English (U.S.)
2. **Configure TestFlight** — Add internal tester group

#### Step 4: Archive & upload

1. **macOS archive:**
   ```bash
   xcodebuild archive -scheme Slideshow \
     -destination 'generic/platform=macOS' \
     -archivePath ./build/Slideshow-macOS.xcarchive
   ```
2. **iOS archive:**
   ```bash
   xcodebuild archive -scheme SlideshowMobile \
     -destination 'generic/platform=iOS' \
     -archivePath ./build/Slideshow-iOS.xcarchive
   ```
3. **Upload** both via `xcodebuild -exportArchive` with `ExportOptions.plist`:
   ```xml
   <dict>
     <key>method</key>
     <string>app-store-connect</string>
     <key>destination</key>
     <string>upload</string>
     <key>teamID</key>
     <string>X8VJSFQ9QC</string>
   </dict>
   ```
   Note: `app-store` method name is deprecated — use `app-store-connect`.
4. **Verify install** — Install on Mac and iPhone from TestFlight
   - Internal builds available immediately (no App Review), expires after 90 days

### Decisions

- [x] **Icon format:** Traditional `AppIcon.appiconset` with single 1024x1024 PNG. Liquid Glass `.icon` deferred to a future design pass.
- [x] **App name:** "Slideshow" (working title, can change display name in App Store Connect later)
- [x] **TestFlight group:** Internal only (up to 100 testers, no App Review required)
- [x] **Bundle ID strategy:** Universal app — single `is.ars.slideshow` for both macOS and iPhone
- [x] **iOS scope:** Ship tracer-bullet code as-is (page-swipe browser, no editing). Real iOS MVP is a separate plan.

### Out of scope (deferred to `ios-target` plan)

- iOS-adapted EditorPanel, FileInfoPanel, SettingsView
- Presenter mode on iPhone
- Creating new slideshows on iPhone
- Drag-to-reorder on iPhone
- iOS accessibility audit (tracer code is functional, not polished)
- iOS UI tests

## Branches

- `feature/testflight` — All infra work: icon, metadata, signing, iOS target restore, archive → #13

## Notes

- Team ID `X8VJSFQ9QC` was used successfully in the iOS tracer-bullet branch (PR #4)
- iOS tracer commits: `f2d6ea0`, `46e1a23`, `e707194` — cherry-pick or restore from history
- `docs/app-icon.md` has detailed research on Icon Composer format (for future Liquid Glass pass)
- SlideshowKit's `Package.swift` already declares `.iOS(.v26)` — no package changes needed
- Archive & upload can be done via CLI (`xcodebuild -exportArchive`) or Xcode Organizer
- Authentication for upload requires App Store Connect API key or Apple ID in Xcode keychain
- Once both platforms are approved for App Store (not TestFlight), universal purchase is permanent
- Privacy manifest required-reason API categories: file timestamps, user defaults, system boot time,
  disk space, active keyboards. CGImageSource/ImageIO is NOT in the list.
