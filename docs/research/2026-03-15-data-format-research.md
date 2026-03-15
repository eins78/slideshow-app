# Data format research: single project file for image-focused slideshows

> Research conducted 2026-03-15. Context: replacing per-image `.md` sidecar files with a single human-readable project file that lists images with optional captions and presenter notes.

## 1. Existing image slideshow/presentation formats

### Lightroom Classic slideshows
- **Format**: Proprietary internal database; exports to MP4 video, PDF, or JPEG sequences
- **Image references**: Library catalog references (not file paths)
- **Metadata**: Titles, captions stored in IPTC/XMP metadata embedded in or alongside images
- **Ordering**: Manual drag-reorder within the Slideshow module
- **Human-editable**: No — locked inside Lightroom's catalog
- **Takeaway**: Export-only; no editable project file. The slideshow IS the catalog view.

### Deckset (macOS)
- **Format**: Single `.md` file
- **Slide separator**: `---` on its own line (blank lines above/below)
- **Image references**: Standard markdown `![](image.jpg)` or `![](http://url/image.jpg)`; drag-to-app copies syntax to clipboard
- **Image modifiers**: Alt-text keywords: `![fit](img.jpg)`, `![left](img.jpg)`, `![right](img.jpg)`, `![inline](img.jpg)`, `![filtered](img.jpg)`, `![original](img.jpg)`, `![x%](img.jpg)`
- **Background images**: Any `![](img.jpg)` on a slide with text becomes the background automatically
- **Presenter notes**: Lines prefixed with `^` become notes (not shown on slides)
- **Configuration**: Inline directives: `footer: text`, `slidenumbers: true`, `presenter-notes: text-scale(2)`
- **Captions**: No native caption field; text on the slide serves as captions
- **Human-editable**: Excellent — it's just markdown
- **Parser complexity**: Low — line-by-line, split on `---`
- **Takeaway**: The closest prior art to what we want. Simple, elegant, image-forward. The `^` notes convention is clever — minimal syntax overhead.

### Marp (Markdown Presentation Ecosystem)
- **Format**: Single `.md` file with `marp: true` in frontmatter
- **Slide separator**: `---`
- **Image references**: `![alt text](image.jpg)` with extended syntax for sizing in alt text: `![w:900](img.jpg)`, `![bg](img.jpg)` for backgrounds
- **Per-slide directives**: HTML comments `<!-- backgroundColor: aqua -->` apply to current + subsequent slides; `<!-- _backgroundColor: aqua -->` (underscore prefix) applies to current slide only
- **Global config**: YAML frontmatter at top: `theme`, `paginate`, `header`, `footer`, `backgroundColor`, `backgroundImage`
- **Speaker notes**: Not natively in Marpit core; added via plugins
- **Human-editable**: Good — standard markdown with comment-based directives
- **Parser complexity**: Medium — CommonMark + custom directive parsing in HTML comments
- **Takeaway**: The scoped vs. inherited directive system (`_` prefix = this slide only) is interesting. HTML comment directives are clever but invisible in plain text.

### Slidev
- **Format**: Single `slides.md` file
- **Slide separator**: `---`
- **Per-slide frontmatter**: YAML block between `---` delimiters at the start of each slide — the separator doubles as the frontmatter opener
- **Global headmatter**: First YAML block configures the entire deck
- **Image references**: Standard markdown `![](img.jpg)` + `background: /path.png` in frontmatter
- **Speaker notes**: HTML comment blocks `<!-- notes here -->` at end of each slide
- **Ordering**: Sequential in the markdown file
- **Human-editable**: Good but YAML-heavy — each slide can have its own frontmatter block
- **Parser complexity**: Medium-high — must parse interleaved YAML blocks between content
- **Takeaway**: The "separator doubles as frontmatter opener" pattern is elegant. Per-slide YAML frontmatter is the most structured approach of any tool studied. But it's designed for code-heavy tech talks, not image portfolios.

