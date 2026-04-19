---
name: nano-pdf
description: Edit PDFs with natural-language instructions using the nano-pdf CLI. Modify text, fix typos, update titles, and make content changes to specific pages without manual editing.
version: 1.0.0
author: hermes-CCC (ported from Hermes Agent by NousResearch)
license: MIT
metadata:
  hermes:
    tags: [PDF, Documents, Editing, NLP, Productivity]
    homepage: https://pypi.org/project/nano-pdf/
---

# nano-pdf

Edit PDFs using natural-language instructions. Point it at a page and describe what to change.

## When to Use

- User wants to fix a typo on a specific PDF page
- User needs to update a title, date, name, or short piece of text inside a PDF
- User has a generated report or deck and wants a small content correction
- User wants to avoid manual PDF editors (Acrobat, Preview, etc.) for a one-line change
- Programmatic PDF text edits are needed in a script or automation

Do NOT use this skill for:

- Redesigning page layout, adding new pages, or complex graphical changes
- Redacting confidential data (use a dedicated redaction tool that removes underlying text)
- Very large batch edits across hundreds of PDFs without verification

## Prerequisites

```bash
# Install with uv (recommended if uv is available)
uv pip install nano-pdf

# Or with pip
pip install nano-pdf
```

Also required:

- A working Python environment (3.10+ recommended).
- An API key configured per `nano-pdf --help` — the tool calls an LLM under the hood.

## Usage

```bash
nano-pdf edit <file.pdf> <page_number> "<instruction>"
```

Arguments:

- `<file.pdf>` — path to the input PDF (read + write).
- `<page_number>` — page to modify. May be 0-based or 1-based depending on version.
- `<instruction>` — natural-language description of the change.

## Examples

```bash
# Change a title on page 1
nano-pdf edit deck.pdf 1 "Change the title to 'Q3 Results' and fix the typo in the subtitle"

# Update a date on a specific page
nano-pdf edit report.pdf 3 "Update the date from January to February 2026"

# Fix content
nano-pdf edit contract.pdf 2 "Change the client name from 'Acme Corp' to 'Acme Industries'"
```

## Procedure

1. Confirm the input file exists and is not write-locked.
2. Identify the target page. If unsure, open the PDF and count pages first.
3. Write a precise instruction that names the specific text to change and the
   replacement text. Avoid vague instructions like "fix the typo".
4. Run `nano-pdf edit <file> <page> "<instruction>"`.
5. Verify the resulting PDF by:
   - Reading file size to confirm it actually changed.
   - Opening the PDF or extracting text from the target page and checking the edit.
6. If the edit landed on the wrong page, retry with `page ± 1` to account for
   0-based vs 1-based indexing differences.

## Decision Rules

- Prefer `nano-pdf` when the change is a small text correction on a known page.
- Prefer re-generating the source (markdown, slides, LaTeX) when the change is
  structural, spans many pages, or requires layout adjustments.
- Prefer a dedicated redaction tool when the goal is to remove sensitive content.
- Prefer manual editing when the PDF is scanned-only and text is not selectable
  (nano-pdf needs a text layer).

## Outputs

- The modified PDF at the original path (or wherever the CLI writes — check
  `nano-pdf --help` for output flags).
- Any diagnostic text printed by the CLI. Save this to a log if the edit is
  part of a larger automation.

## Failure Modes

- **Wrong page edited.** Retry with `page ± 1`. Confirm the indexing convention
  of the installed version.
- **LLM hallucination.** The model may rewrite more than requested. Always
  re-read the affected page after the edit.
- **Unreadable text layer.** Scanned PDFs without OCR cannot be edited — run
  OCR first (see the `ocr-and-documents` skill) and then try again.
- **API key missing.** `nano-pdf --help` lists the required environment
  variables. Set them before running.
- **Corrupted output.** If the resulting PDF will not open, restore the
  original from version control or a backup and retry with a simpler
  instruction.

## Notes

- Page numbers may be 0-based or 1-based depending on version — if the edit hits
  the wrong page, retry with ±1.
- Always verify the output PDF after editing (check file size, or open it).
- The tool uses an LLM under the hood — requires an API key (check
  `nano-pdf --help` for config).
- Works well for text changes; complex layout modifications may need a
  different approach.
