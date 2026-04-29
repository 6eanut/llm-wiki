# LLM Wiki — Compounding Knowledge Base for Claude Code

A **Claude Code skill** that builds and maintains a persistent, interlinked wiki from your source documents. Based on Andrej Karpathy's [LLM Wiki pattern](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f).

Knowledge is compiled once and kept current, not re-derived on every query.

---

## Quick Start

```bash
# 1. Install the skill globally (one-time)
./llm-wiki/install.sh --force

# 2. Set up wiki in your project
~/.claude/skills/llm-wiki/scripts/setup-project.sh ./wiki --with-hooks

# 3. Start Claude Code — that's it!
# Ask any question naturally. Claude checks the wiki first, automatically.
```

### What to Expect

After setup, start Claude Code in your project and ask a question:

```
You: "What is RISC-V?"

Claude: [reads ./wiki/.llm-wiki/index.md automatically]
        [finds relevant pages]
        [synthesizes answer with citations]

        ## Answer
        RISC-V is an open standard instruction set architecture...

        ## Evidence
        | Source Page | Key Point | Confidence |
        |-------------|-----------|------------|
        | [[risc-v]] | ISA overview | high |
```

**You don't need to type `/wiki-query` for routine questions.** Claude reads CLAUDE.md at startup and follows the rule: "check the wiki before answering."

If the wiki doesn't have relevant knowledge, Claude will tell you and suggest adding source files to `.raw/`.

### Adding Knowledge

1. Drop source files (markdown, text) into `./.raw/`
2. Run `/wiki-ingest .raw/your-file.md`
3. The file is analyzed, concepts extracted, and interlinked pages created

---

## Slash Commands

| Command | Description |
|---------|-------------|
| `/wiki` | Dashboard — total pages, recent activity, pending reviews |
| `/wiki-ingest <file\|URL>` | Two-phase ingest: analyze source → generate interlinked pages |
| `/wiki-query <question>` | Index-first retrieval — reads only relevant pages, synthesizes answer |
| `/wiki-lint [--quick\|--full]` | Health check. Quick = bash scripts (free). Full = LLM semantic analysis |
| `/wiki-save` | Save current answer as a permanent synthesis page |
| `/wiki-graph` | Generate interactive D3.js force-directed knowledge graph |
| `/wiki-review` | Process the review queue — contradictions, stale pages, knowledge gaps |

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

| | RAG | LLM Wiki |
|---|-----|----------|
| Knowledge state | Re-derived per query | Persisted, compounding |
| Cross-references | None | Bidirectional [[wikilinks]] |
| Contradictions | Undetected | Flagged with callout blocks |
| Confidence | Opaque | Explicit per-page ratings |
| Audit trail | None | `based_on` provenance chain |
| Query cost | Every query reads source chunks | Index-first: only 3-5 pages read |
| Proactive | No — must be invoked | Yes — CLAUDE.md + hook drives behavior |

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

## Credits

- **Pattern**: [Andrej Karpathy](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f)
- **Implementation**: Built with Claude Code

## License

MIT
