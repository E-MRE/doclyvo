# apps/native

Doclyvo's mobile (iOS/Android) and desktop (Windows/macOS/Linux) app — a single Flutter codebase.

**Planned stack:** Flutter (Dart).

**Status:** Not scaffolded yet (`flutter create` has not been run).

**Split of responsibilities:**
- Basic PDF operations (merge/split/rotate/watermark) → native Dart packages (e.g.
  `syncfusion_flutter_pdf`, `pdfrx`), no backend needed.
- Heavy operations (Office↔PDF conversion, OCR) → calls the FastAPI backend in `apps/api`
  over HTTP.
- Desktop-specific option: shell out to a local LibreOffice/Ghostscript binary to reduce the
  backend dependency — not decided yet.

**Reference:** See `../../design/` for the design source and `ROADMAP.md` at the repo root.
