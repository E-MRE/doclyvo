# Flutter Reference Knowledge Base

This folder is the shared Flutter convention and knowledge base for this repo.
The `mars-*` skills read the relevant files here **before** acting, so that
generated and refactored code follows one consistent set of architecture,
naming, state-management, and design-system rules.

It captures Feature-First Clean Architecture conventions, folder taxonomy,
networking/error-handling patterns, and review checklists as explicit,
reusable heuristics rather than tutorials.

## Subfolders

- `skills/` — Core engineering knowledge: architecture, project structure,
  coding standards, naming, dependency injection, state management, navigation,
  networking, error handling, models/mapping, performance, testing, design
  system, widget patterns, responsive rules, localization, build_runner,
  extensions/utils, and a `do_not_do.md` of anti-patterns.
- `patterns/` — Decision heuristics: widget decomposition, folder decision
  rules, feature creation flow, and shared-vs-local widget rules. Describes how
  structural decisions are made and when abstractions are introduced.
- `reviews/` — Validation checklists (code review, architecture, performance)
  used to sanity-check any implementation before it is accepted.
- `prompts/` — Reusable task templates for AI agents: feature creation, bugfix,
  refactor, and code review. Each enforces reading the relevant `skills/` files
  first and following repo conventions over generic best practices.
- `examples/` — Real good/bad code samples with `good/` and `bad/`
  subfolders; each bad example notes why it is bad and what to do instead.

## Placeholders

This content was genericized from a real production Flutter project. Project-
specific identifiers and PII were replaced with placeholders — substitute them
for your project when applying the guidance:

- `<app>` — the Dart package/import name (e.g. `package:<app>/...`)
- `<AppName>` — the human-facing application name
- `<team>` — the owning team or organization
- `<user>` — a sample user/display name in examples

Everything else is intentionally project-agnostic technical guidance.
