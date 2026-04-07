# Migration Guide: Hermes Agent to Claude Code Skills

This guide explains how to move from a Hermes Agent workflow to `hermes-CCC`, a Claude Code native skill pack.

## What Changes

Hermes Agent typically feels like a single agent runtime with named commands, internal tool routing, and a persistent operating style.

`hermes-CCC` keeps the same operating ideas but expresses them as local skills that Claude Code can load on demand:

- Hermes command vocabulary becomes skill-trigger vocabulary.
- Hermes orchestration patterns become explicit markdown procedures.
- Hermes tool use becomes Claude Code tool choice plus shell commands.
- Hermes memory becomes file-backed durable notes.
- Hermes trajectories become structured JSONL capture guidance.

## Mental Model Shift

### Hermes mindset

- start with a smart agent runtime
- call internal tools
- rely on the runtime to manage memory and route work

### Claude Code mindset

- start with a coding agent plus local files
- let skill descriptions trigger the right operating mode
- use skills to provide procedural knowledge
- use the terminal, connectors, and local documentation as the execution substrate

## Recommended Migration Order

1. Install `hermes-CCC` into `~/.claude/skills/`.
2. Start with the core operating skills:
   - `hermes-route`
   - `hermes-memory`
   - `hermes-skill`
   - `hermes-traj`
3. Add engineering discipline skills next:
   - `systematic-debugging`
   - `test-driven-development`
   - `subagent-driven-development`
4. Add external workflow skills based on your stack:
   - GitHub skills
   - `arxiv`
   - `huggingface-hub`
   - `youtube-content`
   - `native-mcp`
   - `mcporter`
   - `research-paper-writing`
   - `jupyter-live-kernel`

## Command Translation Pattern

In Hermes, you might think in terms of slash commands or runtime subcommands.

In Claude Code, use the same concepts as skill names and explicit requests:

- "route this task" maps to `hermes-route`
- "load memory before coding" maps to `hermes-memory`
- "save this workflow as a skill" maps to `hermes-skill`
- "capture this interaction for training" maps to `hermes-traj`

You do not need a special runtime command parser. The skill description is the trigger surface.

## Memory Migration

Hermes users often expect memory to be implicit. In Claude Code it is safer to make memory explicit and file-backed.

Recommended approach:

1. create a dedicated project memory directory
2. maintain an index file such as `MEMORY.md`
3. persist only durable decisions, preferences, repeated fixes, and architecture notes
4. keep volatile task chatter out of memory

The `hermes-memory` skill formalizes this process.

## Routing Migration

Hermes routing is usually internal to the runtime.

In Claude Code, routing becomes a visible planning step:

- determine complexity
- decide whether the task needs deeper reasoning
- decide whether work should stay local or split into independent streams
- decide whether memory or external docs should be loaded first

The `hermes-route` skill gives you a repeatable way to do that.

## Tooling Migration

Hermes often wraps tool abstractions. Claude Code usually exposes tools more directly:

- shell commands for local automation
- connectors for GitHub, research, docs, and notebook workflows
- MCP servers for custom tool surfaces
- markdown skills for reusable operating procedures

This makes the system more transparent. You see both the instructions and the execution substrate.

## Migration Checklist

Use this checklist when porting an existing Hermes workflow:

1. Identify the repeated task.
2. Write down the actual commands, APIs, and files used.
3. Decide whether the behavior belongs in:
   - a skill
   - a shell script
   - an MCP server
   - project memory
4. Create or update the relevant `SKILL.md`.
5. Add decision rules and failure handling.
6. Add output contracts so the behavior is repeatable.
7. Validate the install and line-count requirements.

## Porting a Hermes Command

When converting a Hermes command into a Claude Code skill:

1. Name the skill after the operational unit, not the original implementation detail.
2. Put the trigger information into the `description` frontmatter field.
3. Put the execution procedure in the Markdown body.
4. Include exact CLI or connector usage, not just abstract advice.
5. Include failure recovery and verification steps.

## Common Mistakes

- Porting abstractions instead of workflows
- Writing descriptions that do not say when to use the skill
- Treating memory as a dumping ground
- Omitting commands, file formats, or output schemas
- Replacing precise procedures with generic prose

## Recommended First Week Workflow

For the first week after migration, use this loop:

1. route the task
2. prefetch memory
3. execute with a discipline skill such as debugging or TDD
4. use GitHub skills for review and PR hygiene
5. save successful patterns as skills
6. capture trajectories worth analyzing later

That sequence reproduces the spirit of Hermes while fitting naturally into Claude Code.

## Where to Go Next

- Read [`tool-mapping.md`](./tool-mapping.md) to map Hermes concepts to Claude Code equivalents.
- Read the package [`README.md`](../README.md) for installation and the full skills table.
- Customize individual skills for your team after the initial migration is stable.
