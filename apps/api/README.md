# apps/api

Doclyvo's backend service — Python 3.12, FastAPI, pikepdf. Shared by `apps/web` and (later)
`apps/native` for anything that can't run purely on the client.

**Phase A scope (current):** merge, split, compress, rotate, reorder PDFs, all synchronous
request/response over HTTP — no job queue, no database yet. See
`../../docs/build-prompt-web-mvp.md` for the full scope rationale and
`../../.claude/reference/api/` for the coding conventions this app follows.

## Setup

```bash
uv sync
cp .env.example .env
```

## Run it

```bash
uv run uvicorn app.main:app --reload
```

The API listens on `http://localhost:8000`. `apps/web` expects it there by default
(`API_BASE_URL` in `apps/web/.env.example`).

## Architecture

- `app/main.py` — FastAPI app, CORS, the `DoclyvoError` → JSON error-shape exception handler.
- `app/config.py` — all configuration (`pydantic-settings`, reads `.env`).
- `app/core/` — cross-tool infrastructure: the error hierarchy and the per-request temp
  workspace lifecycle (`app/core/files.py`).
- `app/features/<tool>/` — one folder per PDF operation (`merge`, `split`, `compress`,
  `rotate`, `reorder`), each with a thin `router.py` and the actual `pikepdf` work in
  `service.py`. See `.claude/reference/api/skills/pdf_processing.md` for the isolation rules.

Every endpoint accepts `multipart/form-data`, writes uploads into a per-request temp
directory, and returns the processed file directly (`split` returns a `.zip` of one PDF per
page). The temp directory is deleted once the response has been sent, whether the request
succeeded or failed.

## Data & retention

Files never touch a database or a persistent disk location — they live in `TEMP_DIR`
(default `/tmp/doclyvo`) only for the duration of one request, then are deleted immediately.
There is currently no job history and nothing to back up.

## Deferred to a later phase

- **PostgreSQL / job history / docker-compose.** The stack decision in the root `ROADMAP.md`
  includes PostgreSQL, but Phase A's operations are synchronous and stateless — there is
  nothing yet for a database to store. Wiring up SQLAlchemy + Alembic + `docker-compose.yml`
  is deferred to whichever Phase B feature first needs persistent job/history records, per
  `../../ROADMAP.md`'s open work list. Standing up an unused Postgres container today would
  just be dead weight.
- LibreOffice headless (Office↔PDF conversion), OCR, watermark, redact, signatures, accounts —
  see `../../docs/build-prompt-web-mvp.md` for the full deferred list.

## Testing

```bash
uv run pytest
```

Fixture PDFs live in `tests/fixtures/`, checked in rather than generated at test time.
Regenerate them with:

```bash
uv run python scripts/generate_fixtures.py
```

## Linting

```bash
uv run ruff check .
```
