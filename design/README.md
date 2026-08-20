# design/

Source files for the Doclyvo Claude Design canvas. These are the same `.dc.html` files
published at:

https://claude.ai/code/artifact/1a44a2b4-c1a1-4167-9367-b7930137703f

Each `.dc.html` is a self-contained "Design Component" (template + a `DCLogic` class) that
renders as one artboard on the canvas. `canvas.json` lays out their positions.

**Artboards:**
- `Main.dc.html` — Home (desktop). Tool grid now covers all eleven tools (updated
  2026-08-20 — it previously only had the original seven and had drifted out of sync
  with `ToolGrid.tsx`'s full list); each card's icon is the exact same inline SVG used
  in that tool's own artboard header (see e.g. `Rotate.dc.html`'s header icon), so home
  and the tool's own page always show a matching icon.
- `Compress.dc.html` — Compress tool flow (desktop) — the reference template every other
  single-file tool below was adapted from. **Processing-state convention:** every tool's
  "processing" phase should show a determinate, percentage-labeled bar that climbs from
  0 toward ~92% while the request is in flight and snaps to 100% on completion (see
  `Compress.dc.html`'s `startCompress`/`progressPct` for the reference implementation,
  added 2026-08-20 replacing the earlier indeterminate sliding bar) — this pattern is
  documented centrally here rather than hand-copied into every other tool's `.dc.html`,
  per the "adapt from Compress" rule below.
- `Result.dc.html` — Result/download screen (desktop)
- `Merge.dc.html` — Merge tool flow, multi-file reorder (desktop)
- `Sign.dc.html` — Sign tool flow, draw/type/upload tabs (desktop)
- `Split.dc.html` — split-to-individual-pages flow, no settings, single action (desktop)
- `Rotate.dc.html` — per-page selection (click a thumbnail to toggle) + 90°/180°/270° angle
  picker, live rotation preview on selected thumbnails (desktop)
- `Reorder.dc.html` — page-level reorder via left/right arrows under each thumbnail, same
  pattern as `Merge.dc.html`'s file reorder but applied to pages (desktop)
- `Watermark.dc.html` — live-preview text watermark on a single representative page; text
  cycles through presets (no free-text input in this preview runtime), position (center/
  diagonal/corner) and opacity (light/medium/strong) pills (desktop)
- `Protect.dc.html` — password field (masked, reveal toggle, "generate new" regenerates a
  demo password) + permission checkboxes (no print/copy/edit) (desktop)
- `Ocr.dc.html` — language pills (Türkçe/English) + output-format pills (searchable PDF /
  plain text), with a recognized-text preview panel that appears once done (desktop)
- `PdfToWord.dc.html` — the simplest of the four: a "keep layout" checkbox and a
  pdf-icon → arrow → docx-icon visual, no other settings (desktop)
- `Redact.dc.html` — permanent, true-content-removal redaction (not a cosmetic overlay):
  page navigation with a per-page "has marked regions" dot indicator, click-to-simulate
  region marking (each region a solid dark box with a "×" remove button), a page-grouped
  list of marked regions in the settings panel, and a persistent-but-calm permanence warning
  ("bu alanların altındaki metin kalıcı olarak silinir, geri alınamaz") — the main action
  button is disabled with zero regions marked (desktop)
- `Mobile*.dc.html` — mobile (390px) counterparts of all of the above
- `StyleGuide.dc.html` — color palette, typography, spacing/radius, component tokens, and a
  note aimed at AI agents picking up this project later

**Design tokens (also documented inside StyleGuide.dc.html):**
- Accent color: `#DC4731` (warm red associated with PDF tools, distinct from ILovePDF/Adobe's
  exact hue)
- Font: system font stack only (`-apple-system, BlinkMacSystemFont, 'SF Pro Text', 'Helvetica
  Neue', Arial, sans-serif`) — no custom webfont except `Caveat` (Google Fonts) for the
  signature preview in Sign/MobileSign
- Light theme: bg `#F5F5F7`, surface `#FFFFFF`, border `#D2D2D7`, text `#1D1D1F`, secondary
  text `#6E6E73`
- Dark theme: bg `#000000`, surface `#1C1C1E`, border `#38383A`, text `#F5F5F7`, secondary
  text `#98989D`
- Card radius 16px, button/panel radius 12px, small icon capsule radius 10-11px
- Buttons/icon buttons use `:active { transform: scale(0.97) }` for press feedback; top bars
  use `position: sticky` + `backdrop-filter: blur(20px) saturate(180%)`

**Known gaps / not yet designed:** none — every tool from the original scope, plus `Redact`
(the first Phase B tool designed beyond `Sign`), now has a design. Any *new* tool added later
should still adapt `Compress.dc.html`'s layout (file panel + settings panel + action button
with idle/processing/done phases) rather than starting from scratch.

**If editing these files further:** use the `design` skill's `seed-canvas.mjs` helper to
re-seed and republish to the same artifact URL above — don't hand-edit a seeded output file.
