# Agent Workflow — Mandatory for All Swift Code

This rule file is the authoritative reference for when and how to use swift-agents specialists. It is NOT optional. Skipping it is a workflow violation.

## CRITICAL: Swift-agents are mandatory

This is a Swift/SwiftUI project. Every implementation task MUST go through `swift-lead` dispatch. There are no exceptions — not for "simple" fixes, not for "just one file", not for urgent requests.

**Common rationalizations that are violations:**
- "This is too simple for specialist review" — simple code has simple reviews; skip nothing
- "The user wants this fast" — fast and wrong costs more than slow and right
- "I'll just do this one thing first" — the first thing IS dispatching swift-lead
- "It's only a test file / config change" — testing-specialist exists for exactly this

## When to dispatch swift-lead

**Before writing any Swift code.** Not after. Not "when it seems complex enough." Before.

swift-lead evaluates the task and routes to the right specialists:
- UI code → `swiftui-specialist` + `mobile-a11y-specialist`
- Async/actor/Task code → `concurrency-specialist`
- Image loading, caching, rendering → `performance-specialist`
- Tests → `testing-specialist`
- Models, persistence → `swiftdata-specialist`
- Security, keychain → `swift-security-specialist`

### How to dispatch

Use the `Agent` tool with `subagent_type: "swift-lead"` and describe the task:

```
Agent(subagent_type: "swift-lead", prompt: "Review this task: [describe what you're about to implement]")
```

### How swift-lead works

swift-lead is an **orchestrator**, not a single reviewer. It:
1. Reads the task description and relevant code
2. Dispatches **1-5 specialists in parallel** based on what the task touches
3. Synthesizes their recommendations into guidance
4. Does NOT write code itself — it delegates and coordinates

**Mandatory pairs** (swift-lead enforces these automatically):
- UI code → always gets `swiftui-specialist` + `mobile-a11y-specialist`
- Async/actor code → always gets `concurrency-specialist`
- AI features → relevant AI specialist + `concurrency-specialist`

**Review order:** architecture first, implementation second, accessibility last.

**Example:** Task "Fix drag jank in HorizontalDivider" → swift-lead dispatches:
- `swiftui-specialist` (gesture patterns, view composition)
- `mobile-a11y-specialist` (divider accessibility)
- `performance-specialist` (rendering during drag)

### When NOT to dispatch swift-lead

These tasks do not require specialist agents:
- Documentation-only changes (CLAUDE.md, plans, READMEs, session logs)
- Git admin (branch cleanup, plot commands, merge operations, PR descriptions)
- Non-code config (editing .gitignore, project.yml structure-only changes)
- Pure research / codebase exploration (reading files, searching)

If in doubt, dispatch — a quick "not needed" from swift-lead costs less than a missed review.

## Two-phase review model

This project uses two complementary review mechanisms at different stages:

**Phase 1 — Pre-code (specialist agents):** Before writing code, dispatch `swift-lead` → specialist agents provide design guidance, catch architectural issues, and ensure accessibility/concurrency/performance are considered upfront.

**Phase 2 — Post-commit (Gemini review):** After committing code, run `/simplify` → `/ai-review` (routes to Gemini). Gemini catches implementation bugs, logic errors, and missed edge cases in the actual code.

These are **not alternatives** — both phases are required. Specialists prevent bad designs. Gemini catches bad implementations.

## STOP checkpoints

You MUST stop and verify at these points. Each checkpoint is a gate — do not proceed past it until all items are satisfied.

### Checkpoint 1: Before first code write
- [ ] Have I dispatched `swift-lead`?
- [ ] Have the relevant specialists reviewed the approach?
- [ ] If writing UI code: has `mobile-a11y-specialist` been consulted?
- [ ] If writing concurrent code: has `concurrency-specialist` been consulted?

### Checkpoint 2: Before commit
- [ ] `cd SlideshowKit && swift test` — zero failures
- [ ] `xcodebuild -scheme Slideshow -destination 'platform=macOS' build` — zero warnings
- [ ] All DoD items 1-9 verified (see CLAUDE.md)

### Checkpoint 3: After commit, before next task
- [ ] Run `/simplify` on changed code
- [ ] If findings: fix and commit as a **separate** commit (never amend into the original)
- [ ] Run `/ai-review` for Gemini review
- [ ] If findings: fix and commit as a **separate** commit, re-run `/ai-review`
- [ ] Repeat until clean (max 10 iterations — if still failing, STOP and ask the human)
- [ ] Only THEN move to next task or push

### Checkpoint 4: Before push
- [ ] All commits have passed through checkpoint 3
- [ ] No checkpoint was skipped

## Commit protocol

Commits are the atomic unit of work. Follow these rules:

- **Commit after each logical task** — one logical change per commit, not batched at the end
- **Commit before reviews** — `/simplify` and `/ai-review` input must be a committed state
- **Never amend** review/simplify fix commits into the original — each fix is its own commit
- **Preserve full history** — the git log must tell the story: what was built, what the review found, and why fixes were made
- **Fix commit messages** reference what triggered them (e.g., "fix simplify findings in SidecarParser" with bullet points)
- **Commit message format** — imperative mood, lowercase, no trailing period (see `git-and-workflow.md`)

## Definition of Done is a blocking gate

The DoD in CLAUDE.md is not a checklist to glance at — it is a gate. Code that hasn't passed ALL items is not done, not committable, and not pushable. If the user asks to push and DoD isn't met, say so. "The user asked me to push" is not a valid reason to skip DoD.

The review steps (items 10-11) are the most commonly skipped. They are also the most important — they catch bugs that the author is blind to. Skipping reviews to save time is borrowing against future debugging time at high interest.

## Interaction with user urgency

When the user sends short, urgent messages ("push it", "ship it", "just fix it"):
- The urgency is about the outcome, not about skipping process
- Complete the process efficiently, don't skip it
- If genuinely blocked by process, tell the user what's pending and why
