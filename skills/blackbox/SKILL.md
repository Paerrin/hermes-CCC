---
name: blackbox
description: Delegate coding tasks to Blackbox AI CLI agent. Multi-model agent with built-in judge that runs tasks through multiple LLMs and picks the best result. Requires the blackbox CLI and a Blackbox AI API key.
version: 1.0.0
author: hermes-CCC (ported from Hermes Agent by NousResearch)
license: MIT
metadata:
  hermes:
    tags: [Coding-Agent, Blackbox, Multi-Agent, Judge, Multi-Model]
    related_skills: [claude-code, codex, hermes-agent]
---

# Blackbox CLI

Delegate coding tasks to [Blackbox AI](https://www.blackbox.ai/) via Claude Code's Bash tool. Blackbox is a multi-model coding agent CLI that dispatches tasks to multiple LLMs (Claude, Codex, Gemini, Blackbox Pro) and uses a judge to select the best implementation.

The CLI is [open-source](https://github.com/blackboxaicode/cli) (GPL-3.0, TypeScript, forked from Gemini CLI) and supports interactive sessions, non-interactive one-shots, checkpointing, MCP, and vision model switching.

## Purpose

Use Blackbox when you want the same task run across multiple frontier models and a judge to pick the winning implementation. Best for:

- High-stakes refactors where you want the strongest possible diff.
- "Second opinion" builds — run the same prompt through several providers.
- Exploratory tasks where you don't yet know which model style will produce the cleanest result.

## Activation Criteria

Trigger this skill when the user:

- Says "use blackbox", "delegate to blackbox", "run this through multiple models", or similar.
- Wants a judge/chairman to compare LLM outputs on the same task.
- Has the `blackbox` CLI installed and an API key configured.

Do **not** trigger when Claude Code can handle the task itself in-session — blackbox delegation costs credits and adds latency.

## Prerequisites

- Node.js 20+ installed.
- Blackbox CLI installed: `npm install -g @blackboxai/cli`
- Or install from source:
  ```bash
  git clone https://github.com/blackboxaicode/cli.git
  cd cli && npm install && npm install -g .
  ```
- API key from [app.blackbox.ai/dashboard](https://app.blackbox.ai/dashboard).
- Configured: run `blackbox configure` and enter your API key.
- Verify the CLI is on PATH before delegating: `command -v blackbox`.

## Procedure

### 1. One-Shot Tasks

Run a non-interactive one-shot in the target project directory:

```bash
cd /path/to/project && blackbox --prompt 'Add JWT authentication with refresh tokens to the Express API'
```

For quick scratch work in a throwaway repo:

```bash
cd $(mktemp -d) && git init && blackbox --prompt 'Build a REST API for todos with SQLite'
```

### 2. Background Mode (Long Tasks)

For tasks that take minutes, launch via the Bash tool's `run_in_background: true` so Claude Code can continue responding while the agent works:

1. Start in background:
   ```bash
   cd ~/project && blackbox --prompt 'Refactor the auth module to use OAuth 2.0'
   ```
   with `run_in_background=true`. Capture the Bash shell id that Claude Code returns.
2. Monitor progress using the Monitor or BashOutput tools against that shell id.
3. If Blackbox asks an interactive question, send input via the appropriate Claude Code shell input tool or kill and restart with `--yolo` to auto-approve.
4. Kill the shell if the session stalls or runs too long.

### 3. Checkpoints and Resume

Blackbox CLI has built-in checkpoint support for pausing and resuming tasks. After a run completes, Blackbox prints a checkpoint tag. Resume with a follow-up prompt:

```bash
cd ~/project && blackbox --resume-checkpoint 'task-abc123-2026-03-06' --prompt 'Now add rate limiting to the endpoints'
```

Use resume instead of starting a fresh session whenever you want to keep the task's context and token savings.

### 4. Session Commands

During an interactive session (`blackbox session`), use these slash commands:

| Command | Effect |
|---------|--------|
| `/compress` | Shrink conversation history to save tokens |
| `/clear` | Wipe history and start fresh |
| `/stats` | View current token usage |
| `Ctrl+C` | Cancel current operation |

### 5. PR Reviews

Clone to a temp directory to avoid modifying the working tree:

```bash
REVIEW=$(mktemp -d) && git clone https://github.com/user/repo.git "$REVIEW" && cd "$REVIEW" && gh pr checkout 42 && blackbox --prompt 'Review this PR against main. Check for bugs, security issues, and code quality.'
```

Read the resulting review output and summarize findings back to the user; do not push commits from the scratch clone.

### 6. Parallel Work

Spawn multiple Blackbox runs for independent tasks by launching each one as its own background Bash shell, each in a distinct working directory:

```bash
cd /tmp/issue-1 && blackbox --prompt 'Fix the login bug'
cd /tmp/issue-2 && blackbox --prompt 'Add unit tests for auth'
```

Both invocations should run with `run_in_background=true`. Monitor each shell separately and collect results when finished.

### 7. Multi-Model / Judge Mode

Blackbox's differentiator is running the same task through multiple models and judging the results. Configure the providers via `blackbox configure` — select multiple providers to enable the Chairman/judge workflow where the CLI evaluates outputs from different models and picks the best one.

Use multi-model mode when:

- The task is architecturally significant (design decisions, cross-cutting refactors).
- You want evidence of multiple model attempts for review.
- Credit budget allows — multi-model runs burn through credits faster than single-model.

## Key Flags

| Flag | Effect |
|------|--------|
| `--prompt "task"` | Non-interactive one-shot execution |
| `--resume-checkpoint "tag"` | Resume from a saved checkpoint |
| `--yolo` | Auto-approve all actions and model switches |
| `blackbox session` | Start interactive chat session |
| `blackbox configure` | Change settings, providers, models |
| `blackbox info` | Display system information |

## Vision Support

Blackbox automatically detects images in input and can switch to multimodal analysis. VLM modes:

- `"once"` — switch model for current query only.
- `"session"` — switch for the entire session.
- `"persist"` — stay on the current model (no switch).

## Token Limits

Control per-session token usage via `.blackboxcli/settings.json`:

```json
{
  "sessionTokenLimit": 32000
}
```

Lower the limit for long-running background sessions to keep cost bounded.

## Decision Rules

1. **Use non-interactive `--prompt` mode** for anything Claude Code launches — interactive `blackbox session` is only for a human driver in the terminal.
2. **Always run the command from the correct working directory** so the agent edits the intended repo.
3. **Prefer background mode for tasks > ~60 seconds** so Claude Code stays responsive.
4. **Do not kill shells for being slow** — poll first, kill only on genuine stall or runaway cost.
5. **Always verify prerequisites** (`command -v blackbox` and a configured API key) before delegating.
6. **Multi-model only when warranted** — single-model runs are cheaper and usually sufficient.
7. **Never ship blackbox output without review** — read the diff, run tests, and validate before handing back to the user.

## Outputs

A successful delegation produces:

- A Blackbox checkpoint tag (for resume).
- A set of file changes in the working directory.
- A console log of the agent's reasoning and tool calls.

Report back to the user:

1. Which task was delegated and to which directory.
2. Checkpoint tag (if any).
3. Summary of files changed and tests added.
4. Any remaining follow-ups Blackbox flagged.

## Failure Modes

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| `blackbox: command not found` | CLI not installed or not on PATH | `npm install -g @blackboxai/cli` then reopen shell |
| Immediate auth error | Missing/expired API key | Run `blackbox configure` and re-enter the key |
| Session hangs forever | Interactive prompt waiting on a human | Run with `--yolo` or kill and re-dispatch with narrower prompt |
| Out-of-credits error | Blackbox account balance exhausted | Top up on dashboard, or fall back to Claude Code in-session |
| Garbled output or no color | PTY not allocated for streaming use | Launch via the Bash tool with `run_in_background=true` and read logs instead of streaming |
| Checkpoint resume fails | Tag mismatch or stale working tree | List checkpoints with `blackbox info` and confirm the working directory state |

## Rules

1. **Use non-interactive `--prompt`** from Claude Code — never try to drive an interactive TUI through Bash.
2. **Always `cd` into the correct project** — keep the agent focused on the right directory.
3. **Background long tasks** — use `run_in_background=true` and monitor via shell output tools.
4. **Don't interfere** — monitor, don't kill sessions just because they're slow.
5. **Report results** — after completion, check what changed and summarize for the user.
6. **Credits cost money** — Blackbox uses a credit-based system; multi-model mode consumes credits faster.
7. **Check prerequisites** — verify `blackbox` CLI is installed and configured before attempting delegation.
