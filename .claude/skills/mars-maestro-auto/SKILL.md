---
name: mars-maestro-auto
description: >
  Project-agnostic autonomous UI-testing skill for ANY Flutter app driven live through the
  Maestro MCP server. Drop this skill folder into a project and it: (1) self-configures — detects
  the appId, picks a device, learns the build command; (2) logs in and EXPLORES the app on its own,
  screenshotting every major state and building a reusable project map; (3) AUTHORS a smoke-test
  suite of Maestro YAML flows for the core journey; (4) SELF-HEALS fragile selectors by editing the
  Flutter source to add `Semantics(identifier:)` keys (with a rebuild) when a control has no stable
  text/id anchor. Uses ONLY the Maestro MCP tools + the live UI — writes no Dart tests (it versions
  YAML flows and, when needed, adds accessibility ids to widgets). ALWAYS trigger when the user says
  "maestro autopilot", "otonom smoke kur", "explore edip smoke test yaz", "bu projeye maestro kur",
  "set up maestro and build smoke tests", "keşfet ve test üret", "/mars-maestro-auto", or drops this
  skill into a new repo and asks it to test the app by itself. Distinct from `mars-maestro-add`
  (which adds ONE targeted E2E test to a known screen): this one carries NO project assumptions and
  autonomously configures, explores, builds the smoke suite, and self-heals selectors live.
invocation: /mars-maestro-auto, /maestro-auto, /maestro-autopilot
---

# Mars Maestro Auto — portable, self-configuring UI test builder

You drive a **live Flutter app** through the **Maestro MCP** server, explore it, and leave behind a
runnable smoke suite. You write **no Dart test code**. You version **YAML flows** under `.maestro/`,
and — only when a control cannot be selected reliably — you add `Semantics(identifier:)` keys to the
app's Dart widgets so Maestro can see them. Everything you know about the app you learn **live**, by
`inspect` + `screenshot`, never from memory.

This skill is **project-independent**. Nothing here names a specific app. On first use in a repo you
CONFIGURE (Phase 0), then EXPLORE (Phase 1), then BUILD SMOKE (Phase 2), self-healing selectors along
the way (Phase 3). Read `references/` before acting:
- `references/subflow-templates.md` — copy-paste `config.yaml`, `bootstrap`, `login`, `dismiss-popups`,
  `goto-<screen>` starters.
- `references/key-injection-playbook.md` — the exact, safe procedure to add `Semantics(identifier:)`
  in Flutter when a selector is missing (mirrors the pattern this skill relies on).
- `references/project-map-template.md` — the per-screen map you fill in and keep current.

---

## Non-negotiable rules (learned the hard way)

1. **MCP + UI only.** Everything through the Maestro MCP tools (`list_devices`, `start_device`,
   `launch_app`, `inspect_view_hierarchy`, `take_screenshot`, `tap_on`, `input_text`, `run_flow`,
   `run_flow_files`, `check_flow_syntax`, `back`, `stop_app`). Call `cheat_sheet`/`query_docs` when
   unsure of syntax.
2. **Never author a selector without inspecting first.** `inspect` → read the real tree → pick the
   selector. Re-inspect after EVERY navigation; stale trees cause false matches.
3. **Selector priority:** (a) a registered `Semantics(identifier:)` id → `id:` selector; (b) stable
   visible text from the app's own locale strings; (c) as a LAST resort a `point:` tap — and if you
   used a point, that control is a self-heal candidate (Phase 3).
4. **Never assert on live/streaming numbers** (prices, balances, P/L, timers). Assert static labels.
   To prove a value is *live*, sample it twice and assert it **changed** (`copyTextFrom` ×2 +
   `evalScript` + `assertTrue v1 != v2`) — never assert a specific number.
5. **Credentials come from `.maestro/.env`** (gitignored), injected at run time via the MCP `env`
   param / `-e`. NEVER inline credentials or secrets in a flow.
6. **Locale contract:** run the device in a single known locale (default en-US) and take every text
   selector from the app's own locale asset for that language. State the locale in `config.yaml`.
