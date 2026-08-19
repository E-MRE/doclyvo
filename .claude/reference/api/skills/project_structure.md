# Project Structure — apps/api

Feature-first, same rule as the Flutter and web sides: a tool is a vertical slice.

```
apps/api/
├── app/
│   ├── main.py                  → FastAPI app creation, middleware, router registration only
│   ├── config.py                → Settings (pydantic-settings), the ONLY place env vars are read
│   ├── core/
│   │   ├── errors.py             → exception hierarchy (see error_handling.md)
│   │   ├── database.py           → SQLAlchemy engine/session setup
│   │   └── files.py              → shared temp-file lifecycle helpers (upload dir, cleanup)
│   ├── features/
│   │   └── <tool>/                → e.g. compress, merge, sign, convert
│   │       ├── router.py           → FastAPI route handlers — thin, no PDF logic here
│   │       ├── service.py          → the actual pikepdf/LibreOffice/OCR work
│   │       ├── schemas.py          → Pydantic request/response models for this tool
│   │       └── models.py           → SQLAlchemy models, only if this tool needs its own table
│   └── shared/
│       ├── schemas.py             → cross-tool Pydantic models (e.g. JobStatus)
│       └── models.py              → cross-tool tables (e.g. Job, User)
└── tests/                        → mirrors app/ structure 1:1 (see testing.md)
```

**Dependency direction:** `router.py → service.py → core/`. A router never calls pikepdf or
shells out to LibreOffice directly — always through that tool's `service.py`. `core/` never
imports from `features/`. **Tools never import another tool's `service.py`** — if two tools
need the same PDF operation, that operation belongs in `core/` (or a shared
`features/pdf_ops/` module both call), not copy-pasted or cross-imported.

**Where does new code go?**

| What | Where |
|---|---|
| A new tool's endpoint | `features/<tool>/router.py` |
| The actual PDF/LibreOffice/OCR work for that tool | `features/<tool>/service.py` |
| Request/response shape for that tool | `features/<tool>/schemas.py` |
| Something 2+ tools need (e.g. "extract page count") | `core/` or a shared `features/pdf_ops/` |
| A DB table used by multiple tools (Job, User) | `shared/models.py` |
| Env-driven config | `app/config.py`'s `Settings`, never `os.environ.get(...)` inline |
