# Deployment — Render

Both `apps/api` and `apps/web` deploy to [Render](https://render.com)'s free tier, defined
declaratively in the root [`render.yaml`](../render.yaml) blueprint.

## Why Render

`ROADMAP.md` originally left the provider open between Render, Railway, and Fly.io. As of this
pass (2026-08-20), Railway and Fly.io have both dropped their free tiers (Railway is now a paid
usage-metered plan; Fly.io requires a credit card and bills per-second). Render is the only one
of the three with a genuinely free web service tier, so it's the pick — see the trade-off below.

**Free tier caveats to know going in:**

- Each free web service gets 512 MB RAM / 0.1 CPU. LibreOffice and Tesseract are both
  memory-hungry; under concurrent PDF-to-Word or OCR requests this is the first thing to hit a
  limit. Fine for low-traffic personal use, not for real concurrent load — revisit the ROADMAP.md
  hosting decision if that changes.
- Free services spin down after 15 minutes of inactivity; the next request pays a 30-60s
  cold-start penalty. This applies to both `doclyvo-api` and `doclyvo`.
- No persistent disk needed — `apps/api` was already designed stateless (per-request temp
  workspace, deleted after the response), which fits Render's free ephemeral filesystem exactly.

## What's deployed

- **`doclyvo-api`** — `apps/api`, deployed via `apps/api/Dockerfile` (Render `runtime: docker`).
  The Dockerfile installs `libreoffice-writer` (not the full `libreoffice` metapackage — Writer
  + core is all PDF-to-Word needs, and it's roughly half the image size) and
  `tesseract-ocr`/`tesseract-ocr-tur` on top of `ghcr.io/astral-sh/uv:python3.12-bookworm-slim`,
  then `uv sync --frozen` for the Python deps. `soffice` is on `PATH` in this Debian-based image
  (unlike the macOS Homebrew cask), so `LIBREOFFICE_BINARY=soffice` — the same default as
  `.env.example` — just works.
- **`doclyvo`** — `apps/web`, deployed as a native Render Node service (no Dockerfile
  needed): `npm ci && npm run build`, then `npm run start`. Next.js reads Render's injected
  `$PORT` automatically.

## First deploy

1. Push this repo to GitHub/GitLab (Render blueprints deploy from a connected repo).
2. In the Render dashboard: **New** → **Blueprint** → connect the repo → Render detects
   `render.yaml` at the root and proposes both services.
3. Confirm and deploy. First build will be slow (LibreOffice install + image build); expect
   several minutes.
4. **Check the assigned URLs.** `render.yaml` predicts `doclyvo-api.onrender.com` and
   `doclyvo.onrender.com` (Render's `<service-name>.onrender.com` pattern) and bakes those
   into each other's env vars (`CORS_ORIGINS` on the API, `API_BASE_URL` on the web app). If
   either name was already taken and Render assigned a different subdomain, update the *other*
   service's env var in the Render dashboard to match, then redeploy that service.
5. Verify: `curl https://doclyvo-api.onrender.com/health` → `{"status": "ok"}`, then open
   `https://doclyvo.onrender.com` and run one tool end-to-end (Compress is the simplest,
   PDF-to-Word/OCR are the best test of the LibreOffice/Tesseract install actually working in
   the container).

## Updating env vars later

`render.yaml` is the source of truth for non-secret config — edit it and push to change values
across deploys. There are no secrets to manage yet (no database, no API keys); if that changes,
use Render's dashboard env var UI (or a Render "environment group") rather than committing
secrets into `render.yaml`.

## Not covered here

PostgreSQL hosting is intentionally still not part of this pass. `apps/api` now has a database
integration — the `sign` tool's authenticated hash + audit-log path (see `apps/api/README.md`)
— but that path is unreachable in production today: no login system exists yet to issue the
bearer credential that turns it on, so it never runs. Adding a Render Postgres instance now
would be dead weight with nothing exercising it. When a real login system ships:

1. Render dashboard → **New** → **Postgres**, on the free tier to start.
2. Add the resulting connection string as `DATABASE_URL` on `doclyvo-api`'s env vars.
3. Run `uv run alembic upgrade head` against it once (from a machine that can reach it, or a
   one-off Render job) to create `audit_log_entries`.
