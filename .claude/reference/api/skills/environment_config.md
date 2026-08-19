# Environment & Config — apps/api

- All configuration comes from `app/config.py`'s `Settings` class (`pydantic-settings`,
  reading from `.env` / real env vars) — **never** `os.environ.get(...)` scattered through the
  codebase, and never a hardcoded database URL, LibreOffice path, or max-file-size constant
  inline in a service.
- `Settings` is instantiated once (`get_settings()`, cached with `lru_cache` or FastAPI's
  `Depends`) and injected where needed — services and routers receive it via `Depends`, not by
  importing a global.
- `.env` files are never committed (already covered by the repo's `.gitignore`); a
  `.env.example` with every key and a safe placeholder value is committed instead, and kept in
  sync whenever a new setting is added.
- Distinguish environments explicitly (`ENVIRONMENT=development|staging|production` in
  `Settings`) rather than inferring behavior from, e.g., whether `DATABASE_URL` contains
  "localhost".
