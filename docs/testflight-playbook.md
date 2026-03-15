# TestFlight Playbook

How to ship a new TestFlight build for Slideshow. Covers both macOS and iOS.

## Prerequisites

- Xcode with signing configured (team `X8VJSFQ9QC`, automatic signing)
- App record exists in App Store Connect ("Slideshow Image Presentations", bundle `is.ars.slideshow`)
- Internal tester group configured in TestFlight

## 1. Bump version numbers

In `project.yml` under `settings.base`:

```yaml
MARKETING_VERSION: "0.2.0"      # user-facing version (semver)
CURRENT_PROJECT_VERSION: "2"     # build number (integer, must increment per upload)
```

**Rules:**
- `CURRENT_PROJECT_VERSION` must be higher than any previously uploaded build — App Store Connect rejects duplicates
- `MARKETING_VERSION` can stay the same across builds (e.g., multiple beta builds for the same version)
- Regenerate after changing: `xcodegen generate`

## 2. Build and test

```bash
xcodegen generate
cd SlideshowKit && swift test
xcodebuild -project Slideshow.xcodeproj -scheme Slideshow -destination 'platform=macOS' build
xcodebuild -project Slideshow.xcodeproj -scheme SlideshowMobile -destination 'generic/platform=iOS' build
```

All must pass with zero errors before archiving.

## 3. Archive

### macOS

```bash
xcodebuild archive -project Slideshow.xcodeproj \
  -scheme Slideshow \
  -destination 'generic/platform=macOS' \
  -archivePath ./build/Slideshow-macOS.xcarchive
```

### iOS

```bash
xcodebuild archive -project Slideshow.xcodeproj \
  -scheme SlideshowMobile \
  -destination 'generic/platform=iOS' \
  -archivePath ./build/Slideshow-iOS.xcarchive
```

## 4. Upload

### macOS

```bash
xcodebuild -exportArchive \
  -archivePath ./build/Slideshow-macOS.xcarchive \
  -exportOptionsPlist ExportOptions.plist \
  -allowProvisioningUpdates
```

### iOS

```bash
brew unlink rsync    # workaround for Xcode 26 beta rsync mismatch
xcodebuild -exportArchive \
  -archivePath ./build/Slideshow-iOS.xcarchive \
  -exportOptionsPlist ExportOptions.plist \
  -exportPath ./build/export-ios \
  -allowProvisioningUpdates
brew link rsync      # restore after upload
```

The `ExportOptions.plist` at repo root configures `app-store-connect` method with team ID.

Alternatively, use Xcode GUI: Window > Organizer > select archive > Distribute App > TestFlight Internal Only.

## 5. Verify

- Internal builds appear in TestFlight within minutes (no App Review)
- Install on Mac and iPhone from TestFlight app
- Builds expire after 90 days

## Troubleshooting

### "The app name you entered is already being used"

Generic names ("Slideshow", "Photos", etc.) are reserved. Use a distinctive name in App Store Connect. The `CFBundleDisplayName` on the Home Screen can still be "Slideshow" — the store name and display name are independent.

### "Info.plist must contain LSApplicationCategoryType"

Required for macOS App Store / TestFlight distribution. Add to `Slideshow/Info.plist`:

```xml
<key>LSApplicationCategoryType</key>
<string>public.app-category.photography</string>
```

The CLI upload doesn't validate this — only the Xcode GUI "TestFlight Internal Only" flow catches it. Add it anyway to avoid surprises.

### "Incomplete Document Type Configuration" (warning)

Add `LSHandlerRank` to each `CFBundleDocumentTypes` entry:

```xml
<key>LSHandlerRank</key>
<string>Alternate</string>
```

### ITMS-91053: Missing privacy manifest

Every upload (including internal TestFlight) requires `PrivacyInfo.xcprivacy`. The project includes one declaring file timestamp and user defaults API usage.

### CLI and Xcode GUI archives are independent

Xcode Organizer and `xcodebuild archive` use separate build pipelines. An archive created by CLI won't appear in Organizer, and vice versa. If you change code after a CLI archive, the GUI will rebuild — resulting in a new build number. To keep build numbers predictable, pick one workflow and stick with it.

### iOS export "Copy failed" (rsync error)

Xcode 26 beta invokes `/usr/bin/rsync` with `--extended-attributes` (`-E`), but if Homebrew's rsync 3.4.1 is linked, it creates a version mismatch between client (system openrsync) and server (Homebrew rsync). Fix:

```bash
brew unlink rsync        # before distributing
# ... distribute in Xcode Organizer ...
brew link rsync          # restore after
```

Affects both CLI and GUI for iOS. macOS export is unaffected (no IPA/rsync step).

## Reference

- App Store Connect name: **Slideshow Image Presentations**
- Bundle ID: `is.ars.slideshow` (universal, both platforms)
- Team ID: `X8VJSFQ9QC`
- SKU: `slideshow`
- Category: `public.app-category.photography`
- `ExportOptions.plist`: repo root
- Privacy manifest: `Slideshow/PrivacyInfo.xcprivacy`
