# design/

Source files for the Doclyvo Claude Design canvas. These are the same `.dc.html` files
published at:

https://claude.ai/code/artifact/1a44a2b4-c1a1-4167-9367-b7930137703f

Each `.dc.html` is a self-contained "Design Component" (template + a `DCLogic` class) that
renders as one artboard on the canvas. `canvas.json` lays out their positions.

**Artboards:**
- `Main.dc.html` — Home (desktop)
- `Compress.dc.html` — Compress tool flow (desktop) — the reference template for other
  simple single-file tools (Split, Watermark, Protect, PDF to Word, etc.)
- `Result.dc.html` — Result/download screen (desktop)
- `Merge.dc.html` — Merge tool flow, multi-file reorder (desktop)
- `Sign.dc.html` — Sign tool flow, draw/type/upload tabs (desktop)
- `Mobile*.dc.html` — mobile (390px) counterparts of the above
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

**Known gaps / not yet designed:** Split, Watermark, Protect, OCR, PDF to Word — build these
by adapting `Compress.dc.html`'s layout (file panel + settings panel + action button with
idle/processing/done phases), not from scratch.

**If editing these files further:** use the `design` skill's `seed-canvas.mjs` helper to
re-seed and republish to the same artifact URL above — don't hand-edit a seeded output file.
