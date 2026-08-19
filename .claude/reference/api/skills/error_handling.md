# Error Handling — apps/api

The response shape here is a contract with `apps/web` and `apps/native` — don't change it
casually; see `.claude/reference/web/skills/error_handling.md` for the client side of this
contract.

## Exception hierarchy

```python
class DoclyvoError(Exception):
    code: str      # stable machine-readable code, e.g. "file_too_large"
    message: str   # human-readable, safe to show the user

class FileTooLargeError(DoclyvoError): ...
class UnsupportedFormatError(DoclyvoError): ...
class ProcessingFailedError(DoclyvoError): ...  # pikepdf/LibreOffice failure, wrapped
```

- Services raise a specific `DoclyvoError` subclass, never a bare `Exception` or a raw
  `subprocess.CalledProcessError` — wrap external tool failures (pikepdf, LibreOffice) into a
  `ProcessingFailedError` with the specifics logged server-side, not exposed raw to the client.
- A single FastAPI exception handler (`app/main.py` or `core/errors.py`) catches
  `DoclyvoError` and returns:
  ```json
  { "error": { "code": "file_too_large", "message": "..." } }
  ```
  with the appropriate HTTP status — this is the shape `apps/web`'s `ApiError` expects.
- Unhandled exceptions still get caught by a catch-all handler that logs the full traceback
  server-side and returns a generic `internal_error` code to the client — never leak a Python
  traceback or internal path in the response body.
- Validation errors (Pydantic) use FastAPI's default 422 handling — don't reinvent that path.
