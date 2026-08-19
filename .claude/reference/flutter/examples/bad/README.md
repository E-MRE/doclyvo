# Bad Examples

This directory contains annotated code snippets that demonstrate anti-patterns to avoid.

## How to Use

Each file should be named after the anti-pattern it illustrates, e.g.:
- `antipattern_raw_emit.dart`
- `antipattern_inline_edgeinsets.dart`
- `antipattern_cubit_singleton.dart`
- `antipattern_image_network.dart`

## When to Add Examples

Add an example here when:
- A pattern violation was found in code review
- The mistake is non-obvious and the `do_not_do.md` rule is not self-explanatory
- An AI agent generated code using this anti-pattern

## Format

Each example file should include a header comment block:

```dart
// ANTI-PATTERN: <name>
// VIOLATES: <which rule in do_not_do.md or skill file>
// FIX: <brief description of the correct approach>
// SEE: reference/flutter/examples/good/<corresponding_good_example>.dart
```
