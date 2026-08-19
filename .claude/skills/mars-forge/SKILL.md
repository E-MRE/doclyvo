---
name: mars-forge
description: Takes a task (Jira ticket, GitHub issue, plain description, and/or a Figma link/design) and forges it into a single, self-contained English execution prompt for a *separate* fresh AI session — it does not implement anything itself. Clarifies the task interactively (one open question at a time), analyzes this project's architecture/coding style/existing code (using codebase-memory-mcp when available), drafts the prompt, and quality-gates the draft against the gathered reports before handing it to the user as a copy-pasteable block. Trigger phrases include "görev promptu oluştur", "bu ticket için prompt hazırla", "planlama promptu üret", "şu görevi prompt'a çevir", "forge this task", "build an execution prompt for this", "/mars-forge", "/forge".
invocation: /mars-forge, /forge, /mars-task-prompt
---

# Mars Forge

Takes a task (Jira ticket, GitHub issue, plain description, and/or a Figma link/design) and **does not write code or execute anything itself** — instead it forges the task plus this project's architecture, coding style, and relevant existing code into a single, self-contained **English execution prompt**, meant to be pasted into a **separate, fresh session**.

> **Note:** This skill's only output is a prompt — delivered as a copy-pasteable code block in chat, never written to a file. The generated prompt forces whatever session it's pasted into to plan first, explain the plan to the user **in Turkish** and get approval, then execute step by step (with tests and commit/push checkpoints). This skill itself never edits files, commits, or opens PRs.

## When to Use

- Turning a ticket/issue/Figma design into an approval-gated, step-by-step execution process meant to run in another session
- When the task description is incomplete or ambiguous and needs clarifying before work can start
- When you want the task pre-analyzed against this project's real architecture/existing code and that context baked into the prompt
- When you want the execution process (issue creation, branching, testing, commit/push, Maestro validation) to have explicit, sequential approval gates

---

## Usage

```
/mars-forge <ticket text / issue number-url / description> [figma link]
/forge "<task description>"
```

**Examples:**
```
/mars-forge PROJ-231: Add installment options to the payment screen, https://figma.com/file/...
/forge https://github.com/org/repo/issues/58
/mars-task-prompt "Add a filter to the order list, not sure which screen/cubit owns it"
```

---

## Roles (simulated sub-agents)

Phases 2-4 run as **simulated sub-agents**, the same way `mars-create-ai-markdown` does it: no separate Agent tool call is required — the main session sequentially adopts each role's perspective and produces a "report", which the next role consumes as input. **Phase 1 is the exception** — it needs a one-question-at-a-time loop with the real user, so it runs live in this same conversation, not delegated to a sub-agent (sub-agents can't hold a back-and-forth with the user).

| Role | Job | Input | Output |
|---|---|---|---|
| **Researcher** (Phase 1, interactive) | Clarifies the task | raw task + figma | **Report A** |
| **Project Analyst** (Phase 2) | Architecture/style/existing-code analysis | Report A + project | **Report B** |
| **Prompt Architect** (Phase 3) | Drafts the English prompt | Report A + B | Draft Prompt |
| **QA Reviewer** (Phase 4) | Audits the draft, requests revisions | Draft + Report A + B | Approved Prompt / Revision Request |

---

## Workflow

### Phase 1: Task Clarification (Researcher — interactive, live)

1. Parse the input: a Jira/GitHub reference, plain text, or a Figma link attached?
   - If a GitHub issue number/URL was given: `gh issue view <number> --json title,body,labels,url`
   - If a Figma link was given: note it. If this session has no way to view it, ask the user to summarize the key points (screen name, new components, states).
2. Extract: **goal**, **scope**, **acceptance criteria**, **out of scope**, **design references**.
3. Identify missing/ambiguous points. If any exist, **ask exactly one question, wait for the answer, evaluate it, then ask the next one if still needed** — never dump a list of questions in one message. Stop once nothing is ambiguous.
4. If no clarification is needed at all, skip this phase's Q&A loop.
5. Compile: **Report A — Task Clarification Report**
   ```markdown
   ## Report A: Task Clarification
   - Goal:
   - Scope (included):
   - Out of scope:
   - Acceptance criteria: [ ] ...
   - Design/Figma references:
   - Clarifications obtained from the user: (question → answer pairs)
   - Remaining open points / assumptions made (with rationale, if any):
   ```

