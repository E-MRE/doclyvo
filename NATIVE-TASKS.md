# Doclyvo Native (Flutter) — Task Breakdown

Status: planning complete, implementation not started. `apps/native` is currently a
bare `flutter create` scaffold (default counter-app template) — see
`apps/native/README.md`.

**Purpose of this file:** each task below is meant to be handed to a **separate,
fresh Claude Code session with empty conversation context**. A session working a
task should:

1. Read `apps/native/CLAUDE.md` first (auto-loaded when cwd is inside `apps/native`
   — always do this even if it wasn't auto-injected, e.g. when cwd is the repo root).
2. Read only this task's own section below.
3. Read only the "Key inputs" files this task lists.
4. Implement only what "Deliverables" lists, verify against "Definition of Done",
   then stop — do not start the next task.

Do not skip step 1. All architecture rules (Cubit-only state management, GetIt
behind `AppDependency`, Dio behind `NetworkService`, go_router, easy_localization,
build_runner codegen, `final class` widgets, no hardcoded colors/spacing/strings)
live there and in `.claude/reference/flutter/skills/*.md` — they are not repeated
in full here.

## Architecture: hybrid client/backend split (decided 2026-08-21)

Not all 11 tools work the same way. See the Decisions log at the bottom for the
full reasoning; the short version:

- **8 tools run fully on-device, no network call at all:** Merge, Split, Rotate,
  Reorder, Watermark, Compress, Protect, Sign — via the `pdf_manipulator` package
  (MIT, prebuilt binaries per platform, no Rust toolchain needed), wrapped by a
  house `PdfEngineService` abstraction (task P0-11). This is Phase 3A below.
- **3 tools keep calling `apps/api` over HTTP:** Redact, OCR, PDF-to-Word — their
  client-side equivalents are unproven (redaction quality, OCR accuracy/bundle
  size) or genuinely missing (real PDF→DOCX layout fidelity). This is Phase 3B
  below, and it's where the original all-backend contract still applies:
  every `/tools/<name>` endpoint is `POST` multipart/form-data, returns the
  processed file as **raw bytes** with metadata in response headers (e.g.
  `X-Original-Size`) — not a JSON envelope. See `apps/native/CLAUDE.md` for detail.

**Both flows share the same UI shell** (Phase 2's upload/progress/result/error
widgets) — only the "how do I actually get the output bytes" step differs between
Phase 3A (call `PdfEngineService` locally) and Phase 3B (call `NetworkService`
against the backend).

**Dependency graph:** Phase 0 tasks are sequential (each builds on the last, except
P0-11 which only needs P0-1+P0-3 and can be done any time after those). Phase 1
depends on all of Phase 0. Phase 2 depends on Phase 0+1. Phase 3A tasks depend on
Phase 0+1+2 **and P0-11** specifically; Phase 3B tasks depend on Phase 0+1+2 **and
P0-4** (network layer) specifically. Tasks within 3A or within 3B don't depend on
each other — any order or parallel sessions, ordered simplest-first here. Phase 4
depends on all of Phase 3A + 3B.

---

## Phase 0 — Foundation

Nothing in later phases compiles without this phase. Work these **in order** (P0-11
is the one exception — see its own dependency note), one session per task (or
combine adjacent small ones into one session if it stays focused — do not skip
ahead).

### P0-1 — Dependencies & lint baseline

**Goal:** add every package the rest of the plan needs, once, so later tasks never
have to reach for a random package on their own.

**Depends on:** none.

**Key inputs:**
- `.claude/reference/flutter/skills/build_runner_rules.md`
- `.claude/reference/flutter/skills/coding_standards.md`
- `.claude/reference/flutter/skills/project_structure.md`
- current `apps/native/pubspec.yaml`, `apps/native/analysis_options.yaml`

**Deliverables:**
- `pubspec.yaml` updated with: `flutter_bloc`, `go_router`, `easy_localization`,
  `dio`, `get_it`, `json_annotation`/`json_serializable`, `envied`/`envied_generator`,
  `flutter_gen_runner` (dev), `build_runner` (dev), and **`pdf_manipulator`** (the
  client-side PDF engine — covers manipulation AND page-thumbnail rendering, no
  separate preview package needed; see `apps/native/CLAUDE.md`). Follow its pub.dev
  setup instructions for native platforms (it downloads a prebuilt binary on first
  build — verify this actually happens cleanly on at least one platform before
  moving on, since the whole hybrid plan depends on this working).
- `analysis_options.yaml` aligned to house lint baseline (`very_good_analysis` or
  whatever `coding_standards.md` specifies).
- `build.yaml` if the codegen tools need one.
- `scripts/build.sh` per `build_runner_rules.md` if that convention expects a script.

**Definition of done:**
- `flutter pub get` succeeds with no version conflicts.
- `dart run build_runner build --delete-conflicting-outputs` runs without error
  (even with nothing to generate yet).
- `flutter analyze` runs clean against the new lint baseline (existing default
  template code may still trigger the `final class` rule — that's fixed in P0-10,
  not here).
- `pdf_manipulator`'s native setup completes on at least one platform (confirms the
  prebuilt-binary download path works before any feature depends on it).

