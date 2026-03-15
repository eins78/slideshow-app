# Build fix and guardrails

**Date:** 2026-03-15
**Scope:** Fix Xcode "Could not attach" debugger issue, fix Sendable warning, restore build guardrails

## Problem

App built successfully but Xcode couldn't run it — "Could not attach to Slideshow, LLDB provided no error string." Also had a persistent concurrency warning on `DocumentFilePresenter`.

## Root Causes

1. **Debugger attachment failure:** Stale DerivedData. Fixed by deleting DerivedData + regenerating xcodeproj via xcodegen.

2. **Sendable warning:** `DocumentFilePresenter` captured `self` (non-Sendable) in a `@Sendable` closure for debounce logic using `DispatchWorkItem`. Fixed by making the class `Sendable` with `OSAllocatedUnfairLock`-protected state and a generation-counter debounce pattern.

3. **Missing `SWIFT_TREAT_WARNINGS_AS_ERRORS`:** This setting was added in commit `bf0d0b8` on `worktree-ios` branch but never merged to main. Cherry-picked the guardrails commit (verify script, actor I/O rule, image a11y rules) to main.

## Key Decisions

- **Generation counter over DispatchWorkItem:** `DispatchWorkItem` is not `Sendable` and `Mutex` is `~Copyable` (can't be captured in closures). `OSAllocatedUnfairLock<UInt64>` generation counter is the simplest Sendable-safe debounce.
- **Cherry-pick vs merge:** The `worktree-ios` branch has diverged significantly. Cherry-picked only the build guardrails commit rather than merging the full branch.

## Lesson Learned

Cross-cutting changes (build settings, rules, scripts) should go to main first, then feature branches rebase on top. The `SWIFT_TREAT_WARNINGS_AS_ERRORS` setting was lost because it lived only on an unmerged feature branch.

## Commits

- `b3b1818` — fix DocumentFilePresenter sendability and enable warnings-as-errors
- `1713737` — cherry-pick build guardrails from worktree-ios branch