### reveal.js / remark.js
- **reveal.js**: HTML-native with optional markdown plugin. Slide separator `---`, vertical slides `----`. Background images via HTML comments: `<!-- .slide: data-background="./image.png" -->`. Speaker notes in `<aside class="notes">`.
- **remark.js**: Pure markdown. Separator `---`, incremental slides `--`. Speaker notes after `???` marker. CSS-like class syntax `.center[content]`.
- **Both**: Text-presentation focused, not image-portfolio focused
- **Takeaway**: remark.js `???` for notes is very clean — no escaping needed, just a marker line.

### HedgeDoc/HackMD slide mode
- **Format**: Markdown document with `type: slide` in YAML header
- **Slide separator**: `---` (horizontal), `----` (vertical/nested)
- **Configuration**: YAML header with `slideOptions:` block (theme, transition)
- **Speaker notes**: Supported via reveal.js under the hood
- **Powered by**: reveal.js internally
- **Human-editable**: Yes — collaborative real-time markdown editing IS the product
- **Takeaway**: Proves the `---` separator is universal. The nested `----` for sub-slides is interesting but not relevant for image slideshows.

### iA Presenter
- **Format**: `.iapresenter` file = ZIP containing markdown + embedded media
- **Slide separator**: `---` (horizontal rule) OR 3 blank lines OR heading boundaries (`#`, `##`)
- **Image references**: Content block syntax: `/file.jpg "This is your caption"` (path + quoted caption)
- **Image metadata**: Size control (cover/contain), positioning — only with content block syntax, not markdown `![]()` syntax
- **Speaker notes**: ALL unindented text is speaker-only by default; TAB-indented text appears on slides
- **Media**: Images must be added to Media Manager (for file access permissions), then stored inside the ZIP
- **Human-editable**: The markdown inside is editable, but the ZIP wrapper requires extraction
- **Parser complexity**: Medium — custom content block syntax + tab-based visibility
- **Takeaway**: The "default invisible, tab for visible" inversion is bold — everything is a note unless you explicitly promote it to the slide. The `/file.jpg "caption"` content block syntax is very clean for image+caption. The ZIP bundle approach solves portability but sacrifices "just a folder."

### Obsidian slides (Advanced Slides / Slides Extended)
- **Format**: Standard Obsidian `.md` file
- **Slide separator**: `---`
- **Image references**: Obsidian wiki-links `![[image.jpg]]` or standard markdown
- **Built on**: reveal.js
- **Human-editable**: Yes — it's your Obsidian vault
- **Takeaway**: Demonstrates that the `---` separator convention works even inside a note-taking app's format.

### Pandoc slide output
- **Slide separator**: Headings (`##`) or `---`
- **Speaker notes**: `::: notes` ... `:::` (fenced div syntax)
- **Image references**: Standard markdown
- **Takeaway**: The fenced div `:::` syntax is powerful for structured blocks but ugly for a photo-focused format.

## 2. Markdown-based presentation format conventions summary

| Tool | Separator | Notes syntax | Image syntax | Per-slide config |
|------|-----------|-------------|--------------|------------------|
| Deckset | `---` | `^ note text` | `![fit](img.jpg)` | Inline directives |
| Marp | `---` | Plugin-dependent | `![bg w:900](img.jpg)` | `<!-- directive -->` |
| Slidev | `---` | `<!-- comment -->` | `![](img.jpg)` + frontmatter | YAML frontmatter block |
| reveal.js | `---` / `----` | `<aside class="notes">` | HTML/markdown | HTML data attributes |
| remark.js | `---` | `???` | markdown | YAML-like properties |
| HedgeDoc | `---` / `----` | reveal.js style | markdown | YAML header |
| iA Presenter | `---` / 3 blanks / headings | Unindented text | `/file.jpg "caption"` | Tab indentation |
| Pandoc | `##` headings / `---` | `::: notes` | markdown | Fenced div attributes |

**Universal convention**: `---` is THE slide separator. Every single tool uses it.

## 3. Photo essay / portfolio formats

