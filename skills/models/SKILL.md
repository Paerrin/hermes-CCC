---
name: models
description: Specific model architectures and tools — image segmentation (Segment Anything / SAM), audio generation (AudioCraft / MusicGen), multimodal encoders (CLIP, LLaVA), image generation (Stable Diffusion), and speech (Whisper). Use when the user needs a non-LLM model or a multimodal capability, not general text generation. Routes to concrete leaf skills and defines when each applies.
version: 1.0.0
author: hermes-CCC (ported from Hermes Agent by NousResearch)
license: MIT
metadata:
  hermes:
    tags: [models, multimodal, vision, audio, segmentation, generation, sam, clip, llava, stable-diffusion, whisper, audiocraft, musicgen]
---

# Models - Non-Text Modalities and Specialized Architectures

## Purpose

Act as the router for all model work that is not plain LLM chat: segmentation, detection, image and audio generation, multimodal understanding, speech-to-text. Pick the right leaf skill based on modality and task, then hand off with a precise config.

## Activation criteria

Activate when the user wants:

- Image segmentation, masks, bounding boxes, "cut out the object", "remove background".
- Image generation, img2img, inpainting, ControlNet, SDXL, LoRA-conditioned images.
- Audio generation, music, sound effects, "compose a 30s clip", MusicGen, AudioGen.
- Speech-to-text, subtitles, diarization, transcription, timestamp alignment.
- Image-text embeddings, CLIP similarity, zero-shot classification, retrieval over images.
- Visual question answering, image captioning, screenshot understanding (LLaVA).

Do not activate for pure text (route to `inference` or `training`), for storing embeddings (route to `vector-databases`), or for evaluation harnesses (route to `evaluation`).

## Leaf skills and when to pick each

- `segment-anything` (SAM / SAM2) - open-vocabulary segmentation, mask generation, object isolation. Use for "segment", "mask", "extract object".
- `audiocraft` - MusicGen (music), AudioGen (ambient sound), EnCodec (audio tokenization). Use for music and sound-effect synthesis.
- `stable-diffusion` - text-to-image, img2img, inpainting, SDXL, ControlNet. Use for any image generation.
- `whisper` - speech-to-text, language ID, translation, subtitle generation. Use for any audio-to-text.
- `clip` - image-text joint embeddings, zero-shot classification, image-text similarity, retrieval. Use when the user asks "is this image about X" or "find the most similar image".
- `llava` - vision-language model (image-conditioned chat). Use when the user wants a model to answer questions *about* an image in natural language.

## Procedure

1. Classify by modality: image vs. audio vs. text-from-audio vs. multimodal.
2. Classify by task: generate, understand, align/embed, transcribe, segment.
3. Pick the leaf skill from the matrix:

   | Modality / task | Generate | Understand | Embed / align | Segment |
   |-----------------|----------|------------|---------------|---------|
   | Image           | stable-diffusion | llava   | clip          | segment-anything |
   | Audio           | audiocraft       | (n/a)   | (n/a)         | (n/a)            |
   | Speech -> text  | (n/a)            | whisper | (n/a)         | (n/a)            |

4. Confirm hardware: most image/audio models need a GPU with >= 8 GB VRAM. Whisper small/medium runs on CPU; large-v3 prefers GPU.
5. Pin versions: `diffusers`, `transformers`, and model revisions. Model weights change; regenerations without pinning are not reproducible.
6. If the task crosses modalities (e.g., "describe this image, then generate a song about it"), chain leaf skills explicitly.

## Decision rules

- Image generation with precise control: prefer ControlNet + SDXL over plain SDXL.
- Background removal or object isolation: prefer SAM2 with a positive-point prompt over classical matting.
- Long audio transcription (> 30 s): use Whisper with VAD + chunked inference, not a single forward pass.
- "Is this image of a cat": CLIP zero-shot is almost always sufficient and cheaper than LLaVA.
- VQA or describing a complex scene: LLaVA (or a hosted VLM) beats CLIP.
- Music generation: MusicGen-medium (1.5B) is the default; MusicGen-large (3.3B) only when quality demands.

## Outputs

- Chosen leaf skill and a one-sentence justification.
- A runnable code snippet or CLI command for the chosen model.
- VRAM estimate and fallback if hardware is insufficient (smaller variant, quantization, CPU offload).
- Where the output artifact lives (file path, S3, Modal volume, HF hub).
- A citation-worthy record: model id, revision, parameters, seed.

## Failure modes

- Running SDXL on < 8 GB VRAM without `enable_model_cpu_offload()`: OOM. Add offload or switch to SD 1.5.
- Whisper without VAD on noisy long audio: hallucinated repetitions. Always chunk with a VAD.
- CLIP zero-shot on classes it never saw (domain-specific): low confidence scores; calibrate with a labeled probe set.
- Generating images without a fixed seed for reproducibility claims: reject; force a seed for anything the user wants to reproduce.
- Transcribing audio containing PII without noting redaction policy: flag before output.

## Commands

Stable Diffusion (SDXL):

```python
from diffusers import StableDiffusionXLPipeline
import torch

pipe = StableDiffusionXLPipeline.from_pretrained(
    "stabilityai/stable-diffusion-xl-base-1.0",
    torch_dtype=torch.float16,
).to("cuda")
img = pipe("a cyberpunk cat reading a book, cinematic lighting", num_inference_steps=30).images[0]
img.save("out.png")
```

SAM2 mask:

```python
from sam2.build_sam import build_sam2
from sam2.sam2_image_predictor import SAM2ImagePredictor
sam = build_sam2("sam2_hiera_l.yaml", "sam2_hiera_large.pt", device="cuda")
pred = SAM2ImagePredictor(sam)
pred.set_image(img_np)
masks, scores, _ = pred.predict(point_coords=[[x, y]], point_labels=[1])
```

Whisper transcription:

```bash
pip install -U openai-whisper
whisper input.mp3 --model large-v3 --language en --output_format srt
```

CLIP zero-shot:

```python
import torch
from transformers import CLIPModel, CLIPProcessor
model = CLIPModel.from_pretrained("openai/clip-vit-large-patch14").to("cuda")
proc = CLIPProcessor.from_pretrained("openai/clip-vit-large-patch14")
inputs = proc(text=["a cat", "a dog", "a car"], images=image, return_tensors="pt", padding=True).to("cuda")
with torch.no_grad():
    out = model(**inputs)
probs = out.logits_per_image.softmax(dim=-1)
```

MusicGen clip:

```python
from audiocraft.models import MusicGen
model = MusicGen.get_pretrained("facebook/musicgen-medium")
model.set_generation_params(duration=15)
wav = model.generate(["lofi hip hop for late-night coding"])
```

LLaVA VQA:

```python
from transformers import LlavaForConditionalGeneration, AutoProcessor
model = LlavaForConditionalGeneration.from_pretrained("llava-hf/llava-1.5-13b-hf").to("cuda")
proc = AutoProcessor.from_pretrained("llava-hf/llava-1.5-13b-hf")
prompt = "USER: <image>\nWhat is in the image?\nASSISTANT:"
inputs = proc(prompt, image, return_tensors="pt").to("cuda")
print(proc.decode(model.generate(**inputs, max_new_tokens=128)[0], skip_special_tokens=True))
```

## Hand-off contract

When routing, specify:

- Modality and task label
- Input artifact location (URL, path, tensor shape)
- Output artifact location and format
- Hardware and VRAM budget
- Seed and version pins for reproducibility
