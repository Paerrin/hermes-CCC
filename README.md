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
| `skills/` (402) | 103 skills across 17 categories |
| `tools/` (68) | Claude Code native tools + MCP servers |
| `gateway/` platforms | Discord/Telegram via cc-channel plugin |
| `cron/` | CronCreate tool |
| `environments/` | Claude Code execution context |
| `plugins/memory/` | cc-channel-mem + auto-memory |

---

## Install

```bash
git clone https://github.com/Paerrin/hermes-CCC
cd hermes-CCC
chmod +x install.sh && ./install.sh
```

**Windows (PowerShell):**
```powershell
git clone https://github.com/Paerrin/hermes-CCC
cd hermes-CCC
.\install.ps1
```

**One-liner (Unix):**
```bash
curl -fsSL https://raw.githubusercontent.com/Paerrin/hermes-CCC/master/install.sh | bash
```

Restart Claude Code after install to activate all skills.

---

## Skill Catalog (103 skills)

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
| blackbox | `/blackbox` | Autonomous agent benchmark runner with multi-model judge |

### Software Development
| Skill | Invoke | Description |
|---|---|---|
| systematic-debugging | `/systematic-debugging` | 4-phase root cause investigation |
| test-driven-development | `/test-driven-development` | Red-Green-Refactor TDD cycle |
| subagent-driven-development | `/subagent-driven-development` | Parallel subagent workstreams |
| github-code-review | `/github-code-review` | Full PR code review workflow |
| github-pr-workflow | `/github-pr-workflow` | PR lifecycle automation |
| github-issues | `/github-issues` | Issue management and triage |
| plan | `/plan` | Write a concrete markdown plan without executing |
| requesting-code-review | `/requesting-code-review` | Delegate PR review to a subagent |
| writing-plans | `/writing-plans` | Structured planning workflow for complex tasks |
| codebase-inspection | `/codebase-inspection` | Deep repo archaeology and code navigation |
| github-auth | `/github-auth` | GitHub token setup and credential management |
| github-repo-management | `/github-repo-management` | Repo settings, branch rules, webhooks, access |

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
| accelerate | `/accelerate` | HuggingFace Accelerate for distributed training |
| clip | `/clip` | OpenAI CLIP vision-language model |
| evaluation | `/evaluation` | LLM evaluation harness and benchmarking |
| guidance | `/guidance` | Constrained generation with grammar/regex |
| huggingface-tokenizers | `/huggingface-tokenizers` | Fast tokenizer training and analysis |
| inference | `/inference` | Inference server selection and configuration |
| lambda-labs | `/lambda-labs` | Reserved GPU cloud instances |
| llava | `/llava` | Multimodal vision-language model serving |
| modal | `/modal` | Serverless GPU cloud for ML workloads |
| models | `/models` | Model selection, download, and evaluation routing |
| nemo-curator | `/nemo-curator` | NVIDIA NeMo data curation pipeline |
| peft | `/peft` | Parameter-efficient fine-tuning (LoRA, QLoRA, etc.) |
| pytorch-fsdp | `/pytorch-fsdp` | Fully Sharded Data Parallel training |
| pytorch-lightning | `/pytorch-lightning` | Structured PyTorch training loops |
| saelens | `/saelens` | Sparse autoencoder training and analysis |
| simpo | `/simpo` | Simple preference optimization fine-tuning |
| slime | `/slime` | Scalable LLM inference and model efficiency |
| tensorrt-llm | `/tensorrt-llm` | NVIDIA TensorRT-LLM optimized inference |
| torchtitan | `/torchtitan` | PyTorch-native large model training |
| training | `/training` | Training framework selection and setup |
| vector-databases | `/vector-databases` | Vector DB selection and integration routing |

