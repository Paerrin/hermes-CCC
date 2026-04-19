---
name: training
description: Fine-tuning, RLHF/DPO/GRPO/SimPO training, distributed training frameworks, and optimization tools for training LLMs and other models. Use when the user wants to fine-tune, align, pretrain, or distill a model. Routes to leaf skills (axolotl, trl-fine-tuning, unsloth, pytorch-fsdp, pytorch-lightning, torchtitan, accelerate, peft, simpo, slime, grpo-rl-training) and defines the decision rules for framework and algorithm choice.
version: 1.0.0
author: hermes-CCC (ported from Hermes Agent by NousResearch)
license: MIT
metadata:
  hermes:
    tags: [training, fine-tuning, rlhf, dpo, grpo, simpo, distributed, fsdp, lightning, torchtitan, accelerate, peft, lora, axolotl, trl, unsloth, mlops]
---

# Training - Fine-Tune, Align, and Scale Model Training

## Purpose

Route any training-style workload to the correct framework and algorithm. Cover SFT, parameter-efficient tuning (LoRA/QLoRA), preference optimization (DPO/SimPO/KTO), RL (GRPO, PPO, RLOO), distributed training (FSDP, Megatron, DeepSpeed), and full pretraining. Make the decision explicit: framework, parallelism, precision, optimizer, and evaluation hooks all chosen on purpose.

## Activation criteria

Activate when the user:

- Says "fine-tune", "train", "pretrain", "SFT", "continued pretraining", "distill", "align".
- Mentions an algorithm: DPO, GRPO, SimPO, KTO, PPO, RLOO, ORPO, RLHF.
- Mentions a framework: axolotl, TRL, unsloth, Lightning, FSDP, DeepSpeed, Megatron, torchtitan.
- Mentions LoRA/QLoRA, adapters, PEFT, Q-LoRA, DoRA.
- Asks about scaling: "train on N GPUs", "multi-node", "gradient accumulation", "ZeRO-3", "tensor parallel".

Do not activate for serving the resulting checkpoint (use `inference`), for evaluating it (use `evaluation`), or for embedding retrieval (use `vector-databases`).

## Leaf skills and when to pick each

High-level training orchestrators (pick one):

- `axolotl` - YAML-driven SFT, DPO, QLoRA pipelines on top of transformers. Default for "I have a JSONL and want to fine-tune a 7B-70B model".
- `trl-fine-tuning` - HuggingFace TRL for SFT, DPO, RLOO, PPO, GRPO. Use when you need algorithmic control or a custom reward.
- `unsloth` - 2x faster QLoRA / LoRA SFT on single-GPU with low VRAM. Default for consumer GPUs and < 16B models.

Distributed training frameworks (pick one per run):

- `pytorch-fsdp` - native PyTorch Fully Sharded Data Parallel. Default large-scale backend for HF-style training.
- `pytorch-lightning` - structured training loops, multi-GPU, mixed precision, plug-in strategies. Good when you want clean callbacks, not boilerplate.
- `torchtitan` - reference pretraining stack (3D parallelism, torch.compile). Use for research-scale pretraining.
- `accelerate` - thin wrapper unifying DDP / FSDP / DeepSpeed launch. Default when you want "4 lines to go distributed".

Algorithm / adapter skills:

- `peft` - LoRA, QLoRA, DoRA, prefix tuning, IA3 adapters. Required companion for any parameter-efficient method.
- `simpo` - Simple Preference Optimization (DPO variant with reference-free length normalization). Use instead of DPO when you can.
- `slime` - async RL scheduler for LLM training. Use when the user wants GRPO/PPO at scale with rollouts.
- `grpo-rl-training` - reasoning-focused GRPO fine-tuning. Use for chain-of-thought or task-specific reasoning gains.

## Procedure

1. Classify the objective:
   - Capability transfer / instruction following: **SFT** via axolotl/trl/unsloth.
   - Preference alignment / style: **DPO or SimPO**.
   - Reasoning / reward-driven behavior: **GRPO / RLOO / PPO**.
   - Pretraining / continued pretraining: **torchtitan or axolotl pretrain**.
