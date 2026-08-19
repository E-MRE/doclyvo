# Data Fetching & State — apps/web

## Server vs. client components

- Default to **server components**. Reach for `'use client'` only when a component needs
  interactivity (state, event handlers, browser APIs) — file upload widgets, progress UI,
  theme toggles.
- Fetch data in server components / server actions, not in a `useEffect` on the client, unless
  the data genuinely depends on client-only state.

## Talking to the backend

- **One API client** (`lib/api-client.ts`) wraps every call to the FastAPI backend
  (`apps/api`). No feature calls `fetch(...)` directly against a hardcoded backend URL — the
  base URL comes from an env var read once in `lib/api-client.ts`.
- Each feature's `actions.ts` calls `lib/api-client.ts`, never the reverse, and never skips it
  to call `fetch` inline in a component (mirrors the Flutter rule: no direct `Dio`/network
  calls inside a screen — always through a repository-equivalent layer).
- File uploads (PDF processing) go through server actions using `FormData`, not client-side
  `fetch` with the file directly, so the upload can be validated/sized server-side first.

## Client-side state

- Local UI state (which tab is active, is the dropzone hovering): `useState`, no external
  library needed.
- Cross-component state within one feature (e.g. multi-step compress flow): lift to the
  nearest shared client component, or a small `useReducer` — don't reach for a global store
  for feature-local state.
- If genuine cross-feature client state emerges (e.g. an app-wide theme toggle), that's the
  point to introduce a minimal solution (React context or Zustand) — don't add one
  preemptively.
- Async job status (a long-running compress/merge job): poll via a server action or use
  Server-Sent Events from `apps/api`, not client-side `setInterval` calling `fetch` directly —
  centralize the polling logic in one hook (`features/<tool>/hooks/use-job-status.ts`).
