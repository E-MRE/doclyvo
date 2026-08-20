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
- **Backend hosting:** [Render](https://render.com) free tier, chosen 2026-08-20 — Railway and
  Fly.io had both dropped their free tiers by this point (Railway is now paid usage-metered,
  Fly.io requires a card and bills per-second), leaving Render as the only genuinely free option
  of the three. Revisit if traffic grows past the free tier's 512MB RAM / cold-start limits — see
  `docs/deployment.md`.
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
- Screens designed, desktop + mobile: Home, Compress, Result, Merge, Sign, Split, Rotate,
  Reorder, Watermark, Protect, OCR, PDF-to-Word — every tool from the original scope now has
  a design (2026-08-20).
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

## Phase A (done — 2026-08-20)

`apps/web` (Next.js 15 + Tailwind v4) and `apps/api` (Python 3.12 + FastAPI + pikepdf) are
scaffolded and working end-to-end, all nine tools from the original scope implemented on both
sides:

- `apps/api`: merge, split, compress, rotate, reorder, watermark, protect, OCR, and PDF-to-Word
  — each a thin router + a `service.py` doing the real work, a per-request temp workspace
  cleaned up via `BackgroundTask` after the response is sent, and a `DoclyvoError` → JSON
  exception handler. Watermark uses pikepdf + reportlab (with a bundled DejaVu Sans font for
  Turkish characters — Helvetica's built-in encoding can't render İ/ı/ğ/ş); protect uses
  pikepdf's encryption/permissions support; OCR renders pages via PyMuPDF and recognizes text
  with `pytesseract` (offloaded to a thread pool); PDF-to-Word is the first real use of the
  LibreOffice headless integration (`app/core/libreoffice.py`), deferred since day one. No
  database yet — see `apps/api/README.md`'s "Deferred to a later phase" for why. 31 pytest
  tests pass (28 default + 3 `@pytest.mark.integration` tests that need real
  tesseract/LibreOffice, excluded from the default run).
- `apps/web`: all nine tool pages, implementing their `design/*.dc.html` sources with real
  empty/idle/processing/done/error states wired to `apps/api` through server actions.
  Rotate/Reorder read the page count client-side via `pdf-lib`
  (`lib/hooks/use-pdf-page-count.ts`) to drive per-page select/rotate and reorder-with-arrows
  UI — no backend endpoint needed for that. Eight Playwright end-to-end tests (one per tool)
  each drive the real flow through both servers together (`npm run test:e2e`), including real
  Tesseract/LibreOffice calls for OCR and PDF-to-Word.
- One deliberate scope cut from the designs: PDF-to-Word's "Düzeni koru" (keep layout) checkbox
  wasn't wired up — LibreOffice's PDF import doesn't expose a real alternate-layout mode via
  the command-line convert path, so a toggle here would do nothing. Shipped without it rather
  than as a fake option; noted in `apps/api/README.md`.
- Next session: Phase B. Read `docs/build-prompt-web-mvp.md`'s "Deferred to a later phase"
  section for what's left (redact/signatures-with-audit-log/accounts, plus the
  PostgreSQL/job-history wiring Phase A intentionally skipped).

## Hosting (Phase A.5 — deployed, 2026-08-20)

`apps/api` and `apps/web` are both deployed to Render's free tier via the root `render.yaml`
blueprint. See `docs/deployment.md` for the why-Render tradeoff, the free-tier caveats (512MB
RAM, 15-min cold-start spin-down), and first-deploy steps. `apps/api/Dockerfile` installs
`libreoffice-writer` + `tesseract-ocr`/`tesseract-ocr-tur` on top of
`ghcr.io/astral-sh/uv:python3.12-bookworm-slim` so the same LibreOffice/Tesseract integrations
that work locally (per `apps/api/README.md`) work in the hosted container too — no code changes
needed, only deploy config. PostgreSQL is explicitly not part of this: still no database
integration anywhere in `apps/api`, so there's nothing to host yet.

## Open / follow-up work

- [x] Design Watermark, Protect, OCR, PDF to Word — done 2026-08-20, see `design/README.md`.
      Every tool from the original scope is now designed.
- [x] Build the `apps/web` pages for Split, Rotate, and Reorder — done 2026-08-20, see Phase A
      above.
- [x] Build `apps/api` endpoints and `apps/web` pages for Watermark, Protect, OCR, and
      PDF-to-Word — done 2026-08-20, see Phase A above. This is what finally activated the
      LibreOffice headless integration deferred since Phase 0.
- [x] Scaffold `apps/web` with `create-next-app` (TypeScript) — done, see Phase A above.
- [ ] Scaffold `apps/native` with `flutter create`.
- [x] Scaffold `apps/api` with FastAPI; wire up pikepdf — done, see Phase A above.
- [ ] Phase B (deferred, not started): redact, signature-with-consent-and-hash + append-only
      audit log, accounts/premium tier. Every other tool from the original scope is now built.
- [ ] Design the PostgreSQL schema (job/history records first; user accounts later for the
      premium tier).
- [x] Pick and configure the hosting provider for `apps/api` + `apps/web` — done 2026-08-20,
      Render free tier, see the "Hosting" section above and `docs/deployment.md`. PostgreSQL
      hosting deliberately deferred — no database integration exists yet to host.
- [ ] Next.js SEO strategy for the marketing/tool landing pages (SSR or static export).
- [ ] Decide whether `apps/native` desktop should shell out to local LibreOffice/Ghostscript
      instead of calling the backend for some operations.

## Working notes

- This file is meant to prevent re-deriving context in a future session — read this first,
  then `design/README.md`, before asking the user to re-explain decisions already made here.
- Keep this file updated as decisions are made or superseded; don't let it silently go stale.