7. **Text matching:** YAML `assertVisible`/`tapOn: "…"` is FULL-regex (exact) — `"Trade"` will not
   match `"Trades"`. The MCP `tap_on` tool fuzzy-matches by default — pass `use_fuzzy_matching:false`
   when you need exactness. Multi-line accessibility text (common on iOS tabs, e.g. `"Orders\nTab 2
   of 3"`) → match with a `[\s\S]*` tail in **single quotes** (double quotes break on the backslash).
   Duplicate visible text (e.g. a heading and a button both "Login") → disambiguate with `index:`.
8. **Failure protocol (always on):** if a flow fails or the app gets stuck (can't reach the next
   screen, endless skeleton/flicker), **STOP** — do not retry blindly or navigate around it.
   `take_screenshot` → `.maestro/reports/errors/NN-<step>.png`, report the failing step + what was on
   screen + the log line, then wait. A stuck screen is itself a finding.
9. **New `Semantics(identifier:)` ids require a fresh build + reinstall** before Maestro can see them
   (they compile into the widget tree). Budget for the rebuild; never assume a just-added id is live.
10. **Environment gotcha:** many apps default to a dev/empty environment on a FRESH install and login
    can then silently fail (correct creds, button enabled, no spinner/error/nav). Before a
    fresh-install run, get the app onto the env your test account lives on (in-app env switcher, saved
    prefs, or a build whose baked env matches), and confirm one manual login. Reinstall wipes that
    choice — re-select after any reinstall. If login does nothing, suspect env before selectors.

---

## Phase 0 — Configure this project (run once)

Goal: reach a **known logged-in home** and record how, so every later flow starts with one line.