### P0-2 — Environment configuration

**Depends on:** P0-1.

**Key inputs:** `.claude/reference/flutter/skills/environment_config.md`

**Deliverables:** `lib/core/config/` — environment profile abstraction (dev/release),
`Configurations` singleton, `.env` templates under `environments/`. The only setting
that matters right now is the `apps/api` base URL, since only 3 of 11 tools (Redact,
OCR, PDF-to-Word) call it — point it at the deployed backend for release and
`localhost`/LAN IP for development.

**Definition of done:** build_runner generates the env files without error;
`Configurations` exposes the API base URL correctly for both profiles.

### P0-3 — Dependency injection skeleton

**Depends on:** P0-1, P0-2.

**Key inputs:** `.claude/reference/flutter/skills/dependency_injection.md`

**Deliverables:** `lib/core/dependency/` (`DependencyInjector` interface, GetIt-backed
implementation), `lib/app/app_dependency.dart` (global `AppDependency` final class),
DI registration mixin skeleton (methods stubbed — actual `registerX()` calls are
added by the features that need them, in later tasks).

**Definition of done:** `AppDependency.injector.get<...>()` resolves a trivially
registered test dependency; nothing outside `lib/core/dependency/` imports `get_it`
directly.

### P0-4 — Network layer

**Depends on:** P0-1, P0-3.

**Key inputs:**
- `.claude/reference/flutter/skills/networking.md`
- `.claude/reference/flutter/skills/error_handling.md`
- Backend contract note in `apps/native/CLAUDE.md` (raw-bytes file responses,
  custom headers) — this matters more here than the generic networking skill doc
  alone would suggest, since these endpoints don't return JSON.

**Note:** this layer is now only exercised by 3 of 11 tools (Redact, OCR,
PDF-to-Word) — still build it fully and correctly, just don't over-invest relative
to `PdfEngineService` (P0-11), which is the higher-traffic path.

**Deliverables:** `lib/core/network/network_service.dart` (abstract),
`lib/core/network/dio_network_manager.dart` (concrete Dio wrapper — must support
multipart upload AND `ResponseType.bytes` download with header access),
`lib/core/models/api_response_model.dart`, `lib/core/error/` exception types
(`ResponseException`, `JsonException`).

**Definition of done:** a manual smoke call to any one real `/tools/<name>` endpoint
(e.g. OCR) round-trips: upload a small PDF, get bytes back, read response headers.

### P0-5 — State management base

**Depends on:** P0-1.

**Key inputs:** `.claude/reference/flutter/skills/state_management.md`

**Deliverables:** `lib/core/states/base_cubit.dart` (`BaseCubit<TState>` with
`safeEmit`/`safeCall`), documented 4-state pattern (Initial/Loading/Success/Error)
for feature state classes to follow. `safeCall` must handle failures from **both**
paths — `ResponseException`/`JsonException` from the network layer (Phase 3B tools)
and whatever exception type `pdf_manipulator` throws on a failed operation (Phase 3A
tools) — check its README for its error/exception surface.

