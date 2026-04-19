---
name: plan
description: Plan mode for Claude Code — inspect context, write a markdown plan into the project's `PLAN.md` or a `plans/` directory, and do not execute the work.
version: 1.1.0
author: hermes-CCC (ported from Hermes Agent by NousResearch)
license: MIT
metadata:
  hermes:
    tags: [planning, plan-mode, implementation, workflow]
    related_skills: [writing-plans, subagent-driven-development]
---

# Plan Mode

Use this skill when the user wants a plan instead of execution.

## Core behavior

For this turn, you are planning only.

- Do not implement code.
- Do not edit project files except the plan markdown file.
- Do not run mutating terminal commands, commit, push, or perform external actions.
- You may inspect the repo or other context with read-only commands/tools when needed.
- Your deliverable is a markdown plan saved inside the project.

## Output requirements

Write a markdown plan that is concrete and actionable.

Include, when relevant:
- Goal
- Current context / assumptions
- Proposed approach
- Step-by-step plan
- Files likely to change
- Tests / validation
- Risks, tradeoffs, and open questions

If the task is code-related, include exact file paths, likely test targets, and verification steps.

## Save location

Save the plan with the `Write` tool into one of these locations, in priority order:

1. If the user specifies a path, use that exact path.
2. If a `plans/` directory already exists in the project root, save to:
   - `plans/YYYY-MM-DD_HHMMSS-<slug>.md`
3. Otherwise, default to a single `PLAN.md` at the project root.

The slug is a short kebab-case summary of the task (for example `wire-up-oauth-callback` or `fix-ingest-race`). Keep it under ~50 characters.

Paths are relative to the project's working directory so the plan stays with the repo and travels through version control.

## Interaction style

- If the request is clear enough, write the plan directly.
- If no explicit instruction accompanies `/plan`, infer the task from the current conversation context.
- If it is genuinely underspecified, ask a brief clarifying question instead of guessing.
- After saving the plan, reply briefly with what you planned and the saved path.

## Plan template

Use this skeleton as a starting point; delete sections that are not relevant:

```markdown
# <Goal in one line>

## Context
- Repo / area:
- Current state:
- Constraints / non-goals:

## Approach
Short narrative of the chosen direction and why it beats alternatives.

## Steps
1. <Action> — `path/to/file.ext`
2. <Action> — command or tool
3. <Action> — verification

## Files likely to change
- `path/one.ext`
- `path/two.ext`

## Tests & validation
- Unit: `pnpm test <file>`
- Integration: <command>
- Manual smoke: <what to click / curl>

## Risks & open questions
- <Risk 1>
- <Open question 1>
```

## Decision rules

- Never bundle the plan file alongside other file changes. The plan is the only write this turn.
- If a previous plan with the same slug exists, suffix the new file with `-v2`, `-v3`, etc. rather than overwriting.
- Keep plans short enough to read in one pass. If a plan exceeds roughly 400 lines, split it by milestone into separate files under `plans/`.
- Prefer concrete commands (`gh`, `pnpm`, `pytest`, `docker compose`) over vague verbs like "test it".

## Outputs

- The plan file path (absolute).
- A one-paragraph summary in chat with the path and the headline steps.

## Failure modes

- Writing code: stop immediately, revert, and save the plan instead.
- No project root: fall back to the current working directory and warn the user.
- Ambiguous scope: ask one clarifying question before writing the plan.
- Overwriting a useful existing plan: always version instead of overwrite.
