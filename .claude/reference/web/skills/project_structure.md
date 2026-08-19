# Project Structure — apps/web

Feature-first, same philosophy as the Flutter side: a feature is a vertical slice, not spread
across horizontal layers.

```
apps/web/
├── app/                        → Next.js App Router — routes only, thin
│   ├── (marketing)/            → SEO-critical static/SSR pages (home, tool landing pages)
│   ├── tools/[tool]/           → dynamic route that renders a tool's feature module
│   ├── api/                    → route handlers ONLY if a server action can't do the job;
│   │                             prefer calling apps/api (FastAPI) directly from server
│   │                             components/actions over proxying through here
│   └── layout.tsx, globals.css
├── features/                   → one folder per tool/feature (merge, compress, sign, ...)
│   └── <feature>/
│       ├── components/         → feature-local UI, not reused elsewhere
│       ├── hooks/               → feature-local hooks (use-<thing>.ts)
│       ├── actions.ts           → server actions / API calls for this feature
│       └── types.ts
├── components/                 → shared, cross-feature UI (Button, Card, UploadDropzone...)
│   └── <ComponentName>/
│       ├── <ComponentName>.tsx
│       └── index.ts
├── lib/                        → cross-cutting utilities, API client, config — the "core"
│   ├── api-client.ts            → the ONLY place that knows the FastAPI base URL
│   ├── design-tokens.ts          → re-exports Tailwind theme values for use in TS logic
│   └── utils.ts
├── styles/ (or tailwind.config.ts at root)
└── public/
```

**Dependency direction (mirrors the Flutter rule):** `features/ → components/`,
`features/ → lib/`, `components/ → lib/`. `lib/` never imports from `features/` or
`components/`. **Features never import from another feature** — if two tools genuinely need
the same piece of UI/logic, promote it to `components/` or `lib/`.

There is no `features/shared/` or `features/common/` folder — same rule as the Flutter side.

**Where does new code go?**

| What | Where |
|---|---|
| A component used by exactly one feature | `features/<x>/components/` |
| A component used by 2+ features, or generic (no feature-specific types) | `components/` |
| A hook only feature `<x>` needs | `features/<x>/hooks/` |
| A hook any feature could use (`useDebounce`, `useFileUpload`) | `lib/hooks/` |
| Design tokens, API client, generic helpers | `lib/` |
| A new tool's page | `app/tools/[tool]/page.tsx` + a `features/<tool>/` folder |
