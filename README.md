# LLM Wiki — Compounding Knowledge Base for Claude Code

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![CI](https://github.com/6eanut/llm-wiki/actions/workflows/ci.yml/badge.svg)](https://github.com/6eanut/llm-wiki/actions/workflows/ci.yml)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](CONTRIBUTING.md)

A **Claude Code skill** that builds and maintains a persistent, interlinked wiki from your source documents. Based on Andrej Karpathy's [LLM Wiki pattern](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f).

Knowledge is compiled once and kept current, not re-derived on every query.

---

## Quick Start

### One Command

```bash
git clone https://github.com/6eanut/llm-wiki
cd llm-wiki
./quickstart.sh
```

That's it. The script installs the skill, initializes the wiki, and drops in demo source files (Greek mythology — optional, use `--no-demo` to skip).

After setup, start Claude Code and run:

```
/wiki-ingest .raw/greek-olympians.md
```

Then ask anything about the content — Claude checks the wiki automatically.

### With Session Hooks (Recommended)

```bash
./quickstart.sh --with-hooks
```

This enables:

- **Dynamic wiki stats at startup** — page count, recent changes, pending reviews injected at the start of every session
- **Hot-cache for session continuity** — context from your last session is bridged forward so you don't lose state between sessions

### Manual Setup

Prefer manual control? Here's the three-step version:

```bash
./llm-wiki/install.sh --force                                           # 1. Install skill
~/.claude/skills/llm-wiki/scripts/setup-project.sh ./wiki --with-hooks  # 2. Init wiki
# 3. Drop source files in .raw/ and run /wiki-ingest
```

### More Options

See the [Quick Start Guide](https://github.com/6eanut/llm-wiki/wiki/Quick-Start) on the wiki for troubleshooting and advanced configuration.

### What to Expect

After setup, start Claude Code in your project and ask a question:

```
You: "What is the relationship between Zeus and Athena?"

Claude: [reads ./wiki/.llm-wiki/index.md automatically]
        [finds relevant pages]
        [synthesizes answer with citations]

        ## Answer
        Athena is Zeus's daughter, born from his head...

        ## Evidence
        | Source Page | Key Point | Confidence |
        |-------------|-----------|------------|
        | [[athena]] | emerged from Zeus's forehead | high |
        | [[zeus]] | Father of Athena | high |
```

**You don't need to type `/wiki-query` for routine questions.** Claude reads CLAUDE.md at startup and follows the rule: "check the wiki before answering."

If the wiki doesn't have relevant knowledge, Claude will tell you and suggest adding source files to `.raw/`.

### Adding Your Own Knowledge

1. Drop source files (markdown, text) into `./.raw/`
2. Run `/wiki-ingest .raw/your-file.md`
3. The file is analyzed, concepts extracted, and interlinked pages created

---
---

## Architecture

### How Proactive Wiki Works

```
Session starts
    ↓
Claude reads CLAUDE.md → "Check the wiki before answering"
    ↓
SessionStart hook runs → wiki stats, topics, pending items
    ↓
Slash commands auto-discovered from ~/.claude/commands/
    ↓
Skill auto-registered as "wiki" from ~/.claude/skills/llm-wiki/
    ↓
User asks any question
    ↓
Claude reads index.md → finds relevant pages → answers with citations
```

### Key Architectural Decisions

| Decision | Rationale |
|----------|-----------|
| **CLAUDE.md for rules** | Always-loaded, no tool call needed. Tells Claude WHEN to use the wiki. |
| **SessionStart hook for state** | Dynamic wiki stats (pages, topics, pending items) injected each session. |
| **LLM is the runtime** | All content work done by Claude. No external language runtime needed. |
| **Bash for determinism only** | SHA-256 hashing, file listing, grep — correctness-critical operations only. |
| **Markdown workflow files** | Each command has a `workflows/*.md` procedure. Documentation = executable instructions. |
| **Two-phase ingest** | Phase 1 (analysis) writes a reviewable analysis before Phase 2 (generation) creates pages. |
| **Auto-generated index** | `index.md` regenerated on every change. Enables O(1) lookup of relevant pages. |
| **SHA-256 incremental caching** | `.done` sentinel files prevent re-ingestion. Safe to re-drop sources. |

### Three-Layer Data Architecture

```
.raw/ (sources)    →    wiki/ (pages)    →    skill (schema + workflows)
  (immutable)            (LLM-generated)       (conventions)
```

---

## Wiki Directory Structure

```
wiki/
├── .llm-wiki/
│   ├── schema.md                   Copy of WIKI_SCHEMA.md
│   ├── config.md                   User preferences
│   ├── index.md                    ★ AUTO-GENERATED — never edit by hand ★
│   ├── review.json                 {pending: [...], resolved: [...]}
│   ├── cache/
│   │   ├── hot-cache.md            Multi-session context bridge
│   │   ├── source-manifest.json    SHA-256 → source metadata
│   │   ├── state-hash.txt          Detects external modifications
│   │   └── ingests/{sha256}.done   Sentinel files (idempotent ingestion)
│   └── inbox/{sha256}-analysis.md  Phase 1 ingest analyses
├── transformer.md                  Concept page
├── 2026-04-28-weekly-notes.md      Article page
├── alan-turing.md                  Person page
└── synth-2026-04-28-riscv.md       Synthesis page
```

---

## Page Types

### `concept` — Define a term, idea, methodology, tool

```yaml
type: concept
language: en | zh | bilingual
```

Body: Definition → Key Properties → Examples → Related

### `article` — Notes, blog drafts, imported documents

```yaml
type: article
```

File: `YYYY-MM-DD-{slug}.md`

### `person` — Author, researcher, notable individual

```yaml
type: person
```

### `synthesis` — Saved query answer (the compounding mechanism)

```yaml
type: synthesis
query, based_on[], confidence: high | medium | low
```

File: `synth-YYYY-MM-DD-{slug}.md`

---

## Bilingual Support

- **Auto-detection**: CJK character ratio determines `zh` / `en` / `bilingual`
- **Page titles**: `"English / 中文"` format for bilingual pages
- **Cross-language wikilinks**: `aliases` field provides translations for link resolution
- **Query matching**: Prefers same-language pages, falls back across languages

---

## Skill File Map

```
llm-wiki/
├── SKILL.md                         Skill manifest with proactive usage rules
├── WIKI.md                          CLAUDE.md template (copied to project root)
├── WIKI_SCHEMA.md                   Page type definitions & conventions
├── install.sh                       Global installation (one-time)
├── commands/                        Auto-discovered slash commands
│   ├── wiki-ingest.md               /wiki-ingest
│   ├── wiki-query.md                /wiki-query
│   ├── wiki-lint.md                 /wiki-lint
│   ├── wiki-save.md                 /wiki-save
│   ├── wiki-graph.md                /wiki-graph
│   └── wiki-review.md               /wiki-review
├── templates/                       Page templates (article, concept, person, synthesis)
├── scripts/                         Deterministic bash operations
│   ├── setup-project.sh             ★ One-stop project setup
│   ├── init-wiki.sh                 Bootstrap new wiki directory
│   ├── hash-files.sh                SHA-256 hash source files
│   ├── check-stale.sh               Index freshness check
│   ├── find-orphans.sh              Pages with zero incoming links
│   ├── validate-frontmatter.sh      Required field validation
│   └── find-broken-links.sh         Dead wikilink detection
├── workflows/                       Deep workflow procedures (read by the skill)
│   ├── ingest.md                    Two-phase source ingestion
│   ├── query.md                     Index-first knowledge retrieval
│   ├── lint.md                      Structural + semantic health check
│   ├── save-synthesis.md            Persist answers as synthesis pages
│   ├── graph.md                     D3.js knowledge graph generation
│   └── review.md                    Review queue processing
└── hooks/                           Session lifecycle
    ├── session-start.sh             Wiki stats + PROACTIVE WIKI RULE
    └── session-stop.sh              Write hot-cache for next session
```

---

## Compared to RAG

| | Typical RAG | LLM Wiki |
|---|-----|----------|
| Knowledge state | Re-derived per query | Persisted, compounding |
| Cross-references | None | Bidirectional [[wikilinks]] |
| Contradictions | Undetected | Flagged with callout blocks |
| Confidence | Opaque | Explicit per-page ratings |
| Audit trail | None | `based_on` provenance chain |
| Query cost | Every query reads source chunks | Index-first: only 3-5 pages read |
| Proactive | No — must be invoked | Yes — CLAUDE.md + hook drives behavior |

> Note: Advanced RAG implementations can include some of these features, but they're not standard. LLM Wiki provides them by design.

---

## Design Principles

| Principle | Implementation |
|-----------|---------------|
| **LLM is the runtime** | All content work done by Claude. No external language runtime needed. |
| **Bash for determinism** | SHA-256, grep, file listing — correctness-critical operations only. |
| **Auto-generated index** | Regenerated on every change. Never hand-edited. |
| **Incremental caching** | SHA-256 sentinel files prevent re-work. |
| **Two-phase ingest** | Human checkpoint between analysis and generation. |
| **Hot cache** | Multi-session context bridge via SessionStop/SessionStart hooks. |
| **True bilingual** | `language` field, CJK detection, cross-language aliases. |
| **Lint separation** | Quick (bash, free) vs Full (LLM, thorough) — pay only when needed. |

---

## Community

- [Contributing Guide](CONTRIBUTING.md)
- [Code of Conduct](CODE_OF_CONDUCT.md)
- [Security Policy](SECURITY.md)
- [Changelog](CHANGELOG.md)
- [Support](SUPPORT.md)
- [FAQ](FAQ.md)

---

## Credits

- **Pattern**: [Andrej Karpathy](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f)
- **Implementation**: Built with Claude Code

## License

MIT — see [LICENSE](LICENSE) for full text.
