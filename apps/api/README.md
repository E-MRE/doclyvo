# apps/api

Doclyvo's backend service — Python 3.12, FastAPI, pikepdf. Shared by `apps/web` and (later)
`apps/native` for anything that can't run purely on the client.

**Phase A scope (current):** merge, split, compress, rotate, reorder, watermark, protect, OCR,
and PDF-to-Word — all synchronous request/response over HTTP, no job queue, no database yet.
See `../../docs/build-prompt-web-mvp.md` for the full scope rationale and
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
  workspace lifecycle (`app/core/files.py`), and the single LibreOffice subprocess wrapper
  every Office-conversion tool calls through (`app/core/libreoffice.py`).
- `app/features/<tool>/` — one folder per PDF operation (`merge`, `split`, `compress`,
  `rotate`, `reorder`, `watermark`, `protect`, `ocr`, `pdf_to_word`), each with a thin
  `router.py` and the actual work in `service.py`. See
  `.claude/reference/api/skills/pdf_processing.md` for the isolation rules.
- `assets/fonts/DejaVuSans-Bold.ttf` — bundled so `watermark` can render Turkish characters
  (İ, ı, ğ, ş) correctly; reportlab's built-in Helvetica only covers Latin-1, not Turkish.

Every endpoint accepts `multipart/form-data`, writes uploads into a per-request temp
directory, and returns the processed file directly (`split` returns a `.zip` of one PDF per
page). The temp directory is deleted once the response has been sent, whether the request
succeeded or failed.

`ocr` and `pdf-to-word` call an external binary (`tesseract`, `soffice`) per request; `ocr`'s
call is offloaded to a thread pool (`starlette.concurrency.run_in_threadpool`) since it can
take real wall-clock seconds, and `pdf-to-word`'s LibreOffice subprocess is natively async
(`asyncio.create_subprocess_exec`) — neither blocks the event loop for other requests.

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
- Redact, signature mode with signer invites/consent/hash-sealing + an append-only audit log,
  accounts/billing — see `../../docs/build-prompt-web-mvp.md` for the full deferred list.
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

Fixture PDFs live in `tests/fixtures/`, checked in rather than generated at test time.
Regenerate them with:

```bash
uv run python scripts/generate_fixtures.py
```

## Linting

```bash
uv run ruff check .
```
