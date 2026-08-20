# apps/native

Doclyvo's mobile (iOS/Android) and desktop (Windows/macOS/Linux) app — a single Flutter codebase.

**Planned stack:** Flutter (Dart).

**Status:** Scaffolded 2026-08-21 via `flutter create --org com.doclyvo --project-name doclyvo
--platforms=ios,android,macos,windows,linux`. No features implemented yet — this is the bare
template.

**Split of responsibilities** (decided 2026-08-21, see `NATIVE-TASKS.md` at the repo root
for full reasoning):
- 8 tools run fully on-device, no backend call at all: Merge, Split, Rotate, Reorder,
  Watermark, Compress, Protect, Sign — via the `pdf_manipulator` package (MIT, prebuilt
  binaries per platform).
- 3 tools call the FastAPI backend in `apps/api` over HTTP: Redact, OCR, PDF-to-Word —
  their client-side equivalents are unproven (redaction reliability, OCR accuracy) or
  missing (real PDF→DOCX layout fidelity), so they stay on the proven
  PyMuPDF/LibreOffice/Tesseract backend for now.
- Desktop LibreOffice/Ghostscript shell-out: decided against — not needed, since the 8
  client-side tools use `pdf_manipulator` and the 3 backend tools already have a working
  backend.

**Reference:** See `../../design/` for the design source, `../../NATIVE-TASKS.md` for the
full task breakdown, `CLAUDE.md` in this directory for standing architecture rules, and
`ROADMAP.md` at the repo root.
