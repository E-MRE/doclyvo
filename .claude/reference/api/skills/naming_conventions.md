# Naming Conventions — apps/api

- **Modules/files:** `snake_case.py`.
- **Classes:** `PascalCase`. Pydantic schemas suffixed by role: `CompressRequest`,
  `CompressResponse` — not a generic `CompressSchema` reused for both directions.
- **Service classes:** `<Tool>Service` (`CompressService`, `MergeService`), one per feature,
  holding the actual pikepdf/LibreOffice/OCR calls.
- **SQLAlchemy models:** singular `PascalCase` (`Job`, `User`), table name plural via
  `__tablename__ = "jobs"`.
- **Functions:** `snake_case`, verbs (`compress_pdf`, `extract_page_count`).
- **Env vars / Settings fields:** `SCREAMING_SNAKE_CASE` in the environment, mapped to
  `snake_case` `Settings` attributes by `pydantic-settings`.
- **Endpoint paths:** plural nouns, kebab-case where multi-word (`/tools/pdf-to-word`, not
  `/tools/pdfToWord` or `/tools/pdf_to_word`).
- No `I`/`Base` prefix on interfaces/abstract classes — same rule as the other two stacks
  (`CompressService`, not `IPdfService` or `BaseCompressService`).
