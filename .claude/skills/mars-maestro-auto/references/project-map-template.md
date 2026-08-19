# Project map — <APP NAME>

Filled live during Phase 1 (explore). Keep current: if navigation/routing changes, refresh the
affected row before authoring against it. This is the single source of "where a screen is and how to
reach/anchor it". Scope to the target platform's build of each screen (e.g. mobile builder).

## Config
- appId: `<com.example.app>`
- device / platform: `<iPhone 15 sim | Pixel 7 emu>` · locale: `<en-US>`
- build + install command: `<the exact command, incl. env/flavor flags>`
- login: fields `<Email Address>` / `<Password>`, submit `<Login (index 1)>`, logged-out anchor
  `<Forgot password?>`, home anchor `<…>`
- first-run popups: `<welcome wizard | notif permission | in-app msg | none>`

## Screens
| Screen | Entry / route | Nav path (from Home) | Screen anchor (static) | goto subflow | Flows | Needs-id? |
|--------|---------------|----------------------|------------------------|--------------|-------|-----------|
| Home | `<launch/deeplink>` | — | `<durable label>` | — | smoke/app-launches | — |
| `<Screen A>` | `<…>` | `<tab/menu → …>` | `<anchor>` | `goto-a.yaml` | `<flow>` | `<control needing Semantics id, or —>` |
| `<Screen B>` | `<…>` | `<…>` | `<anchor>` | `goto-b.yaml` | `<flow>` | `<…>` |

## Streaming / live values (assert CHANGE, never a number)
- `<screen>`: `<which element ticks>` → sample twice + `v1 != v2`.

## Selector notes (this app)
- Duplicate-text collisions: `<"Login" heading vs button → index 1>`, …
- Multi-line accessibility text: `<"Orders\nTab 2 of 3" → 'Orders[\s\S]*' single-quoted>`, …
- Controls with added `Semantics(identifier:)`: `<id → widget file>`, …

## Known issues / findings
- `<bug or gap observed during explore>` → `<bugs/<name>.yaml or ticket>`