### IPTC Photo Metadata Standard
- **Standard**: ISO standard for photo metadata (title, caption, keywords, copyright, contact)
- **Storage**: Embedded in image files (EXIF/XMP) or in XMP sidecar files
- **Key fields**: Title, Description/Caption (who/what/where/when/why), Headline (brief synopsis), Keywords, Copyright
- **Distinction**: Title = short reference; Description = full caption; Headline = summary
- **Human-editable**: XMP sidecars are XML — technically editable but not pleasant
- **Takeaway**: IPTC defines the vocabulary (title, caption, source/copyright, description) that any photo metadata format should respect. Our `caption` and `source` fields align with IPTC Description and Copyright Notice.

### XMP Sidecar files
- **Format**: XML-based, ISO 16684
- **Naming**: `image.jpg` → `image.xmp` (same name, different extension)
- **Scope**: Per-image, not per-collection
- **Content**: Non-destructive edit instructions + metadata (keywords, captions, ratings)
- **Used by**: Lightroom, Capture One, darktable, RawTherapee
- **Human-editable**: Technically yes (XML), practically no
- **Takeaway**: The photography world's standard sidecar format. Per-image, XML-based, not human-friendly. We're right to use something simpler.

### Adobe Portfolio
- **Format**: Web-based, no editable project file
- **Organization**: Galleries → Pages → Albums with Photo Grid modules
- **Metadata**: IPTC metadata preserved but not displayed; no editable caption file
- **Takeaway**: SaaS product, no portable file format. Images organized by collections in a UI, not by files.

### Blurb BookWright
- **Format**: Proprietary `.blurb` / `.bookwright` project file
- **Export**: PDF (print-ready), EPUB (fixed-layout or reflowable)
- **Captions**: Supported via text frames alongside images
- **Human-editable**: No — binary/proprietary project format
- **Takeaway**: Traditional page-layout approach. Not relevant to plain-text formats.

### Static gallery generators

**Sigal**:
- Per-album metadata: `index.md` with key-value header (Title, Thumbnail, Author, Sort) + markdown description
- Per-image metadata: `<imagename>.md` sidecar files with same key-value format
- Also reads EXIF/IPTC from images directly
- Ordering: Alphabetical, or `Sort:` field in album metadata

**Nikola** (static site generator):
- **Single file for gallery metadata**: `metadata.yml` in gallery directory
- **Format**: YAML list of entries with `name`, `caption`, `order` fields
- **Only `name` is required** — images without entries just get filename as caption
- **Ordering**: Explicit `order` field, or alphabetical fallback
- **Human-editable**: Excellent — simple YAML
- **Takeaway**: THIS IS THE CLOSEST PRIOR ART for a single-file-per-folder approach. Simple, optional, graceful fallback.

**Expose** (photo essay generator):
- Folder of images, nested folders for organization
- Per-image metadata: text file with same filename as image (e.g., `sunset.jpg` → `sunset.txt`)
- YAML inside text files for positioning/styling metadata
- Ordering: Alphabetical; numerical prefixes for custom order (stripped from output)
- Underscore prefix to exclude files
- Gallery config: `_config.sh` in project root
- **Takeaway**: Similar sidecar-per-image pattern, but the `_config.sh` is interesting — a single project config alongside per-image metadata.

**Photish**:
- Convention-based: folder structure = gallery structure
- Per-image metadata: YAML file with same name as photo
- **Takeaway**: Another sidecar-per-image tool.

**Eleventy Photo Gallery**:
- Global data file with array of image metadata objects (`title`, `date`, `credit`, `src`, `alt`, `imgDir`)
- **Takeaway**: Single data file approach, but JSON-based, developer-oriented.

## 4. Plain-text structured formats (non-presentation)

### Fountain (screenwriting)
- **Design philosophy**: "Make it look like a screenplay" — raw text reads naturally
- **Title page**: Key-value pairs at top of file (Title, Author, Draft date, Contact) — unknown keys safely ignored
- **Scene headings**: Lines starting with INT/EXT (convention, not syntax)
- **Sections**: `#` headings for organization (not shown in output — purely structural)
- **Synopses**: `= Synopsis text` (not shown in output — notes for the writer)
- **Notes**: `[[double brackets]]` for inline annotations
- **Boneyard**: `/* commented out */` for removed sections
- **Force markers**: `.` (scene heading), `@` (character), `!` (action), `>` (transition), `~` (lyrics)
- **Forward compatibility**: Unknown title page keys ignored; malformed text defaults to Action rather than being discarded — "Better to show the writer what they wrote—in the wrong format—than skip over malformed text"
- **Human-editable**: Exceptional — the format IS the visual
- **Parser complexity**: Medium — line-by-line with context awareness
- **Takeaway**: EXTREMELY relevant design philosophy. The idea that unknown content is preserved rather than discarded, and that the raw file should be readable on its own, is exactly our goal. Fountain proves you can have a highly structured format that reads naturally.

