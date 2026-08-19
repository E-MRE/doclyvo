# apps/web

Doclyvo's web application — Next.js 15, TypeScript, Tailwind CSS v4, App Router.

**Phase A scope (current):** the Compress and Merge tools, implemented from
`design/Compress.dc.html` and `design/Merge.dc.html`. Split/rotate/reorder have API support in
`apps/api` but no web UI yet (not designed — see `design/README.md`'s known gaps). See
`../../docs/build-prompt-web-mvp.md` for the full scope rationale and
`../../.claude/reference/web/` for the coding conventions this app follows.

## Setup

```bash
npm install
cp .env.example .env
```

`apps/api` must be running (see `../api/README.md`) — `API_BASE_URL` in `.env` points at it.

## Run it

```bash
npm run dev
```

Open `http://localhost:3000`.

## Architecture

- `app/` — routes only (`page.tsx`, `layout.tsx`, `app/tools/<tool>/page.tsx`), server-rendered
  by default so tool landing pages stay crawlable.
- `features/<name>/` — one folder per feature (`home`, `compress`, `merge`): feature-local
  components, a server-action `actions.ts` that's the only thing calling `lib/api-client.ts`,
  and `types.ts`.
- `components/` — shared, cross-feature UI (`Header`, `ErrorState`, `UploadDropzone`).
- `lib/api-client.ts` — the one place that knows the FastAPI base URL and turns non-2xx
  responses into a typed `ApiError`.
- `app/globals.css` — the Tailwind v4 `@theme` block with every design token (accent color,
  radius scale, light/dark surface colors) — see `.claude/reference/web/skills/design_system.md`
  for the no-hardcoded-values rule this file exists to satisfy.

Each tool page renders explicit empty → idle → processing → done/error UI states — see
`.claude/reference/web/skills/error_handling.md`.

## Testing

End-to-end (spins up both `apps/api` and `apps/web` automatically):

```bash
npm run test:e2e
```

Type checking and lint:

```bash
npx tsc --noEmit
npm run lint
```
