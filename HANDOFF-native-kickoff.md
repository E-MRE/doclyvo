# Doclyvo — Handoff for the `apps/native` (Flutter) kickoff session

This file gives a new Claude Code session enough context to start work on
`apps/native` without re-deriving decisions already made. Read `ROADMAP.md` at
the repo root right after this file — it's the canonical decision log and has
more detail than what's repeated here. This file is the "what matters for
native, specifically" companion to it.

Note on language: this handoff is written in English, but the project's own
convention (established across prior sessions) is to hold the actual working
conversation in Turkish — code, identifiers, and commit messages stay English,
explanations to the user are in Turkish. Keep following that once you start
talking to the user, even though this document itself is English.

## What Doclyvo is

An ILovePDF/Smallpdf-style PDF toolkit (merge/split/compress/sign/redact/etc.),
monorepo with three apps that don't share code (different languages/package
managers) — they only share the design language and, eventually, the API
contract:

- `apps/web` — Next.js 15 + TypeScript + Tailwind CSS v4. Fully built, all
  eleven tools live, deployed.
- `apps/api` — FastAPI (Python 3.12) + pikepdf/PyMuPDF/LibreOffice/Tesseract.
  Fully built for all eleven tools, deployed. This is the backend `apps/native`
  will call for anything heavy.
- `apps/native` — Flutter, **not started**. `apps/native/README.md` is the only
  file that exists; `flutter create` has not been run. This is deliberate —
  native was always meant to be scaffolded last, once the design and the API
  contract it depends on were stable.

Both `apps/web` and `apps/api` are live on Render's free tier:
`https://doclyvo.onrender.com` (web), `https://doclyvo-api.onrender.com` (api).
See `docs/deployment.md` for the free-tier caveats (512MB RAM, 15-min
cold-start spin-down) that will also apply to any HTTP calls `apps/native`
makes to the same API.

## What's already built (read `ROADMAP.md` for the full history)

- **Phase A** — all nine original tools (merge, split, compress, rotate,
  reorder, watermark, protect, OCR, PDF-to-Word) implemented end-to-end on both
  `apps/web` and `apps/api`.
- **Phase B** — two more tools shipped beyond the original nine:
  - **Sign** — self-sign only (draw/type/upload → place → download); no
    signer-invite/multi-party flow. Introduced `apps/api`'s first database
    integration (SQLAlchemy 2.0 async + Alembic + Postgres) and
    `app/core/auth.py::get_optional_user_id` — a real `HTTPBearer` seam that
    resolves to `None` on every request today because **no login system
    exists yet**. When authenticated (never, in production, right now), it
    hash-seals output with SHA-256 and writes an append-only
    `AuditLogEntry`.
  - **Redact** — true content removal via PyMuPDF (`add_redact_annot` +
    `apply_redactions`), not a cosmetic black-box overlay. The one tool that
    doesn't use the pikepdf/reportlab overlay technique the other ten share.
- **Job history schema** — `app/shared/models.py`'s `Job` model + migration
  exist, but nothing writes to it yet (no accounts = no one to show history
  to). `apps/api/README.md`'s "Job history schema" section has the exact
  wiring steps for whenever login ships — read that before touching it rather
  than re-deriving the plan.