### Org-mode
- **Property drawers**: Per-heading structured metadata in `:PROPERTIES:` ... `:END:` blocks
- **Example**:
  ```
  * Goldberg Variations
  :PROPERTIES:
  :Title: Goldberg Variations
  :Composer: J.S. Bach
  :END:
  ```
- **Inheritance**: Properties can inherit down the heading tree
- **Human-editable**: Good if you know Org-mode; alien otherwise
- **Takeaway**: Property drawers solve the "per-section metadata" problem elegantly. The `:KEY: value` syntax within a delimited block is clean. But the Emacs-centric ecosystem limits adoption.

### TaskPaper
- **Format**: Indented plain text with tags
- **Projects**: Lines ending with `:`
- **Tasks**: Lines starting with `- `
- **Tags**: `@tag(value)` inline
- **Notes**: Any line that's not a project or task
- **Human-editable**: Excellent — reads like a natural outline
- **Takeaway**: The tag-with-value `@tag(value)` pattern is interesting for inline metadata without frontmatter blocks.

### todo.txt
- **Format**: One task per line, structured by convention
- **Priority**: `(A)` prefix
- **Dates**: `YYYY-MM-DD` prefix
- **Projects**: `+project` inline tag
- **Contexts**: `@context` inline tag
- **Human-editable**: Excellent — one line per item, all metadata inline
- **Takeaway**: Proves that per-line metadata can work without YAML/frontmatter. But too terse for captions/notes.

## 5. The "folder of images" convention

### Hugo page bundles
- **Leaf bundle**: Directory with `index.md` + resources (images, PDFs, etc.)
- **Branch bundle**: Directory with `_index.md` + sub-bundles
- **Resource metadata**: Image processing configured in frontmatter; resources accessed by filename
- **Naming convention**: Files in the same directory as `index.md` are automatically "bundled"
- **Takeaway**: Hugo proves that a folder with an index file + co-located resources is a natural, widely-understood pattern. Our `slideshow.yml` (or equivalent) serves the same role as Hugo's `index.md`.

### Jekyll
- **Convention**: Posts in `_posts/`, images in `assets/images/`
- **Frontmatter**: YAML at top of each post, references images by path
- **Per-post folders**: Some setups put `index.md` + images in the same folder
- **Takeaway**: Jekyll normalized YAML frontmatter in markdown. The `_posts/` naming convention (date prefix + slug) is similar to our `003--` prefix convention.

### Static gallery generators (summary)
- **Common pattern**: Folder of images + optional metadata file(s)
- **Two approaches**: (a) sidecar per image (Sigal, Expose, Photish, XMP), or (b) single metadata file per folder (Nikola `metadata.yml`)
- **Ordering**: Almost universally alphabetical with numeric prefix override
- **Takeaway**: The field is split between per-image sidecars and single-file-per-folder. We're proposing to move from (a) to (b), which has precedent in Nikola.

## 6. Markdown frontmatter limitations

### The "frontmatter only at top" problem
Standard markdown frontmatter (YAML between `---` delimiters) can only appear at the very beginning of a file. There is no standard way to add per-section metadata in markdown.

### Solutions explored by various tools

