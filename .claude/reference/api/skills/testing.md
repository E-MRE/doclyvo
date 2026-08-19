# Testing — apps/api

- `tests/` mirrors `app/` 1:1 — same rule as the Flutter side's `test/`↔`lib/` parity
  (`tests/features/compress/test_service.py` for `app/features/compress/service.py`).
- `pytest` + `pytest-asyncio` for async route/service tests; `httpx.AsyncClient` against the
  FastAPI app for route-level tests (no real network).
- Service tests for PDF operations use small, checked-in fixture PDFs
  (`tests/fixtures/*.pdf`) — never rely on downloading a file or a real LibreOffice install
  being present for a *unit* test; mock the `convert_via_libreoffice` helper for anything that
  isn't specifically testing that integration.
- A dedicated (small) set of integration tests may actually shell out to LibreOffice/pikepdf
  for real, marked clearly (`@pytest.mark.integration`) and excluded from the fast default run.
- Every custom `DoclyvoError` subclass has at least one test asserting the router surfaces it
  with the right status code and `code` field (see `error_handling.md`) — this is the
  contract `apps/web` depends on.
- Clean up any temp files a test creates, even on failure (use the same `temp_workspace()`
  helper the app code uses, don't hand-roll a second temp-file pattern in tests).
