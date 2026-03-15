# TestFlight readiness

> Get the app ready for TestFlight distribution — macOS first, iPhone second.

## Status

- **Phase:** Draft
- **Type:** infra
- **Sprint:** <!-- optional, filled when plan is added to a sprint -->

## Changelog

- App is available on TestFlight for macOS (and iPhone)

## Motivation

The app is functionally complete for an initial preview. We need to package it
for TestFlight so testers can install it. The codebase builds cleanly, has 62
passing tests, and the architecture already supports iOS 26+ via SlideshowKit.
The main gaps are administrative: icon integration, version metadata, privacy
manifest, and code signing configuration.

## Design

### Current state

| Item | Status | Notes |
|------|--------|-------|
| App sandbox + entitlements | Done | Sandbox, user-selected r/w, app-scope bookmarks |
| SlideshowKit iOS support | Done | `Package.swift` declares `.iOS(.v26)` |
| App icon artwork | Done | `AppIcon-final.png` (1024x1024) exists at repo root |
| App icon in asset catalog | Missing | Standalone PNG, not in `Assets.xcassets` |
| Version / build number | Missing | No `MARKETING_VERSION` or `CURRENT_PROJECT_VERSION` |
| Info.plist metadata | Incomplete | Only has UTType export; missing display name, copyright |
| Privacy manifest | Missing | No `PrivacyInfo.xcprivacy` — required for App Store |
| Code signing team | Missing | No `DEVELOPMENT_TEAM` in `project.yml` |
| iOS app target | Missing | Only macOS target in `project.yml` |

### Approach

Work in priority order: macOS TestFlight first, then add iPhone target.

#### Phase 1: macOS TestFlight

1. **App icon** — Add `AppIcon-final.png` to `Assets.xcassets/AppIcon.appiconset`
   with proper `Contents.json` (or use Icon Composer .icon format per `docs/app-icon.md`)
2. **Version metadata** — Set `MARKETING_VERSION: "0.1.0"` and
   `CURRENT_PROJECT_VERSION: "1"` in `project.yml`, add `CFBundleShortVersionString`
   and `CFBundleVersion` to Info.plist
3. **Info.plist** — Add `CFBundleDisplayName`, `NSHumanReadableCopyright`
4. **Privacy manifest** — Create `PrivacyInfo.xcprivacy` declaring:
   - `NSPrivacyAccessedAPICategoryFileTimestamp` (file modification dates for ordering)
   - No tracking, no collected data types for this MVP
5. **Code signing** — Add `DEVELOPMENT_TEAM` to `project.yml` (team ID: `X8VJSFQ9QC`
   from prior iOS tracer-bullet work)
6. **Archive & upload** — Build release archive, validate, upload to App Store Connect
7. **App Store Connect** — Create app record, configure TestFlight group

#### Phase 2: iPhone target

1. **Add iOS target** to `project.yml` sharing SlideshowKit dependency
2. **Adapt views** — Replace AppKit interop (NSWindow, NSHostingView) with
   iOS-native presentation; no dual-screen presenter on iPhone
3. **File access** — Replace `NSOpenPanel` with `.fileImporter` (already proven in
   iOS tracer-bullet PR #4)
4. **Touch interactions** — Swipe gestures for slide navigation, pinch-to-zoom
5. **Test on device** — Verify on physical iPhone via TestFlight

### Open Questions

- [ ] Use Icon Composer `.icon` format (Xcode 26+) or traditional multi-size PNG set?
- [ ] App name on TestFlight: "Slideshow" or working title "Mappe"?
- [ ] TestFlight group: internal only, or external beta testers too?
- [ ] Should iPhone target share the same bundle ID or use a separate one?

## Branches

- `feature/testflight-macos` — Phase 1: icon, metadata, privacy manifest, signing config
- `feature/testflight-ios` — Phase 2: add iPhone target, adapt views for touch

## Notes

- Team ID `X8VJSFQ9QC` was used successfully in the iOS tracer-bullet branch (PR #4)
- `docs/app-icon.md` has detailed research on Icon Composer format
- SlideshowKit's `Package.swift` already declares `.iOS(.v26)` — no package changes needed
- The iOS tracer-bullet (worktree-ios) proved the architecture works on iPhone