| Approach | Tool | Syntax | Pros | Cons |
|----------|------|--------|------|------|
| Repeated frontmatter | Slidev | `---` doubles as separator + frontmatter opener | Elegant reuse | Only works when slides are clearly separated |
| HTML comments | Marp | `<!-- key: value -->` | Invisible in rendered output | Invisible in plain text too |
| Fenced divs | Pandoc/Quarto | `::: {.class key=val}` ... `:::` | Powerful, nestable | Ugly, complex |
| Generic directives | CommonMark proposal | `:directive[content]{attrs}` | Standardizable | Still in discussion, not finalized |
| Property drawers | Org-mode | `:PROPERTIES:` ... `:END:` | Clean, per-heading | Emacs-specific |
| Inline tags | TaskPaper | `@tag(value)` | Minimal syntax | Not markdown-compatible |
| Content blocks | iA Presenter | `/file.jpg "caption"` | Very clean for images | Custom syntax, not markdown |
| Markdoc tags | Stripe Markdoc | `{% tag %}` ... `{% /tag %}` | Type-safe, validated | Requires custom parser, not plain markdown |
| Tab indentation | iA Presenter | Tab = visible on slide | Invisible metadata boundary | Fragile (tabs vs spaces) |
| Caret prefix | Deckset | `^ note text` | Simple, per-line | Only for notes, not arbitrary metadata |

### Most relevant for our use case
For an image slideshow single-file format, the Slidev approach (separator doubles as frontmatter opener) and the iA Presenter approach (content block syntax for images) are most relevant. We don't need the full power of fenced divs or Markdoc.

## 7. Prior art for "forgiving parsers"

### Postel's Law (Robustness Principle)
"Be conservative in what you do, be liberal in what you accept from others."
- Originally for TCP; widely applied to file format parsing
- Modern criticism: tolerance of malformed input can lead to ambiguity and security issues
- **Application to our format**: Accept unknown fields, preserve them on round-trip, never refuse to open a valid folder

### Fountain's approach
- Unknown title page keys: silently preserved
- Malformed text: defaults to "Action" (the catch-all element type) — "Better to show the writer what they wrote—in the wrong format—than skip over malformed text"
- **Parsing priority**: Specific patterns match first; anything unrecognized becomes plain content
- **Takeaway**: Exactly our philosophy. Unknown = preserve, malformed = degrade gracefully.

### Protobuf unknown fields
- Binary wire format preserves unknown fields through serialization round-trips
- JSON format does NOT preserve unknown fields (limitation)
- **Takeaway**: For forward compatibility, the format must have a catch-all for unrecognized content. YAML naturally does this — unknown keys are parsed and can be re-serialized.

### Tolerant Reader Pattern
- Consumer of data is built to handle added fields, minor structure changes gracefully
- Unknown enum values preserved as strings, not rejected
- **Application**: Our parser should read what it understands, preserve everything else as raw data, and never fail on unknown content.

### HTML parsing
- HTML5 spec defines error recovery for every possible malformed input
- Browser parsers are the ultimate "forgiving parsers"
- **Takeaway**: Overkill for our needs, but the principle of defined recovery behavior (not undefined behavior) is important.

## 8. Design implications for our format

### Universal conventions to adopt
1. **`---` as slide/image separator** — every presentation tool uses it
2. **YAML for metadata** — widely understood, human-editable, preserves unknown keys
3. **Frontmatter at top for project-level config** — Hugo, Jekyll, Marp, Slidev all do this
4. **Filename references for images** — not paths, not URLs; images are in the same folder
5. **Alphabetical/numeric-prefix ordering as default** — override with explicit order in the file

### Key design questions

**Q: How to associate captions/notes with images?**
Options explored:
- (a) **Nikola-style YAML list**: `- name: img.jpg\n  caption: text\n  notes: text`
- (b) **Slidev-style per-section frontmatter**: Each image gets a YAML block between `---` separators
- (c) **Deckset-style markdown**: Image reference + text on the "slide" is the caption, `^` prefix for notes
- (d) **iA Presenter-style content blocks**: `/img.jpg "caption"` with notes below
- (e) **Fountain-inspired**: Filenames as "scene headings", text below as captions/notes

**Q: Pure YAML vs. markdown-with-YAML?**
- Pure YAML: Easy to parse, but captions with markdown formatting become awkward (escaping)
- Markdown with YAML frontmatter: Natural for text content, but parsing is more complex
- Hybrid: YAML for metadata, free-text blocks for notes/captions

