# Doclyvo — Roadmap

All-in-one PDF toolkit to convert, merge, split, compress, edit, and manage documents online.

## Architecture decisions (Phase 0 — done)

- **Web:** Next.js 15 + TypeScript (frontend) talking to a **FastAPI** (Python 3.12) backend
  that uses **pikepdf** for core PDF ops and **LibreOffice headless** for Office↔PDF
  conversion, backed by **PostgreSQL**. This came from the reference prompt
  ("Use Next.js 15, TypeScript, Python 3.12, FastAPI, pikepdf, LibreOffice headless, and
  PostgreSQL; do not offer alternative stacks") and supersedes an earlier idea of a
  backend-free, WASM-only web client — that idea was dropped because Office conversion has no
  practical WASM equivalent yet.
- **Mobile + Desktop:** Flutter, one codebase for iOS/Android/Windows/macOS/Linux. Simple
  operations run with native Dart packages; heavy operations (Office conversion, OCR) call the
  same FastAPI backend. Desktop may additionally shell out to a local LibreOffice/Ghostscript
  binary later, since desktop apps aren't sandboxed like the browser.
- **Backend hosting:** start on a free/hobby-tier PaaS (Render, Railway, or Fly.io); revisit if
  traffic grows.
- **Auth model:** anonymous usage stays free with no account; an optional account exists for a
  premium/subscription tier.
- **Repo layout:** a monorepo with plain folder separation — `apps/web`, `apps/native`,
  `apps/api` — no Turborepo/Melos. The three apps don't share code (different languages/package
  managers); they only share the design language and, later, an API contract.

## Design (Phase 1 — mostly done)

- Design canvas (Claude Design):
  https://claude.ai/code/artifact/1a44a2b4-c1a1-4167-9367-b7930137703f
- Source files live in `design/` (see `design/README.md` for the full breakdown of tokens and
  artboards).
- Screens designed so far, desktop + mobile: Home, Compress, Result, Merge, Sign, Split,
  Rotate, Reorder.
- `Compress.dc.html` is the reference template for other simple single-file tools — reuse its
  layout (file panel + settings panel + action button with idle/processing/done phases) rather
  than designing each tool from scratch.
- A `StyleGuide.dc.html` artboard documents the color palette, typography, spacing/radius scale,
  and component tokens for anyone (human or agent) picking this project back up.

## Coding conventions (Phase 1.5 — done)

Each app has a written house-style reference under `.claude/reference/`, installed/authored
before any of the three apps were scaffolded, so they start compliant instead of being
retrofitted later:

- `.claude/reference/flutter/` — `apps/native` (feature-based Clean Architecture, Cubit +
  BaseCubit, design tokens instead of hardcoded values, private widgets each in their own
  `part` file — see `feedback-flutter-conventions-enforcement` memory for the resolved
  part-file rule).
- `.claude/reference/web/` — `apps/web` (Next.js App Router feature folders, Tailwind theme
  tokens mirroring the same accent/radius/font as `design/`, server-components-by-default,
  one API client).
- `.claude/reference/api/` — `apps/api` (feature-based routers/services, pikepdf/LibreOffice
  isolated in a service layer, per-request temp workspace with guaranteed cleanup, a shared
  `DoclyvoError` contract that `apps/web`'s error handling depends on).

`.claude/skills/mars-project-overview` (`/mars-overview`) audits `apps/native` against its
reference automatically; the web/api ones don't have an automated auditor yet — apply them
by reading, since no equivalent skill exists for those stacks.

## Phase A (done — 2026-08-19)

`apps/web` (Next.js 15 + Tailwind v4) and `apps/api` (Python 3.12 + FastAPI + pikepdf) are
scaffolded and working end-to-end:

- `apps/api`: merge, split, compress, rotate, reorder — each a thin router + a `service.py`
  doing the real pikepdf work, a per-request temp workspace cleaned up via `BackgroundTask`
  after the response is sent, and a `DoclyvoError` → JSON exception handler. No database yet —
  see `apps/api/README.md`'s "Deferred to a later phase" for why. 14 pytest tests pass.
- `apps/web`: Home, Compress, and Merge pages implementing `design/Main.dc.html`,
  `Compress.dc.html`, `Merge.dc.html` with real empty/idle/processing/done/error states wired
  to `apps/api` through server actions. Split/rotate/reorder have API support; their designs
  (`Split.dc.html`, `Rotate.dc.html`, `Reorder.dc.html` + `Mobile*` counterparts) were added
  2026-08-20, following the Compress/Merge template — building their `apps/web` pages is next
  (see Open work below). A Playwright end-to-end test drives the real Compress flow through
  both servers together (`npm run test:e2e`).
- Next session picking up Phase B: read `docs/build-prompt-web-mvp.md`'s "Deferred to a later
  phase" section for what's left (watermark/redact/OCR/Office-conversion/signatures/accounts,
  plus the PostgreSQL/job-history wiring Phase A intentionally skipped).

## Open / follow-up work

- [ ] Design the remaining tools when needed: Watermark, Protect, OCR, PDF to Word — adapt
      from `Compress.dc.html`, not from scratch.
- [ ] **Build the `apps/web` pages for Split, Rotate, and Reorder** — designs are done
      (`design/Split.dc.html`, `Rotate.dc.html`, `Reorder.dc.html` + mobile), API endpoints
      already exist; this is the next coding task, mirroring the Compress/Merge
      `features/<tool>/{actions.ts,components/,types.ts}` + `app/tools/<tool>/page.tsx`
      pattern. Rotate needs a page-thumbnail multi-select + angle picker; Reorder needs a
      page-thumbnail list with left/right move buttons (same interaction as Merge's file
      reorder, applied to pages).
- [x] Scaffold `apps/web` with `create-next-app` (TypeScript) — done, see Phase A above.
- [ ] Scaffold `apps/native` with `flutter create`.
- [x] Scaffold `apps/api` with FastAPI; wire up pikepdf — done, see Phase A above. LibreOffice
      headless still deferred to the Office-conversion phase.
- [ ] Phase B (deferred, not started): watermark, redact, OCR, Office-to-PDF conversion,
      signature-with-consent-and-hash + append-only audit log, accounts/premium tier.
- [ ] Design the PostgreSQL schema (job/history records first; user accounts later for the
      premium tier).
- [ ] Pick and configure the hosting provider for `apps/api` + PostgreSQL.
- [ ] Next.js SEO strategy for the marketing/tool landing pages (SSR or static export).
- [ ] Decide whether `apps/native` desktop should shell out to local LibreOffice/Ghostscript
      instead of calling the backend for some operations.

## Working notes

- This file is meant to prevent re-deriving context in a future session — read this first,
  then `design/README.md`, before asking the user to re-explain decisions already made here.
- Keep this file updated as decisions are made or superseded; don't let it silently go stale.
