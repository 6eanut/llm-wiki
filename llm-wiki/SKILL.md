---
name: wiki
description: Build and maintain a persistent, interlinked wiki from source documents. Knowledge is compiled once and kept current. Based on Andrej Karpathy's LLM Wiki pattern. Commands: /wiki (dashboard), /wiki-ingest, /wiki-query, /wiki-lint, /wiki-save, /wiki-graph, /wiki-review.
---

# LLM Wiki — Compounding Knowledge Base

A Claude Code skill for building and maintaining a persistent, interlinked wiki from source documents. Knowledge is compiled once and kept current, not re-derived on every query.

Based on Andrej Karpathy's [LLM Wiki pattern](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f).

## Architecture

```
Raw Sources (.raw/)  →  Wiki (markdown pages)  →  Schema (this skill)
   (immutable)           (LLM-generated)           (conventions & rules)
```

You are the wiki maintainer. Your job: read sources, extract concepts, create interlinked pages, and keep everything current. The human curates sources and asks questions. You handle everything else.

## Proactive Usage (CRITICAL)

You should **proactively** use the wiki without waiting for explicit `/wiki*` commands:

1. **Before answering any factual question**: Read `.llm-wiki/index.md` to check if the wiki has relevant pages. If it does, use them as your primary source — cite with `[[wikilinks]]`. Do NOT answer from training data without checking the wiki first.

2. **When the user mentions a topic**: Check if the wiki covers it. Show what the wiki knows.

3. **When the wiki lacks knowledge**: Tell the user clearly: "The wiki doesn't cover this yet." Suggest dropping source documents into `.raw/` for ingestion.

4. **After modifying wiki pages**: Always regenerate the index by reading all pages, extracting frontmatter, and writing the updated `.llm-wiki/index.md`.

5. **Knowledge gap detection**: Actively identify what the wiki is missing and suggest sources to fill gaps.

### How to check the wiki (lightweight, no skill needed)
```
1. Read {project}/wiki/.llm-wiki/index.md  (page catalog)
2. Match query against tags, titles, summaries
3. Read 3-5 most relevant pages
4. Synthesize answer with evidence table and confidence rating
```

### When to use the full skill
Use `Skill("llm-wiki")` when you need deep wiki operations (ingestion, full lint, graph, review queue). The skill gives you access to all `workflows/` and `scripts/`.

## Slash Commands

The skill provides 7 real slash commands. Each is a `.md` file in `commands/` that gets installed to `~/.claude/commands/` by `install.sh`. Claude Code auto-discovers them at startup.

When you are invoked (via `Skill("llm-wiki")`), determine which workflow to follow based on the command the user ran:

| Command | Command file | What it does | Workflow file |
|---------|-------------|-------------|---------------|
| `/wiki` | _(skill auto-registration)_ | Dashboard — stats, recent activity, pending reviews | (inline below) |
| `/wiki-ingest <file\|URL>` | `commands/wiki-ingest.md` | Ingest a source into the wiki (two-phase) | `workflows/ingest.md` |
| `/wiki-query <question>` | `commands/wiki-query.md` | Answer a question from wiki knowledge | `workflows/query.md` |
| `/wiki-lint [--quick\|--full]` | `commands/wiki-lint.md` | Health check — structural or semantic | `workflows/lint.md` |
| `/wiki-save` | `commands/wiki-save.md` | Save current answer as a synthesis page | `workflows/save-synthesis.md` |
| `/wiki-graph` | `commands/wiki-graph.md` | Generate knowledge graph visualization | `workflows/graph.md` |
| `/wiki-review` | `commands/wiki-review.md` | Process the review queue | `workflows/review.md` |

## How to Use This Skill

When you are invoked (via `Skill("llm-wiki")`), determine which workflow to follow based on the command the user ran. Then:

1. **Read the corresponding workflow file** (listed in the table above)
2. **Follow it step by step** — the workflow file contains exact procedures
3. **Use bash scripts** from `scripts/` for deterministic operations (hashing, grep, file listing)
4. **Use your reasoning** for all content work (extraction, cross-referencing, contradiction detection)

## Key File Paths

| Path | Purpose |
|------|---------|
| `WIKI_SCHEMA.md` | Page type definitions, field specs, naming conventions |
| `scripts/init-wiki.sh` | Bootstrap a new wiki directory |
| `{project}/wiki/.llm-wiki/` | Wiki metadata (index, cache, review queue) |
| `{project}/wiki/.llm-wiki/schema.md` | Per-project copy of schema |
| `{project}/wiki/.llm-wiki/config.md` | User configuration overrides |
| `{project}/wiki/.llm-wiki/index.md` | Auto-generated index — **never edit by hand** |
| `{project}/wiki/.llm-wiki/cache/hot-cache.md` | Multi-session context bridge |
| `{project}/.raw/` | Immutable source documents |

## Finding the Wiki Root

The wiki root is determined by (in priority order):
1. `LLM_WIKI_ROOT` environment variable
2. `wiki/` directory in the current project
3. Ask the user: "Where should I put the wiki? (default: ./wiki)"

## /wiki — Dashboard

When the user invokes `/wiki`, do the following:

1. **Check if wiki exists**: Look for `wiki/.llm-wiki/index.md` (or `$LLM_WIKI_ROOT/.llm-wiki/index.md`)
   - If not found: offer to run `scripts/init-wiki.sh` to bootstrap

2. **Read `.llm-wiki/index.md`** for the full page catalog

3. **Read `.llm-wiki/review.json`** for pending review items

4. **Read `.llm-wiki/cache/hot-cache.md`** if it exists (for session context)

5. **Present the dashboard**:

```
# Wiki Dashboard / 维基面板

**Total pages:** {N}
**Last updated:** {timestamp}
**Index status:** {fresh|stale — run /wiki-lint}

## Recent Activity / 最近活动
| Date | Operation | Title |
|------|-----------|-------|
... (from log if exists, or index modified dates)

## Page Types / 页面类型
| Type | Count |
|------|-------|
| concept | N |
| article | N |
| person | N |
| synthesis | N |

## Pending Review / 待审核 ({N})
... (from review.json)

## Active Topics / 活跃主题
... (from hot-cache if available)
```

## Design Principles (For Your Reference)

- **LLM is the runtime**: You read, write, extract, and cross-reference. Bash only for hashing, grep, file listing.
- **Auto-generated index**: `index.md` is rebuilt programmatically on every change. Never edit it by hand.
- **Incremental caching**: SHA-256 of sources prevents re-ingesting unchanged files.
- **Two-phase ingest**: Phase 1 = analysis (reviewable by user), Phase 2 = page generation.
- **Hot cache**: Bridges context between sessions so you don't start cold.
- **True bilingual**: Every page has a `language` field; templates support both zh and en.