1. **Detect the app + toolchain (from the repo, not memory):**
   - appId / bundleId: `ios/Runner/Info.plist` (`CFBundleIdentifier`), `android/app/build.gradle`
     (`applicationId`), or an existing `.maestro/config.yaml`.
   - Flutter present: `flutter --version` (or the repo's `fvm`/absolute path).
   - Build + install command: check `README`, `Makefile`, `pubspec.yaml` scripts, `.vscode/launch.json`
     for the env/flavor flags (e.g. `--dart-define…`, `--flavor`, `--dart-define-from-file`). Record the
     exact command — you'll need it after any Dart edit. If the app uses generated env
     (`envied`/`--dart-define`), note it: a plain build may point at the wrong environment (see rule 10).
2. **Scaffold `.maestro/`** from `references/subflow-templates.md`: `config.yaml` (appId, flow globs,
   locale), `.env.example`, `subflows/{bootstrap,login,dismiss-popups}.yaml`, and empty
   `smoke/ regression/ bugs/ features/ reports/` dirs. Ask the user to fill `.maestro/.env` (copy from
   `.env.example`) — that is the ONLY thing they hand over.
3. **Device:** `list_devices` → pick or `start_device` (correct locale). Ensure a fresh build is
   installed (rule 10 — get onto the working env, confirm one manual login).
4. **Discover login + landing live:** `launch_app` → `inspect` → fill `login.yaml` with the real field
   labels + submit control (resolve duplicate-text with `index:`), and set the logged-out anchor (a
   string unique to the login screen — NOT one shared with a button) and the home anchor in
   `bootstrap.yaml`. Handle first-run popups (welcome wizard, notification/tracking permission,
   in-app messaging, biometric prompt) in `dismiss-popups.yaml`.
5. **Prove it:** run `bootstrap.yaml` (with env creds) to a known home **twice in a row** green.
6. Start the project map (`references/project-map-template.md`).

---

## Phase 1 — Explore autonomously (screenshot every state)

The user gives a goal (or "just map the app"); you drive live and never ask for step-by-step taps.

1. `bootstrap` → home. Standing directive for the whole run: **`take_screenshot` after every major
   state** — after each navigation, text input, and result screen — to
   `.maestro/reports/explore-<area>/NN-<label>.png`, numbered so the sequence reads as a storyboard.
2. Loop, one action at a time, always from the live tree: `inspect` → choose the single next action
   (`tap_on`/`input_text`/`swipe`/`scrollUntilVisible`/`back`) from what is actually on screen → act →
   screenshot → re-inspect. Never batch from memory.
3. Walk the core journey: the bottom-nav / primary destinations, one representative deep screen each,
   the main create/submit flow, and the main list/detail. Flag anything empty/broken/unexpected as you
   pass it (that's a finding, and maybe a bug repro).
4. As you go, fill the **project map**: per screen record route/entry, nav path, a durable screen
   anchor, and the selectors you'd use. Mark every control you could only reach by `point:` — those
   feed Phase 3.
5. Report the state sequence with screenshot paths + findings.

---

## Phase 2 — Build the smoke suite

Turn the explored core journey into runnable flows.

1. Pick the **critical path** (the journey that must never break): launch → login → home → the 1–3
   primary destinations → the main create-or-submit flow → a list/detail assertion → (optional)
   logout. Keep it to what a human would smoke-check before shipping.
2. Author flows under `smoke/` (each starts `- runFlow: ../subflows/bootstrap.yaml`, reuses
   `goto-<screen>.yaml`). Assert **static anchors** only; use the streaming-change pattern (rule 4) for
   any "is it live?" check. `check_flow_syntax` each flow, then run it live to green with `run_flow` /
   `run_flow_files`. Re-inspect after every UI step.
3. Iterate each flow to green. On a genuine app defect, STOP per rule 8, save a repro under `bugs/`,
   report — don't paper over it.
4. Promote stable, re-run-green flows to `regression/` (tags `[regression, <area>]`). The regression
   set only grows. Record a screenshot at each key moment; optionally a video.
5. Update the project map + a short `reports/<run>.md`: what was explored, flows added, selectors that
   needed self-heal (Phase 3), and anything left blocked.

---

## Phase 3 — Self-heal selectors by adding Flutter keys (only when needed)

When a control has **no stable selector** (icon-only, no text, ambiguous, or you had to `point:` tap),
make it testable by adding a `Semantics(identifier:)` key in the app's Dart source — exactly the
pattern that lets Maestro select it via `id:`. Follow `references/key-injection-playbook.md`:

1. Confirm the gap live: `inspect` shows the control with no `resource-id` and no unique text.
2. Locate the widget in `lib/` (grep the nearby visible label, asset name, or callback).
3. Add/extend a **central id registry** (a `SemanticKeys`-style `abstract final class` of snake_case
   string constants) so ids are declared once, never inlined.
4. Wrap the control: `Semantics(identifier: SK.<name>, child: <the tappable widget>)`. Keep it additive
   and invisible — never change layout or behavior to make a test pass.
5. `dart format` + `dart analyze` the changed files (must be clean).
6. **Rebuild + reinstall** with the recorded build command (rule 9), relaunch, and re-inspect to
   confirm the id now surfaces as a native accessibility id.
7. Switch the flow to the `id:` selector; re-run to green.

Scope discipline: add ids ONLY for controls a smoke flow actually needs. Prefer stable visible text
when it exists. One central registry, snake_case, area-prefixed (e.g. `alert_expand_button`).

---

## Folder & tag contract (created in Phase 0)

```
.maestro/
├── config.yaml            appId, flow globs, locale
├── .env / .env.example    TEST_EMAIL / TEST_PASSWORD (real .env gitignored)
├── subflows/              bootstrap, login, dismiss-popups, goto-<screen>
├── smoke/       [smoke]        critical path — must always be green
├── regression/  [regression]  promoted, stable — only grows
├── bugs/        [bug]         repros (pre-fix)
├── features/    [feature]     new-screen tests
└── reports/                   screenshots / video / run notes (gitignored)
    └── errors/                failure-moment screenshots (failure protocol)
```

## Output (every run)
A short `reports/<run>.md` + chat summary: **Explored** (screens, screenshot paths) · **Suite**
(flows added/promoted, tags) · **Self-heal** (ids added + files, or "none needed") · **Result**
(✅/❌/⚠️ per flow) · **Blocked** (failing step, on-screen state, log excerpt — no code fixes beyond
additive keys unless asked). Tight and scannable.
