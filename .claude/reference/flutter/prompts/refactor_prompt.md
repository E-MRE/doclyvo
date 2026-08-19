# Refactor Prompt

Use this prompt when asking an AI agent to refactor existing code to match project conventions.

---

## Prompt Template

```
You are refactoring code in the `<app>` Flutter project.

Before making any changes, read the following files:
1. reference/flutter/skills/coding_standards.md
2. reference/flutter/skills/naming_conventions.md
3. reference/flutter/skills/developer_preferences.md
4. reference/flutter/skills/design_system.md
5. reference/flutter/skills/state_management.md
6. reference/flutter/skills/widget_patterns.md
7. reference/flutter/patterns/widget_decomposition_rules.md
8. reference/flutter/patterns/shared_vs_local_widget_rules.md
9. reference/flutter/skills/do_not_do.md
10. reference/flutter/reviews/code_review_checklist.md

The target file(s) to refactor:

[FILE PATH(S) HERE]

Refactoring goals:
- Align with `final class` convention (replace bare `class` on concrete implementations)
- Replace inline `EdgeInsets`, `SizedBox`, `BorderRadius` with design system constants
- Replace `Image.network()` with `CachedImage`
- Ensure model fields have default values and named parameters
- Replace raw `try/catch` + `emit()` in cubits with `safeCall()`
- Ensure `SafeStateMixin` is used for async `setState`
- Replace `Navigator.push()` with `context.push()` / `context.go()`
- Replace `Theme.of(context)` with `context.theme`
- Apply `Future.wait()` for parallel async calls
- Extract oversized `build()` methods using private classes or private methods

Constraints:
- Do NOT change behavior — only restructure code to match conventions
- Do NOT add features or error handling beyond what is already present
- Do NOT add comments or docstrings to code you did not change
- Preserve all existing functionality exactly
- If a file uses a pattern listed in `reference/flutter/skills/do_not_do.md`, fix it
- If unsure whether a pattern is intentional or a mistake, check `reference/flutter/skills/do_not_do.md`'s
  "Known Inconsistencies" section before flagging it

After refactoring, verify against:
- reference/flutter/reviews/code_review_checklist.md
```

---

## Usage Notes

- Specify exact file paths
- If refactoring a full feature, start with models → repositories → states → cubits → widgets → screens
- Note any known inconsistencies you want preserved (e.g., "CategoryGridView uses `class` — leave as is")
