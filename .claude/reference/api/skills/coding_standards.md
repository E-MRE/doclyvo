# Coding Standards — apps/api

- **Full type hints everywhere** — function signatures, return types, class attributes.
  `mypy --strict` (or at minimum pyright in strict mode) should pass; no bare `Any` without a
  reason.
- **Pydantic v2** for every request/response model and for `Settings` — no hand-rolled `dict`
  payloads, no `TypedDict` where a Pydantic model would do.
- **`ruff`** for linting + formatting (replaces black/isort/flake8) — one tool, one config,
  `ruff.toml` at the repo root of `apps/api`.
- Async all the way down for I/O: route handlers are `async def`, DB session use is
  async-SQLAlchemy, the LibreOffice subprocess call runs via `asyncio.create_subprocess_exec`
  or is offloaded to a thread pool (`run_in_executor`) — never a blocking call inside an
  `async def` route handler.
- Dependency injection via FastAPI's `Depends()` for DB sessions, settings, and current-user
  (once auth exists) — don't reach for a global session/singleton.
- `pathlib.Path`, never raw string path concatenation, for anything touching the filesystem
  (temp upload dirs, output files).
