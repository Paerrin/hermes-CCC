# Hermes Tool Mapping to Claude Code

This document maps common Hermes Agent concepts and tool patterns to Claude Code equivalents used by `hermes-CCC`.

## Mapping Principles

- Prefer native Claude Code tools when the capability already exists.
- Use shell commands for deterministic local automation.
- Use connectors when the target system is remote and the connector is available.
- Use MCP when a reusable tool surface should exist outside a single skill.
- Use `SKILL.md` files to express operating procedures and decision logic.

## Core Mapping Table

| Hermes concept | Hermes role | Claude Code equivalent | Notes |
| --- | --- | --- | --- |
| Router | choose execution path or model depth | `hermes-route` skill + planning | routing becomes explicit and inspectable |
| Memory manager | store and retrieve durable context | `hermes-memory` skill + project memory files | file-backed memory is easier to audit |
| Skill synthesizer | convert behaviors into reusable units | `hermes-skill` skill | use markdown skills instead of runtime modules |
| Trajectory logger | store interaction traces | `hermes-traj` skill + JSONL | suitable for QA and fine-tuning prep |
| Internal debugging tool | multi-step failure analysis | `systematic-debugging` skill | pairs well with tests and logs |
| Test loop tool | red-green-refactor | `test-driven-development` skill | use local test runners directly |
| Worker swarm | parallel work decomposition | `subagent-driven-development` skill | applies only when subagents are allowed |
| GitHub reviewer | inspect PR diffs and comment | `github-code-review` skill + GitHub connector | findings-first review style |
| PR manager | branch, PR, merge flow | `github-pr-workflow` skill + GitHub connector | keeps PRs small and reviewable |
| Issue triager | classify and execute issues | `github-issues` skill + GitHub connector | turn issues into plans and closures |
| Paper retriever | search papers | `arxiv` skill + arXiv API/shell HTTP clients | skill includes API and bibtex patterns |
| Model hub tool | interact with Hugging Face | `huggingface-hub` skill + `huggingface-cli` | use `hf` or `huggingface-cli` commands |
| RL trainer | run reinforcement fine-tuning | `grpo-rl-training` skill + TRL scripts | covers GRPO-specific configuration |
| Media ingestion tool | download media and metadata | `youtube-content` skill + `yt-dlp` | includes transcript and chapter extraction |
| Tool server registry | configure external tools | `native-mcp` skill | covers config, transports, and debugging |
| MCP scaffolder | generate a new tool server | `mcporter` skill + FastMCP templates | optimized for quick server creation |
| Research author | draft technical papers | `research-paper-writing` skill | coordinates outline, citations, and LaTeX |
| Notebook runtime | inspect and run notebooks | `jupyter-live-kernel` skill + `nbformat`/Jupyter | safe live-kernel workflow |

## Execution Surface Mapping

### Hermes runtime tool call

Typical Hermes behavior:

- ask the agent runtime to use a tool
- rely on the runtime to structure the call

Claude Code equivalent:

- call a connector tool if available
- otherwise run a shell command
- otherwise create an MCP surface for the missing capability

### Hermes memory write

Typical Hermes behavior:

- implicit or managed memory persistence

Claude Code equivalent:

- update a memory file
- keep an explicit memory index
- save only durable knowledge

### Hermes workflow plugin

Typical Hermes behavior:

- custom runtime extension

Claude Code equivalent:

- `SKILL.md` if the behavior is procedural
- script in the repository if the behavior is deterministic
- MCP server if the behavior should be callable as a reusable tool

## Decision Tree

Use this quick decision tree when translating a Hermes capability:

1. Is the capability mainly procedural guidance?
   - create or update a skill
2. Is the capability deterministic local automation?
   - add a script and reference it from the skill
3. Is the capability remote-system integration with an available connector?
   - use the connector and document the workflow in the skill
4. Is the capability absent and broadly reusable?
   - build an MCP server and document it with `native-mcp` or `mcporter`

## Examples

### Example: Hermes review tool

Hermes:

- run a PR review module over a diff

Claude Code:

- use the `github-code-review` skill
- fetch PR metadata and diff with the GitHub connector
- produce findings-first review comments

### Example: Hermes training trace exporter

Hermes:

- export a conversation trace into a fine-tuning format

Claude Code:

- use the `hermes-traj` skill
- write JSONL lines with task type, tags, and completion state

### Example: Hermes MCP-like extension

Hermes:

- implement a custom tool inside the runtime

Claude Code:

- scaffold a FastMCP server with `mcporter`
- register it with `native-mcp`
- use the server from Claude Code after configuration

## Summary

The main translation pattern is simple:

- Hermes internal behavior becomes explicit Claude Code procedure
- Hermes runtime tools become shell commands, connectors, or MCP servers
- Hermes memory becomes explicit project files
- Hermes reusable modules become local skills

That transparency is the core design advantage of `hermes-CCC`.
