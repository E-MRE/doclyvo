# apps/api

Doclyvo's backend service. Shared by `apps/web` and `apps/native` for anything that can't run
purely on the client.

**Planned stack:** Python 3.12, FastAPI, pikepdf, LibreOffice headless, PostgreSQL.

**Status:** Not scaffolded yet.

**Scope:**
- PDF operations via `pikepdf` (merge/split/rotate/watermark/compress).
- Office↔PDF conversion via LibreOffice headless.
- OCR (library TBD, e.g. `pytesseract`).
- File lifecycle: upload → process → download → delete.
- PostgreSQL: used for job/history records and, later, optional user accounts (premium tier).
  Anonymous usage without an account must keep working.

**Hosting:** Start on a free/hobby-tier PaaS (Render, Railway, or Fly.io); revisit if traffic
grows.

**Reference:** See `ROADMAP.md` at the repo root for the full architecture context.
