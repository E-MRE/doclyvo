# PDF Processing — apps/api

This is the domain-specific core of the backend — get the isolation and cleanup rules right
here or every tool inherits the same bugs.

## Service isolation

- All `pikepdf` calls and all LibreOffice subprocess invocations live inside a tool's
  `service.py` — never in `router.py`, never in a Pydantic schema, never in a shared utility
  that isn't explicitly named for the operation it does.
- A service method takes file paths/bytes in, returns a file path/bytes out — it never knows
  about HTTP (no `Request`, no `HTTPException` inside a service; raise a domain exception
  instead, see `error_handling.md`, and let the router translate it to HTTP).
- LibreOffice headless calls are wrapped in a single helper (`core/libreoffice.py`,
  `convert_via_libreoffice(input_path, output_format) -> Path`) that every tool needing
  Office↔PDF conversion calls — don't let each tool shell out to `soffice` with its own
  argument list.

## Temp file lifecycle

- Every uploaded file gets a per-request temp directory (`core/files.py`'s
  `temp_workspace()` context manager / async context manager) — never write to a shared,
  unscoped temp path that two concurrent requests could collide on.
- The temp workspace is deleted in a `finally` block (or via the context manager's `__aexit__`)
  regardless of whether the operation succeeded — a failed compress must not leak a temp file.
- Set an explicit max upload size (via FastAPI's request size limit or a manual check before
  processing) and reject oversized files early, before any pikepdf/LibreOffice work starts.
- Never trust the client-supplied filename for anything beyond display — generate the actual
  on-disk filename (UUID-based) to avoid path traversal.

## Privacy / retention

- Match the promise made in the design (`design/README.md`'s "Dosyalar bu makinede
  işlenir/24 saat sonra silinir" language, and the anonymous-usage decision in `ROADMAP.md`):
  processed files are deleted after a short retention window (e.g. 24h) via a scheduled
  cleanup job, not kept indefinitely "just in case."
- Don't log file contents or filenames at anything above debug level; job IDs are fine to log,
  user document names are not.
