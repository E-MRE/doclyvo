# Build prompt — apps/web + apps/api MVP

This is the working spec for the first coding phase, started 2026-08-19. It adapts a reference
prompt (below) to this repo's actual decisions in `ROADMAP.md`. Read `ROADMAP.md` and
`design/README.md` first if you're picking this up in a new session — this file assumes both.

## Original reference prompt (verbatim, source of the feature scope)

> Build a personal replacement for ILovePDF Premium in an empty repository.
> Use Next.js 15, TypeScript, Python 3.12, FastAPI, pikepdf, LibreOffice headless, and PostgreSQL; do not offer alternative stacks.
> The core loop is: merge, split, compress, convert, and annotate PDFs locally, preserve originals, generate auditable outputs, and keep files in a user-owned store without uploading them to a vendor.
> Make the first run work locally with one documented command.
> Store all user data locally by default and make export straightforward.
> Put secrets in .env, ship .env.example, and never commit credentials.
> Keep every original immutable and write each operation to a versioned output file.
> Support merge, split, reorder, rotate, compress, watermark, redact, OCR, and Office-to-PDF conversion.
> Render page previews and warn when fonts, forms, signatures, or encryption may be altered.
> For signature mode, place fields, invite signers, record consent, and seal a final PDF hash.
> Maintain an append-only event log with timestamps, document hashes, and delivery outcomes.
> Add file expiry, download, deletion, backup, and a prominent low-stakes-use warning.
> Include clear empty, loading, success, and recoverable error states.
> Add input validation, safe filenames, and graceful handling of unavailable APIs.
> Write focused tests for the core transformation and one end-to-end happy path.
> Create a README with setup, architecture, permissions, data location, and backup steps.
> Do not add accounts, billing, telemetry, analytics, or a hosted control plane.
> Deliberately leave out qualified or regulated electronic signatures.
> Deliberately leave out government identity verification.
> Deliberately leave out full Acrobat-level editing and enterprise document governance.
> Finish by running the tests and listing the exact commands used.

## Adaptations made, and why

| Original line | Adaptation | Why |
|---|---|---|
| "in an empty repository" | Build inside `apps/web` (Next.js) and `apps/api` (FastAPI) of the existing `doclyvo` monorepo, following `.claude/reference/web/` and `.claude/reference/api/` conventions | Repo isn't empty — it already has the design source, roadmap, and house style written down; don't restart from zero |
| Full feature list (merge, split, compress, convert, watermark, redact, OCR, Office-to-PDF, signature-with-consent-and-hash, append-only audit log) | **Phase A (this pass): merge, split, compress, rotate, reorder only.** Everything else is Phase B+ | Matches the user's stated "step by step" preference; only Compress/Merge (and a simplified Sign) have been designed so far — watermark/redact/OCR/Office-conversion/full signature-with-audit-hash haven't been designed or planned in depth yet |
| "keep files in a user-owned store without uploading them to a vendor" / "store all user data locally" | Files are uploaded to *our own* `apps/api` (not a third-party vendor API) for processing, stored in a per-job temp workspace, deleted after a retention window (see `.claude/reference/api/skills/pdf_processing.md`) | The constraint is about not routing user files through a third-party SaaS, not about literally never leaving the user's device — our own backend satisfies the spirit of it |
| "Do not add accounts, billing, telemetry, analytics, or a hosted control plane" | Correct for Phase A. `ROADMAP.md`'s "optional account for premium tier" is explicitly a *later* phase, not part of this pass | No real conflict once sequenced — build anonymous-first, add accounts when there's an actual premium feature needing one |
| "For signature mode, place fields, invite signers, record consent, and seal a final PDF hash" + append-only event log | **Deferred to Phase B.** The current `Sign.dc.html` design only covers draw/type/upload + placement, not invite/consent/hash-sealing/audit log | This is a materially bigger feature (multi-party workflow, hash sealing, audit trail) than what's designed or scoped for the first pass |
| "Make the first run work locally with one documented command" | Kept as-is — `docker compose up` (or equivalent) should bring up `apps/api` + PostgreSQL; `apps/web` runs with `npm run dev` against it, documented in each app's README | Directly compatible with later deploying the same `apps/api` to the PaaS chosen in `ROADMAP.md` — local-first dev setup and hosted deployment aren't in tension |

## Phase A execution prompt (use this to kick off the coding session)

Build the MVP of Doclyvo's web app inside the existing `doclyvo` monorepo:

- **Scope:** merge, split, compress, rotate, reorder PDFs. No accounts, no billing, no
  telemetry. No OCR, watermark, redact, Office-conversion, or e-signature yet — those are
  later phases, don't scaffold placeholders for them.
- **Stack:** Next.js 15 + TypeScript in `apps/web`; Python 3.12 + FastAPI + pikepdf +
  PostgreSQL in `apps/api` (LibreOffice headless isn't needed until Office-conversion ships in
  a later phase — don't wire it up yet, but don't design against ever adding it either).
  Follow `.claude/reference/web/` and `.claude/reference/api/` for structure/naming/error
  handling/design tokens.
- **Design:** implement `design/Main.dc.html`, `design/Compress.dc.html`, and
  `design/Merge.dc.html` (and their `Mobile*` counterparts for responsive behavior, not as
  separate routes) as the actual Next.js pages — same layout, same tokens (`#DC4731` accent,
  system font stack, radius scale), same interaction pattern (idle → processing → done).
- **Data:** keep every uploaded original immutable; each operation writes a new, separately
  named output file (not an in-place overwrite). Files live in a per-job workspace and expire
  after a documented retention window (see `.claude/reference/api/skills/pdf_processing.md`).
- **States:** every async flow has explicit empty, loading, success, and recoverable-error UI
  states — no bare spinners with no error path.
- **Testing:** focused tests for the core PDF transformations (merge/split/compress/rotate/
  reorder) in `apps/api`, plus one end-to-end happy-path test through the web UI for one tool
  (compress is the reference-designed one, start there).
- **Docs:** a README per app covering setup, architecture, and the one command to run it
  locally; `.env.example` for `apps/api`, secrets never committed.
- **Finish** by actually running the tests and reporting the exact commands used.

## Deferred to a later phase (tracked, not forgotten)

- **PostgreSQL / job history / docker-compose.** Phase A's five operations are synchronous
  request/response (upload → process → return the file) with no job history yet, so there's
  nothing for a database to store — wiring up SQLAlchemy + Alembic + `docker-compose.yml` is
  deferred to whichever Phase B feature first needs persistent records. See
  `apps/api/README.md`.
- Watermark, redact, OCR, Office-to-PDF conversion.
- Signature mode with field placement, signer invites, consent recording, and final PDF hash
  sealing; an append-only event log with timestamps/hashes/delivery outcomes.
- File-level backup strategy beyond the retention window.
- Accounts, billing/premium tier, telemetry/analytics.
- Qualified/regulated e-signatures, government identity verification, full Acrobat-level
  editing/enterprise governance — deliberately out of scope entirely (not just deferred), per
  the original prompt.
