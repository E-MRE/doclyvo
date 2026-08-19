# Do Not Do — apps/web

**Design system violations**
- Hardcoded hex color (`style={{ color: '#DC4731' }}`, `className="text-[#DC4731]"`) → use
  the `accent` theme token (`text-accent`).
- Arbitrary Tailwind spacing/radius values (`p-[13px]`, `rounded-[14px]`) → use the theme scale
  or extend it properly.
- A second styling system alongside Tailwind (styled-components, emotion, inline `style=`) →
  Tailwind only.

**Structure violations**
- A feature importing from another feature's folder → promote the shared piece to
  `components/` or `lib/`.
- A `features/shared/` or `features/common/` folder → doesn't exist, put it in `components/`
  or `lib/`.
- A component calling `fetch()` directly against a hardcoded backend URL → go through
  `lib/api-client.ts`.

**Rendering violations**
- `'use client'` on a component that doesn't need interactivity — check first whether it can
  stay a server component.
- SEO-critical copy that only renders after a client-side fetch — see
  `skills/seo_rendering.md`.

**General violations**
- `any` in TypeScript without a very good, commented reason.
- Default export on a component/hook/util (page/layout/route files are the sole exception).
- Catching an error and doing nothing with it (`catch {}`) — always surface it (UI state,
  log, or rethrow a typed error).
- A raw, generic error message shown to the user when the API returned a specific error code.
