# Git Conventions & Workflow

## Commit messages

- Imperative mood, lowercase, no trailing period
- Examples:
  - GOOD: `add sidecar parser with frontmatter support`
  - GOOD: `fix thumbnail cache eviction on memory pressure`
  - BAD: `Added sidecar parser`, `Fix thumbnail cache eviction.`, `updates`
- One logical change per commit — do not bundle unrelated changes
- No force pushes to `main`

## Branch naming

- `feature/<slug>` — implementation branches tied to a plan
- `bug/<slug>` — bug fix branches
- `idea/<slug>` — exploratory branches, may be abandoned
- `docs/<slug>` — documentation-only branches
- Slugs are lowercase kebab-case: `feature/sidecar-parser`, `bug/thumbnail-cache-leak`

## Review workflow

**No task is complete without reviews. NEVER skip.**

Full protocol: `.claude/rules/agent-workflow.md` (STOP checkpoints, commit protocol, review loop).
Summary: commit → `/simplify` → fix → `/ai-review` → fix → repeat until clean (max 10 rounds).

## Plot workflow (git-native planning)

These conventions prepare for plot adoption after MVP:

- Plans are markdown files in `docs/plans/`, named with date prefix: `YYYY-MM-DD-<slug>.md`
- A plan merges to `main` BEFORE any implementation branch is created from it
- One plan can spawn multiple implementation branches
- Sprint tracking files go in `docs/sprints/`
- Plans describe WHAT and WHY; implementation branches contain the HOW (code)

## .gitignore

The following must always be in `.gitignore`:
```
.build/
DerivedData/
xcuserdata/
.swiftpm/
*.xcodeproj/xcuserdata/
*.xcworkspace/xcuserdata/
```
