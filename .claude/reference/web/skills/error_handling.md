# Error Handling — apps/web

## API error shape (must match `apps/api`'s error contract — see
`.claude/reference/api/skills/error_handling.md`)

- `lib/api-client.ts` throws a typed `ApiError { code: string; message: string; status: number }`
  for any non-2xx response — features never inspect a raw `Response` object or a raw fetch
  error.
- Server actions catch `ApiError` and return a discriminated result
  (`{ ok: true; data: T } | { ok: false; error: ApiError }`) to the client component — never
  let an action throw across the server/client boundary uncaught.

## UI error states

- Every async UI state has three branches: loading, error, success — same discipline as the
  Flutter side's `Initial/Loading/Success/Error`. Don't render a bare error string; use a
  shared `<ErrorState message retry={...} />` component (`components/ErrorState/`).
- User-facing error copy is specific to what failed (file too large, unsupported format,
  server unavailable) — never a generic "Something went wrong" when the API error code tells
  you more.
- Log unexpected errors (`console.error` in dev; wire to a real logging/monitoring service
  before production) — never swallow an error silently.
