# Code Review Prompt

Use this prompt when asking an AI agent to review code for convention compliance and quality.

---

## Prompt Template

```
You are performing a code review for the `<app>` Flutter project.

Before reviewing, read the following files:
1. reference/flutter/skills/coding_standards.md
2. reference/flutter/skills/naming_conventions.md
3. reference/flutter/skills/architecture.md
4. reference/flutter/skills/state_management.md
5. reference/flutter/skills/design_system.md
6. reference/flutter/skills/widget_patterns.md
7. reference/flutter/skills/developer_preferences.md
8. reference/flutter/skills/do_not_do.md
9. reference/flutter/reviews/code_review_checklist.md
10. reference/flutter/reviews/architecture_checklist.md
11. reference/flutter/reviews/performance_checklist.md

Files to review:

[FILE PATH(S) HERE]

Review focus:

[OPTIONAL: SPECIFY FOCUS — e.g., "architecture only", "performance only", "full review"]

Review instructions:
- Report violations as a structured list grouped by category
- For each violation, show: file path + line context + what's wrong + what it should be instead
- Reference the specific rule from `reference/flutter/skills/do_not_do.md` or the relevant skill file
- Distinguish between: MUST FIX (convention violation), SHOULD FIX (improvement), NOTE (awareness item)
- Do NOT flag items listed under "Known Inconsistencies" in `reference/flutter/skills/do_not_do.md`
  unless they are new occurrences beyond the known ones
- Do NOT suggest adding features or refactoring beyond what is necessary to fix violations
- Do NOT suggest generic Flutter best practices that conflict with this project's conventions
  (this project's conventions always override generic Flutter advice)

After the violation list, provide:
- A summary: overall compliance score (rough estimate)
- Top 3 most critical issues if any exist
- Whether the code is safe to merge (assuming violations are addressed)
```

---

## Usage Notes

- Run this against every new feature before merging
- For large features, review in layers: data layer first, then presentation layer
- If reviewing generated code (`*.g.dart`), skip — generated code is excluded from linting and review
- Cross-reference with `reference/flutter/examples/good/` and `reference/flutter/examples/bad/` if examples are available for the pattern in question
