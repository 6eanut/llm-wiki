# Frequently Asked Questions

## Installation

### How do I install LLM Wiki?

The quickest way:

```bash
git clone https://github.com/6eanut/llm-wiki
cd llm-wiki
./quickstart.sh
```

For session hooks (recommended): `./quickstart.sh --with-hooks`

For manual control, see the three-step setup in [README.md](README.md#manual-setup).

### How do I uninstall?

```bash
./uninstall.sh
```

This removes the global skill installation and all slash commands. Your project wiki directories are preserved.

### Does LLM Wiki work on macOS?

Yes. You may need GNU coreutils for some scripts:

```bash
brew install coreutils grep jq
```

### Does it work on Windows?

Yes, via WSL (Windows Subsystem for Linux). Native Windows (without WSL) is not tested.

---

## Usage

### How do I start building a wiki?

1. Drop source files (Markdown or plain text) into `.raw/` in your project
2. Run `/wiki-ingest .raw/your-file.md` in Claude Code
3. The LLM analyzes the source, extracts concepts, and creates interlinked wiki pages

### Do I need to manually run `/wiki-query`?

No. Once the skill is installed and CLAUDE.md is set up, Claude automatically checks the wiki before answering factual questions. You only need `/wiki-query` for explicit wiki-only searches.

### What file formats can I ingest?

Markdown (`.md`) and plain text (`.txt`) files work best. The LLM can handle most text formats, but markdown is recommended for best results.

### How large can my source files be?

There is no hard limit, but very large files (>10,000 words) may benefit from being split into smaller chunks. The ingest workflow handles large sources by processing them in sections.

### How do I handle knowledge that contradicts existing wiki pages?

The ingest workflow automatically detects contradictions and adds callout blocks. You can also use the review queue (`/wiki-review`) to manually reconcile conflicts.

---

## Configuration

### Where are configuration settings stored?

In `wiki/.llm-wiki/config.md`. This file is created by `init-wiki.sh` and contains:

- Wiki name and language preferences
- Ingest settings (auto-index, two-phase, review requirements)
- Query settings (max pages to read, language matching)
- Lint settings (startup lint, full lint frequency)

### How do I change the wiki root directory?

Set the `LLM_WIKI_ROOT` environment variable before starting Claude Code:

```bash
export LLM_WIKI_ROOT=/path/to/your/wiki
```

### Can I use multiple wikis in different projects?

Yes. Each project has its own `wiki/` directory with its own `.llm-wiki/` configuration. The skill is installed globally but reads project-local wiki data.

---

## Troubleshooting

### "Wiki not found" or "No index.md"

Run the setup script in your project directory:

```bash
~/.claude/skills/llm-wiki/scripts/setup-project.sh ./wiki
```

### Skill commands not working

Reinstall the skill:

```bash
cd llm-wiki
./llm-wiki/install.sh --force
```

### Shell scripts fail with "command not found"

Ensure dependencies are installed:

- `bash` 4.0+
- GNU `find`, `grep`, `sed`, `sort`, `sha256sum`
- `jq` (for session hooks)

On macOS: `brew install coreutils grep jq`

### Index shows stale data

Run `/wiki-lint` to regenerate the index. If the problem persists, check `wiki/.llm-wiki/cache/state-hash.txt`.

### How do I fix broken wikilinks?

Run `/wiki-lint` — the quick lint mode automatically detects broken `[[wikilinks]]` using `find-broken-links.sh`. Manually fix the links in the affected pages.

---

## Design

### How is this different from RAG?

See the comparison table in [README.md](README.md#compared-to-rag). Key differences:

- Knowledge is persisted as structured wiki pages, not re-derived per query
- Bidirectional `[[wikilinks]]` provide cross-references
- Contradictions are explicitly detected and flagged
- Uses an index for O(1) page lookup instead of vector similarity

### Why Bash scripts instead of Python/Node.js?

Bash is used only for deterministic operations (hashing, file listing, grep). The LLM (Claude) is the runtime for all content work. This means zero external runtime dependencies.

### Can I contribute new page types or workflows?

Yes! See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines. New page types need a template in `templates/` and schema updates in `WIKI_SCHEMA.md`.
