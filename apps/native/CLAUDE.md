# apps/native — Project Standards (read this first, every session)

This file is auto-loaded by Claude Code whenever the working directory is inside
`apps/native`. It exists so a **fresh session with zero prior context** can pick up
any task from `../../NATIVE-TASKS.md` and execute it correctly without re-deriving
the architecture from scratch.

## What this app is

Doclyvo's mobile (iOS/Android) + desktop (macOS/Windows/Linux) PDF toolkit — one
Flutter codebase, 11 tools (compress, merge, split, rotate, reorder, watermark,
protect, ocr, pdf-to-word, sign, redact) mirroring `apps/web` (Next.js, done) and
calling `apps/api` (FastAPI, done, deployed). No web/Flutter-web target.

**Architecture decision (hybrid, decided 2026-08-21):** 8 of the 11 tools run
entirely on-device via the `pdf_manipulator` package (MIT license, Rust engine,
ships prebuilt binaries for iOS/Android/macOS/Windows/Linux — no Rust toolchain
needed to build it) — **Merge, Split, Rotate, Reorder, Watermark, Compress,
Protect, Sign**. These make zero network calls; `apps/api` is not involved for them
at all, which is the whole point (avoids the free-tier backend's cold-start delay).
The remaining 3 — **Redact, OCR, PDF-to-Word** — keep calling `apps/api` over HTTP,
because their client-side equivalents are either unproven or genuinely missing: this
was a deliberate, risk-tiered decision, not an oversight. See the Decisions log in
`../../NATIVE-TASKS.md` for the full reasoning. **Do not** move these 3 to
client-side processing without re-running that feasibility research and getting
explicit sign-off first.

**Client-side PDF engine:** never import `pdf_manipulator` directly from a feature.
Go through the `PdfEngineService` abstraction in `lib/core/pdf/` (built in task
P0-11) — same reasoning as `NetworkService`/`AppDependency`: an unproven, very young
third-party dependency (published ~2026-07-30, small GitHub community as of this
writing) should sit behind one interface so a future swap or bug workaround touches
one file, not 8 features. Before implementing any client-side tool, read that
specific operation's method in the `pdf_manipulator` pub.dev README/example first —
this plan was written from its high-level capability list (merge, split, rotate,
reorder, watermark, compress, encrypt/decrypt, sign, redact, convert, render), not
verified exact method signatures. `pdf_manipulator` also covers page-thumbnail
rendering (its "render pages" capability) — there is no separate PDF preview
package; Rotate/Reorder use the same dependency for both manipulation and preview.

**Backend contract for the 3 remaining API-backed tools (Redact, OCR, PDF-to-Word):**
Every `/tools/<name>` endpoint is `POST`, multipart/form-data (`file` + form fields
for settings), and returns the **raw processed file as bytes** (`FileResponse` on the
backend), with metadata in custom response headers (e.g. `X-Original-Size`,
`X-Compressed-Size`) — NOT a JSON envelope. Configure Dio with
`ResponseType.bytes` for these calls and read `response.headers` for metadata; do not
assume `ApiResponseModel<TData>` JSON deserialization applies to tool-processing
endpoints. Confirm exact field names by reading that tool's
`apps/api/app/features/<tool>/router.py` + `schemas.py` before writing the repository.

## Mandatory architecture (non-negotiable — enforced by `.claude/reference/flutter/`)

Full detail lives in `../../.claude/reference/flutter/skills/*.md`. Read the specific
files your task lists — don't guess. Summary:

- **Layers:** `lib/app/` (router, DI wiring, theme, global config) → `lib/core/`
  (network, base classes, shared widgets, localization, zero upward imports) ←
  `lib/features/<feature>/` (data/domain/presentation per feature). `app/` imports
  only `core/`. `features/` import only `app/` + `core/`, never another feature.
  `lib/generated/` holds codegen output only.
- **State management:** `flutter_bloc`, Cubit-only (no Bloc event classes). Every
  cubit extends the house `BaseCubit<TState>` (`safeEmit`/`safeCall`, catches
  `ResponseException`/`JsonException`). 4-state pattern: Initial/Loading/Success/Error.
- **DI:** GetIt, but never imported directly outside `lib/core/dependency/`. Exposed
  to features only via the global final class `AppDependency`.
- **Networking:** Dio wrapped by abstract `NetworkService` → concrete
  `DioNetworkManager`. See backend-contract note above for the file-download shape.
- **Navigation:** `go_router`, single `final router = GoRouter(...)` in
  `lib/app/app_router.dart`, custom `TransitionPageBuilder` for transitions.
- **Localization:** `easy_localization`, Turkish only (`tr-TR`) for now,
  `LocalizationConfig` final class, `LocaleKeys` generated — no hardcoded UI strings.
- **Codegen:** `build_runner` drives `json_serializable`, `envied_generator`,
  `flutter_gen_runner`, `easy_localization` key generation. Run
  `dart run build_runner build --delete-conflicting-outputs` after adding
  models/env vars/assets/translation keys.
- **Widgets:** every widget class is `final class`, never plain `class`. No
  hardcoded `Colors.*`/`Color(0x...)` — go through the generated/theme color system.
  No hardcoded `EdgeInsets`/`BorderRadius` numbers — go through the spacing/radius
  token system (`Sizes`/`AppInsets`).
- **Tests:** `test/` mirrors `lib/` directory structure exactly. Any widget test
  that pumps a real screen goes through `test/helpers/widget_test_harness.dart`
  (`initializeTestLocalization`, `registerAppDependencies`/`resetAppDependencies`,
  `pumpLocalized(..., surfaceSize:)`) — hand-rolling `pumpWidget` +
  `LocalizationWrapper` fails on GetIt, on `shared_preferences`, or on the
  translation asset loading off the real event loop.

## Responsive layout: the mid-width overflow trap (read before writing any screen)

`ResponsiveConstants.mobileBreakpoint` is **700**, and screens pick their layout with
a single `isMobile` bool. That means every width from 700px up renders the *desktop*
branch — including a resized desktop window, a landscape tablet, and a split-view
iPad, none of which are anywhere near the 1440px the designs in `design/*.dc.html`
are drawn at. Desktop content laid out at 700–1100px overflows, and Flutter treats a
`RenderFlex` overflow as an **error**, not as harmless clipping.

This has already bitten three home-screen widgets (all fixed — copy the fix, don't
re-derive it):

- **A `Row` of buttons or nav items that must fit on one line.** Either add a third
  tier that drops the optional items below a measured breakpoint (`HomeHeader` +
  `ResponsiveConstants.headerNavBreakpoint`), or swap `Row` → `Wrap` with
  `spacing`/`runSpacing` so items fall to a second line (`HomeHeroSection`'s CTAs).
  Measure the real threshold — pump the widget inside `IntrinsicWidth` at a huge
  surface and read `tester.getSize` — instead of guessing a round number.
- **Text inside a fixed-height cell.** `ToolGrid` positions cards at a fixed cell
  height, so `ToolCard`'s title/description carry `maxLines` + `TextOverflow.ellipsis`.
  Any text in a `Positioned`/`SizedBox`-constrained box needs the same.

**Required for every new screen:** a width-sweep test like
`test/features/home/presentation/pages/home_screen_responsive_test.dart` — pump the
screen at 360/430/699/700/800/900/1024/1080/1200/1440/1920 via
`pumpLocalized(..., surfaceSize:)` and assert `tester.takeException()` is `null`.
Note that `pumpLocalized` defaults to a 1440x1024 surface and the raw
`flutter_test` default is 800x600; neither one on its own catches this class of bug.

## Design source

- `../../design/README.md` — design tokens (colors, spacing, radius, typography,
  motion) and the "Compress-as-template" pattern (every tool follows the same
  upload → settings → processing → result flow).
- `../../design/<Tool>.dc.html` / `../../design/Mobile<Tool>.dc.html` — desktop and
  mobile Claude Design canvas exports, one pair per screen. Read only the ones your
  current task names.
- `../../design/StyleGuide.dc.html` — full token/component reference.
- Accent color `#DC4731`; radius 16 (cards) / 12 (buttons/panels); spacing scale
  4/8/12/16/24/32; system font stack; motion respects `prefers-reduced-motion`.

## How to work a task from NATIVE-TASKS.md

1. Read this file (you just did).
2. Open `../../NATIVE-TASKS.md`, find your assigned task ID, read only that task's
   section.
3. Read exactly the "Key inputs" files that task lists (reference skill docs, design
   files, API router+schemas, web feature folder for behavior parity) — don't read
   unrelated tasks' inputs, and don't skip the ones listed.
4. Before implementing a new feature module, also skim
   `../../.claude/reference/flutter/patterns/feature_creation_flow.md` and
   `../../.claude/reference/flutter/prompts/feature_creation_prompt.md` — they encode
   the exact file-by-file order the house convention expects.
5. Implement only what the task's "Deliverables" list names. Do not start a
   dependent task's work — leave it for its own session.
6. Verify against the task's "Definition of Done" checklist before finishing. Run
   `flutter analyze` and `flutter test` if the task touches testable code.
7. Do not mark ROADMAP.md/NATIVE-TASKS.md checkboxes yourself unless the task
   explicitly says to — leave status updates to the orchestrating session.

## Do not

- Do not add Flutter web support.
- Do not call the backend for the 8 client-side tools (Merge, Split, Rotate,
  Reorder, Watermark, Compress, Protect, Sign) — they must work fully offline via
  `pdf_manipulator`/`PdfEngineService`.
- Do not move Redact, OCR, or PDF-to-Word to client-side processing without
  re-validating `pdf_manipulator`'s real-world output quality first (see the
  Decisions log in `NATIVE-TASKS.md`) — this was a deliberate, revisitable risk call.
- Do not import `pdf_manipulator` (or `dio`/`get_it`) directly from a feature —
  always go through the `PdfEngineService`/`NetworkService`/`AppDependency`
  abstractions.
- Do not invent new architecture/state-management/DI approaches — everything above
  is fixed by `.claude/reference/flutter/`.
- Do not hardcode strings, colors, or spacing — see rules above.
