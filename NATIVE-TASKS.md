# Doclyvo Native (Flutter) — Task Breakdown

Status (2026-08-21): **Phase 0 complete, Phase 1 complete (including P1-4/P1-5's
responsive tier system and home tablet layout), P2-1 complete, P2-2 complete,
P2-3 complete.**
Remaining: P2-4, all of Phase 3A/3B, all of Phase 4.

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
depends on all of Phase 0. **P1-4 (responsive tier system) is a hard prerequisite for
every task after it** — P2-2 onwards and all of Phase 3 build UI, and they must build
it for three tiers, not two. Phase 2 depends on Phase 0+1. Phase 3A tasks depend on
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

**Fixed (2026-08-21).** The `.env-templates/` directory itself is gitignored
(`.gitignore` line 30) — deliberately, this was never a bug, it's the same
per-developer-local-secrets pattern as `apps/api/.env.example` and
`apps/web/.env.example`. A committed **example** already existed at
`.env-templates.example/{development,release}.env.example` documenting the
expected keys — what was actually missing was the real, gitignored
`.env-templates/` directory itself; nobody had run the one-time "copy the
example, fill it in" step P0-2 should have documented but didn't. Created
`.env-templates/development.env` and `.env-templates/release.env` at the **repo
root** (not `apps/native/`) from that example, with one value corrected:
`envied`'s `@Envied(path: '../../.env-templates/...')` is resolved relative to
the **process's working directory** when `build_runner` runs (`apps/native/`),
not relative to the annotated `.dart` file, so the path lands one level above
`apps/native/` — worth spelling out since it's easy to misread as
`apps/native/.env-templates/`. `CLIENT_ID`/`CLIENT_SECRET` stayed as the
example's placeholder values (they're declared on `EnvironmentProfile` but
unused anywhere else in `lib/` — this app has no OAuth/account system; revisit
if/when they get an actual purpose). `BASE_URL` for release: the example had
`https://api.doclyvo.com`, which does not resolve to anything found in this
repo (no render.yaml/DNS reference) — used `https://doclyvo-api.onrender.com`
instead, the actually-deployed URL per `docs/deployment.md`. If `api.doclyvo.com`
is a real planned custom domain, update the `.example` file and this one
together once it's live. Also: build_runner's own incremental cache doesn't
treat the `.env` file as a tracked input, so after creating/editing it, a plain
`dart run build_runner build --delete-conflicting-outputs` still served the
stale cached error — `dart run build_runner clean` first, then build, is what
actually picks up a new/changed `.env` file.

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

**Done (2026-08-21), with a known defect:** the two-value `isMobile` responsive model
this task shipped overflows at 700–1080px. Patched per-widget the same day; the root
cause is fixed by **P1-4**, and the tablet layout it never had is **P1-5**. Do not
copy P1-2's `isMobile` bool into a new screen.

### P1-3 — Home DI registration

**Depends on:** P0-3, P1-1, P1-2.

**Key inputs:** `.claude/reference/flutter/skills/dependency_injection.md`

**Deliverables:** register `HomeCubit` in the DI registration mixin from P0-3; wire
the home screen to obtain it via `AppDependency`.

**Definition of done:** no direct `HomeCubit()` construction in the widget tree;
cubit obtained exclusively through DI.

### P1-4 — Responsive tier system (mobile / tablet / desktop)

**Depends on:** P0-7, P1-2. **Blocks: P2-2, P2-3, P2-4 and all of Phase 3** — those
tasks build screens, and they must build them for three tiers. Do this one first.

**Why this task exists.** P1-2 shipped the home screen with a single `isMobile` bool
compared against `ResponsiveConstants.mobileBreakpoint` (700). That means *every*
width from 700px up renders the desktop branch — a resized desktop window, a
landscape tablet, an iPad split view — even though `design/*.dc.html` is drawn at
1440px. Three home widgets overflowed because of it (`HomeHeader`,
`HomeHeroSection`, `ToolCard`); they were patched individually on 2026-08-21, but the
two-value bool is the root cause and it is about to be copied into 11 more tool
screens. See the "mid-width overflow trap" section in `apps/native/CLAUDE.md`.

**Key inputs:** `apps/native/CLAUDE.md` (the overflow-trap section — read it, the
known fixes are listed there and must not be re-derived),
`lib/app/constants/responsive_constants.dart`,
`lib/features/home/presentation/` (all four widgets already carry a tier decision in
some form), `test/features/home/presentation/pages/home_screen_responsive_test.dart`,
`test/helpers/widget_test_harness.dart`.

