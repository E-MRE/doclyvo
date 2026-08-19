# Bugfix Prompt

Use this prompt when asking an AI agent to fix a bug while preserving architecture and conventions.

---

## Prompt Template

```
You are fixing a bug in the `<app>` Flutter project.

Before making any changes, read the following files:
1. reference/flutter/skills/architecture.md
2. reference/flutter/skills/error_handling.md
3. reference/flutter/skills/state_management.md
4. reference/flutter/skills/flutter_best_practices.md
5. reference/flutter/skills/do_not_do.md

Bug description:

[DESCRIBE THE BUG HERE]

Affected file(s):

[FILE PATH(S) HERE]

Fix constraints:
- Fix ONLY the reported bug — do not refactor surrounding code
- Do NOT change class declarations, method signatures, or architecture
- Do NOT introduce new patterns or abstractions to fix a simple bug
- If the fix requires a `setState`, use `SafeStateMixin` (already in scope for StatefulWidgets)
- If the fix requires throwing an error, use `ResponseException` or `JsonException`
- If the fix involves an async call, preserve `safeCall()` usage pattern
- If the fix changes a model field, ensure all model fields still have default values
- Do NOT add `print()` statements — use `debugPrint()` if logging is needed
- After fixing, verify the fix does not break the pattern rules in `reference/flutter/skills/do_not_do.md`

After applying the fix, verify:
- The cubit still uses `safeCall()` for async operations
- The widget lifecycle (initState/dispose) is still intact
- No new inline magic numbers introduced
```

---

## Usage Notes

- Be specific about reproduction steps in the bug description
- Include relevant state (e.g., "happens when state is `BannerError`")
- If the bug is in generated code (`*.g.dart`), fix the source model/annotation and re-run `build_runner`
- If the bug is in DI registration order, check `AppDependencyRegisterMixin` for initialization sequence
