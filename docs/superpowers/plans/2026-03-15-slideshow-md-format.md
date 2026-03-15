# slideshow.md Format Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

> **DoD per task:** After each task commit, run `/simplify` then `/ai-review`. Fix findings in separate commits. Repeat `/ai-review` until clean (max 10 iterations). See CLAUDE.md "Definition of Done" and "Git History Rules".

**Goal:** Replace per-image sidecar files and `slideshow.yml` with a single `slideshow.md` markdown project file, using swift-markdown for AST-based parsing.

**Architecture:** New `SlideshowParser` reads markdown via swift-markdown AST, extracting headings (captions), images, blockquotes (source), paragraphs/lists/tables/code (notes), and opaque blobs (unrecognized content). `SlideshowWriter` serializes back to normalized markdown. Old sidecar/YAML infrastructure is deleted. The `Slide` model changes from 1:1 with an image to a document section with 0-N images.

**Tech Stack:** Swift 6, swift-markdown (AST parsing), Yams (frontmatter YAML), Swift Testing (`@Test`, `#expect`, `#require`)

**Spec:** `docs/superpowers/specs/2026-03-15-slideshow-md-format-design.md`

**Status:** Implementation complete. All 15 tasks done, all tests passing, Xcode build clean.

---

_Plan contents truncated for brevity — see git history for full original plan._
_The key change from the original: each task now includes DoD steps (simplify + ai-review) after commit._
