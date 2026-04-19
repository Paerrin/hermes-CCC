---
name: ocr-and-documents
description: Extract text from PDFs and scanned documents. Use a web extraction tool for remote URLs, pymupdf for local text-based PDFs, marker-pdf for OCR/scanned docs. For DOCX use python-docx, for PPTX see the powerpoint skill.
version: 2.3.0
author: hermes-CCC (ported from Hermes Agent by NousResearch)
license: MIT
metadata:
  hermes:
    tags: [PDF, Documents, Research, Arxiv, Text-Extraction, OCR]
    related_skills: [powerpoint]
---

# PDF & Document Extraction

For DOCX: use `python-docx` (parses actual document structure, far better than OCR).
For PPTX: see the `powerpoint` skill (uses `python-pptx` with full slide/notes support).
This skill covers **PDFs and scanned documents**.

## When to Use

- The user gives you a PDF (local or URL) and asks for its text, summary, or any
  content-level answer that requires reading it.
- The user mentions "OCR", "scanned document", "extract text", "arxiv paper",
  or a `.pdf` file.
- You need markdown or structured output from a PDF to feed into another step
  (summarization, diffing, indexing).

## Step 1: Remote URL Available?

If the document has a URL, **always try a web-extraction tool first** (for
example Claude Code's built-in `WebFetch`, or a Firecrawl-backed fetcher if
configured):

```
WebFetch(url="https://arxiv.org/pdf/2402.03300", prompt="Extract the paper text as markdown")
WebFetch(url="https://example.com/report.pdf",   prompt="Extract the report text as markdown")
```

This handles PDF-to-markdown conversion with no local dependencies.

Only use local extraction when: the file is local, remote fetching fails, or
you need batch processing.

## Step 2: Choose Local Extractor

| Feature | pymupdf (~25MB) | marker-pdf (~3-5GB) |
|---------|-----------------|---------------------|
| **Text-based PDF** | yes | yes |
| **Scanned PDF (OCR)** | no  | yes (90+ languages) |
| **Tables** | basic | high accuracy |
| **Equations / LaTeX** | no  | yes |
| **Code blocks** | no  | yes |
| **Forms** | no  | yes |
| **Headers/footers removal** | no  | yes |
| **Reading order detection** | no  | yes |
| **Images extraction** | embedded only | with context |
| **Images → text (OCR)** | no  | yes |
| **EPUB** | yes | yes |
| **Markdown output** | via pymupdf4llm | native, higher quality |
| **Install size** | ~25MB | ~3-5GB (PyTorch + models) |
| **Speed** | Instant | ~1-14s/page (CPU), ~0.2s/page (GPU) |

**Decision**: Use pymupdf unless you need OCR, equations, forms, or complex
layout analysis.

If the user needs marker capabilities but the system lacks ~5GB free disk:

> "This document needs OCR/advanced extraction (marker-pdf), which requires
> ~5GB for PyTorch and models. Your system has [X]GB free. Options: free
> up space, provide a URL so I can use a web extractor, or I can try
> pymupdf which works for text-based PDFs but not scanned documents or
> equations."

---

## pymupdf (lightweight)

```bash
pip install pymupdf pymupdf4llm
```

**Via helper script** (under this skill's `scripts/` directory):

```bash
python scripts/extract_pymupdf.py document.pdf              # Plain text
python scripts/extract_pymupdf.py document.pdf --markdown    # Markdown
python scripts/extract_pymupdf.py document.pdf --tables      # Tables
python scripts/extract_pymupdf.py document.pdf --images out/ # Extract images
python scripts/extract_pymupdf.py document.pdf --metadata    # Title, author, pages
python scripts/extract_pymupdf.py document.pdf --pages 0-4   # Specific pages
```

**Inline** (no helper script needed):

```bash
python3 -c "
import pymupdf
doc = pymupdf.open('document.pdf')
for page in doc:
    print(page.get_text())
"
```

---

## marker-pdf (high-quality OCR)

```bash
# Check disk space first
python scripts/extract_marker.py --check

pip install marker-pdf
```

**Via helper script**:

```bash
python scripts/extract_marker.py document.pdf                # Markdown
python scripts/extract_marker.py document.pdf --json         # JSON with metadata
python scripts/extract_marker.py document.pdf --output_dir out/  # Save images
python scripts/extract_marker.py scanned.pdf                 # Scanned PDF (OCR)
python scripts/extract_marker.py document.pdf --use_llm      # LLM-boosted accuracy
```

**CLI** (installed with marker-pdf):

```bash
marker_single document.pdf --output_dir ./output
marker /path/to/folder --workers 4    # Batch
```

---

## Arxiv Papers

```
# Abstract only (fast)
WebFetch(url="https://arxiv.org/abs/2402.03300", prompt="Extract the abstract")

# Full paper
WebFetch(url="https://arxiv.org/pdf/2402.03300", prompt="Extract the full paper as markdown")

# Search
WebSearch(query="arxiv GRPO reinforcement learning 2026")
```

## Split, Merge & Search

pymupdf handles these natively — use inline Python:

```python
# Split: extract pages 1-5 to a new PDF
import pymupdf
doc = pymupdf.open("report.pdf")
new = pymupdf.open()
for i in range(5):
    new.insert_pdf(doc, from_page=i, to_page=i)
new.save("pages_1-5.pdf")
```

```python
# Merge multiple PDFs
import pymupdf
result = pymupdf.open()
for path in ["a.pdf", "b.pdf", "c.pdf"]:
    result.insert_pdf(pymupdf.open(path))
result.save("merged.pdf")
```

```python
# Search for text across all pages
import pymupdf
doc = pymupdf.open("report.pdf")
for i, page in enumerate(doc):
    results = page.search_for("revenue")
    if results:
        print(f"Page {i+1}: {len(results)} match(es)")
        print(page.get_text("text"))
```

No extra dependencies needed — pymupdf covers split, merge, search, and text
extraction in one package.

---

## Notes

- A web-extraction tool (WebFetch, Firecrawl, or equivalent) is always the
  first choice for URLs.
- pymupdf is the safe default — instant, no models, works everywhere.
- marker-pdf is for OCR, scanned docs, equations, complex layouts — install
  only when needed.
- Both helper scripts accept `--help` for full usage.
- marker-pdf downloads ~2.5GB of models to `~/.cache/huggingface/` on first use.
- For Word docs: `pip install python-docx` (better than OCR — parses actual
  structure).
- For PowerPoint: see the `powerpoint` skill (uses python-pptx).

## Failure Modes

- **Helper scripts missing.** This skill references `scripts/extract_pymupdf.py`
  and `scripts/extract_marker.py`, which are part of the upstream Hermes Agent
  bundle. Either port them from
  `https://github.com/NousResearch/hermes-agent/tree/main/skills/productivity/ocr-and-documents/scripts`
  or use the inline Python snippets above.
- **Encrypted PDF.** pymupdf raises on password-protected PDFs. Ask the user
  for the password or a decrypted copy.
- **Scanned PDF with pymupdf.** Returns empty text — switch to marker-pdf or a
  web extractor.
- **Non-English OCR quality.** marker-pdf supports 90+ languages; set the
  language hint in its config when extracting non-Latin scripts.
