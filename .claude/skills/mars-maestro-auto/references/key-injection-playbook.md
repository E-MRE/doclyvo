# Key-injection playbook — make an untestable control testable (Flutter)

Use this ONLY when a control a smoke flow needs has no stable selector: icon-only, no visible text,
ambiguous duplicate text, or you could only reach it with a `point:` tap. You add a
`Semantics(identifier:)` accessibility id so Maestro can select it via `id:`. This is additive and
invisible — it must never change layout, behavior, or copy.

## Why this works
`Semantics(identifier: 'foo')` maps to the native accessibility id — iOS `accessibilityIdentifier`,
Android `resource-id` — which Maestro reads and matches with `id: "foo"`. Widget `Key`s do NOT surface
as native ids, so they are useless to Maestro; only `Semantics(identifier:)` does.

## Procedure
1. **Prove the gap live.** `inspect` the screen; confirm the target row/button shows **no
   `resource-id`** and has no unique text you could match instead. (If stable text exists, use it —
   don't add an id.)
2. **Find the widget.** In `lib/`, grep for a nearby visible label, the icon asset name, or the
   callback (e.g. `onClose`, `onTap`, the localized key). Confirm it's the mobile/target-platform
   build of the widget if the project is platform-split.
3. **Declare the id centrally.** Keep one registry so ids are declared once and never inlined. If the
   project already has one (e.g. a `SemanticKeys` / `SK` class), extend it. Otherwise create:
   ```dart
   // lib/app/testing/semantic_keys.dart  (or the project's conventional test-support location)
   /// Accessibility identifiers exposed to black-box UI automation (Maestro).
   /// Each maps to the native accessibility id via Semantics(identifier:).
   abstract final class SemanticKeys {
     static const exampleButton = 'example_button';
   }
   typedef SK = SemanticKeys;
   ```
   Naming: `snake_case`, area-prefixed, descriptive — e.g. `alert_expand_button`,
   `portfolio_group_toggle`, `position_quick_close_button`.
4. **Wrap the control.** Add the import for the registry, then wrap the tappable widget:
   ```dart
   Semantics(
     identifier: SK.exampleButton,
     child: <the existing InkWell/GestureDetector/IconButton/ElevatedButton>,
   )
   ```
   - Wrap the smallest widget that is the actual tap target.
   - If the control sits inside a larger tappable region that ALSO needs its own id, give each its own
     `Semantics(identifier:)` — Flutter emits them as distinct nodes; verify both surface after build.
   - Match the file's existing style; keep the diff minimal.
5. **Verify statically.** `dart format <files>` and `dart analyze <files>` — must be clean before build.
6. **Rebuild + reinstall.** New ids compile into the tree — they are invisible to Maestro until you
   rebuild with the project's recorded build command and reinstall on the device. (Budget minutes.)
   Relaunch, `inspect`, confirm the id now appears as `resource-id=<id>`.
7. **Use it.** Switch the flow's selector to `id: "<id>"` (or the MCP `tap_on` `id:` arg); re-run green.

## Guardrails
- **Verify only, keys only.** The one source change this skill may make is adding accessibility ids.
  Never alter logic, layout, or wording to make a test pass. If a real bug blocks the flow, STOP and
  report it (failure protocol) — do not work around it.
- **Minimal & central.** Only add ids for controls a smoke flow actually uses. One registry class.
- **Rebuild awareness.** After ANY id addition, the previously-installed binary is stale; every flow
  that relies on the new id needs the fresh build. Note this in the run report.
- If you cannot find/modify the widget safely, leave the flow on a text/point selector, flag the
  control as "needs id" in the project map, and move on — don't force a risky edit.
