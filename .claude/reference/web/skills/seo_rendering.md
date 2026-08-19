# SEO & Rendering Strategy — apps/web

This is the reason the web app is Next.js rather than Flutter Web (see
`ROADMAP.md`/`project-doclyvo-architecture` memory) — don't undermine it with client-only
rendering on the pages that need to rank.

- **Tool landing pages** (`app/tools/[tool]/page.tsx` and the marketing home page) must be
  server-rendered with real content in the initial HTML — no "loading skeleton then client
  fetch" for the copy/headline/description search engines need to see.
- Use Next's `generateMetadata` per tool page for title/description/OpenGraph — not a single
  static `<title>` shared across all tool pages.
- Static-generate (`generateStaticParams`) the tool landing pages where content doesn't depend
  on a live session — they're the same for every visitor until the tool itself is opened.
- The actual file-processing UI (upload, progress, result) is a client component *inside* the
  server-rendered page shell — SEO copy lives outside it, not gated behind the interactive
  part mounting.
- Don't add a client-side router redirect for the canonical tool URL — resolve it server-side.
