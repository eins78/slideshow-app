# App Icon — "Mappe"

## Concept

The icon shows a **framed landscape photograph** — a sunset mountain scene inside a picture frame on a deep teal background, with slideshow navigation dots below.

The mountain silhouettes form the letter **"M"** for "Mappe" (German: folder/portfolio), the app's working title.

### Visual elements

| Layer | Description |
|-------|-------------|
| Background | Dark teal-to-navy diagonal gradient |
| Frame | Cream/gold border with inner mat line |
| Landscape | Sunset sky gradient (blue → purple → orange), mountain silhouettes, dark water/ground |
| Dots | 5 navigation dots below frame, center dot highlighted (active slide) |

### Color palette

- Background: `#0F1A2D` → `#0D3348` → `#152139`
- Frame border: `rgb(0.92, 0.87, 0.75)` — warm cream/gold
- Sky top: `rgb(0.20, 0.30, 0.55)` — deep blue
- Sky mid: `rgb(0.55, 0.40, 0.50)` — mauve
- Sky low: `rgb(0.85, 0.55, 0.35)` — warm orange
- Mountains: `rgb(0.10, 0.12, 0.18)` — near-black blue
- Dots active: `rgb(0.92, 0.87, 0.75)` at 90% opacity
- Dots inactive: same color at 35% opacity

## Current state

- **v1 preferred** — `AppIcon-v1.png` (1024×1024, ~665 KB)
- Layers also generated separately for future Icon Composer use

### Refinement ideas

- Adjust mountain peaks for a cleaner "M" read
- Add subtle sun/moon between peaks
- Try lighter frame weight
- Test with macOS rounded-rect mask applied
- Explore Liquid Glass treatment via Icon Composer layers

## How the icon was generated

Drawn entirely in code using `CGContext` + Core Graphics, executed via Xcode's `ExecuteSnippet` MCP tool. No external design tools needed.

The generation code creates a 1024×1024 bitmap context, draws gradient backgrounds, stroked frame borders, clipped sky gradients, path-based mountain silhouettes, and filled ellipse dots — all with the Core Graphics C API from Swift.

### Layer images for Icon Composer

Three separate layers were also generated (transparent PNGs, 1024×1024):

1. **Background** — solid gradient, no transparency
2. **Foreground** — framed landscape with transparent surround
3. **Front** — navigation dots only, mostly transparent

These can be dragged into Icon Composer to create a `.icon` file with Liquid Glass effects.

## Icon Composer `.icon` format (research notes)

The `.icon` format introduced in Xcode 26 is a **macOS package** (folder treated as single file):

```
AppIcon.icon/
├── icon.json          # composition manifest
└── assets/            # layer image files (SVG preferred, PNG supported)
    ├── background.svg
    ├── foreground.svg
    └── front.svg
```

### What we know

- UTType: `com.apple.iconcomposer.icon` conforming to `com.apple.package`
- Built on `IconComposerFoundation.framework` → `IconComposition` → `Group` → `Layer`
- `icon.json` uses **kebab-case** keys (confirmed: `image-name`, not `imageName`)
- Layers support: `name`, `image-name`, `position`, `fill`, `opacity`, `isGlass`, `blendMode`
- Groups add: `blurMaterial`, `translucency`, `shadow`, `specular`, `lighting`
- Properties use `SpecializableProperty<T>` for light/dark/tinted mode variants
- Serialization internally uses `NSFileWrapper` snapshots
- `actool` compiles `.icon` → `.icns` + `Assets.car` (within an `.xcassets` catalog)

### What remains undocumented

- Exact `icon.json` schema (Apple hasn't published it)
- How `image-name` resolves to asset files (NSFileWrapper key lookup, not filesystem path)
- The `SpecializableProperty` JSON encoding for mode variants

### Compilation

```bash
# .icon must be inside an .xcassets catalog for actool
xcrun actool \
  --compile <output-dir> \
  --app-icon AppIcon \
  --platform macosx \
  --include-all-app-icons \
  --minimum-deployment-target 26.0 \
  --output-partial-info-plist <output-dir>/partial.plist \
  <path-to>/Assets.xcassets
```

### References

- [Creating your app icon using Icon Composer — Apple](https://developer.apple.com/documentation/Xcode/creating-your-app-icon-using-icon-composer)
- [Adding Icon Composer icons to Xcode — Use Your Loaf](https://useyourloaf.com/blog/adding-icon-composer-icons-to-xcode/)
- [Icon Composer Notes — Virtual Sanity](https://www.virtualsanity.com/202507/icon-composer-notes/)
- [Create icons with Icon Composer — WWDC25](https://developer.apple.com/videos/play/wwdc2025/361/)
- [swift-bundler .icon support](https://github.com/moreSwift/swift-bundler/pull/119) — `LayeredIconCompiler.swift` shows actool invocation
