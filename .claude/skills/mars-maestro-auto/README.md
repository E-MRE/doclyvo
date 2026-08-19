# mars-maestro-auto — portable Flutter UI-test autopilot (Maestro MCP)

A **project-independent** Claude Code skill: drop it into any Flutter repo and it explores the app
live via the Maestro MCP server, builds a smoke-test suite of YAML flows, and — when a control has no
stable selector — adds `Semantics(identifier:)` keys to the Flutter source so it becomes testable.
No project assumptions are baked in; it self-configures on first use.

## Install into another project
1. Copy this folder to the target repo:
   `cp -R skills/mars-maestro-auto <other-project>/.claude/skills/`
2. Ensure the Maestro MCP server is available to Claude Code in that repo (it exposes
   `list_devices`, `start_device`, `launch_app`, `inspect_view_hierarchy`, `take_screenshot`,
   `tap_on`, `input_text`, `run_flow`, `run_flow_files`, `check_flow_syntax`, `back`, `stop_app`).
   Typically: `claude mcp add maestro --scope project -- maestro mcp` (needs Maestro CLI installed),
   then restart Claude Code.
3. In that repo, run `/mars-maestro-auto` (or say "bu projeye maestro kur / explore edip smoke yaz").

## What it does (see `SKILL.md`)
- **Phase 0 Configure** — detect appId + build command, scaffold `.maestro/`, discover login/landing
  live, get `bootstrap` green twice.
- **Phase 1 Explore** — log in, drive one live action at a time, screenshot every state, build a
  project map.
- **Phase 2 Smoke** — turn the core journey into `smoke/*` flows (static anchors only; live values
  proven by change, never by value), run each to green, promote stable ones to `regression/`.
- **Phase 3 Self-heal** — add `Semantics(identifier:)` keys in Dart when a selector is missing
  (rebuild + reinstall), then switch the flow to `id:`.

## Files
- `SKILL.md` — the behavioral spec (rules, phases, folder/tag contract).
- `references/subflow-templates.md` — `config.yaml` + bootstrap/login/dismiss-popups/goto starters +
  the streaming-change assertion + how to run via MCP.
- `references/key-injection-playbook.md` — safe, additive procedure to add accessibility ids.
- `references/project-map-template.md` — the per-screen map to fill and keep current.

## The only thing the user provides
`.maestro/.env` with a dedicated test `TEST_EMAIL` / `TEST_PASSWORD` (gitignored). Everything else the
skill discovers or builds itself.

## Guardrail
Verify-only: the sole source change it may make is adding accessibility ids. It never alters logic,
layout, or copy to pass a test; on a genuine defect it stops and reports (failure protocol).
