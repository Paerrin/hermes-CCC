---
name: songsee
description: Generate spectrograms and audio feature visualizations (mel, chroma, MFCC, tempogram, etc.) from audio files via CLI. Useful for audio analysis, music production debugging, and visual documentation.
version: 1.0.0
author: hermes-CCC (ported from Hermes Agent by NousResearch)
license: MIT
metadata:
  hermes:
    tags: [Audio, Visualization, Spectrogram, Music, Analysis]
    category: media
    homepage: https://github.com/steipete/songsee
    upstream_author: community
prerequisites:
  commands: [songsee]
---

# songsee

Generate spectrograms and multi-panel audio feature visualizations from audio files.

## When to Use

- User asks for a spectrogram, waveform visualization, or audio "picture"
- User wants to debug audio synthesis, TTS output, or music production issues visually
- User wants to compare two audio files side by side via their spectral content
- User wants to document an audio pipeline with annotated plots (mel, chroma, MFCC, tempogram, HPSS, self-similarity, loudness, flux)
- You need to pair audio output with `vision_analyze` or another image-understanding pass

Do NOT use this skill to transcribe audio to text (use `whisper`), to synthesize new audio, or to edit audio samples — it is read-only visualization only.

## Prerequisites

Requires [Go](https://go.dev/doc/install):
```bash
go install github.com/steipete/songsee/cmd/songsee@latest
```

Optional: `ffmpeg` for formats beyond WAV/MP3.

Verify the install:
```bash
songsee --version
```

If the binary is not on `PATH`, add `$HOME/go/bin` (or the relevant `GOBIN`) to `PATH` and re-test before attempting any visualization.

## Quick Start

```bash
# Basic spectrogram
songsee track.mp3

# Save to specific file
songsee track.mp3 -o spectrogram.png

# Multi-panel visualization grid
songsee track.mp3 --viz spectrogram,mel,chroma,hpss,selfsim,loudness,tempogram,mfcc,flux

# Time slice (start at 12.5s, 8s duration)
songsee track.mp3 --start 12.5 --duration 8 -o slice.jpg

# From stdin
cat track.mp3 | songsee - --format png -o out.png
```

## Visualization Types

Use `--viz` with comma-separated values:

| Type | Description |
|------|-------------|
| `spectrogram` | Standard frequency spectrogram |
| `mel` | Mel-scaled spectrogram |
| `chroma` | Pitch class distribution |
| `hpss` | Harmonic/percussive separation |
| `selfsim` | Self-similarity matrix |
| `loudness` | Loudness over time |
| `tempogram` | Tempo estimation |
| `mfcc` | Mel-frequency cepstral coefficients |
| `flux` | Spectral flux (onset detection) |

Multiple `--viz` types render as a grid in a single image.

## Common Flags

| Flag | Description |
|------|-------------|
| `--viz` | Visualization types (comma-separated) |
| `--style` | Color palette: `classic`, `magma`, `inferno`, `viridis`, `gray` |
| `--width` / `--height` | Output image dimensions |
| `--window` / `--hop` | FFT window and hop size |
| `--min-freq` / `--max-freq` | Frequency range filter |
| `--start` / `--duration` | Time slice of the audio |
| `--format` | Output format: `jpg` or `png` |
| `-o` | Output file path |

## Decision Rules

- Default to a **single `spectrogram`** when the user has not asked for anything more specific. It is the most universally readable view.
- Reach for **`mel`** any time the user is working with speech or TTS output — it tracks perceptual frequency far better than the linear spectrogram.
- Reach for **`chroma`** for tonal analysis (key detection, sample matching, cover versions).
- Reach for **`tempogram`** when debugging rhythm, groove, or BPM detection bugs.
- Reach for **`flux`** when the user cares about onsets, beats, or transient detection.
- Use **`--start` / `--duration`** to zoom in on a specific event instead of rendering the entire song — render time scales with duration.
- Prefer `png` for crisp documentation. Use `jpg` only when the output will be embedded in something size-sensitive like a markdown email.

## Outputs

Each invocation writes a single image file (path controlled by `-o`, default derived from input filename). When multiple `--viz` types are requested, they are rendered as labelled panels within that single image. No metadata sidecar is produced; if the caller needs structured audio features (numeric arrays), this is the wrong tool — use `librosa` or the feature-extraction APIs directly.

## Failure Modes

- `unsupported format` — songsee decodes WAV and MP3 natively. For anything else (FLAC, M4A, OGG, Opus, AAC), install `ffmpeg` and re-run. If `ffmpeg` is present and the error persists, the file is likely corrupt or truncated.
- `command not found: songsee` — Go install did not place the binary on `PATH`. Run `go env GOBIN` (or fall back to `$HOME/go/bin`) and prepend that to `PATH`.
- Blank / all-black output — the source is likely silent, or the `--min-freq` / `--max-freq` window excludes every bin. Remove those flags first to confirm.
- Extremely tall outputs — stacking 6+ `--viz` types produces a very tall image. Pair with explicit `--width` / `--height`, or render in two calls.

## Notes

- WAV and MP3 are decoded natively; other formats require `ffmpeg`.
- Output images can be inspected with `vision_analyze` or any vision-capable model for automated audio analysis.
- Useful for comparing audio outputs, debugging synthesis, or documenting audio processing pipelines.
- Pair with the `whisper` skill when both transcription and a spectrogram are needed — songsee for the picture, whisper for the words.
