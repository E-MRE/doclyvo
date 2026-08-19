# apps/web — Coding Conventions

Reference knowledge base for `apps/web` (Next.js 15 + TypeScript), mirroring the spirit of
`.claude/reference/flutter/` for the native app: no hardcoded design values, feature-based
structure, one clear place for each kind of code.

`apps/web` has not been scaffolded yet. These are the conventions to apply from the first
commit, not a retrofit — `apps/web` starts compliant.

**Files:**
- `skills/project_structure.md` — App Router layout, feature folders, where code goes
- `skills/design_system.md` — design tokens (colors/spacing/radius/type), no hardcoded values
- `skills/naming_conventions.md` — file/component/hook naming
- `skills/data_fetching_state.md` — server vs. client components, API calls, state
- `skills/coding_standards.md` — TypeScript strictness, lint baseline, formatting
- `skills/error_handling.md` — API error shape, UI error states
- `skills/seo_rendering.md` — SSR/SSG strategy for tool landing pages (see `ROADMAP.md`'s SEO
  open item)
- `skills/do_not_do.md` — the concrete "never do this" list

**Cross-stack consistency:** the accent color (`#DC4731`), radius scale (12/16/20px), and
system-font-only typography already established in `design/README.md` for the Flutter/Claude
Design work apply here too — the web app should look like the same product, not a reskin.

**Assumptions made ahead of scaffolding** (revisit if the user picks differently once
`apps/web` is actually created):
- Styling: Tailwind CSS with a theme extension (not a CSS-in-JS library).
- No specific UI component library assumed (shadcn/ui is a reasonable default if one is
  wanted, but plain Tailwind + custom components is equally fine — decide when scaffolding).