### Research
| Skill | Invoke | Description |
|---|---|---|
| arxiv | `/arxiv` | arXiv paper search and download |
| research-paper-writing | `/research-paper-writing` | Academic paper workflow with LaTeX |
| blogwatcher | `/blogwatcher` | Monitor RSS feeds and blogs |
| duckduckgo-search | `/duckduckgo-search` | Free web search, no API key needed |
| polymarket | `/polymarket` | Prediction market probability data |
| llm-wiki | `/llm-wiki` | LLM knowledge base and model comparison |
| bioinformatics | `/bioinformatics` | Genomics, proteomics, and sequence analysis |
| domain-intel | `/domain-intel` | Domain and threat intelligence research |
| drug-discovery | `/drug-discovery` | Computational drug discovery and molecular design |
| gitnexus-explorer | `/gitnexus-explorer` | Cross-repo code search and exploration |
| parallel-cli | `/parallel-cli` | GNU Parallel for concurrent CLI workloads |
| qmd | `/qmd` | Quarto document authoring and rendering |
| scrapling | `/scrapling` | Fast, resilient web scraping |

### Productivity
| Skill | Invoke | Description |
|---|---|---|
| google-workspace | `/google-workspace` | Gmail, Drive, Sheets, Calendar automation |
| linear | `/linear` | Linear issue and project management |
| jupyter-live-kernel | `/jupyter-live-kernel` | Notebook execution and kernel management |
| maps | `/maps` | Location search, routing, and geo data |
| nano-pdf | `/nano-pdf` | Lightweight PDF reading and extraction |
| ocr-and-documents | `/ocr-and-documents` | OCR, document parsing, and extraction |
| powerpoint | `/powerpoint` | Presentation creation and editing |
| obsidian | `/obsidian` | Obsidian vault management and note operations |

### Creative
| Skill | Invoke | Description |
|---|---|---|
| excalidraw | `/excalidraw` | Diagrams and whiteboard sketches via MCP |
| manim-video | `/manim-video` | Mathematical animations with Manim |
| architecture-diagram | `/architecture-diagram` | System architecture diagrams |
| ascii-art | `/ascii-art` | ASCII art generation and conversion |
| ascii-video | `/ascii-video` | Video to ASCII art conversion |
| baoyu-infographic | `/baoyu-infographic` | Data-driven infographic generation |
| creative-ideation | `/creative-ideation` | Structured brainstorming and idea generation |
| p5js | `/p5js` | Generative art and creative coding with p5.js |
| popular-web-designs | `/popular-web-designs` | Replicate and riff on popular UI patterns |
| songwriting-and-ai-music | `/songwriting-and-ai-music` | AI-assisted songwriting and music generation |

### Infrastructure
| Skill | Invoke | Description |
|---|---|---|
| docker-management | `/docker-management` | Container, image, Compose management |
| native-mcp | `/native-mcp` | MCP server integration in Claude Code |
| mcporter | `/mcporter` | Convert any CLI tool into an MCP server |
| fastmcp | `/fastmcp` | Build MCP servers with FastMCP |
| webhook-subscriptions | `/webhook-subscriptions` | Webhook setup and subscription management |

### Communication
| Skill | Invoke | Description |
|---|---|---|
| one-three-one-rule | `/one-three-one-rule` | 1-3-1 structured decision and proposal format |

### Email
| Skill | Invoke | Description |
|---|---|---|
| himalaya | `/himalaya` | CLI email client — read, send, organize |
| agentmail | `/agentmail` | Agent-native email automation |

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
| gif-search | `/gif-search` | Search and embed GIFs via Tenor/Giphy |
| heartmula | `/heartmula` | Heart rate and biometric data integration |
| songsee | `/songsee` | Music discovery and lyrics lookup |

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
└── skills/             ← 103 skill directories
    ├── hermes-route/
    ├── hermes-memory/
    └── ...
```

---

## Contributors

| Contributor | Role |
|---|---|
| [AlexAI-MCP](https://github.com/AlexAI-MCP) | Creator & Maintainer |
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