**Deliverables:**
- `lib/app/constants/responsive_constants.dart`: a `ScreenTier` enum
  (`mobile`, `tablet`, `desktop`) plus its boundaries. Keep the two numbers already
  established and measured rather than inventing new ones: `mobile` below 700,
  `tablet` 700–1080, `desktop` 1080 and up. `headerNavBreakpoint` (1080) becomes the
  tablet/desktop boundary — fold it in, don't leave two constants meaning the same
  thing.
- `lib/app/extensions/build_context_extension.dart`: `ScreenTier get screenTier`
  plus `bool get isMobile` / `isTablet` / `isDesktop` conveniences, so widgets stop
  reading `MediaQuery.sizeOf(context).width` and comparing numbers themselves.
- Replace the `isMobile` bool threaded through `HomeScreen` → `HomeHeader`,
  `HomeHeroSection`, `UploadPreviewCard`, `ToolGrid`, `ToolCard` with the tier. Keep
  the existing mobile and desktop output byte-for-byte identical; `tablet` may map to
  the desktop branch for now — P1-5 designs it properly.
- `UploadDropzone`'s `isCompact` bool (from P2-1) gets the same treatment.

**Definition of done:**
- No widget in `lib/` compares a raw width number any more — `grep -rn
  "mobileBreakpoint\|sizeOf(context).width" lib/` only hits the extension and the
  constants file.
- `home_screen_responsive_test.dart` still passes at all 12 widths, and the sweep is
  extended to assert the tier the extension reports at each one.
- `flutter analyze` clean, `flutter test` green. No visual change at 390px or 1440px.

### P1-5 — Home screen tablet layout

**Depends on:** P1-4.

**Why this task exists.** P1-4 gives the app a `tablet` tier but points it at the
desktop layout. This task decides what tablet actually looks like — which is a design
decision, not a refactor, which is why it is a separate session.

**Key inputs:** `design/Main.dc.html` (desktop, 1440px), `design/MobileHome.dc.html`
(mobile), `design/README.md`, `design/StyleGuide.dc.html`.

**There is no tablet design export.** The canvas only has the two ends of the range.
Derive the middle from them and **record every choice you make in the Decisions log
at the bottom of this file**, so P2/P3 sessions follow the same rules instead of each
inventing their own. The decisions the home screen forces:
- Hero + upload card: side by side (desktop) or stacked (mobile)? The hero's `flex: 6`
  share is what made its CTAs overflow at tablet widths.
- Tool grid: 4 columns (desktop) or 2 (mobile), or 3? Does Compress stay a 2x2
  featured card?
- Header: `HomeHeader` already drops its nav links below 1080 — is that the intended
  tablet header, or should tablet get a condensed nav?
- Type scale and paddings: desktop's, mobile's, or something in between?

**Deliverables:** the `tablet` branch of `lib/features/home/presentation/` widgets,
plus new Decisions-log entries stating the four choices above as rules future
screens must follow.

**Definition of done:** home screen renders a deliberate tablet layout (not the
desktop one squeezed) at 700–1079px; `home_screen_responsive_test.dart` green at all
widths; the layout rules are written down in the Decisions log.

---

## Phase 2 — Shared tool-flow widgets

These are used by **all 11** Phase 3 tools (both 3A client-side and 3B
backend-dependent) — get them right once here rather than duplicating per tool.

**All four widgets must work at three tiers, not two.** Do P1-4 first. Every widget
here takes the tier (not an `isMobile`/`isCompact` bool) and ships with a width-sweep
test — see the "mid-width overflow trap" section in `apps/native/CLAUDE.md` for the
known failure modes and their fixes, and `test/helpers/widget_test_harness.dart` for
`pumpLocalized(..., surfaceSize:)`.

### P2-1 — Upload dropzone widget ✅ done (2026-08-21)

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