- **This session (2026-08-20/21)** — a UI/UX pass on `apps/web` fixing drift
  between the design canvas and the live code: real file upload + scroll-to-
  tools on the home page (was previously a static link that always routed to
  Compress regardless of intent), real per-tool SVG icons and a featured
  Compress card, a working dark/light header toggle (theme was previously
  OS-preference-only, no user override), a real back button on tool pages, a
  shared fake-percentage progress bar and a richer result panel (checkmark,
  download, "do another tool" chips) across all eleven tools replacing plain
  text summaries, page-transition/progress/result-panel motion, and a
  character-count filename-truncation fallback (`truncateFilename()` in
  `apps/web/lib/utils.ts`) for the one spot (PDF-to-Word's icon visual) where
  CSS `truncate` had no bounding width to clip against. Commits: `e9bc6d9`,
  `f2ea848`, both pushed to `master`. None of this changes anything
  `apps/native` depends on directly, but the patterns (fake progress, result
  panel with cross-tool suggestions, pending-file handoff between screens) are
  worth being aware of if you want native to feel consistent with web.
- **Explicitly deferred, not blocking native**: a footer for `apps/web` (user
  asked to skip it for now, will define it as a separate future feature) and
  further decorative animation passes.

## Design system — what native should pull from

- Canvas (source of truth for every screen, desktop + mobile):
  `https://claude.ai/code/artifact/1a44a2b4-c1a1-4167-9367-b7930137703f`
- Source files: `design/*.dc.html` (one per screen/state) + `design/canvas.json`
  (layout) + `design/README.md` (full artboard list, tokens, conventions,
  "known gaps"). Read `design/README.md` first — it's short and current as of
  this session.
- **Important nuance for native**: the `Mobile*.dc.html` files are HTML/CSS
  mockups of the *web* app at a 390px viewport — they are the UX/flow
  reference (what each screen shows, in what order, what states exist), not
  literal markup to port. Translate the intent into Flutter widgets using the
  tokens below, following `.claude/reference/flutter/skills/design_system.md`
  for how tokens are supposed to be consumed in Dart (theme extension /
  constants, never hardcoded hex values in widgets).
- Design tokens (`design/README.md` has the exact values; don't guess):
  accent `#DC4731`; light bg `#F5F5F7` / surface `#FFFFFF` / border `#D2D2D7`
  / text `#1D1D1F`; dark bg `#000000` / surface `#1C1C1E` / border `#38383A`
  / text `#F5F5F7`; card radius 16px, button/panel radius 12px; system font
  stack (no custom webfont except `Caveat` for the Sign screen's signature
  preview — irrelevant to native unless you replicate that exact visual).
- Motion conventions added this session (documented in `design/README.md`):
  page-transition fade+slide, a shimmer sweep on active progress bars, a
  checkmark-confirmation flash on download, all respecting reduced-motion —
  worth matching in spirit (Flutter has its own idiomatic ways to do this;
  don't try to port the literal CSS).
- Every tool screen has five states baked into its design: empty / idle /
  processing / done / error. Whatever native builds per tool should cover all
  five, not just the happy path — this bit the web build in earlier sessions
  (see "known past design mistakes" below) and is worth avoiding from the
  start in Flutter too.

## Known past mistakes (from `apps/web` — don't repeat them in `apps/native`)

Pattern-level lessons that generalize beyond web-specific code:
1. Icons must be real vector icons per element, never a placeholder glyph or
   emoji standing in for "add the real icon later." A `ToolGrid` component
   shipped with `●` for every single icon for a while — caught late.
2. Interactive elements need every state defined (disabled/hover/active/
   pressed) up front, not just the default look.
3. A shared constant duplicated across 2-3 places instead of defined once is
   a recurring smell (e.g. total-page-count literals) — extract early.
4. Sibling screens (a tool's desktop and mobile version, or — for native — a
   tool's Android/iOS/desktop rendering) drift out of sync silently on shared
   details like a header's back-button padding. Cross-check siblings when
   changing one.
5. When you build a feature "from a template" (Compress was the template for
   the other 8 simple single-file tools on web), a fix made in the template
   later doesn't automatically propagate — it has to be applied deliberately
   everywhere it should apply, or documented as the shared convention if
   hand-touching every file isn't worth it.

## What `apps/native` needs to decide/do (from `ROADMAP.md`'s open items)

- [ ] `flutter create` to actually scaffold the project — nothing exists yet
  beyond the README.
- [ ] Decide the split precisely: which operations run with native Dart
  packages (`apps/native/README.md` suggests `syncfusion_flutter_pdf` /
  `pdfrx` for merge/split/rotate/watermark-type simple ops) vs. which call
  `apps/api` (Office↔PDF conversion, OCR — anything needing LibreOffice/
  Tesseract).
- [ ] Decide whether desktop builds (Windows/macOS/Linux) should shell out to
  a local LibreOffice/Ghostscript binary instead of hitting the network API,
  since desktop apps aren't sandboxed like the browser — not decided yet,
  called out explicitly as open in both `ROADMAP.md` and
  `apps/native/README.md`.
- [ ] If/when calling `apps/api`: endpoints take `multipart/form-data`, return
  the processed file directly (`split` returns a `.zip`), and errors come back
  as a `DoclyvoError` JSON contract (`.claude/reference/api/` has the shape).
  Auth is optional today (`get_optional_user_id` resolves to `None` for every
  real request — there's no login system yet), so don't build against an auth
  flow that doesn't exist in production yet.
- [ ] Accounts / premium tier still doesn't exist anywhere in the stack. Don't
  assume native can log a user in — that's a cross-cutting piece of work not
  started on any platform.

## Flutter conventions — read before writing any code

`.claude/reference/flutter/` is the house style, written and installed before
`apps/native` was even scaffolded so the codebase starts compliant:

- `skills/` — architecture, project structure, state management (Cubit +
  `BaseCubit`), naming, DI, navigation, networking, error handling, models/
  mapping, performance, testing, design system, widget patterns, responsive
  rules, localization, `build_runner`, extensions/utils, and a `do_not_do.md`
  of anti-patterns to avoid outright.
- `patterns/` — decision heuristics: widget decomposition, folder decisions,
  feature-creation flow, shared-vs-local widget rules.
- `reviews/` — checklists (code review / architecture / performance) to
  self-check against before considering anything done.
- `prompts/` — task templates (feature creation, bugfix, refactor, code
  review) that already enforce "read the skills files first."
- The content was genericized from a real production app — placeholders like
  `<app>`, `<AppName>`, `<team>`, `<user>` need substituting for Doclyvo's own
  identifiers the first time they're touched.
- Known resolved nuance: there was a contradiction between two of these files
  about whether private widgets need their own `part` file; `developer_
  preferences.md` is the one that wins. Don't re-litigate this if it comes up.
- The `/mars-overview` skill (`mars-project-overview`) audits `apps/native`
  against this reference automatically once there's code to audit — good
  first thing to run after scaffolding produces a real Flutter tree.
- `mars-flutter-implement` / `mars-implement-ticket` are the skills meant for
  actually building screens/features against this convention set.

## Quick reference paths

- `ROADMAP.md` — the decision log; read it next.
- `design/README.md` — design tokens, artboard list, motion/filename
  conventions, "known gaps."
- `apps/api/README.md` — backend feature list, `DoclyvoError` contract, Job
  history schema section, deferred-work list.
- `docs/build-prompt-web-mvp.md` — the original reference prompt this whole
  project was scoped from.
- `docs/deployment.md` — hosting tradeoffs and free-tier caveats relevant to
  anything native calls over the network.
- `.claude/reference/flutter/` — house Flutter conventions (above).
- `apps/native/README.md` — the one file that exists in `apps/native` today.

## Working conventions to keep

- Commit messages in English; **no co-author trailer** — explicit, repeated
  user preference across every session so far, don't add it back by default.
- Design-first discipline: for anything with a visual/UX component, the
  `design/*.dc.html` sources (or, for native, the equivalent design decision)
  should be settled and documented before code, not after.
