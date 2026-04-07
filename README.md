# hermes-CCC

> Hermes Agent, faithfully ported to Claude Code Channel (CCC).

**hermes-CCC** brings the power of [Hermes Agent](https://github.com/NousResearch/hermes-agent) by NousResearch into Claude Code's native skill system — no separate process, no OAuth, no lock-in. Everything runs inside Claude Code.

Built by [AlexAI-MCP](https://github.com/AlexAI-MCP).

---

## What's Ported

| Hermes Component | hermes-CCC Equivalent |
|---|---|
| `agent/` brain | `/hermes-route`, `/hermes-memory`, `/hermes-skill`, `/hermes-traj`, `/hermes-persona`, `/hermes-compress`, `/hermes-search`, `/hermes-insights` |
| Honcho user modeling | `/honcho` |
| `skills/` (402) | 46 core skills across 10 categories |
| `tools/` (68) | Claude Code native tools + MCP servers |
| `gateway/` platforms | Discord/Telegram via cc-channel plugin |
| `cron/` | CronCreate tool |
| `environments/` | Claude Code execution context |
| `plugins/memory/` | cc-channel-mem + auto-memory |

---

## Install

```bash
git clone https://github.com/AlexAI-MCP/hermes-CCC
cd hermes-CCC
chmod +x install.sh && ./install.sh
```

**Windows (PowerShell):**
```powershell
git clone https://github.com/AlexAI-MCP/hermes-CCC
cd hermes-CCC
.\install.ps1
```

**One-liner (Unix):**
```bash
curl -fsSL https://raw.githubusercontent.com/AlexAI-MCP/hermes-CCC/main/install.sh | bash
```

Restart Claude Code after install to activate all skills.

---

## Skill Catalog (46 skills)

### Core Brain (Hermes Identity)
| Skill | Invoke | Description |
|---|---|---|
| hermes-route | `/hermes-route` | Analyze task complexity → recommend opus/sonnet/haiku |
| hermes-memory | `/hermes-memory` | Memory prefetch/sync/nudge (memory_manager port) |
| hermes-skill | `/hermes-skill` | Skill lifecycle: create, improve, audit |
| hermes-traj | `/hermes-traj` | Log interaction trajectories for analysis/RL |
| hermes-persona | `/hermes-persona` | Switch persona: researcher/coder/analyst/creative/advisor |
| hermes-compress | `/hermes-compress` | Compress context, extract session state |
| hermes-search | `/hermes-search` | Search past sessions, memory files, project history |
| hermes-insights | `/hermes-insights` | Usage analytics and productivity insights |
| honcho | `/honcho` | Cross-session user modeling (dialectic user profile) |

### Software Development
| Skill | Invoke | Description |
|---|---|---|
| systematic-debugging | `/systematic-debugging` | 4-phase root cause investigation |
| test-driven-development | `/test-driven-development` | Red-Green-Refactor TDD cycle |
| subagent-driven-development | `/subagent-driven-development` | Parallel subagent workstreams |
| github-code-review | `/github-code-review` | Full PR code review workflow |
| github-pr-workflow | `/github-pr-workflow` | PR lifecycle automation |
| github-issues | `/github-issues` | Issue management and triage |

### MLOps / AI
| Skill | Invoke | Description |
|---|---|---|
| vllm | `/vllm` | OpenAI-compatible LLM inference server |
| llama-cpp | `/llama-cpp` | Local GGUF inference (CPU+GPU) |
| whisper | `/whisper` | Speech recognition and transcription |
| stable-diffusion | `/stable-diffusion` | Text-to-image with diffusers |
| grpo-rl-training | `/grpo-rl-training` | GRPO/RL fine-tuning with TRL |
| huggingface-hub | `/huggingface-hub` | Model/dataset download, upload, search |
| flash-attention | `/flash-attention` | 2-4x attention speedup, 10-20x memory savings |
| instructor | `/instructor` | Structured Pydantic outputs from any LLM |
| chroma | `/chroma` | Open-source vector DB for local RAG |
| qdrant | `/qdrant` | Production vector search engine |
| faiss | `/faiss` | Ultra-fast in-memory vector similarity search |
| pinecone | `/pinecone` | Managed cloud vector database |

### Research
| Skill | Invoke | Description |
|---|---|---|
| arxiv | `/arxiv` | arXiv paper search and download |
| research-paper-writing | `/research-paper-writing` | Academic paper workflow with LaTeX |
| blogwatcher | `/blogwatcher` | Monitor RSS feeds and blogs |
| duckduckgo-search | `/duckduckgo-search` | Free web search, no API key needed |
| polymarket | `/polymarket` | Prediction market probability data |

### Productivity
| Skill | Invoke | Description |
|---|---|---|
| google-workspace | `/google-workspace` | Gmail, Drive, Sheets, Calendar automation |
| linear | `/linear` | Linear issue and project management |
| jupyter-live-kernel | `/jupyter-live-kernel` | Notebook execution and kernel management |

### Creative
| Skill | Invoke | Description |
|---|---|---|
| excalidraw | `/excalidraw` | Diagrams and whiteboard sketches via MCP |
| manim-video | `/manim-video` | Mathematical animations with Manim |

### Infrastructure
| Skill | Invoke | Description |
|---|---|---|
| docker-management | `/docker-management` | Container, image, Compose management |
| native-mcp | `/native-mcp` | MCP server integration in Claude Code |
| mcporter | `/mcporter` | Convert any CLI tool into an MCP server |

### Security / OSINT
| Skill | Invoke | Description |
|---|---|---|
| sherlock | `/sherlock` | Username search across 400+ social networks |
| oss-forensics | `/oss-forensics` | Supply chain risk and dependency analysis |
| one-password | `/one-password` | 1Password CLI secret management |

### Blockchain
| Skill | Invoke | Description |
|---|---|---|
| base-blockchain | `/base-blockchain` | Base (Ethereum L2) on-chain data queries |
| solana | `/solana` | Solana blockchain data via JSON RPC |

### Media
| Skill | Invoke | Description |
|---|---|---|
| youtube-content | `/youtube-content` | Download, transcript, and research YouTube |

---

## Relationship to Hermes Agent

This is a Claude Code-native reinterpretation of Hermes operational patterns, not a byte-for-byte clone. The key differences:

- **No separate process** — everything runs inside Claude Code
- **No OAuth** — uses Claude Code's native auth
- **No gateway** — uses existing Discord/Telegram MCP plugins
- **No model dependency** — works with any Claude model

See [`docs/migration-guide.md`](./docs/migration-guide.md) for migration guidance from Hermes Agent.

---

## Package Layout

```
hermes-CCC/
├── README.md
├── install.sh          ← Unix/WSL installer
├── install.ps1         ← Windows PowerShell installer
├── CLAUDE.md           ← Maintainer notes
├── LICENSE             ← MIT
├── docs/
│   ├── migration-guide.md
│   └── tool-mapping.md
├── .github/
│   └── workflows/
│       └── validate.yml
└── skills/             ← 46 skill directories
    ├── hermes-route/
    ├── hermes-memory/
    └── ...
```

---

## Contributors

| Contributor | Role |
|---|---|
| [AlexAI-MCP](https://github.com/AlexAI-MCP) (yongwook.lee@daewooenc.com) | Creator & Maintainer |
| Claude (Anthropic) | Skill design, porting, and architecture |
| Codex (OpenAI) | Parallel skill generation and build automation |

---

## Acknowledgements

hermes-CCC is built on top of the excellent work done by the [NousResearch](https://nousresearch.com) team on [Hermes Agent](https://github.com/NousResearch/hermes-agent). The original framework's design — its brain architecture, skill system, memory management, and platform integrations — served as the direct blueprint for this port.

A sincere thank you to the Hermes Agent community and all contributors who made the original project what it is. This package exists because of your work.

hermes-CCC is an independent port. Not affiliated with NousResearch.

---

## License

MIT © 2026 AlexAI-MCP
