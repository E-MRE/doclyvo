# Coding Standards — apps/web

- **TypeScript strict mode on** (`"strict": true` in `tsconfig.json`). No `any` — use
  `unknown` and narrow, or define the real type. No `// @ts-ignore` without a comment
  explaining why and a linked issue if it's a real gap.
- **ESLint:** `next/core-web-vitals` + `eslint-config-prettier` baseline; treat warnings as
  something to fix before merging, not ignore.
- Prefer `interface` for object shapes that might be extended, `type` for unions/aliases —
  don't mix conventions randomly within a file.
- **No default exports** for components/hooks/utils (named exports only) — default exports
  make renames and greps unreliable. Exception: `page.tsx`/`layout.tsx`/`route.ts`, which Next's
  App Router requires as default exports.
- Explicit return types on exported functions; inference is fine for local/inline functions.
- `const` over `let` always; never `var`.
- Async/await over `.then()` chains.
- Parallel data fetching with `Promise.all` when requests don't depend on each other — same
  rule as the Flutter side's `Future.wait()` preference.
