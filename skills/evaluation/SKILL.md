---
name: evaluation
description: Model evaluation benchmarks, experiment tracking, data curation, tokenizers, and interpretability tools. Use when measuring LLM quality on standard benchmarks, tracking training runs, curating pretraining data, tuning tokenizers, or probing learned representations with SAEs. Routes to concrete leaf skills (lm-evaluation-harness, weights-and-biases, nemo-curator, huggingface-tokenizers, saelens) and defines the decision rules between them.
version: 1.0.0
author: hermes-CCC (ported from Hermes Agent by NousResearch)
license: MIT
metadata:
  hermes:
    tags: [evaluation, benchmarks, experiment-tracking, data-curation, tokenizers, interpretability, mlops, lm-eval, wandb, sae]
---

# Evaluation - Measure, Track, and Understand Models

## Purpose

Cover the full "did this model get better" loop: benchmark evaluation, experiment tracking, data curation for training mixes, tokenizer construction, and mechanistic interpretability. Use this skill as a router when the user asks a broad question about evaluating a model or understanding its behavior, then delegate to the specific leaf skill listed below.

## Activation criteria

Activate when the user:

- Says "evaluate", "benchmark", "score", "measure model quality", "MMLU", "HumanEval", "GSM8K", "BIG-bench", "helm".
- Wants experiment tracking, run comparison, hyperparameter sweeps, metric logging ("track runs", "wandb", "log metrics").
- Needs to build, filter, deduplicate, or quality-score a pretraining / fine-tuning corpus.
- Wants to train or inspect a tokenizer (BPE, Unigram, WordPiece, vocabulary size, merges).
- Wants to probe internal representations with sparse autoencoders, feature circuits, or activation analysis.

Do not activate for raw inference serving (use `inference`), for training loops themselves (use `training`), or for retrieval (use `vector-databases`).

## Leaf skills and when to pick each

- `lm-evaluation-harness` - standardized benchmark suite (MMLU, HellaSwag, TruthfulQA, GSM8K, BIG-bench, ARC). Use for leaderboard-style numbers, regression testing after fine-tune, and cross-model comparison.
- `weights-and-biases` - run tracking, hyperparameter sweeps, artifact versioning, live loss curves, team dashboards. Use whenever a training loop runs longer than a couple minutes or a sweep must be reproducible.
- `nemo-curator` - GPU-accelerated text dataset curation: exact/fuzzy dedup, language ID, quality classifiers, PII redaction, token counting. Use when building or cleaning a pretraining mix.
- `huggingface-tokenizers` - train BPE/Unigram/WordPiece tokenizers, add special tokens, measure fertility, export to `tokenizer.json`. Use when creating a new tokenizer or debugging tokenization drift.
- `saelens` - sparse autoencoders for mechanistic interpretability. Use when the user asks about features, circuits, steering, or "what is this model representing".

## Procedure

1. Classify the request into one of: benchmarks, tracking, data, tokenizer, interpretability.
2. If ambiguous, ask one clarifying question: "Do you want benchmark numbers, a training dashboard, a cleaner dataset, a new tokenizer, or internal feature analysis?"
3. Invoke the matching leaf skill and hand off all context.
4. If multiple sub-tasks are required (e.g., train tokenizer + curate data + run benchmarks), sequence them explicitly and track dependencies.
5. Record the evaluation protocol (model hash, dataset revision, harness version, seed) alongside results.

## Decision rules

- Before running any benchmark: pin the harness version and the model revision. Numbers without versions are not comparable.
- Before curating a new dataset: define the quality filter target (tokens retained, duplicate rate, non-English %) so you know when to stop.
- Before training a tokenizer: decide vocabulary size and special-token budget first; changing these later invalidates checkpoints.
- Before committing to a SAE interpretation: verify reconstruction loss and feature density are within published ranges for the model family.
- Always log eval results to W&B (or equivalent) the moment they exist, so reruns can be compared.

## Minimum standard evaluation pack

When the user says "just evaluate my model":

- MMLU (5-shot) - knowledge
- HellaSwag (0-shot) - commonsense
- ARC-Challenge (25-shot) - reasoning
- TruthfulQA (0-shot) - truthfulness
- GSM8K (8-shot, maj@1) - math
- HumanEval (0-shot, pass@1) - code

Run with `lm-eval --model hf --model_args pretrained=<repo> --tasks mmlu,hellaswag,arc_challenge,truthfulqa,gsm8k,humaneval --batch_size auto`.

## Outputs

- A routed recommendation naming the leaf skill to load.
- A concrete command or config for the chosen tool.
- A protocol document listing: model id, revision, harness/tool version, dataset version, seed, hardware.
- Results logged to W&B (or a local `results.jsonl`) plus a Markdown summary table.

## Failure modes

- Comparing numbers across harness versions: refuse; re-run the baseline on the current version.
- Cherry-picking seeds: require seed sweeps (at least 3 seeds) for small deltas.
- Eval contamination: flag if benchmark data appears in training corpus and re-score on a held-out split.
- Dataset curation without counting tokens retained vs. dropped: reject; numbers are required to justify filter thresholds.
- SAE feature claims without activation patching or ablation evidence: mark as hypothesis, not finding.

## Commands

Standard benchmark run:

```bash
pip install lm-eval
lm-eval --model hf \
  --model_args pretrained=HuggingFaceH4/zephyr-7b-beta,dtype=bfloat16 \
  --tasks mmlu,hellaswag,arc_challenge,truthfulqa,gsm8k \
  --batch_size auto \
  --output_path ./eval_results
```

Experiment tracking:

```bash
pip install wandb
wandb login
# In training script:
#   import wandb; wandb.init(project="hermes-eval", config={...})
#   wandb.log({"mmlu": 0.62, "loss": 1.23})
```

Data curation (NeMo Curator):

```bash
pip install nemo-curator
python -m nemo_curator.scripts.prepare_task_data \
  --input-dir raw_corpus/ \
  --output-dir clean_corpus/ \
  --filters language,fuzzy_dedup,quality_classifier
```

Tokenizer training:

```python
from tokenizers import Tokenizer, models, trainers, pre_tokenizers
tok = Tokenizer(models.BPE())
tok.pre_tokenizer = pre_tokenizers.ByteLevel(add_prefix_space=False)
trainer = trainers.BpeTrainer(vocab_size=32000, special_tokens=["<s>","</s>","<pad>","<unk>"])
tok.train(["corpus.txt"], trainer)
tok.save("tokenizer.json")
```

SAE analysis (sketched):

```python
from sae_lens import SAE
sae = SAE.from_pretrained("gpt2-small-res-jb", layer=8)
# feed activations, inspect top features, run ablations
```

## Hand-off contract

When routing to a leaf skill, include:

- Model identifier and revision
- Hardware (GPU count, VRAM per GPU, framework versions)
- Goal metric or artifact
- Deadline or budget (tokens, GPU-hours, dollars)
- Where results must land (W&B project, directory, report file)
