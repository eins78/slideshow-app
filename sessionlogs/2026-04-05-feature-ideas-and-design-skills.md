# Feature ideas capture and design skill installation

**Date:** 2026-04-05 / 2026-04-06
**Branch:** `idea/batch-preview-navigation`
**PR:** #24 (draft)

## What happened

### Feature ideas via /plot-idea (batch mode)

Captured two feature ideas as draft plans:

1. **preview-navigation** — mini-navigation overlay in preview panel with back/forward buttons and a "follow editor cursor" toggle. Default on (preview tracks editor selection), toggle off for independent browsing.
2. **flexible-layout** — configurable panel positions (left/right/top/bottom), iPhone-adaptive defaults, scalable panel system for future panels (file explorer, Apple Photos import, presenter notes). Flagged as needing a research dossier before approval.

Both plans are intentionally light on implementation details — meant to be refined before `/plot-approve`.

### GitHub stars research for design agent skills

Searched 724 starred repos for design/UI/accessibility skills relevant to a SwiftUI image slideshow app. Ranked results:

**Installed as marketplace plugins (both repos):**
- `pbakaus/impeccable` — design language skill with 20 commands (/polish, /audit, /critique, /typeset). Typography, color (OKLCH), spatial design, motion design references.
- `Community-Access/accessibility-agents` — 79 accessibility agents, WCAG 2.2 AA. Note: has enforcement hooks that may overlap with existing swift-agents `mobile-a11y-specialist`.

**Copied as raw skills to home-workspace (private repo):**
- `Leonxlnx/taste-skill` @ `f05a85b` (2026-03-29) — 7 variants (taste, soft, minimalist, brutalist, redesign, output, stitch). Note: React/Tailwind-focused implementation details, but design principles transfer to SwiftUI.
- `rjs/shaping-skills` @ `7d8c311` (2026-03-04) — 5 skills (shaping, breadboarding, framing-doc, kickoff-doc, breadboard-reflection). Shape Up methodology for collaborative problem definition.

**Not installed (no clean path):**
- `msitarzewski/agency-agents` — personality-driven prompts, less rigorous than swift-agents
- `aplaceforallmystuff/claude-art-skill` — image generation via Gemini, not code
- `obra/the-elements-of-style` — writing quality (already available as `elements-of-style@superpowers-marketplace`, currently disabled)

### Installation decisions

- Marketplace plugins (`extraKnownMarketplaces` in `~/.claude/settings.json`) for repos with `.claude-plugin/marketplace.json`
- Raw skill copy for repos without plugin manifests — only to home-workspace (private), not slideshow-app (public)
- Each copied skill gets a README.md with source repo link, commit hash, commit date, copy date
- Symlinks rejected — Claude Code discovers skills via `plugin.json` → `skills` field, not directory scanning

## Commits

**slideshow-app** (`idea/batch-preview-navigation`, rebased on main):
- `5b963f7` — plot: preview panel mini-navigation, flexible panel layout system
- `b244640` — enable impeccable and accessibility-agents plugins

**home-workspace** (`main`):
- `366c29b` — add design and shaping skills, enable impeccable and accessibility-agents plugins

## Next steps

- [ ] Refine plan Design and Branches sections for both ideas
- [ ] Commission research dossier for flexible-layout (SwiftUI panel systems state of the art)
- [ ] `gh pr ready 24` when plans are refined
- [ ] Evaluate accessibility-agents hooks for conflicts with swift-agents workflow
