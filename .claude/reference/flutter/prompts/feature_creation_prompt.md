# Feature Creation Prompt

Use this prompt when asking an AI agent to implement a new feature in this repository.

---

## Prompt Template

```
You are implementing a new feature for the `<app>` Flutter project.

Before writing any code, read the following files in order:
1. reference/flutter/skills/architecture.md
2. reference/flutter/skills/project_structure.md
3. reference/flutter/skills/naming_conventions.md
4. reference/flutter/skills/state_management.md
5. reference/flutter/skills/models_and_mapping.md
6. reference/flutter/skills/networking.md
7. reference/flutter/skills/dependency_injection.md
8. reference/flutter/skills/widget_patterns.md
9. reference/flutter/skills/design_system.md
10. reference/flutter/patterns/feature_creation_flow.md
11. reference/flutter/patterns/folder_decision_rules.md
12. reference/flutter/patterns/widget_decomposition_rules.md
13. reference/flutter/patterns/shared_vs_local_widget_rules.md
14. reference/flutter/skills/do_not_do.md

After reading, implement the following feature:

[DESCRIBE THE FEATURE HERE]

Requirements:
- Follow the step-by-step flow in `reference/flutter/patterns/feature_creation_flow.md` exactly
- The `home` feature is the canonical reference — match its structure
- Use `final class` for all concrete classes
- Use `safeCall()` in the cubit, never raw try/catch
- States are plain `final class implements XState` — no freezed
- All model fields must have defaults and named parameters
- Register the repository and cubit in `AppDependencyRegisterMixin`
- Add the route using `TransitionPageBuilder.*`
- Apply design system constants — no inline magic numbers
- Use `EmptySize.*` and `SliverEmptySize.*` for spacing
- Check `reference/flutter/reviews/code_review_checklist.md` before considering done

After implementing, verify against:
- reference/flutter/reviews/code_review_checklist.md
- reference/flutter/reviews/architecture_checklist.md
```

---

## Usage Notes

- Substitute `[DESCRIBE THE FEATURE HERE]` with a specific, concise feature description
- Include API endpoint name and expected response shape if known
- Reference existing similar features (e.g., "similar to the banners feature") to anchor style
- If the feature has multiple entities (e.g., campaigns + categories), specify each entity separately