**What actually shipped** (read this before wiring the dropzone into a tool screen —
the paths and the widget's contract differ from the plan above):
- `lib/core/widgets/upload/file_picker_service.dart` — abstract `FilePickerService`:
  `pickPdf()` returns `null` when the user cancels (cancelling is not an error),
  `resolveDroppedPath()` handles a desktop drop, `isPdfFileName()` is the shared
  gate. Concrete `PlatformFilePickerManager` sits next to it. Registered in the DI
  mixin as a lazy singleton — resolve it via `AppDependency.injector`, never
  construct it.
- `lib/core/widgets/upload/models/picked_pdf_file.dart` — `PickedPdfFile`
  (`name`, `sizeInBytes`, `path`, `formattedSize`, lazy `readBytes()`). No
  `PlatformFile`/`DropItem` type escapes the service, so `readBytes()` is what you
  hand to `PdfEngineService`.
- `lib/core/error/file_picker_exception.dart` — `FilePickerException` +
  `FilePickerErrorKind` (`notPdf`, `unreadable`, `pickerFailure`).
- **`lib/app/widgets/upload/upload_dropzone.dart` — note the path.** The plan said
  `lib/core/widgets/upload/`, but the widget needs `PrimaryButton` and
  `BuildContextExtension`, both in `lib/app/`, and `architecture.md` forbids `core/`
  importing `app/`. The layer rule won; the service and model stayed in `core/`.
  Owner approved the deviation on 2026-08-21.
- The widget is **controlled**: the caller owns `selectedFile` and reacts to
  `onFileSelected`/`onFileRemoved`. Only drag-hover and the validation error live in
  its local state, so a tool cubit drives it. It also needs `filePickerService`
  passed in — `core/` cannot reach `AppDependency` itself.
- Drag-drop is wired only on macOS/Windows/Linux (`DropTarget` is not wrapped at all
  on mobile). `desktop_drop` is **pinned to exactly 0.7.1** — 0.8.0's
  `android/build.gradle` breaks `flutter build apk`. Do not bump it without running
  that build.
- `file_picker` is v12, whose API is `FilePicker.pickFile(...) → PlatformFile?`
  (static, single-file) — not the `FilePicker.platform.pickFiles` +
  `FilePickerResult` shape most examples online still show.
- macOS needed `com.apple.security.files.user-selected.read-write` added to both
  entitlements files; without it the sandbox blocks reading the picked file.

**Still open from this task:** the dropzone is not attached to any screen yet (tool
screens are Phase 3), so the file-picker dialog has only been verified to *build* on
macOS and Android — nobody has clicked it on a real device. Verify it during the
first Phase 3A tool. Its `isCompact` bool is also still a bool; P1-4 converts it.

### P2-2 — Progress indicator widget ✅ done (2026-08-21)

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
text matches bar fill, works for both a real async duration and a simulated one;
takes the tier from P1-4 (no `isMobile` bool) and ships a width-sweep test.

**What actually shipped:** `lib/app/widgets/progress/progress_indicator.dart` —
`ToolProgressIndicator` (bytes-in style, not `ProgressIndicator`: that name
collides with Flutter's own `material.dart` class). Same layer deviation as
`UploadDropzone` (P2-1): it needs `BuildContextExtension.textSoftColor`, and
`core/` may not import `app/`, so it lives in `lib/app/widgets/`, not the
`lib/core/widgets/` the plan named. `progress`/`label`/`hint`/`tier` are all
caller-controlled; `label` defaults to `progress.processing` and `hint` to a new
`progress.hint` key ("Bu işlem birkaç saniye sürebilir."), both added to
`tr-TR.json`. Percentage and bar-fill width both animate via one
`TweenAnimationBuilder<double>` (250ms, matching the web's bar-width transition)
so they can never visually disagree. The shimmer sweep is a real
`AnimationController` (`SingleTickerProviderStateMixin`, 1.3s loop, matching
`apps/web`'s `animate-shimmer-sweep`) that is only `repeat()`-ed when
`MediaQuery.disableAnimations` is false, checked in `didChangeDependencies` — not
just visually hidden under reduced motion, actually stopped. **Test-writing note
for later widgets with a looping `AnimationController`:** `pumpLocalized` ends in
`pumpAndSettle`, which hangs forever against a repeating controller — width-sweep
and static-content tests must force `MediaQuery(data: MediaQueryData
(disableAnimations: true))` around the widget under test; a test that wants to
verify the animation actually ticks has to hand-roll `pumpWidget` +
`tester.runAsync` + explicit `tester.pump(duration)` calls instead of using the
harness helper. See `test/app/widgets/progress/progress_indicator_test.dart`.
Regenerating `LocaleKeys` initially failed because P0-2's `.env` files were
missing — **fixed same-day, see the P0-2 section above** for the actual cause
(a path-resolution gotcha in `envied`, not a missing task) and the fix.

### P2-3 — Result panel widget ✅ done (2026-08-21)

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
appears when the result came from the backend; takes the tier from P1-4 and ships a
width-sweep test — the before/after comparison card is a `Row` of two blocks, which
is the shape that overflows first at tablet widths (use `Wrap` or stack it).

**What actually shipped:** `lib/app/widgets/result/result_panel.dart` —
`ResultPanel`. Same layer deviation as `UploadDropzone`/`ToolProgressIndicator`
(P2-1/P2-2): it needs `BuildContextExtension` plus the `PrimaryButton`/
`SecondaryButton`/`AppCard` widgets, all in `lib/app/`, and `core/` may not
import `app/`, so it lives in `lib/app/widgets/`, not the `lib/core/widgets/`
the plan named. Notable API choices, so later Phase 3 tool tasks don't
re-derive them:
- `message` (the tool-specific subtitle, e.g. "rapor-2024.pdf sıkıştırıldı ve
  indirilmeye hazır.") is entirely caller-owned copy — the widget only owns
  the fixed "Dosyan hazır" heading (new key `result.ready`). Each Phase 3
  tool composes its own localized message the same way this plan already
  expects tool-specific translation keys to be added per tool.
- `beforeSizeInBytes`/`afterSizeInBytes` are asserted to be supplied together
  or not at all — the comparison card (and its reduction/growth percent,
  `-58%`/`+50%`) only renders when both are known, since not every tool has
  a meaningful before/after (e.g. Merge combines multiple inputs).
  `pageCount` is independently optional.
- **The before/after `Row` never overflows at any width because both blocks
  sit in `Expanded`, not a fixed width** — satisfies the DoD's `Wrap`-or-stack
  requirement without actually needing `Wrap`; the width-sweep test (12
  widths, 360-1920px) confirms it holds even with a long file name, a
  secondary action, and the auto-delete notice all showing at once.
- The download/secondary buttons deliberately keep `PrimaryButton`/
  `SecondaryButton`'s existing intrinsic sizing (`Row(mainAxisSize: min)`
  internally) rather than stretching the download button to fill the row like
  `design/Result.dc.html` draws it — forcing that via `Expanded` would hand
  `PrimaryButton` a tight width it doesn't have an `alignment` for, and it
  would then left-align its icon+label instead of centering them. Neither
  button has been used stretched anywhere else in the app, so this stayed
  intrinsic-width (centered `Row` on tablet/desktop, stacked `Column` on
  mobile) rather than changing a shared button's contract for one screen.
  Revisit if a later tool screen genuinely needs a full-width primary action.
- Byte formatting (`KB`/`MB`/`GB`) is a small private duplicate of
  `PickedPdfFile.formattedSize`'s algorithm, not a shared import — pulling in
  the upload feature's file model just for its static formatting logic
  would be a heavier coupling than the four-line function it would save.

### P2-4 — Error state widget

**Depends on:** P0-6, P0-7, P0-9.

**Key inputs:** `.claude/reference/flutter/skills/error_handling.md`

**Deliverables:** `lib/core/widgets/errors/error_state_widget.dart` (icon, message,
retry button, token-driven error color).

**Definition of done:** retry callback fires; message accepts a localized string;
takes the tier from P1-4 and ships a width-sweep test — a long error message is
exactly the kind of content that overflows a fixed-height box at tablet widths.

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
- **Laid out for all three tiers** (mobile / tablet / desktop) using P1-4's
  `ScreenTier` — never a raw width comparison, never a two-value bool. Follow the
  tablet rules P1-5 recorded in the Decisions log; if this tool's design needs a rule
  that isn't there yet, add it there rather than deciding locally.
- **A width-sweep test** at `test/features/<tool>/presentation/pages/` modelled on
  `test/features/home/presentation/pages/home_screen_responsive_test.dart`: pump the
  screen at 360/430/699/700/800/900/1024/1080/1200/1440/1920 via
  `pumpLocalized(..., surfaceSize:)` and assert `tester.takeException()` is `null`.
  Read `apps/native/CLAUDE.md`'s "mid-width overflow trap" section first — the three
  recurring failure modes and their fixes are already written down there.
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
- **Laid out for all three tiers** and covered by a width-sweep test — identical
  requirement to Phase 3A above, same reasoning, same reference test.
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

### P4-1 — Responsive & three-tier layout pass

**Depends on:** all Phase 3A + 3B, P1-4, P1-5. **Key inputs:** `apps/native/CLAUDE.md`'s "mid-width overflow trap" section, the tablet rules in this file's Decisions log, all `design/Mobile*.dc.html`, `design/README.md` (filename truncation: 16 chars mobile / 24 desktop). **Deliverables/DoD:** every tool screen verified at **phone, tablet and desktop** widths — P1-4/P1-5 built the tier system and the home screen's tablet layout, this pass confirms all 11 tool screens actually honour them; every screen has a passing width-sweep test; `grep -rn "mobileBreakpoint\|sizeOf(context).width" lib/` still only hits the extension and the constants file; filename truncation applied consistently; touch targets ≥48dp on mobile and tablet.

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

- 2026-08-21 — **P1-2's responsive model is a known defect, and P1-4/P1-5 exist to
  fix it properly.** The home screen picks its layout from one `isMobile` bool
  compared against `mobileBreakpoint` (700), so everything from 700px up renders the
  desktop branch, which the `design/*.dc.html` exports draw at 1440px. Three widgets
  overflowed as a result and were patched on the spot: `HomeHeader` gained a third
  tier that drops its nav links below a *measured* 1080px
  (`ResponsiveConstants.headerNavBreakpoint`; the full header's intrinsic width is
  1017.25px), `HomeHeroSection`'s CTA `Row` became a `Wrap`, and `ToolCard`'s
  title/description got `maxLines` + ellipsis because `ToolGrid` positions cards at a
  fixed cell height. **These three fixes are the canonical patterns — later sessions
  should copy them, not re-derive them**; they are written up in
  `apps/native/CLAUDE.md` under "Responsive layout: the mid-width overflow trap",
  together with the rule that a breakpoint must be *measured*
  (`IntrinsicWidth` + `tester.getSize`) rather than guessed. Flutter treats a
  `RenderFlex` overflow as an error, not as harmless clipping, and none of this is
  visible in a 1440px manual check — hence the mandatory width-sweep test
  (`test/features/home/presentation/pages/home_screen_responsive_test.dart`) now
  required by every Phase 2/3 task's DoD.
- 2026-08-21 — **Decision: three tiers, using the two boundaries already measured.**
  `mobile` < 700, `tablet` 700–1080, `desktop` ≥ 1080, expressed as a `ScreenTier`
  enum in P1-4. 700 is the pre-existing `mobileBreakpoint`; 1080 is
  `headerNavBreakpoint`, chosen with headroom over the measured 1017.25px for longer
  translations and larger system text scales. Picked over inventing round numbers
  (960/1280) so the constants keep matching a real measurement. **Open:** what the
  tablet tier actually *looks like* — there is no tablet design export, only the two
  ends of the range. P1-5 decides it and must record the choices here.
- 2026-08-21 — **P2-1 done.** Notable outcomes, all written up in full under the
  task itself: the `UploadDropzone` widget lives in `lib/app/widgets/upload/`, not
  the `lib/core/widgets/upload/` the plan named, because it needs `PrimaryButton` +
  `BuildContextExtension` from `lib/app/` and `architecture.md` forbids `core/`
  importing `app/` (owner approved; the service and model did stay in `core/`);
  `desktop_drop` is pinned to exactly **0.7.1** because 0.8.0's Android gradle module
  breaks `flutter build apk`; `file_picker` v12's API is
  `FilePicker.pickFile(...) → PlatformFile?`, not the `FilePicker.platform.pickFiles`
  + `FilePickerResult` shape older examples show; macOS needs
  `com.apple.security.files.user-selected.read-write` in both entitlements files.
- 2026-08-21 — **A widget-test harness now exists and every UI task should use it:**
  `test/helpers/widget_test_harness.dart` (`initializeTestLocalization`,
  `registerAppDependencies`/`resetAppDependencies`, `pumpLocalized(..., surfaceSize:)`).
  It exists because three separate things bite any test that pumps a real screen:
  screens resolve `ThemeService`/cubits from GetIt in `initState`,
  `EasyLocalization.ensureInitialized` needs `SharedPreferences.setMockInitialValues`
  first, and the translation asset loads off the *real* event loop so the pump has to
  sit inside `tester.runAsync`. It also defaults the surface to 1440x1024, because
  `flutter_test`'s own 800x600 default silently lands inside the tablet tier. The four
  pre-existing tests that were failing for exactly these reasons were fixed on the
  same day.

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
- API base URL for development: **resolved 2026-08-21** — `http://localhost:8000`
  (matches `apps/api/README.md`'s default `uvicorn` port) for development,
  `https://doclyvo-api.onrender.com` (per `docs/deployment.md`) for release. See
  the P0-2 section's "Fixed" note for where these actually live
  (`.env-templates/` at the repo root) and why the annotation's relative path is
  easy to misread.
- Sign's audit-log/hash parity (client-side signature placement vs. the existing
  web feature's optional backend-backed audit trail): **not yet decided** — see
  P3A-8's Notes column. Decide during that task, record the choice here.
- 2026-08-21 — **P0-11 done, and it resolves three of this file's open questions
  by reading `pdf_manipulator` 4.1.0's real API instead of its capability list.**
  The engine's surface is `Pdf` + extensions (`PdfSugar`, `PdfStandalone`),
  driven by `DataSource`/`DataSink` (`MemorySource`/`MemorySink` in memory,
  `FileSource`/`FileSink` from the separate `package:pdf_manipulator/io.dart`
  entry point). Every op returns a `PdfTask<T>` — a `Future` plus `cancel()`.
  Findings that later tasks should not re-derive:
  - **Protect (P3A-7) can keep its permission checkboxes.** `PdfEncryptionConfig`
    takes a `PdfPermissions` object with per-flag control (`print`, `printHq`,
    `modify`, `copy`, `annotate`, `fillForms`, `accessibility`, `assemble`), not
    just a password — so no-print / no-copy / no-edit map to real restrictions.
    `PdfProtectionOptions` collapses them to the design's three checkboxes.
  - **Split (P3A-2) gets individual files, not a zip.** `pdf.split` asks for a
    `DataSink` per chunk via a factory and never produces an archive;
    `PdfEngineService.split` returns `List<Uint8List>` in document order.
    Assembling an archive, if the Result panel wants one, is the feature's job.
  - **Thumbnails are PNG bytes** (`RenderedPage.data`), sized via
    `PdfRenderSize.thumbnail(n)`, streamed one page at a time — but the engine's
    stream carries no page index, so `renderThumbnails` pairs each event with
    the index it was asked for. Rotate/Reorder/Redact feed these straight into
    `Image.memory`.
- 2026-08-21 — **Decision: `PdfEngineService` is bytes-in / bytes-out**
  (`Uint8List`), not file-path based. Keeps the interface free of `dart:io` (so
  it works unchanged on web), matches how the Phase 2 dropzone and result panel
  hand data around, and leaves reading the picked file / writing the output to
  the feature edge. Trade-off accepted: whole documents sit in memory during an
  operation. If a large-file problem shows up, add a file-backed overload here
  rather than in a feature — the engine package already supports streaming via
  `FileSource`/`FileSink`.
- 2026-08-21 — **Decision: engine errors are translated, not re-exported.**
  `PdfEngineException` (`lib/core/error/`) carries the engine's message plus a
  `PdfEngineErrorKind` enum (passwordRequired, wrongPassword, corrupted,
  pageOutOfRange, unsupported, cancelled, engineFailure), mapped from the
  package's sealed `PdfError` hierarchy inside
  `pdf_manipulator_engine_service.dart`. `BaseCubit.safeCall` now catches
  `PdfEngineException` instead of `PdfError`, which was the last
  `pdf_manipulator` import outside the engine file — P0-11's "only this file may
  import it" rule now actually holds for all of `lib/`. Features that need to
  re-prompt for a password should switch on `kind`, not parse the message.
- 2026-08-21 — **P1-5 done: the four tablet layout decisions, binding on every
  later screen unless it records a reason to deviate here.**
  1. **Hero + upload card: stacked full-width, not a side-by-side Row.**
     Splitting them into a 6:5 Row at 700-1080px gives each column only
     ~320-490px — the exact narrowness that made the hero's CTAs overflow in
     the first place (see the P1-2/P1-4 entries above). `HomeScreen` now
     stacks them (`stackHeroAndUpload = tier != ScreenTier.desktop`) the same
     way mobile does; only `desktop` keeps the Row.
  2. **Tool grid: 3 columns, not 4 squeezed or 2 stretched.** 4 desktop
     columns at 700-1080px produce ~150-240px cells, barely wider than
     mobile's ~173px 2-column cells despite the extra chrome; 2 columns
     wastes the headroom tablet actually has. 3 columns lands at ~207-333px
     per cell. Compress keeps its "featured" treatment as a full-width
     horizontal banner (`ToolGrid._tabletCells`) rather than desktop's 2x2
     block, which would leave an awkward lone column beside it in a 3-wide
     grid; Redact (the 11th tool, an odd one out either way) gets the same
     full-width banner treatment for visual balance instead of a half-empty
     row.
  3. **Header: tablet keeps the nav links hidden (inherited from P1-4's
     `showNavLinks = tier == desktop`, unchanged) but keeps desktop's
     wordmark size and padding, not mobile's compact ones.** `HomeHeader`
     already branched its sizing on `tier == mobile`, not `tier != desktop`,
     so tablet already got this for free — no code change was needed here,
     just confirming it's the intended rule and not an accident.
  4. **Type scale and paddings: desktop's throughout, not mobile's or a
     blend.** Once the hero stops sharing a row with the upload card, it has
     the tablet's full content width (~652-1032px) to itself — plenty of
     room for the 48px display headline and full spacing scale (24px
     container padding, `Sizes.xl`/`xxl` gaps) desktop uses. `HomeHeroSection`
     and `UploadPreviewCard` already branched on `tier == mobile`, so, like
     decision 3, tablet inherited the desktop treatment automatically —
     stacking was the only actual layout change this task made. The
     takeaway for later screens: a widget that already keys its
     typography/padding off `tier == mobile` rather than `tier != desktop`
     usually does not need new tablet-specific styling, only a new
     tablet-specific *arrangement* (Row vs. Column, column count) where one
     applies.
  Files changed: `lib/features/home/presentation/pages/home_screen.dart`
  (stacking), `lib/features/home/presentation/widgets/tool_grid.dart` (3-column
  tablet cells + per-tier `horizontal`/`showDescription`), and
  `test/features/home/presentation/pages/home_screen_responsive_test.dart`
  (asserts the hero/upload card are stacked at every non-desktop width and
  side-by-side at desktop widths, on top of the existing no-overflow sweep).
  `HomeHeader`, `HomeHeroSection`, and `UploadPreviewCard` needed no changes —
  their existing `tier == mobile` branches already produced the desktop
  treatment at the tablet tier once P1-4 introduced the three-tier enum.
- 2026-08-21 — **P2-2 done.** `ToolProgressIndicator`
  (`lib/app/widgets/progress/progress_indicator.dart`) followed P2-1's layer
  deviation for the same reason (`BuildContextExtension` needed, `core/` can't
  import `app/`). Along the way, `dart run build_runner build` failed
  (`envied_generator`: missing `.env` files) because nobody had done P0-2's
  local one-time setup — **fixed the same day, see the P0-2 section above**;
  it was gitignored-local-secrets working as designed, not a broken task.
  Separately: any widget with a *looping* `AnimationController` (this one's shimmer sweep)
  cannot be tested through `pumpLocalized`, because it ends in `pumpAndSettle`,
  which never returns against a repeating animation — force
  `MediaQuery(data: MediaQueryData(disableAnimations: true))` around such a
  widget in layout/content tests, and hand-roll `pumpWidget` + `runAsync` +
  explicit `tester.pump(duration)` calls for the one test that wants to verify
  the animation actually ticks. See
  `test/app/widgets/progress/progress_indicator_test.dart`.
- 2026-08-21 — **P2-3 done.** `ResultPanel`
  (`lib/app/widgets/result/result_panel.dart`) followed the same layer
  deviation as P2-1/P2-2 (`BuildContextExtension` + `PrimaryButton`/
  `SecondaryButton`/`AppCard` all live in `lib/app/`). Full detail is under the
  task itself; the one rule later Phase 3 tool tasks should reuse is the
  overflow fix for the before/after comparison card: put each size block in
  an `Expanded`, never a fixed width, and the "`Row` of two blocks" shape the
  task warned about stops being an overflow risk at any surface width without
  needing `Wrap`. `beforeSizeInBytes`/`afterSizeInBytes` are optional and must
  come as a pair — omit both for tools with no meaningful before/after size
  (e.g. Merge).
