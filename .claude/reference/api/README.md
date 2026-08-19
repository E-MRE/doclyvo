# apps/api — Coding Conventions

Reference knowledge base for `apps/api` (Python 3.12, FastAPI, pikepdf, LibreOffice headless,
PostgreSQL), mirroring the same philosophy as `.claude/reference/flutter/` and
`.claude/reference/web/`: feature-based structure, no hardcoded config, one clear place for
each kind of code, a service layer between routes and the messy PDF-tooling reality.

`apps/api` has not been scaffolded yet — these conventions apply from the first commit.

**Files:**
- `skills/project_structure.md` — feature-based router/service layout
- `skills/coding_standards.md` — typing, formatting, lint baseline
- `skills/naming_conventions.md` — module/class/function naming
- `skills/pdf_processing.md` — pikepdf/LibreOffice service isolation, temp file lifecycle
- `skills/error_handling.md` — exception hierarchy, consistent JSON error shape (must match
  `apps/web`'s `ApiError` expectations)
- `skills/environment_config.md` — settings via `pydantic-settings`, no hardcoded config
- `skills/testing.md` — pytest conventions
- `skills/do_not_do.md` — the concrete "never do this" list

**Cross-stack consistency:** this backend is shared by both `apps/web` and `apps/native` (for
heavy operations) — see `ROADMAP.md`. Its API contract is the seam between three codebases;
changing a response shape or endpoint path is a breaking change for two other apps, not a
local refactor.

**Assumptions made ahead of scaffolding** (revisit once `apps/api` is actually created):
- ORM: SQLAlchemy 2.0 (async) + Alembic for migrations — a conventional, well-supported
  default for FastAPI + PostgreSQL; not yet confirmed with the user.
- Dependency/package manager: `uv` or `poetry` — pick one when scaffolding, don't mix.