**Definition of done:** a throwaway test cubit extending `BaseCubit` emits safely
after `close()` is called (no "emit after close" crash) and `safeCall` catches
errors from both a simulated network failure and a simulated `pdf_manipulator`
failure correctly.

### P0-6 — Localization setup

**Depends on:** P0-1.

**Key inputs:** `.claude/reference/flutter/skills/localization_rules.md`,
`design/README.md` (for the exact Turkish copy already used on the web app — reuse
wording, don't re-translate from scratch).

**Deliverables:** `lib/core/localization/localization_config.dart`,
`assets/translations/tr-TR.json` seeded with the strings needed by Phase 1/2 (home
screen, shared upload/progress/result/error widgets — not all 11 tools yet, add
tool-specific keys in each tool's own Phase 3 task).

**Definition of done:** `dart run build_runner build` generates `LocaleKeys`;
`EasyLocalization` wraps the app; a placeholder screen renders one string via
`LocaleKeys.x.tr()`.

### P0-7 — Theme system & design tokens

**Depends on:** P0-1, P0-6.

**Key inputs:**
- `.claude/reference/flutter/skills/theme_usage.md`
- `.claude/reference/flutter/skills/design_system.md`
- `design/README.md` (canonical token values)
- `design/StyleGuide.dc.html`

**Design tokens to encode** (see `apps/native/CLAUDE.md` for the short version;
`design/README.md` is the source of truth if anything here looks incomplete):
accent `#DC4731`; light: background `#F5F5F7`, surface `#FFFFFF`, border `#D2D2D7`,
text `#1D1D1F`, text-soft `#6E6E73`; dark: background `#000000`, surface `#1C1C1E`,
border `#38383A`, text `#F5F5F7`, text-soft `#98989D`; accent-soft = 12% accent on
white (light) / 22% accent on black (dark); spacing 4/8/12/16/24/32; radius 16
(cards) / 12 (buttons/panels) / 10–11 (small icon capsules); type scale: Display 48
/800, H1 28/800, H2 20/800, Body 15/400, Label 12/700 uppercase; system font stack
(no custom font except Caveat for signatures, needed later in the Sign task).

**Deliverables:** `lib/app/theme/` (`AppTheme` abstract, `LightTheme`, `DarkTheme`,
`ThemeManager`), `lib/core/utils/constants/sizes.dart`,
`lib/core/utils/constants/app_insets.dart`, `assets/colors/colors.xml` +
`flutter_gen` output.

**Definition of done:** no `Colors.*`/`Color(0x...)` literal outside the theme files
themselves; toggling `ThemeManager` switches every token consistently; a placeholder
screen shows correct colors in both modes.

### P0-8 — Router setup

**Depends on:** P0-1, P0-3, P0-7.

**Key inputs:** `.claude/reference/flutter/skills/navigation.md`

**Deliverables:** `lib/app/app_router.dart` (`final router = GoRouter(...)`) with a
home route and 11 placeholder tool routes (empty scaffold pages, content comes in
Phase 3), `lib/app/utils/builders/transition_page_builder.dart` (fade-in-up, per
`design/README.md`'s motion section), route path constants.

**Definition of done:** app boots to home placeholder; navigating to any of the 11
tool routes shows its placeholder with the fade-in-up transition; back navigation
works.

### P0-9 — Base shared widgets

**Depends on:** P0-1, P0-6, P0-7.

**Key inputs:** `.claude/reference/flutter/skills/widget_patterns.md`,
`design/StyleGuide.dc.html`

**Deliverables:** `lib/app/widgets/` — primary/secondary buttons (with the 0.97
press-scale from `design/README.md`'s motion section), card, text field, base error
container. All `final class`, all token-driven (no literals).

**Definition of done:** each widget renders correctly in a throwaway
harness/example screen in both themes; no hardcoded numbers/colors in these files.

### P0-10 — App initializer & main entry point

**Depends on:** all of P0-2 through P0-9.

**Key inputs:** `.claude/reference/flutter/skills/architecture.md`,
`.claude/reference/flutter/skills/project_structure.md`

**Deliverables:** `lib/app/app_initializer.dart` (bootstraps DI registration,
theme, localization), rewritten `lib/main.dart` (replaces the default counter-app
template entirely — delete `MyApp`/`MyHomePage`/`_counter` code, replace with
`MaterialApp.router` wired to `router`, theme, and `EasyLocalization`), delete
`test/widget_test.dart`'s counter-increment test (replace with a trivial "app
boots" smoke test, matching the mirrored `test/` structure rule).

**Definition of done:** `flutter run` boots to the real home placeholder (not the
counter demo) with no errors, in both light and dark system theme.

### P0-11 — Client-side PDF engine layer

**Depends on:** P0-1, P0-3. Does **not** depend on P0-4 through P0-10 and can be
built any time after those two — but every Phase 3A tool task depends on it.

**Key inputs:**
- `.claude/reference/flutter/skills/dependency_injection.md` (same
  interface-hiding pattern as `NetworkService` — apply it here too)
- `.claude/reference/flutter/skills/error_handling.md`
- The `pdf_manipulator` pub.dev page and README/example app — read its actual API
  surface directly, do not assume method names from this plan.

**Deliverables:** `lib/core/pdf/pdf_engine_service.dart` (abstract interface
covering: merge, split, rotate, reorder, watermark, compress, encrypt/protect,
add-image-stamp (for Sign), render-page-thumbnail), `lib/core/pdf/
pdf_manipulator_engine_service.dart` (concrete implementation wrapping the
`pdf_manipulator` package), registered into DI via `AppDependency` (P0-3). No
feature code anywhere may import `package:pdf_manipulator` directly — only this
file may.

**Definition of done:** a throwaway smoke test round-trips at least 2 operations
(e.g. merge two tiny PDFs, render a page thumbnail) against a real local file, fully
offline (airplane mode / no network), confirming the prebuilt-binary path from P0-1
actually works end to end.

---

## Phase 1 — App shell & home screen

### P1-1 — Home cubit & state

**Depends on:** P0-5.

**Key inputs:** `.claude/reference/flutter/skills/state_management.md`

**Deliverables:** `lib/features/home/presentation/cubit/home_cubit.dart` +
`home_state.dart` (4-state pattern; the cubit can be a thin no-op for now since the
home screen has no async data yet).

**Definition of done:** cubit extends `BaseCubit`, compiles, is unit-testable.

### P1-2 — Home screen UI

**Depends on:** P0-6, P0-7, P0-8, P0-9, P1-1.

**Key inputs:** `design/Main.dc.html` (desktop), `design/MobileHome.dc.html`
(mobile), `.claude/reference/flutter/skills/responsive_rules.md`,
`apps/web/features/home/components/` (behavior/copy reference only — do not port
React code, just match interaction/labels).

**Deliverables:** `lib/features/home/presentation/pages/home_screen.dart` +
`widgets/` (header, tool grid, tool card, hero/upload area). Desktop: hero + upload
card + 4-column tool grid, Compress featured as a 2x2 card. Mobile: stacked layout,
2-column grid, Compress and Redact spanning full width. All 11 tools represented as
cards navigating to their route (routes already exist as placeholders from P0-8).

**Definition of done:** layout matches both design files at their respective
breakpoints; every tool card navigates correctly; theme toggle visible and working.

### P1-3 — Home DI registration

**Depends on:** P0-3, P1-1, P1-2.

**Key inputs:** `.claude/reference/flutter/skills/dependency_injection.md`

**Deliverables:** register `HomeCubit` in the DI registration mixin from P0-3; wire
the home screen to obtain it via `AppDependency`.

**Definition of done:** no direct `HomeCubit()` construction in the widget tree;
cubit obtained exclusively through DI.

---

## Phase 2 — Shared tool-flow widgets

These are used by **all 11** Phase 3 tools (both 3A client-side and 3B
backend-dependent) — get them right once here rather than duplicating per tool.

### P2-1 — Upload dropzone widget

**Depends on:** P0-6, P0-7, P0-9.

**Key inputs:** `design/Compress.dc.html` (idle + file-selected states),
`.claude/reference/flutter/skills/widget_patterns.md`

**Deliverables:** `lib/core/widgets/upload/upload_dropzone.dart` (idle state: dashed
border, icon, "Dosya Seç" button; selected state: filename, size, remove button),
`lib/core/widgets/upload/file_picker_service.dart` abstraction (desktop drag-drop +
mobile file-picker dialog; PDF-only validation).

**Definition of done:** works via file-picker dialog on at least one mobile and one
desktop target; rejects non-PDF files with a visible error; clear/remove resets
state.

### P2-2 — Progress indicator widget

**Depends on:** P0-6, P0-7.

**Key inputs:** `design/Compress.dc.html` (processing state), `design/README.md`
(shimmer-sweep / reduced-motion rules)

**Deliverables:** `lib/core/widgets/progress/progress_indicator.dart` (determinate
bar, animated percentage, status text below), shimmer sweep animation gated on
`MediaQuery.disableAnimations` (reduced-motion).

**Note on progress source:** Phase 3B (backend) tools have a real upload/processing
duration to show progress for. Phase 3A (client-side) tools may finish almost
instantly on small files — check whether `pdf_manipulator` exposes a progress
callback for its operations; if not, use a brief simulated progress animation
(matching `apps/web`'s existing `useFakeProgress` hook pattern — see
`apps/web/lib/hooks/`) rather than skipping the progress state entirely, so the UX
stays consistent across all 11 tools.

**Definition of done:** bar animates smoothly, respects reduced-motion, percentage
text matches bar fill, works for both a real async duration and a simulated one.

### P2-3 — Result panel widget

**Depends on:** P0-6, P0-7, P0-9.

**Key inputs:** `design/Result.dc.html`, `design/MobileResult.dc.html`

**Deliverables:** `lib/core/widgets/result/result_panel.dart` (success badge
pop-in, before/after file size comparison card, download button, optional secondary
action, 24-hour auto-delete notice text — note the auto-delete notice only makes
sense for Phase 3B/backend-processed files; make it conditional, not always shown,
since Phase 3A files never leave the device).

**Definition of done:** renders correctly with representative before/after data;
download button triggers a callback (actual save-to-disk wiring happens per-tool in
Phase 3, since the file bytes source differs between 3A/3B); auto-delete notice only
appears when the result came from the backend.

### P2-4 — Error state widget

**Depends on:** P0-6, P0-7, P0-9.

**Key inputs:** `.claude/reference/flutter/skills/error_handling.md`

**Deliverables:** `lib/core/widgets/errors/error_state_widget.dart` (icon, message,
retry button, token-driven error color).

**Definition of done:** retry callback fires; message accepts a localized string.

---

## Phase 3A — Client-side tools (no backend, `pdf_manipulator`)

Every task here produces one complete feature module:
`lib/features/<tool>/{data,domain,presentation}/...` where the "data" layer calls
`PdfEngineService` (from P0-11) instead of a network repository. Cubit follows the
4-state pattern; screen built from Phase 2 shared widgets (upload → tool-specific
settings → progress → result/error, all fully offline). Ordered simplest-first; all
8 can be worked in any order or in parallel sessions.

**Every task in this group shares these key inputs:**
- `.claude/reference/flutter/skills/architecture.md` (feature folder structure)
- `.claude/reference/flutter/skills/state_management.md`
- `.claude/reference/flutter/patterns/feature_creation_flow.md`
- `.claude/reference/flutter/prompts/feature_creation_prompt.md`
- `apps/native/CLAUDE.md`'s "Client-side PDF engine" section
- The `pdf_manipulator` pub.dev README/example — **read the actual method
  signature for your specific operation before writing code**; this plan names the
  operation, not the verified exact API.

Plus, per tool, the design file and web reference below (web reference is for
copy/behavior parity only — the native version does not call the API these
`apps/web` pages happen to call).

| ID | Tool | Design file(s) | Web reference (copy/behavior only) | `pdf_manipulator` capability to use | Notes |
|----|------|----------------|--------------------------------------|--------------------------------------|-------|
| P3A-1 | Compress | `design/Compress.dc.html`, `design/MobileCompress.dc.html` | `apps/web/features/compress/components/` | compress (quality param) | Verify output size/quality against `apps/web`'s existing (pikepdf-backed) result on the same test file — if visibly worse, log it in the Decisions log below rather than shipping silently. |
| P3A-2 | Split | `design/Split.dc.html`, `design/MobileSplit.dc.html` | `apps/web/features/split/components/` | split / extract pages | No settings; confirm what container format the result comes back as (individual files vs a zip you must assemble yourself) and adjust the Result panel accordingly. |
| P3A-3 | Merge | `design/Merge.dc.html`, `design/MobileMerge.dc.html` | `apps/web/features/merge/components/` | merge | Multi-file upload + reorder list before merging. |
| P3A-4 | Rotate | `design/Rotate.dc.html`, `design/MobileRotate.dc.html` | `apps/web/features/rotate/components/` | render (thumbnails) + rotate | Per-page thumbnails via the same `PdfEngineService`, per-page angle state, rotate applied on submit. |
| P3A-5 | Reorder | `design/Reorder.dc.html`, `design/MobileReorder.dc.html` | `apps/web/features/reorder/components/` | render (thumbnails) + reorderPages | Per-page thumbnails; up/down arrow reordering. |
| P3A-6 | Watermark | `design/Watermark.dc.html`, `design/MobileWatermark.dc.html` | `apps/web/features/watermark/components/` | watermark | Text + position/opacity presets; live preview can reuse the thumbnail-render capability on page 1. |
| P3A-7 | Protect | `design/Protect.dc.html`, `design/MobileProtect.dc.html` | `apps/web/features/protect/components/` | encrypt/decrypt | Password field (reveal toggle, generate) + permission checkboxes (no-print/no-copy/no-edit) — verify the package's encrypt API actually exposes per-permission flags, not just a password, before committing to that UI. |
| P3A-8 | Sign | `design/Sign.dc.html`, `design/MobileSign.dc.html` | `apps/web/features/sign/components/` | addImageStamp (or equivalent) for drawn/typed/uploaded signature placement | **Product decision needed at implementation time:** the existing `apps/web` Sign feature has an optional-auth hash + append-only audit-log path that inherently needs a backend (see `apps/api/README.md`'s Sign section). Moving visual signature placement client-side is straightforward; whether audit-log parity is in scope for native MVP or deferred is NOT decided here — pick one, record the choice in this file's Decisions log, don't silently drop or silently backend-call for it. |

**Definition of done, per tool (applies to all 8):**
- Screen reachable from its home-screen tool card (route already exists from P0-8).
- Upload → settings → processing → result/error flow all work with **zero network
  calls** — verify by testing in airplane mode.
- Tool-specific settings match the design file's controls.
- Result screen shows correct output info; download saves the file bytes to disk
  (mobile: share-sheet or downloads dir; desktop: file-save dialog) with no
  auto-delete notice (nothing was uploaded anywhere).
- All UI strings for this tool added to `assets/translations/tr-TR.json` and used
  via `LocaleKeys`, none hardcoded.
- `test/features/<tool>/` mirrors the feature's `lib/features/<tool>/` structure.

---

## Phase 3B — Backend-dependent tools (`apps/api` over HTTP)

These 3 keep the original all-backend design from the first version of this plan.
Same feature-module shape as Phase 3A, but the "data" layer is a repository calling
`NetworkService` (P0-4) against `/tools/<name>`, not `PdfEngineService`.

**Every task in this group shares these key inputs:**
- `.claude/reference/flutter/skills/architecture.md`
- `.claude/reference/flutter/skills/state_management.md`
- `.claude/reference/flutter/skills/networking.md`
- `.claude/reference/flutter/patterns/feature_creation_flow.md`
- `.claude/reference/flutter/prompts/feature_creation_prompt.md`
- Backend contract note in `apps/native/CLAUDE.md` (raw bytes + header metadata,
  not JSON)

| ID | Tool | Design file(s) | API contract | Web reference | Notes |
|----|------|----------------|---------------|------------------------------------|-------|
| P3B-1 | OCR | `design/Ocr.dc.html`, `design/MobileOcr.dc.html` | `apps/api/app/features/ocr/router.py` + `schemas.py` | `apps/web/features/ocr/components/` | Language + output-format pills; confirm exact response shape (searchable PDF vs plain text) in `router.py`/`schemas.py`. |
| P3B-2 | PDF to Word | `design/PdfToWord.dc.html`, `design/MobilePdfToWord.dc.html` | `apps/api/app/features/pdf_to_word/router.py` + `schemas.py` | `apps/web/features/pdf-to-word/components/` | "Keep layout" checkbox; note the underscore-vs-hyphen folder-name mismatch between api (`pdf_to_word`) and web (`pdf-to-word`). |
| P3B-3 | Redact | `design/Redact.dc.html`, `design/MobileRedact.dc.html` | `apps/api/app/features/redact/router.py` + `schemas.py` | `apps/web/features/redact/components/` | Per-page thumbnails (use `PdfEngineService`'s render capability locally for the marking UI even though the actual redaction call goes to the backend) + click-to-mark regions + permanence warning + action disabled until ≥1 region marked. |

**Definition of done, per tool (applies to all 3):**
- Screen reachable from its home-screen tool card.
- Upload → settings → processing → result/error flow all work against the real
  deployed `apps/api` backend (or a local instance) — not mocked.
- Tool-specific settings match the design file's controls.
- Result screen shows correct before/after or output info; download saves the
  returned file bytes to disk; auto-delete notice shown (file was uploaded to the
  backend).
- All UI strings added to `assets/translations/tr-TR.json` via `LocaleKeys`.
- `test/features/<tool>/` mirrors `lib/features/<tool>/`.

---

## Phase 4 — Polish

Work these only after all 8 Phase 3A + 3 Phase 3B tools are done.

### P4-1 — Responsive & mobile layout pass

**Depends on:** all Phase 3A + 3B. **Key inputs:** `.claude/reference/flutter/skills/responsive_rules.md`, all `design/Mobile*.dc.html`, `design/README.md` (filename truncation: 16 chars mobile / 24 desktop). **Deliverables/DoD:** every tool screen verified at phone and desktop widths; filename truncation applied consistently; touch targets ≥48dp on mobile.

### P4-2 — Dark mode complete pass

**Depends on:** all Phase 3A + 3B, P0-7. **Key inputs:** `.claude/reference/flutter/skills/theme_usage.md`, `design/StyleGuide.dc.html`. **Deliverables/DoD:** every screen checked in dark mode; no light-only hardcoded values found; text contrast acceptable.

### P4-3 — Localization completeness pass

**Depends on:** all Phase 3A + 3B, P0-6. **Key inputs:** `.claude/reference/flutter/skills/localization_rules.md`. **Deliverables/DoD:** grep the whole `lib/features/` tree for string literals in `Text(...)` that aren't `.tr()` calls — zero remaining; semantic labels added to icon-only buttons.

### P4-4 — Test coverage pass

**Depends on:** all Phase 3A + 3B. **Key inputs:** `.claude/reference/flutter/skills/testing.md`. **Deliverables/DoD:** unit tests for every cubit's state transitions; mocked tests for both `PdfEngineService` (3A tools) and `NetworkService`-backed repositories (3B tools); at least one end-to-end widget test per group (e.g. Compress for 3A, OCR for 3B).

### P4-5 — Offline/airplane-mode verification pass

**Depends on:** all Phase 3A. **Key inputs:** none beyond the app itself. **Deliverables/DoD:** with the device/machine in airplane mode, confirm all 8 Phase 3A tools work end-to-end and only the 3 Phase 3B tools show a clear network-error state — this is the actual point of the hybrid architecture, so it needs an explicit pass, not just an assumption.

### P4-6 — Build & release preparation

**Depends on:** all Phase 3A + 3B, P0-1. **Deliverables/DoD:** app icons/splash for all 5 platforms, `pubspec.yaml` metadata finalized, release build succeeds on iOS/Android/macOS/Windows/Linux with no warnings — pay particular attention to `pdf_manipulator`'s prebuilt-binary download working in release/CI builds, not just local dev, for every platform.

### P4-7 — Update `apps/native/CLAUDE.md` and this file

**Depends on:** all tasks. **Deliverables/DoD:** add a "Feature creation checklist" section to `apps/native/CLAUDE.md` reflecting whatever the actual established pattern turned out to be after building all 11 tools (in case reality diverged from this plan, especially around `pdf_manipulator`'s real API); mark this file's phases as complete; if any Phase 3A tool had to fall back to the backend because `pdf_manipulator` couldn't actually do what this plan assumed, record that explicitly.

---

## Decisions log

*(append here as tasks make choices, so later sessions don't re-litigate them)*

- 2026-08-21 — Initial plan drafted: all 11 tools call `apps/api` over HTTP, no
  client-side PDF processing (matches `apps/native/README.md`'s original
  "not decided yet" framing at the time).
- 2026-08-21 (same day, revised) — User (project owner) raised the free-tier
  hosting cold-start problem and asked whether the 11 tools could be done fully
  client-side instead. Researched the current Flutter/Dart package ecosystem
  (web research, not just training knowledge) and found `pdf_manipulator`
  (pub.dev, MIT license, Rust engine with prebuilt binaries for
  iOS/Android/macOS/Windows/Linux, published ~2026-07-30): claims to cover merge,
  split, rotate, reorder, watermark, compress, encrypt/decrypt, sign, **true**
  redaction (removes underlying content, not an overlay), page rendering, and
  PDF→Office conversion. Verified via the package's actual pub.dev page and GitHub
  repo (not just the research agent's summary) that it's real, ships prebuilt
  binaries (no Rust toolchain needed to build), and the redaction/conversion
  claims are documented — but the repo is very young (22 GitHub stars, 1 open
  issue, first published weeks ago), so real-world quality for the
  highest-stakes operations (Redact = legal/privacy exposure if it fails silently;
  PDF→DOCX = layout-fidelity quality unverified; OCR = would need a
  mobile-ML-Kit/desktop-Tesseract split with real accuracy/bundle-size tradeoffs)
  is unproven.
- 2026-08-21 — **Decision:** hybrid, risk-tiered split, chosen by the project
  owner over "adopt fully" and "stay all-backend": Merge, Split, Rotate, Reorder,
  Watermark, Compress, Protect, Sign (8 tools — mechanical operations, easy to
  visually verify correctness, low stakes if `pdf_manipulator` has a rough edge)
  move to client-side via `pdf_manipulator`/`PdfEngineService`, no backend
  involved. Redact, OCR, PDF-to-Word (3 tools — privacy-critical, accuracy-critical,
  or fidelity-critical respectively) stay on `apps/api`, using the already-proven
  PyMuPDF/LibreOffice/Tesseract backend, until `pdf_manipulator` (or an
  alternative) is field-tested enough to reconsider. This decision should be
  revisited once the 8 client-side tools have shipped and proven the package out.
- PDF preview/thumbnail rendering: resolved — `pdf_manipulator` covers this too
  (its "render pages" capability), no separate package needed.
- API base URL for development: **not yet set** — decide in P0-2 (needs a
  reachable `apps/api` instance, local or deployed; only matters for the 3 Phase
  3B tools now).
- Sign's audit-log/hash parity (client-side signature placement vs. the existing
  web feature's optional backend-backed audit trail): **not yet decided** — see
  P3A-8's Notes column. Decide during that task, record the choice here.
