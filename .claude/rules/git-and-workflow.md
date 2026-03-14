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

**No task is complete without a clean Gemini review. NEVER skip reviews.**

1. Complete the task, ensure DoD items 1-9 pass
2. **Commit** the work (one logical change per commit)
3. Run `/simplify` to review changed code for reuse, quality, and efficiency
4. If simplify finds issues: **fix and commit** the fixes as a separate commit (never amend)
5. Run `/ai-review` to get a second-model review from Gemini
6. If issues found: **fix and commit** as a separate commit, then run `/ai-review` again
7. Repeat until the review comes back clean
8. Maximum 10 review iterations — if still failing after 10, STOP and ask the human for help
9. Only then move to the next task

**History preservation:** every commit before and after review must be preserved. Never amend fixes into the original commit — the git log must tell the full story of what was built, what was found, and why it was changed. Fix commit messages should reference what triggered them (e.g., "fix simplify findings in SidecarParser").

Work in PR-sized batches — each commit should be a self-contained, reviewable unit.

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
