# Doclyvo — repo-wide instructions

Auto-loaded in every session, from any working directory in this repo. It holds only
what applies to **all three apps**; each app's own rules live next to it:

- `apps/native/CLAUDE.md` — Flutter app (architecture, responsive tiers, task flow).
  Also read `.claude/reference/flutter/`.
- `apps/web/` — Next.js frontend. See `.claude/reference/web/`.
- `apps/api/` — FastAPI backend. See `.claude/reference/api/`.

Task breakdowns live in `NATIVE-TASKS.md` and `ROADMAP.md`.

## Code discovery: query the graph before you read files

This repo is indexed in the **codebase-memory MCP server** under the project name
`doclyvo` — one index covering the repo root, so `apps/native`, `apps/web` and
`apps/api` are all in it. That index is a symbol graph — classes, functions, call
edges, routes — and answering "where is X" from it costs a fraction of what reading
or grepping the tree costs. Make it the default way to locate code; fall back to
`Read`/`Grep`/`Glob` for what the graph does not hold.

**Before you start a task — check freshness, do not re-index:**

1. `index_status(project: "doclyvo")` — expect `status: "ready"`, then compare its
   `git.head_sha` against `git rev-parse HEAD`.
2. Shas match → the graph is current. Start querying.
3. Shas differ → `detect_changes(project: "doclyvo", since: "<indexed head_sha>")`.
   If a handful of files moved, keep using the graph and `Read` those specific files
   directly. Only if the drift is large — or `index_status` reports the project
   missing — run `index_repository(repo_path: "<repo root>", mode: "fast")` first.

Indexing is the expensive operation and the graph is normally already current, so a
routine full re-index at session start is wasted work. The freshness check above is
what belongs at the start.

**After you finish a task — re-index, once your changes are committed:**

`index_repository(repo_path: "<repo root>", mode: "fast")`

Your work is exactly what made the graph stale, so pay that cost here, at the end,
where it buys the next session a current graph for free. Treat this as the last step
of any task that added, deleted, renamed, or moved a symbol — in Dart, TypeScript or
Python alike. Skip it only when nothing about the code graph changed (docs,
translation strings, task-file status edits).

**Which tool answers which question:**

| You want | Use |
| --- | --- |
| Find a class/component/route/repository by name or naming pattern | `search_graph(name_pattern:, label:, qn_pattern:)` |
| The source of one symbol you can already name | `get_code_snippet(qualified_name:)` — precise ranges, cheaper than reading the whole file |
| Who calls this / what this reaches, including across the web↔api boundary | `trace_path(function_name:, mode: "calls" \| "data_flow" \| "cross_service")` |
| Layer and feature layout, module boundaries | `get_architecture(aspects:)` |
| A text or regex sweep across code | `search_code(pattern:)` (graph-augmented grep) |
| Anything the above cannot express | `query_graph(query:)` (Cypher) |

**Keep reading files directly for:** everything that is not source code —
`pubspec.yaml`, `package.json`, `requirements.txt`, `apps/native/assets/translations/*.json`,
`design/*.dc.html`, the `CLAUDE.md` files, `NATIVE-TASKS.md`, `ROADMAP.md`,
`.claude/reference/**/*.md` — and **always `Read` a file in full before you `Edit`
it**. A graph snippet shows you a symbol, not the surrounding code you are about to
change.

**Subagents inherit none of this.** A fresh subagent has empty context and will reach
for `Grep` by default. When you spawn one, name the MCP tools it should use and give
it the project name `doclyvo` in its prompt.
