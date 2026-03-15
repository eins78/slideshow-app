# Accessibility Rules

These rules apply when writing or modifying any SwiftUI view file.

Based on [swift-agents/mobile-a11y-specialist](https://github.com/Techopolis/swift-agents) (MIT).

## Required modifiers

- Every `Button`, `Toggle`, and custom interactive control MUST have an `accessibilityLabel`
- Icon-only buttons MUST have an `accessibilityLabel` (SF Symbol name is not sufficient)
- Content images (`Image(uiImage:)`, `Image(nsImage:)`) MUST have `.accessibilityLabel` and `.accessibilityAddTraits(.isImage)`
- Decorative images (backgrounds, dividers, chrome) MUST use `.accessibilityHidden(true)`
- Tappable images MUST also have `.accessibilityAddTraits(.isButton)`
- Section headers MUST use `.accessibilityAddTraits(.isHeader)`
- Use `.accessibilityAddTraits` — never direct trait assignment (overwrites defaults)

## Grouping

- List rows with multiple text elements: `.accessibilityElement(children: .combine)`
- Slide metadata (filename + caption + info): group into single VoiceOver element
- Modal overlays: `.accessibilityAddTraits(.isModal)` + escape action

## Keyboard navigation

- All primary actions MUST have keyboard shortcuts
- Presentation mode: arrow keys, space, escape already required
- Slide list: up/down selection, enter to preview, delete to remove

## Dynamic Type and appearance

- Use system fonts or `@ScaledMetric` — no hardcoded font sizes
- Respect `@Environment(\.accessibilityReduceMotion)` for animations
- Respect `@Environment(\.accessibilityReduceTransparency)` for blur effects
- Never convey information by color alone — add icons, labels, or patterns

## Click targets

- Minimum 44x44 points for all interactive elements
- Grid items, toolbar buttons, and context menu triggers included

## Review agent

For active accessibility auditing during review, dispatch the `mobile-a11y-specialist` agent (from swift-agents upstream).
