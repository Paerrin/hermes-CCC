---
name: fastmcp
description: Build Model Context Protocol (MCP) servers in Python using the FastMCP framework. Expose tools, resources, and prompts to Claude Code and any MCP-compatible client. Use when the user asks to create an MCP server, convert a library/API into MCP tools, add tools to Claude Code, write custom tool integrations, or scaffold a FastMCP project.
version: 1.0.0
author: hermes-CCC (ported from Hermes Agent by NousResearch)
license: MIT
metadata:
  hermes:
    tags: [mcp, fastmcp, python, tools, integration, server, protocol, claude-code]
    related_skills: [native-mcp, webhook-subscriptions, mcporter]
---

# FastMCP

Build Model Context Protocol (MCP) servers with the FastMCP Python framework. FastMCP is the fast, Pythonic way to expose functions, APIs, files, and system capabilities as MCP tools, resources, and prompts that any MCP-aware client (Claude Code, Claude Desktop, Cursor, continue.dev, etc.) can call.

## When to Use

- User wants to add a new tool or integration to Claude Code
- User wants to wrap a Python library, a REST API, or a CLI as MCP tools
- User asks to "build an MCP server", "create MCP tools", "expose X as MCP"
- User wants a lightweight alternative to writing the raw JSON-RPC protocol by hand
- User asks to convert a Python function into an MCP tool with one decorator

## What FastMCP gives you

- `@mcp.tool` — turn any Python function into a callable tool with automatic schema from type hints
- `@mcp.resource` — expose files, database rows, or API responses as readable resources
- `@mcp.prompt` — expose reusable prompt templates
- Transport handling: `stdio` (default), `streamable-http`, `sse`, `ws`
- Pydantic-based schema generation from type hints
- Async support out of the box
- Structured logging, progress notifications, elicitation (asking the user)

## Install

```bash
# Using uv (preferred)
uv pip install fastmcp

# Or pip
pip install fastmcp
```

Pin `fastmcp>=2.0` for current features. The older `mcp[cli]` package is a different SDK — do not mix the two.

## Minimal Server

`server.py`:

```python
from fastmcp import FastMCP

mcp = FastMCP("demo")

@mcp.tool
def add(a: int, b: int) -> int:
    """Add two integers and return the sum."""
    return a + b

@mcp.tool
def greet(name: str, enthusiastic: bool = False) -> str:
    """Greet a user by name."""
    greeting = f"Hello, {name}"
    return greeting + ("!" if enthusiastic else ".")

if __name__ == "__main__":
    mcp.run()  # defaults to stdio transport
```

Run it standalone to validate:

```bash
python server.py
# Then in another terminal:
fastmcp dev server.py     # interactive inspector
```

## Wire It into Claude Code

Add the server to `.mcp.json` (project-scoped) or `~/.claude.json` (user-scoped):

```json
{
  "mcpServers": {
    "demo": {
      "command": "python",
      "args": ["/absolute/path/to/server.py"],
      "env": {}
    }
  }
}
```

Reload Claude Code. The tools should appear prefixed as `mcp__demo__add`, `mcp__demo__greet`.

For `uv` projects, prefer launching through uv so dependencies resolve automatically:

```json
{
  "mcpServers": {
    "demo": {
      "command": "uv",
      "args": ["--directory", "/absolute/path/to/project", "run", "server.py"]
    }
  }
}
```

## Tools — core patterns

### Type-hint-driven schemas

```python
from pydantic import Field
from typing import Annotated

@mcp.tool
def search(
    query: Annotated[str, Field(description="Search term")],
    limit: Annotated[int, Field(ge=1, le=100, description="Max results")] = 10,
) -> list[dict]:
    """Search the local index."""
    return do_search(query, limit)
```

Field descriptions propagate into the MCP tool schema, which helps the model call the tool correctly.

### Async tools

```python
import httpx

@mcp.tool
async def fetch_json(url: str) -> dict:
    """GET a URL and return decoded JSON."""
    async with httpx.AsyncClient(timeout=20) as client:
        r = await client.get(url)
        r.raise_for_status()
        return r.json()
```

