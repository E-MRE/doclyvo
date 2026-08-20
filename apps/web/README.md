# apps/web

Doclyvo's web application — Next.js 15, TypeScript, Tailwind CSS v4, App Router.

**Phase A scope (done):** all nine tools — Compress, Merge, Split, Rotate, Reorder, Watermark,
Protect, OCR, and PDF-to-Word — each implemented from its `design/*.dc.html` source.
**Sign** (self-sign only — draw/type/upload a signature, place it, download) is the tenth,
the first Phase B slice; see `../api/README.md` for the authenticated hash + audit-log path
it optionally triggers server-side. See `../../docs/build-prompt-web-mvp.md` for the full
scope rationale and `../../.claude/reference/web/` for the coding conventions this app
follows.

`apps/api` must have its own system dependencies installed for OCR and PDF-to-Word to work —
see `../api/README.md`'s Setup section (Tesseract, LibreOffice headless).

## Setup

```bash
npm install
cp .env.example .env
```

`apps/api` must be running (see `../api/README.md`) — `API_BASE_URL` in `.env` points at it.

## Run it

```bash
npm run dev
```

Open `http://localhost:3000`.

## Architecture

- `app/` — routes only (`page.tsx`, `layout.tsx`, `app/tools/<tool>/page.tsx`), server-rendered
  by default so tool landing pages stay crawlable.
- `features/<name>/` — one folder per feature (`home`, `compress`, `merge`, `split`, `rotate`,
  `reorder`, `watermark`, `protect`, `ocr`, `pdf-to-word`, `sign`): feature-local components, a
  server-action `actions.ts` that's the only thing calling `lib/api-client.ts`, and `types.ts`.
- `lib/hooks/use-pdf-page-count.ts` — reads a PDF's page count client-side via `pdf-lib` (no
  server round-trip); used by Split/Rotate/Reorder to render per-page selection UI before the
  file is ever sent to `apps/api`.
- `components/` — shared, cross-feature UI (`Header`, `ErrorState`, `UploadDropzone`).
- `lib/api-client.ts` — the one place that knows the FastAPI base URL and turns non-2xx
  responses into a typed `ApiError`.
- `app/globals.css` — the Tailwind v4 `@theme` block with every design token (accent color,
  radius scale, light/dark surface colors) — see `.claude/reference/web/skills/design_system.md`
  for the no-hardcoded-values rule this file exists to satisfy.

Each tool page renders explicit empty → idle → processing → done/error UI states — see
`.claude/reference/web/skills/error_handling.md`.

## Testing

End-to-end — one spec per tool (compress, split, rotate, reorder, watermark, protect, ocr,
pdf-to-word, sign), spins up both `apps/api` and `apps/web` automatically:

```bash
npm run test:e2e
```

The `ocr` and `pdf-to-word` specs exercise `apps/api`'s real Tesseract/LibreOffice calls (no
mocking at this boundary) — install those system dependencies first (see `../api/README.md`).
On macOS, pass `LIBREOFFICE_BINARY` through since the Homebrew cask isn't on `PATH`:

```bash
LIBREOFFICE_BINARY=/Applications/LibreOffice.app/Contents/MacOS/soffice npm run test:e2e
```

Type checking and lint:

```bash
npx tsc --noEmit
npm run lint
```