### Phase 2: Project Context Analysis (Project Analyst)

Take Report A as input and analyze the project:

1. Read `CLAUDE.md`, the relevant `.claude/reference/flutter/skills/*.md` files (architecture, coding_standards, state_management, networking, do_not_do, naming_conventions), and any convention docs relevant to the task.
2. Scan an **existing feature** similar to the task's target area (folder layout, import style, DI registration pattern to mirror).
3. If `codebase-memory-mcp` is connected in this session (check `.mcp.json` / the current MCP tool list):
   - Use `search_graph` / `trace_path` / `get_architecture` / `search_code` to find existing classes/functions/routes relevant to the task — what exists where, which layers are affected, which call chains matter.
   - If it's not connected, skip this step and note in the report "codebase-memory-mcp is not configured in this project."
4. Note whether the `maestro` MCP is configured in this project (`.mcp.json`) — needed for Phase 3's conditional Maestro step.
5. Compile: **Report B — Project Context Report**
   ```markdown
   ## Report B: Project Context
   - Architectural layer(s) and affected file/folder paths:
   - Conventions to apply (final class, BaseCubit+safeEmit, design tokens, etc. — with real class names):
   - Existing feature/file(s) to use as a reference:
   - codebase-memory-mcp findings (if connected): relevant classes/functions/routes + relationships
   - maestro mcp status: present/absent
   - Risk points to watch (dual-screen impact, DI registration, l10n, etc.):
   ```

### Phase 3: Prompt Drafting (Prompt Architect)

Blend Report A + Report B into an **English** draft prompt that follows the mandatory structure below (see "Generated Prompt Template"). Hand the draft to Phase 4.

### Phase 4: Quality Control (QA Reviewer)

Audit the draft line by line against Report A + B and the **Prompt Quality Checklist** below.

- Mark each criterion PASS/FAIL.
- If any **critical** criterion FAILs: send the draft back to Phase 3 with a concrete description of the problem (revision request) → Phase 3 fixes it → Phase 4 re-audits.
- **At most 3 revision cycles.** If a critical criterion is still FAILing after the 3rd attempt: deliver the best available version, appending the unresolved QA concerns as a "⚠️ Known gaps" note at the end of the prompt — do not loop indefinitely.
- Once every critical criterion PASSes (or the 3-cycle budget is spent), move to Phase 5.

### Phase 5: Delivery

Present the approved (or gap-flagged) prompt as a single copy-pasteable ```` ```markdown ```` or ```` ```text ```` code block in chat. Do not write it to a file. Add a short header noting how many revision cycles ran, any unresolved gaps, and a reminder to paste the prompt into a separate/new session.

---

## Generated Prompt Template (Phase 3's output must follow this structure)

