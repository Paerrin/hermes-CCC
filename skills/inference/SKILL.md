---
name: inference
description: Model serving, quantization (GGUF/GPTQ/AWQ), structured output, inference optimization, and model surgery for deploying and running LLMs. Use when the user needs to run a model (local or hosted), quantize weights, constrain decoding to a schema, squeeze latency, or modify model architecture. Routes to leaf skills (vllm, llama-cpp, outlines, obliteratus, tensorrt-llm, guidance) and defines decision rules between them.
version: 1.0.0
author: hermes-CCC (ported from Hermes Agent by NousResearch)
license: MIT
metadata:
  hermes:
    tags: [inference, serving, quantization, structured-output, gguf, gptq, awq, vllm, llama-cpp, outlines, tensorrt-llm, mlops]
---

# Inference - Serve, Quantize, and Constrain LLMs

## Purpose

Route and execute model-serving work end to end: pick the right engine, pick the right quantization, constrain outputs to a schema when needed, and tune for throughput or latency. Use this skill as the entry point whenever the user wants to "run" or "deploy" a model, or to make an existing deployment faster, cheaper, or more reliable.

## Activation criteria

Activate when the user:

- Says "serve", "deploy", "host", "run this model", "inference endpoint", "OpenAI-compatible API".
- Asks for quantization: "convert to GGUF", "AWQ", "GPTQ", "Q4_K_M", "4-bit", "8-bit", "fit on X GB VRAM".
- Needs structured output: "force JSON", "constrain to schema", "regex decode", "grammar", "tool call schema".
- Requests latency/throughput tuning: "tok/s", "batch size", "speculative decoding", "prefix caching", "continuous batching".
- Wants model surgery: "abliterate refusal", "steer", "remove safety layer", "merge LoRAs".

Do not activate for training (use `training`), for embedding retrieval (use `vector-databases`), or for raw benchmark runs (use `evaluation`).

## Leaf skills and when to pick each

- `vllm` - production-grade serving on NVIDIA GPUs. PagedAttention, continuous batching, speculative decoding, OpenAI-compatible server. Default choice for multi-user serving on A100/H100/L40S.
- `llama-cpp` - CPU + Metal + CUDA inference with GGUF. Best for laptops, Apple Silicon, edge, small VRAM, and offline demos.
- `tensorrt-llm` - lowest-latency option on NVIDIA; requires engine build step. Use when tok/s or TTFT is the binding constraint and you can afford a build pipeline.
- `outlines` - grammar/regex/JSON-schema constrained decoding. Use when output must parse or match a contract. Works with transformers and vllm.
- `guidance` - programmatic prompting and constrained generation with a richer control-flow DSL than outlines. Use for multi-turn templated agents where you want code-like flow.
- `obliteratus` - model surgery: refusal-direction ablation, activation steering, layer surgery. Use only with explicit, legitimate research intent; document rationale.

## Procedure

1. Ask three questions if unknown:
   - Hardware available (GPU model + VRAM, or CPU/Apple Silicon)
   - Concurrency target (single user vs. N concurrent requests)
   - Output contract (freeform text, JSON schema, tool calls, regex)
2. Pick the engine:
   - GPU + concurrency > 1 + OpenAI API shape: `vllm`.
   - GPU + lowest latency + willing to pre-build: `tensorrt-llm`.
   - CPU, Apple Silicon, laptop, or < 8 GB VRAM: `llama-cpp`.
3. Pick quantization:
   - VRAM fits full precision BF16: skip quantization.
   - Need 4-bit: GPTQ or AWQ on GPU (vllm/transformers), or `Q4_K_M` GGUF on `llama-cpp`.
   - Extreme constraints: `Q2_K` / `IQ2_XS` GGUF, accept quality loss.
4. If structured output is required, layer `outlines` or `guidance` on top of the chosen engine.
5. If architectural edits are needed, stop and route to `obliteratus`; do not silently modify weights.
6. Document the deployment: model id, quantization, engine version, flags, hardware, commit hash.

## Decision rules

- Never deploy a quantized model without comparing 1-2 benchmark numbers to the BF16 baseline.
- Default KV-cache dtype should match weight dtype unless throughput is desperate.
- Batch size > 1 with greedy decoding is fine; with sampling, log the seed for reproducibility.
- Free-text JSON "please return JSON" is not a contract - use schema-constrained decoding whenever a parser downstream can fail.
- Enable prefix caching (`--enable-prefix-caching` in vllm) whenever prompts share long system prefixes.
- For agentic tool use, prefer schema-constrained decoding over post-hoc JSON parsing.

## Outputs

- A chosen engine and rationale tied to the three activation questions.
- A concrete serve command plus an example client call (curl or OpenAI SDK).
- A quantization plan with expected VRAM and expected quality delta.
- A structured-output block (JSON schema or regex) when the output must parse.
- A rollback plan: which known-good checkpoint to fall back to.

## Failure modes

- Deploying a 4-bit model without an eval delta vs BF16: reject, run MMLU + HumanEval minimum.
- Running with continuous batching but a max-sequence cap too low: requests get truncated silently; always set `--max-model-len` explicitly.
- Forgetting `--enable-prefix-caching` on agentic workloads: 2-5x throughput left on the table.
- Using `temperature=0` with speculative decoding where the draft/target mismatch yields wrong tokens; verify with a sampling seed.
- Abliterating or steering a model without logging which layers and coefficients were touched: forbidden; surgeries must be reproducible.

## Commands

vLLM OpenAI-compatible server:

```bash
pip install vllm
vllm serve meta-llama/Meta-Llama-3.1-8B-Instruct \
  --dtype bfloat16 \
  --max-model-len 8192 \
  --enable-prefix-caching \
  --port 8000
# curl -s http://localhost:8000/v1/models
```

llama.cpp GGUF server:

```bash
# assumes llama.cpp built; model pre-downloaded as .gguf
./llama-server -m models/Meta-Llama-3.1-8B-Instruct-Q4_K_M.gguf \
  -c 8192 --host 0.0.0.0 --port 8080
```

Outlines structured JSON:

```python
from outlines import models, generate
from pydantic import BaseModel

class Answer(BaseModel):
    city: str
    population: int

model = models.vllm("meta-llama/Meta-Llama-3.1-8B-Instruct")
gen = generate.json(model, Answer)
print(gen("Give me a world capital.", max_tokens=128))
```

TensorRT-LLM engine build (sketch):

```bash
trtllm-build --checkpoint_dir ./tllm_ckpt \
  --output_dir ./engines/llama3-8b \
  --gemm_plugin bfloat16 \
  --max_input_len 4096 --max_output_len 1024
```

Quantize to GGUF Q4_K_M:

```bash
# inside llama.cpp repo
python convert_hf_to_gguf.py models/Meta-Llama-3.1-8B-Instruct --outtype bf16
./llama-quantize models/Meta-Llama-3.1-8B-Instruct/ggml-model-bf16.gguf \
  models/Meta-Llama-3.1-8B-Instruct-Q4_K_M.gguf Q4_K_M
```

## Hand-off contract

When routing to a leaf skill, include:

- Model repo and revision
- Hardware (GPU model, count, VRAM)
- Target concurrency and SLA (p50/p95 latency, min tok/s)
- Quantization choice and expected VRAM
- Output contract (freeform / JSON schema / regex / tools)
- Where the endpoint must live (localhost, systemd, Docker, Modal, etc.)
