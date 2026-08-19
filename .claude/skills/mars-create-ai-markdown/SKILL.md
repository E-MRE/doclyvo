---
name: mars-create-ai-markdown
description: Generates a project-specific AI context file (e.g., CLAUDE.md, CURSOR.md). Type `/mars-create-ai-md help` for parameters and usage.
disable-model-invocation: false
---

Task: Creating a Project-Optimized AI Context File

You are triggered by the command `/mars-create-ai-markdown`. 
First, analyze the arguments provided by the user immediately after the command. 

EXPECTED INPUT FORMAT: `/mars-create-ai-markdown [ai_name] [mcp_flag]`
- `[ai_name]`: The name of the AI (e.g., claude, cursor, copilot). If not provided, default to "AI". The output file will be named `[AI_NAME].md` (uppercase).
- `[mcp_flag]`: A flag to enable the codebase memory MCP. Accepts `-true` or `--mcp`. If absent, assume it is FALSE.

SPECIAL COMMAND: If the user inputs `/mars-create-ai-markdown help`, STOP all execution and ONLY output the "Help & Usage Guide" section below.

### Help & Usage Guide
**Usage:** `/mars-create-ai-markdown [ai_name] [mcp_flag]`

**Parameters:**
- `ai_name`: The target AI assistant (e.g., claude, cursor). Determines the file name (e.g., CLAUDE.md).
- `mcp_flag`: Add `-true` to enable the codebase memory MCP server. The default value is false.

**Examples:**
- `/mars-create-ai-markdown claude` -> Generates CLAUDE.md using only the standard workspace context.
- `/mars-create-ai-markdown cursor -true` -> Generates CURSOR.md utilizing the codebase memory MCP.
- `/mars-create-ai-markdown help` -> Displays this help menu.

---

### EXECUTION (IF NOT HELP COMMAND)

Act as a Principal Software Architect and AI Engineering Lead. My goal is to create a high-density, clear, and action-oriented `[AI_NAME].md` file that fully aligns with this project's architecture, coding standards, and workflows. 

**CRITICAL INSTRUCTION:** The entire content of the generated `[AI_NAME].md` file MUST be written in English.

Resources and Tools at Your Disposal:
1. "mars-skills" directory: For project-specific patterns, best practices, and skill definitions.
2. [CONDITIONAL - ONLY IF MCP FLAG IS TRUE]: "codebase memory mcp": Use this MCP server strictly to understand the general context, connections, and architectural decisions of the project.

Complete the following steps sequentially by simulating sub-agents. Internally evaluate each agent's findings before summarizing them.

STEP 1: RESEARCH AND ANALYSIS AGENTS
- Agent A (Architectural Analyst): Analyze the project's architecture, adopted coding standards like SOLID/DRY/KISS, dependency management, and tech stack. 
  * If MCP flag is TRUE: Deep dive using the codebase memory MCP.
  * If MCP flag is FALSE: Rely solely on the standard workspace context.
  Report your findings.
- Agent B (Pattern Expert): Review the `mars-skills` directory to extract recurring code patterns, folder/file naming conventions, and specific business logic structures. Report your findings.
- Agent C (Prompt/Context Engineer): Determine the essential sections that should be in an industry-standard, highly efficient `[AI_NAME].md` file. Research and define how to formulate proactive constraints (Guardrails) to prevent LLM errors. Report your findings.

STEP 2: SYNTHESIS AND CREATION AGENT
By combining the reports of Agents A, B, and C, draft a detailed `[AI_NAME].md` (in English) based on the following structure:
- The persona and tone the AI assistant should adopt in this project.
- Strict architectural rules to follow and avoid (Rules must be clear and restrictive).
- Standards for component creation, naming, and state management.
- Guidelines on how to utilize the patterns within `mars-skills` when adding new features.

STEP 3: REVIEW AND FINALIZATION
- As a fourth agent, compare the generated draft against the requirements from the initial reports.
- If there are superficial, generic items, or points that do not match the actual codebase, correct and elaborate on them.
- Mars-Skills Alignment: Have the patterns and rules from the skill set been correctly integrated into the draft?
- Hallucination Test: Has any non-existent command or architectural rule leaked into the file?
- Prepare the final file in a clean Markdown format (named strictly as `[AI_NAME].md`) and output it as a single code block. Ensure the entire file is written in English.