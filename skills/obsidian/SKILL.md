---
name: obsidian
description: Read, search, create, and update notes inside an Obsidian vault directly from the shell. Covers wikilink-aware note manipulation, folder scoping, frontmatter hygiene, and safe appends for markdown-first knowledge bases.
version: 1.0.0
author: hermes-CCC (ported from Hermes Agent by NousResearch)
license: MIT
metadata:
  hermes:
    tags: [obsidian, note-taking, markdown, knowledge-base, wikilinks]
    category: note-taking
    related_skills: [llm-wiki]
---

# Obsidian Vault

A minimal, filesystem-native skill for working with an Obsidian vault from the shell. An Obsidian vault is just a directory of markdown files, which means all vault operations reduce to `cat`, `find`, `grep`, and safe writes.

## When to Use

- The user asks to read, create, append to, or search a note by name or content.
- The user wants a quick index of notes under a folder.
- The user wants to link notes together with `[[wikilinks]]`.
- An automation needs to dump transcripts, meeting notes, or daily journals into the vault.

Do NOT use this skill for non-markdown files (attachments, PDFs, canvases) — those should go through the Obsidian app directly. Do not use this skill to run Obsidian plugins; plugins only execute inside the Obsidian app.

## Vault Location

**Location:** Set via `OBSIDIAN_VAULT_PATH` environment variable.

If unset, defaults to `~/Documents/Obsidian Vault`.

Note: Vault paths may contain spaces — always quote them.

```bash
VAULT="${OBSIDIAN_VAULT_PATH:-$HOME/Documents/Obsidian Vault}"
```

Confirm the vault exists before any write operation:

```bash
[ -d "$VAULT" ] || { echo "Vault not found at $VAULT"; exit 1; }
```

## Read a Note

```bash
VAULT="${OBSIDIAN_VAULT_PATH:-$HOME/Documents/Obsidian Vault}"
cat "$VAULT/Note Name.md"
```

If you only need a section, pipe through `sed -n '/^## Heading/,/^## /p'` or read with the standard `Read` tool.

## List Notes

```bash
VAULT="${OBSIDIAN_VAULT_PATH:-$HOME/Documents/Obsidian Vault}"

# All notes
find "$VAULT" -name "*.md" -type f

# In a specific folder
ls "$VAULT/Subfolder/"

# Notes modified in the last 7 days
find "$VAULT" -name "*.md" -type f -mtime -7
```

For large vaults, prefer `rg --files` (ripgrep) or the `Glob` tool — `find` walks every directory including `.obsidian/` which is noise.

## Search

```bash
VAULT="${OBSIDIAN_VAULT_PATH:-$HOME/Documents/Obsidian Vault}"

# By filename
find "$VAULT" -name "*.md" -iname "*keyword*"

# By content (list matching files)
grep -rli "keyword" "$VAULT" --include="*.md"

# With context (filenames + 2 lines around each hit)
grep -rn --include="*.md" -C 2 "keyword" "$VAULT"
```

Prefer the `Grep` tool for complex queries — ripgrep is faster on huge vaults and respects `.gitignore`-style patterns.

## Create a Note

```bash
VAULT="${OBSIDIAN_VAULT_PATH:-$HOME/Documents/Obsidian Vault}"
cat > "$VAULT/New Note.md" << 'ENDNOTE'
---
created: 2026-04-19
tags: [inbox]
---

# Title

Content here.
ENDNOTE
```

Guidelines:

- Use human-readable filenames with spaces — Obsidian resolves `[[New Note]]` to `New Note.md` anywhere in the vault.
- Prefer a `---` YAML frontmatter block with at minimum a `created` date and `tags` array when the user maintains structured metadata.
- Keep a H1 `# Title` in addition to the filename; Obsidian displays the H1 in search results.

## Append to a Note

```bash
VAULT="${OBSIDIAN_VAULT_PATH:-$HOME/Documents/Obsidian Vault}"
printf '\n%s\n' "New content here." >> "$VAULT/Existing Note.md"
```

For daily-journal style appends, include a timestamp heading:

```bash
printf '\n## %s\n%s\n' "$(date +%H:%M)" "New entry." >> "$VAULT/Daily/$(date +%Y-%m-%d).md"
```

Always `>>` not `>`; a stray `>` will destroy the note.

## Wikilinks

Obsidian links notes with `[[Note Name]]` syntax. When creating notes, use these to link related content — they are the primary navigation mechanism.

- `[[Note Name]]` — default link to note titled exactly "Note Name".
- `[[Note Name|display text]]` — pipe syntax provides a custom label.
- `[[Note Name#Heading]]` — anchor to a specific heading.
- `[[Note Name#^block-id]]` — anchor to a block reference.

When updating an existing note, check inbound links before renaming:

```bash
grep -rln --include="*.md" "\[\[Old Name\]\]" "$VAULT"
```

Rewrite them alongside the rename to avoid creating dangling links.

## Daily Notes

If the vault uses Obsidian's Daily Notes plugin, the convention is one file per day under a `Daily/` or `Journal/` folder, named `YYYY-MM-DD.md`. Create or append to today's file:

```bash
VAULT="${OBSIDIAN_VAULT_PATH:-$HOME/Documents/Obsidian Vault}"
TODAY="$VAULT/Daily/$(date +%Y-%m-%d).md"
mkdir -p "$(dirname "$TODAY")"
[ -f "$TODAY" ] || printf '# %s\n\n' "$(date +%Y-%m-%d)" > "$TODAY"
```

## Outputs

Every operation produces either printed content (read/search/list) or a modified markdown file on disk. This skill never reaches into Obsidian's plugin or cache state, so changes made here appear as-if-typed next time the Obsidian app is opened.

## Failure Modes

- `No such file or directory` — the vault path is wrong or `OBSIDIAN_VAULT_PATH` is unset and the default does not exist. Fix by setting `OBSIDIAN_VAULT_PATH` or passing an explicit absolute path.
- Stale Obsidian cache after bulk edits — Obsidian rebuilds its search cache on reopen, which can take a moment on large vaults. This is cosmetic; files are correct on disk.
- Accidentally overwritten a note — use `git` or the vault's Obsidian Sync history if available. If neither is enabled, recommend the user enable `File recovery` or a git-based backup before running destructive operations.
- Collision with the Obsidian app — live editing in the app while a script writes to the same file can produce conflict markers. Prefer that the user close or pause sync before batch operations.

## Pitfalls

- Do not modify files under `.obsidian/` — those are the app's config and plugin state. Edits risk corrupting the vault.
- Avoid creating notes at the vault root when folders exist — match the vault's existing folder structure.
- When piping long content into `cat > file << 'EOF'`, always quote the `EOF` marker to prevent shell expansion of `$` and backticks in the note body.
