# Design System — apps/web

**Rule: no hardcoded color, spacing, radius, or font-size in a component.** Every value comes
from the Tailwind theme, which itself mirrors the tokens already established in
`design/README.md` (the Claude Design canvas source of truth).

## Tailwind theme extension (`tailwind.config.ts`)

```ts
theme: {
  extend: {
    colors: {
      accent: { DEFAULT: '#DC4731', hover: 'color-mix(in oklch, #DC4731 85%, black)' },
      // light theme
      bg: '#F5F5F7', surface: '#FFFFFF', border: '#D2D2D7',
      text: '#1D1D1F', 'text-soft': '#6E6E73',
      // dark theme equivalents go on the `dark:` variant, not a second token set —
      // Tailwind's `dark:` modifier IS the theme switch, don't hand-roll one
    },
    borderRadius: { card: '16px', panel: '12px', capsule: '10px' },
    fontFamily: {
      sans: ['-apple-system', 'BlinkMacSystemFont', 'SF Pro Text', 'Helvetica Neue', 'Arial', 'sans-serif'],
    },
  },
}
```

- Use `dark:bg-black dark:text-[#F5F5F7]` etc. for dark mode — Tailwind's built-in dark
  variant, not a custom theme context (keep it simple; there's no per-component theming need
  here like Flutter's `ThemeExtension`).
- Component code uses the semantic class (`bg-surface`, `text-text-soft`, `rounded-card`),
  never a raw hex (`bg-[#FFFFFF]`) or an arbitrary Tailwind value (`p-[18px]`) — if the scale
  doesn't have the value you need, add it to the theme extension, don't inline it.
- Spacing: stick to Tailwind's default scale (multiples of 4px: `p-4`, `gap-6`, ...) — don't
  invent a parallel spacing token file; Tailwind's scale already is the token system as long as
  arbitrary values are avoided.
- `lib/design-tokens.ts` re-exports the same hex/radius values as plain TS constants for the
  rare case logic (not JSX className) needs the raw value (e.g., an inline SVG `stroke`
  attribute, or a canvas draw call) — this is the ONE place a hex literal is allowed to exist.

## Component styling rules

- No inline `style={{ color: '#...' }}` — ever. If Tailwind's utility classes truly can't
  express something, add it to the theme extension instead of reaching for `style`.
- No third CSS-in-JS layer (styled-components, emotion) — Tailwind only, to avoid two
  competing styling systems.
- Icons: inline SVG, stroke-based, 1.5–2px stroke width, 24px grid — same visual language as
  the Claude Design source (see `design/README.md`), not a random icon library mixed in.
