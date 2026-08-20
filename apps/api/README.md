# apps/api

Doclyvo's backend service — Python 3.12, FastAPI, pikepdf. Shared by `apps/web` and (later)
`apps/native` for anything that can't run purely on the client.

**Phase A scope:** merge, split, compress, rotate, reorder, watermark, protect, OCR, and
PDF-to-Word — all synchronous request/response over HTTP, no job queue, no database.
**`sign`** (self-sign only — draw/type/upload a signature, place it, download) is the first
Phase B slice and the first endpoint to touch a database: when the request carries an
`Authorization: Bearer` credential it hash-seals the signed PDF and writes an append-only
audit-log row to PostgreSQL; anonymous requests (100% of real traffic today, since no login
exists yet) stay exactly as stateless as the other nine tools. See
`../../docs/build-prompt-web-mvp.md` for the full scope rationale and
`../../.claude/reference/api/` for the coding conventions this app follows.

## Setup

```bash
uv sync
cp .env.example .env
```

**System dependencies** (not installed by `uv sync` — these are native binaries):

- **Tesseract OCR**, plus the language packs the `ocr` endpoint offers (`eng`, `tur`):
  - macOS: `brew install tesseract`, then drop `tur.traineddata` into
    `$(brew --prefix)/share/tessdata/` (Homebrew's tesseract only ships `eng` — grab
    `tur.traineddata` from the
    [tessdata_fast](https://github.com/tesseract-ocr/tessdata_fast) repo).
  - Debian/Ubuntu: `apt install tesseract-ocr tesseract-ocr-tur`.
- **LibreOffice headless**, for the `pdf-to-word` endpoint:
  - macOS: `brew install --cask libreoffice`. The cask does **not** put `soffice` on `PATH` —
    set `LIBREOFFICE_BINARY=/Applications/LibreOffice.app/Contents/MacOS/soffice` in `.env`.
  - Debian/Ubuntu: `apt install libreoffice`, where `soffice` is normally already on `PATH`
    (the `LIBREOFFICE_BINARY=soffice` default just works).

## Run it

```bash
uv run uvicorn app.main:app --reload
```

The API listens on `http://localhost:8000`. `apps/web` expects it there by default
(`API_BASE_URL` in `apps/web/.env.example`).

## Architecture

- `app/main.py` — FastAPI app, CORS, the `DoclyvoError` → JSON error-shape exception handler.
- `app/config.py` — all configuration (`pydantic-settings`, reads `.env`).
- `app/core/` — cross-tool infrastructure: the error hierarchy, the per-request temp
  workspace lifecycle (`app/core/files.py`), the single LibreOffice subprocess wrapper every
  Office-conversion tool calls through (`app/core/libreoffice.py`), the optional-bearer-token
  dependency (`app/core/auth.py`), and the async SQLAlchemy engine/session + append-only
  audit-log writer (`app/core/database.py`, `app/core/audit.py`) that only `sign`'s
  authenticated path ever touches.
- `app/shared/models.py` — cross-tool SQLAlchemy models: `AuditLogEntry` (sign's hash-sealed
  compliance trail) and `Job` (a general "what did I run" history table — schema only, no
  router writes to it yet; see "Job history schema" below) — per
  `.claude/reference/api/skills/project_structure.md`, tables shared across tools don't live
  in a single feature's folder.
- `app/features/<tool>/` — one folder per PDF operation (`merge`, `split`, `compress`,
  `rotate`, `reorder`, `watermark`, `protect`, `ocr`, `pdf_to_word`, `sign`), each with a thin
  `router.py` and the actual work in `service.py`. See
  `.claude/reference/api/skills/pdf_processing.md` for the isolation rules.
- `assets/fonts/DejaVuSans-Bold.ttf` — bundled so `watermark` can render Turkish characters
  (İ, ı, ğ, ş) correctly; reportlab's built-in Helvetica only covers Latin-1, not Turkish.
  `assets/fonts/Caveat-SemiBold.ttf` is the same idea for `sign`'s "type" mode (OFL license in
  `Caveat-OFL.txt` next to it).
- `migrations/` — Alembic, async-aware (`migrations/env.py` builds its engine from
  `get_settings().database_url`). Two revisions so far: `audit_log_entries`, `jobs`.

Every endpoint accepts `multipart/form-data`, writes uploads into a per-request temp
directory, and returns the processed file directly (`split` returns a `.zip` of one PDF per
page). The temp directory is deleted once the response has been sent, whether the request
succeeded or failed.

`ocr` and `pdf-to-word` call an external binary (`tesseract`, `soffice`) per request; `ocr`'s
call is offloaded to a thread pool (`starlette.concurrency.run_in_threadpool`) since it can
take real wall-clock seconds, and `pdf-to-word`'s LibreOffice subprocess is natively async
(`asyncio.create_subprocess_exec`) — neither blocks the event loop for other requests.

## Local Postgres (sign's audit-log path)

Only needed if you're touching `sign`'s authenticated hash + audit-log path — every other
endpoint, and `sign` itself when called anonymously, works with no database at all.

```bash
docker compose up -d
uv run alembic upgrade head
```

`DATABASE_URL` in `.env.example` points at this local container. Unset (the default in
production today) is a valid, supported state — see the "critical design decision" note in
`app/features/sign/router.py`'s call site: the database is only ever touched inside
`if user_id is not None:`, never as a blanket per-request dependency.

## Job history schema (designed, not wired — 2026-08-20)

`app/shared/models.py`'s `Job` model (+ its `jobs` migration) exists so a future "here's what
you ran" history view has a table to write to, but **nothing writes to it today** — no tool's
router creates a `Job` row. That's deliberate, not an oversight: without real accounts, there
is no user to show a history to, so wiring the write now would be speculative infrastructure
with zero consumers. This section exists so a future session doesn't have to re-derive that
reasoning, and knows exactly what to do once it stops being true.

**When a real login system ships, wiring this in means:**

1. Each tool's router creates one `Job` row after a successful (or failed) run — `tool`,
   `original_filename`, `status` (`JobStatus.SUCCEEDED`/`FAILED`), `error_code` on failure.
2. Gate it the same way `sign` gates its audit-log write: an imperative call inside
   `if user_id is not None:`, **not** a blanket `Depends()` — see `app/features/sign/router.py`
   and the "critical design decision" note there. Anonymous requests should stay exactly as
   stateless as they are today; there's no product reason to log activity nobody can ever look
   back at.
3. `user_id` reuses whatever `get_optional_user_id` (`app/core/auth.py`) resolves to then — no
   new auth plumbing needed, this table was designed against the same seam `sign` already uses.
4. A `GET /me/jobs`-style endpoint (or similar) would be the actual consumer — that's separate,
   unbuilt, and the first thing that would make this table's data visible to anyone.

`Job` is intentionally separate from `AuditLogEntry`: the latter is `sign`'s hash-sealed,
append-only compliance trail (a legal/audit concept from the original reference prompt);
`Job` is a general activity-history concept meant to eventually cover all ten tools, with no
hash-sealing or audit guarantees attached.

## Data & retention

Files never touch a database or a persistent disk location — they live in `TEMP_DIR`
(default `/tmp/doclyvo`) only for the duration of one request, then are deleted immediately.
A `jobs` table schema exists (see "Job history schema" above) but nothing writes to it yet,
so in practice there is still no job history anywhere and nothing to back up.

## Deferred to a later phase

- **Hosting Postgres.** The local dev path (`docker-compose.yml` + Alembic, above) is done,
  but `sign`'s authenticated path is unreachable in production today — no login system issues
  a bearer credential, so `user_id` is always `None` there. Provisioning a managed Postgres on
  Render today would be exactly the dead weight `../../docs/deployment.md` already warns
  about; do that once a real login system makes the path reachable.
- Signer invites, multi-party consent workflow, accounts/billing — `sign` today is
  self-sign-only, matching `design/Sign.dc.html`. See `../../docs/build-prompt-web-mvp.md` and
  `../../ROADMAP.md`'s Phase B entry for the full deferred list.
- **Wiring `Job` history into the ten tools' routers.** The schema exists (see "Job history
  schema" above) but nothing writes to it — deferred to whenever login ships, same as
  accounts/billing above, since it's the same missing dependency (a real `user_id`).
- Redact — no design, no scope decision made on it yet.
- `watermark`'s "keep layout" idea and any richer OCR/PDF-to-Word options were deliberately
  left out rather than shipped as a non-functional toggle — see the design vs. implementation
  note in `../../ROADMAP.md`'s Phase A entry.

## Testing

```bash
uv run pytest
```

`ocr` and `pdf-to-word` each have two kinds of tests:
- A router test that **mocks** the service (`OcrService.recognize` /
  `PdfToWordService.convert`) so the default run never needs `tesseract` or `soffice`
  installed — this is what `uv run pytest` runs everywhere, including CI.
- A `service.py` test marked `@pytest.mark.integration` that calls the real binary, excluded
  by default (`addopts = "-m 'not integration'"` in `pyproject.toml`). Run it explicitly once
  the system dependencies above are installed:

  ```bash
  uv run pytest -m integration
  ```

`sign`'s audit-log write follows the same split: `tests/features/sign/test_router.py`
monkeypatches `record_audit_log_entry` (same style as `OcrService.recognize`) so the default
run needs no real Postgres, and `tests/integration/test_audit_log.py` (also
`@pytest.mark.integration`) writes a real row — bring up the local Postgres first (see "Local
Postgres" above). `tests/integration/test_jobs_schema.py` does the same for `Job` — since
nothing in the app writes to that table yet, it only proves the migration produces a usable
table, not any application behavior. Both integration test modules pin
`pytest.mark.asyncio(loop_scope="session")`: `app/core/database.py`'s cached engine needs one
event loop shared across the whole integration run, not pytest-asyncio's default fresh loop
per test function — see the comment at the top of either file.

Fixture PDFs live in `tests/fixtures/`, checked in rather than generated at test time.
Regenerate them with:

```bash
uv run python scripts/generate_fixtures.py
```

## Linting

```bash
uv run ruff check .
```
