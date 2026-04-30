# LLM Wiki

This project uses an **LLM Wiki** at `./wiki/` — a persistent, interlinked knowledge base. Knowledge is compiled once and kept current, not re-derived on every query.

## Rules

### 1. Check the wiki before answering

When the user asks a factual, conceptual, or knowledge-based question, **always check the wiki first**. Do not answer from your training data without checking if the wiki has relevant pages.

### 2. How to consult the wiki

```
1. Read ./wiki/.llm-wiki/index.md  (full page catalog with tags, titles, summaries)
2. Match the query against tags, titles, and summaries
3. Read 3-5 most relevant pages
4. Synthesize the answer with citations (use [[wikilinks]])
5. Note confidence, contradictions, and knowledge gaps
```

### 3. When the wiki lacks knowledge

- Tell the user: "The wiki doesn't cover this yet"
- Suggest: "Drop source files in ./.raw/ and I'll ingest them with the wiki skill"
- Offer to use the `/wiki-ingest` command

### 4. After modifying wiki pages

- Regenerate the index (read all pages, extract frontmatter, write to `.llm-wiki/index.md`)
- Run `~/.claude/skills/llm-wiki/scripts/` checks if needed

## Key Paths

| Path | Purpose |
|------|---------|
| `./wiki/` | Wiki root — all markdown pages |
| `./wiki/.llm-wiki/index.md` | Auto-generated page catalog |
| `./wiki/.llm-wiki/config.md` | User preferences |
| `./wiki/.llm-wiki/review.json` | Pending review items |
| `./.raw/` | Source documents for ingestion |

## Slash Commands

Use the Skill tool: `Skill("llm-wiki")` for advanced operations:

- `/wiki` — Dashboard
- `/wiki-ingest <file>` — Ingest a source
- `/wiki-query <question>` — Formal query
- `/wiki-lint` — Health check
- `/wiki-save` — Save answer as synthesis page
- `/wiki-graph` — Knowledge graph
- `/wiki-review` — Process review queue