### Returning structured data

Tools may return dicts, lists, Pydantic models, strings, or `bytes`. FastMCP serializes them. Return Pydantic models to keep types honest:

```python
from pydantic import BaseModel

class Hit(BaseModel):
    id: str
    score: float
    title: str

@mcp.tool
def top_hits(query: str) -> list[Hit]:
    ...
```

### Progress + logging

```python
from fastmcp import Context

@mcp.tool
async def long_job(n: int, ctx: Context) -> str:
    for i in range(n):
        await ctx.report_progress(i, n)
        await ctx.info(f"step {i}")
    return "done"
```

Inject `ctx: Context` anywhere in the signature and FastMCP will wire it up.

## Resources

Resources are read-only data the client can fetch by URI.

```python
@mcp.resource("config://app")
def app_config() -> str:
    return open("config.toml").read()

@mcp.resource("users://{user_id}/profile")
def user_profile(user_id: str) -> dict:
    return load_profile(user_id)
```

URIs with placeholders become parameterized resources — the client lists a template, then fetches a concrete URI.

## Prompts

```python
@mcp.prompt
def code_review(language: str, code: str) -> str:
    return f"Review this {language} code for bugs, clarity, and security:\n\n{code}"
```

Prompts are templates the client surfaces to the user as slash commands or menu items.

## Transports

| Transport | When to use | Command |
|---|---|---|
| `stdio` (default) | Local subprocess launched by a client | `mcp.run()` |
| `streamable-http` | Remote server, long-running, modern HTTP streaming | `mcp.run(transport="streamable-http", host="0.0.0.0", port=8000)` |
| `sse` | Legacy Server-Sent Events clients | `mcp.run(transport="sse", port=8000)` |
| `ws` | WebSocket clients | `mcp.run(transport="ws", port=8000)` |

For remote servers, put the process behind a reverse proxy with TLS and authentication. Never expose an un-authenticated MCP server on the public internet.

## Testing

Use FastMCP's built-in in-process client for unit tests — no subprocess, no network:

```python
import asyncio
from fastmcp import Client
from server import mcp

async def test_add():
    async with Client(mcp) as client:
        result = await client.call_tool("add", {"a": 2, "b": 3})
        assert result.data == 5

asyncio.run(test_add())
```

For end-to-end smoke tests, `fastmcp dev server.py` opens a web inspector that lists tools, resources, and prompts and lets you invoke them.

## Decision rules

- Prefer **tools** for actions (anything with side effects or computation).
- Prefer **resources** for data the client should read, list, or cache.
- Prefer **prompts** for reusable prompt templates the user will trigger by name.
- Keep tool inputs small and explicit — never accept an open-ended `kwargs: dict` unless you also document every field.
- Put expensive imports behind lazy initialization if the module is loaded just to list tools.
- Log to `ctx.info` / `ctx.warning` / `ctx.error` rather than `print` — stdout on stdio transport is the protocol channel and printing to it will corrupt it.

## Outputs

- A runnable `server.py` (or package) exposing `@mcp.tool` / `@mcp.resource` / `@mcp.prompt` functions.
- A `.mcp.json` (or `~/.claude.json`) entry that launches it.
- A short test file using `fastmcp.Client` against the in-process server.

## Failure modes

- **Tool not appearing in Claude Code** — check `.mcp.json` syntax, restart Claude Code, and verify the `command` works from a clean shell.
- **"Unexpected token" on startup** — something printed to stdout on a stdio transport. Audit for stray `print()` calls and library banners.
- **Schema shows `any`** — missing or too-loose type hints. Add `Annotated[..., Field(...)]` or a Pydantic model.
- **Timeouts** — default client timeout is short. Either make the tool async and use `ctx.report_progress`, or split the work into smaller tools.
- **Auth on HTTP transports** — FastMCP does not ship auth; run behind a reverse proxy, add a bearer-token middleware, or use mTLS.

## References

- FastMCP docs: https://gofastmcp.com
- MCP spec: https://modelcontextprotocol.io
- Related skills in this pack: `native-mcp`, `mcporter`, `webhook-subscriptions`