2. Classify the scale:
   - Single GPU, <= 16B, LoRA/QLoRA: `unsloth`.
   - 1-8 GPUs single node, any method: `axolotl` + `peft`.
   - Multi-node, 70B+, full-weights: `pytorch-fsdp` or `torchtitan`.
3. Pick precision: BF16 is default; FP8 only with supported hardware and validated stability.
4. Pick parallelism:
   - ZeRO-2 / FSDP-SHARD_GRAD_OP up to ~13B per node.
   - FSDP full-shard + activation checkpointing beyond.
   - Tensor / pipeline parallel only when a single layer no longer fits.
5. Wire eval hooks: log to W&B, run `lm-evaluation-harness` at checkpoints, not just final.
6. Decide checkpoint cadence: "every N steps" and "last K kept" to bound disk.

## Decision rules

- Always prefer SimPO over DPO unless there is a strong reason (reference model available and needed).
- Always prefer QLoRA + a single GPU over full-weight training when VRAM is the bottleneck and model <= 70B.
- Use FSDP (native) over DeepSpeed for HF-centric stacks; DeepSpeed only when ZeRO-Infinity or CPU-offload is needed.
- Gradient accumulation is free effective-batch-size; prefer it over fragile micro-batch tuning.
- Start with LR 2e-5 for SFT on 7B, 1e-4 for LoRA, 5e-7 for DPO/SimPO; tune from there.
- Tokenize once, save a pre-tokenized dataset; re-tokenizing per run wastes hours.

## Outputs

- Chosen framework + algorithm with one-line justification.
- A YAML or training script ready to launch.
- Launch command with correct launcher (`accelerate launch`, `torchrun`, `deepspeed`).
- Estimated GPU-hours and VRAM per device.
- Eval plan: checkpoints, harness, W&B project.
- Release plan: where weights and tokenizer will be pushed (HF Hub, S3, Modal volume).

## Failure modes

- Using AdamW 32-bit on a memory-bound run: swap to 8-bit AdamW (`bitsandbytes`) or paged AdamW.
- Forgetting `gradient_checkpointing` at 13B+ with FSDP SHARD_GRAD_OP: OOM.
- Training DPO with wrong chat template: silent quality loss; always dry-run `tokenizer.apply_chat_template` on one sample and print.
- Running RL without a pinned seed or environment version: unreproducible.
- No evaluation hooks: cannot distinguish a bad run from a good one until too late.

## Commands

axolotl SFT (YAML-driven):

```bash
pip install axolotl
axolotl train configs/llama3_8b_sft.yml
# minimal config: base_model, datasets[], sequence_len, adapter: qlora, lr, optimizer, output_dir
```

unsloth QLoRA SFT on single GPU:

```python
from unsloth import FastLanguageModel
model, tok = FastLanguageModel.from_pretrained(
    "unsloth/Meta-Llama-3.1-8B-Instruct",
    max_seq_length=4096, load_in_4bit=True,
)
model = FastLanguageModel.get_peft_model(model, r=16, lora_alpha=32, target_modules="all-linear")
# then standard transformers Trainer
```

TRL SimPO:

```python
from trl import SimPOTrainer, SimPOConfig
cfg = SimPOConfig(output_dir="out", beta=2.0, gamma_beta_ratio=0.5,
                  learning_rate=5e-7, per_device_train_batch_size=2,
                  gradient_accumulation_steps=8, bf16=True, num_train_epochs=1)
trainer = SimPOTrainer(model=model, args=cfg, train_dataset=pref_ds, tokenizer=tok)
trainer.train()
```

accelerate launch (FSDP):

```bash
accelerate config  # once
accelerate launch --config_file fsdp.yaml train.py
```

FSDP native launch:

```bash
torchrun --nproc_per_node=8 train.py --fsdp full_shard --bf16
```

## Hand-off contract

When routing, provide:

- Base model + revision
- Dataset path + format (JSONL, parquet, HF dataset id)
- Task type (SFT / DPO / SimPO / GRPO / pretrain)
- Hardware (nodes, GPUs per node, VRAM, interconnect)
- Budget (GPU-hours, wallclock)
- Target output (adapter, full weights, merged HF repo)
- Eval plan and W&B project