**Q: How to handle images not mentioned in the file?**
Following Nikola's pattern: images in the folder but not in the project file get their own slides with no caption, appended in filename order. The project file is optional progressive enhancement.

### Formats to study further
1. **Nikola's `metadata.yml`** — single-file YAML for image collections
2. **Deckset's markdown** — the closest "image presentation as markdown" format
3. **iA Presenter's content blocks** — clean image+caption syntax
4. **Fountain's philosophy** — forgiving parsing, raw readability, graceful degradation

---

## Sources

- [Deckset Help - Getting Started](https://docs.deckset.com/English.lproj/getting-started.html)
- [Deckset Help - Background Images](https://docs.deckset.com/English.lproj/Media/01-background-images.html)
- [Deckset Help - Presenter Notes](https://docs.deckset.com/English.lproj/Presenting/presenter-notes.html)
- [Deckset Help - Configuration Commands](https://docs.deckset.com/English.lproj/Customization/01-configuration-commands.html)
- [Marp: Markdown Presentation Ecosystem](https://marp.app/)
- [Marp Directives](https://marpit.marp.app/directives)
- [Slidev Syntax Guide](https://sli.dev/guide/syntax)
- [Slidev Block Frontmatter](https://sli.dev/features/block-frontmatter)
- [reveal.js Markdown](https://revealjs.com/markdown/)
- [remark.js](https://remarkjs.com/)
- [HedgeDoc Slide Options](https://docs.hedgedoc.org/references/slide-options/)
- [iA Presenter Markdown Guide](https://ia.net/presenter/support/basics/markdown)
- [iA Presenter Images](https://ia.net/presenter/support/visuals/images)
- [iA Presenter Improved Image Handling](https://ia.net/topics/improved-image-handling-ia-presenter-1-2)
- [Obsidian Slides Extended](https://github.com/ebullient/obsidian-slides-extended)
- [Pandoc Speaker Notes](https://pandoc.org/demo/example33/10.5-speaker-notes.html)
- [Pandoc Divs and Spans](https://pandoc.org/demo/example33/8.18-divs-and-spans.html)
- [Hugo Page Bundles](https://gohugo.io/content-management/page-bundles/)
- [Hugo Front Matter](https://gohugo.io/content-management/front-matter/)
- [Jekyll Front Matter](https://jekyllrb.com/docs/front-matter/)
- [Nikola Gallery Metadata](https://github.com/getnikola/nikola/issues/3017)
- [Sigal Album Information](https://sigal.readthedocs.io/en/stable/album_information.html)
- [Expose Static Photo Essay Generator](https://github.com/Jack000/Expose)
- [Fountain Syntax](https://fountain.io/syntax/)
- [Org-mode Property Syntax](https://orgmode.org/manual/Property-Syntax.html)
- [Org-mode Drawers](https://orgmode.org/manual/Drawers.html)
- [IPTC Photo Metadata Standard](https://www.iptc.org/std/photometadata/specification/IPTC-PhotoMetadata)
- [IPTC Photo Metadata User Guide](https://www.iptc.org/std/photometadata/documentation/userguide/)
- [XMP Sidecar Files in DAM](https://www.orangelogic.com/sidecar-in-digital-asset-management)
- [ExifTool Metadata Sidecar Files](https://exiftool.org/metafiles.html)
- [Markdoc by Stripe](https://markdoc.dev/docs/overview)
- [CommonMark Generic Directives Proposal](https://talk.commonmark.org/t/generic-directives-plugins-syntax/444)
- [Tolerant Reader Pattern](https://java-design-patterns.com/patterns/tolerant-reader/)
- [Postel's Law / Robustness Principle](https://en.wikipedia.org/wiki/Robustness_principle)
- [Robustness Principle Reconsidered (ACM)](https://cacm.acm.org/practice/the-robustness-principle-reconsidered/)
- [Protobuf Forward Compatibility](https://earthly.dev/blog/backward-and-forward-compatibility/)
- [MDX - Markdown for the Component Era](https://mdxjs.com/)
- [todo.txt Format](https://github.com/todotxt/todo.txt)
