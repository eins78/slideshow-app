# Live Preview Bug Fixes + Agent Workflow Audit

**Date:** 2026-03-15
**Branch:** `feature/live-preview` → merged to `main`
**PR:** https://github.com/eins78/slideshow-app/pull/22
**Session:** `03a410ef` (continuation of text-view-implementation session)

## Context

Resumed from a prior session that implemented live preview with cursor-following in text-view mode (PR #22). Two bugs were reported during manual testing, plus a discovery that agent workflow rules were being systematically ignored.

## Work Done

### Bug Fixes (3 commits)

1. **Cursor-after-trailing-separator bug** (`51a8991`)
   - `CursorSlideMapper` returns index beyond slide count when cursor is on empty line after trailing `---\n` (produced by `SlideshowWriter`)
   - Fix: clamp `rawIndex` to `min(rawIndex, doc.slides.count - 1)` in `SlideshowTextView.updatePreviewForCursor`
   - Added 2 tests documenting trailing separator behavior (cursor ON vs AFTER)
   - Key insight: multiline string literals don't end with `\n` but `SlideshowWriter` output does — test needed `\n` appended to match real output

2. **HSplitView layout jank** (`b37242a`)
   - `HSplitView` re-distributes width when child content identity changes (list→grid→text swap)
   - Fix: replaced `HSplitView` with `HStack(spacing: 0)` + custom `HorizontalDivider` + `@State previewWidth`
   - Initial implementation had drag jank — feedback loop from local coordinate space shifting as divider moved
   - Fix: `DragGesture(coordinateSpace: .global)` + `Optional` sentinel instead of `== 0` check
   - Applied same fix to existing `DraggableDivider` (vertical variant had same bug)
   - User requested dynamic max width — changed from hardcoded `400` to `GeometryReader` based `containerWidth - 308`

3. **Agent workflow rules** (`fc31e5c`) — see below

### Agent Workflow Audit

**Critical finding:** Across 11 session logs / 89 commits, **zero specialist agents were ever invoked** despite the swift-agents infrastructure being installed and a `UserPromptSubmit` hook configured. All reviews were done via Gemini (`/ai-review`), never specialist agents.

**Root cause analysis of this session's failures:**
- Hook message was informational ("If this task involves Swift...") — easy to rationalize skipping
- Hook told the LLM WHAT to do but not HOW (no `Agent` tool syntax)
- DoD was a passive list in CLAUDE.md, not an active gate
- Speed-oriented user messages ("push ot") were interpreted as permission to skip process

**Changes made:**
- New `.claude/rules/agent-workflow.md` — authoritative workflow reference with:
  - Mandatory swift-lead dispatch with exact `Agent` tool syntax
  - List of prohibited rationalizations
  - 4 STOP checkpoints (before code, before commit, after commit, before push)
  - Two-phase review model explanation (specialists pre-code, Gemini post-commit)
  - Exclusion criteria for non-code tasks
  - Commit protocol consolidated from `git-and-workflow.md`
- Updated hook to blocking tone with dispatch syntax and exclusions
- Restructured CLAUDE.md DoD as "BLOCKING GATE" with phases
- Added DoD item 0: dispatch swift-lead before any Swift code

## Decisions

- **Clamp in caller, not mapper:** `CursorSlideMapper` is a pure separator-counting function — it shouldn't know about slide count. The caller owns the domain knowledge.
- **Custom divider over HSplitView:** HSplitView has no API to lock divider position when children change. Custom HStack + divider is the standard workaround.
- **Global coordinate space for drag:** Local coordinates create feedback loops when the dragged view moves during drag. This is a known SwiftUI pattern.
- **agent-workflow.md is the single authority:** Consolidated review workflow from 3 files into 1 to prevent contradictions and reduce "I didn't see that rule" failures.

## Commits

| Hash | Description |
|------|-------------|
| `51a8991` | fix cursor-after-trailing-separator showing wrong slide |
| `b37242a` | fix layout jank: replace HSplitView with stable HStack + divider |
| `fc31e5c` | add agent-workflow rules with dispatch syntax and review model |
| `3b9b89a` | merge feature/live-preview into main |

## Pending

- [ ] DoD items 10-11 were not run on commits `51a8991` and `b37242a` (no `/simplify` or `/ai-review`)
- [ ] The new agent workflow rules have not yet been tested in a real Swift implementation session
- [ ] Worktree at `.worktrees/live-preview/` can be cleaned up now that branch is merged
