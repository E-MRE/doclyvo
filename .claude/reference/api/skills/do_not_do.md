# Do Not Do — apps/api

**Structure violations**
- pikepdf/LibreOffice calls inside `router.py` → belongs in that tool's `service.py`.
- One tool's `service.py` importing another tool's `service.py` → shared logic goes in
  `core/` or a shared `pdf_ops` module instead.
- A `features/shared/` grab-bag folder → cross-tool code goes in `shared/` (models/schemas
  only) or `core/` (behavior), not a copy of the feature pattern.

**Config violations**
- `os.environ.get(...)` anywhere outside `app/config.py`.
- A hardcoded file-size limit, LibreOffice binary path, or database URL inline in a service.

**File-handling violations**
- Writing to a shared/unscoped temp path instead of a per-request `temp_workspace()`.
- Trusting a client-supplied filename for the on-disk path (path traversal risk) — generate
  it server-side.
- Leaving a temp file behind on the error path — cleanup must run in `finally`.
- Keeping processed files longer than the stated retention window "just in case."

**Error-handling violations**
- Raising a bare `Exception` or letting a raw `subprocess.CalledProcessError` /
  `pikepdf.PdfError` reach the client — wrap it in a `DoclyvoError` subclass.
- Returning a Python traceback or internal file path in an API response body.
- A blocking (sync) call inside an `async def` route handler — offload to a thread/executor.

**General violations**
- A Pydantic schema reused verbatim for both request and response when their fields actually
  differ — name and define them separately.
- `Any` in a type hint without a comment justifying it.