```markdown
# Task: <short title>

## Context
<project name/type, tech stack summary — from Report B>

## Goal & Scope
<Report A: goal, scope, out of scope>

## Acceptance Criteria
- [ ] ...

## Design References
<Figma link / design notes, if any; omit this section if none>

## Project Conventions (must follow)
<Report B: real class names, final class/BaseCubit/design-token rules, etc.>

## Relevant Existing Code
<Report B: codebase-memory-mcp findings, or the manually-scanned similar feature — file paths + what they're for; include "verify these still exist before relying on them">

## Execution Contract (follow in order, do not skip a gate)
1. Enter planning mode. Investigate the codebase as needed to understand exactly what must change and where.
2. Produce a step-by-step implementation plan.
3. Present the full plan to the user **in Turkish**, then ask for approval before doing anything else. Do not proceed without explicit approval.
4. After approval, ask the user (in Turkish) whether a GitHub issue should be opened for this task. Act on the answer.
5. Ask the user (in Turkish) whether a new branch should be created. Act on the answer.
6. Execute the plan **one step at a time**. For each step:
   a. Implement the step.
   b. Write unit tests covering edge cases and adversarial/breaking scenarios for the code touched in this step — not just the happy path.
   c. Run the tests; fix until they pass.
   d. Ask the user (in Turkish) whether to commit and push this step. Act on the answer.
   e. Only move to the next step after the user confirms.
7. <CONDITIONAL — include only if Report B says "maestro mcp: present"> After the full task is complete, ask the user (in Turkish) whether to validate the change with a Maestro test flow, since this project has the maestro MCP configured.

## Constraints
- Always ask one question at a time; wait for the answer before asking the next.
- Never skip an approval gate.
- Never force-push or bypass hooks.
- If a referenced file/class from "Relevant Existing Code" no longer exists, say so and adapt instead of guessing.

⚠️ Known gaps (only added if a critical point remains unresolved after 3 revision cycles):
- ...
```

---

## Prompt Quality Checklist (Phase 4's audit list)

| # | Criterion | Critical? |
|---|---|---|
| 1 | Goal & Scope matches Report A's goal/scope exactly; ambiguities/assumptions are explicitly flagged | Critical |
| 2 | Acceptance Criteria are concrete and verifiable (mappable to code) | Critical |
| 3 | Project Conventions section names **real** classes/rules (from Report B — no generic/placeholder names) | Critical |
| 4 | Relevant Existing Code section lists concrete file paths (from codebase-memory-mcp findings or the scanned reference feature) with a "verify it still exists" caveat | Critical |
| 5 | The Execution Contract's 6 steps (plan→approval→issue question→branch question→step-by-step+test+commit question→continuation approval) are complete and **in order** | Critical |
| 6 | The prompt explicitly states that the plan presentation and every follow-up question must be **in Turkish** | Critical |
| 7 | The testing step explicitly says "edge-case, adversarial/breaking, not limited to the happy path" | Critical |
| 8 | The Maestro step is included **only if** Report B says "maestro mcp: present"; otherwise it's absent entirely | Critical |
| 9 | The prompt is self-contained — it doesn't reference this conversation or the report names, and reads standalone in a fresh session | Critical |
| 10 | Language: the prompt body is entirely in English (the only exception is the "ask/explain in Turkish" instructions) | Critical |
| 11 | No unnecessary repetition/filler, bullet points are scannable, no overly long paragraphs | Minor |

Phase 5 is not reached until every "Critical" row PASSes (except when the 3-cycle budget is exhausted).

---

## Output Format

```markdown
# 🔥 Mars Forge — Execution Prompt Ready

**Revision cycles:** <0-3> | **Status:** ✅ All critical criteria passed / ⚠️ Open gap(s) after 3 cycles

<short list of open gaps, if any>

Copy the prompt below and paste it into a **separate, fresh session**:

\`\`\`markdown
<final prompt from Phase 3/4>
\`\`\`
```

---

## Boundaries

### Does
- Clarifies the task (ticket/issue/description/Figma) interactively
- Analyzes project architecture/style + (if available) codebase-memory-mcp for task-specific code context
- Produces a self-contained English execution prompt from Report A+B
- Quality-gates the generated prompt against the checklist (max 3 revisions)

### Does Not
- Write code, edit files, or execute the plan (that's the job of the **separate** session the prompt is pasted into)
- Perform git operations (issue creation, branching, commit, push) — those happen in the target session with user approval
- Save the prompt to a file (chat code block only)
- Render/view the Figma design itself (without a Figma MCP, it relies on the user's summary)

---

## Related Skills

- `/mars-implement-ticket` — If the same input should be implemented directly in this session instead of a separate one
- `/mars-project-overview` — To manually deepen Report B's project-wide context
- `/mars-maestro-auto` — To set up the Maestro validation step referenced at the end of the generated prompt
- `/mars-unit-test` — To align the Execution Contract's edge-case tests with this project's real test style
